---
title: Windows10平台安装lxml记录
date: 2016-10-31 15:49:38
tags: Python
---


前几天尝试使用一个简单的微博爬虫进行操作，导包的时候遇到lxml缺失的问题，找了好久最终在百度知道上找到个能用的，(⊙﹏⊙)b。

###  1. 环境
1. python2.7, win10 64位
2. pip 环境变量配置 <!--more-->

### 2. 开始
1. cmd 命令行敲入
> pip install wheel

2. 准备lxml安装文件
   下载[地址](https://pypi.python.org/pypi/lxml/3.4.2)
   我的是win10 64位，选择 lxml-3.4.2-cp27-none-win_amd54.xhl

3. 下载完成后放到 c:\python27\文件夹下
4. 命令行敲入
> pip install c:\python27\lxml...(刚才的文件名)

5. 最后会提示
> successfully installeed lxml-3.4.2

这时候关闭pycharm project，重新打开就可以看到导入成功了。

### ref
- [百度有时候也是挺管用的](http://jingyan.baidu.com/article/cbcede07177b8702f40b4df9.html)
