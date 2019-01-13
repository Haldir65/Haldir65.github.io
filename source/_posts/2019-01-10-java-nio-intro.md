---
title: java nio使用指南
date: 2019-01-10 22:25:50
tags: [tbd]
---

关于java nio的一些点
![](https://www.haldir66.ga/static/imgs/UmbriaCastelluccio_EN-AU8834990889_1920x1080.jpg)
<!--more-->

[本文大多数内容来自知乎专栏](https://zhuanlan.zhihu.com/p/27625923)的复制粘贴，因为别人写的比我好

### nio及DirectByteBuffer相关操作
nio包含了很多东西，核心的应该是selector
DirectBuffer这个东西很容易讲，一句话就能说清楚：这是一块在Java堆外分配的，可以在Java程序中访问的内存。
先来解释一下几个堆是什么。以32位系统为例（64位系统也是一样的，只是地址空间更大而已，写起来没有32位系统看上去那么简洁），操作系统会为一个进程提供4G的地址空间，换句话说，一个进程可用的内存是4G。在Linux上，又为内核空间留了1G，剩下的3G是可以供用户使用的(粗略来看是这样的)。这1G就叫做内核空间，3G被称为用户空间。
一个java进程下不过对于操作系统而言，肯定是一个用户进程。所以jva也就有了这3G的使用权。jvm想要使用这些内存的时候，会使用malloc方法去找操作系统去要（其实中间还隔了一个C runtime，我们不去管这个细节，只把malloc往下都看成是操作系统的功能，并不会带来太大的问题）
而JVM要来的这些的内存，有一块是专门供Java程序创建对象使用的，这块内存在JVM中被称为堆(heap)。堆这个词快被用烂了，操作系统有堆的概念，C runtime也有，JVM里也有，然后还有一种数据结构也叫堆（参看本课程堆排序部分），为了区别，我在以后的文章里只称JVM中的堆为Java堆。关于Java堆的结构和管理，在后面GC调优部分，我会详细地讲，这里我只介绍一下本节课所需要的内容。
我们使用普通的ByteBuffer，那么这个ByteBuffer就会在Java堆内，被JVM所管理：
```java
ByteBuffer buf = ByteBuffer.allocate(1024);
```
在执行GC的时候，JVM实际上会做一些整理内存的工作，也就说buf这个对象在内存中的实际地址是会发生变化的。有些时候，ByteBuffer里都是大量的字节，这些字节在JVM GC整理内存时就显得很笨重，把它们在内存中拷来拷去显然不是一个好主意。
那这时候，我们就会想能不能给我一块内存，可以脱离JVM的管理呢？在这样的背景下，就有了DirectBuffer。先看一下用法：
```java
ByteBuffer buf = ByteBuffer.allocateDirect(1024);
```
这两个函数的实现是有区别的:
```java
public static ByteBuffer allocateDirect(int capacity) {
        return new DirectByteBuffer(capacity);
    }

    public static ByteBuffer allocate(int capacity) {
        if (capacity < 0)
            throw new IllegalArgumentException();
        return new HeapByteBuffer(capacity, capacity);
    }
```
DirectByteBuffer的核心就是调用了 unsafe.allocateMemory(size)方法。
Java对象在Java堆里申请内存的时候，实际上是比malloc要快的，所以DirectBuffer的创建效率往往是比Heap Buffer差的。
但是，如果进行网络读写或者文件读写的时候，DirectBuffer就会比较快了，说起来好笑，这个快是因为JDK故意把非DirectBuffer的读写搞慢的，我们看一下JDK的源代码。
share/classes/sun/nio/ch/IOUtil.java
```java
static int write(FileDescriptor fd, ByteBuffer src, long position,
                     NativeDispatcher nd) 
        throws IOException
    {   
        if (src instanceof DirectBuffer)
            return writeFromNativeBuffer(fd, src, position, nd);

        // Substitute a native buffer
        int pos = src.position();
        int lim = src.limit();
        assert (pos <= lim);
        int rem = (pos <= lim ? lim - pos : 0); 
        ByteBuffer bb = Util.getTemporaryDirectBuffer(rem);
        try {
            bb.put(src);
            bb.flip();
        // ................略
```
如果src是DirectBuffer，就直接调用writeFromNativeBuffer，如果不是，则要先创建一个临时的DirectBuffer，把src拷进去，然后再调用真正的写操作。为什么要这么干呢？还是要从DirectBuffer不会被GC移动说起。writeFromNativeBuffer的实现，最终会把Buffer的address传给操作系统，让操作系统把address开始的那一段内存发送到网络上。这就要求在操作系统进行发送的时候，这块内存是不能动的(jni调用传递的是地址，地址不能乱动)。而我们知道，GC是会乱搬Java堆里的东西的，所以无奈，我们必须得弄一块地址不会变化的内存，然后把这个地址发给操作系统。


常用的ByteBuffer本质上是一个byte[]，包括这么几个变量
容量（Capacity） 缓冲区能够容纳的数据元素的最大数量。容量在缓冲区创建时被设定，并且永远不能被改变。
上界（Limit） 缓冲区里的数据的总数，代表了当前缓冲区中一共有多少数据。
位置（Position） 下一个要被读或写的元素的位置。Position会自动由相应的 get( )和 put( )函数更新。
标记（Mark） 一个备忘位置。用于记录上一次读写的位置。一会儿，我会通过reset方法来说明这个属性的含义。
ByteBuffer是一个抽象类，不能new出来
```java
ByteBuffer byteBuffer = ByteBuffer.allocate(256);
```
以上的语句可以创建一个大小为256字节的ByteBuffer，此时，mark = -1, pos = 0, limit = 256, capacity = 256。capacity在初始化的时候确定了，运行时就不会再变化了，而另外三个变量是随着程序的执行而不断变化的。

由于本质上就是一个byte[]，读数据的时候position放到0, limit放到当前已经存放的数据的位置，读完为止。写数据的时候也差不多，position放到当前已经存放的数据的curIndex+1，limit放到capicity的位置，填满为止。

从读变成写可以这么干
```java
byteBuffer.limit(byteBuffer.position())
byteBuffer.position(0);

//由于这个方法实在太频繁,jdk就帮忙封装了一个叫做flip的方法
public final Buffer flip() {
        limit = position;
        position = 0;
        mark = -1;
        return this;
    }
```
显然连续调用flip会导致limit变成0，不能读也不能写了。
mark方法类似于打一个标记，待会儿通过reset回到这个position。


### java的byte数组在内存层面不一定是连续的，C语言里面是连续的
原因是GC会挪动内存

## nio的channel
在Java IO中，基本上可以分为文件类和Stream类两大类。Channel 也相应地分为了FileChannel 和 Socket Channel，其中 socket channel 又分为三大类，一个是用于监听端口的ServerSocketChannel，第二类是用于TCP通信的SocketChannel，第三类是用于UDP通信的DatagramChannel。channel 最主要的作用还是用于非阻塞式读写。可以使用Channel结合ByteBuffer进行读写。
一个简单的client server echo程序可以这样写
```java
// server

public class WebServer {
    public static void main(String args[]) {
        try {
            ServerSocketChannel ssc = ServerSocketChannel.open();
            ssc.socket().bind(new InetSocketAddress("127.0.0.1", 8000));
            SocketChannel socketChannel = ssc.accept();

            ByteBuffer readBuffer = ByteBuffer.allocate(128);
            socketChannel.read(readBuffer);

            readBuffer.flip();
            while (readBuffer.hasRemaining()) {
                System.out.println((char)readBuffer.get());
            }

            socketChannel.close();
            ssc.close();
        }
        catch (IOException e) {
            e.printStackTrace();
        }
    }
}

// client
public class WebClient {
    public static void main(String[] args) {
        SocketChannel socketChannel = null;
        try {
            socketChannel = SocketChannel.open();
            socketChannel.connect(new InetSocketAddress("127.0.0.1", 8000));

            ByteBuffer writeBuffer = ByteBuffer.allocate(128);
            writeBuffer.put("hello world".getBytes());

            writeBuffer.flip();
            socketChannel.write(writeBuffer);
            socketChannel.close();
        } catch (IOException e) {
        }
    }
}
```

### MMAP(memory mapped file)
将文件映射到内存空间的操作，懒得看原理的话，背下这段话就够了
>**常规文件操作需要从磁盘到页缓存再到用户主存的两次数据拷贝。而mmap操控文件，只需要从磁盘到用户主存的一次数据拷贝过程。说白了，mmap的关键点是实现了用户空间和内核空间的数据直接交互而省去了空间不同数据不通的繁琐过程。因此mmap效率更高**

mmap函数是unix/linux下的系统调用，mmap系统调用并不是完全为了用于共享内存而设计的,mmap实现共享内存也是其主要作用之一，事实上可以实现两个java进程之间的通信。

A进程
```java
public class Main {
    public static void main(String args[]){
        RandomAccessFile f = null;
        try {
            f = new RandomAccessFile("C:/hinusDocs/hello.txt", "rw");
            FileChannel fc = f.getChannel();
            MappedByteBuffer buf = fc.map(FileChannel.MapMode.READ_WRITE, 0, 20);

            buf.put("how are you?".getBytes());

            Thread.sleep(10000);

            fc.close();
            f.close();

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
```
B进程
```java
public class MapMemoryBuffer {
    public static void main(String[] args) throws Exception {
        RandomAccessFile f = new RandomAccessFile("C:/hinusDocs/hello.txt", "rw");
        FileChannel fc = f.getChannel();
        MappedByteBuffer buf = fc.map(FileChannel.MapMode.READ_WRITE, 0, fc.size());

        while (buf.hasRemaining()) {
            System.out.print((char)buf.get());
        }
        System.out.println();
    }
}
```
很多java方法本质上就是jni进行了系统调用。
在sun.nio.ch.FileChannelImpl里有map的具体实现：
```java
try {
            // If no exception was thrown from map0, the address is valid
            addr = map0(imode, mapPosition, mapSize);
        } catch (OutOfMemoryError x) {

private native long map0(int prot, long position, long length)
```
比如Java的这个map0函数，具体的实现在
solaris/native/sun/nio/ch/FileChannelImpl.c这个文件里

```c
JNIEXPORT jlong JNICALL
Java_sun_nio_ch_FileChannelImpl_map0(JNIEnv *env, jobject this,
                                     jint prot, jlong off, jlong len)
{
    void *mapAddress = 0;
    jobject fdo = (*env)->GetObjectField(env, this, chan_fd);
    jint fd = fdval(env, fdo);
    int protections = 0;
    int flags = 0;

    if (prot == sun_nio_ch_FileChannelImpl_MAP_RO) {
        protections = PROT_READ;
        flags = MAP_SHARED;
    } else if (prot == sun_nio_ch_FileChannelImpl_MAP_RW) {
        protections = PROT_WRITE | PROT_READ;
        flags = MAP_SHARED;
    } else if (prot == sun_nio_ch_FileChannelImpl_MAP_PV) {
        protections =  PROT_WRITE | PROT_READ;
        flags = MAP_PRIVATE;
    }

    mapAddress = mmap64(
        0,                    /* Let OS decide location */
        len,                  /* Number of bytes to map */
        protections,          /* File permissions */
        flags,                /* Changes are shared */
        fd,                   /* File descriptor of mapped file */
        off);                 /* Offset into file */

    if (mapAddress == MAP_FAILED) {
        if (errno == ENOMEM) {
            JNU_ThrowOutOfMemoryError(env, "Map failed");
            return IOS_THROWN;
        }
        return handle(env, -1, "Map failed");
    }

    return ((jlong) (unsigned long) mapAddress);
}
```
其实就是通过jni调用了c语言api.


## 总结
netty的作者在演讲中提到java官方的nio并不特别好，所以，生产环境用的都是netty这种。

## 参考
[美团团队出的关于nio的解说](https://zhuanlan.zhihu.com/p/23488863) 
这里面有一句原话摘抄下来：
> 线程的创建和销毁成本很高，在Linux这样的操作系统中，线程本质上就是一个进程。创建和销毁都是重量级的系统函数。像Java的线程栈，一般至少分配512K～1M的空间，