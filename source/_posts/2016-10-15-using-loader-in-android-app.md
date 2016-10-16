---
title: 使用Loader进行异步数据操作
date: 2016-10-15 19:12:22
tags:
---
App中经常有这样的需求:
进入一个页面，首先查询数据库，如果数据库数据有效，直接使用数据库数据。否则去网络查询数据，网络数据返回后重新加载数据。
很显然，这里的查询数据库和网络请求都需要放到子线程去操作，异步了。android推荐使用Loader进行数据查询，最大的好处就是Laoder会处理好与生命周期相关的事情，Android Developers推出过关于Loaders的[介绍视频](https://www.youtube.com/watch?v=s4eAtMHU5gI&index=8&list=PLWz5rJ2EKKc9CBxr3BVjPTPoDPLdPIFCE)，Loader就是为了解决这种问题而推出的，Loader具有几点好处
1. 如果Activity挂掉了，Activity中启动了的线程怎么办，如果不处理好有可能导致leak。
2. activity挂了，而子线程中持有View的强引用，此时再去更新View已经没有意义，View已经不可见了
3. 这条线程所做的工作，加载的资源都白白浪费了，下次还需要重新加载一遍。
<!--more-->

### 1. 自定义一个Loader(加载数据类型，Cache处理等)
Loader的使用就像一个AsyncTask一样，可以提前指定需要在异步线程中做的事情、数据类型以及完成加载后将数据推送到主线程。谷歌给出了一个使用Loader来查询手机上安装的App并显示在一个ListView中的DemoApp，虽然是好几年前的东西了，并且使用的是V4包里的Loader,但还是值得学习。
首先来看自定义的AppListLoader
```java
public class AppListLoader extends AsyncTaskLoader<List<AppEntry>>{//AsynTaskLoader支持泛型，AppEntry是已安装App信息的包装类。
    private List<AppEntry> mApps; 查询的App列表保存为成员变量
 
 //构造函数
 public AppListLoader(Context ctx) {
        // Loaders may be used across multiple Activitys (assuming they aren't
        // bound to the LoaderManager), so NEVER hold a reference to the context
        // directly. Doing so will cause you to leak an entire Activity's context.
        // The superclass constructor will store a reference to the Application
        // Context instead, and can be retrieved with a call to getContext().
        super(ctx);
        //第一，这里运行在主线程上；
		//第二，传进来的context(一般是Activity只是为了获取ApplicationContext)
        mPm = getContext().getPackageManager();//getContext()返回的是Application的Context。
    }
	
	
	  @Override
    public List<AppEntry> loadInBackground() {
        if (DEBUG) Log.i(TAG, "+++ loadInBackground() called! +++");
        LogUtil.p("");// 子线程,耗时的工作放到这里
        // Retrieve all installed applications.
        List<ApplicationInfo> apps = mPm.getInstalledApplications(0);//PackageManager的方法

        if (apps == null) {
            apps = new ArrayList<ApplicationInfo>();
        }

        // Create corresponding array of entries and load their labels.
        List<AppEntry> entries = new ArrayList<AppEntry>(apps.size());
        for (int i = 0; i < apps.size(); i++) {
            AppEntry entry = new AppEntry(this, apps.get(i));
            entry.loadLabel(getContext());
            entries.add(entry);
        }

        // Sort the list.
        Collections.sort(entries, ALPHA_COMPARATOR);

        return entries;
    }

	
	 @Override
    public void deliverResult(List<AppEntry> apps) {
        //运行在主线程上
        if (isReset()) {//这里就类似于AsyncTask的onPostExecute了，把子线程处理好的数据推送到主线程
            if (DEBUG) Log.w(TAG, "+++ Warning! An async query came in while the Loader was reset! +++");
            // The Loader has been reset; ignore the result and invalidate the data.
            // This can happen when the Loader is reset while an asynchronous query
            // is working in the background. That is, when the background thread
            // finishes its work and attempts to deliver the results to the client,
            // it will see here that the Loader has been reset and discard any
            // resources associated with the new data as necessary.
            if (apps != null) {
                releaseResources(apps);
                return;
            }
        }//如果调用了reset()方法，说明子线程加载的数据是无效的，释放资源，处理无效数据

        // Hold a reference to the old data so it doesn't get garbage collected.
        // We must protect it until the new data has been delivered.
        List<AppEntry> oldApps = mApps;
        mApps = apps;

        if (isStarted()) {// 如果一切正常，即调用了startLoading且stopLoading和reset均为被调用
            if (DEBUG) Log.i(TAG, "+++ Delivering results to the LoaderManager for" +
                    " the ListFragment to display! +++");
            // If the Loader is in a started state, have the superclass deliver the
            // results to the client.
            super.deliverResult(apps);
        }

        // Invalidate the old data as we don't need it any more.
        if (oldApps != null && oldApps != apps) {
            if (DEBUG) Log.i(TAG, "+++ Releasing any old data associated with this Loader. +++");
            releaseResources(oldApps);
        }
    }
}
```
到此，数据加载的Server端算是完成，这里注意调用到了isReset()、isStarted()等方法，这些就是Server端在在处理Client端生命周期是需要注意的，这个后面再说。

### 2. 使用LoaderManager管理Loader
我们使用LoaderManager在Activity或Fragment中与Loader交互。通常在onCreate或者onActivityCreated中:
> getSupportedLoaderManager.initLoader()//Activity中
> getLoaderManager() //Fragment中

这里介绍在Fragment中的使用，因为Loader处理好了与Activity,Fragment甚至Child Fragment的生命周期。
推荐使用v4包里的Loader，Loader是在Android3.0引入FrameWork中的，但v4包让Loadder在更早的版本上也有相应的API。更重要的是，v4 包中的Loader是伴随着v4包新的release step，也就是说v4包会与时俱进修复其中的bug。
这一点在medium上有[介绍](https://medium.com/google-developers/making-loading-data-on-android-lifecycle-aware-897e12760832#.wrh1ciyts) 。
再看一下这个方法
>  public abstract <D> Loader<D> initLoader(int id, Bundle args,
            LoaderManager.LoaderCallbacks<D> callback);
			

Demo中使用的是Fragment：
>  // Initialize a Loader with id '1'. If the Loader with this id already
            // exists, then the LoaderManager will reuse the existing Loader.
            getLoaderManager().initLoader(LOADER_ID, null, this);			
			
相对应的Fragment需要implements  LoaderManager.LoaderCallbacks<List<AppEntry>> //注意泛型
这个接口有三个方法
```java
 public interface LoaderCallbacks<D> {
       
        public Loader<D> onCreateLoader(int id, Bundle args);

       
        public void onLoadFinished(Loader<D> loader, D data);

       
        public void onLoaderReset(Loader<D> loader);
    }
```			
看一下Demo中是如何实现的
```java
   @Override
        public android.support.v4.content.Loader<List<AppEntry>> onCreateLoader(int id, Bundle args) {
            if (DEBUG) Log.i(TAG, "+++ onCreateLoader() called! +++");
            return new AppListLoader(getActivity());
        }

        @Override
        public void onLoadFinished(android.support.v4.content.Loader<List<AppEntry>> loader, List<AppEntry> data) {
            if (DEBUG) Log.i(TAG, "+++ onLoadFinished() called! +++");
            mAdapter.setData(data);//加载数据到UI

            if (isResumed()) {
                setListShown(true);
            } else {
                setListShownNoAnimation(true);
            } 
        }

        @Override
        public void onLoaderReset(android.support.v4.content.Loader<List<AppEntry>> loader) {
            if (DEBUG) Log.i(TAG, "+++ onLoadReset() called! +++");
            mAdapter.setData(null);//loader被reset，UI这边需要清除所有与Loader数据相关的引用，但清除数据的任务会由Loader处理好
        }
```
在三个明显的回调中处理好数据绑定到UI及过期数据的清理即可。

### 3. 处理Activity生命周期的问题
回到server端(Loader),AsyncTaskLoader是一个abstract class，loadInBackground方法已经实现了，但还有几个方法强调必须要复写或者与生命周期相关
```java
 @Override
protected void onStartLoading() {
	/**
     * Subclasses must implement this to take care of loading their data,
     * as per {@link #startLoading()}.  This is not called by clients directly,
     * but as a result of a call to {@link #startLoading()}.
     */
	 在这里检查一下成员变量中的数据是否不为空，有数据的话，deliverResults
}

@Override
protected void onStopLoading() {
 /**
     * Subclasses must implement this to take care of stopping their loader,
     * as per {@link #stopLoading()}.  This is not called by clients directly,
     * but as a result of a call to {@link #stopLoading()}.
     * This will always be called from the process's main thread.
     */
}

@Override
protected void onReset() {
/**
     * Subclasses must implement this to take care of resetting their loader,
     * as per {@link #reset()}.  This is not called by clients directly,
     * but as a result of a call to {@link #reset()}.
     * This will always be called from the process's main thread.
	如果调用了destoryLoader或者Loader相关联的Activity/Fragment被destory了
	所以在Demo中可以看到onReset里面调用了onStopLoading去取消当前任务，同时释放资源，取消广播注册
     */
}

@Override
public void onCanceled(List<AppEntry> apps) {
 /**
     * Called if the task was canceled before it was completed.  Gives the class a chance
     * to clean up post-cancellation and to properly dispose of the result.
     *
     * @param data The value that was returned by {@link #loadInBackground}, or null
     * if the task threw {@link OperationCanceledException}.
     */
	 在这里释放资源
}

@Override
public void forceLoad() {
/**
     * Force an asynchronous load. Unlike {@link #startLoading()} this will ignore a previously
     * loaded data set and load a new one.  This simply calls through to the
     * implementation's {@link #onForceLoad()}.  You generally should only call this
     * when the loader is started -- that is, {@link #isStarted()} returns true.
     *
     * <p>Must be called from the process's main thread.
     */
	 startLoading会直接使用onConfigurationchange之前的Activity中Loader加载的数据，但这里则放弃旧的数据，重新加载，所以isStarted会在这时返回true（）
}
```
考虑一下，如果在加载数据过程中数据源发生了变化，比如在扫描已安装App过程中又安装了新的App怎么办？所以这里又注册了两个广播，在onReceive的时候调用
>     mLoader.onContentChanged();
//这会直接调用forceLoad（Loader已经started）或者设置一个标志位，让takeContentChanged（）返回true
> 在onStartLoading中发现这个为true，直接forceLoad
//接下来进入loadInBackground,完成后进入deliverResult
deliverResult首先检查Activity是否destoryed(挂了直接释放资源),没挂的话判断下isStarted(是否一切正常，未调用过stopLoading或reset)，符合条件的话通过super.deliverResult把数据传递出去。接下来判断下之前的旧数据和新数据是否一致，否则释放掉旧数据

整个过程考虑到了数据的有效性，资源的释放，在Loader这一端，通过isReset,isStarted等方法确保了不确定的数据加载过程能够和不确定的生命周期和谐共处。
网上看到的关于Loader的文章大部分是关于CursorLoader的，也就是和数据库打交道的那一块，这里不细说。主要是目前没有看到太多App中使用这种加载模式，可能确实有点麻烦。在Medium上看到这篇文章，觉得还是有必要做一些记录的。

### 4. 关于性能
最后我想说的是，AsyncTaskLoader内部使用的还是AsyncTask那一套，关于AsyncTask的串行和并行的讨论网上有很多。于是我看了下AsyncTaskLoader中最终调用AsyncTask的execute方法:
>  mTask.executeOnExecutor(mExecutor, (Void[]) null);

至于这个mExecutor的本质:

> public static final Executor THREAD_POOL_EXECUTOR
            = new ThreadPoolExecutor(CORE_POOL_SIZE, MAXIMUM_POOL_SIZE, KEEP_ALIVE,
                    TimeUnit.SECONDS, sPoolWorkQueue, sThreadFactory); 
CORE_POOL_SIZE = 5
嗯，并行的线程池，性能应该还不错。
学过rxjava，是否rxjava会是一种比loader更好的加载数据的方式呢

### Reference

1. [rxLoader](http://huxian99.github.io/2015/10/28/RxJava%E7%9A%84Android%E5%BC%80%E5%8F%91%E4%B9%8B%E8%B7%AF-RxJava%E5%AE%9E%E6%88%98-%E4%BA%8C/)
2. [making loading data on android lifecycle aware](https://medium.com/google-developers/making-loading-data-on-android-lifecycle-aware-897e12760832#.btjs9ady6)
3. [AppListLoader](https://github.com/alexjlockwood/adp-applistloader)