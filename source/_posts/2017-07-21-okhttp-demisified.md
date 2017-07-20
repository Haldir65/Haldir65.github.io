---
title: 2017-07-21-okhttp-demisified
date: 2017-07-21 00:02:56
tags:
---

很早的时候就知道，OkHttp在io层面上的操作是由Okio代为完成的，所以实际意义上和Socket打交道的应该是Okio。而Okio身又比传统的java io要高效。所以，在分析OkHttp之前，有必要针对Okio的一些方法进行展开，作为后面读写操作的铺垫。

Okio -> OkHttp -> Picaso  -> Retrofit 

![](http://odzl05jxx.bkt.clouddn.com/6da83b3b20094b044a320d1e89dfcd00.jpg?imageView2/2/w/600)
<!--more-->
