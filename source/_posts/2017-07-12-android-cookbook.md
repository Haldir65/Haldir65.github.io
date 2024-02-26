---
title: 日常开发手册
date: 2017-07-12 08:40:08
tags: [android,java,tools]
---

A Cookbook shall look like a collection of Recipes, or an index page from where dinner are made. And it keeps you sane.
![](https://api1.reindeer36.shop/static/imgs/Cg-4zFVJ0xGITwm_AA688WRj8n8AAXZ9wGMpd0ADr0J195.jpg)
<!--more-->


github上已经star了四百多个项目，应该复习下了。


## 各个平台相关的特定的一些记录

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
[Fragment源码解析](http://haldir65.github.io/2017/07/12/2017-07-12-fragment-decoded/)  



### 底层原理
[主线程的工作原理](http://haldir65.github.io/2016/10/12/2016-10-12-How-the-mainThread-work/) **Michael Bailey American Express, 他2016年还讲了LayoutInflater的工作原理**
[vsync原理解释](http://djt.qq.com/article/view/987)
[让service常驻后台的方法](http://haldir65.github.io/2016/10/20/2016-10-20-android-dirty-code/)
//下面这些已经有人写的很好了，直接看就可以了
[应用进程启动流程](http://blog.csdn.net/qq_23547831/article/details/51119333)
[Launcher启动流程](http://blog.csdn.net/qq_23547831/article/details/51112031)
[SystemServer进程启动流程](http://blog.csdn.net/qq_23547831/article/details/51105171)
[Zygote进程启动流程](http://blog.csdn.net/qq_23547831/article/details/51104873)
[Apk安装流程](http://blog.csdn.net/qq_23547831/article/details/51210682)
[Activity启动流程](http://blog.csdn.net/qq_23547831/article/details/51224992)
//这个博主写的一系列底层分析都比较清楚

图片出自[搜狐](http://www.sohu.com/a/130814934_675634)
![](https://api1.reindeer36.shop/static/imgs/android-processs.jpg)
[Activity的生命周期](https://www.jianshu.com/p/0a4cb44ce9d1)
[Instant Run的工作原理](https://yq.aliyun.com/articles/202918)
[插件化加载就两件事，代码加载，资源加载](https://blog.csdn.net/watertekhqx/article/details/51303109)

### 新版本适配，新特性
[Android 7.0的适配](http://haldir65.github.io/2016/10/08/android-7-0-new-features/)

### 工具方法
[沉浸式状态栏](http://haldir65.github.io/2016/10/14/2016-10-14-Android-translucent-status-bar/)
[replace butterKnife with databinding](http://haldir65.github.io/2016/09/22/replace-butterKnife-with-databinding/)


### 拆轮子
[Glide源码解析](http://haldir65.github.io/2017/07/21/2017-07-21-glide-decoded/)
[Rxjava2的一些点](http://haldir65.github.io/2017/04/23/2017-04-23-rxjava2-for-android/) **Jake Wharton**
[Retrofit源码解析](http://haldir65.github.io/2017/07/01/2017-07-01-it-began-with-a-few-bits/)
[OkHttp和Okio源码解析](http://haldir65.github.io/2017/07/21/2017-07-21-okhttp-demisified/)

## 跟java相关的
[java集合类的实现原理](http://haldir65.github.io/2017/06/25/2017-06-12-Collections-Refuled-by-Stuart-Marks/)
[Java线程池的一些点](http://haldir65.github.io/2017/04/30/2017-04-30-concurrency-and-beyond/)
[使用AnnotationProcessor自动生成代码](http://haldir65.github.io/2016/12/31/2016-12-31-Eliminating-BoilPlate-AnnotationProcessor/)
[翻译了一个印度口音的关于jvm架构的视频](http://haldir65.github.io/2017/05/24/2017-05-24-jvm-architecture/)
[一个Java Object到底占用多少内存(from java code to java heap)](http://haldir65.github.io/2017/07/23/2017-07-23-from-java-code-to-java-heap/)
[LruCache的原理](http://haldir65.github.io/2017/07/23/2017-07-23-lru-cache-and-more/)

## 工具书
[git常用操作手册](http://haldir65.github.io/2016/09/27/git-manual/)
[adb常用命令手册](http://haldir65.github.io/2016/12/10/2016-12-10-adb-command/)

## 杂乱的点
[java中的任何细碎的点](http://haldir65.github.io/2017/06/17/2017-06-17-tiny-details-in-java/)


## ToDo List
Java相关

- [X] 画一下java的集合框架
- [X] String StringBuffer StringBuilder区别(StringBuffer很多方法都加了synchronized)
- [ ] 多线程异步断点续传框架原理,利用该原理在图片加载框架中的应用(MappedByteBuffer或者RandomAccessFile)
- [X] 多线程断点续传原理，大文件下载oom问题
- [X] java位运算，Collection框架中多次用到了
- [ ] gson的原理，cache什么的，常规json解析器的原理
- [ ] 垃圾回收器的分类及优缺点
- [X] ThreadLocal原理及可能的内存泄漏(主要还是Thread的生命周期比较长)
- [ ] Understanding Dagger2's generated code
- [X] 单例模式需要考虑到jvm优化的问题（为什么要写两个synchronized）
- [ ] java类加载机制(classLoader相关的，类的加载顺序)
- [ ] Java四种引用
- [ ] Future和FutureTask,CompletableFuture这些怎么用
- [ ][反射](http://blog.csdn.net/briblue/article/details/76223206)
- [ ] java堆和栈的区别，如何判断堆栈上的对象死没死
- [ ] 自己写一个一部图片加载框架，并发图像滤镜框架
- [ ] try catch finally到底会不会执行
- [ ] 并发编程，java.util.concurrent里面的类熟练掌握，粗略了解原理
- [ ]写一个[生产者消费者](https://github.com/Mr-YangCheng/ForAndroidInterview/blob/master/java/%5BJava%5D%20%E5%A4%9A%E7%BA%BF%E7%A8%8B%E4%B8%8B%E7%94%9F%E4%BA%A7%E8%80%85%E6%B6%88%E8%B4%B9%E8%80%85%E9%97%AE%E9%A2%98%E7%9A%84%E4%BA%94%E7%A7%8D%E5%90%8C%E6%AD%A5%E6%96%B9%E6%B3%95%E5%AE%9E%E7%8E%B0.md)模型
- [X] HashMap和conrrentHashmap区别(分段锁比较难)[Segement分段，获取size的时候先乐观，然后悲观](https://zhuanlan.zhihu.com/p/31614308)
- [ ] java的包结构：java.lang(Language核心类);java.io(I/O相关);java.util(包含collection和concurrent);java.nio(另一种I/O);java.net(网络操作)
- [ ] 面试长谈[问题](http://www.cnblogs.com/zuoxiaolong/p/life51.html)
- [ ] jvm字节码看函数调用[链接](https://mp.weixin.qq.com/s/jv7avKM3Z3zK8sJNdtii_g)，Jit for dummies
- [ ] OkHttp跑分[github](https://github.com/square/okhttp/blob/master/benchmarks/src/main/java/okhttp3/benchmarks/Benchmark.java)以及作者的[Gplus](https://plus.google.com/+JesseWilson/posts/EJCDEiPrN42)，以及外国人做的[High-Concurrency HTTP Clients on the JVM](https://dzone.com/articles/high-concurrency-http-clients-on-the-jvm)，纯属好玩。
- [ ] 指令重排序，内存栅栏，JVM垃圾回收机制，何时触发MinorGC
- [ ] Eden和Survivor的比例分配等
- [ ] Gson主要的代码在JsonWriter里面，打几个断点即可。gson这类parser的劣势就在于allocating a bounch of String(array) and throw them away。
- [ ] 类[加载机制和时序](http://www.51gjie.com/java/554.html)



Android相关
- [ ] [在线查看AOSP源码的最好网站](http://androidxref.com/9.0.0_r3/)
- [ ] AppCompat源码解析
- [ ] ContentProvider的启动过程
- [ ] IPC，Binder原理[Binder学习指南](http://weishu.me/2016/01/12/binder-index-for-newer/)
- [ ] [Android Internals](https://academy.realm.io/posts/360-andev-2017-effie-barak-android-internals/)
- [ ] cookie存储位置(data/data/package_name/app_WebView/Cookies.db),db存储位置
- [ ] Binder的原理，Binder里面引用计数的原理，Binder底层为什么用红黑树
- [X] 拆ButterKnife
- [X] onSaveInstance,不仅仅是Activity,Fragment，View中也有，具体实现原理。View一定要有id(在View.dispatchSaveInstanceState中判断了id不为-1).[继承BaseSavedState]
- [X] 热修复框架原理
- [Android应用程序资源的编译和打包过程分析](http://blog.csdn.net/luoshengyang/article/details/8744683)
- [ ] WebView JS交互，WebView存在的[漏洞](http://www.jianshu.com/p/9f7e9ab8d2fa),通过反射可看可能存在的[安全问题](https://my.oschina.net/fengheju/blog/673629)以及[C代码](http://blog.csdn.net/xueerfei008/article/details/26750659)
- [ ] Media相关，视频播放etc，相机，滤镜等.[Demo](https://github.com/w1123440793/VideoListDemo)
- [X] FFMpeg，[IjkPlayer](http://www.jianshu.com/p/a4eea7ea4664)，[弹幕](https://github.com/Bilibili/DanmakuFlameMaster)
- [X] using protobuf on android
- [ ] binder线程池被占满(默认最多15条线程)
- [ ] UI Toolkit源码解析(android.widget包下面的)
    - [X] ViewPager的原理，作者Adam Powell
    - [ ] View的源码, View的绘制原理(往displayList那边靠)
    - [ ] ViewGroup源码
    - [X] FrameLayout
    - [X] LinearLayout(主要代码在measureHorizontal,layoutHorizontal)
    - [ ] RelativeLayout
    - [X] PopupWindow(api24以上的深坑网上也有解决方法)
    - [X] Dialog
    - [X] ImageView(onMeasure主要是尊重drawable的aspect ratio)[setImageResource前后图片大小不一致会有些问题](https://www.jianshu.com/p/bebe0029be57)
    - [ ] TextView(super complicated)
    - [X] ScrollView(不到2000行，滑动是在onTouchEvent里面修改mScrollY实现的，而mScrollY会在View的draw里面去translate一下canvas，所以ScrollView就是这么滑动的)
    - [ ] NestedScrollView
    - [ ] ListView原理,加载优化
    - [ ] RecyclerView（这货最早的时候9K行，现在好像1.2W行。prefetcher什么的，滑动过程中不去加载图片，参考我写的Glide笔记）


- [ ] 属性动画据说用了反射，源码解析
- [ ] Aosp中的launcher地址[Launcher3](https://android.googlesource.com/platform/packages/apps/Launcher3/)，网上分析的也很多
- [X] Context是什么
- [ ][Android View的显示框架原理](https://juejin.im/post/5a1e8d5ef265da431280ae19)，讲的比较全
- [X] 美团那个Walle 还是要玩玩的
- [X] Android生命周期在不同版本的表现形式[有些onXXX在高版本不会调](http://blog.csdn.net/liuweiballack/article/details/47026263)，[原因是HoneyComb之后对Activity LifeCycle进行了改动](http://www.androiddesignpatterns.com/2013/08/fragment-transaction-commit-state-loss.html)
- [ ] 要不是Jake Wharton在DroidConNYC2017上提到，还不知道有v4包里面有**AtomicFile**这玩意
- [X] LocalBroadCastManager好像是基于handler实现的
- [ ] armeabiv,arm64-v8a等问题[Android 设备的CPU类型(通常称为”ABIs”)](https://zhuanlan.zhihu.com/p/23102158)
- [ ] Romain Guy提到了android asset atlas，顺带看下[ZygotoInit](http://blog.csdn.net/luoshengyang/article/details/45831269).preloadDrawable的定义在[com.android.internal.R.array.preloadingdrawables](https://android.googlesource.com/platform/frameworks/base/+/refs/heads/nougat-release/core/res/res/values/arrays.xml)
- [ ] Zygote进程启动流程
- [X] SystemServer进程启动流程
- [ ] Launcher启动流程
- [Android 应用点击图标到Activity界面显示的过程分析](https://juejin.im/entry/5a0d02086fb9a045263b2387)
- [Android面试题汇总](https://juejin.im/entry/59dd75cd51882578d5037626)
- [X] [SurfaceView，TextureView从入门到解析](https://cloud.tencent.com/developer/article/1034235)
- [ ] LeakCanary的原理就是registerActivityLifecycleCallbacks,在onDestory的时候，检查有没有该释放没有释放的东西，具体的Pierre-Yves Ricau在[Droidcon NYC 2015 - Detect all memory leaks with LeakCanary!](https://www.youtube.com/watch?v=mU1VcKx8Wzw) 都说过了。
- [ ] [Android watchdog](http://gityuan.com/2016/06/21/watchdog/)
- [ ]加上一个支持多进程的SharedPreference Manager吧，差点忘了。

> Studio里面看源码，find usage没有的话，find in path , choose android sdk

Linux相关
- [X] linux进程间通信方式有哪些（信号量这种）
- [X] Linux command extended
- [X] 搭建mail服务
- [x] win10加ubuntu[双系统](http://www.jianshu.com/p/2eebd6ad284d)安装[如果不需要了直接删分区，删除引导即可]
- [x]win10 装ubuntu有时候失败是因为删除了C盘的一个文件夹[参考](http://blog.csdn.net/fesdgasdgasdg/article/details/54183577)

网络通信
- [X] TCP UDP的不同 TCP三次握手，wireShark[抓包](https://www.youtube.com/watch?v=r0l_54thSYU),抓一个App的包，模拟请求
- [X] 如何维持一个长连接
- [ ] 点击一个网址底层经历哪些过程
- [X] ffmpeg[参考教程](http://blog.csdn.net/leixiaohua1020/article/details/15811977)

Gradle相关
- [ ]写一些DSL吧[Old Driver](https://github.com/Ccixyj/JBusDriver)
- [X] Gradle下载的cache都放在C盘了，问题是C盘哪里，能删吗，C盘快不够用了


Python
- [ ] sending  mail via Flask
- [X] bootstrap integration



数据库相关
- [X] MySql从入门到删库跑路
- [ ] Realm的优点

C语言从入门到放弃
- [X] 加载ffmpeg需要，不得不学[ffmpeg教程](http://blog.csdn.net/leixiaohua1020/article/details/47008825)


数据结构，算法(注意，不值得深究)
- [ ] 数据结构，操作系统
- [X] 编码，底层二进制
- [X] 二分法查找，排序，冒泡，复杂度
- [ ] 数组跟链表区别,数组跟链表排序时区别,数组跟链表排序时区别
- [ ] 八大排序[算法](http://www.cnblogs.com/123hll/p/6903454.html)
- [ ] 算法刷题网站[剑指offer](https://www.nowcoder.com/ta/coding-interviews),[leetcode](https://www.nowcoder.com/ta/leetcode)



## 一些精彩的的演讲
[Droidcon Montreal Jake Wharton - A Few Ok Libraries](https://www.youtube.com/watch?v=WvyScM_S88c)
[Advanced Scrolling Techniques on Android](https://www.youtube.com/watch?v=N3J4ZFiR_3Q)
[Android Graphics Performance](https://www.youtube.com/watch?v=vQZFaec9NpA&feature=youtu.be&t=29m51s) the cost of setAlpha
[Developing Mobile Experiences at Facebook's scale](https://www.youtube.com/watch?v=PBnU0GXtGFY)

## 一些有名的人
[GDE](https://developers.google.com/experts/all/technology/android)
Dianne Hackborn
[Jesse Wilson](https://github.com/swankjesse)

## Good Reading
[Android Source code](https://android-review.googlesource.com)
[Project Butter and other stuff](http://www.jianshu.com/p/75139692b8e6)
[SurfaceFlinger](https://speakerdeck.com/brittbarak/view-to-pixel-2-dot-0-droidcon-sf-17)

## 一些列入的规划的想法
- 多线程下载实例
- 自己写一个ImageLoader(主要是多线程同步的问题,queue)

对于Android来说，平台技术发展相对缓慢，这是跟前端比。
