---
title: 编程语言中使用到的多线程基础数据结构
date: 2019-01-30 07:53:33
tags: [java, tbd]
---

![](https://www.haldir66.ga/static/imgs/HongKongFireworks_ZH-CN13422096721_1920x1080.jpg)
主要讲讲java中的notify,wait,synchronized ，unsafe等多线程基础工具的使用方式。

<!--more-->
## java


### wait和notify
有一个异常叫做java.lang.IllegalMonitorStateException。意思就是没有在synchronized block中调用wait或者notify方法。
java Object中是有一个monitor对象的，wait和notify就是基于这个属性去实现的。只要在同一对象上去调用notify/notifyAll方法，就可以唤醒对应对象monitor上等待的线程了。
为什么jvm需要对象的头部信息呢，一是给GC，锁做标记，二是hash数据和分代年龄，三是为了从对象指针就可以会的其数据类型及动态分派的能力，四是数组类型需要有数量信息。

### synchronized关键字
从语法上讲，synchronized可以用在
instance　method(锁在这个instance上), static method (锁在这个class )以及method block(锁这一块代码逻辑)。
➜ $ cat SynchronizedSample.java 
```java
package com.me.harris.concurrent;

public class SynchronizedSample {
    public void method() {
        synchronized (this) {
            System.out.println("Method 1 start");
        }
    }
}
```
javac SynchronizedSample.java
javap -c SynchronizedSample
```
Warning: Binary file SynchronizedSample contains com.me.harris.concurrent.SynchronizedSample
Compiled from "SynchronizedSample.java"
public class com.me.harris.concurrent.SynchronizedSample {
  public com.me.harris.concurrent.SynchronizedSample();
    Code:
       0: aload_0
       1: invokespecial #1                  // Method java/lang/Object."<init>":()V
       4: return

  public void method();
    Code:
       0: aload_0
       1: dup
       2: astore_1   
       3: monitorenter  ///看这里
       4: getstatic     #2                  // Field java/lang/System.out:Ljava/io/PrintStream;
       7: ldc           #3                  // String Method 1 start
       9: invokevirtual #4                  // Method java/io/PrintStream.println:(Ljava/lang/String;)V
      12: aload_1
      13: monitorexit //看这里
      14: goto          22
      17: astore_2
      18: aload_1
      19: monitorexit
      20: aload_2
      21: athrow
      22: return
    Exception table:
       from    to  target type
           4    14    17   any
          17    20    17   any
}
```
java doc是这么解释的
>Each object is associated with a monitor. A monitor is locked if and only if it has an owner. The thread that executes monitorenter attempts to gain ownership of the monitor associated with objectref, as follows:
• If the entry count of the monitor associated with objectref is zero, the thread enters the monitor and sets its entry count to one. The thread is then the owner of the monitor.
• If the thread already owns the monitor associated with objectref, it reenters the monitor, incrementing its entry count.
• If another thread already owns the monitor associated with objectref, the thread blocks until the monitor's entry count is zero, then tries again to gain ownership.
看上去很像c语言里面的semctl嘛。
Synchronized是通过对象内部的一个叫做监视器锁（monitor）来实现的。但是监视器锁本质又是依赖于底层的操作系统的Mutex Lock来实现的。而操作系统实现线程之间的切换这就需要从用户态转换到核心态，这个成本非常高，状态之间的转换需要相对比较长的时间，这就是为什么Synchronized效率低的原因。因此，这种依赖于操作系统Mutex Lock所实现的锁我们称之为“重量级锁”。JDK中对Synchronized做的种种优化，其核心都是为了减少这种重量级锁的使用。JDK1.6以后，为了减少获得锁和释放锁所带来的性能消耗，提高性能，引入了“轻量级锁”和“偏向锁”。

[轻量级锁和偏向锁](http://www.cnblogs.com/paddix/p/5405678.html)

类似的，synchronized修饰的instance method在编译后添加了一个ACC_SYNCHRONIZED的flag，同步是通过这个标志实现的。


## 回顾一下用notify,wait,synchronized实现的生产者-消费者模型
基本的思路就是生产者和消费者共同持有一个锁（随便new一个Object出来就是了），生产者和消费者都extends Thread。
生产者的run方法里while(true)，再加上synchronized，往queue里面丢东西，塞满了就notify一下（让消费者去消费）。
消费者的run方法里面while(true)，再加上synchronized，从queue里面取东西，发现没东西了。notify一下其他人（让生产者去生产）。

## Sleep和wait的区别
不要搞混淆了，sleep是不会让出cpu的执行权的，而wait则会让出cpu执行权，也就是释放锁。

## yield的用法
yield是让当前线程从running的状态变成runnable的状态（不过这个方法很少用到）

## join的用法
和python一样，主线程调用childThread.join()就是让主线程等子线程执行完了之后再去执行后面的语句。不过从源码来看,join调用了wait。
```java
public final void join() throws InterruptedException {
    join(0); //这里面调用了wait方法，也就是主线程会wait住
}

public synchronized void start() {
    //Thread的start方法中做了相应的处理，所以当join的线程执行完成以后，会自动唤醒主线程继续往下执行
}
```
[调用join的线程总得被唤醒啊](https://stackoverflow.com/questions/9866193/who-and-when-notify-the-thread-wait-when-thread-join-is-called) stackoverflow上说是在native层面调用的notify。有人翻出来openjdk的cpp源码
```cpp
void JavaThread::run() {
  ...
  thread_main_inner();
}

void JavaThread::thread_main_inner() {
  ...
  this->exit(false);
  delete this;
}

void JavaThread::exit(bool destroy_vm, ExitType exit_type) {
  ...
  // Notify waiters on thread object. This has to be done after exit() is called
  // on the thread (if the thread is the last thread in a daemon ThreadGroup the
  // group should have the destroyed bit set before waiters are notified).
  ensure_join(this);
  ...
}

static void ensure_join(JavaThread* thread) {
  // We do not need to grap the Threads_lock, since we are operating on ourself.
  Handle threadObj(thread, thread->threadObj());
  assert(threadObj.not_null(), "java thread object must exist");
  ObjectLocker lock(threadObj, thread);
  // Ignore pending exception (ThreadDeath), since we are exiting anyway
  thread->clear_pending_exception();
  // Thread is exiting. So set thread_status field in  java.lang.Thread class to TERMINATED.
  java_lang_Thread::set_thread_status(threadObj(), java_lang_Thread::TERMINATED);
  // Clear the native thread instance - this makes isAlive return false and allows the join()
  // to complete once we've done the notify_all below
  java_lang_Thread::set_thread(threadObj(), NULL);
  lock.notify_all(thread);
  // Ignore pending exception (ThreadDeath), since we are exiting anyway
  thread->clear_pending_exception();
}
```
答案就在
lock.notify_all(thread);这里

[锁的实现](https://www.jianshu.com/p/acf667ccec40)
java中的锁一共有4种状态，级别从低到高分别是：
- 无锁状态
- 偏向锁
- 轻量级锁
- 重量级锁

### 偏向锁：
顾名思义，为了让线程获得锁的代价更低，引入了偏向锁。
**加锁**
当一个线程访问同步块并且获取锁时，会在对象头和栈帧中的锁记录里存储锁偏向的线程id，这样，这个线程便获取了这个对象的偏向锁，之后这个线程进入和退出就不需要通过CAS操作，也就是原子操作，来进行加锁和解锁，只需要简单的测试下对象头存储的偏向锁的线程id是否和自身的id一致，如果一致，那么已经获取锁，直接进入。否则，判断对象中是否已经存储了偏向锁，如果没有锁，那么使用CAS竞争锁，如果设置了，那么尝试使用CAS将对象头的偏向锁指向当前线程。
**解锁**
偏向锁的解锁时机是在竞争时才会释放锁,撤销时需要等待全局安全点，这个时间点没有正在执行的字节码，首先会暂停拥有偏向锁的线程，然后检查偏向锁的线程是否存活，如果不活动，那么直接设置为无锁状态。否则要么偏向其他锁，要么恢复到无锁或者标记对象不适合偏向锁。

### 轻量锁
会自旋尝试获取锁，消耗cpu资源
**加锁**
一旦多线程发起了锁竞争，并且释放了偏向锁之后，线程通过CAS修改Mark Word，如果当前没有对象持有同步体的锁，那么直接将同步体的锁修改的轻量锁，否则，该线程将自旋获取锁，直到膨胀为重量级锁，修改同步体的Mark Word为重量级锁，然后阻塞
**解锁**
一旦有其他线程因想获取当前锁而膨胀为重量级锁，那么这个线程将会通过CAS替换Mark Word，然后失败，解锁，并且唤醒其他等待线程。

### 重量级锁
会阻塞，不消耗cpu资源，但是响应时间较慢
synchronized
内部也是利用了锁。
每一个对象都有一个自己的monitor，必须先获取这个monitor对象才能够进入同步块或同步方法，而这个monitor对象的获取是排他的，也就是同一时刻只能有一个线程获取到这个monitor







[图解java并发](http://ifeve.com/图解java并发上/)
unSafe

hacknoon中有关于python中多线程primitives的文章
c语言中多线程通信基础
基本的思想都是相通的


## 参考
[美团博客中关于java锁的一片文章](https://tech.meituan.com/2018/11/15/java-lock.html)