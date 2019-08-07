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

[抛出异常也需要获得锁](https://javadoop.com/post/Threads-And-Locks-md)
wait方法抛出了InterruptedException异常，即使是异常，也是要获取到监视器锁了才会抛出

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
Synchronized是通过对象内部的一个叫做监视器锁（monitor）来实现的，monitor对象存在于每一个java对象的对象头中(具体点是存的是指针)。但是监视器锁本质又是依赖于底层的操作系统的Mutex Lock来实现的。而操作系统实现线程之间的切换这就需要从用户态转换到核心态，这个成本非常高，状态之间的转换需要相对比较长的时间，这就是为什么Synchronized效率低的原因。因此，这种依赖于操作系统Mutex Lock所实现的锁我们称之为“重量级锁”。JDK中对Synchronized做的种种优化，其核心都是为了减少这种重量级锁的使用。JDK1.6以后，为了减少获得锁和释放锁所带来的性能消耗，提高性能，引入了“轻量级锁”和“偏向锁”。

## Java虚拟机对synchronized的优化
锁的状态总共有四种，无锁状态、偏向锁、轻量级锁和重量级锁。随着锁的竞争，锁可以从偏向锁升级到轻量级锁，再升级的重量级锁，但是锁的升级是单向的，也就是说只能从低到高升级，不会出现锁的降级

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


[轻量级锁和偏向锁](https://blog.csdn.net/javazejian/article/details/72828483)

类似的，synchronized修饰的instance method在编译后添加了一个ACC_SYNCHRONIZED的flag，同步是通过这个标志实现的。


## 回顾一下用notify,wait,synchronized实现的生产者-消费者模型

基本的思路就是生产者和消费者共同持有一个锁（随便new一个Object出来就是了），生产者和消费者都extends Thread。
生产者每次生产一个都会notifyAll，消费者每次消费一个都会notifyAll

[在Java中，每个对象都有两个池，锁(monitor)池和等待池](http://cmsblogs.com/?p=2915)
锁池 :假设线程A已经拥有了某个对象(注意:不是类)的锁，而其它的线程想要调用这个对象的某个synchronized方法(或者synchronized块)，由于这些线程在进入对象的synchronized方法之前必须先获得该对象的锁的拥有权，但是该对象的锁目前正被线程A拥有，所以这些线程就进入了该对象的锁池中。
等待池 :假设一个线程A调用了某个对象的wait()方法，线程A就会释放该对象的锁(因为wait()方法必须出现在synchronized中，这样自然在执行wait()方法之前线程A就已经拥有了该对象的锁)，同时线程A就进入到了该对象的等待池中。如果另外的一个线程调用了相同对象的notifyAll()方法，那么处于该对象的等待池中的线程就会全部进入该对象的锁池中，准备争夺锁的拥有权。如果另外的一个线程调用了相同对象的notify()方法，那么仅仅有一个处于该对象的等待池中的线程(随机)会进入该对象的锁池.

也即是被notify的线程都在锁池里(有权竞争cpu)，自己调用wait的线程都在等待池里(无权竞争cpu)。 那么什么时候竞争呢，持有锁的线程自己wait(释放锁)了，那么有权竞争的线程就开始竞争，获得锁的进入同步代码块或者同步方法。

需要注意的是
***notify/notifyAll方法调用后，并不会马上释放监视器锁，而是在相应的synchronized(){}/synchronized方法执行结束后才自动释放锁。***

wait方法就是将当前线程加入object的waitSet同时释放锁（理解成一个hashset也行），notifyAll则是把waitset里面的内容全部挪到blocked队列中，在notifyAll的线程执行完毕释放锁之后，挑选一个获得锁。[JVM源码分析之Object.wait/notify实现](https://www.jianshu.com/p/f4454164c017)

[oracle的文档上说明了,wait有一个spurious wakeup](https://docs.oracle.com/javase/8/docs/api/java/lang/Object.html#wait()) 是出于performance考虑，表现为wait的线程不需要notify也能自己醒过来。(文档中也指出了，这也就是为什么每一个wait都要包在一个while loop里面的原因)。这一现象在某些os上，包括linux上就有。
Effective java里面说要把wait写在一个while检查里面
```java
// The standard idiom for calling the wait method in Java 
synchronized (sharedObject) { 
    while (condition) { 
      sharedObject.wait(); // 就是为了防止spurious wakeup
    } 
    // do action based upon condition e.g. take or put into queue 
}
```
[how not to do java concurrency](https://www.youtube.com/watch?v=Oi6-pXX11qw)



以下代码验证通过
```java
public class Test1 {

    private static int count = 0;
    private static final int FULL = 5;
    private static final String LOCK = "lock";


    public static void main(String[] args) {
        Test1 instance = new Test1();
        new Thread(instance.new Producer()).start();
        new Thread(instance.new Consumer()).start();
    }

    class Producer implements Runnable{

        @Override
        public void run() {
            for (int i = 0; i < 10; i++) {
                synchronized (LOCK){
                    while (count==FULL){
                        try{
                            System.out.println("PRODUCER WILL WAITING");
                            LOCK.wait();
                            System.out.println("PRODUCER END WAITING");
                            // 进入 wait()方法后，当前线程释放锁。在从 wait()返回前，线程与其他线程竞争重新获得锁
                        }catch (Exception e){
                            e.printStackTrace();
                        }
                    }
                    count++;
                    System.out.println(Thread.currentThread().getName() + "生产者生产，目前总共有" + count);
                    LOCK.notifyAll();//当前处在wait状态的线程不会马上获得锁
                }
                //退出synchronize代码块之后，程序退出 synchronized 代码块后，当前线程才会释放锁，wait所在的线程也才可以获取该对象锁
            }
        }
    }

    class Consumer implements Runnable {

        @Override
        public void run() {
            for (int i = 0; i < 10; i++) {
                synchronized (LOCK){
                    while (count==0){
                        try {
                            System.out.println("CONSUMER WILL WAITING");
                            LOCK.wait();
                            System.out.println("CONSUMER END WAITING");
                            // 进入 wait()方法后，当前线程释放锁。在从 wait()返回前，线程与其他线程竞争重新获得锁
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                    }
                    count--;
                    System.out.println(Thread.currentThread().getName()+"消费者消费，当前还剩下"+count+"个");
                    LOCK.notifyAll();
                }
            }
        }
    }
}
```
对应输出如下（输出结果不确定）
```
Thread-0生产者生产，目前总共有1
Thread-0生产者生产，目前总共有2
Thread-0生产者生产，目前总共有3
Thread-0生产者生产，目前总共有4
Thread-0生产者生产，目前总共有5
PRODUCER WILL WAITING        //producer线程开始wait，阻塞在这里
Thread-1消费者消费，当前还剩下4个 // 消费者线程进入Synchronized代码块
PRODUCER END WAITING //消费者每次在执行完synchronized代码块都会notifyAll，所以生产者又开始竞争锁，这一次居然抢到了，于是之前的wait返回
Thread-0生产者生产，目前总共有5 //发现满了，重复上面的wait步骤
PRODUCER WILL WAITING  //释放锁
Thread-1消费者消费，当前还剩下4个 //锁被别人抢到
PRODUCER END WAITING //别人notify导致我抢到了锁
Thread-0生产者生产，目前总共有5
PRODUCER WILL WAITING
Thread-1消费者消费，当前还剩下4个
PRODUCER END WAITING
Thread-0生产者生产，目前总共有5
PRODUCER WILL WAITING
Thread-1消费者消费，当前还剩下4个
PRODUCER END WAITING
Thread-0生产者生产，目前总共有5
PRODUCER WILL WAITING
Thread-1消费者消费，当前还剩下4个
PRODUCER END WAITING
Thread-0生产者生产，目前总共有5 //生产者最后一次生产
Thread-1消费者消费，当前还剩下4个
Thread-1消费者消费，当前还剩下3个
Thread-1消费者消费，当前还剩下2个
Thread-1消费者消费，当前还剩下1个
Thread-1消费者消费，当前还剩下0个
```

从代码执行顺序来看，wait方法调用后，当前线程阻塞住(虽然还在一个同步代码块中，直到别的线程notify，这个wait方法才会返回)，此时另一个线程竞争获取锁开始执行同步代码块。

synchronized对于内存可见性的影响[java内存模型](https://javadoop.com/post/java-memory-model)
一个线程在获取到监视器锁以后才能进入 synchronized 控制的代码块，一旦进入代码块，首先，该线程对于共享变量的缓存就会失效，因此 synchronized 代码块中对于共享变量的读取需要从主内存中重新获取，也就能获取到最新的值。
退出代码块的时候的，会将该线程写缓冲区中的数据刷到主内存中，所以在 synchronized 代码块之前或 synchronized 代码块中对于共享变量的操作随着该线程退出 synchronized 块，会立即对其他线程可见（这句话的前提是其他读取共享变量的线程会从主内存读取最新值）。

## Thread.sleep并不释放锁，只是让出cpu执行时间
Thread.sleep和Object.wait都会暂停当前的线程，对于CPU资源来说，不管是哪种方式暂停的线程，都表示它暂时不再需要CPU的执行时间。OS会将执行时间分配给其它线程。区别是，调用wait后，需要别的线程执行notify/notifyAll才能够重新获得CPU执行时间。
所以在同步代码块里执行sleep是一个很糟糕的做法


## interrupt与线程中断
```java
//中断线程（实例方法）
public void Thread.interrupt();

//判断线程是否被中断（实例方法）
public boolean Thread.isInterrupted();

//判断是否被中断并清除当前中断状态（静态方法）
public static boolean Thread.interrupted();
```

这个要背下来javadoc的描述，因为不同操作系统上的实现细节可能有差异:
>  /**
     * Interrupts this thread.
     *
     * <p> Unless the current thread is interrupting itself, which is
     * always permitted, the {@link #checkAccess() checkAccess} method
     * of this thread is invoked, which may cause a {@link
     * SecurityException} to be thrown.
     *
     * <p> If this thread is blocked in an invocation of the {@link
     * Object#wait() wait()}, {@link Object#wait(long) wait(long)}, or {@link
     * Object#wait(long, int) wait(long, int)} methods of the {@link Object}
     * class, or of the {@link #join()}, {@link #join(long)}, {@link
     * #join(long, int)}, {@link #sleep(long)}, or {@link #sleep(long, int)},
     * methods of this class, then its interrupt status will be cleared and it
     * will receive an {@link InterruptedException}.
     *
     * <p> If this thread is blocked in an I/O operation upon an {@link
     * java.nio.channels.InterruptibleChannel InterruptibleChannel}
     * then the channel will be closed, the thread's interrupt
     * status will be set, and the thread will receive a {@link
     * java.nio.channels.ClosedByInterruptException}.
     *
     * <p> If this thread is blocked in a {@link java.nio.channels.Selector}
     * then the thread's interrupt status will be set and it will return
     * immediately from the selection operation, possibly with a non-zero
     * value, just as if the selector's {@link
     * java.nio.channels.Selector#wakeup wakeup} method were invoked.
     *
     * <p> If none of the previous conditions hold then this thread's interrupt
     * status will be set. </p>
     *
     * <p> Interrupting a thread that is not alive need not have any effect.
     *
     * @throws  SecurityException
     *          if the current thread cannot modify this thread
     *
     * @revised 6.0
     * @spec JSR-51
     */
概括下来就是在wait,i/o操作，或者selector操作的中间调用线程对象的interrupt方法会抛出InterruptedException，如果不是上述三种情况之一，则将重置isInterrupted的标志位。也就意味着对于这种非阻塞的线程是不会因为interrupt方法而停下来的

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


### unsafe
这个类的源码在sun.misc这个package下，看源码的话需要导入openjdk源码
和多线程相关的类是LockSupport,让一个线程休眠的方法使用的是LockSupport.park（AQS中挂起线程的就是在parkAndCheckInterrupt中使用了这个方法）调用了Unsafe.park方法（这是个native方法，c++的实现似乎是使用了pthread_mutex）



[图解java并发](http://ifeve.com/图解java并发上/)


[pv操作](https://liujiacai.net/blog/2018/12/29/how-java-synchronizer-work/)



## 参考
[美团博客中关于java锁的一篇文章](https://tech.meituan.com/2018/11/15/java-lock.html)

[AQS这个java并发基础类的实现原理](https://javadoop.com/post/AbstractQueuedSynchronizer)