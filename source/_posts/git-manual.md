---
title: git常用手册
date: 2016-09-27 17:24:51
categories: [技术]
tags: [git]
---

常用git命令，使用场景

1. 在本地创建一个项目并同步到github的过程

```git
$ mkdir ~/hello-world    //创建一个项目hello-world
$ cd ~/hello-world       //打开这个项目
$ git init             //初始化 
$ touch README   		//创建文件
$ git add README        //更新README文件
$ git commit -m 'first commit'     //提交更新，并注释信息“first commit”
$ git remote add origin git@github.test/hellotest.git     //连接远程github项目  
$ git push -u origin master     //将本地项目更新到github项目上去
```

2. 将本地git branch和远程github repository同步

```
git branch --set-upstream local_branch origin/remote_branch
```

<!--more-->

3. git默认对大小写不敏感，所以，新建一个文件adapter.java，上传到github之后说不定就给变成了Adapter.java

> 在windows下面将已经push到远端的文件，改变其文件名的大小写时，Git默认会认为文件没有发生任何改动，从而拒绝提交和推送，原因是其默认配置为大小写不敏感，故须在bash下修改配置：

```
git config core.ignorecase false 
```

