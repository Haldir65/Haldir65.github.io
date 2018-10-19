---
title: Windows10平台安装lxml记录
date: 2016-10-31 15:49:38
categories: blog
tags: [python]
---

![](https://www.haldir66.ga/static/imgs/Carla_Ossa_in_strapless_gown.jpg)
 <!--more-->

前几天尝试使用一个简单的微博爬虫进行操作，导包的时候遇到lxml缺失的问题，找了好久最终在百度知道上找到个能用的，(⊙﹏⊙)b。

###  1. 环境
1. python2.7, win10 64位
2. pip 环境变量配置

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


### 2018年1月更新
首先确认pip是否安装了lxml，pip list(查看已安装的包)
[How to install LXML for Python 3 on 64-bit Windows](https://www.webucator.com/blog/2015/03/how-to-install-lxml-for-python-3-on-64-bit-windows/)
因为安装的是python3.6，所以下载lxml‑4.1.1‑cp36‑cp36m‑win32.whl这个文件
win10的64位系统只需要安装 lxml‑4.1.1‑cp36‑cp36m‑win32.whl ,
如果安装lxml‑4.1.1‑cp36‑cp36m‑win_amd64.whl的话，可能会提示[filename-whl-is-not-supported-wheel-on-this-platform](https://stackoverflow.com/questions/28568070/filename-whl-is-not-supported-wheel-on-this-platform)，是因为安装的python是32位的。


### ref
- [百度有时候也是挺管用的](http://jingyan.baidu.com/article/cbcede07177b8702f40b4df9.html)
