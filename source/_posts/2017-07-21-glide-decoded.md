---
title: 从glide源码到图片加载框架设计思路
date: 2017-07-21 00:13:02
tags: [android]
---

glide的源码几个月前曾经拜读过，大致了解了其异步加载的实现原理。图片加载和网络请求很类似，就像当初看Volley，从一个Request --->  CacheDispatch  ---> NetworkDispatcher  ---->  ResponseDeliver。优秀的轮子不仅执行效率高，同时具备高的扩展性。读懂源码其实只是第一步，往下应该是利用框架提供的扩展方案，再往后应该就是能够独立设计出一套类似的框架了。
写这篇文章时，Glide的版本是3.8


![](https://api1.reindeer36.shop/static/imgs/a11f41e0b1df95212c71920b3959cd72.jpg)
<!--more-->

## 1. 使用入门
印象中最早接触Glide是在cheesequare中，顿时发现，原来加载图片可以这么简单，之后的开发过程中总会对Glide有所偏倚。接近两年之后再来过一遍源码，希望能够回答那个“如果让你来设计一个图片加载框架，你会怎么设计？”的问题。
使用方式很简单

```java
  Glide.with(activity)
                .load(R.drawable.image_id)
                .into(mImageView);

```

来看这里面做了什么：

```java
       public RequestManager get(FragmentActivity activity) {
        if (Util.isOnBackgroundThread()) {
            return get(activity.getApplicationContext());
        } else {
            assertNotDestroyed(activity);
            FragmentManager fm = activity.getSupportFragmentManager();
            return supportFragmentGet(activity, fm);
        }
    }


    SupportRequestManagerFragment getSupportRequestManagerFragment(final FragmentManager fm) {
        SupportRequestManagerFragment current = (SupportRequestManagerFragment) fm.findFragmentByTag(
            FRAGMENT_TAG);
        if (current == null) {
            current = pendingSupportRequestManagerFragments.get(fm);
            if (current == null) {
                current = new SupportRequestManagerFragment();
                pendingSupportRequestManagerFragments.put(fm, current);
                fm.beginTransaction().add(current, FRAGMENT_TAG).commitAllowingStateLoss();
                handler.obtainMessage(ID_REMOVE_SUPPORT_FRAGMENT_MANAGER, fm).sendToTarget();
            }
        }
        return current;
    }

```

with方法只是返回了一个RequestManager，with方法可以接受Fragment,Activity以及Context等.以上面的activity为例，supportFragmentGet方法只是通过FragmentActivity的supportFragmentManager去findFragmentByTag，这个Tag叫做：“com.bumptech.glide.manager”，所以一般在Debug的时候，去SupportFragmentManager里面查找，有时候能够看到一个这样的Fragment。这个方法里面就是查找这样的一个Fragment，甚至我们自己也可以FindFragmentByTag去调用这个Fragment的方法(这是一个Public的class)然后从这个Fragment里面获得RequestManager成员变量（没有就new一个并set）。可以看出，一个Fragment只有一个RequestManager，Fragment主要是为了跟Activity生命周期挂钩的。这里有必要讲一下为什么要写两次current ==null，findFragmentByTag并不会在commitAllowingStateLoss之后就会返回添加的Fragment，只是往主线程的MessageQueue里面丢了一个消息，这个消息执行完毕之后才findFragmentByTag才不为空。这里用Handler丢一条消息，这条消息肯定要排在之前那条消息之后才被执行，所以才有这样一个Pendingmap的设计。当然到这里，最重要的还是Glide是通过commit了一个特殊的Fragment来实现生命周期监听。
具体来看：SupportRequestManagerFragment中

```java
  @Override
    public void onStart() {
        super.onStart();
        lifecycle.onStart();
    }

    @Override
    public void onStop() {
        super.onStop();
        lifecycle.onStop();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        lifecycle.onDestroy();
    }
```

而对应到LifeCycle的各个方法：

```java
 void onStart() {
        isStarted = true;
        for (LifecycleListener lifecycleListener : Util.getSnapshot(lifecycleListeners)) {
            lifecycleListener.onStart();
        }
    }

    void onStop() {
        isStarted = false;
        for (LifecycleListener lifecycleListener : Util.getSnapshot(lifecycleListeners)) {
            lifecycleListener.onStop();
        }
    }

    void onDestroy() {
        isDestroyed = true;
        for (LifecycleListener lifecycleListener : Util.getSnapshot(lifecycleListeners)) {
            lifecycleListener.onDestroy();
        }
    }
```
就是把内部维护的一个集合一个个拿出来调用响应生命周期的方法。
而这个LifeCycleListener就是上面创建RequestManager时(构造函数传进来了fragment的lifeCycle)添加的。RequestManager还默认添加了一个ConnectivityMonitor，主要作用就是在生命周期的onStart注册了一个ConnectivityManager.CONNECTIVITY_ACTION的BroadCastReceiver，在onStop的时候unRegister，在网络状态变化的时候调用RequestManager的RequestTracker成员变量的restartRequet。


小结：
- 在有权限(android.permission.ACCESS_NETWORK_STATE)的情况下，Glide已经做好了有网-> 断网-> 有网的恢复请求。另外，Android 7.0虽说不再发送ConnectivityManager.CONNECTIVITY_ACTION这个广播，但对于前台应用，动态注册的Receiver还是能够收到，Glide由于是在OnStart注册的，所以完全没问题。
- 在一个Activity中，RequestManager只要一个，其实开发者自己保留下来也没什么问题


## 2. RequestManager调度请求

来看下这个RequestManager的成员变量

```java
public class RequestManager implements LifecycleListener {
    private final Context context;
    private final Lifecycle lifecycle;
    private final RequestManagerTreeNode treeNode;
    private final RequestTracker requestTracker;
    private final Glide glide; //全局只有一个，控制线程池，用Application的Context创建的
    private final OptionsApplier optionsApplier;
    private DefaultOptions options;

    }


    class OptionsApplier {

        public <A, X extends GenericRequestBuilder<A, ?, ?, ?>> X apply(X builder) {
            if (options != null) {
                options.apply(builder);
            }
            return builder;
        }
    }

```
上面这个泛型写的非常绕，OptionApplier的意思就是，如果用户提供了一些定制(存在options里面)，就给一些定制的选择。一般这个options为null。




### 2.1 各种Type的Request

Glide的RequestManager可以接受各种各样的来源

```java
   public DrawableTypeRequest<Integer> load(Integer resourceId) {
        return (DrawableTypeRequest<Integer>) fromResource().load(resourceId);
    }

     public DrawableTypeRequest<byte[]> load(byte[] model) {
        return (DrawableTypeRequest<byte[]>) fromBytes().load(model);
    }

      public DrawableTypeRequest<File> load(File file) {
        return (DrawableTypeRequest<File>) fromFile().load(file);
    }

//上述方法都调用到了
     private <T> DrawableTypeRequest<T> loadGeneric(Class<T> modelClass) {
        ModelLoader<T, InputStream> streamModelLoader = Glide.buildStreamModelLoader(modelClass, context);
        ModelLoader<T, ParcelFileDescriptor> fileDescriptorModelLoader =
                Glide.buildFileDescriptorModelLoader(modelClass, context);
        if (modelClass != null && streamModelLoader == null && fileDescriptorModelLoader == null) {
            throw new IllegalArgumentException("Unknown type " + modelClass + ". You must provide a Model of a type for"
                    + " which there is a registered ModelLoader, if you are using a custom model, you must first call"
                    + " Glide#register with a ModelLoaderFactory for your custom model class");
        }

        return optionsApplier.apply(
                new DrawableTypeRequest<T>(modelClass, streamModelLoader, fileDescriptorModelLoader, context,
                        glide, requestTracker, lifecycle, optionsApplier));
    }

```

DrawableTypeRequest接受一个泛型，可以是String(网络路径)，File(本地文件),Integer（资源文件）。所以最终返回的DrawableTypeRequet里面装的可能是String.class，Integer.class也可能是File.class。
比较难懂的是 streamModelLoader和fileDescriptorModelLoader的创建.

```java
public interface ModelLoader<T, Y> {
    DataFetcher<Y> getResourceFetcher(T model, int width, int height);
}
```
ModelLoader其实就是只有一个方法的接口，例如with(File)会传一个File.class进来，返回的streamModelLoader的T就是File，Y就是InputStream。
ModelLoader<T, Y>负责提供DataFetcher<Y>，T是数据源，可以是File,Resourse，url等等。Y用于描述类型，本地的就使用ParcelFileDescriptor（记得FileDescriptor属于Native的东西），网络上的就使用InputStream.
T和Y的组合可能有很多种，Cache在Glide(全局唯一)的loaderFactory（成员变量）的一个HashMap(没用ConcurrentHashMap是因为buildModelLoader方法加锁了)中。所以这份缓存也是全局唯一的。
T和Y的一一对应其实是在Glide的构造函数里面写好的：

```java

        register(File.class, ParcelFileDescriptor.class, new FileDescriptorFileLoader.Factory());
        register(File.class, InputStream.class, new StreamFileLoader.Factory());
        register(int.class, ParcelFileDescriptor.class, new FileDescriptorResourceLoader.Factory());
        register(int.class, InputStream.class, new StreamResourceLoader.Factory());
        register(Integer.class, ParcelFileDescriptor.class, new FileDescriptorResourceLoader.Factory());
        register(Integer.class, InputStream.class, new StreamResourceLoader.Factory());
        register(String.class, ParcelFileDescriptor.class, new FileDescriptorStringLoader.Factory());
        register(String.class, InputStream.class, new StreamStringLoader.Factory());
        register(Uri.class, ParcelFileDescriptor.class, new FileDescriptorUriLoader.Factory());
        register(Uri.class, InputStream.class, new StreamUriLoader.Factory());
        register(URL.class, InputStream.class, new StreamUrlLoader.Factory());
        register(GlideUrl.class, InputStream.class, new HttpUrlGlideUrlLoader.Factory());
        register(byte[].class, InputStream.class, new StreamByteArrayLoader.Factory());
```
左边有很多种，右边只可能是InputStream或者ParcelFileDescriptor。

### 2.2 Request的继承关系

```
 public class DrawableTypeRequest<ModelType> extends DrawableRequestBuilder<ModelType> implements DownloadOptions
 public class DrawableRequestBuilder<ModelType>
        extends GenericRequestBuilder<ModelType, ImageVideoWrapper, GifBitmapWrapper, GlideDrawable>
        implements BitmapOptions, DrawableOptions
 public class GenericRequestBuilder<ModelType, DataType, ResourceType, TranscodeType> implements Cloneable        
```

记住这个ModelType就是Glide.with(context).load(XXX) 里面传进去的Object的Class，例如File.class，那么
上面其实就是创建了一个DrawableTypeRequest，泛型是File ，构造函数一层层往上调用，DrawableRequestBuilder这一层调用了crossFade方法，即默认会有一个crossFade的效果，默认用的是DrawableCrossFadeFactory。注意这里把属于RequestManager的RequestTracker也传进来了。
- Glide.with(context).load(XX)到目前为止只是返回了一个DrawableTypeRequest<ModelType> 的实例。(还在主线程)

## 2.3 小结
Glide.with返回一个RequestManger，每个Activity只会有一个RequestManager
load方法返回了一个DrawableTypeRequest<T>，这个T可能是File,String,Interger等。
到目前为止还只是构建一个Request。

## 3. DrawableRequestBuilder的into方法
Glide的最后一个调用方法是into()，也是最终分发请求的方法

DrawableRequestBuilder
```java
 @Override
    public Target<GlideDrawable> into(ImageView view) {
        return super.into(view);
    }


    public Target<TranscodeType> into(ImageView view) {
        Util.assertMainThread();//还是在主线程对不对
        if (view == null) {
            throw new IllegalArgumentException("You must pass in a non null View");
        }

        if (!isTransformationSet && view.getScaleType() != null) {
            switch (view.getScaleType()) {
                case CENTER_CROP:
                    applyCenterCrop();
                    break;
                case FIT_CENTER:
                case FIT_START:
                case FIT_END:
                    applyFitCenter();
                    break;
                //$CASES-OMITTED$
                default:
                    // Do nothing.
            }
        }

        return into(glide.buildImageViewTarget(view, transcodeClass));
        //这个into接收一个Target的子类的实例，而Target又继承自LifeCycleListener
        //这个TranscodeClass是每一个Request创建的时候从构造函数传进来的。

    }


 //transcodeclass可能是GlideDrawable.class，也可能是Bitmap.class也可能是Drawable.class
     @SuppressWarnings("unchecked")
    public <Z> Target<Z> buildTarget(ImageView view, Class<Z> clazz) {
        if (GlideDrawable.class.isAssignableFrom(clazz)) { //isAssignableFrom表示左边的class是否是右边class一个类或者父类，应该和instaceof倒过来。
            return (Target<Z>) new GlideDrawableImageViewTarget(view);
        } else if (Bitmap.class.equals(clazz)) {
            return (Target<Z>) new BitmapImageViewTarget(view);
        } else if (Drawable.class.isAssignableFrom(clazz)) {
            return (Target<Z>) new DrawableImageViewTarget(view);
        } else {
            throw new IllegalArgumentException("Unhandled class: " + clazz
                    + ", try .as*(Class).transcode(ResourceTranscoder)");
        }
    }

```
GlideDrawableImageViewTarget、BitmapImageViewTarget以及DrawableImageViewTarget全部继承自ImageViewTarget，后者继承自ViewTarget,再继承自BaseTarget，再 implements Target。一层层继承下来，GlideDrawableImageViewTarget等三个子类中都有一个Request，一个T extents View(看来不一定是ImageView)



### 3.1 以GlideDrawableImageViewTarget为例
```java
public class GlideDrawableImageViewTarget extends ImageViewTarget<GlideDrawable> {
    private static final float SQUARE_RATIO_MARGIN = 0.05f;
    private int maxLoopCount;
    private GlideDrawable resource;
    }
```
GlideDrawable是一个继承自Drawable的抽象类，添加了isAnimated(),setLoopCount以及由于实现了isAnimated所需要的三个方法(start,stop,isRunning)。子类必须实现这五个抽象方法。

GlideDrawableImageViewTarget往上走
```java
public abstract class ImageViewTarget<Z> extends ViewTarget<ImageView, Z> implements GlideAnimation.ViewAdapter{

}
```

接着往上找父类

```java
public abstract class ViewTarget<T extends View, Z> extends BaseTarget<Z> {
    private static final String TAG = "ViewTarget";
    private static boolean isTagUsedAtLeastOnce = false;
    private static Integer tagId = null;

    protected final T view;
    private final SizeDeterminer sizeDeterminer;

}
```

看下文档：A base Target for loading android.graphics.Bitmaps into Views that provides default implementations for most most methods and can determine the size of views using a android.view.ViewTreeObserver.OnDrawListener
To detect View} reuse in android.widget.ListView or any android.view.ViewGroup that reuses views, this class uses the View setTag(Object) method to store some metadata so that if a view is reused, any previous loads or resources from previous loads can be cancelled or reused.
 Any calls to View setTag(Object)on a View given to this class will result in excessive allocations and
 and/or IllegalArgumentExceptions. If you must call View#setTag(Object)on a view, consider  using BaseTarget or SimpleTarget instead.

