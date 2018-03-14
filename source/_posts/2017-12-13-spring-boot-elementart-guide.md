---
title: Spring Boot入门记录
date: 2017-12-13 23:19:33
tags: [tools]
---


关于Spring Boot的基本知识要点
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/scenery1511100670897.jpg?imageView2/2/w/600)
<!--more-->


## 1. 创建一个Spring Boot app 非常简单
[Creating a Spring Application in Intelij is darn Simple](https://medium.com/@ahmetkapusuz/spring-boot-hello-world-application-with-intellij-idea-1524c68ddaae)


## 2. 组件及用法

### 2.1 Service
### 2.2 Dao
### 2.3 Entity
### 2.4 Controller

## 3. 一些配置
Spring Boot修改内置Tomcat端口号：
EmbeddedServletContainerCustomizer

>或者在
src/main/resources/application.yml文件中添加
server
  port: 8081

=================================================================
在windows里面查看内网ip，从控制面板进去看是不准的，DHCP有效期过了自动换掉，得自己敲ipconfig，这样才是最及时的。

以Okio为例，maven的搜索网站是<p>https://search.maven.org/remote_content?g=com.squareup.okio&a=okio&v=LATEST</p>，实际下发的域名是<p>https://repo1.maven.org/maven2/com/squareup/okio/okio/1.14.0/okio-1.14.0.jar</p>。用wget看，是302重定向了。

[2小时学会SpringBoot](https://www.youtube.com/playlist?list=PLO5e_-yXpYLDcuEz8BlB_J_hQpzI-ZM4Y)
[accessing-data-mysql](https://spring.io/guides/gs/accessing-data-mysql/)
