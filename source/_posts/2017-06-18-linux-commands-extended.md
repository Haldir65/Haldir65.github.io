---
title: linux常用命令扩展
date: 2017-06-18 16:51:49
categories: blog
tags: 
  - linux
---
> 一些linux的常用命令，linux环境下运行server ,bash的语法
>  

![](http://odzl05jxx.bkt.clouddn.com/ChMkJ1gq00WIXw_GAA47r_8gjqgAAXxJAH8qOMADjvH566.jpg?imageView2/2/w/600)

<!--more-->

1. 常用软件安装
[utorrent](http://blog.topspeedsnail.com/archives/5752)
apache,mysql

2. 环境变量怎么改
平时在shell中输入sudo XXX ,系统是如何知道怎么执行这条指令的呢。首先，可以查看which XXX ，用于查找某项指令对应的文件的位置。而像sudo这种都放在PATH位置，系统会在几个关键位置查找sudo命令。用户本身完全可以创建一个叫做sudo的文件chmod+X ，然后运行这个sudo。
```
查看PATH : echo $PATH
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games (注意，系统是按照这个顺序找的，如果在第一个目录下找到一个叫sudo的东西，就会直接执行了，所以这里是有潜在的危险的)
看下哪个命令对应的位置在哪里
which XXX
比如sudo 就放在 /usr/bin/sudo
```

> $PATH
环境变量修改在~./bashrc或者 ~./profile里面
具体来说，比如要把/etc/apache/bin目录添加到PATH中
PATH=$PATH:/etc/apache/bin  #只对本次回话有效
或者  PATH=$PATH:/etc/apache/bin #在~./bashrc或者~./profile里面添加这句话

3. alias设置
vi 中输入 /XXX 可以搜索
vi ~/.bashrc 
添加 alias yourcommand='ls -alr' 
重开session即可生效

4. 


