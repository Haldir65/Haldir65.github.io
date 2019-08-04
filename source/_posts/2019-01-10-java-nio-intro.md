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
而JVM要来的这些的内存，有一块是专门供Java程序创建对象使用的，这块内存在JVM中被称为堆(heap)。堆这个词快被用烂了，操作系统有堆的概念，C runtime也有，JVM里也有，然后还有一种数据结构也叫堆.
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
但是，如果进行网络读写或者文件读写的时候，DirectBuffer就会比较快了。 **说起来好笑，这个快是因为JDK故意把非DirectBuffer的读写搞慢的，我们看一下JDK的源代码**。
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
原因是GC会挪动内存，所以DirectByteBuffer存在的主要意义是为了给c语言层调用提供连续的内存。

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


### Selector
java.nio.channels.Selector是一个抽象类，因为在不同的操作系统上的实现不一样。但基本原理是一样的，所有的Channel都由selector管理，用户层向selector注册感兴趣的IO动作，并通过selctor.select方法轮询IO事件。
java nio中主要的Channel的实现包括:
- FileChannel (处理文件io)
- DatagramChannel (处理udp通信)
- SocketChannel （通过tcp读取网络数据）
- ServerSocketChannel(服务端接收传入的tcp数据)


改进一下上面的WebClient和WebServer。
```java
public class EpollServer {
    public static void main(String[] args) {
        try {
            ServerSocketChannel ssc = ServerSocketChannel.open();
            ssc.socket().bind(new InetSocketAddress("127.0.0.1", 8001));
            ssc.configureBlocking(false);

            Selector selector = Selector.open();
            // 注册 channel，并且指定感兴趣的事件是 Accept
            ssc.register(selector, SelectionKey.OP_ACCEPT);

            ByteBuffer readBuff = ByteBuffer.allocate(1024);
            ByteBuffer writeBuff = ByteBuffer.allocate(128);
            writeBuff.put("received".getBytes());
            writeBuff.flip();

            while (true) {
                int nReady = selector.select();
                Set<SelectionKey> keys = selector.selectedKeys();
                Iterator<SelectionKey> it = keys.iterator();

                while (it.hasNext()) {
                    SelectionKey key = it.next();
                    it.remove();

                    if (key.isAcceptable()) {
                        // 创建新的连接，并且把连接注册到selector上，而且，
                        // 声明这个channel只对读操作感兴趣。
                        SocketChannel socketChannel = ssc.accept();
                        socketChannel.configureBlocking(false);
                        socketChannel.register(selector, SelectionKey.OP_READ);
                    }
                    else if (key.isReadable()) {
                        SocketChannel socketChannel = (SocketChannel) key.channel();
                        readBuff.clear();
                        socketChannel.read(readBuff);

                        readBuff.flip();
                        System.out.println("received : " + new String(readBuff.array())+" at "+ System.currentTimeMillis());
                        key.interestOps(SelectionKey.OP_WRITE);
                    }
                    else if (key.isWritable()) {
                        writeBuff.rewind();
                        SocketChannel socketChannel = (SocketChannel) key.channel();
                        socketChannel.write(writeBuff);
                        System.out.println("dispatched msg to client  : " + new String(writeBuff.array())+" at "+ System.currentTimeMillis());
                        key.interestOps(SelectionKey.OP_READ);
                    }
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}


public class EpollClient {
    public static void main(String[] args) {
        try {
            SocketChannel socketChannel = SocketChannel.open();
            socketChannel.connect(new InetSocketAddress("127.0.0.1", 8001));

            ByteBuffer writeBuffer = ByteBuffer.allocate(32);
            ByteBuffer readBuffer = ByteBuffer.allocate(32);

            writeBuffer.put("hello".getBytes());
            writeBuffer.flip();

            while (true) {
                writeBuffer.rewind();
                socketChannel.write(writeBuffer);
                readBuffer.clear();
                socketChannel.read(readBuffer);
                System.out.println("received  from server :" + new String(readBuffer.array()));
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}    
```

这套处理io事件的程序模型在python中也有对应的selector模块，使用方式也是相近的。因为无论是java还是python，都是对操作系统上的c语言api的select,poll,epoll系统调用进行了封装。SelectionKey类似于epoll中的一个事件，包括OP_READ，OP_WRITE，OP_ACCEPT和OP_CONNECT。事实上从openjdk源码来看，确实是对poll的封装