- 翻译一下，ViewTarget提供了将Bitmap 加载进View的大部分方法的基本实现，并且添加了onPreDrawListener以获得View的尺寸，对于Resuse View的场景，通过setTag来取消被滑出屏幕的View的request的加载。

既然提供了大部分方法的默认实现，那么一定有方法没实现，其实就是
protected void setResource(Z resource)啦。
这个Z可能是Bitmap,GlideDrawable或者Drawable。直接拿来setImageBitmap或者setImageDrawable就可以了，这个方法其实在是解码完成之后了。

关键是default implementation是怎么实现的以及这些方法在父类中的调用时机。
ViewTarget的构造函数传进来一个View的子类，同时创建一个SizeDeterminer（只是通过onPreDrawListener获得View的宽和高）。

再往上找父类
```java
public abstract class BaseTarget<Z> implements Target<Z> { //添加了一个Request成员变量，为Target中的一些方法提供了空实现，比如onLoadStarted，onLoadXXX等

    private Request request;

    }
```

到这里，还只是配置资源要加载进的对象，我倾向于把Target看成一个资源加载完毕的中转者，它管理了View（也可以没有View）和Request，在外部调用Target.onLoadStarted等方法是，调用View(如果有的话)的xxx方法。

### 3.2任务分发
```java
    public <Y extends Target<TranscodeType>> Y into(Y target) {
        Util.assertMainThread(); //还在主线程上
        Request previous = target.getRequest();

        if (previous != null) { //每一个Target都只有一个Request，用于清除之前的请求
            previous.clear();
            requestTracker.removeRequest(previous);
            previous.recycle();
        }

        Request request = buildRequest(target);
        target.setRequest(request);
        lifecycle.addListener(target);
        requestTracker.runRequest(request);

        return target; //这里返回Target的好处在于可以接着链式调用，上面只是添加到任务队列，真正被处理还得等到下一帧(onPreDraw调用时)，所以这里还可以接着对这个Target进行配置
    }
```
注意 requestTracker.runRequest(request)方法
GenericRequest.java
```java
  /**
     * {@inheritDoc}
     */
    @Override
    public void begin() {
        startTime = LogTime.getLogTime();
        if (model == null) {
            onException(null);
            return;
        }

        status = Status.WAITING_FOR_SIZE;
        if (Util.isValidDimensions(overrideWidth, overrideHeight)) {
            onSizeReady(overrideWidth, overrideHeight);
        } else {
            target.getSize(this); //这个方法其实就等于挂了个钩子在onPreDraw中调用，onPreDraw时会调用onSizeReady。
        }

        if (!isComplete() && !isFailed() && canNotifyStatusChanged()) {
            target.onLoadStarted(getPlaceholderDrawable());
        }
        if (Log.isLoggable(TAG, Log.VERBOSE)) {
            logV("finished run method in " + LogTime.getElapsedMillis(startTime));
        }
    }
```
onSizeReady才是真正开始干活的时机，理由也很充分。解码Bitmap必须要知道需要多大的尺寸，否则也是白搭。
GenericRequest.java
```java
   /**
     * A callback method that should never be invoked directly.
     */
    @Override
    public void onSizeReady(int width, int height) {

        if (status != Status.WAITING_FOR_SIZE) {
            return;
        }
        status = Status.RUNNING;

        width = Math.round(sizeMultiplier * width); //这个sizeMultiplier可以通过链式调用配置
        height = Math.round(sizeMultiplier * height);

        ModelLoader<A, T> modelLoader = loadProvider.getModelLoader();
        final DataFetcher<T> dataFetcher = modelLoader.getResourceFetcher(model, width, height);

        ResourceTranscoder<Z, R> transcoder = loadProvider.getTranscoder();
        loadedFromMemoryCache = true;
        loadStatus = engine.load(signature, width, height, dataFetcher, loadProvider, transformation, transcoder,
                priority, isMemoryCacheable, diskCacheStrategy, this);
        loadedFromMemoryCache = resource != null;
        if (Log.isLoggable(TAG, Log.VERBOSE)) {
            logV("finished onSizeReady in " + LogTime.getElapsedMillis(startTime));
        }
    }
```


