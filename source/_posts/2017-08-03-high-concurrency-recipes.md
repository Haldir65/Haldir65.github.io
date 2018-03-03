---
title: 高并发实践手册
date: 2017-08-03 21:04:28
tags: [java,tools,concurrency]
---

![](http://odzl05jxx.bkt.clouddn.com/image/blog/be3c80a11edfd0fdb75d098550ed2c8e.jpg?imageView2/2/w/600)
<!--more-->



![](http://odzl05jxx.bkt.clouddn.com/image/jpg/1102533137-5.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/1102533911-1.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/20120103214255_nTsVt.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/apic5964_sc115.com.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/apic6283_sc115.com.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/849c18412f8e7a0b18df09f6f87e6516.jpg?imageView2/2/w/600)

![](http://odzl05jxx.bkt.clouddn.com/pretty-orange-mushroom-wallpaper-5386b0c8c3459.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/timg.jpg?imageView2/2/w/600)

![](http://odzl05jxx.bkt.clouddn.com/beautiful-dandelion-wallpaper-5384b7d0e8b09.jpg?imageView2/2/w/600)

![](http://odzl05jxx.bkt.clouddn.com/bullet-shots-over-the-flower-wallpaper-56ee6081c7f2b.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/cotton-grass-whip-wallpaper-5383509d2bd13.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/macro-of-yellow-narcisa-flower-wallpaper-53834d45b40a1.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/nature-grass-wet-plants-high-resolution-wallpaper-573f2c6413708.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/ripe-grapes-macro-wallpaper-1920x1080-538350f32e183.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/yellow-autumn-leaves-wallpaper-537f1e4672a31.jpg?imageView2/2/w/600)

> The difference between “concurrent” and “parallel” execution
[Good to know](https://stackoverflow.com/questions/1897993/what-is-the-difference-between-concurrent-programming-and-parallel-programming)

## 1. 同时对共享资源进行操作好一点的加锁的方式

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
每一条线程调用ThreadLocal的set方法时都只能改变属于自己（线程）的值，调用get的时候也只能读到自己曾经设置的值。在多条线程面前，一个ThreadLocal类似于一个银行，每条线程只能保存或者更改读取自己的保险柜里的东西，保险柜钥匙即Thread自身。

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

## 9. CountdownLatch的简单使用

作者：天然鱼
链接：http://www.jianshu.com/p/cef6243cdfd9
來源：简书

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

## 10.指令重排不是说说而已
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
这也就解释了我们平时是怎么写单例的


## 11.HashMap不是线程安全的，可能会在reHash里形成死锁
[非常烧脑](https://juejin.im/post/5a224e1551882535c56cb940)


## 10. CyclicBarrier


------------------------------mere trash-------------------------------------------------
1. 构造函数也不是线程安全的(因为指令重排)
2. 同步一个对象的前提是各方都同意使用同一把锁作为调用方法的前提，单方面加锁并不限制不尊重锁机制的使用者。
3. 在多线程的场景下，无逻辑相关的代码写的前后顺序并无意义，原因是编译器会进行指令重排。
4. volatile并不是Atomic操作，例如，A线程对volatile变量进行写操作(实际上是读和写操作)，B线程可能在这两个操作之间进行了写操作；例如用volatile修饰count变量那么 count++ 操作就不是原子性的。而AtomicInteger类提供的atomic方法可以让这种操作具有原子性如getAndIncrement()方法会原子性的进行增量操作把当前值加一
5. CopyOnWriteArrayList和Collections.synchronizedList相比。在高并发前提下，前者读的性能更好，后者写的性能更好（前者的写性能极差）。[CopyOnWriteArrayList与Collections.synchronizedList的性能对比](http://blog.csdn.net/yangzl2008/article/details/39456817)。CopyOnWriteArrayList适合做缓存。
6. java io为什么慢，有一个原因是InputStream的read方法和OutputStream的write方法都是加了synchronized的。而Okio里面synchronized方法我没找到，另外，真的想要io性能的话，用nio。


## 参考
- [看起来 ReentrantLock 无论在哪方面都比 synchronized 好](http://blog.csdn.net/fw0124/article/details/6672522)
- [Jesse Wilson - Coordinating Space and Time](https://www.youtube.com/watch?v=yS0Nc-L1Uuk)
- [一级缓存，时钟周期](http://www.cnblogs.com/xrq730/p/7048693.html)volatile硬件层面的实现原理
- [StampedLock in Java](https://netjs.blogspot.ca/2016/08/stampedlock-in-java.html)
- [Java 8 StampedLocks vs. ReadWriteLocks and Synchronized](http://blog.takipi.com/java-8-stampedlocks-vs-readwritelocks-and-synchronized/)
