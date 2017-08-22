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

### 1. 常用软件安装
[utorrent](http://blog.topspeedsnail.com/archives/5752)
apache,mysql

### 2. 环境变量怎么改
平时在shell中输入sudo XXX ,系统是如何知道怎么执行这条指令的呢。首先，可以查看which XXX ，用于查找某项指令对应的文件的位置。而像sudo这种都放在PATH位置，系统会在几个关键位置查找sudo命令。用户本身完全可以创建一个叫做sudo的文件chmod+X ，然后运行这个sudo。
```
查看PATH : echo $PATH
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games (注意，系统是按照这个顺序找的，如果在第一个目录下找到一个叫sudo的东西，就会直接执行了，所以这里是有潜在的危险的)
看下哪个命令对应的位置在哪里
which XXXk
比如sudo 就放在 /usr/bin/sudo
```

> $PATH
环境变量修改在~./bashrc或者 ~./profile里面
具体来说，比如要把/etc/apache/bin目录添加到PATH中
PATH=$PATH:/etc/apache/bin  #只对本次回话有效
或者  PATH=$PATH:/etc/apache/bin #在~./bashrc或者~./profile里面添加这句话

### 3. alias设置
vi 中输入 /XXX 可以搜索
vi ~/.bashrc
添加 alias yourcommand='ls -alr'
重开session即可生效

### 4. pushd和popd（类似于文件夹stack）

### 5. 小硬盘linux磁盘要经常清理需要的命令
- du --max-depth=1 -h # 查看当前路径下所有文件/文件夹的大小
- du -k --max-depth=2 | sort -rn # 加上排序

### 6. AWK文本分析工具
- awk '{print $0}' /etc/passwd # 和cat差不多，显示文本内容

### 7.tar命令
主要是跟压缩和解压文件有关的,[参考](http://man.linuxde.net/tar)
```
tar -cvf log.tar log2012.log 仅打包，不压缩！
tar -zcvf log.tar.gz log2012.log 打包后，以 gzip 压缩
tar -jcvf log.tar.bz2 log2012.log 打包后，以 bzip2 压缩
```

对照手册来看：
-c //小写的c，--create，表示创建新的备份文件
-v //verbose,显示进度什么的
-f 指定备份文件
-z --gzip，通过gzip压缩或者解压文件

### 8.定时任务怎么写
已经有网站把各种常用的[example](https://crontab.guru/every-6-hours)写出来了，直接照抄就是
后面跟上需要的命令，例如重启就是 /sbin/reboot

### 9. 查找相关(grep,find)
在文件中查找字符串，不区分大小写
- grep -i "sometext" filenname
在一个文件夹里面的所有文件中递归查找含有特定字符串的文件
- grep -r "sometext" *

find
根据文件名查找文件
- find -name *.config  #在当前目录下查找
- find / -name finename # 在根目录下查找filename的文件("filename"用双引号包起来)
- 

### 10.已安装的软件
- sudo dpkg -l

### 11.Ping一个主机
- ping -c 5 gmail.com #只发送5次

### 12.Wget 
下载文件 
- wget url
下载文件并以指定的文件名保存下来
- wget -0 filename url




## 参考
- [每天一个Linux命令](http://www.cnblogs.com/peida/archive/2012/12/05/2803591.html)
- [awk是三个人的名字](https://mp.weixin.qq.com/s/L0oViwqjIgudY-SrV0paRA)
