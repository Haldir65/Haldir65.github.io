---
title: 高并发实践手册
date: 2017-08-03 21:04:28
tags: [java,tools,concurrency]
---

![](http://odzl05jxx.bkt.clouddn.com/image/blog/be3c80a11edfd0fdb75d098550ed2c8e.jpg?imageView2/2/w/600)
<!--more-->


![](http://odzl05jxx.bkt.clouddn.com/image/jpg/1102531047-2.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/1102533137-5.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/1102533911-1.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/20120103214255_nTsVt.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/apic5964_sc115.com.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/apic6283_sc115.com.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/bamboo-buds-wallpaper-53859567dd31a.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/fresh-sparkle-dew-drops-on-red-flower-wallpaper-53861cf580909.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/pretty-orange-mushroom-wallpaper-5386b0c8c3459.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/timg.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/unclassified_unclassified--115_07-1920x1440.jpg?imageView2/2/w/600)

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

**volatile并不是Atomic操作，例如，A线程对volatile变量进行写操作(实际上是读和写操作)，B线程可能在这两个操作之间进行了写操作；**

## 3. Fork/join since java 7
有些任务是可以分块的。[work-stealing的实现](http://ifeve.com/java7-fork-join-and-closure/)

## 4. ArrayBlockingQueue<E> Thread Safe

## 5.ReentrantLock 不公平锁
在jdk1.5里面，ReentrantLock的性能是明显优于synchronized的，但是在jdk1.6里面，synchronized做了优化，他们之间的性能差别已经不明显了。



## 参考
- [看起来 ReentrantLock 无论在哪方面都比 synchronized 好](http://blog.csdn.net/fw0124/article/details/6672522)
- [Jesse Wilson - Coordinating Space and Time](https://www.youtube.com/watch?v=yS0Nc-L1Uuk)
- [一级缓存，时钟周期](http://www.cnblogs.com/xrq730/p/7048693.html)volatile硬件层面的实现原理
