---
title: git常用手册
date: 2016-09-27 17:24:51
categories: [技术]
tags: [git]
---

常用git命令，使用场景

git默认对大小写不敏感，所以，新建一个文件adapter.java，上传到github之后说不定就给变成了Adapter

> 在windows下面将已经push到远端的文件，改变其文件名的大小写时，[Git](http://lib.csdn.net/base/git)默认会认为文件没有发生任何改动，从而拒绝提交和推送，原因是其默认配置为大小写不敏感，故须在bash下修改配置：

```
git config core.ignorecase false 
```

