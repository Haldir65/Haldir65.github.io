---
title: AbstractQueuedSynchronizer源码分析
date: 2019-07-05 08:59:54
tags: [java]
---


关于java.util.concurrent.locks.AbstractQueuedSynchronizer,这个类是juc的基础。ReentrantLock中，ThreadPoolExecutor中，CountDownLatch中都有用到。
![](https://api1.reindeer36.shop/static/imgs/CapeBretonSunset_EN-AU10231293487_1920x1080.jpg)
<!--more-->

先看java doc中是怎样描述的吧:
**Provides a framework for implementing blocking locks and related synchronizers (semaphores, events, etc) that rely on first-in-first-out (FIFO) wait queues. **

<!--more-->

通常使用ReentrantLock的时候，都是这样的
```java
reentrantLock.lock();
try {
    // 执行代码...
} finally {
// 释放锁
reentrantLock.unlock();
}
```

来看看内部实现
ReentrantLock.lock方法
```java
 public void lock() {
        sync.lock();
}

/**
    * Sync object for non-fair locks 
    默认是非公平的Sync，非常短，主要的逻辑都在父类AQS中
*/
static final class NonfairSync extends Sync {

    /**
        * Performs lock.  Try immediate barge, backing up to normal
        * acquire on failure.
        */
    final void lock() {
        if (compareAndSetState(0, 1))
            setExclusiveOwnerThread(Thread.currentThread());
        else
            acquire(1);
    }

    protected final boolean tryAcquire(int acquires) {
        return nonfairTryAcquire(acquires);
    }
}


static final class FairSync extends Sync {

        final void lock() {
            acquire(1);
        }
        
    public final void acquire(int arg) {
        if (!tryAcquire(arg) &&
            acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
            selfInterrupt();
    }
}

```
[acquire这个方法主要在这篇文章里，写的非常好](https://javadoop.com/post/AbstractQueuedSynchronizer)。这篇文章分析的是FairSync,但NonFairSync的区别并不大，比方说公平锁遵守先来后到（所有的线程都会争着去排队到tail），非公平锁则是上来就试着用cas抢锁(抢成功的话就setExclusiveOwner)，不成功的话才走排队那一套

挂起线程和唤醒线程使用的是
LockSupport.park(this);
LockSupport.unpark(s.thread);
根据网上的分析，在native层使用的是cpp的pthread_mutex，不是可以重入的(也就是不要乱来，lock和unlock一定要配对使用)

使用到了AbstractQueuedSynchronizer的类包括reentrantLock中的Sync, ThreadPoolExecutor中的worker，CountDownLatch中的Sync,Semaphore.Sync。以下分别展开这些类的叙述

## ReentrantLock
非常常见的锁，注意的是一定要在finally里面释放掉锁。内部包含一个Sync静态类。
上述已经提到了ReentrantLock是如何通过Sync完成lock以及后续节点的唤醒的


## CountDownLatch
主线程启动几条线程同时起跑，希望主线程不要急着退出，等其他线程跑完，主线程再恢复运行，这种场景用CountDownLatch可以，用CyclicBarrier可以，用Phaser也可以。参考[Phaser 使用介绍](https://www.javadoop.com/post/phaser-tutorial)中的示例代码

使用CountDownLatch的话
```java
// 1. 设置 count 为 1
CountDownLatch latch = new CountDownLatch(1);

for (int i = 0; i < 10; i++) {
    new Thread(() -> {
        try {
            // 2. 每个线程都等在栅栏这里，等待放开栅栏，不会因为有些线程先启动就先跑路了
            latch.await();

            // doWork();

        } catch (InterruptedException ignore) {
        }
    }).start();
}

doSomethingELse(); // 确保在下面的代码执行之前，上面每个线程都到了 await() 上。

// 3. 放开栅栏
latch.countDown();
```

CountDownLatch.java
```java
public void await() throws InterruptedException {
    sync.acquireSharedInterruptibly(1);
}


public void countDown() {
    sync.releaseShared(1);
}
```

await中使当前线程停下来的方法在doAcquireSharedInterruptibly中，而唤醒线程的方法在releaseShared中。CountDownLatch因为有一个count的概念，所以在调用releaseShared之前总是会判断当前count是否已经到达了0。因为一旦到达了0，那么在等待的线程(调用了await的线程就可以恢复运行)。
> CountDownLatch的原理： **AQS 共享模式的典型使用，构造函数中的 1 是设置给 AQS 的 state 的。latch.await() 方法会阻塞，而 latch.countDown() 方法就是用来将 state-- 的，减到 0 以后，唤醒所有的阻塞在 await() 方法上的线程。**


### CyclicBarrier 来实现这种几条线程同步的方法更简单
```java
// 1. 构造函数中指定了 10 个 parties
CyclicBarrier barrier = new CyclicBarrier(10);

for (int i = 0; i < 10; i++) {
    executorService.submit(() -> {
        try {
            // 2. 每个线程"报告"自己到了，
            //    当第10个线程到的时候，也就是所有的线程都到齐了，一起通过
            barrier.await();

            // doWork()

        } catch (InterruptedException | BrokenBarrierException ex) {
            ex.printStackTrace();
        }
    });
}
```

### Phaser其实是用到的比较少的
```java
Phaser phaser = new Phaser();
// 1. 注册一个 party
phaser.register();

for (int i = 0; i < 10; i++) {

    phaser.register();

    executorService.submit(() -> {
        // 2. 每个线程到这里进行阻塞，等待所有线程到达栅栏
        phaser.arriveAndAwaitAdvance();

        // doWork()
    });
}
phaser.arriveAndAwaitAdvance();
``` 
上述代码中phaser.register被调用了11次，就像开会一样，所有人都到齐了才能开始


## ThreadPoolExecutor.Worker


## Semaphore
Semaphere的构造函数中可以传一个int参数,用于标识同时最多有几条线程可以获得permit（也就是同时最多有几条线程进入acquire和release之间的代码块中）
```java
Semaphore.acquire();
// 操作数据
Semaphore.release();
```
假如构造函数中传入了1，那么这个semaphore实际上是一个lock或者说mutex，如果大于一，那么同时进入这段代码块里的线程就有多个了，就需要实现自己的同步逻辑。（race condition，往往要加一段sleep就能快速重现，比如两条线程同时对一个int 0 自增，那么极有可能得到的结果是1而不是预期的2，因为各自看到的都是0）


## Exchanger
Exchanger是成双成对使用的，支持泛型，两条线程同时开跑，先到的会等着，两个都到了之后，互相交换泛型的数据


## Mutex
juc里面没有c语言那样的mutex，不过Reentrantlock这种实际上就发挥了mutex的作用。


## tbd 
使用AQS的普遍方式是自己继承实现一个Sync（写一个试试看？Tomcat里面就有）


[简明概括](https://juejin.im/post/5dd4bc97f265da0bc53c7d41)

1. AQS有个临界变量state,当一个线程获取到state==0时, 表示这个线程进入了临界代码(获取到锁), 并原子地把这个变量值+1
2. 没能进入临界区(获取锁失败)的线程, 会利用CAS的方式添加到到CLH队列尾去, 并被LockSupport.park挂起.
3. 当线程释放锁的时候, 会唤醒head节点的下一个需要唤醒的线程(有些线程cancel了就不需要唤醒了)
4. 被唤醒的线程检查一下自己的前置节点是不是head节点(CLH队列的head节点就是之前拿到锁的线程节点)的下一个节点,
如果不是则继续挂起, 如果是的话, 与其他线程重新争夺临界变量,即重复第1步



## 参考
[一行一行源码分析清楚 AbstractQueuedSynchronizer](https://javadoop.com/post/AbstractQueuedSynchronizer-2)