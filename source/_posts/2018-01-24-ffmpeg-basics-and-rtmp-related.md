---
title: ffmpeg知识手册
date: 2018-01-24 13:44:33
tags:
---

ffmpeg安装手记
![](https://www.haldir66.ga/static/imgs/water foot cold dark river.jpg)
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


[ffmpeg c语言写一个video player](https://github.com/mpenkov/ffmpeg-tutorial)


[ffmpeg的node js 包装](https://github.com/fluent-ffmpeg/node-fluent-ffmpeg)

### 视频基础信息
视频包括：
内容元素
Image
Audio
Metadata(元信息)

编码解码器(Codec)
video: H.263, H.264,H.265
Audio: AAC, HE-AAC

容器文件格式(Container)
MP3 , Mp4 ,FLV, AVI

视频关键字
帧率（Frame rate）
码率 （Bit rate） -- 这个是指文件大小
分辨率 (Bit rate)
图片群组 (Group of Picture， GOP) I帧率 ： 关键帧(完整，直接解码) B/P帧 ：参考帧 P帧依赖于前帧，B帧依赖于前后帧

帧数据 编码压缩之后组成多个GOP，最后封装成视频。

视频直播结构

摄像头 编码 -> 视频流 -> 传输给server -> server负责推流 -> 交给播放器
录制包括Native, webRTC(提供js的api获取视频数据)
直播协议这边，分为HLS和rtmp. html5的video标签使用HLS协议(.m3u8)，
pc端使用flash,native端使用系统播放器使用rtmp协议

### HLS
HLS(HTTP Live Streaming)协议播放视频流在webview中使用比较简单,android和ios的webview都支持
```html
<video control autoplay>
    <source src="http://10.66.99.77:8080/hls/mystream.m38u" type="application/vnd.apple.mpegurl"/>
    <p class="warning">Your browser does not support HTML5 video. </p>
</video>
```

HLS协议的.m3u8文件理论上就是讲推送的视频流切分成多个.ts文件外加一些配置。注意这个.m3u8文件只是一个文本文件，很小的。
所以video标签在请求完上面的m3u8文件之后，就会根据配置信息去拉取真正的.ts文件。ts文件时长太长或者太短都不好，一般推荐是5s。

### RTMP(Real Time Messaging Protocol)
是Macromedia开发的直播协议，现在属于Adobe。rtmp和HLS一样可以用于视频直播，但是RTMP因为是基于flash的，所以无法在ios生态中播放，但是实时性要比HLS好，就是低延时。所以一般使用这种协议来上传视频流，也就是视频流推送到服务器。RTMP是基于tcp长连接的，延时在2s左右，而HLS是基于http的，延时在10-30s左右。
推流端的话，Android一般是用MediaCodec将视频数据编码成rtmp包的格式，RTMP流本质上是FLV格式的音视频
nginx上要配合一个nginx-rtmp-module来做








## 参考

[nginx搭建rtmp推流服务](https://www.jianshu.com/p/fc64102d6162)

todo 
opencv
view video using ffmplayer

tbd
- [ ] ffmpeg 的js wrapper

[ijkplayer现在看来似乎只是ffmpeg的一层wrapper](https://github.com/Bilibili/ijkplayer)
