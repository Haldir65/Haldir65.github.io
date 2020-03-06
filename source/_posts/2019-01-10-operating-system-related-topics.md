---
title: 操作系统原理
date: 2019-01-10 22:32:11
tags: [tbd]
---

操作系统原理的一些记录
![](https://api1.foster66.xyz/static/imgs/SouthMoravian_ZH-CN13384331455_1920x1080.jpg)
<!--more-->


## 操作系统是如何做好断电保护的？
日志文件系统（journaling file system）是一个具有故障恢复能力的文件系统，在这个文件系统中，因为对目录以及位图的更新信息总是在原始的磁盘日志被更新之前写到磁盘上的一个连续的日志上，所以它保证了数据的完整性。当发生系统错误时，一个全日志文件系统将会保证磁盘上的数据恢复到发生系统崩溃前的状态。同时，它还将覆盖未保存的数据，并将其存在如果计算机没有崩溃的话这些数据可能已经遗失的位置，这是对关键业务应用来说的一个很重要的特性。

## 内存中段和分页的语义是什么

### linux disk  I/O Scheduler
[I/O Scheduler](https://www.elastic.co/guide/en/elasticsearch/guide/current/hardware.html)
ssd的与hdd的策略应不同

[为什么用户态和内核态的切换耗费时间](https://www.cnblogs.com/gtarcoder/articles/5278074.html)
[用户态与内核态](https://www.cnblogs.com/bakari/p/5520860.html)


## 参考
[从内核文件系统看文件读写过程](http://www.cnblogs.com/huxiao-tee/p/4657851.html)
[计算机底层知识拾遗](https://blog.csdn.net/ITer_ZC/column/info/computer-os-network)