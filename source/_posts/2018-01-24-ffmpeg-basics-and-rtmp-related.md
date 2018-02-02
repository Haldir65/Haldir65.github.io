---
title: 2018-01-24-ffmpeg-basics-and-rtmp-related
date: 2018-01-24 13:44:33
tags:
---

ffmpeg安装手记
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/water foot cold dark river.jpg?imageView2/2/w/600)
<!--more-->


## 安装
[how-to-install-ffmpeg-on-windows](http://adaptivesamples.com/how-to-install-ffmpeg-on-windows/)
[下载](https://ffmpeg.zeranoe.com/builds/)

检查下是否安装完成:
> ffmpeg -codecs

## Basic commands
> ffmpeg -i video.mp4 ## 从视频中提取出信息
 ffmpeg -i video.mp4 video.avi ## 格式转换
ffmpeg -i input.mp4 -vn -ab 320 output.mp3 ##提取视频中的音频，转成mp3
ffmpeg -i input.mp4  -t 50 output.avi  ## 提取视频前50s
ffmpeg -i input.mp4 -aspect 16:9 output.mp4 ## 更改长宽比



参考[20-ffmpeg-commands-beginners](https://www.ostechnix.com/20-ffmpeg-commands-beginners/)

需要知道的是，***视频转码是很费性能的***，消耗的时间也比较长。


## 参考

[nginx搭建rtmp推流服务](https://www.jianshu.com/p/fc64102d6162)