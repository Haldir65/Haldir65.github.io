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
所有的python bytecode在执行前都需要获得interpreter的lock,one vm thread at a time。
GIL的出现似乎是历史原因（为了方便的直接使用当时现有的c extension）。而没有在python3中被移除的原因是因为这会造成单线程的程序在python3中跑的反而比python2中慢。

因为GIL的存在，python中的线程并不能实现cpu的并发运行(同时只能有一条线程在运行)。但对于I/O intensive的任务来说，cpu都在等待I/O操作完成，所以爬虫这类操作使用多线程是合适的。

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
首先，因为协程是一种能暂停的函数，那么它暂停是为了什么？一般是等待某个事件，比如说某个连接建立了；某个 socket 接收到数据了；某个计时器归零了等。而这些事件应用程序只能通过轮询的方式得知是否完成，**但是操作系统（所有现代的操作系统）可以提供一些中断的方式通知应用程序，如 select, epoll, kqueue 等等**。
[understand-python-asyncio](https://lotabout.me/2017/understand-python-asyncio/)

## 牵涉到一些celery的点
todo


## 参考
[多进程还可以牵涉到进程池的概念](https://codewithoutrules.com/2018/09/04/python-multiprocessing/)
[What is the Python Global Interpreter Lock (GIL)?](https://realpython.com/python-gil/)
[multiprocessing-vs-multithreading-in-python-what-you-need-to-know](https://timber.io/blog/multiprocessing-vs-multithreading-in-python-what-you-need-to-know/)
