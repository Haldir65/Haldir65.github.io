---
title: 使用Loader进行数据操作
date: 2016-10-15 19:12:22
tags:
---
App中经常有这样的需求:
进入一个页面，首先查询数据库，如果数据库数据有效，直接使用数据库数据。否则去网络查询数据，网络数据返回后重新加载数据。
很显然，这里的查询数据库和网络请求都需要放到子线程去操作，异步了。android推荐使用Loader进行数据查询，最大的好处就是Laoder会处理好与生命周期相关的事情，这一点对于避免Leak十分重要。
学过rxjava，是否rxjava会是一种比loader更好的加载数据的方式呢<!--more-->



### Reference

1. [rxLoader](http://huxian99.github.io/2015/10/28/RxJava%E7%9A%84Android%E5%BC%80%E5%8F%91%E4%B9%8B%E8%B7%AF-RxJava%E5%AE%9E%E6%88%98-%E4%BA%8C/)
2. [making loading data on android lifecycle aware](https://medium.com/google-developers/making-loading-data-on-android-lifecycle-aware-897e12760832#.btjs9ady6)