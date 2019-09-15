---
title: jdk集合类源码分析[queue]
date: 2019-09-15 10:30:47
tags:
---


queue的一些实现类及使用场景分析
![](https://www.haldir66.ga/static/imgs/RioGrande_ZH-CN8091224199_1920x1080.jpg)
<!--more-->


## 1. Queue在线程池中的应用
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
