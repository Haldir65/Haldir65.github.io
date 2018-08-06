---
title: Retrofit源码阅读笔记
date: 2017-07-01 23:03:00
tags:
   - Retrofit
   - OkHttp
   - Okio
---

### This is gonna be nasty...... TL;DR
![](http://www.haldir66.ga/static/imgs/d653491fb55bec754b8471aa6a3f6eed.jpg)

<!--more-->

### 1. Retrofit

#### 1.1 使用方法
Retrofit本身并不局限于Android平台，java应用也可以用来和服务器沟通。
Retrofit一般的用法看上去很简单
```java
 public interface GitHub {
    @GET("/repos/{owner}/{repo}/contributors")
    Call<List<Contributor>> contributors(
        @Path("owner") String owner,
        @Path("repo") String repo);
  }

Retrofit retrofit = new Retrofit.Builder()
        .baseUrl(API_URL)   // end_point
        .addConverterFactory(GsonConverterFactory.create())
        .build();

    // Create an instance of our GitHub API interface.
    GitHub github = retrofit.create(GitHub.class);

    // Create a call instance for looking up Retrofit contributors.
    Call<List<Contributor>> call = github.contributors("square", "retrofit");

    // Fetch and print a list of the contributors to the library.
    List<Contributor> contributors = call.execute().body();
    for (Contributor contributor : contributors) {
      System.out.println(contributor.login + " (" + contributor.contributions + ")");
    }

```
关键来看这段 retroft.create ,重点都在这里面。关键的代码就在这三行里面了


>ServiceMethod serviceMethod = loadServiceMethod(method);
OkHttpCall okHttpCall = new OkHttpCall<>(serviceMethod, args);
return serviceMethod.callAdapter.adapt(okHttpCall);

### 1.2 第一个方法以及ServiceMethod的创建
loadServiceMethod(Method)会查找invoke的时候会查找methodCache中有没有这个方法，没有的话调用Builder方法创建一个ServiceMethod实例并放入cahce。看一看这个Builder的构造函数 ，基本上就是把Builder中的参数引用赋值给ServiceMethod实例。

result = new ServiceMethod.Builder(this, method).build();
```java
 public Builder(Retrofit retrofit, Method method) {
      this.retrofit = retrofit; //client创建retrofit时可以设定一些属性
      this.method = method;
      this.methodAnnotations = method.getAnnotations();
      this.parameterTypes = method.getGenericParameterTypes();
      this.parameterAnnotationsArray = method.getParameterAnnotations();
    }
```

```java
根据ServiceMethod的变量名基本上能够猜到各自的用处，比如httpMethod（GET、POST）,
contentType（MimeType）
 public ServiceMethod build() {
        // 1.创建callAdapter,调用retrofit对象设定的callAdapter,例如RxjavAdapter,注意这里面的实现是便利retrofit对象的adapterFactories，找到一个就返回。找不到的话会丢出来一个IllegalArgumentException
      callAdapter = createCallAdapter();
       //callAdapter的作用 就是将retrofit.Call的Call转成一个T。例如上面就是把Call<List<Contributor>>转成一个List<Contributor>，这个过程是上面提到的最重要的三个方法中的第三部 adapt（okHttpCall）。可以认为是拿着一个已经创建好的okHttp的Call去做事情，在适当的时候将网络返回结果转成用户事先定义好的respose类型。
        //这一步返回一个java.lang.reflect.Type ，就个class的基本作用家就是根据泛型来确定response的class。
      responseType = callAdapter.responseType();
        //2.创建用于response和Request的converter。
      responseConverter = createResponseConverter();
      for (Annotation annotation : methodAnnotations) {
        parseMethodAnnotation(annotation); //这里面就是把@GET变成"GET"这个String，表示当前方法是一个GET请求
      }
      int parameterCount = parameterAnnotationsArray.length;
      //3.创建ParameterHandler
      parameterHandlers = new ParameterHandler<?>[parameterCount];
      for (int p = 0; p < parameterCount; p++) {
        Type parameterType = parameterTypes[p];
        Annotation[] parameterAnnotations = parameterAnnotationsArray[p];
        if (parameterAnnotations == null) {
          throw parameterError(p, "No Retrofit annotation found.");
        }
        parameterHandlers[p] = parseParameter(p, parameterType, parameterAnnotations);
        //关键看这个方法
         private ParameterHandler<?> parseParameter(int p, Type parameterType, Annotation[] annotations)
         第一个参数表示当前的数组index
         第二个参数表示想要的Response类型
         第三个参数表示该方法上的注解，就是@那些东西
         接下来就是调用 private ParameterHandler<?> parseParameterAnnotation(
        int p, Type type, Annotation[] annotations, Annotation annotation)方法来判断各种Http方法，这一段代码有300多行。。。。看完有助于掌握Http协议。
      }
      return new ServiceMethod<>(this);
    }
}
```


关键是这三个方法，Buider在这个过程中完成了一些变量的赋值

1. createCallAdapter  --->  retrofit.callAdapter(returnType, annotations); 从adapterFactories(显然可以有多个)中遍历，找到了一个就返回。已经实现的的有三种**策略**，DefaultCallAdapterFactory、ExecutorCallAdapterFactory和RxjavaCallAdapterFactory。显然用户可以在创建retrofit实例的过程中install自己的callAdapter实现。
再次强调这个CallAdapter的作用，就是将Retrofit的Call adapt成对应的Response class的实例。

2. createResponseConverter --->  retrofit.responseBodyConverter(responseType, annotations);
Retrofit2.Converter<F, T> (from和To，我猜的)

Convert objects to and from their representation in HTTP. Instances are created by {@linkplain
 * Factory a factory} which is {@linkplain Retrofit.Builder#addConverterFactory(Factory) installed}
 * into the {@link Retrofit} instance.

从retrofit对象的converterFactories（可以有多个，原因在于server有时候会返回json，有时候会返回protocolBuffer，有时候返回xml，response回来的时候会一个个问，这一点jake Wharton多次提到过）中遍历，找到一个就返回。确切的说，是找到一个能够处理的。



3. 创建parameterHandlers
应该可以猜到，这一步就是把用户定义的注解转换成发起网络请求时需要带上的参数
> private ParameterHandler<?> parseParameterAnnotation(int p, Type type, Annotation[] annotations, Annotation annotation)

这个方法随便展开一点，关注第三个参数和第四个参数

例如       
```java 
 public interface GitHub {
    @GET("/repos/{owner}/{repo}/contributors")
    Call<List<Contributor>> contributors(
        @Path("owner") String owner,
        @Path("repo") String repo);
  }
```  

ServiceMethod走到这一步，annotations就表示 @Path("owner") String owner。注意这里的@PATH是注解类，可以把它当成一个wrapper，这里面就调用了path.value()。
```java
else if (annotation instanceof Path) {
        Path path = (Path) annotation;
        String name = path.value(); // 调用该方法时传入的String
        validatePathName(p, name);
        Converter<?, String> converter = retrofit.stringConverter(type, annotations);  
        return new ParameterHandler.Path<>(name, converter, path.encoded());
      }
```      
ParameterHandler.Path<>在ParameterHandler这个类里面，看一下结构![](http://odzl05jxx.bkt.clouddn.com/ParameterHandlers.jpg)
Path这个class中关键的方法apply:
```java
 @Override void apply(RequestBuilder builder, @Nullable T value) throws IOException {
      builder.addPathParam(name, valueConverter.convert(value), encoded);
    }
```
再往下走：
```java
relativeUrl = relativeUrl.replace("{" + name + "}", canonicalizeForPath(value, encoded));
```
apply这个方法会在构建Request时由RequestBilder调用，以上面的实例为例子，name就是"owner" ,value就是调用该方法时传进来的值，其实就只是Stirng.replace()方法。
到这里，Buidler已经完成了
- 准备callAdapter，
- createResponseConverter
- 和填充parameterHandlers数组的任务
直接new一个ServiceMethod出来就好了

```java
ServiceMethod(Builder<T> builder) {
    this.callFactory = builder.retrofit.callFactory();  // okhttp3.Call.Factory
    this.callAdapter = builder.callAdapter; //
    this.baseUrl = builder.retrofit.baseUrl(); //这个就是
    this.responseConverter = builder.responseConverter; // GsonConverter
    this.httpMethod = builder.httpMethod; //@GET
    this.relativeUrl = builder.relativeUrl; //@Path
    this.headers = builder.headers; //@Header
    this.contentType = builder.contentType;  //application/json这种
    this.hasBody = builder.hasBody;
    this.isFormEncoded = builder.isFormEncoded;
    this.isMultipart = builder.isMultipart;
    this.parameterHandlers = builder.parameterHandlers;
  }
```

上面最重要的三个方法讲完了第一个。  



### 1.3 第二个方法和OkHttpCall
第二个方法:
 OkHttpCall<Object> okHttpCall = new OkHttpCall<>(serviceMethod, args);

OkHttpCall的成员变量：
okhttp3.Call rawCall //用于发起请求
ServiceMethod<T, ?> serviceMethod;  //这就是刚才实例化的serviceMethod对象
这个类相对简单，主要看execute方法

```java
 @Override public Response<T> execute() throws IOException {
    okhttp3.Call call;
    synchronized (this) {
      if (executed) throw new IllegalStateException("Already executed.");
      executed = true;
      call = rawCall;
      if (call == null) {
        try {
          call = rawCall = createRawCall();
        } catch (IOException | RuntimeException e) {
        }
      }
    }
    return parseResponse(call.execute()); //建立连接，发起请求，解析response都在这里了（都在一条线程上）。execute是okHttp的方法。
  }
```
还记得最简单的Demo吗，同步执行网络请求
Call<List<Contributor>> call = github.contributors("square", "retrofit");
List<Contributor> contributors = call.execute().body();
这也是Retrofit2.Call.execute方法最终就是走到了这里

createRawCall方法
```java
 okhttp3.Request request = serviceMethod.toRequest(args);
 okhttp3.Call call = serviceMethod.callFactory.newCall(request);
    if (call == null) {
      throw new NullPointerException("Call.Factory returned null.");
    }
    return call;
```
parseRespnse的实现
```java
  Response<T> parseResponse(okhttp3.Response rawResponse) throws IOException {
    ResponseBody rawBody = rawResponse.body(); //有用的信息在这里
    // Remove the body's source (the only stateful object) so we can pass the response along.
    rawResponse = rawResponse.newBuilder()
        .body(new NoContentResponseBody(rawBody.contentType(), rawBody.contentLength()))
        .build(); //根据服务器返回的contentType和contentLength创建一个新的response用于检测200

    int code = rawResponse.code();
    if (code < 200 || code >= 300) {
      try {
        // Buffer the entire body to avoid future I/O.
        ResponseBody bufferedBody = Utils.buffer(rawBody);
        return Response.error(bufferedBody, rawResponse); //创建一个body为null的Retrofit2.Response
      } finally {
        rawBody.close();
      }
    }

    if (code == 204 || code == 205) {
      rawBody.close();
      return Response.success(null, rawResponse);
    }

    ExceptionCatchingRequestBody catchingBody = new ExceptionCatchingRequestBody(rawBody);
    try {
      T body = serviceMethod.toResponse(catchingBody); //调用ServiceMethod的responseConverter去转换，前面说过，responseConverter是在builder初始化的时候根据策略，从Retrofit的converterFactories中遍历，找到了就返回。
      return Response.success(body, rawResponse); //返回创建一个body为定义好的数据类型的Retrofit2.Response，一般情况下，调用Response.body()就能得到所要的实体数据。
    } catch (RuntimeException e) {
      // If the underlying source threw an exception, propagate that rather than indicating it was
      // a runtime exception.
      catchingBody.throwIfCaught();
      throw e;
    }
  }
```
这里可以得知，Retrofit对于状态码的处理，1XX和3XX以上全部走到error中


execute是同步方法，enqueue是异步请求的方法，底层其实就调用了OkHttp.Call.enqueue()，所以说Retrofit本身并不负责创建网络请求，线程调度。只做了parseRespnse的方法，另外，OkHttp和Retrofit本身并不负责把Response推到主线程上，Android 平台可能要注意。

### 1.4 第三个方法和AdapterFactory
return serviceMethod.callAdapter.adapt(okHttpCall); //这个return需要的是Object,涉及到动态代理，可以无视。

回头看一下serviceMethod的createCallAdapter方法，就是从retrofit对象的adapterFactories中一个个遍历：

> CallAdapter<?, ?> adapter = adapterFactories.get(i).get(returnType, annotations, this)；

找到之后就返回，默认的实现有DefaultCallAdapterFactory和ExecutorCallAdapterFactory以及RxjavaCallAdapterFactory。

```java
// 在DefaultCallAdapterFactory中的处理方式是

 return new CallAdapter<Call<?>>() {
      @Override public Type responseType() {
        return responseType;
      }

      @Override public <R> Call<R> adapt(Call<R> call) {
        return call;
      }
    };


// ExecutorCallAdapterFactory的处理方式是


 return new CallAdapter<Object, Call<?>>() {
      @Override public Type responseType() {
        return responseType;
      }

      @Override public Call<Object> adapt(Call<Object> call) {
        return new ExecutorCallbackCall<>(callbackExecutor, call);
      }
    };
```


其实就是将callback丢到一个线程池callbackExecutor中，这个线程池可以通过Retrofit创建的时候配置，简单来说就是response会在这个线程池中回调。

 RxjavaCallAdapterFactory的做法是
```java
 @Override
  public CallAdapter<?> get(Type returnType, Annotation[] annotations, Retrofit retrofit) {
    Class<?> rawType = getRawType(returnType);
    String canonicalName = rawType.getCanonicalName();
    boolean isSingle = "rx.Single".equals(canonicalName); //直接看包名。。。。。
    boolean isCompletable = "rx.Completable".equals(canonicalName);
    if (rawType != Observable.class && !isSingle && !isCompletable) {
      return null;
    }
    if (!isCompletable && !(returnType instanceof ParameterizedType)) {
      String name = isSingle ? "Single" : "Observable";
      throw new IllegalStateException(name + " return type must be parameterized"
          + " as " + name + "<Foo> or " + name + "<? extends Foo>");
    }

    if (isCompletable) {
      // Add Completable-converter wrapper from a separate class. This defers classloading such that
      // regular Observable operation can be leveraged without relying on this unstable RxJava API.
      // Note that this has to be done separately since Completable doesn't have a parametrized
      // type.
      return CompletableHelper.createCallAdapter(scheduler);
    }

    CallAdapter<Observable<?>> callAdapter = getCallAdapter(returnType, scheduler);
    if (isSingle) {
      // Add Single-converter wrapper from a separate class. This defers classloading such that
      // regular Observable operation can be leveraged without relying on this unstable RxJava API.
      return SingleHelper.makeSingle(callAdapter);
    }
    return callAdapter;
}
```


### 1.5 使用Retrofit的best practices

到这里，retrofit的工作流程就通过三个方法讲完了，接下来根据jake wharton的talk [making retrofit work for you](https://www.youtube.com/watch?v=t34AQlblSeE)来讲几个best practice。

#### 1.5.1 end point 不一样怎么办
默认情况下，如果不指定client,每一次都会创建一个新的OkHttpClient，这样做就丧失了disk caching,connection pooling等优势。

![endpoint](http://odzl05jxx.bkt.clouddn.com/different_end_point.jpg)    

所以需要提取出一个OkHttpClient,解决方式很简单
![](http://odzl05jxx.bkt.clouddn.com/different_end_point_teh_right_way.jpg)

#### 1.5.2 不要创建多个HttpClient

shallow copy
```java
OkHttpClient client = new OkHttpClient();

OkHttpClient clientFoo = client.newBuilder().addInterceptor(new FooInterceptor()).build();

OkHttpClient clientBar = client.newBuilder().readTimeOut(20,SECONDS).writeTimeOut(20,SECONDS).build();
```

#### 1.5.3 有的接口需要认证（加Header），有的不需要（比如登录，忘记密码）
一般可能会想到在OkHttp的Interceptor中去判断url然后手动加上header，一种更好的解决方式是，假定所有的API都需要加Header，对于登录和忘记密码的Api,这样写
```java
@POST("/login")
@Headers("No-Authentication: true")
Call<User> login(@Body LoginRequest request)
```
//这个header对于server是不可见的，现在在Interceptor中，
只要判断request.header("No-Authentication")==null 即表示该接口需要加上header。
所以，对于特定接口的筛选可以，采用这种方式。

#### 1.5.4 Converters将byte变成java对象，底层的解析器不要创建多个

addConverterFactory，和之前的创建两个httpclient一样，人们也很容易创建两个解析器。解决方法也很实在，提取出来公用即可。
![](http://odzl05jxx.bkt.clouddn.com/creating%20two%20convertors.jpg)


#### 1.5.5 addConverterFactory可以调用多次
假如一个接口返回json，一个接口返回proto。不要试图创建多个retrofit实例。这样就可以了
![](http://odzl05jxx.bkt.clouddn.com/different_response.jpg)

底层的原理是这样的。
User是Proto,Friend是Json。 Proto都extends一个protoType class，所以只要看下是否 instanceof proto就可以了。这一切都是在serviceMethod创建过程中判断的。这里顺序很重要。由于gson基本能够序列化一切，所以gson总是会认为自己可以成功。所以要把protoConverter放在前面。
 GsonConverterFactory, SimpleXmlConverterFactory converters , they say yes to everyThing. 所以如果出现这种情况怎么办？
 首先定义自己的注解
 ```java
 @interface Xml {}
 @interface Json {}

 interface Service{
    @GET("/User") @Xml
    Call<User> user(); // User是XML

    @GET("/Friends") @Json
    Call<Friends> friends();  //Friends是Json
 }

class XmlOrJsonConverterFactroy extend Converter.Factory{
    final Converter.Factory xml = ///;
    final Converter.Factory json = //....;

    @override
    public Converter<ResponseBody,?> responseBodyConverter(Type type, Annotation[] annotations, Retrofit retrofit){
        // annotations就包含了刚才我们添加的注解
        for (Annotation annotation : annotations){
            if(annotation.getClass == Xml.class){
                return xml.reponseBodyConverter(type,annotations,retrofit);
            }else if(annotation.getClass == Json.class){
                // json
            }
            return null; 都不是。 会去找下一个Converter..
        }
    }
}
[AnnotatedConverterFactory用于自定义类型](https://github.com/square/retrofit/blob/master/samples/src/main/java/com/example/retrofit/AnnotatedConverters.java)
```

#### 1.5.6 服务器返回的数据中包括一些metaData
使用delegate的方式去除这些metadata，只获取想要的response实体对象
![](http://odzl05jxx.bkt.clouddn.com/delegaet_converters.jpg)
但这些metaData是有用的。。怎么处理
可以在convert中集中处理自定义错误码。

#### 1.5.7 和Rxjava配合使用
CallAdapterFactory和ConverterFactory类似，也可以自定义，所以这样可以直接将所有的Observable返回到主线程

![](http://odzl05jxx.bkt.clouddn.com/always_observe_on_mian_thread.jpg)


所以，Retrofit就是将HttpClient、Converter和CallAdapter这三样职能结合起来，又提供了足够的定制化。


### 1.6 补充
OkHttp本身没有将response挪到主线程，Retrofit这么干了，具体在
Retrofit.Builder.build方法里面
```java
public Retrofit build() {
  Executor callbackExecutor = this.callbackExecutor;
  if (callbackExecutor == null) {
    callbackExecutor = platform.defaultCallbackExecutor();
    //Andriod平台默认挪到主线程，就是一个持有主线程的线程池
    //这个线程池的excute方法就是用一个hadler推到主线程了。
  }
  // Make a defensive copy of the adapters and add the default Call adapter.
  List<CallAdapter.Factory> adapterFactories = new ArrayList<>(this.adapterFactories);
  adapterFactories.add(platform.defaultCallAdapterFactory(callbackExecutor));
  //如果不加CallAdapterFactory的话，
  //Android平台默认直接把response丢回给callback，默认配置也是在主线程干的。
  //如果不希望在主线程接收Response的话，自己在Builder里面添加callbackExecutor.

  // Make a defensive copy of the converters.
  List<Converter.Factory> converterFactories = new ArrayList<>(this.converterFactories);

  return new Retrofit(callFactory, baseUrl, converterFactories, adapterFactories,
      callbackExecutor, validateEagerly);
}
```

根据[jake Wharton在stackoverFlow上的回答](https://stackoverflow.com/questions/21652461/retrofit-callback-on-main-thread),Retrofit parse byte to Object的过程是发生在子线程的。



## update
[根据stackoverFlow上的解释，对于queryParameters，一些optional的参数直接传null就可以了](https://stackoverflow.com/questions/37016261/retrofit-optional-and-required-fields) 这段从源码上还没有来得及看清楚。


### 2. OkHttp


### 3. A few 'ok' libraries
why moshi ? why Retrofit call can be clone cheap？
why SinkedSource?
why protolBuffer cost less ?



### Ref
1. [Paisy解析Retrofit](https://blog.piasy.com/2016/06/25/Understand-Retrofit/)
2. [open-sourse-projetc解析Retrofit](https://github.com/android-cn/android-open-project-analysis/tree/master/tool-lib/network/retrofit)
3. [Making Retrofit Work For You by Jake Wharton](https://www.youtube.com/watch?v=t34AQlblSeE)
