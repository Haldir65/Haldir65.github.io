---
title: VPS下载Youtube视频并同步到本地
date: 2017-05-07 16:48:01
tags: [linux,python]
---

几天前花几块钱买了个新的vps，试了下，速度不错。后来看到网上有关于如何使用vps下载视频并拖到Windows的，试了一下，确实酸爽。
<!--more-->

### 1. youtube下载视频到vps的硬盘上
首先是安装一些必要的环境，我安装的系统是Ubuntu 14.0.4 ，这个版本默认的python是2.7。配置好pip,python等环境后，首先安装youtube-dl,基本上就是两行命令搞定的事情，参考[官网](http://rg3.github.io/youtube-dl/download.html)
```
sudo curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl

sudo chmod a+rx /usr/local/bin/youtube-dl
```

为了方便管理，首先在/根目录下面创建一个文件夹并切换到该目录下
> mkdir youtube   


以一个普通的[视频链接](https://www.youtube.com/watch?v=7PtDrv5AUmA)为例 
直接使用 
> youtube-dl https://www.youtube.com/watch?v=7PtDrv5AUmA


就能自动选择合适的格式，下载到当前目录。比较好的一点是，由于vps在美国，下载速度非常快，维持在20MB/ms的样子。下载好的文件会放在当前目录下，后面使用pscp工具从vps拖下来就好了，不过我实践下来，这一步往往是最慢的。关键要看vps到你的ip的速度。有些时候还会突然断掉，所以很麻烦。这个看后面能不能搞定百度云盘中转。
还有一个要注意的，生成的文件名是随机的，比如
> -yj74P_BY1zI.mp4

由于前面带了一个横杠，很多命令是不认这种名字的，需要手动重命名一下 
> mv -yj74P_BY1zI.mp4 porn.video
> mv ./-yj74P_BY1zI.mp4 porn.video #. 表示当前目录




有时候下载的文件带有空格，有时候带有中文，用单引号包起来就好了。

youtube-dl还有一些命令行参数可以设置
> youtube-dl --all-formats https://www.youtube.com/watch?v=7PtDrv5AUmA


这样会列出所有的可供下载的分辨率选项，每个选项前面带有一个序号，选择特定分辨率的选项下载只需要
> youtube-dl -f 13 https://www.youtube.com/watch?v=7PtDrv5AUmA 


### 2.从vps的硬盘上把下载好的视频拖下来
VPS下载视频的速度很快，但从vps到国内的速度就很慢了。
目前可能的方案有从百度网盘或dropBox中转，测试了一下百度网盘的方案bypy，vps上传到网盘速度太慢，shell出现假死，据说是百度方面限速的原因，所以这条路基本也是堵上了的。


### 3.后话
[you-get](https://github.com/soimort/you-get)也是基于python3的下载工具，使用简单。在windows上安装还有点麻烦，
在ubuntu上只需 pip3 install you-get 就安装好了
使用方式更简单 > you-get "url"
you-get还提供了windows版本 下载youtube视频只需要
> you-get -x 127.0.0.1:1080 -o "D:\Porn" 'https://www.youtube.com/watch?v=jNQXAC9IVRw'



[参考](https://doub.io/dbrj-1/)
[百度云盘同步的方法](http://www.typemylife.com/use-vps-download-videos-from-youtube-upload-to-baidu-cloud/)
[讨论](https://www.v2ex.com/t/189034)
