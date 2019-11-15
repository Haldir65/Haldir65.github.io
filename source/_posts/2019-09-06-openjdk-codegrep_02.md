---
title: openjdk源码解析[二]
date: 2019-09-06 21:06:23
tags: [java]
---

涉及socket的一些class,java.net.xxx
![](https://www.haldir66.ga/static/imgs/may1_ZH-CN8582006115_1920x1080.jpg)

<!--more-->

java socket编程主要是tcp和udp编程，涉及到的class包括socket(tcp client)和ServerSocket(tcp server)以及DatagramSocket(udp)，主要的类都在java.net这个package下面。
常用的包括：处理http请求的HttpURLConnection，代表资源地址的URL(不是URI)，SocketInputStream和SocketOutputStream。


## URL是对一份资源地址的表示

```java
public class URLDemo {
    public static void main(String[] args) {
        try {
            URL url = new URL("https://www.baidu.com/abced.html?language=zh_CN#ssss-libev");
            System.out.println(url);
            System.out.println(url.getProtocol()); // https
            System.out.println(url.getHost()); // www.zfl9.com
            System.out.println(url.getPort()); // -1
            System.out.println(url.getDefaultPort()); // 443
            System.out.println(url.getFile()); // /abced.html?language=zh_CN
            System.out.println(url.getPath()); // /abced.html
            System.out.println(url.getQuery()); // language=zh_CN
            System.out.println(url.getRef()); // ssss-libev
        } catch (MalformedURLException e) {
            e.printStackTrace();
        }
    }
}
```


## tcp socket
Socket和ServerSocket，这俩一个代表tcp通信的客户端，一个代表服务端。从源码来看,ServerSocket和socket内部分别持有一个SocketImpl对象，用于将对应的方法代理给native方法。

### ServerSocket
主要的方法包括
```java
//几个构造函数
public ServerSocket() throws IOException;
public ServerSocket(int port) throws IOException;
public ServerSocket(int port, int backlog, InetAddress bindAddr) throws IOException ;


//绑定端口
public void bind(SocketAddress endpoint) throws IOException
public void bind(SocketAddress endpoint, int backlog) throws IOException


//开始接受client的请求
public Socket accept() throws IOException 

//还有一些设置超时什么的
public synchronized void setSoTimeout(int timeout) throws SocketException
public void setReuseAddress(boolean on) throws SocketException 
public synchronized void setReceiveBufferSize (int size) throws SocketException
```

分别来看：
构造函数中默认创建了一个SocksSocketImpl（这是一个SOCKS (V4 & V5) TCP socket implementation，就是一个支持socks协议的socket实现）。
SocksSocketImpl继承自PlainSocketImpl继承自AbstractPlainSocketImpl。
注意这些父类中都有一段static 代码块，所以创建了子类的时候这些父类的代码块都会被执行：
```java
class PlainSocketImpl extends AbstractPlainSocketImpl
{
    static {
        initProto();
    }

    static native void initProto();

}

abstract class AbstractPlainSocketImpl extends SocketImpl
{
    static {
        java.security.AccessController.doPrivileged(
            new java.security.PrivilegedAction<Void>() {
                public Void run() {
                    System.loadLibrary("net"); 
                    return null;
                }
            });
    }
}
```

[initProto主要是为了cache filed id](https://github.com/AdoptOpenJDK/openjdk-jdk8u/blob/master/jdk/src/solaris/native/java/net/PlainSocketImpl.c)


接下来是bind方法,serverSocket中的实现是
```java
getImpl().bind(epoint.getAddress(), epoint.getPort());
getImpl().listen(backlog); //这个backlog默认是50
```
所以是同时做了两件事，bind和listen。分别调用到了:
```java
native void socketBind(InetAddress address, int port)
    throws IOException;
native void socketListen(int count) throws IOException;
```
对应的c语言实现是:
[socketListen](https://github.com/AdoptOpenJDK/openjdk-jdk8u/blob/master/jdk/src/solaris/native/java/net/PlainSocketImpl.c#L618)
```c
JNIEXPORT void JNICALL
Java_java_net_PlainSocketImpl_socketListen (JNIEnv *env, jobject this,
                                            jint count)
{
    /* this FileDescriptor fd field */
    jobject fdObj = (*env)->GetObjectField(env, this, psi_fdID);
    /* fdObj's int fd field */
    int fd;

    if (IS_NULL(fdObj)) {
        JNU_ThrowByName(env, JNU_JAVANETPKG "SocketException",
                        "Socket closed");
        return;
    } else {
        fd = (*env)->GetIntField(env, fdObj, IO_fd_fdID);
    }

    /*
     * Workaround for bugid 4101691 in Solaris 2.6. See 4106600.
     * If listen backlog is Integer.MAX_VALUE then subtract 1.
     */
    if (count == 0x7fffffff)
        count -= 1;

    if (JVM_Listen(fd, count) == JVM_IO_ERR) {
        NET_ThrowByNameWithLastError(env, JNU_JAVANETPKG "SocketException",
                       "Listen failed");
    }
}
```
所以是调用了JVM_Listen这个方法,再往下就是cpp了，在/hotspot/src/share/vm/prims/jvm.cpp这个文件中，调用的是os:listen函数，这里应该是虚拟机的实现了。
不出意外的，JVM_Bind这个方法也出现在jvm.cpp这个方法中。
> 在hostspot中，os是一个封装特定操作系统行为的静态类，其实现多在hotspot/src/os中。

以linux为例，实现在[os_linux.inline.hpp](https://github.com/AdoptOpenJDK/openjdk-jdk8u/blob/master/hotspot/src/os/linux/vm/os_linux.inline.hpp)

```c++
inline int os::bind(int fd, struct sockaddr* him, socklen_t len) {
  return ::bind(fd, him, len);
}
```
应该是调用了[bind](https://linux.die.net/man/2/bind)这个linux函数。

### udp socket
tbd, 实在太多了


### socketXXXStream
大部分的native方法都在plainSocketImpl.java中
```java
native void socketCreate(boolean isServer) throws IOException;

native void socketConnect(InetAddress address, int port, int timeout)
    throws IOException;

native void socketBind(InetAddress address, int port)
    throws IOException;

native void socketListen(int count) throws IOException;

native void socketAccept(SocketImpl s) throws IOException;

native int socketAvailable() throws IOException; 

native void socketClose0(boolean useDeferredClose) throws IOException;

native void socketShutdown(int howto) throws IOException;

static native void initProto();

native void socketSetOption0(int cmd, boolean on, Object value)
    throws SocketException;

native int socketGetOption(int opt, Object iaContainerObj) throws SocketException;

native void socketSendUrgentData(int data) throws IOException;
```
上面的方法基本上看名字就能跟对应的java方法对上号，这里说一个socketAvailable,这个应该是对应socketInputStream的available(这个方法是inputStream要求的)。
那么它的对应的c++方法是JVM_SocketAvailable
```c++
int os::socket_available(int fd, jint *pbytes) {
  // Linux doc says EINTR not returned, unlike Solaris
  int ret = ::ioctl(fd, FIONREAD, pbytes);

  //%% note ioctl can return 0 when successful, JVM_SocketAvailable
  // is expected to return 0 on failure and 1 on success to the jdk.
  return (ret < 0) ? 0 : 1;
}
```
所以这个方法返回的要么是0要么是1？
看一下oracle的[java doc](https://docs.oracle.com/javase/9/docs/api/java/io/InputStream.html#available)

```
public int available​()
              throws IOException
Returns an estimate of the number of bytes that can be read (or skipped over) from this input stream without blocking by the next invocation of a method for this input stream. The next invocation might be the same thread or another thread. A single read or skip of this many bytes will not block, but may read or skip fewer bytes.
Note that while some implementations of InputStream will return the total number of bytes in the stream, many will not. It is never correct to use the return value of this method to allocate a buffer intended to hold all data in this stream.

A subclass' implementation of this method may choose to throw an IOException if this input stream has been closed by invoking the close() method.

The available method for class InputStream always returns 0.

This method should be overridden by subclasses.
```
也就是说多数subclass的实现中返回的值，是靠不住的，可能会小。所以依赖这个返回值allocate一个buffer区存储底层的数据是不正确的。



### tbd
这么写下去，虚拟机的东西太多了。。。

## 参考
[java socket编程](https://www.zfl9.com/java-socket.html)
