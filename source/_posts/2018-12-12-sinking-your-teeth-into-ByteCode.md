---
title: bytecode基本解读
date: 2018-12-12 11:11:02
tags: [java,tbd]
---

python中可以使用diss module 轻易的查看byte code。那么在java中呢
![](https://www.haldir66.ga/static/imgs/BadlandsBday_EN-AU10299777329_1920x1080.jpg)
<!--more-->

interpreting the talk from 
[Sinking Your Teeth Into Bytecode](https://jakewharton.com/sinking-your-teeth-into-bytecode/)


java 有一个关键字叫做goto，在java代码中好像不能用，但是其实在生成的bytecode里面有goto关键字(c语言也有)

## 参考
[JVM bytecode engineering 101](https://www.youtube.com/watch?v=lP4ED_dN16g)
