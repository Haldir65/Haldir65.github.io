---
title: java线程池的实现原理
date: 2017-04-30 19:17:45
tags: [concurrency]
---

原本只打算写一点关于线程池的实现原理，后来发现坑越挖越大。不得不写到一半停下来，所以，这算是一篇不那么完善的关于原理的解析吧。
![](https://www.haldir66.ga/static/imgs/16d714eb6e8ecc23e4d6ba20d0be17a0.jpg)
<!--more-->

1. 线程池的常规使用方式
通常说的线程池对外表现为具有一系列操作功能的接口，Executor提供了execute一个runnable的功能，而其子类ExecutorService则对外提供了更多的实用功能，所以平时用的都是ExecutorService的实现类。
```java

public interface Executor {

    /**
     * Executes the given command at some time in the future.  The command
     * may execute in a new thread, in a pooled thread, or in the calling
     * thread, at the discretion of the {@code Executor} implementation.
     *
     * @param command the runnable task
     * @throws RejectedExecutionException if this task cannot be
     * accepted for execution
     * @throws NullPointerException if command is null
     */
    void execute(Runnable command);
}


public interface ExecutorService extends Executor{
	
}


public abstract class AbstractExecutorService implements ExecutorService {
	
}
public class ThreadPoolExecutor extends AbstractExecutorService {
	
}
```
更具体一点来说，java.util.concurrent.ThreadPoolExecutor这个类提供了上述接口的具体实现，同时对外提供了一些hook(beforeExecute、afterExecute等)，当然开发者也可以继承这个方法，实现更多自定义功能。
它的构造函数如下：
```
public ThreadPoolExecutor(int corePoolSize,
                              int maximumPoolSize,
                              long keepAliveTime,
                              TimeUnit unit,
                              BlockingQueue<Runnable> workQueue) {
        this(corePoolSize, maximumPoolSize, keepAliveTime, unit, workQueue,
             Executors.defaultThreadFactory(), defaultHandler);
    }
```
但实际上，java不建议这样直接弄一个线程池出来，而是使用java.util.concurrent.Executors中的一些现成的工厂方法来创建一个线程池实例，具体的方法名很好理解，newFixedThreadPool，newSingleThreadExecutor，newCachedThreadPool等等。关于线程池构造函数各个参数的意义以及Executors提供的各种线程方法的适用场合，网上有很多详尽的文章。


```java
Thread有这些状态
    */
    public enum State {
        NEW,
        RUNNABLE,
        BLOCKED,
        WAITING,
        TIMED_WAITING,
        TERMINATED;
    }
```

这里针对execute方法具体的实现来展开，即，如何做到自动扩容，如何做到线程缓存，如何实现终止，以及资源同步问题。
```java
 public void execute(Runnable command) {
        if (command == null)
            throw new NullPointerException();
        /*
         * Proceed in 3 steps:
         *
         * 1. If fewer than corePoolSize threads are running, try to
         * start a new thread with the given command as its first
         * task.  The call to addWorker atomically checks runState and
         * workerCount, and so prevents false alarms that would add
         * threads when it shouldn't, by returning false.
         *
         * 2. If a task can be successfully queued, then we still need
         * to double-check whether we should have added a thread
         * (because existing ones died since last checking，上一次检查之后可能有线程挂掉了) or that
         * the pool shut down since entry into this method. So we
         * recheck state and if necessary roll back the enqueuing if
         * stopped, or start a new thread if there are none.
         *
         * 3. If we cannot queue task, then we try to add a new
         * thread.  If it fails, we know we are shut down or saturated
         * and so reject the task.
         */
        int c = ctl.get();
        if (workerCountOf(c) < corePoolSize) { //
       // Core pool size is the minimum number of workers to keep alive (and not allow to time out etc)
        unless allowCoreThreadTimeOut is set, in which case the minimum is zero.
            if (addWorker(command, true))//true表示创建新的Worker时的上限是coolPoolSize,false表示上限是maximunPoolSize
            一般前者都小于等于后者，成功创建新的Worker并执行任务的话,直接在这里就return掉了
                return;
            c = ctl.get(); //当前pool的state,ctl是一个AtomicInteger
        }
        if (isRunning(c) && workQueue.offer(command)) {//addworker就是创建一个新的Worker并立即执行command，没能成功就得暂时放进queue了。offer就是往这里面加一个runnable
            int recheck = ctl.get();//recheck的原因源码中也说明了
           //走到这一步，说明已经成功加入到队列中了。
            if (! isRunning(recheck) && remove(command))
                reject(command);//pool随时可能会被关掉
            else if (workerCountOf(recheck) == 0)
                addWorker(null, false);

        }
        else if (!addWorker(command, false))
            reject(command);
    }
```
来看addWorker的实现

```java
private boolean addWorker(Runnable firstTask, boolean core) {
        retry:
        、、、省略代码
        try {
            w = new Worker(firstTask);
            //每一个不为null的command都会创建一个新的worker
            final Thread t = w.thread;
            if (t != null) {
                final ReentrantLock mainLock = this.mainLock;
                mainLock.lock();//加锁
                try {
                        workers.add(w); //workers就是一个普通的HashSet,同步的问题通过ReentrantLock解决
                    }
                } finally {
                    mainLock.unlock();
                }
                if (workerAdded) {
                    t.start(); //这里就是真正执行command的方法了
                    workerStarted = true;
                }
            }
        } 
        return workerStarted; //这里可以看出来,addWorker返回值表示这个command有没有被执行
    }



 final void runWorker(Worker w) { //每一条线程运行起来的时候都会走这个方法
        try {
            while (task != null || (task = getTask()) != null) {
                w.lock();//task可能是第一个runnable，也可能是从queue中取出来的
                //getTask方法就是不断的从队列中获取任务。注意之前addTask的方法入参说明,command是该worker执行的第一个任务。也就是说，一个worker之后还有可能从queue中获取新的任务。线程能够一直有任务执行，就不会进入死亡状态(Thread有几个状态)
                try {
                    beforeExecute(wt, task);//钩子
                    Throwable thrown = null;
                    try {
                        task.run(); 
                    } catch (RuntimeException x) {
                        thrown = x; throw x;
                    } catch (Error x) {
                        thrown = x; throw x;
                    } catch (Throwable x) {
                        thrown = x; throw new Error(x);
                    } finally {
                        afterExecute(task, thrown);//钩子
                    }
                } finally {
                    task = null;
                    w.completedTasks++;
                    w.unlock();
                }
            }
            completedAbruptly = false;
        } finally {
            processWorkerExit(w, completedAbruptly);
        }
    }    
```
addWorker会创建一个新的Worker(线程)，并将command作为这个线程要执行的第一个任务，而Worker的run方法是线程跑起来执行的方法。至于如何实现从queue中获取任务交给线程去完成，看getTask方法
```java
private Runnable getTask() {
        boolean timedOut = false; // Did the last poll() time out?

        for (;;) { //轮询
            try {
                Runnable r = timed ?
                    workQueue.poll(keepAliveTime, TimeUnit.NANOSECONDS) : //从queue中提取任务
                    workQueue.take();
                if (r != null)
                    return r;
                
            } catch (InterruptedException retry) {
                timedOut = false;
            }
        }
    }
```
整体来说，executor.execute方法就是通过new出Woker，而Worker则会在run方法中不停的从queue中获取新的任务，从而确保线程不会挂掉。也就是所谓的线程池缓存了线程，避免了频繁创建线程的开销。


2. Worker这个类继承自AbstractQueuedSynchronizer
AbstractQueuedSynchronizer即大名鼎鼎的AQS。


3. Reetranlock的使用
这其中有
注意上面使用了重入锁 ReentrantLock，后来发现ThreadPoolExecutor中多处使用了这个类。

4. Future,Callable,FutureTask等等

最后，今天下午看到很多jdk里源码的注释，作者都是 Doug Lea ，实在佩服前人的功力。之前也看过一些自定义线程池的实现，现在看起来确实差很多，不要重复造轮子不意味着不需要去了解轮子是怎么造出来的。

Reference 
1. [Java 多线程：线程池实现原理](https://github.com/pzxwhc/MineKnowContainer/issues/9)