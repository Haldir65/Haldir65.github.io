---
title: Tomcat部分源码解析
date: 2019-07-28 21:50:29
tags: [java,tbd]
---

Tomcat源码解析

![](https://www.haldir66.ga/static/imgs/LetchworthSP_EN-AU14482052774_1920x1080.jpg)
<!--more-->

tomcat的使用很简单，windows下双击那个startup.bat或者cd 到bin目录，运行catlina run就可以了。配置的话，用xml文件就可以了，静态文件放在webapp/目录下。。


从Spring-boot支持的embedded servlet container就能看出来，tomcat的替代品有不少
spring-boot-starter-undertow,
spring-boot-starter-jetty,
spring-boot-starter-tomcat 


[apache支持zero-copy](https://httpd.apache.org/docs/2.4/mod/core.html#enablesendfile)

## 参考
[tomcat源码解析](https://blog.csdn.net/Dwade_mia/column/info/18882)