selctor在openjdk的实现是:
selctor.select -> PollSelectorImpl.doSelect ->  pollWrapper.poll -> poll0

sun.nio.ch.PollArrayWrapper 
```java
private native int poll0(long pollAddress, int numfds, long timeout);
```
对应的c语言实现在:
jdk8u-jdk/src/solaris/native/sun/nio/ch/PollArrayWrapper.c
```c

#include "jni.h"
#include "jni_util.h"
#include "jvm.h"
#include "jlong.h"
#include "sun_nio_ch_PollArrayWrapper.h"
#include <poll.h>
#include <unistd.h>
#include <sys/time.h>

JNIEXPORT jint JNICALL
Java_sun_nio_ch_PollArrayWrapper_poll0(JNIEnv *env, jobject this,
                                       jlong address, jint numfds,
                                       jlong timeout)
{
    struct pollfd *a;
    int err = 0;

    a = (struct pollfd *) jlong_to_ptr(address);

    if (timeout <= 0) {           /* Indefinite or no wait */
        RESTARTABLE (poll(a, numfds, timeout), err); ## 就是调用了poll
    } else {                     /* Bounded wait; bounded restarts */
        err = ipoll(a, numfds, timeout);
    }

    if (err < 0) {
        JNU_ThrowIOExceptionWithLastError(env, "Poll failed");
    }
    return (jint)err;
}
```

windows平台的实现是sun.nio.ch.WindowsSelectorImpl.java



### MMAP(memory mapped file)
将文件映射到内存空间的操作，懒得看原理的话，背下这段话就够了
>**常规文件操作需要从磁盘到页缓存再到用户主存的两次数据拷贝。而mmap操控文件，只需要从磁盘到用户主存的一次数据拷贝过程。说白了，mmap的关键点是实现了用户空间和内核空间的数据直接交互而省去了空间不同数据不通的繁琐过程。因此mmap效率更高**

实际上,mmap系统调用并不是完全为了用于共享内存而设计的.它本身提供了不同于一般对普通文件的访问方式,是进程可以像读写内存一样对普通文件操作.而Posix或System V的共享内存则是纯粹用于共享内存的,当然mmap实现共享内存也是主要应用之一.
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


jni可以做一些很有意思的事情
标准输入，标准输出，标准错误输出是所有操作系统都支持的，对于一个进程来说，文件描述符0,1,2固定是标准输入，标准输出，标准错误输出。

