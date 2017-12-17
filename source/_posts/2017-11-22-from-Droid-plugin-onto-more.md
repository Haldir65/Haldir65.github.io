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
adb getEvent sendEvent
input tap x y
input touchescreen
input text helloworld
input keyevent

Xposed的介绍与入门
Xposed的原理与Multidex及动态加载问题

[在Android中执行shell指令](https://github.com/jaredrummler/AndroidShell)
[滴滴的virtualApp](https://github.com/didi/VirtualAPK)


## 参考
[分析DroidPlugin，深入理解插件化框架](https://github.com/tiann/understand-plugin-framework)
[逆向大全](http://www.wjdiankong.cn/)
