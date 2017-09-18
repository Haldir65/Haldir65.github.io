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



##  4.对象池

## 5.MediaScanner是一个和有趣的可以扫描多媒体文件的类
[技术小黑屋](http://droidyue.com/blog/2014/07/12/scan-media-files-in-android-chinese-edition/)

### 6. Drawable跟单例有点像
[官方文档](https://developer.android.com/guide/topics/graphics/2d-graphics.html#drawables)上有这么一句，看起来很不起眼的
Note: Each unique resource in your project can maintain only one state, no matter how many different objects you instantiate for it. For example, if you instantiate two Drawable objects from the same image resource and change a property (such as the alpha) for one object, then it also affects the other. When dealing with multiple instances of an image resource, instead of directly transforming the Drawable object you should perform a tween animation.
这件事的意义在于，Drawable在整个Application中是单例。
简单来说，getDrawable每次返回的都是一个新的Drawable，但Drawable只是一个Wrapper，放在res文件夹里的Drawable资源在整个Application中是单例。
证明的方式很简单: 两个相同资源的Drawable可能不一样，但Drawable.getConstantState都是同一个instance。
原理的话，参考 [Cyril Mottier在2013年的演讲](https://www.youtube.com/watch?v=JuE13KXRMxg)
xml是binary optimized的，
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
被人为调用Bitmap.recycle()的res中的图片资源直接不能用了，怎么办，重新用BitmapFactory去decode呗。照说Android 3.0之后就不应该调用Recycle方法了，记得Chet Haase说过，Recycle doesn't do anything。

### 7. Aidl里面有些关键字
oneway关键字。
AIDL 接口的实现必须是完全线程安全实现。 oneway 关键字用于修改远程调用的行为。使用该关键字时，远程调用不会阻塞；它只是发送事务数据并立即返回