java语法中有一条是final的成员变量要么在声明的时候就初始化，要么在构造函数中就得初始化。在System这个class中，我们看到了使用jni强行修改final变量的做法
[JDK 源码阅读 : FileDescriptor](http://www.importnew.com/28981.html)文中提到:
> System作为一个特殊的类，类构造时无法实例化in/out/err，构造发生在initializeSystemClass被调用时，但是in/out/err是被声明为final的，如果声明时和类构造时没有赋值，是会报错的，所以System在实现时，先设置为null，然后通过native方法来在运行时修改（学到了不少奇技淫巧。。），通过setIn0/setOut0/setErr0的注释也可以说明这一点：

```java
public final class System {
    public final static InputStream in = null;
    public final static PrintStream out = null;
    public final static PrintStream err = null;
    /**
    * Initialize the system class.  Called after thread initialization.
    */
    private static void initializeSystemClass() {
        FileInputStream fdIn = new FileInputStream(FileDescriptor.in);
        FileOutputStream fdOut = new FileOutputStream(FileDescriptor.out);
        FileOutputStream fdErr = new FileOutputStream(FileDescriptor.err);
        setIn0(new BufferedInputStream(fdIn));
        setOut0(newPrintStream(fdOut, props.getProperty("sun.stdout.encoding")));
        setErr0(newPrintStream(fdErr, props.getProperty("sun.stderr.encoding")));
    }
    private static native void setIn0(InputStream in);
    private static native void setOut0(PrintStream out);
    private static native void setErr0(PrintStream err);
}
```

```c
/*
 * The following three functions implement setter methods for
 * java.lang.System.{in, out, err}. They are natively implemented
 * because they violate the semantics of the language (i.e. set final
 * variable).
 */
JNIEXPORT void JNICALL
Java_java_lang_System_setIn0(JNIEnv *env, jclass cla, jobject stream)
{
    jfieldID fid =
        (*env)->GetStaticFieldID(env,cla,"in","Ljava/io/InputStream;");
    if (fid == 0)
        return;
    (*env)->SetStaticObjectField(env,cla,fid,stream);
}
JNIEXPORT void JNICALL
Java_java_lang_System_setOut0(JNIEnv *env, jclass cla, jobject stream)
{
    jfieldID fid =
        (*env)->GetStaticFieldID(env,cla,"out","Ljava/io/PrintStream;");
    if (fid == 0)
        return;
    (*env)->SetStaticObjectField(env,cla,fid,stream);
}
JNIEXPORT void JNICALL
Java_java_lang_System_setErr0(JNIEnv *env, jclass cla, jobject stream)
{
    jfieldID fid =
        (*env)->GetStaticFieldID(env,cla,"err","Ljava/io/PrintStream;");
    if (fid == 0)
        return;
    (*env)->SetStaticObjectField(env,cla,fid,stream);
}
```

这篇文章还指出了:
>尝试关闭0，1，2文件描述符，需要特殊的操作。首先这三个是不能关闭的，
如果关闭了，后续打开的文件就会占用这三个描述符，

```c
// /jdk/src/solaris/native/java/io/FileInputStream_md.c
JNIEXPORT void JNICALL
Java_java_io_FileInputStream_close0(JNIEnv *env, jobject this) {
    fileClose(env, this, fis_fd);
}
// /jdk/src/solaris/native/java/io/io_util_md.c
void fileClose(JNIEnv *env, jobject this, jfieldID fid)
{
    FD fd = GET_FD(this, fid);
    if (fd == -1) {
        return;
    }
    /* Set the fd to -1 before closing it so that the timing window
     * of other threads using the wrong fd (closed but recycled fd,
     * that gets re-opened with some other filename) is reduced.
     * Practically the chance of its occurance is low, however, we are
     * taking extra precaution over here.
     */
    SET_FD(this, -1, fid);
    // 尝试关闭0，1，2文件描述符，需要特殊的操作。首先这三个是不能关闭的，
    // 如果关闭的，后续打开的文件就会占用这三个描述符，
    // 所以合理的做法是把要关闭的描述符指向/dev/null，实现关闭的效果
    // 不过Java代码中，正常是没办法关闭0，1，2文件描述符的
    if (fd >= STDIN_FILENO && fd <= STDERR_FILENO) {
        int devnull = open("/dev/null", O_WRONLY);
        if (devnull < 0) {
            SET_FD(this, fd, fid); // restore fd
            JNU_ThrowIOExceptionWithLastError(env, "open /dev/null failed");
        } else {
            dup2(devnull, fd);
            close(devnull);
        }
    } else if (close(fd) == -1) { // 关闭非0，1，2的文件描述符只是调用close系统调用
        JNU_ThrowIOExceptionWithLastError(env, "close failed");
    }
}
```

[知乎上关于DirectByteBuffer的讨论](https://www.zhihu.com/question/60892134/answer/191781461)
>整个JVM都是运行在用户空间上的，不存在内核空间的分配。Java NIO 的IO读写如果不是directbuffer就把数据copy的临时的directbuffer中再做IO读写。所以直接使用directbuffer会节省内存copy次数，这是JavaNIO框架具体实现方式的限制，不好称之为“优势”。JavaNIO使用directbuffer进行IO读写的原因主要是在GC优化上。jvm并不是不能直接用java heapbuffer或java byte[]直接做IO读写，但会mark此段内存不能移动，从而影响GC效率。但是JavaNIO框架里的IO操作都是非阻塞模式的快速操作，究竟能影响多少GC效率还不能轻易下结论。JavaNIO的高效主要体现在相对java bio在管理大量连接时少使用了很多线程而节省的线程资源和线程切换，但其编程模型比BIO要复杂得多，只能说NIO高效，不好说它“高级”。对于客户端使用少量连接时，BIO比NIO更有优势，不但编程模型简单，IO效率也不比NIO差。directbuffer本身也是一个内存隐患，使用directbuffer并不能像heapbuffer或byte[]一样任意使用可以被GC及时的回收。所以使用directbuffer最好是分配好缓存起来重复使用，否则很容易出现OOM错误。

DirectByteBuffer这个对象占用的内存是放在java heap上的，这部分没多少，但是其分配的native内存(也就是放在C语言的heap上的)是占主要大小的。这部分的释放使用了PhantomReference追踪DirectByteBuffer被加入到ReferenceQueue的时候就会开始运行一个runnbale，这里面去调用jni方法释放内存。


### FileChannel的几个重要方法

直接上一个用FileChannel读取文件的代码
```java
RandomAccessFile aFile = new RandomAccessFile("/tmp/sample.txt", "rw");
FileChannel inChannel = aFile.getChannel();
ByteBuffer buf = ByteBuffer.allocate(48);
int bytesRead = inChannel.read(buf);
while (bytesRead != -1) {
  System.out.println("Read " + bytesRead);
  buf.flip();
  while(buf.hasRemaining()){
    System.out.print((char) buf.get());
  }

  buf.clear();
  bytesRead = inChannel.read(buf);
}
aFile.close();
```


## 3. 从opnjdk的C语言实现来看jvm对system call的选择
[Java File I/O大混战](https://www.youtube.com/watch?v=MSYbEQLm8ww) 这篇youtube上的演讲从jdk对system call调用的选择来看分析了各自的效率
FileChannel.transferTo方法会根据host machine的操作系统选择文件操作的system call方案:
速度和效率也是依次降低
1. sendFile（linux kernel 2.4+支持，data copy使用磁盘DMA engine，不消耗cpu，即所谓zero copy）
2. mmap
3. read(最慢)

[上面这段话的代码实例在FileChannelImpl.java这个文件中](https://github.com/AdoptOpenJDK/openjdk-jdk8u/blob/master/jdk/src/share/classes/sun/nio/ch/FileChannelImpl.java)
```java
public long transferTo(long position, long count,
                           WritableByteChannel target)
        throws IOException
{
            // Attempt a direct transfer, if the kernel supports it
    if ((n = transferToDirectly(position, icount, target)) >= 0)
        return n;

    // Attempt a mapped transfer, but only to trusted channel types
    if ((n = transferToTrustedChannel(position, icount, target)) >= 0)
        return n;

    // Slow path for untrusted targets
    return transferToArbitraryChannel(position, icount, target);
}
```


[zero copy技术](https://xunnanxu.github.io/2016/09/10/It-s-all-about-buffers-zero-copy-mmap-and-Java-NIO/)

## 4. java nio介绍
[java nio介绍](https://www.zfl9.com/java-nio.html#more) 文章写的非常好
java io的发展经历了三个阶段
1. io/bio 即java.io.*，面向流，阻塞io，逐个字节的读写，没有相应的缓冲（除了bufferd），效率较低
2. nio ，java.nio.* 面向缓冲区，阻塞/非阻塞，包含Buffer,Channel,Selector
3 .aio/nio.2,  java.nio.channels.Asynchronous*,异步IO、阻塞IO、由ThreadPool线程池实现，每个异步IO Channel都属于某个AsynchronousChannelGroup，而每个AsynchronousChannelGroup都与一个ThreadPool相关联。

BIO、NIO、AIO 适用场景分析：
1) BIO方式适用于连接数目比较小且固定的架构，这种方式对服务器资源要求比较高，并发局限于应用中，JDK1.4 以前的唯一选择，但程序直观简单易理解。
2) NIO方式适用于连接数目多且连接比较短（轻操作）的架构，比如聊天服务器，并发局限于应用中，编程比较复杂，JDK1.4 开始支持。
3) AIO方式适用于连接数目多且连接比较长（重操作）的架构，比如相册服务器，充分调用 OS 参与并发操作，编程比较复杂，JDK1.7 开始支持。

linux下提供五种io model（这个主要是针对socket来讲的，本地File读取都是阻塞的，不要想太多）
1. 同步IO(synchronous IO)
2. 阻塞IO(bloking IO)
3. 非阻塞IO(non-blocking IO)
4. 多路复用IO(multiplexing IO)
5. 信号驱动式IO(signal-driven IO) 这种用的不多
异步IO(asynchronous IO)
具体的介绍看这篇文章:[五种io模式的介绍](http://cmsblogs.com/?p=4812)

这里要声明，io操作可以简单的分为三类：
1. 内存io，直接对byte[]数组进行操作，效率非常高，也不存在什么阻塞的问题
2. 文件io，FileInputStream,RamdomAccessFile这些东西，**这个跟上面5种model没有太大关系**，并且只能运行在阻塞模式。java的FileChannel只能是阻塞式的。
3. socket io ,比如说ServerSocket，DatagramSocket这种，这也是Java NIO 的主要研究对象，有阻塞模式、非阻塞模式，默认为阻塞模式。

对于Socket的读(recv)和写(send)操作来说,主要有两个阶段，以recv()为例：
(1) 等待数据准备，通常涉及等待网络上的数据分组到达，然后被复制到内核的某个缓冲区(tcp buffer之类的)
(2) 将数据从内核空间来拷贝到进程空间，将接收到的数据从内核缓冲区复制到应用进程的缓冲区（调用者提供的字节数组）
分别对上面四种（信号驱动式IO用的不多，不介绍了）

- 对于**同步阻塞IO**来说，这两个阶段都是阻塞的
- 对于**同步非阻塞IO**来说，当socket接收缓冲区没有数据时，recv会立刻返回一个特定的状态值，表示现在没有数据，待会再来吧。当socket接收缓冲区有数据的时候，recv将数据拷贝到进程空间的这个过程，也是阻塞的。通常采用轮训polling的方式，循环往复的主动询问内核有没有数据可以读取。实际上，这样的轮询其实还不阻塞IO的性能好。只有第一步是非阻塞的，第二步还是阻塞的
- 对于**多路复用IO**来说，它的优势是可以调用select、poll、epoll这些操作系统级别的系统调用，同时轮训多个socket连接。当调用select、poll、epoll的时候，如果所监控的socket中有部分socket可读，可写或者连接上的时候，就会返回，将其返回给用户进程来处理，这个过程是阻塞的。只不过是因为select、poll、epoll系统调用而阻塞的；
当系统调用返回后，用户进程再调用recv，将数据从内核拷贝到进程空间中，这个过程也是阻塞的。事实上这个方式比第二种还差些，因为这里包含了两个系统调用(select/poll/epoll、recv)，而第二种只有一个系统调用recv。但是这种方式的优势是可以处理更多的连接。连接数大的时候，缺点就被优点给掩盖了。
IO多路复用相比多进程/多线程+ 阻塞IO的系统开销小，因为系统不需要创建新的进程或者线程，也不需要维护多个进程，线程的执行。对于多路复用IO来说，第一个阶段是因为select、poll、epoll而阻塞的，第二个阶段(recv)依旧是阻塞的。
- 对于**异步IO**来说，两个阶段都没有被阻塞，因为只需要发起rec、send请求，系统会帮忙完成数据的copy，完事之后通知用户进程一声。

异步操作(asynchronous IO)的本质
所有的程序最终都会由计算机硬件来执行，所以为了更好的理解异步操作的本质，我们有必要了解一下它的硬件基础。
熟悉电脑硬件的朋友肯定对 DMA 这个词不陌生，硬盘、光驱的技术规格中都有明确 DMA 的模式指标，其实网卡、声卡、显卡也是有 DMA 功能的。
DMA 就是直接内存访问的意思，也就是说，拥有 DMA 功能的硬件在和内存进行数据交换的时候可以不消耗 CPU 资源。只要 CPU 在发起数据传输时发送一个指令，硬件就开始自己和内存交换数据，在传输完成之后硬件会触发一个中断来通知操作完成。
这些无须消耗 CPU 时间的 I/O 操作正是异步操作的硬件基础。所以即使在 DOS 这样的单进程（而且无线程概念）系统中也同样可以发起异步的 DMA 操作。

线程的本质
线程不是一个计算机硬件的功能，而是操作系统提供的一种逻辑功能，线程本质上是进程中一段并发运行的代码，所以线程需要操作系统投入 CPU 资源来运行和调度。
linux下有一条命令可以查看当前进程下有多少个线程：
ps –o nlwp pid ## nlwp含义是number of light-weight process。
ps -eLo pid ,stat | grep pid | grep running | wc -l

nio中的几个主要概念
**channel** 和jdk1.4之前的bio的"将io抽象为流"的概念是差不多的，只不过流是单向的，channel是双向的
**Buffer** 就是对数组的封装
**Selector** 对select、poll、epoll系统调用的包装，用于Socket channel，因为它要求channel必须是非阻塞的

bio是没有缓冲区的（BufferedInputStream,BufferedReader这种除外），包括RandomAccessFile也没有缓冲区
Nio都是有缓冲区的，必须和Buffer对象一起使用，Buffer对象就是缓冲区。

ByteBuffer是唯一直接与channel交互的缓冲，因为所有的数据都是以二进制形式存在的
在 BIO 中，与文件 IO 相关联的三个类是：
1) java.io.FileInputStream，从文件流中读取字节数据，只读；
2) java.io.FileOutputStream，向文件流中写入字节数据，只写；
3) java.io.RandomAccessFile，独立的IO流类，支持r只读、rw读写、rws读写 + metadata/data自动同步、rwd读写 + data自动同步四种模式；

为了迎合 NIO，这几个类都进行修改，加入了getChannel()方法，获取对应的FileChannel对象，提供高效率的 I/O 操作；
但是 NIO 并未给 FileChannel 提供非阻塞支持，FileChannel 只能运行在阻塞模式下，但是效率依旧比 BIO 高，因为有 Buffer 啊；

而java.net包中的三个 Socket 类：
1) java.net.ServerSocket：TCP Socket，Server端；
2) java.net.Socket：TCP Socket；
3) java.net.DatagramSocket：UDP Socket；

