---
title: 从glide源码到图片加载框架设计思路
date: 2017-07-21 00:13:02
tags: [android]
---

glide的源码几个月前曾经拜读过，大致了解了其异步加载的实现原理。图片加载和网络请求很类似，就像当初看Volley，从一个Request --->  CacheDispatch  ---> NetworkDispatcher  ---->  ResponseDeliver。优秀的轮子不仅执行效率高，同时具备高的扩展性。读懂源码其实只是第一步，往下应该是利用框架提供的扩展方案，再往后应该就是能够独立设计出一套类似的框架了。


![](http://odzl05jxx.bkt.clouddn.com/a11f41e0b1df95212c71920b3959cd72.jpg?imageView2/2/w/600)
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

with方法只是返回了一个RequestManager，with方法可以接受Fragemnt,Activity以及Context等.以上面的activity为例，supportFragmentGet方法只是通过FragmentActivity的supportFragmentManager去findFragmentByTag，这个Tag叫做：“com.bumptech.glide.manager”，所以一般在Debug的时候，去SupportFragmentManager里面查找，有时候能够看到一个这样的Fragment。这个方法里面就是查找这样的一个Fragment，甚至我们自己也可以FindFragmentByTag去调用这个Fragment的方法(这是一个Public的class)然后从这个Fragemnt里面获得RequestManager成员变量（没有就new一个并set）。可以看出，一个Fragment只有一个RequestManager，Fragment主要是为了跟Activity生命周期挂钩的。这里有必要讲一下为什么要写两次current ==null，findFragmentByTag并不会在commitAllowingStateLoss之后就会返回添加的Fragment，只是往主线程的MessageQueue里面丢了一个消息，这个消息执行完毕之后才findFragmentByTag才不为空。这里用Handler丢一条消息，这条消息肯定要排在之前那条消息之后才被执行，所以才有这样一个Pendingmap的设计。当然到这里，最重要的还是Glide是通过commit了一个特殊的Fragment来实现生命周期监听。
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

- public class DrawableTypeRequest<ModelType> extends DrawableRequestBuilder<ModelType> implements DownloadOptions
- public class DrawableRequestBuilder<ModelType>
        extends GenericRequestBuilder<ModelType, ImageVideoWrapper, GifBitmapWrapper, GlideDrawable>
        implements BitmapOptions, DrawableOptions 
- public class GenericRequestBuilder<ModelType, DataType, ResourceType, TranscodeType> implements Cloneable        


记住这个ModelType就是Glide.with(context).load(XXX) 里面传进去的Object的Class，例如File.class




## 3. Engine及任务描述
### 3.1 解码任务

## 4. 缓存机制，BitmapPool以及MemoryCache（算上DiskCache的话至少三层Cache）


## 来一些不拘一格的加载图片的方法
### 使用Application的Context,不跟生命周期走

## 小结


## 参考