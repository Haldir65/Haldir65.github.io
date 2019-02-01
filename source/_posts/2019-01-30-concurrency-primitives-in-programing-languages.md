---
title: 编程语言中使用到的多线程基础数据结构
date: 2019-01-30 07:53:33
tags: [java]
---

![](https://www.haldir66.ga/static/imgs/HongKongFireworks_ZH-CN13422096721_1920x1080.jpg)
主要讲讲java中的notify,wait,synchronized ，unsafe等多线程基础工具的使用方式。

<!--more-->
## java

###　wait和notify
有一个异常叫做java.lang.IllegalMonitorStateException。意思就是没有在synchronized block中调用wait或者notify方法。
java Object中是有一个monitor对象的，wait和notify就是基于这个属性去实现的。只要在同一对象上去调用notify/notifyAll方法，就可以唤醒对应对象monitor上等待的线程了。

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


=================================

[图解java并发](http://ifeve.com/图解java并发上/)
unSafe

hacknoon中有关于python中多线程primitives的文章
c语言中多线程通信基础
基本的思想都是相通的


## 参考
[美团博客中关于java锁的一片文章](https://tech.meituan.com/2018/11/15/java-lock.html)