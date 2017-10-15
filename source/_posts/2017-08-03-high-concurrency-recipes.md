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
![](http://odzl05jxx.bkt.clouddn.com/unclassified_unclassified--115_07-1920x1440.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/beautiful-dandelion-wallpaper-5384b7d0e8b09.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/beautiful-red-rose-petals-wallpaper-56801fc038122.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/bee-getting-the-pollen-wallpaper-538358eb5d5a3.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/bullet-shots-over-the-flower-wallpaper-56ee6081c7f2b.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/cotton-grass-whip-wallpaper-5383509d2bd13.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/macro-of-yellow-narcisa-flower-wallpaper-53834d45b40a1.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/nature-grass-wet-plants-high-resolution-wallpaper-573f2c6413708.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/ripe-grapes-macro-wallpaper-1920x1080-538350f32e183.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/single-yellow-beauty-flower-on-the-fence-wallpaper-56801fde208df.jpg?imageView2/2/w/600)
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


## 2. ThreadLocal当做一个HashMap来用就好了



## 3. Fork/join since java 7
有些任务是可以分块的。[work-stealing的实现](http://ifeve.com/java7-fork-join-and-closure/)

## 4. ArrayBlockingQueue<E> Thread Safe

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

     synchronized(lock) { //… }

  }

```
零长度的byte数组对象创建起来将比任何对象都经济――查看编译后的字节码：生成零长度的byte[]对象只需3条操作码，而Object lock = new Object()则需要7行操作码。



------------------------------mere trash-------------------------------------------------
1. 构造函数也不是线程安全的
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
