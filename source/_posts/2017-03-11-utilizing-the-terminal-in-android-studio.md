---
title: 使用IDE内置的Terminal
date: 2017-03-11 22:28:51
categories: blog
tags: [android]
---


![io](http://odzl05jxx.bkt.clouddn.com/device-2017-03-11-222239.png?imageView2/2/w/600)
这周终于把Google I/O 2016的Android App在Device上跑起来了，顺便尝试多多使用命令行进行编译或者安装。

<!-- more -->


### 1. 编译Android client并安装到本地设备
官方提供了比较完善的Build Instructions，对于习惯于shift+F10的我来说，还是有点麻烦。

clone下来[iosched](https://github.com/google/iosched)，修改gradle.properities里面的supportLib等值，参考Build Instruction ，

> gradlew clean assembleDebug


往往这一步会开始下载gradle，非常耗时。参考了stackOverFlow，自己去下载gradle 3.3 -all.zip，放到/gradle/wrapper文件夹下，修改gradle-wrapper.properities，将其中的distributionUrl改成


> distributionUrl=gradle-3.3-all.zip

等于直接省去上述下载步骤。Build完成后，敲入命令行

>gradlew installNormalDebug

不出意外的话，即可进入主页面。

### 2. Server端配置
Google io 2016 Android Client提供了Map Intergation和Youtube video display以及GCM等服务。这些全部集成在Google Cloud Platform上配置。


--------------------------------------------------------------------

关于性能优化有一些建议：
> don't do premature optimazition
在你整天思考到底要用Enum还是IntDef的时候，你的网络库已经allocate了一大堆的垃圾。将精力集中在解决最严重的问题上。，



## 1. Systrace用于跟踪一段方法执行过程中的影响
```java
try {
    Trace.beginSection(TAG);
    // do stuff
    }finally {
     Trace.endSection();
    }
```
计算一段方法到底花了多长时间，当然还是要在Android device monitor里面begin trace，注意要勾选**Enable Application Traces from XXXX**，选中自己的包名就好了。一开始可能不是特别好找，只要在html中ctrl+f找到了自己写的TAG，慢慢来应该能找到的。

## 2. FileObserver
[FileObserver](https://developer.android.com/reference/android/os/FileObserver.html)可以监控设备上文件的更改，删除，读取。
底层原理是使用了linux内核的inotify机制。

## 3. Environment.getXXX长什么样
私有文件应该放在哪里，公开的文件适合放在哪里，tmp文件可以放在哪里。
```java
Log.i("codecraeer", "getFilesDir = " + getFilesDir());
Log.i("codecraeer", "getExternalFilesDir = " + getExternalFilesDir("exter_test").getAbsolutePath());
Log.i("codecraeer", "getDownloadCacheDirectory = " + Environment.getDownloadCacheDirectory().getAbsolutePath());
Log.i("codecraeer", "getDataDirectory = " + Environment.getDataDirectory().getAbsolutePath());
Log.i("codecraeer", "getExternalStorageDirectory = " + Environment.getExternalStorageDirectory().getAbsolutePath());
Log.i("codecraeer", "getExternalStoragePublicDirectory = " + Environment.getExternalStoragePublicDirectory("pub_test"));
```



##  4.对象池(Object Pool)
这个看一下Glide里面的BitmapPool就好了
LruBitmapPool.java
pool的大小是MemorySizeCalculator算出来的，考虑了App可以使用的最大内存和屏幕分辨率像素对应容量这两个因素。
对象池主要关注put和get这两个方法。
Glide中的LruBitmapPool.java中有一段很有意思的注释
```java
 @Override
    public synchronized Bitmap get(int width, int height, Bitmap.Config config) {
        Bitmap result = getDirty(width, height, config);
        if (result != null) {
            // Bitmaps in the pool contain random data that in some cases must be cleared for an image to be rendered
            // correctly. we shouldn't force all consumers to independently erase the contents individually, so we do so
            // here. See issue #131.
            result.eraseColor(Color.TRANSPARENT);
        }

        return result;
    }
```
就是说，从回收池里面取出来的Bitmap可能存储了一些脏数据，在复用之前要清除下旧数据。

> 另外，MotionEvent,Message以及Okio里面的Segment都是可以被recycle和obtain的可回收再利用对象。Andorid Bitmap后期支持了inBitmap，也是类似于回收再利用的概念。
Bitmap有点不同，虽然内存中的表现形式只是二维byte数组。但在支持inBitmap之前，并不是每一个Bitmap都可以被直接回收用于存储下一个Bitmap.

[V4包里提供了简单的实现](https://developer.android.com/reference/android/support/v4/util/Pools.html)

## 5.MediaScanner是一个和有趣的可以扫描多媒体文件的类
[技术小黑屋](http://droidyue.com/blog/2014/07/12/scan-media-files-in-android-chinese-edition/)

### 6. Drawable跟单例有点像
[官方文档](https://developer.android.com/guide/topics/graphics/2d-graphics.html#drawables)上有这么一句，看起来很不起眼的
Note: Each unique resource in your project can maintain only one state, no matter how many different objects you instantiate for it. For example, if you instantiate two Drawable objects from the same image resource and change a property (such as the alpha) for one object, then it also affects the other. When dealing with multiple instances of an image resource, instead of directly transforming the Drawable object you should perform a tween animation.
这件事的意义在于，Drawable在整个Application中是单例。
简单来说，getDrawable每次返回的都是一个新的Drawable，但Drawable只是一个Wrapper，放在res文件夹里的Drawable资源在整个Application中是单例。
证明的方式很简单: 两个相同资源的Drawable可能不一样，但Drawable.getConstantState都是同一个instance。
原理的话，参考 [Cyril Mottier在2013年的演讲](https://www.youtube.com/watch?v=JuE13KXRMxg)
就跟xml是binary optimized的一样，
亲测，在一个Activity中改变Drawable的Alpha属性，退出重新进，Drawable的Alpha就已经是被更改了的。在另一个Activity中引用这个Drawable，Alpha也受到影响。
更严重的是，在一个Activity中使用((BitmapDrawable)getDrawable).getBitmap().recycle()，在另一个Activity中使用这个Drawable，直接报错：
```
java.lang.RuntimeException: Canvas: trying to use a recycled bitmap android.graphics.Bitmap@c08bbc6
at android.graphics.Canvas.throwIfCannotDraw(Canvas.java:1270)
at android.graphics.Canvas.drawBitmap(Canvas.java:1404)
at android.graphics.drawable.BitmapDrawable.draw(BitmapDrawable.java:544)
at android.widget.ImageView.onDraw(ImageView.java:1228)
```
**这种东西根本防不胜防。**
[stackOverFlow](https://stackoverflow.com/questions/25858362/issue-when-recycling-bitmap-obtained-from-bitmapdrawable)上也有讨论
被人为调用Bitmap.recycle()的res中的图片资源直接不能用了，怎么办，重新用BitmapFactory去decode或者创建一张Canvas，用原来的bitmap去画呗。照说Android 3.0之后就不应该调用Recycle方法了，记得Chet Haase说过，Recycle doesn't do anything。
另外一种说法是，bitmap.isMutable()返回是false的话(从res加载的)就不该去mutate。真要更改像素属性的话，可以创建一个Canvas，然后用原来的bitmap去画一个一样大的，或者用bitmap.copy方法创建一个新的。

### 7. Aidl里面有些关键字
oneway关键字。
AIDL 接口的实现必须是完全线程安全实现。 oneway 关键字用于修改远程调用的行为。使用该关键字时，远程调用不会阻塞；它只是发送事务数据并立即返回

### 8. 自定义View一个不容易发现的点
自定义View的套路一般是这样的
```java
public CustomTitleView(Context context, AttributeSet attrs) {
   {  
       this(context, attrs, 0);  
   }  

   public CustomTitleView(Context context)  
   {  
       this(context, null);  
   }  

   public CustomTitleView(Context context, AttributeSet attrs, int defStyle)  
   {  
       super(context, attrs, defStyle);  
      // 获得我们所定义的自定义样式属性
        init();
   }  
}
```
然后在layout里面去findViewById，妥妥的找不到。写在xml里面，会调到两个参数的构造函数，因为id这种东西写是在xml里面的，所以在两个参数的构造函数里面做事情就好了。

### 9. Dialog会出的一些错误
9.1. showDialog之前最好判断下,activity.isFinishing
否则会崩成这样：
```
E/AndroidRuntime: FATAL EXCEPTION: main
Process: com.xxx.xxx, PID: 30025
 android.view.WindowManager$BadTokenException: Unable to add window -- token android.os.BinderProxy@59d55fe is not valid; is your activity running?
 at android.view.ViewRootImpl.setView(ViewRootImpl.java:579)
 at android.view.WindowManagerGlobal.addView(WindowManagerGlobal.java:310)
 at android.view.WindowManagerImpl.addView(WindowManagerImpl.java:91)
 at android.app.Dialog.show(Dialog.java:319)
 ...
```


9.2. show一个Dialog，忘记关掉就finish，App不会崩，但日志里面有error：
从用户角度来看，Dialog随着页面的关闭也关了
```
 E/WindowManager: android.view.WindowLeaked: Activity com.example.SomeActivity has leaked window com.android.internal.policy.PhoneWindow$DecorView
 at android.view.ViewRootImpl.<init>(ViewRootImpl.java:380)
 at android.view.WindowManagerGlobal.addView(WindowManagerGlobal.java:299)
 at android.view.WindowManagerImpl.addView(WindowManagerImpl.java:91)
 at android.app.Dialog.show(Dialog.java:319)
 ...
```
对比一下上面那个error，目测只有FATAL EXCEPTION才会导致App崩溃

9.3. activity finish掉之后再去Dismiss，先出2的日志，然后是一个fatal exception
```java
button.setOnClickListener { v ->
            showDialog()
            finish() // onBackPressed也一样
            v.postDelayed( Runnable { mDialg!!.dismiss() },2000)
}
```
```
//第一个是这个
E/WindowManager: android.view.WindowLeaked: Activity com.xxx.DialogActivity has leaked window com.android.internal.policy.PhoneWindow$DecorView{240a531 V
//2秒之后出现这个
E/AndroidRuntime: FATAL EXCEPTION: main
 Process: com.harris.simplezhihu, PID: 7256
  java.lang.IllegalArgumentException: View=com.android.internal.policy.PhoneWindow$DecorView{240a531 V.E...... R......D 0,0-1026,716} not attached to window manager
at android.view.WindowManagerGlobal.findViewLocked(WindowManagerGlobal.java:424)
at android.view.WindowManagerGlobal.removeView(WindowManagerGlobal.java:350)
at android.view.WindowManagerImpl.removeViewImmediate(WindowManagerImpl.java:123)
at android.app.Dialog.dismissDialog(Dialog.java:362)
```
就崩了，dismiss之前先判断下isFinishing就没事了


9.4. dialog.show不是异步方法
```java
showDialog()
finish()
```
App不会崩，和2一样的error日志,看来不是Fatal
瞅一眼源码
Dialog.java:
```java
public void show() {
      // .......
      mWindowManager.addView(mDecor, l);
      mShowing = true;
      sendShowMessage();//发个消息给，OnShowListener
    }

private void sendShowMessage() {
     if (mShowMessage != null) {
         // Obtain a new message so this dialog can be re-used
         Message.obtain(mShowMessage).sendToTarget();
         //sendToTarget是到主线程的MessageQueue去排队了
     }
 }
```
所以ui上显示出Dialog和onShow不是一前一后(在同一个消息里面)调用的。
```java
private static final class ListenersHandler extends Handler {
    private final WeakReference<DialogInterface> mDialog;

    public ListenersHandler(Dialog dialog) {
        mDialog = new WeakReference<>(dialog);
    }

    @Override
    public void handleMessage(Message msg) {
        switch (msg.what) {
            case DISMISS:
                ((OnDismissListener) msg.obj).onDismiss(mDialog.get());
                break;
            case CANCEL:
                ((OnCancelListener) msg.obj).onCancel(mDialog.get());
                break;
            case SHOW:
                ((OnShowListener) msg.obj).onShow(mDialog.get());
                break;
        }
    }
}
```
很容易想到onDismiss(Dialog)里面的dialog可能为null，(主线程恰好在排队，正好来一次GC)，可能性应该不大。

9.5. Dialog中有一个OnKeyListener，所以用户手动按返回键会去dismissDialog并消费掉事件，代码调用onBackPressed和手动按返回键是不一样的。

### 10. RecyclerView的ItemAnimator有很多方法可以override
Chet的[Demo](https://github.com/google/android-ui-toolkit-demos)


### 11. 一些点
- 图片缓存策略
- Rxjava如何管理生命周期
- Okio源码
- OkHttp中和WebView中Cookie是怎么处理的
- Android上Socket的使用
- 注解
- Android上的进程通信，共享内存问题
- Webp格式
- UI widget检查Thread是在ViewRootImpl里面有一段方法checkThread() 。

### 12. No Activity found to handle Intent { act=com.android.camera.action.CROP
[com.android.camera.action.CROP](https://commonsware.com/blog/2013/01/23/no-android-does-not-have-crop-intent.html)并不是一个AOSP官方规定的Intent，有些设备上是会报错的。这个链接的作者是[Mark Murphy](https://stackoverflow.com/users/115145/commonsware)，很有趣的一个人。
[stackOverFlow上也有讨论](https://stackoverflow.com/questions/41890891/no-activity-found-to-handle-intent-com-android-camera-action-crop)
解决办法就是加一个catch(ActivityNotFoundException)就好了


### 13. Dalvik和Art崩的时候堆栈是不一样的
//Dalvik是这么崩的
```java
at android.view.View.performClick(View.java:4438)
at android.view.View$PerformClick.run(View.java:18439)
at android.os.Handler.handleCallback(Handler.java:733)
at android.os.Handler.dispatchMessage(Handler.java:95)
at android.os.Looper.loop(Looper.java:136)
at android.app.ActivityThread.main(ActivityThread.java:5095)
at java.lang.reflect.Method.invokeNative(Method.java)
at java.lang.reflect.Method.invoke(Method.java:515)
at com.android.internal.os.ZygoteInit$MethodAndArgsCaller.run(ZygoteInit.java:786)
at com.android.internal.os.ZygoteInit.main(ZygoteInit.java:602)
at dalvik.system.NativeStart.main(NativeStart.java)
```
//art是这么崩的
```java
at android.app.Activity.performStart(Activity.java:6311)
at android.app.ActivityThread.performLaunchActivity(ActivityThread.java:2387)
at android.app.ActivityThread.handleLaunchActivity(ActivityThread.java:2484)
at android.app.ActivityThread.access$900(ActivityThread.java:158)
at android.app.ActivityThread$H.handleMessage(ActivityThread.java:1352)
at android.os.Handler.dispatchMessage(Handler.java:102)
at android.os.Looper.loop(Looper.java:171)
at android.app.ActivityThread.main(ActivityThread.java:5454)
at java.lang.reflect.Method.invoke(Method.java)
at com.android.internal.os.ZygoteInit$MethodAndArgsCaller.run(ZygoteInit.java:726)
at com.android.internal.os.ZygoteInit.main(ZygoteInit.java:616)
```
### 14. 理解Canvas,surface,window等概念
[Dianne Hackborn的回答](https://stackoverflow.com/questions/4576909/understanding-canvas-and-surface-concepts/4577249#4577249)
onDraw里面的canvas是lock surface得到的


### 15.如果想要用一个动画移动一个View的话，没必要animate更改LayoutParams
更改LayoutParams看上去是现实生活中应该做的，但其实只需要用setTranslationX或者setTranslationY就好了。如果动画的每一帧都去更改layoutParams（会requestLayout，非常慢）,正确的做法是在视觉上做到正确的，animate TranslationX，这些是postLayout params，等动画结束后再把应有的layout属性设置上去。这样动画会更加流畅。 ---- Android for Java Developers(Big Android BBQ 2015)  -- Chet Haase

### 16. tint跑在GPU上，background会invalidate整个Drawable
如果想要动画渐变一个View的Background的话,[animate tint](https://www.youtube.com/watch?v=71ISWyJPSEY&index=9&list=PLWz5rJ2EKKc_HyE1QX9heAgTPdAMqc50z)即可，性能更好


### 17. SpringAnimation(具有弹性的动画)
Facebook早在15年就推出了具有弹性的[动画](https://github.com/facebook/rebound),谷歌在16年给supportLib添加了[Spring Animation](https://developer.android.com/guide/topics/graphics/spring-animation.html)，都是相似的理念。
弹性动画的关键是在keyFrame处算出非线性的值，用于设定UI控件展示状态。

### 18. Choreographer可以添加callback
doFrame方法的参数是(long FrameTimeNanos)，这个时间需要除以1000 1000
测试了一下，Frame确实是16毫秒更新一次，也就是接收到VSYNC信号的时机。
其实简单的想一下，这样可以用来显示当前应用的帧率，16ms就是60FPS,20ms就是50FPS.
论那些跑分软件是怎么做出来的。。。。当然更专业的方式应该是这个命令
> adb shell dumpsys SurfaceFlinger --latency + <window名>
网上有人写了python脚本，看起来更加直观一点

### 19. 网络请求的Batch
网络较差的情况下，可以将Request cache下来，等到网络较好的时候再执行。
Jesse Wilson[推荐](https://stackoverflow.com/questions/37529303/how-to-cache-the-request-queue-not-responses-with-okhttp)使用[TAPE](https://github.com/square/tape)
有两种实现，基于文件系统的和基于内存的。基于内存的很简单，基于文件的能够在crash发生时自动回退。

### 20.getSystemService是存在[memory leak](https://segmentfault.com/a/1190000004882511)问题的
context.getSystemService源码分析到最后，是从一个Hashmap里面取出Service
activity.getSystemService -> ContextImpl.getSystemService -> SystemServiceRegistry.getSystemService(SystemServiceRegistry里面有个HashMap<String, ServiceFetcher<?>>)
WifiManager存在leak的[issue](https://issuetracker.google.com/issues/63244509)

### 21. PopupWindow在7.0和7.1上是存在问题的
[参考](http://www.jianshu.com/p/dbd792b910ce)解决方式
```java
if (Build.VERSION.SDK_INT < 24) {
                    popupWindow.showAsDropDown(button);
   } else {
        int[] location = new int[2];  // 获取控件在屏幕的位置
        button.getLocationOnScreen(location);
      if (Build.VERSION.SDK_INT == 25) {
         int tempheight = popupWindow.getHeight();
      if (tempheight == WindowManager.LayoutParams.MATCH_PARENT || screenHeight <= tempheight) {
             popupWindow.setHeight(screenHeight - location[1] - button.getHeight());
           }
     }
       popupWindow.showAtLocation(button, Gravity.NO_GRAVITY, location[0], location[1] + button.getHeight());
 }
```

### 22. onSaveInstance的调用顺序以及ActivityThread的一些点
onSaveInstance在HoneyComb之前会在onPause前调用，HoneyComb开始，会在onStop前调用
3.0之前的基本不用看了，目前在Android 25 sdk中
ActivityThread.performStopActivityInner
```java
if (!r.activity.mFinished && saveState) {
          if (r.state == null) {
              callCallActivityOnSaveInstanceState(r);
          }
      }

try {
      // Now we are idle.
       r.activity.performStop(false /*preserveWindow*/);
   } catch (Exception e) {
       if (!mInstrumentation.onException(r.activity, e)) {
           throw new RuntimeException(
                   "Unable to stop activity "
                   + r.intent.getComponent().toShortString()
                   + ": " + e.toString(), e);
       }
   }
```
其实Activity的所有onXXX都是由ActivityThread发起的，其实主函数也在这里。
那么开始吧
ActivityThread.handleLaunchActivity
```java
 private void handleLaunchActivity(ActivityClientRecord r, Intent customIntent, String reason){
      // ...................
     Activity a = performLaunchActivity(r, customIntent);
     //'''''''''
     if (a != null) {
        handleResumeActivity(r.token, false, r.isForward,
                !r.activity.mFinished && !r.startsNotResumed, r.lastProcessedSeq, reason);
                  }
     //''''''''''

 }

 private Activity performLaunchActivity(ActivityClientRecord r, Intent customIntent){
   // ............
   activity = mInstrumentation.newActivity(
                   cl, component.getClassName(), r.intent);
   //Activity实例就是在这里面反射创建出来的
    if (activity != null) {
      //......
      mInstrumentation.callActivityOnCreate(activity, r.state);   /// onCreate
      if (!r.activity.mFinished) { //经常会有人在onCreate里面finish
                   activity.performStart();   // onStart
                   r.stopped = false;
               }
    }

 }
```

所以总的顺序是
ActivityThread#handleLaunchActivity ->
ActivityThread#performLaunchActivity ->
反射创建Activity实例 ->
mInstrumentation.callActivityOnCreate ->
activity.performStart() ->
handleResumeActivity()
以上都是在一个Message里面做的这个Message的what是“LAUNCH_ACTIVITY =100”，这个Message是
基本的尿性是 handleXXX -> performXXX
另外,onActivityResult是在ActivityThread的deliverResults里面触发的

### 23. 编译出错
>duplicate files copied in apk lib/x86/libRoadLineRebuildAPI.so 集成高德地图的时候

在app的build.gradle中添加
```
packagingOptions {
    pickFirst 'lib/**.so'
}
```

### 24. Could not resolve com.android.support:appcompat-v7:26.1.0
Android Studio里面设置httpProxy要生效其实得看gradle.properities文件里面这几行
```
systemProp.http.proxyPort=1080
systemProp.http.proxyHost=127.0.0.1
systemProp.https.proxyPort=1080
systemProp.https.proxyHost=127.0.0.1
```
注意，maven(),google()这些库都是https的，所以得把https也勾上。

### 25. 执行gradlew命令多了之后c盘占用空间越来越小
执行gradlew命令，会根据gradlew-wrapper.properities中设置的distributionUrl去下载对应的gradle-4.1-all.zip，然后unzip到
> C://Users//username//.gradle//wrapper//dists

这个目录。所以切换到这个目录，可以把之前2.x,3.x的全部都删掉了，看了下大小，将近3个GB。
还有每个Android项目的根目录下都有一个.gradle文件夹。按照linux文件系统的传统，前面加上一个点的意思都是隐藏文件。点进去看，里面的东西删除也没问题。

### 26. 在 AndroidStudio 工程点击 Run 按钮， 实际上做了什么操作呢？
[知乎的回答](https://www.zhihu.com/question/65289196)
看下日志就很清晰了
```text
17:35:33 Executing tasks: [:app:assembleDebug]
17:35:34 Gradle build finished in 858ms

09/14 17:35:34: Launching app
$ adb push /Users/didi/github/VirtualAPK/app/build/outputs/apk/app-debug.apk /data/local/tmp/com.didi.virtualapk
$ adb shell pm install -r "/data/local/tmp/com.didi.virtualapk"
Success

$ adb shell am start -n "com.didi.virtualapk/com.didi.virtualapk.MainActivity" -a android.intent.action.MAIN -c android.intent.category.LAUNCHER
Client not ready yet..Waiting for process to come online
Connected to process 21777 on device samsung-sm_g9500-98895a473737504e42
```
简单来说就是gradle installDebug
 Android Stuido点击build按钮做了什么[Configure Your Build](https://developer.android.com/studio/build/index.html)

### 27. 多进程场景下Application的onCreate是会被多次调用的
在Application的onCreate中添加日志
```java
//正常的Application起来都是1
Log.e("current-process-id is "+android.os.Process.myPid()); // 1
Log.e("current-thread-id is "+Thread.currentThread().getId()); // 1

//在应用内点击按钮起一个process，application的onCreate又被执行了一次
Log.e("current-process-id is "+android.os.Process.myPid()); // 12055
Log.e("current-thread-id is "+Thread.currentThread().getId()); // 1

//这时候看下当前系统中跑的所有进程，这个12055的进程就在这里面
ActivityManager mActivityManager = (ActivityManager)this.getSystemService(getApplicationContext().ACTIVITY_SERVICE);
        for (ActivityManager.RunningAppProcessInfo appProcess : mActivityManager.getRunningAppProcesses()) {
            if (appProcess.pid == pid) {
                processNameString = appProcess.processName;
            }
        }
```
至于原因的话，ActivityThread的handleCreateService方法中有这么一句： Application app = packageInfo.makeApplication(false, mInstrumentation);但是这个不会把MainActivity重新创建一个。

至于为什么要用多进程，[微信Android客户端后台保活经验分享](http://www.infoq.com/cn/articles/wechat-android-background-keep-alive)这篇文章中提到了微信至少用了三个进程，这篇文章还提到Shadowsocks-Android就开了个进程跑C程序来维护代理。记得系统给每个Application分配的内存总量不那么多，可以通过   
```java
Runtime runtime = Runtime.getRuntime();
LogUtil.w(TAG, String.valueOf(toMB(runtime.freeMemory()))); // 5.79MB
LogUtil.w(TAG, String.valueOf(toMB(runtime.totalMemory()))); //14.13MB
 private String toMB(long number) {
         return String.format("%.2f", number / 1024.0 / 1024.0);
     }               
```
大概也就几十个MB的样子，确实不是很多。多进程下，等于平白多了几十MB的内存，对于缓解性能压力还是有好处的。

### 28. 关于Android APK 安装过程
以下内容来自[Android APK 安装过程详解](http://blog.csdn.net/zhaokaiqiang1992/article/details/72863932)
首先APK 的本质是一个 Zip 压缩包，只是后缀被修改为 apk，其中打包了源代码编译出的 class.dex、一些图片视频资源文件和一些 Native 库文件。APK 文件与 Zip 文件最大的一个不同是 APK 包含签名信息，用于保证安装包安全不被修改。
> ODEX 文件是 Dalvik 将 DEX 文件中可执行文件——class.dex——文件解压出来后，存储在本地后生成的。因为 Android 系统无法直接运行 APK 文件，需要将其解压后找到 class.dex 文件后才可以运行，因此在安装时就将其取出放在本地，可以提高应用启动速度。除了这个原因，其实在将 class.dex 转换成 ODEX 文件过程中，还根据当前系统进行了优化（直接复制到其他系统不一定可以运行），文件大小会减少，ODEX 文件比 DEX 文件更难反编译，这也在一定程度上提高了安全性，因此在一些系统预装或系统级应用大多采用了 ODEX 优化。
一般 ODEX 不直接运行，在 Dalvik 运行 ODEX 时，需要通过 JIT 进行优化，提高运行效率。JIT 是一种在运行时同步将字节码转化成机器码的过程，Dalvik 直接运行转化后的机器码，这会导致部分的内存和时间开销，但是整体来说，在某些情况下是会提高系统性能的。（有些动态编译器，可能根据经验或尝试编译，优化这一过程，可能运行次数越多，优化效果越好）
OAT 文件是 ART 运行的文件，是一种二进制可运行文件，包含 DEX 文件和编译出的本地机器指令文件，其文件格式类似于网络数据报文，包含文件头和文件体，文件头的 oatdata、oatexec 和 oatlastword 字段分别描述 DEX 文件位置和本地机器指令的起止位置。因为 OAT 文件包含 DEX 文件，因此比 ODEX 文件占用空间更大，由于其在安装时经过了 ART 的处理，ART 加载 OAT 文件后不需要经过处理就可以直接运行，它没有了从字节码装换成机器码的过程，因此运行速度更快。可以理解为 JIT 从运行时才解析提前到了安装时解析，安装变慢，运行变快。
