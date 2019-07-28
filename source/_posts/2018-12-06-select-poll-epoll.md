---
title:  select、poll、epoll学习笔记
date: 2018-12-06 08:38:54
tags: [linux,tools,tbd]
---

select，poll，epoll都是IO多路复用的机制。I/O多路复用就通过一种机制，可以监视多个描述符，一旦某个描述符就绪（一般是读就绪或者写就绪），能够通知程序进行相应的读写操作。但select，poll，epoll本质上都是同步I/O，因为他们都需要在读写事件就绪后自己负责进行读写，也就是说这个读写过程是阻塞的，而异步I/O则无需自己负责进行读写，异步I/O的实现会负责把数据从内核拷贝到用户空间。
![](https://www.haldir66.ga/static/imgs/OrionNebula_EN-AU10620917199_1920x1080.jpg)
<!--more-->

linux下提供五种io model
同步IO(synchronous IO)
阻塞IO(bloking IO)
非阻塞IO(non-blocking IO)
多路复用IO(multiplexing IO)
信号驱动式IO(signal-driven IO) 这种用的不多
异步IO(asynchronous IO)
具体的介绍看这篇文章:[五种io模式的介绍](http://cmsblogs.com/?p=4812)



用户态到内核态的内存copy的开销

mac上叫做Kqueue
[epoll或者Kqueue的原理是什么](https://www.zhihu.com/question/20122137)



在看[socket programming in python](https://realpython.com/python-sockets/)这篇文章时发现有selector这样的操作。其实和c语言的做法很相似。


[Windows IOCP与Linux的epoll机制对比](https://www.jianshu.com/p/d2f4c35cb692)
系统I/O模型 可分为三类：
第一种： 阻塞型(blocking model)，
应用进程发起connect请求，进入系统内核方法调用。内核负责发送SYN,等待ACK,等到ACK、SYNC到达以后，发送ACK，连接完成，return用户态的connect调用。以上过程中，应用层一直阻塞。


第二种： 非阻塞同步型(non-blocking model): "wait until any socket is available to read or write from/to buffer, then call non blocking socket function which returns immediately."
可以通过设置SOCK_NONBLOCK标记创建非阻塞的socket fd，或者用fcntl也是一样的。
比方说c语言在linux环境下可以这么写。
```c
 // client side
   int socketfd = socket(AF_INET, SOCK_STREAM | SOCK_NONBLOCK, 0);

   // server side - see man page for accept4 under linux 
   int socketfd = accept4( ... , SOCK_NONBLOCK);
```
对非阻塞fd调用系统接口时，不需要等待事件发生而立即返回，事件没有发生，接口返回-1，此时需要通过errno的值来区分是否出错，有过网络编程的经验的应该都了解这点。不同的接口，立即返回时的errno值不尽相同，如，recv、send、accept errno通常被设置为EAGIN 或者EWOULDBLOCK，connect 则为EINPRO- GRESS 。
就是说，客户端程序会不停地去尝试读取数据，但是不会阻塞在那个读方法里，如果读的时候，没有读到内容，也会立即返回。这就允许我们在客户端里，读到不数据的时候可以搞点其他的事情了。


第三种： 非阻塞异步型(asynchronous aka. overlapping model): "call a socket function which returns immediately, then wait for its completion, then access the result data object"
IO多路复用，I/O复用(I/O multiplexing). IO多路复用是nio的核心和关键，也是实现高性能服务器的关键。
应用进程通过调用epoll_wait阻塞等待可读事件，等可读事件触发时，系统会回调注册的函数。


另外还有信号，async io

IOCP基于非阻塞异步模型，而epoll基于非阻塞同步模型。

[IO模型详解](http://cmsblogs.com/?p=4812) blocking io, nonblocking io, io multiplexing, asynchronous io,etc


[Windows IOCP vs Linux EPOLL Performance Comparison](https://www.slideshare.net/sm9kr/iocp-vs-epoll-perfor)
[IO多路复用之epoll总结](https://www.cnblogs.com/Anker/p/3263780.html)
[Linux IO模式及 select、poll、epoll详解](https://segmentfault.com/a/1190000003063859)
[epoll浅析以及nio中的Selector](https://my.oschina.net/hosee/blog/730598)
[大话 Select、Poll、Epoll](https://cloud.tencent.com/developer/article/1005481)
[There is no Windows equivalent to epoll/kqueue , but there is Overlapped IO](https://news.ycombinator.com/item?id=8526264) 简单说就是windows在这方面设计的更优秀，只是开发者并未买账
[Coroutines, Async/Await, Asyncio and the Pulsar Library](https://www.youtube.com/watch?v=M5-mcKh8QmY) node, go goroutine, nginx, gui libraries ,java nio等都以各种形式采用了或实现了自己的event loop

[IO 多路复用 — SELECT 和 POLL](https://void-shana.moe/linux/io-%E5%A4%9A%E8%B7%AF%E5%A4%8D%E7%94%A8-select-%E5%92%8C-poll.html)

[linux kernel aio是另一个内核提供的异步框架，但是不如epoll成熟](https://www.zhihu.com/question/26943558)
[如何使用 epoll? 一个 C 语言实例](https://www.oschina.net/translate/how-to-use-epoll-a-complete-example-in-c)