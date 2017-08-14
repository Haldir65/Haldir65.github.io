---
title: 高并发实践手册
date: 2017-08-03 21:04:28
tags: [java,tools,concurrency]
---

![](http://odzl05jxx.bkt.clouddn.com/image/blog/be3c80a11edfd0fdb75d098550ed2c8e.jpg?imageView2/2/w/600)
<!--more-->

![](http://odzl05jxx.bkt.clouddn.com/Cg-4V1Kg7NCIMLH-AAwW6gNGe9cAAOB4AFTanwADBcC664.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/40164340_40164340_1414330224938_mthumb.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/a13262133_01000.jpg?imageView2/2/w/600)


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
有些任务是可以分块的。




## 参考
- [看起来 ReentrantLock 无论在哪方面都比 synchronized 好](http://blog.csdn.net/fw0124/article/details/6672522)
- [Jesse Wilson - Coordinating Space and Time](https://www.youtube.com/watch?v=yS0Nc-L1Uuk)
- [一级缓存，时钟周期](http://www.cnblogs.com/xrq730/p/7048693.html)volatile硬件层面的实现原理
