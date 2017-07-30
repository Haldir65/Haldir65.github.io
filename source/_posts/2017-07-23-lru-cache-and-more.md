---
title: LruCache阅读笔记
date: 2017-07-23 19:02:21
tags: [android]
---

LruCache在android3.1中加入，即android.util.LruCache，主要是作为一种合理的缓存策略的实现，用于替代原来的SoftReference。v4包提供了static version的实现，即android.support.v4.util.LruCache。
此外，还有DiskLruCache对应磁盘缓存，在OkHttp和Glide等开源项目中都有，可直接复制过来，改下包名直接用。这些类本质上都是对于Least Recently Used算法的实现。稍微看了下网上的博客，LruCache实际上就是利用了LinkedHashmap的accessorder来实现末位淘汰的。v4包里的LinkedHashmap就是java.util里面的,platform里的LinkedHashmap添加了一些方法。
<!--more-->


## 1. 使用入门
这是最简单的一个用于缓存图片Bitmap的cache的算法
```java
int maxMemory = (int) (Runtime.getRuntime().totalMemory()/1024);
        int cacheSize = maxMemory/8;
        mMemoryCache = new LruCache<String,Bitmap>(cacheSize){
            @Override
            protected int sizeOf(String key, Bitmap value) {
                return value.getRowBytes()*value.getHeight()/1024;
            }
        };
```
这个sizeOf函数必须复写，用于计算单个元素大小，主要为了确保缓存不超出最大容量。

## 2.简单介绍
LruCache是线程安全的，在内部的 get、put、remove 包括 trimToSize 都是安全的（因为都上锁了）

## 简书作者写的比较好






## 参考
- [彻底解析Android缓存机制——LruCache](http://www.jianshu.com/p/b49a111147ee)
- [Android源码解析——LruCache](http://www.jianshu.com/p/bdbfdfd0641b)
- [LruCache 源码解析](https://github.com/LittleFriendsGroup/AndroidSdkSourceAnalysis/blob/master/article/LruCache%E6%BA%90%E7%A0%81%E8%A7%A3%E6%9E%90.md)