这几个类其实也定义了一个getChannel()方法，但是默认只能返回null，需要显式的 open() 对应的 SocketChannel 通道。

Channel通道,java.nio.channels包，主要有：FileChannel、ServerSocketChannel、SocketChannel、DatagramChannel

### FileChannel
```java
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.RandomAccessFile;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;

public class FileChannelDemo {
    public static void main(String[] args) throws IOException {
        FileChannel fc = null;

        fc = new FileOutputStream("data.txt").getChannel();
        fc.write(ByteBuffer.wrap("www.baidu.com\n".getBytes()));
        fc.close();

        fc = new RandomAccessFile("data.txt", "rw").getChannel();
        fc.position(fc.size());
        fc.write(ByteBuffer.wrap("www.google.com\n".getBytes()));
        fc.close();

        fc = new FileInputStream("data.txt").getChannel();
        ByteBuffer buf = ByteBuffer.allocate(1024 * 4);
        fc.read(buf);
        buf.flip();
        while (buf.hasRemaining()) {
            System.out.print((char)buf.get());
        }
        // or
        System.out.println();
        buf.rewind();
        System.out.print(new String(buf.array(), 0, buf.remaining()));
        fc.close();
    }
}
```
或者
```java
import java.nio.channels.FileChannel;
import java.nio.ByteBuffer;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.io.IOException;

public class FileChannelOpen {
    private static Path path = Paths.get("test.txt");
    private static final int BUF_SIZE = 1024 * 4;

    public static void main(String[] args)
        throws IOException
    {
        FileChannel fc = FileChannel.open(path, // 文件路径
                                          StandardOpenOption.READ, // r
                                          StandardOpenOption.WRITE, // w
                                          StandardOpenOption.CREATE, // 不存在时新建
                                          StandardOpenOption.TRUNCATE_EXISTING); // 清空原有内容
        ByteBuffer buf = ByteBuffer.allocate(BUF_SIZE);
        buf.put(args.length == 0 ?
                "default-file-content\n".getBytes() :
                args[0].getBytes());

        fc.write((ByteBuffer)buf.flip());
        fc.position(0).read((ByteBuffer)buf.clear());
        System.out.print(new String(buf.array(), 0, buf.flip().remaining()));

        fc.close();
    }
}
```

