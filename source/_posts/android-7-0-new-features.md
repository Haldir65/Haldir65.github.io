---
title: android 7.0一些新特性介绍及适配方案
date: 2016-10-08 03:02:26
tags: android 7
---

## BackGround Optimization

~~CONNECTIVITY_CHANGE~~(很多应用喜欢在Manifest里注册这个BroadCasetReceiver，导致网络变化时，一大堆应用都被唤醒，而ram中无法同时存在这么多process，系统不得不kill old process，由此导致memory thrashing)

同时被移除的还有~~NEW_PICTURE~~,~~NEW_VIDEO~~.

具体来说: 对于**targeting N**的应用，在manifest文件中声明 static broadcastReceiver，监听~~CONNECTIVITY_CHANGE~~将不会唤醒应用。如果应用正在运行，使用context.registerReceiver，将仍能够接受到broadcast。但不会被唤醒。

解决方案: 使用JobScheduler或firebase jobDispatcher。

对于~~NEW_PICTURE~~,~~NEW_VIDEO~~.

所有在7.0 Nuget以上设备运行的应用(无论是否 target N) 都不会收到这些broadcast。简单来说，fully deprecated  !!!

解决方案：使用JobScheduler(可以监听contentProvider change)



## Reference

1. [Docs](https://developer.android.com/topic/performance/background-optimization.html?utm_campaign=adp_series__100616&utm_source=anddev&utm_medium=yt-desc)
2. [youtube](https://www.youtube.com/watch?v=vBjTXKpaFj8)
3. [Andrioid 7.0适配心得](http://gold.xitu.io/entry/57ff7e14a0bb9f005860c805)