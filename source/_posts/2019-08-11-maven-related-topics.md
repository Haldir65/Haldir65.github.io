---
title:  maven的一些东西
date: 2019-08-11 11:13:17
tags:
---


![](https://api1.foster57.tk/static/imgs/FreshSalt_ZH-CN12818759319_1920x1080.jpg)

maven的一些东西
<!--more-->


maven官网提供的通过命令行创建一个maven项目的方法
```shell
mvn -B archetype:generate -DarchetypeGroupId=org.apache.maven.archetypes -DgroupId=com.mycompany.app -DartifactId=my-app
//上述命令生成的文件夹就足够了，连pom.xml也帮忙生成好了，接下来就是去复制粘贴pom里面的内容
mvn compile ##开始编译

// 或者这两条直接收工
mvn archetype:generate -DgroupId=com.websystique.maven -DartifactId=SampleMavenJavaProject -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false
mvn -q clean compile exec:java  -Dexec.mainClass="com.websystique.maven.App"
```


[maven getting started是很友好的教程](https://maven.apache.org/guides/getting-started/index.html#How_do_I_make_my_first_Maven_project)

看完这俩再不会就是蠢
[jetbrain在youtube上的教程](https://www.youtube.com/watch?v=pt3uB0sd5kY)
[Creating a new Maven project in IntelliJ IDEA](https://www.packtpub.com/mapt/book/application_development/9781785286124/2/ch02lvl1sec24/creating-a-new-maven-project-in-intellij-idea)

create from archetype可以选择org.apache.maven.archetypes:maven-archetype-quickstart(真的只有一个hello world)
[如果是spring的话，直接用这个网站更加方便](https://start.spring.io/)


intelij idea里面默认的maven源有
`https://repo.maven.apache.org/maven2`
和`http://download.java.net/maven/1`
这俩网站国内似乎被墙，最好[加代理](https://stackoverflow.com/questions/1784132/intellij-community-cant-use-http-proxy-for-maven/26483623#26483623) 就是在.m2/settings.xml中指定本地proxy。如果你的代理够快的话，修改pom.xml的同时，应该能够很快的开始下载新的依赖
intelij内置了maven, 由于网速的原因，不想浪费时间的话还是给Maven加代理:
在~/.m2/settings.xml中找到这一段，这一段原本是被注释掉的，端口和host根据代理设置。~/.m2/settings.xml这个文件如果不存在，就去intelij的安装目录里面copy一个出来
比如这样：
```xml
 <proxies>
    <proxy>
      <id>optional</id>
      <active>true</active>
      <protocol>http</protocol>
      <host>127.0.0.1</host>
      <port>1080</port>
      <nonProxyHosts>local.net|some.host.com</nonProxyHosts>
    </proxy>
  </proxies>
```

### 或者直接用阿里云的源

实际操作中，使用阿里云的maven镜像似乎更快
```xml
 <mirrors>
   <mirror>
         <id>alimaven</id>
         <name>aliyun maven</name>
         <url>http://maven.aliyun.com/nexus/content/groups/public/</url>
         <mirrorOf>central</mirrorOf>
   </mirror>
 
 </mirrors>
```

打开项目后，在Intellij 右侧有个Maven projects，点开后，有个Lifecycle，再点开，可以看到clean , validate, compile, ….，右击clean，选中Run ‘project[clean]’，这里的project是我们的项目实际的名字。
如果下载失败了的话，可以选择clean，然后就会开始自己重新下载

GroupId类似于你的包名，ArtifictId类似于你的applicationName

## maven是如何解决版本冲突的(同一个package，不同版本同时存在)
tbd
gradle也有一套解决方案，ivy也有
java 9 的module系统没有

maven 中使用jar包的多个版本容易造成依赖问题，解决问题的方式可以将使用jar包的版本排除掉，比如dubbo使用netty 4.0.33版本可以将dubbo排除掉netty依赖，这样其他jar包就不会引用到netty4.0.33版本了。
```xml
<dependency>
    <groupId>com.jd</groupId>
    <artifactId>jsf</artifactId>
    <version>1.6.0</version>
    <exclusions>
        <exclusion>
            <groupId>io.netty</groupId>
            <artifactId>netty-all</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```


### maven中如何顺带把native的library也给打进去。
可以参考netty-transport-native-unix-common 中的做法，写一个makefile，使用maven插件调用系统的gcc命令，传参。最终打包

## 参考