### 3.3 缓存查找
开始查找缓存是engine.load开始的，找到了就调用Callback的onResourceReady
Engine.java
```java
    public <T, Z, R> LoadStatus load(Key signature, int width, int height, DataFetcher<T> fetcher,
            DataLoadProvider<T, Z> loadProvider, Transformation<Z> transformation, ResourceTranscoder<Z, R> transcoder,
            Priority priority, boolean isMemoryCacheable, DiskCacheStrategy diskCacheStrategy, ResourceCallback cb) {
        Util.assertMainThread(); //还是在主线程上
        long startTime = LogTime.getLogTime();

        final String id = fetcher.getId();//如果是个网络图片，返回网络url，类似这种
        EngineKey key = keyFactory.buildKey(id, signature, width, height, loadProvider.getCacheDecoder(),
                loadProvider.getSourceDecoder(), transformation, loadProvider.getEncoder(),
                transcoder, loadProvider.getSourceEncoder());

        EngineResource<?> cached = loadFromCache(key, isMemoryCacheable);
        //EngineResource内部wrap了真正的Resource，并使用一个int acquire表示当前正在占用资源的使用者数。当这个数为0的时候可以release。
        if (cached != null) {
            cb.onResourceReady(cached);
            if (Log.isLoggable(TAG, Log.VERBOSE)) {
                logWithTimeAndKey("Loaded resource from cache", startTime, key);
            }
            return null;
        }
        // 为什么在已经有了Cache这一层缓存之后，还要设置一个ActiveResources缓存。是因为loadFromCache里面调用了LinkedHashMap的remove方法，所以这种马上要用的资源当然要cache在另一份缓存里
        EngineResource<?> active = loadFromActiveResources(key, isMemoryCacheable);
        if (active != null) {
            cb.onResourceReady(active);
            if (Log.isLoggable(TAG, Log.VERBOSE)) {
                logWithTimeAndKey("Loaded resource from active resources", startTime, key);
            }
            return null;
        }

        EngineJob current = jobs.get(key);
        if (current != null) {
            current.addCallback(cb);
            if (Log.isLoggable(TAG, Log.VERBOSE)) {
                logWithTimeAndKey("Added to existing load", startTime, key);
            }
            return new LoadStatus(cb, current);
        }

        EngineJob engineJob = engineJobFactory.build(key, isMemoryCacheable);
        DecodeJob<T, Z, R> decodeJob = new DecodeJob<T, Z, R>(key, width, height, fetcher, loadProvider, transformation,
                transcoder, diskCacheProvider, diskCacheStrategy, priority);
        EngineRunnable runnable = new EngineRunnable(engineJob, decodeJob, priority);
        jobs.put(key, engineJob);
        engineJob.addCallback(cb);
        engineJob.start(runnable);

        if (Log.isLoggable(TAG, Log.VERBOSE)) {
            logWithTimeAndKey("Started new load", startTime, key);
        }
        return new LoadStatus(cb, engineJob);
    }
```