transferTo，最快速的文件复制的方法
```
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.channels.FileChannel;

public class FileCopy2 {
    public static void main(String[] args) throws IOException {
        if (args.length < 2) {
            System.err.println("Usage: FileCopy2 <src_file> <dst_file>");
            System.exit(1);
        }

        FileChannel
            in = new FileInputStream(args[0]).getChannel(),
            out = new FileOutputStream(args[1]).getChannel();

        in.transferTo(0, in.size(), out);
        // or:
        // out.transferFrom(in, 0, in.size());

        in.close();
        out.close();
    }
}
```

接下来介绍，SelectableChannel，主要包括ServerSocketChannel，SocketChannel以及DatagramChannel
 
### SocketChannel和 ServerSocketChannel 
```java
import java.nio.ByteBuffer;
import java.nio.charset.Charset;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.net.StandardSocketOptions;
import java.net.InetSocketAddress;
import java.io.IOException;

public class Server {
    private static ServerSocketChannel servChannel;

    private static final InetSocketAddress BIND_ADDR = new InetSocketAddress("0.0.0.0", 8080);
    private static final int BACKLOG = 128;
    private static final int BUF_SIZE = 1024;

    public static void main(String[] args) throws IOException {
        // 注册 shutdown hook 钩子, 关闭 servChannel
        Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    servChannel.close();
                } catch (IOException e) {}
            }
        }));

        servChannel = ServerSocketChannel.open();
        servChannel.setOption(StandardSocketOptions.SO_REUSEADDR, true);
        servChannel.bind(BIND_ADDR, BACKLOG);

        System.out.printf("----- listen: %s:%d -----\n",
                          BIND_ADDR.getAddress().getHostAddress(),
                          BIND_ADDR.getPort());

        SocketChannel connChannel = null;
        while (true) {
            connChannel = servChannel.accept();
            service(connChannel);
        }
    }

    private static void service(SocketChannel connChannel) throws IOException {
        InetSocketAddress remoteAddr = (InetSocketAddress) connChannel.getRemoteAddress();
        System.out.printf("new Connect: %s:%d\n",
                          remoteAddr.getAddress().getHostAddress(),
                          remoteAddr.getPort());

        ByteBuffer buf = ByteBuffer.allocate(BUF_SIZE);
        while (connChannel.read((ByteBuffer)buf.clear()) != -1) {
            System.out.printf("msg: %s\n", Charset.forName("UTF-8").decode((ByteBuffer)buf.flip()));
            connChannel.write((ByteBuffer)buf.rewind());
        }
        System.out.printf("close Connect: %s:%d\n",
                          remoteAddr.getAddress().getHostAddress(),
                          remoteAddr.getPort());
        connChannel.close();
    }
}



public class Client2 {
    private static final InetSocketAddress SERV_ADDR = new InetSocketAddress("127.0.0.1", 8081);
    private static final int BUF_SIZE = 1024;

    public static void main(String[] args) throws IOException {
        SocketChannel sockChannel = SocketChannel.open();
        sockChannel.setOption(StandardSocketOptions.SO_REUSEADDR, true);
        sockChannel.connect(SERV_ADDR);

        ByteBuffer buf = ByteBuffer.allocate(BUF_SIZE);
        if (args.length == 0) {
            buf.put("default-message".getBytes("UTF-8"));
            sockChannel.write((ByteBuffer)buf.flip());
            sockChannel.read((ByteBuffer)buf.clear());
            System.out.printf("msg: %s\n", Charset.forName("UTF-8").decode((ByteBuffer)buf.flip()));
        }
        for (String s : args) {
            ((ByteBuffer)buf.clear()).put(s.getBytes("UTF-8"));
            sockChannel.write((ByteBuffer)buf.flip());
            sockChannel.read((ByteBuffer)buf.clear());
            System.out.printf("msg: %s\n", Charset.forName("UTF-8").decode((ByteBuffer)buf.flip()));
        }
        sockChannel.close();
    }
}
```


