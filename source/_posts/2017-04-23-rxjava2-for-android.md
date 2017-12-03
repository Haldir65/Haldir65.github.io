---
title: Rxjava2 的一些点
date: 2017-04-23 13:56:07
categories: blog
tags: [rxjava2,android]
---

本文多数内容来自Jake Wharton的演讲，配合一些个人的感受，作为今后使用Rxjava2的一些参考。
![](http://odzl05jxx.bkt.clouddn.com/f21a6a245edfe0b19804be5b3df24a3d.jpg?imageView2/2/w/600)
<!--more-->


## 1. Why Reactive?
最早使用Rxjava的初衷在于方便地实现线程切换，使用链式语法轻松地将异步任务分发到子线程并省去了主动实现回调的麻烦。
我们生活在一个事件异步分发的环境中，网络，文件、甚至用户输入本身也是异步事件，除此之外，安卓系统本身的许多操作也是异步的，例如startActivity，Fragment的transaction，这就要求开发者不得不考虑各种事件状态，并在各种事件之间进行协调。Rxjava将各种事件的处理、完成以及异常在事件定义之初定义好处理方式。事件的开始，进行，完成以及异常，都被抽象到Observable的载体中。值得注意的是，这种链式调用很像Builder Pattern，但本质上每一步都生成了一个新的对象。这个在Rxjava的Wiki上有所说明，即每一步都生成一个新的immutable object（GC表示压力大）。


## 2. 数据源
Stream基本包括这三部分
```
source of data
listener of data
methods for modifying data
```
![](http://odzl05jxx.bkt.clouddn.com/stream_compose.jpg?imageView2/2/w/600)

### 2.1 数据源的种类
Observable<T> 和Flowable<T>，区别在于后者支持BackPressure，后者不支持BackPressure.
接收Observable和Flowable的类型分别为Observer和Subscriber

```java
interface Observer<T>{
  void onNext(T t);
  void onComplete();
  void onError(Throwable t);
  void onSubscribe(Disposable d);
}

interface Disposable{
  void dispose();
}


interface Subscriber<T>{
  void onNext(T t)
  void onComplete();;
  void onError(Throwable t);
  void onSubscribe(Subscription s);
}

interface Subscription{
  void cancel() //用于取消订阅，释放资源
  void request(long r) //请求更多的数据，即BackPressure开始体现的地方
}
```
两者的区别在于最后一个方法，以Disposable为例，当你开始subscribe一个数据源的时，就类似于创建了一个Resurce，而Resource是往往需要在用完之后及时释放。无论是Observable还是Flowable,这个onSubscribe方法会在订阅后立即被调用，这个方法里的Disposable可以保留下来，在必要时候用于释放资源。如Activity的onDestroy中cancel network request.


### 2.2 数据源的对应类
1. Single(订阅一个Single，要么获得仅一个返回值，要么出现异常返回Error)
```java
public abstract class Single<T> implements SingleSource<T> {}

```

2. Completeable(订阅一个completeable，要么成功，不返回值，要么出现异常返回error，就像一个reactive runnale，一个可以执行的command，并不返回结果)
```java
public abstract class Completable implements CompletableSource {}
```
例如，异步写一个文件，要么成功，要么出现error，并不需要返回什么。
```java
public void writeFile(Stirng data){}
// 就可以model成
Completeable writeFile(Stirng data){}
```


3. Maybe(有可能返回值，有可能不返回，也有可能异常，即optional)
```java
public abstract class Maybe<T> implements MaybeSource<T> {}
```
以上三种数据源都有static方法生成：
例如
![from iterable](http://odzl05jxx.bkt.clouddn.com/creating_source_from_iterable.jpg?imageView2/2/w/600)


![fromjust](http://odzl05jxx.bkt.clouddn.com/creating_source_from_just.jpg?imageView2/2/w/600)

比较推荐的方法有两种

### 1. fromCallable
```java
Observable.fromCallable(new Callable<String>(){

  @override
  public String call() throw Exception{
      return getName() //  之前是synchronious的get，现在这一步可以asynchnous执行,比如放一个OkHttpClient.newCall(request).execute(); //因为是异步执行的，也不存在性能问题
}
})
```
上面这段中的call方法会在被订阅后执行，成功的话会走到observer的onNext，失败的话会走到onError。
fromCallable可用于各种数据源，包括Flowable
```java
Flowable.fromCallable(() -> "Hello Flowable");
Observable.fromCallable(() -> "Hello Observable");
Maybe.fromCallable(() -> "Hello Maybe");
Single.fromCallable(() -> "Hello Single");
Completeable.fromCallable(() -> "Hello Completeable");
```
> fromCallable are for modeling synchronous sourse of a single source of data.

很多需要返回值的方法都可以抽象成这种方法。
Maybe和Completeable还有两个方法,用于表示不返回数据的方法
```java
Maybe.fromAction(() -> "Hey jude")
Maybe.fromRunnable(() -> "ignore")

Completeable.fromAction(() -> "Hey jude")
Completeable.fromRunnable(() -> "ignore")

```

### 2. create(Rxjava 1中不推荐使用该方法，Rxjava2中建议使用)
```java
Observable.create(new ObservableOnSubscribe<String>()){
      @override
      public void subscribe (ObservableEmitter<String> e) throws Exception{ //subscribe get called whenever there's a new subscriber, emitter is the person that's listening.
      //
         e.onNext("Hello");
         e.onComplete();
      }
}
```

//一个Observable可以有多个subscriber。一个被观察者可以有多个观察者，被观察者的onNext调用，观察者的onNext也会被调用

lambda更简洁
```java
Observable.create(e ->{
    e.onNext("Hello");
    e.onNext("Hello");
    e.onComplete();
})

Okhttp的异步网络请求也可以model成一种被观察的流
Observable.create(e ->{
   Call call = client.newCall(request);
   call.enqueue(new Callback()){

    @Override
    public void   onResponse(Response r) throws IOException{
      e.onNext(r.body().toString());
      e.onComplete();
    }

    @Override
    public void onFailure(IOException e){
      e.onError(e);
    }

  }
})

//重点了来了，
public interface ObservableEmitter<T> extends Emitter<T> {
    /**
     * Sets a Cancellable on this emitter; any previous Disposable
     * or Cancellation will be unsubscribed/cancelled.
     * @param c the cancellable resource, null is allowed
     */
    void setCancellable(Cancellable c);
}

// emitter可以设置cancel的动作

Observable.create(e ->{
    e.setCacelation(() -view.setOnClickListener(null));
    view.setOnClickListener(v -> e.onNext());
})

// 点击按钮发送事件，取消订阅时避免leak View

和fromCallable一样，create方法也适用于所有五种data source

```



## 3. 如何订阅（接收）这些数据

### 3.1 observer<T>和Subscriber<T>

接收Observable和Flowable的类型分别为Observer和Subscriber

```java
interface Observer<T>{
  void onNext(T t);
  void onComplete();
  void onError(Throwable t);
  void onSubscribe(Disposable d);
}

interface Disposable{
  void dispose();
}


interface Subscriber<T>{
  void onNext(T t);
  void onComplete();
  void onError(Throwable t);
  void onSubscribe(Subscription s);
}

interface Subscription{
  void cancel(); //用于取消订阅，释放资源
  void request(long r) ;//请求更多的数据，即BackPressure开始体现的地方
}
```
## 所以整体来看，数据的流向就这么两种，左边发送数据(可能只有一个，可能间歇性的，可能一直不停)，事件通过数据流传输到右边，右边根据协议作出相应(Reactive)
Observable -> subscribe -> Observer

Flowable -> subscribe -> Subscription

### 3.2 onSubscribe怎么用
通常不直接用这两种base class，因为第四个方法不知道怎么用嘛。
![](http://odzl05jxx.bkt.clouddn.com/4dab298b9f7ce29c43f9d8eaf686e02f.jpg?imageView2/2/w/600)
```java
Observable.just("Hello").subscribe(new DisposableObserver<String>() {
                    @Override
                    public void onNext(String value) {
                    }

                    @Override
                    public void onError(Throwable e) {
                    }

                    @Override
                    public void onComplete() {
                    }
                });


  可以持有DisposableObserver，在停止订阅的时候调用observer.dispose方法，切断流。
  或者这样
  Disposable disposable =   Observable.just("Hello").subscribeWith(new DisposableObserver<String>() {
                    @Override
                    public void onNext(String value) {
                    }

                    @Override
                    public void onError(Throwable e) {
                    }

                    @Override
                    public void onComplete() {
                    }
                });

   subscribeWith返回一个Disposable，subscribe是一个没有返回值的函数    

  偷懒一点的话，通常把这些返回的订阅加入到一个CompositeDisposable,在onDestroy的时候统一取消订阅即可  

  Observable、Single、Completeable、Maybe以及Flowable都支持subscribewith。


```




## 4. 数据源和接受者建立联系

> Observable.subscribe  
或者
> Flowable.subscribe
或者使用之前提到的sbscribeWith
我尝试写了一个比较复杂的调用顺序
```java
Observable.fromCallable(new Callable<List<String>>() {
            @Override
            public List<String> call() throws Exception {
                LogUtil.p("call do on thread any");
                blockThread(2000); // block 2s
                return Arrays.asList(array);
            }
        }).subscribeOn(Schedulers.computation())
                .observeOn(AndroidSchedulers.mainThread())
                .doOnSubscribe(new Consumer<Disposable>() {
                    @Override
                    public void accept(Disposable disposable) throws Exception {
                        LogUtil.p("");
                    }
                }).doOnComplete(new Action() {
            @Override
            public void run() throws Exception {
                LogUtil.p("");
            }
        }).doOnNext(new Consumer<List<String>>() {
            @Override
            public void accept(List<String> strings) throws Exception {
                LogUtil.p("" + strings.get(0));
            }
        }).doAfterNext(new Consumer<List<String>>() {
            @Override
            public void accept(List<String> strings) throws Exception {
                LogUtil.p(""+strings.get(0));
            }
        }).subscribe(new Observer<List<String>>() {
            @Override
            public void onSubscribe(Disposable d) {
                LogUtil.p("onSubscribe " + d.isDisposed());
            }

            @Override
            public void onNext(List<String> value) {
                LogUtil.p(" get Response " + value.size());
                value.set(0, "change first element!");
            }

            @Override
            public void onError(Throwable e) {
            }

            @Override
            public void onComplete() {
                LogUtil.p("");
            }
        });

执行顺序：（括号内数字表示线程id）
doOnsubscribe(1) -> onSubscribe(1) -> call(276) ->doOnNext(1)->onNext(1) -> doAfterNext(1) ->doOnComplete(1)->onComplete(1)
所以基本上可以认为doOnXXX= doBeforeXXX,线程都是一样的。估计是为了打日志用的，或者说用于切片。
像极了OkHttp的interecpter或是gradle的task。

```




## 5. Operator and Threading
```java
Observable<String> greeting  = Observable.just("Hello");
Observable<String> yelling = greeting.map(s ->s.toUppercase())

Observable.subscribeOn(Schedulers.io()) //
```
subscribeOn决定了task在哪条线程上运行，操作符的顺序很重要
![Wrong](http://odzl05jxx.bkt.clouddn.com/reading%20network%20response%20on%20main%20thread.jpg?imageView2/2/w/600)
![Ok](http://odzl05jxx.bkt.clouddn.com/observing%20on%20ui%20thred.jpg?imageView2/2/w/600)


流之间的转换

>Observable -> first() -> single
Observable -> firsetElement -> Maybe
Observable -> ignoreElements() ->Completable

>Flowable -> first() -> single
Flowable -> firsetElement -> Maybe
Flowable -> ignoreElements() ->Completable

- [Combining Observables](https://github.com/ReactiveX/RxJava/wiki/Combining-Observables) 多个数据来源的加工


### updates: 复制一些实例
merge():
```java
// 用于存放最终展示的数据
        String result = "数据源来自 = " ;

        /*
         * 设置第1个Observable：通过网络获取数据
         * 此处仅作网络请求的模拟
         **/
        Observable<String> network = Observable.just("网络");

        /*
         * 设置第2个Observable：通过本地文件获取数据
         * 此处仅作本地文件请求的模拟
         **/
        Observable<String> file = Observable.just("本地文件");


        /*
         * 通过merge（）合并事件 & 同时发送事件
         **/
        Observable.merge(network, file)
                .subscribe(new Observer<String>() {
                    @Override
                    public void onSubscribe(Disposable d) {

                    }

                    @Override
                    public void onNext(String value) {
                        Log.d(TAG, "数据源有： "+ value  );
                        result += value + "+";
                    }

                    @Override
                    public void onError(Throwable e) {
                        Log.d(TAG, "对Error事件作出响应");
                    }

                    // 接收合并事件后，统一展示
                    @Override
                    public void onComplete() {
                        Log.d(TAG, "获取数据完成");
                        Log.d(TAG,  result  );
                    }
                });
```
zip()，比如要同时拉两个接口
```java
public class MainActivity extends AppCompatActivity {


        private static final String TAG = "Rxjava";


        // 定义Observable接口类型的网络请求对象
        Observable<Translation1> observable1;
        Observable<Translation2> observable2;

        @Override
        protected void onCreate(Bundle savedInstanceState) {
            super.onCreate(savedInstanceState);
            setContentView(R.layout.activity_main);

            // 步骤1：创建Retrofit对象
            Retrofit retrofit = new Retrofit.Builder()
                    .baseUrl("http://fy.iciba.com/") // 设置 网络请求 Url
                    .addConverterFactory(GsonConverterFactory.create()) //设置使用Gson解析(记得加入依赖)
                    .addCallAdapterFactory(RxJava2CallAdapterFactory.create()) // 支持RxJava
                    .build();

            // 步骤2：创建 网络请求接口 的实例
            GetRequest_Interface request = retrofit.create(GetRequest_Interface.class);

            // 步骤3：采用Observable<...>形式 对 2个网络请求 进行封装
            observable1 = request.getCall().subscribeOn(Schedulers.io()); // 新开线程进行网络请求1
            observable2 = request.getCall_2().subscribeOn(Schedulers.io());// 新开线程进行网络请求2
            // 即2个网络请求异步 & 同时发送

            // 步骤4：通过使用Zip（）对两个网络请求进行合并再发送
            Observable.zip(observable1, observable2,
                    new BiFunction<Translation1, Translation2, String>() {
                        // 注：创建BiFunction对象传入的第3个参数 = 合并后数据的数据类型
                        @Override
                        public String apply(Translation1 translation1,
                                            Translation2 translation2) throws Exception {
                            return translation1.show() + " & " +translation2.show();
                        }
                    }).observeOn(AndroidSchedulers.mainThread()) // 在主线程接收 & 处理数据
                    .subscribe(new Consumer<String>() {
                        // 成功返回数据时调用
                        @Override
                        public void accept(String combine_infro) throws Exception {
                            // 结合显示2个网络请求的数据结果
                            Log.d(TAG, "最终接收到的数据是：" + combine_infro);
                        }
                    }, new Consumer<Throwable>() {
                        // 网络请求错误时调用
                        @Override
                        public void accept(Throwable throwable) throws Exception {
                            System.out.println("登录失败");
                        }
                    });
        }
}
```



## 链式调用每一步都生成了新的object，Rxjava2和Rxjava1相比，对GC更加友好。
## quote:
### RxJava 2 is not something new. Reactive programming is not new by any stretch, but Android itself is a highly reactive world that we’ve been taught to model in a very imperative, stateful fashion.
Reactive programming allow us to model it in the proper way: asynchronously. Embrace the asynchronicity of the sources, and instead of trying to manage all the state ourselves, compose them together such that our apps become truly reactive.

## updates:
### How about Error Handling ?
[Error handling in RxJava](http://blog.danlew.net/2015/12/08/error-handling-in-rxjava/)



### Reference

-- [GOTO 2016 • Exploring RxJava 2 for Android • Jake Wharton - YouTube](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=6&cad=rja&uact=8&ved=0ahUKEwjlvrfg8bnTAhUI0mMKHcXZC1MQtwIITDAF&url=https%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3DhtIXKI5gOQU&usg=AFQjCNEYczqXGkjYXOUbovtP1CxDPARcXA&sig2=gmLYEd2cVOhI7C2WjOHr9g)
-- [掘金](https://juejin.im/entry/5a025b3b51882561a3265bb7)
-- [使用concat从数据库，内存，网络三层中获取数据](http://www.jianshu.com/p/6f3b6b934787)