Engine先去Cache里面查找，找到了直接调用ResourceCallback(GenericRequest)的onResourceReady(EngineResource<?> resource)，注意这个EngineResource里面包装了一个Resource，主要是为了引用计数。

 Engine的loadFromCache(key, isMemoryCacheable)是第一步，从成员变量cache中获取。找到了就挪到activeResources里面。
 Engine.java
 ```java
 public class Engine implements EngineJobListener,
        MemoryCache.ResourceRemovedListener,
        EngineResource.ResourceListener {
    private static final String TAG = "Engine";
    private final Map<Key, EngineJob> jobs;
    private final EngineKeyFactory keyFactory;
    private final MemoryCache cache;
    private final EngineJobFactory engineJobFactory;
    private final Map<Key, WeakReference<EngineResource<?>>> activeResources;
    private final ResourceRecycler resourceRecycler;
    private final LazyDiskCacheProvider diskCacheProvider;

    

}
 ```
  
EngineResource<?> active = loadFromActiveResources(key, isMemoryCacheable); //4.8的glide是先从这个引用计数里面找
EngineResource<?> cached = loadFromCache(key, isMemoryCacheable); //然后再从com.bumptech.glide.util。LruCache这个类中找.


这个MemoryCache是一个LruCache，大小是在MemorySizeCalculator中获得的，
对于一般的设备，activityManager.getMemoryClass() * 1024 * 1024获得每个App能够使用的Size,乘以0.4。
```java
 MemorySizeCalculator(Context context, ActivityManager activityManager, ScreenDimensions screenDimensions) {
        this.context = context;
        final int maxSize = getMaxSize(activityManager);

        final int screenSize = screenDimensions.getWidthPixels() * screenDimensions.getHeightPixels()
                * BYTES_PER_ARGB_8888_PIXEL; //算出占满整个屏幕的一张图的大小

        int targetPoolSize = screenSize * BITMAP_POOL_TARGET_SCREENS; //乘以4就是bitmappool的大小
        int targetMemoryCacheSize = screenSize * MEMORY_CACHE_TARGET_SCREENS;
        //乘以2就是MemoryCache的大小

        if (targetMemoryCacheSize + targetPoolSize <= maxSize) {
            memoryCacheSize = targetMemoryCacheSize;
            bitmapPoolSize = targetPoolSize;
        } else { //这里判断了BitmapPool和MemoryCache的大小之和不能超出应用可以使用的内存大小的0.4倍。
            int part = Math.round((float) maxSize / (BITMAP_POOL_TARGET_SCREENS + MEMORY_CACHE_TARGET_SCREENS));
            memoryCacheSize = part * MEMORY_CACHE_TARGET_SCREENS;
            bitmapPoolSize = part * BITMAP_POOL_TARGET_SCREENS;
        }
    }
```
所以缓存的大小综合考虑了屏幕分辨率和内存大小。只要屏幕像素不是特别高，一般都会走到第一步。


