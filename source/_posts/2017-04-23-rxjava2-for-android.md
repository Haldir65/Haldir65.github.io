---
title: Rxjava2 的一些点
date: 2017-04-23 13:56:07
categories: blog
tags: [rxjava2,android]
---

本文多数内容来自Jake Wharton的演讲，配合一些个人的感受，作为今后使用Rxjava2的一些参考。
![](https://www.haldir66.ga/static/imgs/f21a6a245edfe0b19804be5b3df24a3d.jpg)
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
![](https://www.haldir66.ga/static/imgs/stream_compose.jpg)

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
两者的区别在于最后一个方法，以Disposable为例，当你开始subscribe一个数据源的时，就类似于创建了一个Resurce，而Resource是往往需要在用完之后及时释放。无论是Observable还是Flowable,这个onSubscribe方法会在订阅后立即被调用，这个方法里的Disposable可以保留下来，在必要时候用于释放资源。如Activity的onDestroy中cancel network request.


### 2.2 数据源的对应类
**Single** (订阅一个Single，要么获得仅一个返回值，要么出现异常返回Error)
```java
public abstract class Single<T> implements SingleSource<T> {}
```

**Completeable** (订阅一个completeable，要么成功，不返回值，要么出现异常返回error，就像一个reactive runnale，一个可以执行的command，并不返回结果)
```java
public abstract class Completable implements CompletableSource {}
```
例如，异步写一个文件，要么成功，要么出现error，并不需要返回什么。
```java
public void writeFile(Stirng data){}
// 就可以model成
Completeable writeFile(Stirng data){}
```


**Maybe** (有可能返回值，有可能不返回，也有可能异常，即optional)
```java
public abstract class Maybe<T> implements MaybeSource<T> {}
```
以上三种数据源都有static方法生成：
例如
![from iterable](https://www.haldir66.ga/static/imgs/creating_source_from_iterable.jpg)


![fromjust](https://www.haldir66.ga/static/imgs/creating_source_from_just.jpg)

比较推荐的方法有两种

### 一. fromCallable
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

### 二. create(Rxjava 1中不推荐使用该方法，Rxjava2中建议使用)
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

**一个Observable可以有多个subscriber。一个被观察者可以有多个观察者，被观察者的onNext调用，观察者的onNext也会被调用**

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
    public void  onResponse(Response r) throws IOException{
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

// 和fromCallable一样，create方法也适用于所有五种data source
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
![](https://www.haldir66.ga/static/imgs/4dab298b9f7ce29c43f9d8eaf686e02f.jpg)
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


  // 可以持有DisposableObserver，在停止订阅的时候调用observer.dispose方法，切断流。
  // 或者这样
  Disposable disposable =  Observable.just("Hello").subscribeWith(new DisposableObserver<String>() {
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

  //  subscribeWith返回一个Disposable，subscribe是一个没有返回值的函数    
  // 偷懒一点的话，通常把这些返回的订阅加入到一个CompositeDisposable,在onDestroy的时候统一取消订阅即可  
  // Observable、Single、Completeable、Maybe以及Flowable都支持subscribewith。
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

// 执行顺序：（括号内数字表示线程id）
// doOnsubscribe(1) -> onSubscribe(1) -> call(276) ->doOnNext(1)->onNext(1) -> doAfterNext(1) ->doOnComplete(1)->onComplete(1)
// 所以基本上可以认为doOnXXX= doBeforeXXX,线程都是一样的。估计是为了打日志用的，或者说用于切片。
// 像极了OkHttp的interecpter或是gradle的task。

```




## 5. Operator and Threading
```java
Observable<String> greeting  = Observable.just("Hello");
Observable<String> yelling = greeting.map(s ->s.toUppercase())

Observable.subscribeOn(Schedulers.io()) //
```
subscribeOn决定了task在哪条线程上运行，操作符的顺序很重要
**this is wrong**
![Wrong](https://www.haldir66.ga/static/imgs/reading_network_response_on_main_thread.jpg)

**this is right**
![Ok](https://www.haldir66.ga/static/imgs/observing_on_ui_thread.jpg)


流之间的转换

>Observable -> first() -> single
Observable -> firsetElement -> Maybe
Observable -> ignoreElements() ->Completable

>Flowable -> first() -> single
Flowable -> firsetElement -> Maybe
Flowable -> ignoreElements() ->Completable

- [Combining Observables](https://github.com/ReactiveX/RxJava/wiki/Combining-Observables) 多个数据来源的加工


### updates: 复制一些实例
**merge():**
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
**zip()** ，比如要同时拉两个接口
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

replay操作符：一个source先创建，发送了3个事件后，有一个subscriber才开始subscribe，这时会把之前的3个事件和之后的陆续事件都丢给subscriber。



## 链式调用每一步都生成了新的object，Rxjava2和Rxjava1相比，对GC更加友好。
## quote:
### RxJava 2 is not something new. Reactive programming is not new by any stretch, but Android itself is a highly reactive world that we’ve been taught to model in a very imperative, stateful fashion.
Reactive programming allow us to model it in the proper way: asynchronously. Embrace the asynchronicity of the sources, and instead of trying to manage all the state ourselves, compose them together such that our apps become truly reactive.

## updates:
### How about Error Handling ?
[Error handling in RxJava](http://blog.danlew.net/2015/12/08/error-handling-in-rxjava/)


Rxjava2中的Subscriber是遵循reactive stream这个项目中的规范的，后者提供了backpressure支持
observable(事实上是observableSource)  -> observer 
Flowable(publisher接口)  ->  Subscriber
[what-is-the-difference-between-an-observer-and-a-subscriber](https://stackoverflow.com/questions/27664221/what-is-the-difference-between-an-observer-and-a-subscriber)

java还有这种写法
```java
PublishSubject.<T>create()
```

Flowable中默认的bufferSize是128，这个是在源码中定义的:
Flowable.bufferSize()方法默认返回的就是128

MissingBackpressureException和BufferOverFlowException应该是不一样的

在相同的一条线程中，是不存在背压的问题的，不同线程之间的消费者和生产者之间可能产生背压问题。
就算消费者线程中不写Thread.sleep()也是有可能出现MissingBackPressureException。

Flowable这种直接遵循上游响应下游request请求才发送数据
```js
     var sp5:Subscription?= null

        btn5.setOnClickListener {
            Flowable.create<String>({emitter ->
                for(i in 0..1000){
                    emitter.onNext(i.toString())
                    LogUtil.e(TAG,"send down message $i")
                }
                emitter.onComplete()
            },BackpressureStrategy.BUFFER)
                    .subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread())
                    .subscribe(object :FlowableSubscriber<String>{
                        override fun onComplete() {
                            LogUtil.e(TAG,"OnComplete called ")
                        }

                        override fun onSubscribe(s: Subscription) {
                            sp5 = s
                            sp5?.request(1)
                        }

                        override fun onNext(t: String?) {
                            LogUtil.e(TAG,"receive message $t")
                            Thread.sleep(100)
                            sp5?.request(1)

                        }

                        override fun onError(t: Throwable?) {
                            LogUtil.e(TAG,t?.message)
                        }

                    })
        }
```

Flowable.fromPublisher()方法接受一个Publisher参数，但是但是但是
> Note that even though Publisher appears to be a functional interface, it is not recommended to implement it through a lambda as the specification requires state management that is not achievable with a stateless lambda.


## rxjava线程切换的原理
[线程切换的原理以及subscribeOn只能用一次的原因](https://www.jianshu.com/p/a9ebf730cd08)
Observable.observeOn()
```java
@CheckReturnValue
@SchedulerSupport(SchedulerSupport.CUSTOM)
public final Observable<T> observeOn(Scheduler scheduler, boolean delayError, int bufferSize) {
    ObjectHelper.requireNonNull(scheduler, "scheduler is null");
    ObjectHelper.verifyPositive(bufferSize, "bufferSize");
    return RxJavaPlugins.onAssembly(new ObservableObserveOn<T>(this, scheduler, delayError, bufferSize)); 
}
```
observeOn方法实际返回了一个ObservableObserveOn实例。外部调用subscribe -> ObservableObserveOn.subScribeActual -> 上游source.subscribe(new ObserveOnObserver<T>(observer, w, delayError, bufferSize))，这个observer是外部调用者写的，等于说这个ObserveOnObserver是上游（actual）和下游(开发者写的observer)之间的桥梁，在收到上游onNext的时候会最终走到
NewThreadWorker.scheduleDirect
```java
  @NonNull
    public ScheduledRunnable scheduleActual(final Runnable run, long delayTime, @NonNull TimeUnit unit, @Nullable DisposableContainer parent) {
        // ...
        ScheduledRunnable sr = new ScheduledRunnable(decoratedRun, parent);
        Future<?> f;
        try {
            if (delayTime <= 0) {
                f = executor.submit((Callable<Object>)sr);
            } else {
                f = executor.schedule((Callable<Object>)sr, delayTime, unit);
            }
            sr.setFuture(f);
        } catch (RejectedExecutionException ex) {
          //....
        }
        return sr;
    }
```
返回了一个ScheduledRunnable,里面包装了一个Future。往executor提交了task之后，task的run方法将被执行，也就是ScheduledRunnable的run方法
```java
 @Override
    public void run() {
        lazySet(THREAD_INDEX, Thread.currentThread());
        try {
            try {
                actual.run();
            } catch (Throwable e) {
                // Exceptions.throwIfFatal(e); nowhere to go
                RxJavaPlugins.onError(e);
            }
        } finally {
            //...
            if (o != PARENT_DISPOSED && compareAndSet(PARENT_INDEX, o, DONE) && o != null) {
                ((DisposableContainer)o).delete(this);
            }
            for (;;) {
                o = get(FUTURE_INDEX);
                if (o == SYNC_DISPOSED || o == ASYNC_DISPOSED || compareAndSet(FUTURE_INDEX, o, DONE)) {
                    break;//判断当前处于DONE的状态的话就可以跳出循环
                }
            }
        }
    }
```


回头看ObserveOnObserver 的创建，

```java
new ObservableObserveOn<T>(this, scheduler, delayError, bufferSize));//这个this是Observable
```
接下来开始subScribe -> subScribeActual
```java
  @Override
    protected void subscribeActual(Observer<? super T> observer) {
        if (scheduler instanceof TrampolineScheduler) {
            source.subscribe(observer);
        } else {
            Scheduler.Worker w = scheduler.createWorker();
            source.subscribe(new ObserveOnObserver<T>(observer, w, delayError, bufferSize)); //这个source就是上面的Observable。这个ObserveOnObserver就像我们平时写的Observer一样，有onNext,onComplete,onError等
        }
    }

//下面是ObserveOnObserver的构造函数
ObserveOnObserver(Observer<? super T> actual, Scheduler.Worker worker, boolean delayError, int bufferSize) {
        this.actual = actual;
        this.worker = worker;
        this.delayError = delayError;
        this.bufferSize = bufferSize;
    }

 @Override
public void onNext(T t) {
    if (done) {
        return;
    }
     if (sourceMode != QueueDisposable.ASYNC) {
        queue.offer(t); //这里，把上游的数据存进queue
    }
    schedule();
}  

void schedule() {
        if (getAndIncrement() == 0) {
            worker.schedule(this); //显然这个this是一个runnable
        }
    }

@Override
public void run() {
    if (outputFused) {
        drainFused();
    } else {
        drainNormal();
    }
}   

//一个for循环
 void drainNormal() {
     //
                for (;;) {
                    boolean d = done;
                    T v;

                    try {
                        v = q.poll();
                    } catch (Throwable ex) {
                        // ..                        
                    }
                    //..
                    a.onNext(v);
                }
        }
```
整理一下，上游的Observable发出OnNext的时候，ObserveOnObserver开始schedule,**也就是通过worker.schedule将任务调度到新的线程**。新的线程运行run方法中for循环从queue中查找result。ObserveOnObserver就是在onNext中接收到上游数据，存到queue里面之后，调度另一条线程去跑一个run方法，该方法会去drain这个queue，也就是取出刚才放进去的数据

### SubscribeOn也是类似的道理
SubscribeOn返回了一个ObservableSubscribeOn实例
ObservableSubscribeOn
```java
   @Override
    public void subscribeActual(final Observer<? super T> s) {
        final SubscribeOnObserver<T> parent = new SubscribeOnObserver<T>(s);
        s.onSubscribe(parent);
        parent.setDisposable(scheduler.scheduleDirect(new SubscribeTask(parent))); //scheduleDirect就是把task丢到scheduler的线程
    }
```

顺便提一下
io.reactivex.schedulers.Schedulers
典型的线程安全单例模式
```java
  static final class SingleHolder {
        static final Scheduler DEFAULT = new SingleScheduler();
    }

    static final class ComputationHolder {
        static final Scheduler DEFAULT = new ComputationScheduler();
    }

    static final class IoHolder {
        static final Scheduler DEFAULT = new IoScheduler();
    }

    static final class NewThreadHolder {
        static final Scheduler DEFAULT = new NewThreadScheduler();
    }
```
这些Scheduler都继承Scheduler这个abstract class
```java
 @NonNull
    public abstract Worker createWorker();
```

Schedulers.io()  ---> io.reactivex.internal.schedulers.IoScheduler //尽量cache,忙不过来的话创建新的线程
Schedulers.computation() io.reactivex.internal.schedulers.ComputationScheduler //只是维持了cpu核心数以内的线程，有任务来的时候round-robin


```java
/**
 * Holds a fixed pool of worker threads and assigns them
 * to requested Scheduler.Workers in a round-robin fashion.
 */
public final class ComputationScheduler extends Scheduler implements SchedulerMultiWorkerSupport {
      private static final String THREAD_NAME_PREFIX = "RxComputationThreadPool"; //这个熟悉的字眼
   
   
    @NonNull
    @Override
    public Worker createWorker() {
        return new EventLoopWorker(pool.get().getEventLoop());
    }
}

/**
 * Scheduler that creates and caches a set of thread pools and reuses them if possible.
 */
public final class IoScheduler extends Scheduler {
     @NonNull
    @Override
    public Worker createWorker() {
        return new EventLoopWorker(pool.get());
    }
}

//EventLoopWorker实际上代理了PoolWorker（继承NewThreadWorker）的工作

public class NewThreadWorker extends Scheduler.Worker implements Disposable {
    private final ScheduledExecutorService executor; //有一个scheduleAtFixedRate的功能可以拿来做定时任务

    volatile boolean disposed;

    public NewThreadWorker(ThreadFactory threadFactory) {
        executor = SchedulerPoolFactory.create(threadFactory); 
    }

}
```

## 为什么多个subscribeOn没有卵用
就是下面这种
```java
 Observable.just(1)
                .map(new Function<Integer, Integer>() {
                    @Override
                    public Integer apply(@NonNull Integer integer) throws Exception {
                        Log.i(TAG, "map-1:"+Thread.currentThread().getName()); //实际运行在RxNewThreadScheduler-1上
                        return integer;
                    }
                })
                .subscribeOn(Schedulers.newThread())
                .map(new Function<Integer, Integer>() {
                    @Override
                    public Integer apply(@NonNull Integer integer) throws Exception {
                        Log.i(TAG, "map-2:"+Thread.currentThread().getName());//实际运行在RxNewThreadScheduler-1上
                        return integer;
                    }
                })
                .subscribeOn(Schedulers.io())
                .map(new Function<Integer, Integer>() {
                    @Override
                    public Integer apply(@NonNull Integer integer) throws Exception {
                        Log.i(TAG, "map-3:"+Thread.currentThread().getName());//实际运行在RxNewThreadScheduler-1上
                        return integer;
                    }
                })
                .subscribeOn(AndroidSchedulers.mainThread())
                .subscribe(new Consumer<Integer>() {
                    @Override
                    public void accept(@NonNull Integer integer) throws Exception {
                        Log.i(TAG, "subscribe:"+Thread.currentThread().getName());//实际运行在RxNewThreadScheduler-1上
                    }
                });
```
官方文档这么说的：
>the SubscribeOn operator designates which thread the Observable will begin operating on, no matter at what point in the chain of operators that operator is called. ObserveOn, on the other hand, affects the thread that the Observable will use below where that operator appears. For this reason, you may call ObserveOn multiple times at various points during the chain of Observable operators in order to change on which threads certain of those operators operate.

subScribeOn返回的是ObservableSubscribeOn
它的subscribeActual里面主要做了这件事
```java
scheduler.scheduleDirect(new SubscribeTask(parent)) //parent是自己包装的一个Observer,SubscribeTask的run方法就是upstream.subScribe(parent)，大致如此
```
ObservableSubscribeOn.subScribe会调用到ObservableSubscribeOn.subscribeActual ---> 调来调去回到SubscribeTask 的 run()，它又开始往上去订阅(subScribeActual)，如此循环到第一个位置

上层事件发生时，会一步步地调用actual.onNext -> actual.onNext...这些actual的连接都是在上面几个不同的线程中连接上的。只是事件发生时，没有走线程调度，直接从第一个scheduler的线程开始运行这段链条状的onNext调用，所以也就只有第一次subScribeOn有用了





### Reference

-- [GOTO 2016 • Exploring RxJava 2 for Android • Jake Wharton - YouTube](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=6&cad=rja&uact=8&ved=0ahUKEwjlvrfg8bnTAhUI0mMKHcXZC1MQtwIITDAF&url=https%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3DhtIXKI5gOQU&usg=AFQjCNEYczqXGkjYXOUbovtP1CxDPARcXA&sig2=gmLYEd2cVOhI7C2WjOHr9g)
-- [掘金](https://juejin.im/entry/5a025b3b51882561a3265bb7)
-- [使用concat从数据库，内存，网络三层中获取数据](http://www.jianshu.com/p/6f3b6b934787)
-- [RxJava 教程第四部分：并发 之数据流发射太快如何办](http://blog.chengyunfeng.com/?p=981)


- [rxjava2操作符详解](https://maxwell-nc.github.io/android/rxjava2-6.html)