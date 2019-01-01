---
title:  select、poll、epoll学习笔记
date: 2018-12-06 08:38:54
tags: [linux,tools]
---

select，poll，epoll都是IO多路复用的机制。I/O多路复用就通过一种机制，可以监视多个描述符，一旦某个描述符就绪（一般是读就绪或者写就绪），能够通知程序进行相应的读写操作。但select，poll，epoll本质上都是同步I/O，因为他们都需要在读写事件就绪后自己负责进行读写，也就是说这个读写过程是阻塞的，而异步I/O则无需自己负责进行读写，异步I/O的实现会负责把数据从内核拷贝到用户空间。
![](https://www.haldir66.ga/static/imgs/OrionNebula_EN-AU10620917199_1920x1080.jpg)
<!--more-->


用户态到内核态的内存copy的开销

mac上叫做Kqueue
[epoll或者Kqueue的原理是什么](https://www.zhihu.com/question/20122137)



在看[socket programming in python](https://realpython.com/python-sockets/)这篇文章时发现有selector这样的操作。其实和c语言的做法很相似。


[Windows IOCP与Linux的epoll机制对比](https://www.jianshu.com/p/d2f4c35cb692)
系统I/O模型 可分为三类：
阻塞型(blocking model)，
非阻塞同步型(non-blocking model): "wait until any socket is available to read or write from/to buffer, then call non blocking socket function which returns immediately."
以及非阻塞异步型(asynchronous aka. overlapping model): "call a socket function which returns immediately, then wait for its completion, then access the result data object"
IOCP基于非阻塞异步模型，而epoll基于非阻塞同步模型。


[Windows IOCP vs Linux EPOLL Performance Comparison](https://www.slideshare.net/sm9kr/iocp-vs-epoll-perfor)
[IO多路复用之epoll总结](https://www.cnblogs.com/Anker/p/3263780.html)
[Linux IO模式及 select、poll、epoll详解](https://segmentfault.com/a/1190000003063859)
[epoll浅析以及nio中的Selector](https://my.oschina.net/hosee/blog/730598)
[大话 Select、Poll、Epoll](https://cloud.tencent.com/developer/article/1005481)
[There is no Windows equivalent to epoll/kqueue , but there is Overlapped IO](https://news.ycombinator.com/item?id=8526264) 简单说就是windows在这方面设计的更优秀，只是开发者并未买账
[Coroutines, Async/Await, Asyncio and the Pulsar Library](https://www.youtube.com/watch?v=M5-mcKh8QmY) node, go goroutine, nginx, gui libraries ,java nio等都以各种形式采用了或实现了自己的event loop