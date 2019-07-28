---
title: netty及nio知识手册
date: 2018-10-13 21:34:19
tags: [nio,tbd]
---

![](https://www.haldir66.ga/static/imgs/cute_cat_sleepy.jpg)
<!--more-->

都说netty要比nio好用，先从官方的intro page看起。

ByteBuff是reference counted的，netty的作者说：
java给人一种不需要清理garbage的illusion
allocating stuff is no big deal , garbage collecting it is.




netty的作者在演讲中提到java官方的nio并不特别好，所以，生产环境用的都是netty这种。

Vertx，是一个基于JVM、轻量级、高性能的应用平台，非常适用于移动端后台、互联网、企业应用架构。[vertx框架底层基于netty](https://vertx.io/)，也是异步io，selector那一套(vertx基于netty)

[netty的example非常多，http2,cors,upload等等都有](https://netty.io/4.1/xref/overview-summary.html)


[Netty - One Framework to rule them all by Norman Maurer](https://www.youtube.com/watch?v=DKJ0w30M0vg)
[netty best practices with norman maurer](https://www.youtube.com/watch?v=_GRIyCMNGGI)