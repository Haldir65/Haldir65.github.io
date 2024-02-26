---
title: java线程池的实现原理
date: 2017-04-30 19:17:45
tags: [concurrency]
---

原本只打算写一点关于线程池的实现原理，后来发现坑越挖越大。不得不写到一半停下来，所以，这算是一篇不那么完善的关于原理的解析吧。
![](https://api1.reindeer36.shop/static/imgs/16d714eb6e8ecc23e4d6ba20d0be17a0.jpg)
<!--more-->

## 1. 线程池的常规使用方式
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
```

```java
public interface ExecutorService extends Executor{
	
}
public abstract class AbstractExecutorService implements ExecutorService {
	
}
public class ThreadPoolExecutor extends AbstractExecutorService {
	
}
```
更具体一点来说，java.util.concurrent.ThreadPoolExecutor这个类提供了上述接口的具体实现，同时对外提供了一些hook(beforeExecute、afterExecute等)，当然开发者也可以继承这个方法，实现更多自定义功能。
它的构造函数如下：
```java
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
//Thread有六种状态
public enum State {
    NEW,
    RUNNABLE,
    BLOCKED,
    WAITING,
    TIMED_WAITING,
    TERMINATED;
}

//ThreadPoolExecutor中用一个AtomicInteger的前三位表示当前state，后29位表示worker的数量。通过AtomicInteger的CAS操作保证多线程之间看到的worker数和当前state是一致的；
private final AtomicInteger ctl = new AtomicInteger(ctlOf(RUNNING, 0));
//用一个ReentrantLock来锁住对workers这个HashSet的添加，删除操作
private final HashSet<Worker> workers = new HashSet<Worker>();    
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
//ThreadPoolExecutor.java
  private boolean addWorker(Runnable firstTask, boolean core) {
      //下面是一个循环，假设线程池不关闭的话，循环去cas实现workerCount自增。但如果workerCount已经大于最大数量的话，则会失败
        retry:
        for (;;) {
            int c = ctl.get();
            int rs = runStateOf(c);

            // Check if queue empty only if necessary.
            if (rs >= SHUTDOWN &&
                ! (rs == SHUTDOWN &&
                   firstTask == null &&
                   ! workQueue.isEmpty()))
                return false; //每一次尝试设置workerCount之前都会检查一下当前是否关闭

            for (;;) {
                int wc = workerCountOf(c);
                if (wc >= CAPACITY ||
                    wc >= (core ? corePoolSize : maximumPoolSize))
                    return false;
                if (compareAndIncrementWorkerCount(c)) 
                    break retry;// 只有自增成功才会跳出循环，否则一直尝试；如果没有自增成功，继续
                c = ctl.get();  // Re-read ctl
                if (runStateOf(c) != rs)//看下当前状态是否发生了变化，一旦变化就要检查当前是否关闭，所以跳到外部循环
                    continue retry;
                // else CAS failed due to workerCount change; retry inner loop
            }
        }
        //走到这里说明自增成功了，在worker数量小于limit的时候，几乎一定能够添加worker成功

        boolean workerStarted = false;
        boolean workerAdded = false;
        Worker w = null;
        try {
            w = new Worker(firstTask);
            final Thread t = w.thread;
            if (t != null) {
                final ReentrantLock mainLock = this.mainLock;
                mainLock.lock();
                try {
                    // Recheck while holding lock.
                    // Back out on ThreadFactory failure or if
                    // shut down before lock acquired.
                    int rs = runStateOf(ctl.get());

                    if (rs < SHUTDOWN ||
                        (rs == SHUTDOWN && firstTask == null)) {
                        if (t.isAlive()) // precheck that t is startable
                            throw new IllegalThreadStateException();
                        workers.add(w);
                        int s = workers.size();
                        if (s > largestPoolSize)
                            largestPoolSize = s;
                        workerAdded = true;
                    }
                } finally {
                    mainLock.unlock();
                }
                if (workerAdded) {
                    t.start(); //这个Thread的构造函数里传入了一个Runnable，也就是Worker自身
                    workerStarted = true;
                }
            }
        } finally {
            if (! workerStarted)
                addWorkerFailed(w);
        }
        return workerStarted;
    }


// 上面在addWorker中，workerCount自增成功后就会
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
            processWorkerExit(w, completedAbruptly); //在这里从workers的HashSet中移除当前worker
        }
    }    
```
addWorker会创建一个新的Worker(线程)，并将command作为这个线程要执行的第一个任务，而Worker的run方法是线程跑起来执行的方法。至于如何实现从queue中获取任务交给线程去完成，看getTask方法
```java
private Runnable getTask() {
        boolean timedOut = false; // Did the last poll() time out?

        for (;;) { //轮询
            boolean timed = allowCoreThreadTimeOut || wc > corePoolSize; //如果当前worker数量超出了corePoolSize，就要允许我这条线程挂掉

            try {
                Runnable r = timed ?
                    workQueue.poll(keepAliveTime, TimeUnit.NANOSECONDS) : //queue的poll是立刻返回的,poll(time,unit)是等待超时返回，take则是阻塞
                    workQueue.take(); // 如果当前没有超过核心线程数，就用take，否则，超过keepAlive时间就设置timedOut为true，重新走一遍循环的时候会cas把当前worker数量自减
                if (r != null)
                    return r;
                
            } catch (InterruptedException retry) {
                timedOut = false;
            }
        }
    }
```

整体来说，executor.execute方法会获取Woker，而Worker则会在run方法中不停的从queue中获取新的任务，从而确保线程不会挂掉。也就是所谓的线程池缓存了线程，避免了频繁创建线程的开销。
在ThreadPoolExecutor的execute方法中有一段注释写的很清楚，分为三步：
1. 如果当前的线程数量小于corePoolSize,直接创建一个新的线程干活
2. 否则加入到队列，成功的话还要重新检查一下，因为可能线程池关闭了
3.  加入队列失败的话，尝试创建一个新的线程(如果size超过maximumPoolSize的话是会失败的)，再次失败的话就调用RejectPolicy

在javadoc中也写的很清楚
1. If fewer than corePoolSize threads are running, the Executor always prefers adding a new thread rather than queuing.
2. If corePoolSize or more threads are running, the Executor always prefers queuing a request rather than adding a new thread.
3. If a request cannot be queued, a new thread is created unless this would exceed maximumPoolSize, in which case, the task will be rejected.

## 2. Queue的选择
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


## 自定义线程池的话，有一些经验公式
简单来说，就是如果你是CPU密集型运算，那么线程数量和CPU核心数相同就好，避免了大量无用的切换线程上下文。
如果你是IO密集型的话，需要大量等待，那么线程数可以设置的多一些，比如CPU核心乘以2.


## 参考
1. [java自带线程池和队列详解](https://www.oschina.net/question/565065_86540)
2. [深入分析 java 8 编程语言规范：Threads and Locks](https://javadoop.com/post/Threads-And-Locks-md)
3. [解读 java 并发队列 BlockingQueue](https://javadoop.com/post/java-concurrent-queue)
4. [聊聊并发（七）——Java 中的阻塞队列](https://www.infoq.cn/article/java-blocking-queue)