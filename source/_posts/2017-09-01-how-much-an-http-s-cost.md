---
title: 一个Http请求耗费多少流量
date: 2017-09-01 06:52:35
tags: [tools]
---

http建立在tcp,ip基础上，tcp协议的可靠性意味着每次http请求都会分解为多次ip请求。很多出于book keeping的东西占用了实际发送数据的相当一部分，具体占用多少。由此顺便展开到http和tcp的基本关系。
![](http://odzl05jxx.bkt.clouddn.com/Cg-4V1Kg7NCIMLH-AAwW6gNGe9cAAOB4AFTanwADBcC664.jpg?imageView2/2/w/600)
<!--more-->

## 1. WireShark+tcpdump抓包

## 2. tcp握手

### 2.x tls 1.3
### 2. xx http2
### 2.xxxx https

## 3. 应用层能做的事情

### 3.1 引申到http2的原理
OkHttp神一样的[注释](https://github.com/square/okhttp/blob/master/okhttp/src/main/java/okhttp3/internal/http2/Http2Reader.java)
一些线上问题[okhttp和http 2.0相遇引发的"血案"](https://zhuanlan.zhihu.com/p/28958516)
http2服务器[搭建](https://www.youtube.com/watch?v=OLWyOIOaeP4&list=PLNYkxOF6rcIDXTg3Gm8Y9Q_D8Ag_RDyQO)
http2解释[原理](https://www.youtube.com/watch?v=r5oT_2ndjms)
tcu、udp[抽象](https://www.youtube.com/watch?v=cTKQAe4DN6g)
[须知](https://www.youtube.com/watch?v=F5smqpbz2sU)

## 3. 结论





### 参考
- [what-of-traffic-is-network-overhead-on-top-of-http-s-requests](https://stackoverflow.com/questions/3613989/what-of-traffic-is-network-overhead-on-top-of-http-s-requests)
