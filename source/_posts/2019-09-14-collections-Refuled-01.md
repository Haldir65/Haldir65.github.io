---
title: jdk集合类源码分析[List]
date: 2019-09-14 15:44:09
tags: [java]
---

源码，以及jdk8中的一些有用的method。

![](https://www.haldir66.ga/static/imgs/SainteVictoireCezanneBirthday_ZH-CN8216109812_1920x1080.jpg)
<!--more-->

```java
public interface List<E> extends Collection<E> {
}
```

List的实现类包括ArrayList,LinkedList,CopyOnWriteArrayList,以及两个不怎么用的类<del>stack和Vector</del>



## 参考
[【死磕 Java 集合】— 总结篇](http://cmsblogs.com/?p=4781)
[Java集合框架常见面试题.md](https://github.com/Snailclimb/JavaGuide/blob/master/docs/java/collection/Java集合框架常见面试题.md）

