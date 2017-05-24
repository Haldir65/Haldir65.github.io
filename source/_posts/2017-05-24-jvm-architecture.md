---
title: jvm架构概述
date: 2017-05-24 22:48:58
tags: [jvm]
---

关于jvm运行的大致架构，最近找到一个比较合适的视频，记录要点如下
![](http://odzl05jxx.bkt.clouddn.com/high_way_scene.jpg?imageView2/2/w/500)
<!--more-->

### 1.从MyApp.java文件开始
大家都知道最开始学习Java的时候，要用javac 来编译MyApp.java来生成一个class文件。
在命令行里，大致是这样的执行顺序:
```java
javac MyApp.java
java MyApp
```
#### 实际上后一句话就创建了一个jvm instance.

### 2. 从class loader进入Execution Engine 再到Host Operating System
java MyApp会调用class loader，后者不仅要负责加载MyApp.class文件，还需要加载java API中的class文件（String,Object,Collection....）。加载的class文件（byte code）被传递给Execution Engine,后者则负责执行byte code（其实也是调用宿主操作系统的方法执行操作）

### 3. where did class loader load class into ?
classloader将class 文件加载进内存中的一部分（Runtime data areas）。到此，jvm architecture的三个主要组件：class loader subsystem,Runtime data areas 以及execution Enigne的主要功能都说清楚了。
所以，这篇文章主要就按照class loader subsystem -> Runtime data areas -> Execution Engine的顺序来讲。


### 4.从classloader开始执行（class loading subsystem）
	- load 将byte code 加载进内存，来源可以是.java文件，可以是.jar文件，甚至可以是network Socket（这要看具体class loader的implementation）。load阶段包含三种不同的class loader，这也是面试时的重点。

	> 1. Bootstrap class loader (jre文件夹中有一个rt.jar文件，里面装的就是java的internal class) // 

	> 2. extension class loader (jre/lib/ext) //负责加载这个文件夹中的class文件

	> 3. Application class loader (CLASSPATH, -cp)//加载CLASSPATH变量中描述的位置

	- load完成后是link
	verify(检查是否是符合jvm标准的byte code) -> prepare(为class中的static variable分配内存，variable被赋默认值) -> Resolve(when all the symbolic reference inside currentclass are resolved，例如引用了其他的class，例如引用了常量池里面的东西，classDefNotFoundException也是在这个时候抛出的)

	注意，以上步骤都是java specification所规定的，但不同的jvm实现可能有微小的差异

class loading subsystem的最后一步是initialize 
class vars to initiazed Value in code(比如静态代码块就是在这时执行的)

### 5. Runtime data area五个部分的划分
Runtime data area 即java virtural machine的内存，可以划分成五部分
	- Method Area
	- Heap
	- java stack 
	- pc Registers
	- Native method stacks

Method Area(方法区，用于存储class的数据，static variable,byte code,class level constant pool都放在这里)	，Method Area也称为Perm gen space(永生代)，默认大小是64MB ，可以通过-XX:MaxPermSize 调节







### 6. Execution Engine的任务
![](http://odzl05jxx.bkt.clouddn.com/starry_sky.jpg?imageView2/2/w/500)







### 参考
[JVM ( java virtual machine) architecture - tutorial](https://www.youtube.com/watch?v=ZBJ0u9MaKtM)