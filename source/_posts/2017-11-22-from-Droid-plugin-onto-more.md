---
title: 从DroidPlugin谈插件化开发
date: 2017-11-22 22:33:44
tags: [android,插件化]
---

关于360团队出开源的[DroidPlugin](https://github.com/DroidPluginTeam/DroidPlugin)的一些记录
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/scenery15111006999.jpg?imageView2/2/w/600)

过程中发现了关于插件化，Hook系统方法的操作，摘录下来。
<!--more-->
## 1. 从Context的本质说起
其实也简单，就是ContextImpl，一个各种资源的容器。
```java
Activity extends ContextThemeWrapper
ContextThemeWrapper extends ContextWrapper
ContextWrapper extends Context
```
Activity作为一个天然的交互核心，能够以一个容器的身份（继承而来）轻易获取这些外部资源，也使得基于UI页面的开发变得简单。
如果对于ActivityThread有所了解的话，就知道Activity的生命周期都是在这个类中完成的
简单来说在ContextImpl中createActivityContext方法中使用new的方式创建了一个ContextImpl，整个流程就是ActivityThread在创建一个Activity后，给它不断赋值的过程。ContextImpl只是一个各种资源的容器（比如Resource,Display,PackageInfo,构造函数里面塞了一些，创建出来之后还给一些变量赋了值）。


Hook(使用Invokcation handler，将一个接口的调用原本的实现包揽下来，把原来的结果占为己有，同时添加一些自己要做的事情)[修改getSystemService，添加自定义功能](http://weishu.me/2016/02/16/understand-plugin-framework-binder-hook/)
Hook掉AMS,在startActivity里面添加一些私货

### 1.1 ActivityThread做了很多事
onSaveInstance是从ActivityThread的callCallActivityOnSaveInstanceState方法dispatch下来的。


## 2. Hook作为插件化的切入点给了开发者篡改系统api实现的通道
[比如Hook掉剪切板SystemService](http://weishu.me/2016/02/16/understand-plugin-framework-binder-hook/),
[比如在ActivityManagerService调用IPC操作时添加私货](http://weishu.me/2016/03/07/understand-plugin-framework-ams-pms-hook/)


![](http://odzl05jxx.bkt.clouddn.com/image/jpg/scenery2a2241cc5c1278cf7a28f15f91dbbb7f.jpg?imageView2/2/w/600)



=-============================-============================-============================-=========================





[为什么 Android 要采用 Binder 作为 IPC 机制？](https://www.zhihu.com/question/39440766)


> 传统的进程间通信方式有管道，消息队列，共享内存等，其中管道，消息队列采用存储-转发方式，即数据先从发送方缓存区拷贝到内核开辟的缓存区中，然后再从内核缓存区拷贝到接收方缓存区，至少有两次拷贝过程。共享内存虽然无需拷贝，但控制复杂，难以使用。socket作为一款通用接口，其传输效率低，开销大，主要用在跨网络的进程间通信和本机上进程间的低速通信。Binder通过内存映射的方式，使数据只需要在内存进行一次读写过程。
内存映射，简而言之就是将用户空间的一段内存区域映射到内核空间，映射成功后，用户对这段内存区域的修改可以直接反映到内核空间，相反，内核空间对这段区域的修改也直接反映用户空间。那么对于内核空间<—->用户空间两者之间需要大量数据传输等操作的话效率是非常高的。


[听说你Binder机制学的不错，来面试下这几个问题](https://www.jianshu.com/p/adaa1a39a274)

Client发起IPC请求，是阻塞的吗？

adb getEvent sendEvent
input tap x y
input touchescreen
input text helloworld
input keyevent

Xposed的介绍与入门
Xposed的原理与Multidex及动态加载问题

### 组件化、插件化
组件化、插件化的前提就是解耦

[在Android中执行shell指令](https://github.com/jaredrummler/AndroidShell)
[滴滴的virtualApp](https://github.com/didi/VirtualAPK)


## 参考
[分析DroidPlugin，深入理解插件化框架](https://github.com/tiann/understand-plugin-framework)
[逆向大全](http://www.wjdiankong.cn/)
