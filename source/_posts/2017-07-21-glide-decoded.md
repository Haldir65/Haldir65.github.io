---
title: 2017-07-21-glide-decoded
date: 2017-07-21 00:13:02
tags:
---

glide的源码几个月前曾经拜读过，大致了解了其异步加载的实现原理。图片加载和网络请求很类似，就像当初看Volley，从一个Request --->  CacheDispatch  ---> NetworkDispatcher  ---->  ResponseDeliver。优秀的轮子不仅执行效率高，同时具备高的扩展性。读懂源码其实只是第一步，往下应该是利用框架提供的扩展方案，再往后应该就是能够独立设计出一套类似的框架了。


![](http://odzl05jxx.bkt.clouddn.com/a11f41e0b1df95212c71920b3959cd72.jpg?imageView2/2/w/600)
<!--more-->

## tdb
## 1. 使用入门

## 2. RequestManager
### 2.1 和Context的生命周期挂钩以及如何在生命周期中获取和释放资源

## 3. Engine及任务描述
### 3.1 解码任务

## 4. 缓存机制，BitmapPool以及MemoryCache（算上DiskCache的话至少三层Cache）
