---
title: 网络通信手册-2
date: 2018-04-26 13:00:02
tags: [tools]
---

OkHttp通过ConnectionPool做到tcp连接复用（在Timeout内）,所以并不是每个http都去建立一个tcp连接
自定义通讯协议，使用java socket实现客户端和服务端。需要注意的是分包问题和黏包问题
![](http://odzl05jxx.bkt.clouddn.com/image/jpglight-and-shadow-2411321_960_720.jpg?imageView2/2/w/600)
<!--more-->

## 1. http请求中tcp连接的复用(深入okHttp 3.9.1的connectionPool以及引用计数)
在高并发的请求连接情况下或者同个客户端多次频繁的请求操作，无限制的创建连接会导致性能低下。所以OkHttp做到了对socket的复用和及时清理。
从第四个intercepter开始
ConnectInterceptor.java
```java
public final class ConnectInterceptor implements Interceptor{

  @Override public Response intercept(Chain chain) throws IOException {
  RealInterceptorChain realChain = (RealInterceptorChain) chain;
  Request request = realChain.request();
  // 第一步，获取streamAllocation
  StreamAllocation streamAllocation = realChain.streamAllocation();

  // We need the network to satisfy this request. Possibly for validating a conditional GET.
  boolean doExtensiveHealthChecks = !request.method().equals("GET");
  // 第二步，使用streamAllocation创建(或者复用)一个httpCodec模型（即处理header和body的读写策略，具体实现包括Http1Codec和Http2Codec）
  HttpCodec httpCodec = streamAllocation.newStream(client, chain, doExtensiveHealthChecks);
  // 第三部，挑选出RealConnection,streamAllocation对象中的mConnection变量是在第二步里面赋值的
  RealConnection connection = streamAllocation.connection();

  return realChain.proceed(request, streamAllocation, httpCodec, connection);
  }
}
```

所以socket连接复用就在这句话里面了
> HttpCodec httpCodec = streamAllocation.newStream(client, chain, doExtensiveHealthChecks);

StreamAllocation.java
```java
public HttpCodec newStream(
    OkHttpClient client, Interceptor.Chain chain, boolean doExtensiveHealthChecks) {

      // 省略部分，主要是这两句话
      RealConnection resultConnection = findHealthyConnection(connectTimeout, readTimeout,
               writeTimeout, connectionRetryEnabled, doExtensiveHealthChecks);
      //
      HttpCodec resultCodec = resultConnection.newCodec(client, chain, this);
    }
```

findHealthyConnection最终走到这里
```java
// Attempt to get a connection from the pool.
for (RealConnection connection : connections) {
    if (connection.isEligible(address, route)) {
      streamAllocation.acquire(connection, true);
      return connection;
    }
  }

// 判断是否isEligible的方法在RealConnection里面

// If the non-host fields of the address don't overlap, we're done.
 if (!Internal.instance.equalsNonHost(this.route.address(), address)) return false;
// 只要DNS,port,protocols等host无关的参数中有一个不同就不能复用

 // If the host exactly matches, we're done: this connection can carry the address.
 if (address.url().host().equals(this.route().address().url().host())) {
   return true; // This connection is a perfect match.
 }
 // 这里说明host是相同的，上面的DNS什么的都是一样的，只有后面的path,query或者RequestBody不同，那么直接复用
```

所以这里socket复用的方式是直接使用RealConnection持有Socket对象的引用，每一次在RealConnection的connect成功后，都会讲这个socket包装成一个BufferedSource(读取Response)和BufferedSink(往外写Request)，在timeout时长内，socket不会被关闭。既然缓存就一定会有清理

在上面的findHealthyConnection中有一段
> streamAllocation.acquire(connection, true);

这里面的作用就是将这条请求（Stream）添加到当前连接承载的一个List<Reference<StreamAllocation>>中，也就是所谓的引用计数。提到这一点是要谈到清理的实现：
ConnectionPool中有一个Executor，目的就是执行一个cleanupRunnable的Runnable，这里面的清理操作大致如下：
```java
long cleanup(long now) {
   // Find either a connection to evict, or the time that the next eviction is due.
   synchronized (this) {
     for (Iterator<RealConnection> i = connections.iterator(); i.hasNext(); ) {
       RealConnection connection = i.next();

       // If the connection is in use, keep searching.
       if (pruneAndGetAllocationCount(connection, now) > 0) {
         inUseConnectionCount++; //这条连接还在用
         continue;
       }

       idleConnectionCount++; //这条连接现在空闲下来了

       // If the connection is ready to be evicted, we're done.
       long idleDurationNs = now - connection.idleAtNanos;// 这条连接已经多久没用到了，假如超过了闲置时间(默认5纳秒)，就准备干掉这个socket
       if (idleDurationNs > longestIdleDurationNs) {
         longestIdleDurationNs = idleDurationNs;
         longestIdleConnection = connection;
       }
     }
       // We've found a connection to evict. Remove it from the list, then close it below (outside
       // of the synchronized block).

       // A connection will be ready to evict soon.

       // All connections are in use. It'll be at least the keep alive duration 'til we run again.

       // No connections, idle or in use.
   }
  // 在这前面如果找不到一条该被干掉的连接，直接return
   closeQuietly(longestIdleConnection.socket());// 这里面就是socket.close了

   // Cleanup again immediately.
   return 0;
 }
```

观察一下ConnectionPool的构造函数
```java
/**
  * Create a new connection pool with tuning parameters appropriate for a single-user application.
  * The tuning parameters in this pool are subject to change in future OkHttp releases. Currently
  * this pool holds up to 5 idle connections which will be evicted after 5 minutes of inactivity.
  */
  // 最多保留5条闲置RealConnection(也就是底层5个Socket),每个连接(Socket)如果超过5分钟没有接客，直接干掉
 public ConnectionPool() {
   this(5, 5, TimeUnit.MINUTES);
 }
```
所以，在创建Client的时候，可以把socket的缓存数量写大一点，也可以自定义一个ConnectionPool，只要实现了put,get,remove等标准的CRD操作就行了。简单来说就是自己设计一个Cache，我觉得可以根据实际的endpoint数量来设定缓存的socket的数量。


## 2. 自定义通讯协议
http这种属于应用层的协议定义了每个数据包的结构是怎样的。在一些场合下，比如追求通讯速度，自定义加密手段，可能需要自定义结构体。
自己用Socket实现一套server-clinent通讯模型其实不难。
server这边，先确定自己对外公布的ip,port。然后起一个serverSocket，死循环去accept，每次accept到一个就添加到一个列表中，同时用线程池去执行一个死跑从socket中read的runnable。
clent这边，根据server的ip和port去连接上，client主动发消息(byte，int,String类型都行)，server这边读到信息，给出response，clinent再读取server的回话，就跟两个人之间你一句我一句说话一样。整个过程中 **保持了长连接**,只要任何一方没有手动设置socket.setSoTimeout的话，放一晚上都不会断开。

一个重点是双方发送的消息格式，即两个人交流的语言，如果全部是String的话，那就跟http很像了，当然任何数据格式从socket发出去最终都是以byte的形式发出去的(比如string会用utf-8或者gbk编码成byte数组)。
google的protoBuffer最重要的两个方法writeTo(object转成byte数组)和parseFrom(byte数组转成object)。

[基于Java Socket的自定义协议，实现Android与服务器的长连接（二）](https://blog.csdn.net/u010818425/article/details/53448817)，基于这篇文章，可以将数据类型定义为统一的protocol，protocol的要素包括:
>协议版本
数据类型（数据类协议，数据ack类协议，心跳类协议，心跳ack类协议）
数据长度(这很重要)
消息id
扩展字段

协议版本要做到向后兼容，基本上只添加数据实体不删除数据实体就可以了
数据类型必需的三个要素是：
**长度，版本号，数据类型** (比方说0表示业务数据，1表示数据ack,2表示心跳，3表示心跳ack)。
扩展字段类似于extra，可以用json或者别的什么去实现。

## 3. tcp的分包和粘包问题

tcp发包的时候，如果一个包过大，会拆成两个包发(分包)。如果太小，发送方会攒着和下一个包一起发（粘包）。作为接收方并不知道收到的包是一个完整的包还是被拆分的还是由两个包合并而来。

可能发生分包和粘包的原因包括：
1、要发送的数据大于TCP发送缓冲区剩余空间大小，将会发生拆包。

2、待发送数据大于MSS（最大报文长度），TCP在传输前将进行拆包。

3、要发送的数据小于TCP发送缓冲区的大小，TCP将多次写入缓冲区的数据一次发送出去，将会发生粘包。

4、接收数据端的应用层没有及时读取接收缓冲区中的数据，将发生粘包。

我们都知道TCP属于传输层的协议，传输层除了有TCP协议外还有UDP协议。那么UDP是否会发生粘包或拆包的现象呢？答案是不会。UDP是基于报文发送的，从UDP的帧结构可以看出，在UDP首部采用了16bit来指示UDP数据报文的长度，因此在应用层能很好的将不同的数据报文区分开，从而避免粘包和拆包的问题。而TCP是基于字节流的，虽然应用层和TCP传输层之间的数据交互是大小不等的数据块，但是TCP把这些数据块仅仅看成一连串无结构的字节流，没有边界；另外从TCP的帧结构也可以看出，在TCP的首部没有表示数据长度的字段，基于上面两点，在使用TCP传输数据时，才有粘包或者拆包现象发生的可能。


虽然有分包和粘包问题，但是作为传输层的tcp能够保证发送出去的顺序和接收到的顺序是一致的。
那么基本的解决方法也很成熟了：
> 1、发送端给每个数据包添加包首部，首部中应该至少包含数据包的长度，这样接收端在接收到数据后，通过读取包首部的长度字段，便知道每一个数据包的实际长度了。
2、发送端将每个数据包封装为固定长度（不够的可以通过补0填充），这样接收端每次从接收缓冲区中读取固定长度的数据就自然而然的把每个数据包拆分开来。
3、可以在数据包之间设置边界，如添加特殊符号，这样，接收端通过这个边界就可以将不同的数据包拆分开。

另外，http协议是通过添加换行符“ /r/n”这种形式来解决上述问题的
参考[TCP粘包，拆包及解决方法](https://blog.csdn.net/Scythe666/article/details/51996268)
