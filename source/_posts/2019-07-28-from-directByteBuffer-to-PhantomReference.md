---
title: 堆外内存，weakHashMap以及四种引用类型的研究
date: 2019-07-28 22:34:37
tags: [java,tbd]
---

DiectByteBuffer（堆外内存）是分配在jvm以外的内存，这个java对象本身是受jvm gc控制的，但是其指向的堆外内存是如何回收的
![](https://www.haldir66.ga/static/imgs/JovianCloudscape_EN-AU11726040455_1920x1080.jpg)
<!--more-->





## weapHashMap 有一个ReferenceQueue的使用