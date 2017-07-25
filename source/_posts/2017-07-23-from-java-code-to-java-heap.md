---
title: java对象内存占用分析
date: 2017-07-23 19:02:52
tags: [java]
---


![](http://odzl05jxx.bkt.clouddn.com/9b157a7acab582078ac1fabada5c8009.jpg?imageView2/2/w/600)
面向对象语言就意味着对象要占用内存空间，那么，java中随便new 出来的东西到底多大？还有，new出来的东西全都都放在heap上吗？
<!--more-->


## 1.首先给出精确判断Object大小的一种方法

一个判断Java Object大小的方法
比较精准的确定一个对象的大小的[方法](https://github.com/liaohuqiu/java-object-size):


```java
public class ObjectSizeFetcher {

    private static Instrumentation instrumentation;

    public static void premain(String args, Instrumentation inst) {
        instrumentation = inst;
    }

    public static long getObjectSize(Object o) {
        return instrumentation.getObjectSize(o);
    }
}
```
这样通常在IDE里面跑不起来。

据说dump memory也行，没试过。

## 2. 内存对齐
JVM为了malloc与gc方便，指定分配的每个对象都需要是8字节的整数倍[参考](http://github.thinkingbar.com/alignment/)
简单来说，一个Object占用的内存大小是8 Byte的倍数


## 3. java对象内存布局
一个class实例占据的大小包括:
1. 自身的大小（对象头+基本数据类型数据大小+引用大小） - Shadow heap size
2. 引用的对象的大小(递归即可) - Retained heap size

### 3.1 基本数据类型大小很简单
![](http://odzl05jxx.bkt.clouddn.com/java_primitives_size.png)

### 3.2 引用的大小：
在 32 位的 JVM 上，一个对象引用占用 4 个字节；在 64 位上，占用 8 个字节。通过 java -d64 -version 可确定是否是 64 位的 JVM。
处理器能够处理的bit范围决定了操作系统能够使用的内存范围：
32位的cpu(2^32 = 4,294,967,296 bits = 4GB)
64位cpu (2^64 = 18,446,744,073,709,551,616 = 16 exabytes)
多数jvm是用c或者c++写的:
-  the Java runtime creates an operating-system process — just as if you were running a C-based program. In fact, most JVMs are written largely in C or C++

查看jvm是否64位的方法:
- java -d64 -version
64位上引用占用大小变大的原因是，需要管理4g以上的内存，指针(内存地址不够用了)


### 3.3 对象头的大小











## 参考
- [JAVA 对象大小](https://www.liaohuqiu.net/cn/posts/caculate-object-size-in-java/)
- [一个Java对象到底占用多大内存](http://www.cnblogs.com/zhanjindong/p/3757767.html)
- [查看 Java 对象大小](http://github.thinkingbar.com/lookup-objsize/)
- [From Java code to Java heap](https://www.ibm.com/developerworks/library/j-codetoheap/index.html)
- [Understanding the Memory Usage of Your Application](https://www.youtube.com/watch?v=FLcXf9pO27w)
- [Thanks for the memory, Linux](https://www.ibm.com/developerworks/library/j-nativememory-linux/index.html)

