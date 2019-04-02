---
title: java多线程中需要注意的一些点
date: 2017-08-03 21:04:28
tags: [java,tools,concurrency]
---

![](https://www.haldir66.ga/static/imgs/be3c80a11edfd0fdb75d098550ed2c8e.jpg)
<!--more-->

> The difference between “concurrent” and “parallel” execution
[Good to know](https://stackoverflow.com/questions/1897993/what-is-the-difference-between-concurrent-programming-and-parallel-programming)
构造函数也不是线程安全的(因为指令重排)



## 1. 可重入锁的概念
可重入锁，也叫做递归锁，指的是同一线程 外层函数获得锁之后 ，内层递归函数仍然有获取该锁的代码，但不受影响。

> A ReentrantLock is owned by the thread last successfully locking, but not yet unlocking it. A thread invoking lock will return, successfully acquiring the lock, when the lock is not owned by another thread. The method will return immediately if the current thread already owns the lock.

也就是说如果当前占用锁的人就是当前线程，那么再次调用lock方法将直接返回。

比方说
>lock.lock()
    ---  lock.lock()
    ---  lock.unlock()
lock.unlock()

ReentrantLock和synchronized都是可重入锁

```java
@Override
       public void run() {
           final ReentrantLock lock = this.lock;
           lock.lock(); //拿不到lock的Thread会挂起
           try {
               this.mList.add("new elements added by" + mIndex + ""); //对共享资源的操作放这里
           }
           finally {
               lock.unlock(); //记得解锁
           }
       }
```

非可重入锁的例子
```java
//一种非可重入锁
class Lock{
    private boolean isLocked = false;
    public synchronized void lock() throws InterruptedException{
        while(isLocked){
            wait();
        }
        isLocked = true;
    }
    public synchronized void unlock(){
        isLocked = false;
        notify();
    }
}
public class TestLock {
        private Lock lock = new Lock();
//    private Lock lock = new ReentrantLock();
    public void t1() throws Exception{
        lock.lock();
        System.out.println("t1执行了");
        t2();
        lock.unlock();
    }

    public void t2() throws Exception{
        lock.lock();
        System.out.println("t2也执行了");
        lock.unlock();
    }

    public static void main(String[] args) throws Exception{
        new TestLock().t1();
    }
}
```
输出:
> t1执行了 程序一直在跑，因为wait住了

ReentrantLock的构造函数可以传一个boolean进去，表示公平锁还是非公平锁，默认是非公平锁。
在获取锁的时候，非公平锁是新到的线程和等待队列中的线程一起竞争锁，但公平锁则始终保证等待最长的线程获取锁。


## 2. ThreadLocal比较好的用例在Andriod的Looper中
Looper.prepare()
```java
private static void prepare(boolean quitAllowed) {
      if (sThreadLocal.get() != null) {
          throw new RuntimeException("Only one Looper may be created per thread");
      }
      sThreadLocal.set(new Looper(quitAllowed));//sThreadLocal是static的，注意leak
  }

// ThreadLocal
  public void set(T value) {
        Thread t = Thread.currentThread();
        ThreadLocalMap map = getMap(t); //ThreadLocalMap就是一个Entry为WeakReference（WeakRWeakReference不是有get方法嘛，也是key-value的形式）。上面返回当前Thread的成员变量。（所以说Thread创建也是很耗费内存的嘛）
        if (map != null)
            map.set(this, value);//注意这个this是sThreadLocal，static的
        else
            createMap(t, value);
    }  
```
一个比较好的关于ThreadlLocal为什么容易leak的[解释](http://blog.xiaohansong.com/2016/08/06/ThreadLocal-memory-leak/)，ThreadLocal是作为ThreadLocalMap中的Entry的key存在的，也就是Thread-> ThreadLocalMap -> Entry -> WeakReference of ThreadLocal 。想想一下，假如外部调用者释放了ThreadLocal的引用，这个Entry中的key就成为null了，但是这个Entry中的Value还在，一直被Thread持有着。所以这事还是在于Thread的生命周期可能很长。fix的方案： 外部确定不用的时候记得调用下remove就好了。


所以避免leak的话，记得调用ThreadLocal.remove
每一条线程调用ThreadLocal的set方法时都只能改变属于自己（线程）的值，调用get的时候也只能读到自己曾经设置的值。在多条线程面前，一个ThreadLocal本身并不是容器，因为数据实际上放在了Thread的一个map里面，每条线程只能保存或者更改读取自己的保险柜里的东西，保险柜钥匙即ThreadLocal自身。

## 3. Fork/join since java 7
有些任务是可以分块的。[work-stealing的实现](http://ifeve.com/java7-fork-join-and-closure/)

## 4. ArrayBlockingQueue<E> Thread Safe
构造函数里面就加了锁，是为了避免指令重排，保证可见性

## 5.ReentrantLock 不公平锁
在jdk1.5里面，ReentrantLock的性能是明显优于synchronized的，但是在jdk1.6里面，synchronized做了优化，他们之间的性能差别已经不明显了。

## 6. StampedLocks(java 8)
java 1.5 就有了ReentrantReadWriteLock，用于实现专门针对读或者写的lock
java 8提供了StampedLocks,lock方法返回一个long的时间戳，可以用这个时间戳release lock，或者检测lock是否有效。例如，tryConvertToOptimisticRead,假如在这个读的时间段内未发生其他线程的写操作，可以认为数据是有效的。像这样
- 假如有线程通过lock.writeLock()获得了写锁，只要不unlockWrite，所有的调用lock.readLock或者tryConvertToOptimisticRead都不会成功。
- 假如有线程获取了读锁，即调用了lock.readLock()，或者tryReadLock获得读取锁。读取获取锁并不是加锁，读并不是危险操作，获取锁只是为了检测读取的过程中是否发生过写
- Optimistic Reading ，即tryConvertToOptimisticRead,只有在当前锁不被写持有的时候才返回一个非零值，这个值用于在读取完毕之后用validate检测本次读取的间隙中是否发生过写操作。

## 7. Android官方文档上对于happens-before的准则有详细的描述
[happens-before](https://developer.android.com/reference/java/util/concurrent/package-summary.html#MemoryVisibility)，主要是jdk本身提供的primitive遵守的并发准则。

## 8. lock的声明方式

一般synchronize(object)就好了,但有更经济的方式
```java
Object lock = new Object();

private byte[] lock = new byte[0]; // 特殊的instance变量

  Public void methodA()
  {

     synchronized(lock) {
       //…
     }

  }

```
零长度的byte数组对象创建起来将比任何对象都经济――查看编译后的字节码：生成零长度的byte[]对象只需3条操作码，而
```java
Object lock = new Object() ;则需要7行操作码。
```

## 9. CountdownLatch和CyclicBarrier
分别举一个例子
```java
public class CountDownLatchTest {

    private int threadNum = 5;//执行任务的子线程数量
    private int workNum = 20;//任务数量
    private ExecutorService service;
    private ArrayBlockingQueue<String> blockingQueue;
    private CountDownLatch latch;

    @Before
    public void setUp() {
        service = Executors.newFixedThreadPool(threadNum, new ThreadFactoryBuilder().setNameFormat("WorkThread-%d").build());
        blockingQueue = new ArrayBlockingQueue<>(workNum);
        for (int i = 0; i < workNum; i++) {
            blockingQueue.add("任务-" + i);
        }
        latch = new CountDownLatch(workNum);//计数器的值为任务的数量
    }

    @Test
    public void test() throws InterruptedException {
        SoutUtil.print("主线程开始运行");
        for (int i = 0; i < workNum; i++) {
            service.execute(new WorkRunnable());
        }
        latch.await();//等待子线程的所有任务完成
        SoutUtil.print("主线程去做其它事");
    }

    //用blockQueue中的元素模拟任务
    public String getWork() {
        return blockingQueue.poll();
    }

    class WorkRunnable implements Runnable {

        public void run() {
            String work = getWork();
            performWork(work);
            latch.countDown();//完成一个任务就调用一次
        }
    }

    private void performWork(String work) {
        SoutUtil.print("处理任务：" + work);
        try {
            //模拟耗时的任务
            Thread.currentThread().sleep(60);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

}
```
CountDownLatch的await方法会阻塞主线程直到N减少到0。

CyclicBarrier的例子

```java
public class CyclicBarrierDemo {
  public static void main(String[] args) {
    int totalThread = 5;
    CyclicBarrier barrier = new CyclicBarrier(totalThread);

    for(int i = 0; i < totalThread; i++) {
      String threadName = "Thread " + i;
      new Thread(() -> {
        System.out.println(String.format("%s\t%s %s", new Date(), threadName, " is waiting"));
        try {
          barrier.await();// 必须等所有线程完成了上面的操作，后面的操作才能执行。
        } catch (Exception ex) {
          ex.printStackTrace();
        }
        System.out.println(String.format("%s\t%s %s", new Date(), threadName, "ended"));
      }).start();
    }
  }
}
```
CyclicBarrier是等大家都调完await之后才开始各自走下一步

CountDownLatch：一个或者多个线程，等待其他多个线程完成某件事情之后才能执行；
CyclicBarrier：多个线程互相等待，直到到达同一个同步点，再继续一起执行。


## 10.指令重排不是说说而已
 在多线程的场景下，无逻辑相关的代码写的前后顺序并无意义，原因是编译器会进行指令重排。
为什么说指令重排序会影响 items 的可见性呢？创建一个对象要分为三个步骤：

```
1 分配内存空间
2 初始化对象
3 将内存空间的地址赋值给对应的引用
```
但是由于指令重排序的问题，步骤 2 和步骤 3 是可能发生重排序的，如下：
```
1 分配内存空间
2 将内存空间的地址赋值给对应的引用
3 初始化对象
```
这也就解释了我们平时是[如何正确地写出单例模式](http://wuchong.me/blog/2014/08/28/how-to-correctly-write-singleton-pattern/)

volatile 在Java中一个特性是保证可见性，另一个是禁止指令重排序优化。


## 11.HashMap不是线程安全的，可能会在reHash里形成死锁
[非常烧脑](https://juejin.im/post/5a224e1551882535c56cb940)

## 12. wait和notify搭配使用，sleep是不释放锁的
转自[sleep和wait到底什么区别](http://www.jasongj.com/java/multi_thread/)
wait是在当前线程持有wait对象锁的情况下，暂时放弃锁，并让出CPU资源，并积极等待其它线程调用同一对象的notify或者notifyAll方法。注意，即使只有一个线程在等待，并且有其它线程调用了notify或者notifyAll方法，等待的线程只是被激活，但是它必须得再次获得锁才能继续往下执行。换言之，即使notify被调用，但只要锁没有被释放，原等待线程因为未获得锁仍然无法继续执行。

wait和notify都必须包在synchronized代码块中（必须在获得锁的前提下调用）

Sleep是Thread对象的静态方法，sleep并不释放锁，也不要求持有锁。

Thread.yield方法是让当前线程从执行状态变成就绪状态（就是和大家一起抢）

synchronized关键字一般有三种用法

**一、实例同步方法**
synchronized用于修饰实例方法（非静态方法）时，执行该方法需要获得的是该类实例对象的内置锁（同一个类的不同实例拥有不同的内置锁）。如果多个实例方法都被synchronized修饰，则当多个线程调用同一实例的不同同步方法（或者同一方法）时，需要竞争锁。但当调用的是不同实例的方法时，并不需要竞争锁。
也正是如此，一个同步方法被调用时，就等于独占了当前实例的锁，其他线程无法调用当前实例的其他同步方法。所以不是很推荐使用同步方法。
**二、静态同步方法**
synchronized用于修饰静态方法时，执行该方法需要获得的是该类的class对象的内置锁（一个类只有唯一一个class对象）。调用同一个类的不同静态同步方法时会产生锁竞争。
**三、同步代码块**
synchronized用于修饰代码块时，进入同步代码块需要获得synchronized关键字后面括号内的对象（可以是实例对象也可以是class对象）的内置锁。

java io为什么慢，有一个原因是InputStream的read方法和OutputStream的write方法都是加了synchronized的。而Okio里面synchronized方法我没找到，另外，真的想要io性能的话，用nio。

同步一个对象的前提是各方都同意使用同一把锁作为调用方法的前提，单方面加锁并不限制不尊重锁机制的使用者。两条线程分别去取两个互不相干的锁，这里面当然不存在阻塞问题。

## 13. CAS操作是有操作系统提供了硬件级别的原子操作的。  
CAS属于乐观的一种，假如比较之后发现OK那最好，假如不成功还允许继续尝试。jdk中使用的是UnSafe这个类，这个类属于“后门”，开发者可以使用这个类直接操控HotSpot jvm内存和线程。被广泛应用于juc包中。

比如说直接操纵内存
```java
Unsafe unsafe = getUnsafe();
Class aClass = A.class;
A a = (A) unsafe.allocateInstance(aClass);
```
最好不要在工程中使用。

## 14.ArrayBlockingQueue和LinkedBlockingQueue

线程池的构造方法最后一个参数是一个BlockingQueue，BlockingQueue是一个接口，就像一个典型的生产者消费者模型问题一样。如果从queue中取element的时候发现size为0，或者往queue中添加element的时候发现queue满了。应对这种资源不能被 ***立即满足*** 的策略就定义了BlockingQueue。
BlockingQueue提供了四种应对策略来处理这种资源不能被立即satisfy的场景

| 空值     | 抛出异常     |   返回一个特殊值 | 阻塞 | 调用者提供一个超时 |
| :------------- | :------------- |:------------- |:------------- |:------------- |
| 插入     | add(e)      | offer(e) | put(e)  | put(e, time ,timeUnit) |
| 移除     | remove()     | poll() | take()  | poll(time,timeUnit) |
| 检查     | element()  | peek()  | 不可用 | 不可用 |

文档上说： Usage example, based on a typical producer-consumer scenario. Note that a BlockingQueue can safely be used with multiple producers and multiple consumers.（BlockingQueue能够安全的用于多个生产者消费者的场景，就是说这个容器已经帮外部处理好了生产和消费并发的同步问题，其实就是加锁）

BlockingQueue的常用的实现类包括ArrayBlockingQueue(FIFO)和LinkedBlockingQueue(FIFO)。

ArrayBlockingQueue是一个由数组实现的 **有界阻塞队列**。该队列采用 ***FIFO*** 的原则对元素进行排序添加。
ArrayBlockingQueue的入列核心方法是enqueue，而这个方法的调用是被包在一个lock.lock和lock.unlock中的，所以是同步的。出列的核心方法是dequeue，也是包在同步lock里面的。构造函数可以传一个fair进来。

LinkedBlockingQueue是Exexutors中使用的创建线程池的静态方法中使用的参数，显然更推荐使用。主要用的是两个方法，
put方法在队列满的时候会阻塞直到有队列成员被消费，take方法在队列空的时候会阻塞，直到有队列成员被放进来。官方文档提到了， **LinkedBlockingQueue的吞吐量通常要高于基于数组的队列，但在大多数并发应用程序中，其可预知的性能要低一些** ， 内部的lock只能是unfair的。

在线程池(ThreadPoolExecutor)中，获取任务使用的是queue的**poll**方法，添加任务使用的是queue的**offer**方法。就是说“不堵塞”


## 15. AtomicXXX只是将value写成volatile，这样get就安全了，set的话直接交给Unsafe了
volatile并不是Atomic操作，例如，A线程对volatile变量进行写操作(实际上是读和写操作)，B线程可能在这两个操作之间进行了写操作；例如用volatile修饰count变量那么 count++ 操作就不是原子性的。而AtomicInteger类提供的atomic方法可以让这种操作具有原子性如getAndIncrement()方法会原子性的进行增量操作把当前值加一,因为AtomicInteger的getAndIncrement方法就是简单的调用了Unsafe的getAndAddInt。


[CAS还是不能解决ABA问题](https://mp.weixin.qq.com/s/nRnQKhiSUrDKu3mz3vItWg) 在java中用AtomicStampedReference就可以了

ABA问题简单说就是两条线程1,2同时想把100改成50，这时1用CAS改好了，2因为某些问题堵住了，恰好这个时候3线程跑进来把50改成了100，这之后2结束堵塞，用CAS比较，嗯，预期是100，没错，直接CAS变成50.（然而正常情况下结果应该是100，也就是说减法操作做了两次）

java.util.concurrent.atomic下包括AtomicBoolean、AtomicInteger...还有AtomicLongFiledUpdater


## 16. 读多写少的场景下的同步
 CopyOnWriteArrayList和Collections.synchronizedList相比。在高并发前提下，前者读的性能更好，后者写的性能更好（前者的写性能极差）。[CopyOnWriteArrayList与Collections.synchronizedList的性能对比](http://blog.csdn.net/yangzl2008/article/details/39456817)。CopyOnWriteArrayList适合做缓存。
 **ReentrantReadWriteLock** 用于针对读多写少的场景进行优化。（获得读锁后，其它线程可获得读锁而不能获取写锁
 获得写锁后，其它线程既不能获得读锁也不能获得写锁）


java 无锁状态、偏向锁、轻量级锁和重量级锁

## 17. CompletableFuture等java 8 的api
[AtomicLongFieldUpdater](http://normanmaurer.me/blog/2013/10/28/Lesser-known-concurrent-classes-Part-1/)比AtomicLong更加省内存的方式


## 18.ScheduledThreadPoolExecutor用于定期执行任务
首先要知道的是早期（jdk1.5之前）可以使用TimerTask去定期执行任务，但是因为其内部实现是只有一条线程，所以难免会因为前面堵塞而达不到准时。
ScheduledThreadPoolExecutor可以解决这个问题，主要是scheduleAtFixedRate和scheduleWithFixedDelay这两个api

ScheduledThreadPoolExecutor作为线程池，内部的blockingQueue使用的是DelayedWorkQueue.
DelayedWorkQueue为ScheduledThreadPoolExecutor中的内部类，它其实和阻塞队列DelayQueue有点儿类似。DelayQueue是可以提供延迟的阻塞队列，它只有在延迟期满时才能从中提取元素，其列头是延迟期满后保存时间最长的Delayed元素。如果延迟都还没有期满，则队列没有头部，并且 poll 将返回 null。
DelayedWorkQueue中的任务必然是按照延迟时间从短到长来进行排序的。ScheduledFutureTask有一个compareTo，用于在队列中进行排序。其实就是看task.time，谁在前头谁上。

```java
public ScheduledFuture<?> scheduleAtFixedRate(Runnable command,
                                                long initialDelay,
                                                long period,
                                                TimeUnit unit) {
    ScheduledFutureTask<Void> sft =
        new ScheduledFutureTask<Void>(command,
                                        null,
                                        triggerTime(initialDelay, unit),
                                        unit.toNanos(period));
}

public ScheduledFuture<?> scheduleWithFixedDelay(Runnable command,
                                                    long initialDelay,
                                                    long delay,
                                                    TimeUnit unit) {
    ScheduledFutureTask<Void> sft =
        new ScheduledFutureTask<Void>(command,
                                        null,
                                        triggerTime(initialDelay, unit),
                                        unit.toNanos(-delay));
}


//而在ScheduledFutureTask中定时任务是这样设置下一次执行时间的

private void setNextRunTime() {
        long p = period;
        if (p > 0)
            time += p;
        else
            time = triggerTime(-p); //当前时间+period。而走到这里，run方法已经走过了，所以如果run堵塞了很久，这个task的下一次执行时间就会不准了
}
```
结论就是scheduleWithFixedDelay可能会因为前面的任务堵塞造成不是那么准

## 参考
- [看起来 ReentrantLock 无论在哪方面都比 synchronized 好](http://blog.csdn.net/fw0124/article/details/6672522)
- [Jesse Wilson - Coordinating Space and Time](https://www.youtube.com/watch?v=yS0Nc-L1Uuk)
- [一级缓存，时钟周期](http://www.cnblogs.com/xrq730/p/7048693.html)volatile硬件层面的实现原理
- [StampedLock in Java](https://netjs.blogspot.ca/2016/08/stampedlock-in-java.html)
- [Java 8 StampedLocks vs. ReadWriteLocks and Synchronized](http://blog.takipi.com/java-8-stampedlocks-vs-readwritelocks-and-synchronized/)
- [死磕java系列](http://cmsblogs.com/?p=2122)
