---
title: netty知识手册
date: 2018-10-13 21:34:19
tags: [nio,tbd]
---

![](https://api1.foster66.xyz/static/imgs/cute_cat_sleepy.jpg)
<!--more-->

都说netty要比nio好用，先从官方的intro page看起。

ByteBuff是reference counted的，netty的作者说：
java给人一种不需要清理garbage的illusion
allocating stuff is no big deal , garbage collecting it is.


[netty 5要求最低jdk11](https://github.com/netty/netty/issues/8540#issue-380245481) ，所以暂时用netty 4.1来学习还是ok的。

### tcp粘包的处理方式

### zero copy与CompositeBytebuf

### netty处理udp也是可以的

### netty通过jni扩展了一些jdk中不存在的功能用于调用系统方法



[ChannelPipeline](https://netty.io/4.1/api/io/netty/channel/ChannelPipeline.html) 是一连串处理events的handler的集合，通常会有包括decoder(将Bytes转换成java object)，业务逻辑处理， encoder(将java object转成bytes)。如果业务处理耗时比较多的话，可以将业务逻辑代码挪到io线程以外
```java
 static final EventExecutorGroup group = new DefaultEventExecutorGroup(16);
 ...

 ChannelPipeline pipeline = ch.pipeline();

 pipeline.addLast("decoder", new MyProtocolDecoder());
 pipeline.addLast("encoder", new MyProtocolEncoder());

 // Tell the pipeline to run MyBusinessLogicHandler's event handler methods
 // in a different thread than an I/O thread so that the I/O thread is not blocked by
 // a time-consuming task.
 // If your business logic is fully asynchronous or finished very quickly, you don't
 // need to specify a group.
 pipeline.addLast(group, "handler", new MyBusinessLogicHandler()); //这样在businessHandler里面就能处理blocking业务，比如操作sql, 或者。。。调用一个rpc?
```

### @ChannelHandler.Sharable这个注解
每一个Channel都需要创建一个新的businessHandler，因为这里牵涉到了state相关的东西
而有些Decoder和Encoder是不具备state的，这种就被添加了@Sharable的注解。最常用的http相关的decoder和encoder并没有添加这个注解，原因在 io.netty.handler.codec.http.HttpObjectDecoder这个class里面，是有一个currentState的。假如遇到了chunked这种，decoder不可能一次读完，那么每一个http请求(背后的channel，connection)都应该保留一个之前曾经读过的部分。自然这个handler就变成了stateful的了。


netty的作者在演讲中提到java官方的nio并不特别好，所以，生产环境用的都是netty这种。

Vertx，是一个基于JVM、轻量级、高性能的应用平台，非常适用于移动端后台、互联网、企业应用架构。[vertx框架底层基于netty](https://vertx.io/)，也是异步io，selector那一套(vertx基于netty)

[netty的example非常多，http2,cors,upload等等都有](https://netty.io/4.1/xref/overview-summary.html)


[Netty - One Framework to rule them all by Norman Maurer](https://www.youtube.com/watch?v=DKJ0w30M0vg)
[netty best practices with norman maurer](https://www.youtube.com/watch?v=_GRIyCMNGGI)
[netty规避了java nio的一个bug](https://www.zhihu.com/question/291370310),关于这个jdk导致cpu100%的bug的讨论很多