```java
//setTag会崩的代码源头在ViewTarget里面,其实在into方法里面会调用到这里，主要是为了去检查previous
 @Override
  @Nullable
  public Request getRequest() {
    Object tag = getTag();
    Request request = null;
    if (tag != null) {
      if (tag instanceof Request) {
        request = (Request) tag;
      } else {
        throw new IllegalArgumentException(
            "You must not call setTag() on a view Glide is targeting");
      }
    }
    return request;
  }
```

### 小结
- ViewTarget里面有一个 T extends View，可见Glide不只适用于ImageView。
- BaseTarget里带了一个private Request，其子类可以通过getRequest获得。
- 对于ListView等可以快速滑动的View，如果某一个View被滑出屏幕外，自动取消请求(通过setTagId实现)
- "You must not call setTag() on a view Glide is targeting" setTag会崩，原因是GenericRequestBuilder的into方法会通过ViewTarget去查找previous，看看这一个ViewTarget是否已经有了request。这一点常见于循环利用View的场景，快速滑动的ViewGroup会复用View。对于同一个View，可能ViewGroup会需要它展示不同的(图片、Url)，所以Glide必须要检查previous，同时清除掉旧的请求。
- GenericRequestBuilder的obtainRequest内部使用了一个ArrayDeque来obtain Request。这样Request实例不会多次创建，回收是在request.recycle里面做的。



### 4. 离开主线程，提交任务到线程池
如果上面两层缓存都没找到，去jobs里找看下有没有已经加入队列的EngineJob
记住上面有两层缓存


