---
title: For those tiny details in Java 
date: 2017-06-17 21:24:48
tags: [java]
---
> interesting stuff in java that don't seem to get enough pubilicity
> 
>

![landscape](http://odzl05jxx.bkt.clouddn.com/34a7d57ccabb18c69d085247cf009b22.jpg?imageView2/2/w/600)

<!--more-->

1. getting the concreate class from generic types
    ```java
        /**
     * Make a GET request and return a parsed object from JSON.
     *
     * @param url     URL of the request to make
     * @param clazz   Relevant class object, for Gson's reflection
     * @param headers Map of request headers
     */
    public GenericMoshiRequest(String url, @Nullable Class<T> clazz, Map<String, String> headers,
                               Response.Listener<T> listener, Response.ErrorListener errorListener) {
        super(Method.GET, url, errorListener);
//        this.clazz = clazz;
        Class<T> entityClass = (Class<T>) ((ParameterizedType) getClass().getGenericSuperclass()).getActualTypeArguments()[0];//使用反射获得泛型对应class
        this.clazz = entityClass;
        this.headers = headers;
        this.listener = listener;
    }
    ```

2. OkHttp 默认会自动重试失败的请求
[okhttp-is-quietly-retrying-requests-is-your-api-ready](https://medium.com/inloop/okhttp-is-quietly-retrying-requests-is-your-api-ready-19489ef35ace)
OkHttp默认会对请求进行重试，具体是在RetryAndFollowUpInterceptor中进行的。
    ```java
   RetryAndFollowUpInterceptor.java

  @Override public Response intercept(Chain chain) throws IOException {
    Request request = chain.request();

    streamAllocation = new StreamAllocation(
        client.connectionPool(), createAddress(request.url()), callStackTrace);

    int followUpCount = 0;
    Response priorResponse = null;
    while (true) { # 不停的尝试
      if (canceled) {
        streamAllocation.release();
        throw new IOException("Canceled");
      }

      Response response = null;
      boolean releaseConnection = true;
      try {
        response = ((RealInterceptorChain) chain).proceed(request, streamAllocation, null, null);
        releaseConnection = false; //默认不认可response成功
      } catch (RouteException e) {
        // The attempt to connect via a route failed. The request will not have been sent.
        if (!recover(e.getLastConnectException(), false, request)) {
          throw e.getLastConnectException();
        }
        releaseConnection = false;
        continue;  //继续尝试
      } catch (IOException e) {
        // An attempt to communicate with a server failed. The request may have been sent.
        boolean requestSendStarted = !(e instanceof ConnectionShutdownException);
        if (!recover(e, requestSendStarted, request)) throw e;
        releaseConnection = false;
        continue; //继续尝试
      } finally {
        // We're throwing an unchecked exception. Release any resources.
        if (releaseConnection) { //出现不可预料的错误，释放硬件资源，端口什么的
          streamAllocation.streamFailed(null);
          streamAllocation.release();
        }
      }
    }
  }
    ```
客户端当然可以使用retryOnConnectionFailure禁止这种自动重试策略，但不建议这么做。另外，为避免减少不必要的重试请求，
OkHttp 3.3.0 [issue](https://github.com/square/okhttp/issues/2394)

> Don’t recover if we encounter a read timeout after sending the request, but do recover if we encounter a timeout building a connection
建立连接超时可以重试(客户端到服务器的通道不可靠，当然可以重试)，连接上之后读取超时则不去重试(服务器出了问题，没有必要重试)。

另外，GET方法本身是人畜无害的，Retry请求多次发起不会造成数据错误；但对于POST，涉及到写服务端写操作，最好带上GUID作为单次请求unique标示。（这是server和client之间需要协商好的protocol）

3. From Java Code To Java Heap 
   A talk from IBM Engineer, talking about optimizing the memery usage for your java application.[youtube](https://www.youtube.com/watch?v=FLcXf9pO27w)
   [ibm](https://www.ibm.com/developerworks/java/library/j-codetoheap/index.html)

4. 强行更改String的内容
  String这种东西是放在常量池里面的，所以
  ```java
  String a = "hello"
  String b = "hello"
  String c = new String("Hello")
  
  显然ab都指向了常量池，c指向了放在堆上的对象，后者也指向常量池
  a==b!=c  

  //更改这个String里面的东西
  Field a_ = String.class.getDeclaredField("value");
        a_.setAccessible(true);
        char[] value=(char[])a_.get(a);
        value[3]='_';   //修改a所指向的值

  这样a,b,c 的值都改掉了      

  ```

5. 注解
```java
 Builder(Retrofit retrofit, Method method) {
      this.retrofit = retrofit;
      this.method = method;
      this.methodAnnotations = method.getAnnotations();
      this.parameterTypes = method.getGenericParameterTypes();
      this.parameterAnnotationsArray = method.getParameterAnnotations();
    }
```

如果不是看到Retrofit的源码，一般还真没机会了解到这几个方法。。

6. java如何把char类型数据转成int类型数据
String a = "123"
Stirng本质上就是一个char[]的包装类，1对应Asicii码的49,2对应50,3对应51.所以实质上就类似于char[] = new char{49,50,51} ;

想把1,2,3分别拿出来得这么写：
```java
char[] array = a.tocharArray();
for(i=0;i<=array.length();i++){
  int a = Integer.parseInt(String.valueof(array.charAt(i)));//这样就能分别把1,2,3拿出来了。
}
```


根据stackoverFlow的[解释](https://stackoverflow.com/questions/14342988/why-are-we-allowed-to-assign-char-to-a-int-in-java), char只是16bit的数字，也就是int（4个字节,32位）的子集。

```java
char word = 'A' +1234 ;//编译通过

char word2 = 'A';
word2 = word2 +1 ;//编译失败
```

[char的转换问题](https://stackoverflow.com/questions/21317631/java-char-int-conversions)