### DatagramChannel
这个主要是udp了


## 最后
不要迷信nio：
1. DirectByteBuffer的本意并不是为了减少内存拷贝(而是为了固定内存地址)，DirectByteBuffer的回收机制比较重要，因为万一发生堆外内存泄露是比较严重的。
2. 不要动不动就mmap，mmap在读写大文件的时候才体现出明显的优势
3. 使用transferTo和transferFrom（会按照sendfile,mmap,bio的顺序查看当前系统支持哪个）
4. nio是直接和byte打交道，java的内码是utf-16BE（为毛c语言只要1个byte，java一个char却要2个byte,因为方便啊，虽然浪费点内存，但是所有的字符，不管是英文，拉丁文，中文，阿拉伯文，2个字节，2^16,unicode也没有这么多吧。相应的,1个字符的c语言的char就不能那么方便的存储中文了。）
5. java的很多api是直接对c语言的api的包装，java.io.RandomAccessFile，独立的IO流类，支持r只读、rw读写、rws读写 + metadata/data自动同步、rwd读写 + data自动同步四种模式。猜测和fsync和fsyncdata有关。
6. ByteOrder，字节序。


## 参考
[美团团队出的关于nio的解说](https://zhuanlan.zhihu.com/p/23488863) 
[java nio](https://www.zfl9.com/java-nio.html#more) 作者的文章条理很清晰。
这里面有一句原话摘抄下来：
> 线程的创建和销毁成本很高，在Linux这样的操作系统中，线程本质上就是一个进程。创建和销毁都是重量级的系统函数。像Java的线程栈，一般至少分配512K～1M的空间，