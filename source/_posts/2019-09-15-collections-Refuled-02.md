---
title: jdk集合类源码分析[queue]
date: 2019-09-15 10:30:47
tags:
---


queue的一些实现类及使用场景分析
![](https://www.haldir66.ga/static/imgs/RioGrande_ZH-CN8091224199_1920x1080.jpg)
<!--more-->


## Queue在线程池中的应用
BlockingQueue是一个接口，jdk中实现了该接口的class包括

ArrayBlockingQueue
DelayQueue
LinkedBlockingQueue
LinkedBlockingDeque
LinkedTransferQueue
PriorityBlockingQueue
SynchronousQueue


BlockingQueue提供了四种应对策略来处理这种资源不能被立即满足的场景

| 空值     | 抛出异常     |   返回一个特殊值 | 阻塞 | 调用者提供一个超时 |
| :------------- | :------------- |:------------- |:------------- |:------------- |
| 插入     | add(e)      | offer(e) | put(e)  | put(e, time ,timeUnit) |
| 移除     | remove()     | poll() | take()  | poll(time,timeUnit) |
| 检查     | element()  | peek()  | 不可用 | 不可用 |


jdk的ThreadPoolExecutor的构造函数中需要传入一个BlockingQueue<Runnable> workQueue，一个阻塞式的队列 。也就是说，添加任务和获取任务的过程都是阻塞的。
jdk中提供的线程池选择的队列：
newCachedThreadPool使用了SynchronousQueue(每一个插入操作必须等待另一个线程的对应移除操作)
newFixedThreadPool使用了LinkedBlockingQueue(这个队列是无界的)，干活的线程就那么多，任务多了就加入队列好了


queue的重要性在于，在线程池(ThreadPoolExecutor)中，获取任务使用的是queue的**poll**方法，添加任务使用的是queue的**offer**方法。

## ArrayBlockingQueue的实现：
ArrayBlockingQueue是一个由数组实现的 **有界阻塞队列**。该队列采用 ***FIFO*** 的原则对元素进行排序添加。

主要的成员变量就这么几个
```java
final Object[] items;

/** items index for next take, poll, peek or remove */
int takeIndex;  //下一次从队列中取的index

/** items index for next put, offer, or add */
int putIndex;  // 下一次往队列中添加的index

/** Number of elements in the queue */
int count;

final ReentrantLock lock; //读写操作都要拿到这个锁

/** Condition for waiting takes */
private final Condition notEmpty;

/** Condition for waiting puts */
private final Condition notFull;
```


1. 入列核心方法是一个private方法enqueue(put ,offer都代理给了这个方法)
出列的核心方法是dequeue(take, poll,peek和remove方法都代理给了这个方法)
2. 这两个方法的调用是被包在一个lock.lock和lock.unlock中的，所以是线程安全的的。
3. 构造函数可以传一个fair进来。enqueue方法里面还有一个notEmpty.signal()， 其实就是典型的通知消费者。同理，dequeue里面有个notFull.signal()，就是通知生产者
4. 底层的数组是不会自动扩容的，但是如果一直添加元素，超出了底层数组的长度的话。offer会return false, put会block当前线程，add会throw new IllegalStateException("Queue full");
5. takeIndex可以看做是fifo队列的head, putIndex可以看做是fifo队列的tail，因为数组本身没有队列的概念，所以需要人为去维护两根指针。可以认为任何时候，底层的数组中是有一个区间是存放元素的。其余位置都是空的。比如遍历所有元素的方式是从取一个int i, 从takeIndex开始一直到putIndex(中途加入碰到了i= items.length，i变为0)。takeIndex和putIndex谁大谁小不一定，都是从0开始的，并且都会往后自增，一旦触碰到items.length，从0再来。所以遍历所有元素的过程就像是takeIndex去追赶putIndex。
这种做法应该叫做两根指针循环从数组中取元素。

## LinkedBlockingQueue的实现
LinkedBlockingQueue是Executors中使用的创建线程池的静态方法中使用的参数，显然更推荐使用。主要用的是两个方法，
put方法在队列满的时候会阻塞直到有队列成员被消费，take方法在队列空的时候会阻塞，直到有队列成员被放进来。官方文档提到了， **LinkedBlockingQueue的吞吐量通常要高于基于数组的队列，但在大多数并发应用程序中，其可预知的性能要低一些** ， 内部的lock只能是unfair的。





## DelayQueue
并发包下面的延时阻塞队列，附带一个Delayed接口用于用于实现定时任务
```java
public interface Delayed extends Comparable<Delayed> {
    long getDelay(TimeUnit unit);
}

public class DelayQueue<E extends Delayed> extends AbstractQueue<E>
    implements BlockingQueue<E> {
    
    }
```
队列中的元素都实现了Delayed的接口，通过getDelay方法实现延迟调度。在queue.take()的时候被add进queue的元素按照getDelay的返回值排序，越早到期的元素越先出队。

ScheduledThreadPoolExecutor中使用了内部实现类DelayedWorkQueue，而是使用数组又实现了一遍优先级队列，本质上没有什么区别。[详细介绍](http://cmsblogs.com/?p=4769)


## ArrayDeque
双端队列是一种特殊的队列，它的两端都可以进出元素，故而得名双端队列。ArrayDeque是一种以数组方式实现的双端队列，它是非线程安全的。
Deque是一个接口,定义了addFirst,addLast, removeFirst, removeLast等操作，因此可以从两端进行操作。
1. ArrarDeque的构造函数也可以传入size，默认初始容量是16，最小容量是8。必须是2的幂
2. 内部维护了一个elements(Object[]) ,同时还有两根指针head（下一次remove和pop的位置）和tail(下一次add的位置)
3. add操作等同于addLast。
4. head和tail都是从0开始的。addLast操作使得tail+1，head不变。第一次addFirst操作使得head从0变为length-1（比如说7），随后的addFirst操作使得head递减。当head==tail的时候，doubleCapacity。
5. getFirst的做法
```java
(E) elements[head];
```
getLast用的是这样的
```java
(E) elements[(tail - 1) & (elements.length - 1)];
```
通过取模的方式让头尾指针在数组范围内循环，x & (len – 1) = x % len，使用&的方式更快；这也是数组长度必须为2的指数幂的原因。
6.doubleCapacity(扩容的方式有点绕)，扩容时,head==tail。以head为边界，右边的挪到x2之后数组的最开头，左边的跟着挪到上述数据的后面，这样填满x2数组的左半部分，同时保证了head=0，tail在最尾部。
7. 通过取模的方式让头尾指针在数组范围内循环（head往左走，tail往右走，两者相遇后扩容）

[详细介绍](http://cmsblogs.com/?p=4771)



