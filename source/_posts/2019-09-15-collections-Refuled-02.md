---
title: jdk集合类源码分析[queue]
date: 2019-09-15 10:30:47
tags:
---


queue的一些实现类及使用场景分析
![](https://www.haldir66.ga/static/imgs/RioGrande_ZH-CN8091224199_1920x1080.jpg)
<!--more-->


## Queue在线程池中的应用
BlockingQueue是一个接口
BlockingQueue提供了四种应对策略来处理这种资源不能被立即满足的场景

| 空值     | 抛出异常     |   返回一个特殊值 | 阻塞 | 调用者提供一个超时 |
| :------------- | :------------- |:------------- |:------------- |:------------- |
| 插入     | add(e)      | offer(e) | put(e)  | put(e, time ,timeUnit) |
| 移除     | remove()     | poll() | take()  | poll(time,timeUnit) |
| 检查     | element()  | peek()  | 不可用 | 不可用 |


ThreadPoolExecutor的构造函数中需要传入一个BlockingQueue<Runnable> workQueue，一个阻塞式的队列 。也就是说，添加任务和获取任务的过程都是阻塞的。
jdk中提供的线程池选择的队列：
newCachedThreadPool使用了SynchronousQueue(每一个插入操作必须等待另一个线程的对应移除操作)
newFixedThreadPool使用了LinkedBlockingQueue(这个队列是无界的)，干活的线程就那么多，任务多了就加入队列好了


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



