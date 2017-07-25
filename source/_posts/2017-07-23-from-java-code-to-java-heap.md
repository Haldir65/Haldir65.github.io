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


## 3. java进程的内存占用情况

### 3.1 操作系统和runtime占用的内存
操作系统的内存中，一部分被操作系统和kernel所占用。对于用c或者c++写的jvm，还需要分配一部分给c runtime。操作系统和c 
runtime占用的内存比较大，不同的操作系统上不一样，windows上默认是2GB。剩下的内存(即user space)，就是进程可以使用的内存。

### 3.2 剩下的内存(user space)
对于Java进程来讲，这剩下的部分分为两块:
- Java Heap(s)
- Native (non-java) Heap

Java Heap可以通过-Xms 和 -Xmx 来设置最小值和最大值
Native Heap是在分配了java maximum Heap大小之后剩下的大小(jvm占用的内存也算在这里面)


### 3.3 数据类型大小
基本数据类型大小很简单，其实也不简单。这张图是从ibm网站上截下来的
![](http://odzl05jxx.bkt.clouddn.com/official_java_primitive_type_size_table.JPG)
注意一个boolean在数组中只占用一个字节，单独使用占用4个字节。
原理[参考](http://www.jianshu.com/p/2f663dc820d0)


引用的大小：
在 32 位的 JVM 上，一个对象引用占用 4 个字节；在 64 位上，占用 8 个字节。通过 java -d64 -version 可确定是否是 64 位的 JVM。
处理器能够处理的bit范围决定了操作系统能够使用的内存范围：
32位的cpu(2^32 = 4,294,967,296 bits = 4GB)
64位cpu (2^64 = 18,446,744,073,709,551,616 = 16 exabytes)
多数jvm是用c或者c++写的:
-  the Java runtime creates an operating-system process — just as if you were running a C-based program. In fact, most JVMs are written largely in C or C++

查看jvm是否64位的方法:
- java -d64 -version
64位上引用占用大小变大的原因是，需要管理4g以上的内存，指针(内存地址不够用了)

## 4. java对象内存布局，从一个Integer说起

一个class实例占据的大小包括:
1. 自身的大小（对象头+基本数据类型数据大小） - Shadow heap size
Object自身的大小在不同的jvm版本和厂商之间有一些变化，但大体上包括三个部分:

- Class ： 一个指针，指向对应的class，用于表明其类型。比如一个Integer就指向java.lang.Integer这个类(32位上4字节，64位上8字节)
- Flags : A collection of flags that describe the state of the object, including the hash code for the object if it has one, and the shape of the object (that is, whether or not the object is an array).（就是存hash值和用于表示是不是数组的，32位上4字节，64位上8字节）
- Lock 所有的Object都能lock，这部分内存用于表示当前Object是否是被synchronized(32位上4字节，64位上8字节)

所以，对于java.lang.Integer来说，一个Integer的大小就是：
32(class信息)+32(Flags)+32(Lock))+32(int是基本数据类型，4字节) = 128bits（16字节）
事实上，一个Interger的大小是int（4个字节）的四倍，简单来说一个对象的头信息就占用了3个字节。

2. 数组的大小
数组和普通的object差不多，多了一个size(32字节)。也就是说。为了存储一个int值。使用一个大小为1的int[]数组的内存消耗比一个Integer还要大。（同样，32位4字节，64位8字节）。数组因为多一个size，所以4个字节起步。

3. 8个字节变成4个字节
IBM和Oracle的jvm都能够提供ompressed References (-Xcompressedrefs) 和Compressed OOPs (-XX:+UseCompressedOops) 选项。这样一来，原本在64位机器上要占用8个字节的指针就只要占用4个字节了。但这只对java Heap上的内存有效，对于Native Heap这部分，64位占用内存还是要比32位多。所以同样的一份代码，在64位上占用的内存一定比32位上多。jdk 1.6.x之后好像默认是打开了的。

4. 引用的对象的大小(递归即可) - Retained heap size
java.lang.Integer还算比较简单的，里面除了一个int值表示value以外，没有其它的成员变量，所以并没有引用到其他对象的实例。对于复杂一点的数据类型，比如jav.lang.String呢？

String本身是一个很简单的类(如果不算常量池的话)，几乎可以看成一个char数组的wrapper。除了一个普通对象的class、Flag和Locks等信息外，String内部还有一个 private int hash（用于Cache hash值），还有offset和count（这俩好像没找到），此外就是一个char数组了。
所以，为了存储8个字符(16个字节,128bits)。首先这个char数组对象占用了16个字节(2*8)+（对象头+数组大小）16个字节 = 256bits。
算到String头上，String本身的文件头是12个字节，算上hash,count,offset各自4个字节，就24个字节了。再加上数组的引用4个字节，再加上数组的大小32个字节。
合计60个字节（480bits）。而这里面实际有用的数据只有16个字节。73.3%的内存都是存储其他东西的。

5. 小结
随便new一个Object就意味着12个Byte没了，数组的话16个字节没了。每添加一个成员变量（指针），4个字节没了。这些都还没算上实际存储的数据。


## 5. java.util框架中使用的那些集合类

### 5.1 HashSet


### 5.2 HashMap

### 5.3 HashTable

### 5.4 LinkedList

### 5.5 ArrayList

### 5.6 StringBuffer









## 一些很有意思的事情
- Integer内部缓存了一个Integer[] ，最大值可以通过(java.lang.Integer.IntegerCache.high)配置
- 不同版本jdk上String的优化很有意思，又是那个一个String占用多少字节的问题



## 参考
- [JAVA 对象大小](https://www.liaohuqiu.net/cn/posts/caculate-object-size-in-java/)
- [一个Java对象到底占用多大内存](http://www.cnblogs.com/zhanjindong/p/3757767.html)
- [查看 Java 对象大小](http://github.thinkingbar.com/lookup-objsize/)
- [From Java code to Java heap](https://www.ibm.com/developerworks/library/j-codetoheap/index.html)
- [Understanding the Memory Usage of Your Application](https://www.youtube.com/watch?v=FLcXf9pO27w)
- [Thanks for the memory, Linux](https://www.ibm.com/developerworks/library/j-nativememory-linux/index.html)
- [boolean数组中一个值占用1bit](http://www.jianshu.com/p/2f663dc820d0)
- [不同jdk版本String做的优化](http://www.yunweipai.com/archives/1092.html) 

