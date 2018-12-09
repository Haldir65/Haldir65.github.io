---
title:  select、poll、epoll学习笔记
date: 2018-12-06 08:38:54
tags: [linux,tools]
---

select，poll，epoll都是IO多路复用的机制。I/O多路复用就通过一种机制，可以监视多个描述符，一旦某个描述符就绪（一般是读就绪或者写就绪），能够通知程序进行相应的读写操作。但select，poll，epoll本质上都是同步I/O，因为他们都需要在读写事件就绪后自己负责进行读写，也就是说这个读写过程是阻塞的，而异步I/O则无需自己负责进行读写，异步I/O的实现会负责把数据从内核拷贝到用户空间。
![](https://www.haldir66.ga/static/imgs/OrionNebula_EN-AU10620917199_1920x1080.jpg)
<!--more-->


用户态到内核态的内存copy的开销



在看[socket programming in python](https://realpython.com/python-sockets/)这篇文章时发现有selector这样的操作。其实和c语言的做法很相似。



[IO多路复用之epoll总结](https://www.cnblogs.com/Anker/p/3263780.html)
[Linux IO模式及 select、poll、epoll详解](https://segmentfault.com/a/1190000003063859)
[epoll浅析以及nio中的Selector](https://my.oschina.net/hosee/blog/730598)
[大话 Select、Poll、Epoll](https://cloud.tencent.com/developer/article/1005481)