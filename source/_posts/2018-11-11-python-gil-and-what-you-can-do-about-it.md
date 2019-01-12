---
title: python中多进程、多线程以及GIL记录
date: 2018-11-11 22:21:52
tags: [python]
---

![](https://www.haldir66.ga/static/imgs/1102533137-5.jpg)
- If your code has a lot of I/O or Network usage:
Multithreading is your best bet because of its low overhead
- If you have a GUI
Multithreading so your UI thread doesn't get locked up
- If your code is CPU bound:
You should use multiprocessing (if your machine has multiple cores)

<!--more-->

Python Global Interpreter Lock(GIL)
对于CPython，所有的python bytecode在执行前都需要获得interpreter的lock,one vm thread at a time。(java实现的python似乎没有这个烦恼)
GIL的出现似乎是历史原因（为了方便的直接使用当时现有的c extension）。而没有在python3中被移除的原因是因为这会造成单线程的程序在python3中跑的反而比python2中慢。

因为GIL的存在，python中的线程并不能实现cpu的并发运行(同时只能有一条线程在运行)。但对于I/O intensive的任务来说，cpu都在等待I/O操作完成，所以爬虫这类操作使用多线程是合适的。根据[A Jesse Jiryu Davis](https://www.youtube.com/watch?v=7SSYhuk5hmc)在pycon2017上的演讲，在多线程python程序中，如果某条线程开始进行I/O操作，就会主动放弃GIL(这是在socket module的源码中)，或者在cpu-intensive程序中，一条线程连续执行1000次(python2中是一个常数)后就会被夺走gil。[socket里面找关键字Py_BEGIN_ALLOW_THREADS和Py_END_ALLOW_THREADS](https://github.com/python/cpython/blob/master/Modules/socketmodule.c)

## 多线程以及一些同步的问题
单线程的版本
```python
# single_threaded.py
import time
from threading import Thread

COUNT = 50000000

def countdown(n):
    while n>0:
        n -= 1

start = time.time()
countdown(COUNT)
end = time.time()

print('Time taken in seconds -', end - start)
```

多线程的版本
```python
# multi_threaded.py
import time
from threading import Thread

COUNT = 50000000

def countdown(n):
    while n>0:
        n -= 1

t1 = Thread(target=countdown, args=(COUNT//2,))
t2 = Thread(target=countdown, args=(COUNT//2,))

start = time.time()
t1.start()
t2.start()
t1.join()
t2.join()
end = time.time()

print('Time taken in seconds -', end - start)
```
多线程虽然同一时刻只能有一条线程运行，但牵涉到数据共享的时候还是要加锁
![](https://haldir66.ga/static/imgs/lockExplanation.jpg)

比如这个例子，照说打印出来的应该是0，但实际操作中可能打出来正数
```python
import time, threading
# 假定这是你的银行存款:
balance = 0

def change_it(n):
    # 先存后取，结果应该为0:
    global balance
    balance = balance + n
    balance = balance - n

def run_thread(n):
    for i in range(1000000):
        change_it(n)

t1 = threading.Thread(target=run_thread, args=(5,))
t2 = threading.Thread(target=run_thread, args=(8,))
t1.start()
t2.start()
t1.join()
t2.join()
print(balance)
```
上述过程的原因在于
balance = balance + n
这一步其实需要至少两条cpu语句：
x = balance +n 
balance = x 

正常顺序是t1 (+5,-5) t2 (+8, -8) 这样的顺序
不正常的顺序
```
初始值 balance = 0

t1: x1 = balance + 5  # x1 = 0 + 5 = 5

t2: x2 = balance + 8  # x2 = 0 + 8 = 8
t2: balance = x2      # balance = 8

t1: balance = x1      # balance = 5
t1: x1 = balance - 5  # x1 = 5 - 5 = 0
t1: balance = x1      # balance = 0

t2: x2 = balance -8 # x2 =-8
t2: balance = x2 # balance = -8

结果 balance = -8
```
所以是有可能打印出-8这样的错误的结果的

这种情况下只要加锁就可以了
```python
import time, threading
balance = 0
lock = threading.Lock()

def change_it(n):
    global balance
    balance = balance + n
    balance = balance - n

def run_thread(n):
    for i in range(1000000):
        lock.acquire()
        try:
            change_it(n)
        finally:
            lock.release()

t1 = threading.Thread(target=run_thread, args=(5,))
t2 = threading.Thread(target=run_thread, args=(8,))
t1.start()
t2.start()
t1.join()
t2.join()
print(balance)
```
改成每一次对共享变量进行操作都需要加锁之后，打印结果就正常了
[多进程之间的同步方式包括queue,Event,Semaphores，Conditions等](https://hackernoon.com/synchronization-primitives-in-python-564f89fee732)

从bytecode来看，[increment这一操作并不是atomic的](https://www.youtube.com/watch?v=7SSYhuk5hmc&t=890s)
python里面很方便
incremnt-is-not-atomic.py
```python
def foo():
    global n
    n += 1

import dis
dis.dis(foo)
```
python incremnt-is-not-atomic.py
```
 3           0 LOAD_GLOBAL              0 (n)
              2 LOAD_CONST               1 (1)
              4 INPLACE_ADD
              6 STORE_GLOBAL             0 (n)
              8 LOAD_CONST               0 (None)
             10 RETURN_VALUE
```


## 多进程

多进程的版本
```python
from multiprocessing import Pool
import time

COUNT = 50000000
def countdown(n):
    while n>0:
        n -= 1

if __name__ == '__main__':
    pool = Pool(processes=2)
    start = time.time()
    r1 = pool.apply_async(countdown, [COUNT//2])
    r2 = pool.apply_async(countdown, [COUNT//2])
    pool.close()
    pool.join()
    end = time.time()
    print('Time taken in seconds -', end - start)
```

多进程之间内存不共享，同步方式是使用Queue(fifo)
```python
#!/usr/bin/env python3

import multiprocessing
import time
import random
import os
from multiprocessing import Queue

q = Queue()

def hello(n):
    time.sleep(random.randint(1,3))
    q.put(os.getpid())
    print("[{0}] Hello!".format(n))

processes = [ ]
for i in range(10):
    t = multiprocessing.Process(target=hello, args=(i,))
    processes.append(t)
    t.start()

for one_process in processes:
    one_process.join()

mylist = [ ]
while not q.empty():
    mylist.append(q.get())

print("Done!")
print(len(mylist))
print(mylist)
```

更加Pythonic的方式是使用asyncio

## Asyncio
优点包括
- Based on futures
- Faster than threads
- Massive I/O concurrency

```python
async def fetch_url(url):
        return await aiohttp.request('GET' , url) ## you get the future, the function is not executed immediatedly

async def fetch_two(url_a,url_b):
        future_a = fetch_url(url_a)
        future_b = fetch_url(url_b)
        a ,b = await asyncio.gather(future_a, future_b)  ## 一旦开始await这个future,这个coroutine才会被加入event loop
        return a, b
```
上述代码虽然还是在同一个进程中运行，还受到GIL制约，但是由于是I/O操作，所以也没什么问题。只是在process返回的结果是，就会受到GIL的影响了。（实际操作中你会发现coroutine还没执行就timeout了）
也就是说，I/O操作用asyncio，数据处理使用multi-processing，这是最好的情况。
由于coroutine和multi-processing是两个相对独立的模块，所以需要自己把两者结合起来。用多进程进行数据处理，每个进程中各自有独立的coroutine在运行。
[John Reese - Thinking Outside the GIL with AsyncIO and Multiprocessing - PyCon 2018](https://www.youtube.com/watch?v=0kXaLh8Fz3k)
```python
async def run_loop(tx, rx):
        ... ## real work here 
        limit = 10
        pending = set()
        while True:
                while len(pending) < limit:
                        task = tx.get_nowait()
                        fn ,args, kwargs = task
                        pending.add(fn(args,kwargs))
                done, pending = await asyncio.wait(pending, ..)        
                for future in done:
                        rx.put_nowait(await future)

def bootstrap(tx, rx):
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        loop.run_untile_complete(run_loop(tx, rx))

def main():        
        p = multiprocessing.Process(target = bootstrap, args = (tx, rx))
        p.start()
```

实际操作可能看起来像这样
```python
async def fetch_url(url):
        return await aiohttp.request('GET' , url) 

def fetch_all(urls):
       tx, rx = Queue(), Queue()
       Process(
               target=bootstrap,
               args=(tx,rx)
       ).start()
       for url in urls:
           task = fetch_url,(url,), {}
           tx.put_nowait(task)
```

已经开源 pip install aiomultiprocess
[aioprocessing](https://github.com/dano/aioprocessing)


## 关于协程
coroutine是一个在很多编程语言中都有的概念，在python中coroutine一般指的是generator based coroutines。
首先，因为协程是一种能暂停的函数，那么它暂停是为了什么？一般是等待某个事件，比如说某个连接建立了；某个 socket 接收到数据了；某个计时器归零了等。而这些事件应用程序只能通过轮询的方式得知是否完成，**但是操作系统（所有现代的操作系统）可以提供一些中断的方式通知应用程序，如 select, epoll, kqueue 等等**。
[understand-python-asyncio](https://lotabout.me/2017/understand-python-asyncio/)

基础是generator(任何包含yield expression的函数)
```
$ >>>def gen_fn():
        print('start')
        yiled 1
        print('middle')
        yield 2
        print('done')
$ >>> gen = gen_fn()
$ >>> gen
$ <generator object gen_fn at 0x7f83cddc0b48>
>>> gen.gi_code.co_code //对应的bytecode
b't\x00d\x01\x83\x01\x01\x00d\x02V\x00\x01\x00t\x00d\x03\x83\x01\x01\x00d\x04V\x00\x01\x00t\x00d\x05\x83\x01\x01\x00d\x00S\x00'
>>> len(gen.gi_code.co_code)
40
>>> gen.gi_frame.f_lasti //instruction pointer , 说明当前执行到哪个指令了，-1说明还没有开始执行
-1
>>> next(gen)
start
1
>>> ret = next(gen)
middle
>>> ret
2 // next方法返回的是yield里面的值
>>> next(gen)
done
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
StopIteration // 这是正常的，说明generator执行完毕


>>> import dis
>>> dis.dis(gen)
  2           0 LOAD_GLOBAL              0 (print)
              2 LOAD_CONST               1 ('start')
              4 CALL_FUNCTION            1
              6 POP_TOP

  3           8 LOAD_CONST               2 (1)
             10 YIELD_VALUE
             12 POP_TOP

  4          14 LOAD_GLOBAL              0 (print)
             16 LOAD_CONST               3 ('middle')
             18 CALL_FUNCTION            1
             20 POP_TOP

  5          22 LOAD_CONST               4 (2)
             24 YIELD_VALUE
             26 POP_TOP

  6          28 LOAD_GLOBAL              0 (print)
             30 LOAD_CONST               5 ('done')
             32 CALL_FUNCTION            1
             34 POP_TOP
             36 LOAD_CONST               0 (None)
             38 RETURN_VALUE
>>>
```

python3.3中开始出现yield关键字，python3.4中开始引入asyncio标准库，python 3.5标准库中出现的async await关键字只是基于generator的sytatic sugar，那么[generator是如何实现的](https://stackoverflow.com/questions/8389812/how-are-generators-and-coroutines-implemented-in-cpython).
- The yield instruction takes the current executing context as a closure, and transforms it into an own living object. This object has a __iter__ method which will continue after this yield statement.
So the call stack gets transformed into a heap object.

[解释generator实现原理的文章](https://hackernoon.com/the-magic-behind-python-generator-functions-bc8eeea54220)

[python 2.5开始，generator能够返回数据，这之前还只是iteratble的](https://snarky.ca/how-the-heck-does-async-await-work-in-python-3-5/) 还可以通过gen.send函数往generator传参数
[event-loop的实现原理简述](https://github.com/AndreLouisCaron/a-tale-of-event-loops)

python3.4需要使用@coroutine的decorator，3.5之后直接使用async await关键字，确实更加方便
```python
import asyncio
import time

async def speak_async(): 
    print('starting====') 
    r = await asyncio.sleep(1) ##这里不能使用time.sleep(1)
    print('OMG asynchronicity!')

loop = asyncio.get_event_loop()  
loop.run_until_complete(speak_async())  
loop.close()  
```


### 多线程环境下对资源的操作需要考虑线程安全问题
有些操作不是原子性的
[Thinking about Concurrency, Raymond Hettinger, Python core developer](https://www.youtube.com/watch?v=Bv25Dwe84g0)
java中最初的设计是有kill thread的method的，但是后来被deprecated了（假设你kill了一个获取了锁的线程，程序将进入死锁状态）。 python中理论上是可以kill一个线程的，但是kill一个线程这件事本身就是不应该的。

一个最简单的多线程资源竞争的例子
```python
import threading

counter = 0

def worker():
    global counter

    counter += 1 
    print('The count is %d' % counter)
    print('------------')


print('Starting up --------')

for i in range(10):
    threading.Thread(target=worker).start()
print('Finishing up')    
```
输出
```
Starting up --------

The count is 1
------------
The count is 2
------------
The count is 3
------------
The count is 4
------------
The count is 5
------------
The count is 6
------------
The count is 7
------------
The count is 8
------------
The count is 9
------------
The count is 10
------------
Finishing up
```
数据量比较小的时候不容易发现这里存在的race condition。如果在每一次对资源进行操作之间都插入一段thread.sleep，问题就出来了

```python
import threading,time, random

FUZZ = True

def fuzz():
    if FUZZ:
        time.sleep(random.random())

counter = 0

def worker():
    global counter
    fuzz()
    oldcnt = counter
    fuzz()
    counter = oldcnt +1
    fuzz()
    print('The count is %d' % counter)
    fuzz()
    print('------------')
    fuzz()


print('Starting up --------\n')
fuzz()

for i in range(10):
    t = threading.Thread(target=worker)
    t.start()
    fuzz()

print('Finishing up')  
fuzz()  
```
资源竞争场景下，问题就出来了
```
Starting up --------

The count is 1
------------
The count is 2
The count is 3
------------
------------
The count is 5
The count is 5
------------
------------
The count is 5
------------
Finishing up
The count is 7
The count is 8
------------
------------
The count is 8
------------
The count is 8
------------
```

多线程之间的同步问题，一种是加锁，另一种是使用atomic message queue.
python中有些module内部已经加了锁，logging,decimal(thread local),databases(reader locks and writer locks),email(atomic message queue)。
锁在写operating system的时候非常有用，但是其他时候不要用。
所有的资源都应该只能同时被一条线程操作。
threading中的join就属于一种barrier（主线程调用t.join，就是等t跑完了之后，主线程再去干接下来的事情） 


### Raymond Hettinger提到message queue的task_done方法是他created的。(还是atomic measge queue, 好像是内部加了锁，操作queue中资源的只有那么一条线程，当然不存在并发问题). 其实raymod也提到了，你也可以用RabbitMQ等,ZEROMQ 甚至是database（内部有read write lock）
```python
def worker():
    while True:
        item = q.get()
        do_work(item)
        q.task_done()

q = Queue()
for i in range(num_worker_threads):
     t = Thread(target=worker)
     t.daemon = True
     t.start()

for item in source():
    q.put(item)

q.join()       # block until all tasks are done
```

爬虫简单的多线程版本是每个线程创建的时候，就给出一个args = [someurl] ，然后有多少任务就创建多少线程。但是这样做迟早会碰上操作系统对最大线程数的设置[据说400+]，于是又想到用threadPool,自己实现threadpool的也是大有人在（内部持有一个任务队列，不停去队列里获取任务）。(https://www.shanelynn.ie/using-python-threading-for-multiple-results-queue/)
```
error: can't start new thread
File "/usr/lib/python2.5/threading.py", line 440, in start
    _start_new_thread(self.__bootstrap, ())
```
那么比较实用的使用场景是，spawn 10条线程去进行while not queue.empty() -> requests.get()操作，各自在完成之后丢到一个通用的容器中，再由message queue独立完成所有response的processing.



## 牵涉到一些celery的点
celery能够利用好多进程
todo


## 参考
[多进程还可以牵涉到进程池的概念](https://codewithoutrules.com/2018/09/04/python-multiprocessing/)
[What is the Python Global Interpreter Lock (GIL)?](https://realpython.com/python-gil/)
[multiprocessing-vs-multithreading-in-python-what-you-need-to-know](https://timber.io/blog/multiprocessing-vs-multithreading-in-python-what-you-need-to-know/)
[A. Jesse Jiryu Davis](https://emptysqua.re/blog/links-for-how-python-coroutines-work/)
[How Do Python Coroutines Work](https://www.youtube.com/watch?v=7sCu4gEjH5I)
[A Jesse Jiryu Davis Grok the GIL Write Fast And Thread Safe Python PyCon 2017](https://www.youtube.com/watch?v=7SSYhuk5hmc) the only thing two threads cann't do in once in Python is run python
[Behold, my friends, the getaddrinfo lock in Python's socketmodule.c:](https://engineering.mongodb.com/post/the-saga-of-concurrent-dns-in-python-and-the-defeat-of-the-wicked-mutex-troll/)
