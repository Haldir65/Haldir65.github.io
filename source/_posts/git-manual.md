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
> reset 是在正常的commit历史中,删除了指定的commit,这时 HEAD 是向后移动了,而 revert 是在正常的commit历史中再commit一次,只不过是反向提交,他的 HEAD 是一直向前的. 即reset是通过一次反向的commit操作撤销之前的commit，而reset则会直接从提交历史里删除commit。如果还没有push，用reset可以在本地解决问题，之后重新commit再push。如果已经push，可以考虑通过一次revert来实现“撤销”的效果。


语法：
#### reset
```java
git reset --hard HEAD //本地仓库文件修改也会消失
git reset --soft HEAD //本地文件修改不会消失，类似于回到git add 之前的状态
git reset --hard HEAD~3 //最近的三次提交全部撤销
```

#### revert
```java
git revert c011eb3c20ba6fb38cc94fe //之后在分支图上就能看到一个新的反向的commit，push即可。
```

### 8. 切分支, 删除分支
本地新建分支
```java
git checkout -b <branchName>
```
将这条分支与远程同步的方式
```java
git branch --set-upstream <laocalBranchName> origin/<RemoteBranchName>
```
直接从远程仓库切一个分支出来并保持同步的方式
```java
git checkout -b <branchName> origin/<branchName>
```

删除远程分支:
```java
git push origin --delete <branchName>
```
删除远程tag
```java
git push origin --delete tag <tagName>
```


### 9. pull

### 10. rebase和cherry-pick


## Reference
-[git reset和revert](http://yijiebuyi.com/blog/8f985d539566d0bf3b804df6be4e0c90.html) 