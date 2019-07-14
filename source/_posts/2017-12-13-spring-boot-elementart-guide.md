---
title: Spring Boot入门记录
date: 2017-12-13 23:19:33
tags: [tools]
---


关于Spring Boot的基本知识要点
![](https://www.haldir66.ga/static/imgs/scenery1511100670897.jpg)
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

或者在src/main/resources/application.yml文件中添加
```yml
server
  port: 8081
```
=================================================================
在windows里面查看内网ip，从控制面板进去看是不准的，DHCP有效期过了自动换掉，得自己敲ipconfig，这样才是最及时的。

以Okio为例，maven的搜索网站是<p>https://search.maven.org/remote_content?g=com.squareup.okio&a=okio&v=LATEST</p>，实际下发的域名是<p>https://repo1.maven.org/maven2/com/squareup/okio/okio/1.14.0/okio-1.14.0.jar</p>。用wget看，是302重定向了。



## Tomcat教程
[Create a Maven Project with Servlet in IntelliJ IDEA](https://medium.com/@backslash112/create-maven-project-with-servlet-in-intellij-idea-2018-be0d673bd9af) 需要使用intelij idea ultimate version，过程中可能需要联网，会比较慢。

Tomcat可以host static file，做法是在webapp文件夹下创建一个MyApp（名字其实随意）文件夹，在这个文件夹里新建一个index.html（文件也随意）,接下来访问localhost:8080/MyApp/index.html 就能看到内容了

补充一些tomcat和servlet的知识
tomcat是web container,servlet是处理业务逻辑的。
servlet继承自HttpServlet,里面有doGet和doPost方法。
servlet和请求的url的对应关系写在web.xml中。

[下面是从一片关于如何使用命令行生成并运行jar的文章中摘抄的](https://medium.com/nycdev/java-get-started-with-apache-maven-a71f4f907cb3)
```
|____src
| |____main
| | |____java
| | | |____com
| | | | |____remkohde
| | |____resources
| |____test
|____target
```
> Above you created the recommended directory structure for a Java application. Java source files are saved in the ‘./src/main/java’ folder, the folder ‘./src/main/resources’ is added to the class-path to include resources like properties files to your Java application, test files are saved in ‘./src/test’, compiled class files are saved to ‘./target/classes’, and jar archives are saved to the ‘./target’ folder.

如上就是一般推荐的java application的目录结构。
./src/main/java’ folder放的是java代码，
‘./src/main/resources’是用来存放属性之类的文件的（被添加到classpath），
test文件存放在‘./src/test’文件夹中，生成的class文件放在‘./target/classes’文件夹中，
‘./target’文件夹中放的是jar文件

[论如何正确地关闭springboot应用](https://stackoverflow.com/questions/26547532/how-to-shutdown-a-spring-boot-application-in-a-correct-way?noredirect=1&lq=1)
**start.sh**
```bash
#!/bin/bash
java -jar myapp.jar & echo $! > ./pid.file &
```
**stop.sh**
```bash
#!/bin/bash
kill $(cat ./pid.file)
```
**start_silent.sh**
```bash
#!/bin/bash
nohup ./start.sh > foo.out 2> foo.err < /dev/null &
```

非嵌入式产品的Web应用，应使用预编译语句PreparedStatement代替直接的语句执行Statement，以防止SQL注入。

[oracle文档中指出manifest文件最后一行要加上一个换行](https://docs.oracle.com/javase/tutorial/deployment/jar/build.html)The manifest must end with a new line or carriage return. The last line will not be parsed properly if it does not end with a new line or carriage return.

[accessing-data-mysql](https://spring.io/guides/gs/accessing-data-mysql/)
[在application.properties文件中可以写的一些配置](https://docs.spring.io/spring-boot/docs/current/reference/html/common-application-properties.html)

[在ubuntu下使用nginx部署Spring boot application](https://www.linode.com/docs/development/java/how-to-deploy-spring-boot-applications-nginx-ubuntu-16-04/)

[example app](https://github.com/gothinkster/spring-boot-realworld-example-app)