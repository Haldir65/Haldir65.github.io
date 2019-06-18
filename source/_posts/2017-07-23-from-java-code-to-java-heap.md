---
title: java对象内存占用分析
date: 2017-07-23 19:02:52
tags: [java]
---


![](https://www.haldir66.ga/static/imgs/9b157a7acab582078ac1fabada5c8009.jpg)
面向对象语言就意味着对象要占用内存空间，那么，java中随便new 出来的东西到底多大？还有，new出来的东西全都都放在heap上吗(有些真不是)？
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

在DirectByteBuffer的构造函数中有这么一段内存对齐的函数
```java
if (pa && (base % ps != 0)) {
        // Round up to page boundary
        address = base + ps - (base & (ps - 1));
} else {
    address = base;
}
```


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
![](https://www.haldir66.ga/static/imgs/official_java_primitive_type_size_table.jpg)
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

4. 引用的对象的大小(递归即可) - Retained heap size(Shallow Heap大小加上引用的对象的)
java.lang.Integer还算比较简单的，里面除了一个int值表示value以外，没有其它的成员变量，所以并没有引用到其他对象的实例。对于复杂一点的数据类型，比如jav.lang.String呢？

String本身是一个很简单的类(如果不算常量池的话)，几乎可以看成一个char数组的wrapper。除了一个普通对象的class、Flag和Locks等信息外，String内部还有一个 private int hash（用于Cache hash值），还有offset和count（这俩好像没找到），此外就是一个char数组了。
所以，为了存储8个字符(16个字节,128bits)。首先这个char数组对象占用了16个字节(2*8)+（对象头+数组大小）16个字节 = 256bits。
算到String头上，String本身的文件头是12个字节，算上hash,count,offset各自4个字节，就24个字节了。再加上数组的引用4个字节，再加上数组的大小32个字节。
合计60个字节（480bits）。而这里面实际有用的数据只有16个字节。73.3%的内存都是存储其他东西的。


说的比较乱了，这里直接照搬一段计算,[参考](http://www.yunweipai.com/archives/1092.html)
```
- 一般而言，Java 对象在虚拟机的结构如下：
•对象头（object header）：8 个字节（保存对象的 class 信息、ID、在虚拟机中的状态）
•Java 原始类型数据：如 int, float, char 等类型的数据
•引用（reference）：4 个字节
•填充符（padding）

String定义：

JDK6:
private final char value[];
private final int offset;
private final int count;
private int hash;

JDK6的空字符串所占的空间为40字节

JDK7:
private final char value[];
private int hash;
private transient int hash32;

JDK7的空字符串所占的空间也是40字节

JDK6字符串内存占用的计算方式：
首先计算一个空的 char 数组所占空间，在 Java 里数组也是对象，因而数组也有对象头，故一个数组所占的空间为对象头所占的空间加上数组长度，即 8 + 4 = 12 字节 , 经过填充后为 16 字节。

那么一个空 String 所占空间为：

对象头（8 字节）+ char 数组（16 字节）+ 3 个 int（3 × 4 = 12 字节）+1 个 char 数组的引用 (4 字节 ) = 40 字节。

因此一个实际的 String 所占空间的计算公式如下：

8*( ( 8+12+2*n+4+12)+7 ) / 8 = 8*(int) ( ( ( (n) *2 )+43) /8 )

其中，n 为字符串长度。
```

5. 小结
随便new一个Object就意味着12个Byte没了，数组的话16个字节没了。每添加一个成员变量（指针），4个字节没了。这些都还没算上实际存储的数据。


## 5. java.util框架中使用的那些集合类

### 5.1 HashSet
A HashSet is an implementation of the Set interface。无重复元素，不保证迭代顺序，常规的add,contains等方法速度不会随着内部元素的增加而变慢。HashSet内部最多有一个null，底层实现是HashMap，这意味着其占用内存要比HashMap大。
默认容量 16个Entries
内部元素为空时的大小 144bytes
查找，添加，删除的时间复杂度为 O(1)，在没有Hash collisions发生的前提下

### 5.2 HashMap
A HashMap is an implementation of the Map interface.
HashMap是一种存储Key-Value型数据的集合，一个key最多map到一个value，key和value都可以为null，可以存储重复元素。（所以）——HashMap是HashSet的一种功能上的简化。
底层是Entries(Entries元素是链表)，长这样。
-  transient HashMapEntry<K,V>[] table = (HashMapEntry<K,V>[]) EMPTY_TABLE;
HashMap的成员变量包括：

transient HashMapEntry<K,V>[] table（HashMapEntry的数组）
int size
int threshold
final float loadFactor
transient int modCount;

一个HashMap刚创建时(完全为空时)的大小为128bytes，jdk 1.8在初始化时没有加载Entries，在put操作时才去分配。可能会好一点。
内部结构一般是这样的，一个HashMapEntry的大小为32byte。
int KeyHash
Object next
Object key
Object value
HashMap每次put键值对时，都使用了一个HashMap$Entry这样的包装类，这意味着整个HashMap的overhead包括：
This means that the total overhead of a HashMap consists of the HashMap object, a HashMap$Entry array entry, and a HashMap$Entry object for each entry.
直接照搬结论：对于HashMap
Default capacities为16个 entries

对于一个有10000个Entries的HashMap，光是由于HashMap，Entry数组以及每个Entry对象带来的overhead就达到了360K左右，这里还不算存储的键值对本身的大小。

### 5.3 Hashtable
HashTable和HashMap的主要区别是HashTable是线程安全的，HashTable中很多方法都加上了synchronized修饰。一般来讲，jdk1.5以上如果想要线程安全，直接用synchronizedHashMap。Hashtable继承自Dictionary，后者已经被废弃了，推荐使用map接口的实现类。
照搬结论：要存储10k个Entries，overhead达到360k。

### 5.4 LinkedList
Linkedist是典型的双向链表，除非增删操作特别频繁，否则没必要使用。
查找的时间复杂度为 o(n)。添加的元素被包装在一个Node节点中。
存储10K个元素的overhead为240K。

### 5.5 ArrayList
ArrayList要好很多，value直接存在一个数组内部，查找的时间复杂度为o(1)
存储10K个元素的overhead为40K左右。

### 5.6 StringBuffer，StringBuilder
StringBuffer直接强加synchronized，StringBuilder和StringBuffer都继承自AbstractStringBuilder。成员变量就两个一个char[] value和一个int count。


## 6.集合的默认初始容量和扩系数
以StirngBuffer为例（也算一种char的集合吧），默认容量是16，即创建了一个char[16]，空的，算上对象头，一共72bytes。这还只是StringBuffer里什么都没存储的情况。
StringBuffer sb = new StringBuffer("My String")。//算下用了多少内存
首先算数组，文件头12bytes，加上size 16bytes。算上数组，（数组长度为str.length+16）一共116bytes，算上内存对齐，一共120bytes。StringBuffer对象的大小：对象头+count+数组指针 = 20 bytes。
合计140bytes，内存对齐后144bytes，只为存储"My String"这9个字符（36bytes）。
上面提到的这些集合类都对外提供了可以设置初始容量的构造函数以避免内存浪费，但要注意HashMap只接受2的指数幂。


### 7.high level抽象带来的便利性及所需付出的代价
面向对象语言推荐开发者使用一些高层抽象化的类，但更加复杂的功能意味着内存占用的增加。而内存意味着一切，所以，权衡好开发便利与内存占用对于程序的高效运行就十分重要，而这一切的前提就在于了解这些Wrapper对象工作的原理。


## 一些很有意思的事情
- Integer内部缓存了一个Integer[] ，最大值可以通过(java.lang.Integer.IntegerCache.high)配置
- 不同版本jdk上String的优化很有意思，又是那个一个String占用多少字节的问题
- 关于ConcurrentModificationException，对一个集合的更改分为结构性更改和集合元素值的更改，前者会抛出ConcurrentModificationException，后者不会。



## 参考
- [JAVA 对象大小](https://www.liaohuqiu.net/cn/posts/caculate-object-size-in-java/)
- [一个Java对象到底占用多大内存](http://www.cnblogs.com/zhanjindong/p/3757767.html)
- [查看 Java 对象大小](http://github.thinkingbar.com/lookup-objsize/)
- [From Java code to Java heap](https://www.ibm.com/developerworks/library/j-codetoheap/index.html)
- [Understanding the Memory Usage of Your Application](https://www.youtube.com/watch?v=FLcXf9pO27w)
- [Thanks for the memory, Linux](https://www.ibm.com/developerworks/library/j-nativememory-linux/index.html)
- [boolean数组中一个值占用1bit](http://www.jianshu.com/p/2f663dc820d0)
- [不同jdk版本String做的优化](http://www.yunweipai.com/archives/1092.html)
- [对象头里面的lock是怎么用的](http://www.cnblogs.com/xrq730/p/6928133.html)
- [Android里面的一个View大概0.5kb](https://academy.realm.io/posts/360-andev-2017-romain-guy-chet-haase-android-performance/)Android studio3.0中使用Memory profiler -> dunp java heap -> check Retained Size (能够看到每个View的大小，一个Toolbar大概在18kb)
- [stuart mark也提到了文件头大小](https://www.youtube.com/watch?v=ogRVWXuuAU4)
