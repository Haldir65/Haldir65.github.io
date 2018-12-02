---
title: page-size and block size
date: 2018-12-02 21:42:24
tags:
---

page size（内存相关）和block size(文件系统相关)的一些点
![](https://www.haldir66.ga/static/imgs/scenery1511100718415.jpg)
<!--more-->
wiki上说
Page size常由processor的架构决定的，操作系统管理内存的最小单位是一个Page size(应用程序申请分配内存时，操作系统实际分配的内存是page-size的整数倍)


[Block size vs. page size](http://forums.justlinux.com/showthread.php?3261-Block-size-vs-page-size)
>  block size concerns storage space on a filesystem.
Page size is, I believe, architecture-dependent, 4k being the size for IA-32 (x86) machines. For IA-64 architecture, I'm pretty sure you can set the page size at compile time, with 8k or 16k considered optimal. Again, I'm not positive, but I think Linux supports 4,8,16, and 64k pages.
Block size is a function of the filesystem in use. Many, if not all filesystems allow you to choose the block size when you format, although for some filesystems the block size is tied to/dependent upon the page size.
Minimun block size is usually 512 bytes, the allowed values being determined by the filesystem in question.


unix系统中查看系统的page size
> getconf PAGESIZE ## X86架构的cpu上一般是4096byte


一个很有意思的现象是，java BufferedInputStream的默认buffer数组大小是8192，okio 的segment的默认size也是8192，这些都是以byte为单位的。找到一个合理的[解释](https://stackoverflow.com/questions/37404068/why-is-the-default-char-buffer-size-of-bufferedreader-8192)。大致意思是8192 = 2^13, windows和linux上这个大小正好占用两个分页文件(8kB)。


## block size(硬盘块)
摘抄一段来自[深入浅出腾讯云CDN：缓存篇](https://zhuanlan.zhihu.com/p/26077257)的话：
> 不管SSD盘或者SATA盘都有最小的操作单位，可能是512B，4KB，8KB。如果读写过程中不进行对齐，底层的硬件或者驱动就需要替应用层来做对齐操作，并将一次读写操作分裂为多次读写操作。




## 参考
- [ ] [Paging Technique : Memory management in Operating System](https://www.youtube.com/watch?v=0Rf5Jc61ArM)
