---
title: 多线程断点续传原理及实现
date: 2017-08-01 22:19:31
tags: [java]
---

主要讲一下在java中实现多线程断点续传的原理,主要讲断点下载的原理。
![](http://odzl05jxx.bkt.clouddn.com/4b52d8db2e9d86b95c730af1db127a81.jpg?imageView2/2/w/600)
<!--more-->


其实就是在Http请求里面加上一个"range"的header，HttpUrlConnection可以这么干：

- conn.setRequestProperty("Range", "bytes=" + 500 + "-" + 1000);

也就是告诉服务器上次下载到的位置，本地写文件可以使用RandomAccessFile。本地需要记录下上次中断后停下来的位置。可以用db记录，也可以用sp记录。


这里面的难点在于多线程同步问题，高效率锁。还得要使用ArrayBlockingQueue。







## 参考 
- [简书](http://www.jianshu.com/p/2b82db0a5181)
- [Demo](https://github.com/AriaLyy/Aria)
- [MultiThreadDownload for Android](https://github.com/Aspsine/MultiThreadDownload)
- [csdn](http://blog.csdn.net/zhaokaiqiang1992/article/details/43939279)