来看后面提交任务这几段
```java
 EngineJob engineJob = engineJobFactory.build(key, isMemoryCacheable);
        DecodeJob<T, Z, R> decodeJob = new DecodeJob<T, Z, R>(key, width, height, fetcher, loadProvider, transformation,
                transcoder, diskCacheProvider, diskCacheStrategy, priority);
        EngineRunnable runnable = new EngineRunnable(engineJob, decodeJob, priority);
        jobs.put(key, engineJob);
        engineJob.addCallback(cb);
        engineJob.start(runnable); //往diskCacheService提交了一个Runnable

class EngineJob implements EngineRunnable.EngineRunnableManager {
    private static final EngineResourceFactory DEFAULT_FACTORY = new EngineResourceFactory();
    private static final Handler MAIN_THREAD_HANDLER = new Handler(Looper.getMainLooper(), new MainThreadCallback());

    private static final int MSG_COMPLETE = 1;
    private static final int MSG_EXCEPTION = 2;

    private final List<ResourceCallback> cbs = new ArrayList<ResourceCallback>();
    private final EngineResourceFactory engineResourceFactory;
    private final EngineJobListener listener;
    private final Key key;
    private final ExecutorService diskCacheService; //线程池
    private final ExecutorService sourceService; //线程池
    private final boolean isCacheable;

    private boolean isCancelled;
    // Either resource or exception (particularly exception) may be returned to us null, so use booleans to track if
    // we've received them instead of relying on them to be non-null. See issue #180.
    private Resource<?> resource;
    private boolean hasResource;
    private Exception exception;
    private boolean hasException;
    // A set of callbacks that are removed while we're notifying other callbacks of a change in status.
    private Set<ResourceCallback> ignoredCallbacks;
    private EngineRunnable engineRunnable;
    private EngineResource<?> engineResource;

    private volatile Future<?> future;
}


```
EngineJob是通过Factory创建的，创建时会传两个线程池进来。一个管DiskCache,一个管Source获取。初始化是在Glide.createGlide里面做的：
```java
if (sourceService == null) {
            final int cores = Math.max(1, Runtime.getRuntime().availableProcessors());
            sourceService = new FifoPriorityThreadPoolExecutor(cores);
        }
        if (diskCacheService == null) {
            diskCacheService = new FifoPriorityThreadPoolExecutor(1);
        }
```
在外部没有提供线程池的情况下，DiskCache一个线程池就好了，SourceService的大小为当前cpu可用核心数，还是比较高效的。
debug的时候可能会看见“fifo-pool-thread-1”这样的线程，就是Glide的。
上面是往DiskCacheService提交了一个EngineRunable，这个Runnable的run里面主要是decodeFromCache和DecodeFroSource，分别代表从**磁盘缓存**获取和从数据源获取。
首先会调用decodeFromCache，一层层往下找，如果没找到的话会调用onLoadFailed方法，并将任务提交给SourceService，去获取资源。


### 4.1 CacheService这个线程池的工作以及第三层缓存的出现
**注意这里出现了第三层缓存**
```
 File cacheFile = diskCacheProvider.getDiskCache().get(key);
```

这一层缓存是给DiskCache的线程池查找用的，查找的时候分为从Result中查找和从Source中查找，其实查找的目的地都是那个DiskCache，Resul是用ResultKey去找的，Source是用ResultKey.getOriginalKey去查找的。物理位置都放在那个磁盘目录下。

另外在DecodeJob的cacheAndDecodeSourceData方法里，存的只是origin(因为用的是origin Key)，然后再拿着originKey去磁盘找，找出来decode。

DecodeFromCache又包括两步decodeResultFromCache和decodeSourceFromCache，这就让人想到Glide的DiskCacheStrategy分为Result和Source，即可以缓存decode结果也可以缓存decode之前的source。前提是在上面的diskCacheProvider.getDiskCache().get(key)方法里面找到了CachedFile。这个路径在InternalCacheDiskCacheFactory里面写了具体的路径

```java
 public InternalCacheDiskCacheFactory(final Context context, final String diskCacheName, int diskCacheSize) {
        super(new CacheDirectoryGetter() {
            @Override
            public File getCacheDirectory() {
                File cacheDirectory = context.getCacheDir();
                if (cacheDirectory == null) {
                    return null;
                }
                if (diskCacheName != null) {
                    return new File(cacheDirectory, diskCacheName);
                    //就是context.getCacheDir+"image_manager_disk_cache"
                    //默认上限是250MB
                    //由于这个Cache放在CacheDir里面，其他应用拿不到
                }
                return cacheDirectory;
            }
        }, diskCacheSize);
    }
```
注意无论是decodeResultFromCache还是decodeSourceFromCache里都有类似的一段：
```java
Resource<T> transformed = loadFromCache(resultKey);
Resource<Z> result = transcode(transformed); ///把一种资源转成另一种资源，比如把Bitmap的Resource转成一个ByteResource
```



### 4.2 SourceService这个线程池以及BitmapPool这一层缓存的出现
```java
   private Resource<T> decodeFromSourceData(A data) throws IOException {
        final Resource<T> decoded;
        if (diskCacheStrategy.cacheSource()) {
            decoded = cacheAndDecodeSourceData(data);
        } else {
            long startTime = LogTime.getLogTime();
            decoded = loadProvider.getSourceDecoder().decode(data, width, height); // 这里面放进BitmapPool了
            if (Log.isLoggable(TAG, Log.VERBOSE)) {
                logWithTimeAndKey("Decoded from source", startTime);
            }
        }
        return decoded;
    }
```

**第四层缓存出现。。。LruBitmapPool**
DecodeFromSource也是类似，判断是否允许Cache，通过DataFetcher获取数据这个数据可能是InputStream，也可能是ImageVideoWrapper。。。总之是一个可以提供数据的来源。如果可以Cache的话，先把数据写到lru里面，然后从lru里面取出来，从Source decode成想要的数据类型。
例如从Stream转成Bitmap是这么干的
StreamBitmapDecoder.java
```java
 @Override
    public Resource<Bitmap> decode(InputStream source, int width, int height) {
        Bitmap bitmap = downsampler.decode(source, bitmapPool, width, height, decodeFormat);
        return BitmapResource.obtain(bitmap, bitmapPool);
    }
```
顺便还放进了LruBitmapPool（又一个实现了lru算法的缓存），Bitmap存在一个LruPoolStrategy接口实例的GroupedLinkedMap中。


