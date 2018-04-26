---
title: Android手册-4
date: 2018-04-13 13:53:52
tags:
---


![](http://odzl05jxx.bkt.clouddn.com/image/jpg/street lights dark night car city bw.jpg?imageView2/2/w/600)

<!--more-->

## 1. 在子线程中显示一个Toast是亲测可行的
不是那种post到主线程的方案
[其实知乎上已经有了讨论](https://www.zhihu.com/question/51099935)
```java
static class ToastThread extends Thread {

     Context mContext;

     public ToastThread(Context mContext) {
         this.mContext = mContext;
     }

     @Override

     public void run() {
         Looper.prepare();
         String threadId = String.valueOf(Thread.currentThread().getId());
         Toast.makeText(mContext,threadId,Toast.LENGTH_SHORT).show();
         Looper.loop();
     }
 }
```
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/toast_transact.JPG)
其实Toast的原理就是通过IPC向NotificationManager请求加入队列，后者会检测权限xxxx。然后通过上面的ipc回调到客户端的onTransact中，这里也就是走到了Toast.TN这个static inner class的handler中，发送一个Message，handlerMessage中完成了WindowManager.addView的操作
需要注意的是，这里还是子线程，所以确实可能存在多条线程同时操作UI的现象。从形式上看，主线程和子线程中的Toast对象各自通过自己的Looper维护了一个消息循环队列，这其中的消息类型包括show,hide和cancel。所以可能存在多条线程同时调用WindowManager的方法，View也是每条线程各自独有的，最坏的场景莫过于两条线程同时各自添加了一个View到window上。另外，子线程中引入looper的形式也造成了子线程实质上的阻塞，当然可以直接当成一个handlerThread来用。
所以不是很推荐这么干，只是说可以做。
**Toast.TN.handleShow**
```java
try {
      mWM.addView(mView, mParams);
      trySendAccessibilityEvent();
  } catch (WindowManager.BadTokenException e) {
      /* ignore */
  }
```

## 2.ContentProvider的onCreate要早于Application的onCreate发生
比如ArchitectureComponent中的lifeCycle就是这么干的，写了个dummpy的contentProvider，在provider的onCreate中去loadLibrary.

## 3. 看到一个关于apk反编译和重新打包的帖子，非常好用
[Android apk反编译及重新打包流程](https://www.jianshu.com/p/792a08d5452c)，关键词apktool。
但是，360加固之后的apk是不能用dex2jar查看java代码的。

### 4.从base.apk谈到apk安装的过程
