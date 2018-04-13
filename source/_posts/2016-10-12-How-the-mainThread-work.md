---
title: 主线程的工作原理
date: 2016-10-12 16:47:42
tag:
    Handler
    Message
categories: blog
---

![](http://odzl05jxx.bkt.clouddn.com/writing%20code%20that%20nobody%20else%20can%20read.jpg)

​	今天突然找到这样一个问题: "Handler的postDelayed会阻塞线程吗？"。基于自己之前对于Handler的线程间通讯机制的理解，还是不能给出明确的答案。正好打算把一篇关于主线程的工作原理的文章写出来，顺带看下能否把这个问题从源码的角度解释清楚。<!--more-->

### 1. 从线程（Thread）开始
通常，一个Process会有一个主线程, 而在Android中，UI控件相关的方法和一些系统callback都会发生在主线程上(onResume,onCreate,onStartCommand,onDraw, etc)。 如果App中使用了多个Process，则每个Process都会有一个主线程，但这不是今天的重点。
Android应用是如何启动的?
启动一个应用时，系统会从Zygote Process fork出一个新的Process，最终走到ActivityThread 的main方法
```java
 public static void main(String[] args) {
 //省略部分无关代码
        Looper.prepareMainLooper();
        ActivityThread thread = new ActivityThread();
        thread.attach(false);
        if (sMainThreadHandler == null) {
            sMainThreadHandler = thread.getHandler();
        }
        // End of event ActivityThreadMain.
        Looper.loop();
        throw new RuntimeException("Main thread loop unexpectedly exited");//从这里可以猜到Looper.loop方法会一直执行下去
    }
```
看一下Looper.prepareMainLooper()方法：
```java

    /**
     * Initialize the current thread as a looper, marking it as an
     * application's main looper. The main looper for your application
     * is created by the Android environment, so you should never need
     * to call this function yourself.  See also: {@link #prepare()}
     */
    public static void prepareMainLooper() {
        prepare(false);
        synchronized (Looper.class) {
            if (sMainLooper != null) {
                throw new IllegalStateException("The main Looper has already been prepared.");
            }
            sMainLooper = myLooper();
        }
    }
```
大致意思就是为当前Thread添加一个Looper。
Looper.java是一个普通的class，其大致作用就是**为当前Thread维持一个message loop**，默认情况下一个Thread并没有一个Looper，要想添加一个，需要在该线程中调用Looper.prepare()，然后调用Looper.loop()方法即可让消息循环一直持续下去。大部分和message Loop的交互都是通过Handler这个类来进行的。例如
```java
class LooperThread extends Thread {
  *      public Handler mHandler;
  *
  *      public void run() {
  *          Looper.prepare();
  *
  *          mHandler = new Handler() {
  *              public void handleMessage(Message msg) {
  *                  // 在这里处理消息
  *              }
  *          };
  *
  *          Looper.loop();
    		//这里面发送消息
  *      }
  *  }
```
Looper持有一个MessageQueue(消息队列)成员变量，消息循环时，Looper就不断地从消息队列中拿出消息进行处理。
下面来看Looper.loop()方法里所做的事：
```java
  /** 删除了部分不相关的代码
     * Run the message queue in this thread. Be sure to call
     * {@link #quit()} to end the loop.
     */
    public static void loop() {
        final Looper me = myLooper();//返回当前线程中对应的Looper，看看下面的Exception就知道了
        if (me == null) {
            throw new RuntimeException("No Looper; Looper.prepare() wasn't called on this thread.");
        }
        final MessageQueue queue = me.mQueue;
        for (;;) {
            Message msg = queue.next(); // might block
            if (msg == null) {
                // No message indicates that the message queue is quitting.
                return;
            }
            try {
                msg.target.dispatchMessage(msg);
            } finally {
               ....省略
            }
        }
    }
```
简单解释一下，也就是从消息队列中取出新的消息(msg)。交给msg.target.dispatchMessage(msg)
这个trarget是个Handler
来看下Handler里面的dispatchMessage方法
```java
 /**
     * Handle system messages here.
     */
    public void dispatchMessage(Message msg) {
        if (msg.callback != null) {
            handleCallback(msg);
        } else {
            if (mCallback != null) {
                if (mCallback.handleMessage(msg)) {
                    return;
                }
            }
            handleMessage(msg);
        }
    }
```
很明显是一个either or 的过程：
Message这个类里面有个Runnable callback，如果这个message有callback的话，就执行这个runnable，否则执行handler.callBack.handleMessage。也就是我们经常用的
```java
Handler handler = new Handler(){
            @Override
            public void handleMessage(Message msg) {
                super.handleMessage(msg);
            }
        };
```
这种内部类的形式了
需要注意的是，Message最好不要用new，使用obtain方法获得，使用release方法释放，这里面有一个消息池的概念，我也不太理解。
MessageQueue中没有太多的公共方法，其中next()方法会返回
> message that should be processed. Will not return message that will be processed at future times.
> Message有一个long类型的变量Message.when，指的是这条消息最早可以被执行的时间，这个时间是基于SystemClock.uptimeMills()的。所以如果消息队列中没有一条message到达自己的可执行时间, 这个next()方法就会一直block。值得注意的是SystemClock.uptimeMills是基于CPU活动时间的，如果cpu处于sleep状态，这个sleep时间是不算的。所以如果你postDelayed了10s，假设cpu5s后开始休眠，10s后醒来，睡眠的这段时间是不算的。所以真正执行的时间可能还会往后延迟。

### 2. Handler
Handler基本上就做两件事
1. add message to the messageQueue of the Looper it's associated with
- post()  //把一条消息添加到所有可以被执行的消息的最后面，但在还没到时间的消息的前面
- postDelayed()/postAtTime() //一个相对时间，一个绝对时间
- postAtFrontOfQueue() // @piwai 插队行为，不要用
2. Handle message when this message doesn't have callback
   Handler的构造方法有7个,初始化时需要获得一个Looper
   常用的Handler handler = new Handler() 会创建一个基于当前线程的Looper的Handler,如果当前线程没有调用Looper.Prepare，会抛出一个异常，这些在源代码里都能看到。
   一些好用的构造函数
> Handler (Looper.getMainLooper()) //往主线程的Looper的消息队列里发消息
> Hanlder(Looper.myLooper()) //往当前线程Looper的消息队列里添加消息

### Choreographer
使用Android studio时，经常会在Logcat里看到这样的 info:
> Skipped 60 frames! The application may be doing too much work on its main thread

这段log出自Chreographer ，大意就是主线程上做的事太多或者做了太多不该在主线程上做的事。至于为什么不要在主线程上做太多的事，来看看主线程都有哪些工作:
System Events , Input Events ,Application callback ,Services, Alarm ,UI Drawing....另外，当屏幕内容发生变化，或者在Animation运行中，系统将会尝试每隔16ms来Draw a Frame。而这部分工作是由Choregrapher来完成的，而其内部是通过一个Handler来进行Frame更新的。

```java
FrameHandler mHandler = new FrameHandler(Looper.myLooper());
Message msg = mHandler.obtainMessage(MSG_DO_FRAME);
msg.setAsynchronous(true);
mHandler.sendMessageAtTime(msg,nextFrameTime)

 private final class FrameHandler extends Handler {
        public FrameHandler(Looper looper) {
            super(looper);
        }

        @Override
        public void handleMessage(Message msg) {
            switch (msg.what) {
                case MSG_DO_FRAME:
                    doFrame(System.nanoTime(), 0);
                    break;
                case MSG_DO_SCHEDULE_VSYNC:
                    doScheduleVsync();
                    break;
                case MSG_DO_SCHEDULE_CALLBACK:
                    doScheduleCallback(msg.arg1);
                    break;
            }
        }
    }
```
假设你在onMeasure,onLayout,onDraw这些方法中耽误主线程太多时间，Choregrapher将不能及时的更新Frame，哪怕你只耽误了1ms，系统也只能在16ms(大约)之后才能更新下一Frame。

### 3. 为了在开发中发现不应该在主线程中进行的操作(IO，网络)，可以使用StrictMode：
```java
if (BuildConfig.DEBUG) {
            StrictMode.setThreadPolicy(new StrictMode.ThreadPolicy.Builder()
                    .detectDiskReads()
                    .detectDiskWrites()
                    .detectNetwork()   // or .detectAll() for all detectable problems
                    .penaltyLog()
                    .build());
            StrictMode.setVmPolicy(new StrictMode.VmPolicy.Builder()
                    .detectLeakedSqlLiteObjects()
                    .detectLeakedClosableObjects()
                    .penaltyLog()
                    .penaltyDeath()
                    .build());
        }
```
### 4 .Activity LifeCycle Events
- Activity LifeCycle Events(startActivity(), finishi()) go out of your process through Binder IPC to the ActivityManager //有时候startActivity启动的Activity不是自己Process的,比如调用系统相机这种
- Then back on to your main queue in the form of lifeCycle callbacks(onCreate(),onDestory() et_al) // 异步，异步！



最后回到文章开头的那个问题：Handler.postDelay会阻塞线程吗？
答案在[这里](http://www.dss886.com/android/2016/08/17/17-18)找到了
postDelayed本身就是把一条消息推迟到相对时间多久之后。关键在Looper取出这条消息时，用的是
> Message msg = queue.next();  // might block

注释已经暗示了可能会阻塞，看下next方法做了什么:
```java
    Message next() {
    .....省略
        for (;;) {
            if (nextPollTimeoutMillis != 0) {
                Binder.flushPendingCommands();
            }

            nativePollOnce(ptr, nextPollTimeoutMillis);

            synchronized (this) {
                // Try to retrieve the next message.  Return if found.
                final long now = SystemClock.uptimeMillis();
                Message prevMsg = null;
                Message msg = mMessages;
                if (msg != null && msg.target == null) {
                    // Stalled by a barrier.  Find the next asynchronous message in the queue.
                    do {
                        prevMsg = msg;
                        msg = msg.next;
                    } while (msg != null && !msg.isAsynchronous());
                }
                if (msg != null) {
                    if (now < msg.when) {
                        // Next message is not ready.  Set a timeout to wake up when it is ready.
                        nextPollTimeoutMillis = (int) Math.min(msg.when - now, Integer.MAX_VALUE);
                    } else {
                        // Got a message.
                        mBlocked = false;
                        if (prevMsg != null) {
                            prevMsg.next = msg.next;
                        } else {
                            mMessages = msg.next;
                        }
                        msg.next = null;
                        msg.markInUse();
                        return msg;
                    }
                } else {
                    // No more messages.
                    nextPollTimeoutMillis = -1;
                }
              }
            }
	//....省略部分
}
```
首先进来 调用了nativePollOnce(ptr,nextPollTimeoutMillis);
这是个native方法，类似于线程的wait方法，不过使用了Native的方法会更加精准。可以认为是用native方法让这个queue.next的方法耗时延长了，所以return时返回的Message也就满足合适的时间。
往下看
>  // Next message is not ready.  Set a timeout to wake up when it is ready.       
>  nextPollTimeoutMillis = (int) Math.min(msg.when - now, Integer.MAX_VALUE);

所以确实是blocked了。但这并不意味着从postDelayed(r,10)开始，接下来的10ms就真的完全堵塞了(queue.next阻塞)
PostDelayed最终会调用到enqueMessage方法，看一下:
```java

        synchronized (this) {
            if (mQuitting) {
                IllegalStateException e = new IllegalStateException(
                        msg.target + " sending message to a Handler on a dead thread");
                Log.w(TAG, e.getMessage(), e);
                msg.recycle();
                return false;
            }

            msg.markInUse();
            msg.when = when;
            Message p = mMessages;
            boolean needWake;
            if (p == null || when == 0 || when < p.when) {
                // New head, wake up the event queue if blocked.
                msg.next = p;
                mMessages = msg;
                needWake = mBlocked;
            } else {
                // Inserted within the middle of the queue.  Usually we don't have to wake
                // up the event queue unless there is a barrier at the head of the queue
                // and the message is the earliest asynchronous message in the queue.
                needWake = mBlocked && p.target == null && msg.isAsynchronous();
                Message prev;
                for (;;) {
                    prev = p;
                    p = p.next;
                    if (p == null || when < p.when) {
                        break;
                    }
                    if (needWake && p.isAsynchronous()) {
                        needWake = false;
                    }
                }
                msg.next = p; // invariant: p == prev.next
                prev.next = msg;
            }

            // We can assume mPtr != 0 because mQuitting is false.
            if (needWake) {
                nativeWake(mPtr);
            }
        }
```
注意nativeWake方法，在满足一定情况下会唤醒线程
总结一下就是postDelayed确实调用了阻塞线程的方法，但一旦消息队列前面插入了可执行的message，会调用唤醒线程的方法。这些大部分在MessageQueue这个class中，看一下基本都能明白。

### 回顾一下整个过程:

主线程作为一个Thread，持有一个Looper对象，Looper持有一个MessageQueue的消息队列，并一个一个地从中取出满足执行时间条件的Message，执行Messgae的callback或者交给Handler的handleMessage去处理。

### 5. update
- MessageQueue里面有个IdleHandler,可以在消息队列空了时候安插一些事情去做，Glide用了这个特性，在主线程不那么忙的时候做了一些事
- nativePoolOnce能够挂起主线程和唤醒主线程的原理是使用了linux的管道：

以下文字出自[Android应用程序消息处理机制（Looper、Handler）分析](http://blog.csdn.net/luoshengyang/article/details/6817933)
>管道是Linux系统中的一种进程间通信机制，具体可以参考前面一篇文章Android学习启动篇推荐的一本书《Linux内核源代码情景分析》中的第6章--传统的Uinx进程间通信。简单来说，管道就是一个文件，在管道的两端，分别是两个打开文件文件描述符，这两个打开文件描述符都是对应同一个文件，其中一个是用来读的，别一个是用来写的，一般的使用方式就是，一个线程通过读文件描述符中来读管道的内容，当管道没有内容时，这个线程就会进入等待状态，而另外一个线程通过写文件描述符来向管道中写入内容，写入内容的时候，如果另一端正有线程正在等待管道中的内容，那么这个线程就会被唤醒。这个等待和唤醒的操作是如何进行的呢，这就要借助Linux系统中的epoll机制了。 Linux系统中的epoll机制为处理大批量句柄而作了改进的poll，是Linux下多路复用IO接口select/poll的增强版本，它能显著减少程序在大量并发连接中只有少量活跃的情况下的系统CPU利用率。但是这里我们其实只需要监控的IO接口只有mWakeReadPipeFd一个，即前面我们所创建的管道的读端，为什么还需要用到epoll呢？有点用牛刀来杀鸡的味道。其实不然，这个Looper类是非常强大的，它除了监控内部所创建的管道接口之外，还提供了addFd接口供外界面调用，外界可以通过这个接口把自己想要监控的IO事件一并加入到这个Looper对象中去，当所有这些被监控的IO接口上面有事件发生时，就会唤醒相应的线程来处理，不过这里我们只关心刚才所创建的管道的IO事件的发生。


有一个开发者永远不应该主动调用的方法：
纵观整个Android系统，Lopper的这个方法只在两处被调用。
```java
/**
 * Initialize the current thread as a looper, marking it as an
 * application's main looper. The main looper for your application
 * is created by the Android environment, so you should never need
 * to call this function yourself.  See also: {@link #prepare()}
 */
public static void prepareMainLooper() {
        prepare(false);
        synchronized (Looper.class) {
            if (sMainLooper != null) {
                throw new IllegalStateException("The main Looper has already been prepared.");
            }
            sMainLooper = myLooper();
        }
    }
```
android.app.ActivityThread中和com.android.server.SystemServer中分别调用了这个方法，言下之意systemServer虽然跑在app_process进程中，但其实也还是有一个looper的循环模型的。



### Reference
1. [Handler.postDelayed()是如何精确延迟指定时间的](http://www.dss886.com/android/2016/08/17/17-18)
2. [How the Main Thread works](https://www.youtube.com/watch?v=aFGbv9Ih9qQ)
3. [安卓中为什么主线程不会因为Looper中的死循环而卡死？](http://www.cnblogs.com/linguanh/p/6412042.html)
