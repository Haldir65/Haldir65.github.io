---
title: 使用IDE内置的Terminal
date: 2017-03-11 22:28:51
categories: blog
tags: [android]
---


![io](http://odzl05jxx.bkt.clouddn.com/device-2017-03-11-222239.png?imageView2/2/w/600)
这周终于把Google I/O 2016的Android App在Device上跑起来了，顺便尝试多多使用命令行进行编译或者安装。

<!-- more -->


### 1. 编译Android client并安装到本地设备
官方提供了比较完善的Build Instructions，对于习惯于shift+F10的我来说，还是有点麻烦。

clone下来[iosched](https://github.com/google/iosched)，修改gradle.properities里面的supportLib等值，参考Build Instruction ，

> gradlew clean assembleDebug


往往这一步会开始下载gradle，非常耗时。参考了stackOverFlow，自己去下载gradle 3.3 -all.zip，放到/gradle/wrapper文件夹下，修改gradle-wrapper.properities，将其中的distributionUrl改成


> distributionUrl=gradle-3.3-all.zip

等于直接省去上述下载步骤。Build完成后，敲入命令行

>gradlew installNormalDebug

不出意外的话，即可进入主页面。

### 2. Server端配置
Google io 2016 Android Client提供了Map Intergation和Youtube video display以及GCM等服务。这些全部集成在Google Cloud Platform上配置。


--------------------------------------------------------------------



## 1. Systrace用于跟踪一段方法执行过程中的影响
```java
try {
    Trace.beginSection(TAG);
    // do stuff
    }finally {
     Trace.endSection();
    }
```
计算一段方法到底花了多长时间，当然还是要在Android device monitor里面begin trace，注意要勾选**Enable Application Traces from XXXX**，选中自己的包名就好了。一开始可能不是特别好找，只要在html中ctrl+f找到了自己写的TAG，慢慢来应该能找到的。
