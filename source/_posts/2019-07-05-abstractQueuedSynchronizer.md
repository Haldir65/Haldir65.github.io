---
title: AbstractQueuedSynchronizer源码分析
date: 2019-07-05 08:59:54
tags:
---

关于java.util.concurrent.locks.AbstractQueuedSynchronizer,这个类是juc的基础。ReentrantLock中，ThreadPoolExecutor中，CountDownLatch中都有用到。

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
根据网上的分析，在native层使用的是cpp的pthread_mutex，不是可以重入的




## 参考
[一行一行源码分析清楚 AbstractQueuedSynchronizer](https://javadoop.com/post/AbstractQueuedSynchronizer-2)