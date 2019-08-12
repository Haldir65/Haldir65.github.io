---
title: jmm(java memory model)概述
date: 2017-05-24 22:48:58
categories: blog
tags: [jvm]
---

关于jvm运行的大致架构，最近找到一个比较合适的视频，记录要点如下
![](https://www.haldir66.ga/static/imgs/high_way_scene.jpg)
<!--more-->

## 1.从MyApp.java文件开始
大家都知道最开始学习Java的时候，要用javac 来编译MyApp.java来生成一个class文件。
在命令行里，大致是这样的执行顺序:
```java
javac MyApp.java
java MyApp
```
** 实际上后一句话就创建了一个jvm instance.**

## 2. 从class loader进入Execution Engine 再到Host Operating System
java MyApp会调用class loader，后者不仅要负责加载MyApp.class文件，还需要加载java API中的class文件（String,Object,Collection....）。加载的class文件（byte code）被传递给Execution Engine,后者则负责执行byte code（其实也是调用宿主操作系统的方法执行操作）

## 3. where did class loader load class into ?
classloader将class 文件加载进内存中的一部分（Runtime data areas）。到此，jvm architecture的三个主要组件：class loader subsystem,Runtime data areas 以及execution Enigne的主要功能都说清楚了。
所以，这篇文章主要就按照class loader subsystem -> Runtime data areas -> Execution Engine的顺序来讲。


## 4.从classloader开始执行（class loading subsystem）
	- load 将byte code 加载进内存，来源可以是.java文件，可以是.jar文件，甚至可以是network Socket（这要看具体class loader的implementation）。load阶段包含三种不同的class loader，这也是面试时的重点。

	> 1. Bootstrap class loader (jre文件夹中有一个rt.jar文件，里面装的就是java的internal class) //

	> 2. extension class loader (jre/lib/ext) //负责加载这个文件夹中的class文件

	> 3. Application class loader (CLASSPATH, -cp)//加载CLASSPATH变量中描述的位置

	- load完成后是link
	verify(检查是否是符合jvm标准的byte code) -> prepare(为class中的static variable分配内存，variable被赋默认值) -> Resolve(when all the symbolic reference inside currentclass are resolved，例如引用了其他的class，例如引用了常量池里面的东西，classDefNotFoundException也是在这个时候抛出的)

	注意，以上步骤都是java specification所规定的，但不同的jvm实现可能有微小的差异

class loading subsystem的最后一步是initialize
class vars to initiazed Value in code(比如静态代码块就是在这时执行的)

## 5. Runtime data area五个部分的划分
Runtime data area 即java virtural machine的内存，可以划分成五部分
	//per jvm ,shared by all threads
	- Method Area
	- Heap

	// per thread
	- java stack
	- pc Registers
	- Native method stacks

### 1. Method Area(方法区，用于存储class的数据，static variable,byte code,class level constant pool都放在这里)	，Method Area也称为Perm gen space(永生代)，默认大小是64MB ，可以通过-XX:MaxPermSize 调节 。这里有可能抛出out of memory error。

### java8将method Area移除，改为 metaspace (就是将method area移到了Native Memory，这样就不会有限制了，也可以人为设置上限)

### 2. Heap
日常开发中new出来的东西都放在这里

-Xms , minimun size
-Xmx , maximum size

### 3. Java Stack
java stacks contains stack frames of the current execution per thread.
eg : method a -> 调用 method b -> 调用method c
当前线程的方法栈中就会push三个stack frame(每个Frame对应一个方法的执行环境)
stack Frame包含当前方法中的变量，以及返回值，etc
这里定义了stackoverFlowError



### 4. pc Registers
这里面装的是程序计数器，后者是指向下一个将要被执行的指令的指针（每条线程都有）。

### 5. Native method stacks
Native method stacks 是由java stack中的方法调用native方法创建的，例如windows上的dll库




## 6. Execution Engine的任务
![](https://www.haldir66.ga/static/imgs/starry_sky.jpg)
	- Interpreter 将byte code 翻译成机器指令并执行(根据指令去调用Native方法，在windows上jre/bin/文件夹中一大堆的dll就是windows平台提供的Native库，在linux上是.so文件)

	- JIT Compiler  just in time compiler（如果有某项byte code instruction被多次调用，这些byte code不会每次都被inteprete，JIT will hold on to that system level target machine code for future usage,which is fast）
	- Hotspot profiler(it helps the JIT Compiler analysise the frequently used byte codess)
	- GC (a lengthy talk)

调用Native Method Interface(JNI) -> Native method libraries（.dll,.so etc）



[java中new一个对象的时候发生了什么](https://blog.csdn.net/SudaDays/article/details/81006483 )
首先，讨论该类没有显式的继承任何类的情况。此时，JVM会检查是否已经加载了这个类，如果没有加载，就会加载该类，一个类只会被加载一次。加载该类的时候会按顺序初始化静态变量，并执行静态语句块，静态函数要被调用才会执行。假如静态变量或静态代码块初始化了一个类的话，会再次执行上面的过程。加载完类之后，开始生成对象，会按照顺序初始化成员变量，基本类型被初始化为0，引用类型被初始化为NULL，然后执行构造器。

下面讨论该类显式继承了一个类的情况，被继承的类没有再显式的继承。JVM会先检查父类是否被加载，如果未加载，则加载该类，并会初始化静态变量并执行静态代码块。然后检查子类，若未加载则同上。当所用到的类加载完后，开始初始化父类，先初始化成员变量，然后执行构造器。子类顺序相同。

总结，JVM会从被继承的最顶层类加载，依次初始化每个类的静态成员变量，执行静态代码块。再从被继承的最顶层类依次初始化成员变量，调用构造器。
![](https://www.haldir66.ga/static/imgs/WolfeCreekCrater_ZH-CN10953577427_1920x1080.jpg)



主流的垃圾回收主要分两大类：引用计数和可达性分析。
JVM没有使用引用计数法，而是使用了可达性分析来进行GC。
可达性分析是基于图论的分析方法，它会找一组对象作为GC Root（根结点），并从根结点进行遍历，遍历结束后如果发现某个对象是不可达的（即从GC Root到此对象没有路径），那么它就会被标记为不可达对象，等待GC。
能作为GC Root的对象必定为可以存活的对象，比如全局性的引用（静态变量和常量）以及某些方法的局部变量（栈帧中的本地变量表）。

以下对象通常可以作为GC Root：

存活的线程
虚拟机栈(栈桢中的本地变量表)中的引用的对象
方法区中的类静态属性以及常量引用的对象
本地方法栈中JNI引用的局部变量以及全局变量


指令重排
int a = 1;
int b = 1;
a = a + 1;
b = b +1 ;
就可能没有
int a = 1;
a = a + 1;
int b = 1;
b = b +1 ;
性能好，因为后者可以 a或b可能在寄存器中了。

处理器为啥要重排序？因为一个汇编指令也会涉及到很多步骤，每个步骤可能会用到不同的寄存器，CPU使用了流水线技术，也就是说，CPU有多个功能单元（如获取、解码、运算和结果），一条指令也分为多个单元，那么第一条指令执行还没完毕，就可以执行第二条指令，前提是这两条指令功能单元相同或类似，所以一般可以通过指令重排使得具有相似功能单元的指令接连执行来减少流水线中断的情况。


方法区又被称为静态区，是程序中永远唯一的元素存储区域。和堆一样，是各个线程共享的内存区域。它用于存储已被虚拟机加载的类信息、常量、静态变量、即时编译器编译后的代码等数据。

### updates
Java中的对象一定在堆上分配内存吗？(随着逃逸分析技术的成熟，有些对象可以被分配在栈内存上)

jmm(java memory model)

### 参考
[JVM ( java virtual machine) architecture - tutorial](https://www.youtube.com/watch?v=ZBJ0u9MaKtM)
[Java系列笔记(3) - Java 内存区域和GC机制](http://www.cnblogs.com/zhguang/p/3257367.html)
[Java内存区域——堆，栈，方法区等](https://blog.csdn.net/qian520ao/article/details/78952895)
[理解Java内存区域与Java内存模型](https://blog.csdn.net/javazejian/article/details/72772461)
[Java 并发基础之内存模型](https://javadoop.com/post/java-memory-model)