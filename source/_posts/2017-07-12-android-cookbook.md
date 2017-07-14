---
title: Android Cookbook
date: 2017-07-12 08:40:08
tags: [android]
---

A Cookbook shall look like a collection of Recipes, or an index page from where dinner are made. And it keeps you sane.

<!--more-->

## Android平台特定的一些记录

### 布局相关的点
[theme和Style](http://haldir65.github.io/2016/10/10/theme-versus-style/)  **Dan lew**



### 事件分发，动画，自定义View
[android使用selectableItemBackground的一些坑](http://haldir65.github.io/2016/09/23/selectableItemBackground-foreground/)
[activity transition pre and post lollipop](http://haldir65.github.io/2016/09/27/activity-transition-pre-and-post-lollipop/)
[事件分发流程](http://haldir65.github.io/2016/10/06/touch-event-distribution/)
[安卓坐标系常用方法](http://haldir65.github.io/2016/10/13/2016-10-13-Android-coordinate-System/)
[android-Ultra-pull-to-refresh分析](http://haldir65.github.io/2016/10/24/2016-10-24-a-peek-on-pull-to-refresh/)


### 内存管理
[内存泄漏](http://haldir65.github.io/2016/09/18/android-inner-class-leak/)


### 任务管理
[使用Loader进行异步数据操作](http://haldir65.github.io/2016/10/15/2016-10-15-using-loader-in-android-app/)

### V4包里面的东西
[使用RecyclerView的Animation Android Dev Summit 2015](http://haldir65.github.io/2016/10/20/2016-10-20-RecyclerViewAnimationStuff/)   **yigit boyar和Chet Haase**
[自定义LayoutManager](http://haldir65.github.io/2016/10/20/2016-10-20-write-your-own-layoutmanager/)  **Dave Smith**


### 底层原理
[主线程的工作原理](http://haldir65.github.io/2016/10/12/2016-10-12-How-the-mainThread-work/) **Michael Bailey American Express, 他2016年还讲了LayoutInflater的工作原理**
[Fragment源码解析](http://haldir65.github.io/2017/07/12/2017-07-12-fragment-decoded/)   // tbd
[让service常驻后台的方法](http://haldir65.github.io/2016/10/20/2016-10-20-android-dirty-code/)

### 新版本适配，新特性
[Android 7.0的适配](http://haldir65.github.io/2016/10/08/android-7-0-new-features/)

### 工具方法
[沉浸式状态栏](http://haldir65.github.io/2016/10/14/2016-10-14-Android-translucent-status-bar/)
[replace butterKnife with databinding](http://haldir65.github.io/2016/09/22/replace-butterKnife-with-databinding/)




## 跟java相关的
[java集合类的实现原理](http://haldir65.github.io/2017/06/25/2017-06-12-Collections-Refuled-by-Stuart-Marks/)
[Rxjava2的一些点](http://haldir65.github.io/2017/04/23/2017-04-23-rxjava2-for-android/) **Jake Wharton**
[Java线程池的一些点](http://haldir65.github.io/2017/04/30/2017-04-30-concurrency-and-beyond/)
[Retrofit源码解析](http://haldir65.github.io/2017/07/01/2017-07-01-it-began-with-a-few-bits/)
[使用AnnotationProcessor自动生成代码](http://haldir65.github.io/2016/12/31/2016-12-31-Eliminating-BoilPlate-AnnotationProcessor/)
[翻译了一个印度口音的关于jvm架构的视频](http://haldir65.github.io/2017/05/24/2017-05-24-jvm-architecture/)



## 工具书
[git常用操作手册](http://haldir65.github.io/2016/09/27/git-manual/)
[adb常用命令手册](http://haldir65.github.io/2016/12/10/2016-12-10-adb-command/)

## 杂乱的点
[java中的任何细碎的点](http://haldir65.github.io/2017/06/17/2017-06-17-tiny-details-in-java/)


## ToDo List
- [ ] Fragment源码解析
- [ ] AppCompat源码解析
- [X] Glide源码解析（写出来）
- [ ] onSaveInstance,不仅仅是Activity,Fragment，View中也有，具体实现原理
- [ ] Binder的原理，Binder里面引用计数的原理，Binder底层为什么用红黑树
- [ ] 垃圾回收器的分类及优缺点
- [ ] java位运算，Collection框架中多次用到了
- [ ] ThreadLocal原理及可能的内存泄漏
- [ ] LruCache的原理
- [ ] 如何维持一个长连接
- [ ] TCP UDP的不同 TCP三次握手，wireShark抓包
- [ ] Realm的优点
- [ ] ContentProvider的启动过程
- [ ] View的绘制原理
- [ ] 点击一个网址底层经历哪些过程
- [ ] String StringBuffer StringBuilder区别
- [ ] Understanding Dagger2's generated code
- [ ] HashMap和conrrentHashmap区别(分段锁)
- [ ] 多线程异步断点续传框架原理,利用该原理在图片加载框架中的应用
- [ ] 单例模式需要考虑到jvm优化的问题（为什么要写两个synchronized）
- [ ] java类加载机制(classLoader相关的)
- [ ] Java四种引用
- [ ] java堆和栈的区别，如何判断堆栈上的对象死没死
- [ ] linux进程间通信方式有哪些（信号量这种）
- [ ] 多线程断点续传原理，大文件下载oom问题
- [ ] 数组跟链表区别,数组跟链表排序时区别,数组跟链表排序时区别
- [ ] 自己写一个一部图片加载框架，并发图像滤镜框架
- [ ] WebView JS交互
- [ ] try catch finally到底会不会执行
- [ ] 二分法查找，排序，冒泡，复杂度
- [ ] gson的原理，cache什么的，常规json解析器的原理，moshi为什么和Okio更配？
- [ ] 画一下java的集合框架
- [ ] UI Toolkit源码解析
    - [ ] ViewPager的原理
    - [ ] ViewGroup，View的源码
    - [ ] ListView,RecyclerView原理,加载优化(prefetcher什么的，滑动过程中不去加载图片,我记得Glide是没有做这件事的)
- [ ] MySql从入门到删库跑路
- [ ] Linux command extended
- [ ] 数据结构，操作系统






## 一些需要看的演讲
[Droidcon Montreal Jake Wharton - A Few Ok Libraries](https://www.youtube.com/watch?v=WvyScM_S88c)
[Advanced Scrolling Techniques on Android](https://www.youtube.com/watch?v=N3J4ZFiR_3Q)

## 一些有名的人
[GDE](https://developers.google.com/experts/all/technology/android)
Dianne Hackborn
[Jesse Wilson](https://github.com/swankjesse)
