---
title: git常用操作手册
date: 2016-09-27 17:24:51
categories: [技术]
tags: [git]
---

## 记录一下常用git的命令，作为日常使用的参考手册

### 1. 在本地创建一个项目并同步到github的过程

```java
$ mkdir ~/hello-world    //创建一个项目hello-world
$ cd ~/hello-world       //打开这个项目
$ git init             //初始化 
$ touch README   		//创建文件
$ git add README        //更新README文件
$ git commit -m 'first commit'     //提交更新，并注释信息“first commit”
$ git remote add origin git@github.test/hellotest.git     //连接远程github项目  
$ git push -u origin master     //将本地项目更新到github项目上去
```

### 2.  将本地git branch和远程github repository同步

```python
git branch --set-upstream local_branch origin/remote_branch
```

<!--more-->

### 3. git处理大小写字母的问题

> git默认对大小写不敏感，所以，新建一个文件adapter.java，上传到github之后说不定就给变成了Adapter.java。在windows下面将已经push到远端的文件，改变其文件名的大小写时，git默认会认为文件没有发生任何改动，从而拒绝提交和推送，原因是其默认配置为大小写不敏感，故须在bash下修改配置：

```java
git config core.ignorecase false 
```

### 4. git设置用户名

```java
$ git config --global user.name "name"
$ git config --global user.email xxx@163.com
```
这样可以为git所有的仓库设置用户名，如果想为指定仓库设置用户名:

```java
$ git config user.name "name"
```
查看当前用户名
```
$ git config user.name 
```

### 5. 设置代理

设置全局代理
```java
git config --global http.proxy socks5://127.0.0.1:1080
```

对指定url设置代理
```java
git config --global http.<要设置代理的URL>.proxy socks5://127.0.0.1:1080
 
git config --global http.https://github.com.proxy socks5://127.0.0.1:1080
```

### 6. 对上一次commit进行修改(在不添加新的commit的基础上)
```java
git commit --amend
```

### 7. git revert和reset的区别

### 8. 切分支, 删除分支

### 9. pull

### 10. rebase和cherry-pick