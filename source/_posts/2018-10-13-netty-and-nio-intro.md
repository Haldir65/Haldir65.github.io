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


selectors

[netty的example非常多，http2,cors,upload等等都有](https://netty.io/4.1/xref/overview-summary.html)


[Netty - One Framework to rule them all by Norman Maurer](https://www.youtube.com/watch?v=DKJ0w30M0vg)
[netty best practices with norman maurer](https://www.youtube.com/watch?v=_GRIyCMNGGI)