### 4.3 回到主线程
EngineRunnable的run方法跑在子线程，在run的最后就是用一个handler推到主线程了。有可能是从CacheService这个线程池里面的线程推过去的，也可能是SourceSevice这个线程池里面推过去的。

onResourceReady最终会走到GenericRequest的onResourceReady方法里
```
  private void onResourceReady(Resource<?> resource, R result) {

        if (requestListener == null || !requestListener.onResourceReady(result, model, target, loadedFromMemoryCache,
                isFirstResource)) {
            GlideAnimation<R> animation = animationFactory.build(loadedFromMemoryCache, isFirstResource);
            target.onResourceReady(result, animation); //注意这句话就可以了
        }
    }

```
最终会调到ImageViewTarget,AppWidgetTarget等Target（持有Request和View,View可能没有），这时候，直接调用ImageView.setImagBitmap等方法就可以了。
图片设置完毕。

### 5. Glide除了普通的加载方法，还能用什么比较有意思的玩法

- 1.Glide加载Gif的原理在GifDecoder的 public synchronized Bitmap getNextFrame()方法里，Gif本质上是一帧帧的Frame数据，Glide将这些数据包装到GifFrame这个类中，每次想要获得下一帧的时候，就从bitmapPool中obtain Bitmap,同时从Frame中提取必要信息填充bitmap.
Gif的显示是在GifDrawable的draw方法里面通过frameLoader.getCurrentFrame()获得当前帧的bitmap。
[android.graphics.Movie](https://developer.android.com/reference/android/graphics/Movie.html)也能加载gif图片。只是Movie里面都是些native方法，glide的GifHeaderParser.java中的readContents方法里面用java方法实现了对gif帧的读取。
从GifDecoder.read这个方法开始读就好了


- 2.GlideDrawableImageViewTarget中有这么一段注释：
```java
@Override
   public void onResourceReady(GlideDrawable resource, GlideAnimation<? super GlideDrawable> animation) {
       if (!resource.isAnimated()) {
           //TODO: Try to generalize this to other sizes/shapes.
           // This is a dirty hack that tries to make loading square thumbnails and then square full images less costly
           // by forcing both the smaller thumb and the larger version to have exactly the same intrinsic dimensions.
           // If a drawable is replaced in an ImageView by another drawable with different intrinsic dimensions,
           // the ImageView requests a layout. Scrolling rapidly while replacing thumbs with larger images triggers
           // lots of these calls and causes significant amounts of jank.
           float viewRatio = view.getWidth() / (float) view.getHeight();
           float drawableRatio = resource.getIntrinsicWidth() / (float) resource.getIntrinsicHeight();
           if (Math.abs(viewRatio - 1f) <= SQUARE_RATIO_MARGIN
                   && Math.abs(drawableRatio - 1f) <= SQUARE_RATIO_MARGIN) {
               resource = new SquaringDrawable(resource, view.getWidth());
           }
       }
       super.onResourceReady(resource, animation);
       this.resource = resource;
       resource.setLoopCount(maxLoopCount);
       resource.start();
   }
```

- 3. Glide还可以用来纯粹的解码获得Bitmap.
```java
Glide.with(itemView.getContext()) //不用担心leak,RequestManager只是通过这个context获得了ApplicationContext，保留下来的是Application的context
               .load(R.drawable.image_41)
               .asBitmap()
               .centerCrop().into(new SimpleTarget<Bitmap>() {
           @Override
           public void onResourceReady(Bitmap resource, GlideAnimation<? super Bitmap> glideAnimation) {

           }

           @Override
           public void onDestroy() {
               super.onDestroy(); //其实这里面是空方法。
           }
       });
```

- 4.缓存路径获取
```java
Glide.with(itemView.getContext())
            .load("")
            .downloadOnly(new BaseTarget<File>() {
                @Override
                public void onResourceReady(File resource, GlideAnimation<? super File> glideAnimation) {
                  Log.d(TAG, resource.getAbsoluteFile());
              //放心，都在主线程
                }

                @Override
                public void getSize(SizeReadyCallback cb) {
                }
            });
```
根据之前的分析，打印出来的应该是context.getCacheDir+"image_manager_disk_cache"+"/xxxxxx.xxx" ，我没研究过后缀，不过这个后缀没意义吧。

- 5. 在2017年的Droidcon2017NYC上，有一个演讲提到了关于图片尺寸大小和内存关系。大致情形就是在使用加载图片的时候，使用了一张3594pixel*5421pixel(1900万像素)的图片（内存占用19million pixels X 4 bytes/pixel = 78MB），填进了一个50dp*50dp的avatar中。而如果使用和ImageView大小一样的图片源的话(150pxX150px)，只需要90kb。这之间的内存消耗差异几乎是1000倍。这位speaker说的解决方案是请求图片是加上宽度和高度参数，或者调用Picasso的fit方法。目前看来，Glide从onSizeReady之后获取资源的每一步，读取缓存，读磁盘，解码图片这些过程都带上了width和height参数，所以应该也是不存在这种浪费内存的问题

-

## 总结
- 4层缓存（MemoryCache是内存中的一层，activeResources是一层（HashMap）,cacheService和SourceService这俩线程池干活需要一个DiskLruCache，另外decode还有一个bitmapPool，其实这不算缓存吧）。
- 默认的缓存大小考虑了屏幕尺寸和可用内存大小，科学合理。线程池的keepAlive数量上，一个是可用cpu核心数，所以快吧，一个是1。
- 全局只有一个Glide,一个页面只有一个RequestManager
- Target是一个接口，将资源的受众抽象成一个接口。
- setTag会崩，ListView,RecyclerView原理,加载优化(prefetcher什么的，滑动过程中不去加载图片，Glide只是取消了之前的请求，并未去prefetch,其实可以啊，网络差的时候，downloadOnly就好了嘛，下次会快一点点)
- 传进去的是context，但它只是借用context.getApplicationContext，保留下来的是ApplicationContext，哪有那么容易leak。
- 生命周期挂钩什么，创建一个没有View的SupportFragment，还是做的很巧妙的。
- 泛型写的各种绕。。。



**现在来回答那个问题：“如果你来设计一个图片加载框架，你会怎么设计？”**

一个ImagerLoader应该具有的几个特性包括：
1. 内存缓存和磁盘缓存,lru
2. 做好图片压缩和bitmap重用(不可见图片及时回收)，避免oom (bitmap的宽高要根据View的大小确定)
3. 对于不同资源来源能够提供对应的DataFetcher
4. 对外提供start,stop,pause,resume等功能，必要时自动跟踪应用生命周期
5. 耗时操作(io，解码)挪到后台
6. 内存缓存可以设计两层bitmap缓存，一层是直接拿来用的(active)，一层是lru的。根据[经验](https://dev.qq.com/topic/591d61f56793d26660901b4e)，一张bitmap占几个MB(高分辨屏幕)，而一个App能够使用的最大heap大小（ActivityManage.getMemoryClass）一般在100多MB，取其中的40%。完全能够做到内存中cache十几张bitmap。

外部调用者需要传入资源(url,File,res，etc)，及ImageView实例(我们也就有了Context)。在onPreDraw之后获得View的尺寸（这一点至关重要）。根据资源地址生成唯一的key，在bitmap pool中查找，然后在内存缓存(lru)中查找。如果还未找到的话提交DiskCache查找请求请求到DiskCache查找线程池，如果未找到提交请求到资源获取线程池(网络，文件，或者Res)，数据获取完成后cahe到disk并提交到主线程。多线程同步和生命周期追踪是难点。


## update
Glide 4.0之后提供了更高的可定制度，
[如何为Glide设定OkHttpClient](https://stackoverflow.com/questions/37208043/how-to-set-okhttpclient-for-glide)
```java
 @GlideModule
    private class CustomGlideModule extends AppGlideModule {

       @Override
       public void registerComponents(Context context, Glide glide, Registry registry) {
           OkHttpClient client = new OkHttpClient.Builder()
                   .readTimeout(15, TimeUnit.SECONDS)
                   .connectTimeout(15, TimeUnit.SECONDS)
                   .build();

       OkHttpUrlLoader.Factory factory = new OkHttpUrlLoader.Factory(client);

           glide.getRegistry().replace(GlideUrl.class, InputStream.class, factory);
       }
   }
```

```java
compile "com.squareup.okhttp3:okhttp:3.8.1"
compile 'com.github.bumptech.glide:glide:4.0.0'
compile ('com.github.bumptech.glide:okhttp3-integration:4.0.0'){
    exclude group: 'glide-parent'
}
```
Glide 4.0的加载顺序是在DecodeJob的runGenerator再到startNext再到loadData。
看了下，本地缓存文件是使用ByteBufferFileLoader（就是用java nio去读取文件）的
加载cache的顺序还是memory hit > diskcache > remote cache 。后面两个都放在glide-disk-cache-thread上做。
在DecodeJob的onResourceDecoded方法中，有这么一个判断
```java
if (dataSource != DataSource.RESOURCE_DISK_CACHE) {
      appliedTransformation = decodeHelper.getTransformation(resourceSubClass);
      transformed = appliedTransformation.transform(glideContext, decoded, width, height);
    }
```
也即DiskCacheStrategy.RESOURCE以及DiskCacheStrategy.ALL这种类型的缓存策略在第一次load完decode完之后。下次从disk中加载的时候直接无视transform。
还有，从一个file中decode出bitmap的方法是从Downsampler.decodeStream这个方法里面调用BitmapFactory.decodeStream方法来做的

先尝试用ByteBufferGifDecoder去decode下载下来的资源（失败了丢一个GlideException出来） ->  换下一个(ByteBufferBitmapDecoder) 这里面就是调用了BitmapFactory.decodeStream(Stream是包装了一个ByteBufferStream，读取的时候实际上调用了byteBuffer的相应方法，也就是使用了DirectByteBuffer的对应方法)这个方法来创建bitmap

### 关于DirectByteBuffer在glide中的使用
java.nio.DirectByteBuffer这个class,从成员变量来看有MemoryBlock,以及FileChannel.MapModel
```java
public static ByteBuffer fromFile(@NonNull File file) throws IOException {
    RandomAccessFile raf = null;
    FileChannel channel = null;
    raf = new RandomAccessFile(file, "r");
    channel = raf.getChannel();
    return channel.map(FileChannel.MapMode.READ_ONLY, 0, fileLength).load(); //map就是mmap，返回的是MappedByteBuffer,这是一个抽象类，实际应该是DirectByteBuffer
  }
```
其实就是使用mmap减少了内存复制的开销

一些默认的配置如果外部没有设置的话是这样的
```java
if (arrayPool == null) {
    arrayPool = new LruArrayPool(memorySizeCalculator.getArrayPoolSizeInBytes());
}

if (memoryCache == null) {
    memoryCache = new LruResourceCache(memorySizeCalculator.getMemoryCacheSize());
}

if (diskCacheFactory == null) {
    diskCacheFactory = new InternalCacheDiskCacheFactory(context);
}
```


tbd
是否可以在onSizeReady之后修改url，添加上七牛的宽高参数？



## 参考
- [Android Glide源码解析](http://frodoking.github.io/2015/10/10/android-glide/)
