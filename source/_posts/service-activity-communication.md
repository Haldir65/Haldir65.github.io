---
title: service和activity的通信方式
date: 2016-09-30 15:25:28
categories: [技术]
tags: [service,android]
---

![](http://odzl05jxx.bkt.clouddn.com/service_lifecycle.png)

一年以前写过一篇关于service和Activity相互通信的很详细的博客，当时真的是费了很大心思在上面。现在回过头来看，还是有些不完善的地方，比如aidl没有给，demo不够全面。现在补上。

<!--more-->

1. 关于Android的Service，[官方文档](https://developer.android.com/guide/components/services.html)是这样描述的

> `Service` 是一个可以在后台执行长时间运行操作而不使用用户界面的应用组件。服务可由其他应用组件启动，而且即使用户切换到其他应用，服务仍将在后台继续运行。 此外，组件可以绑定到服务，以与之进行交互，甚至是执行进程间通信 (IPC)。 例如，服务可以处理网络事务、播放音乐，执行文件 I/O 或与内容提供程序交互，而所有这一切均可在后台进行。

这其中也能看出Android对于Service角色的定位，后台工作，不涉及UI。

Service本身包含started Service和Binded Service

对于Binded Service 使用

![](http://odzl05jxx.bkt.clouddn.com/service_binding_tree_lifecycle.png)



## 待续

### reference

[csdn](http://blog.csdn.net/javazejian/article/details/52709857)



