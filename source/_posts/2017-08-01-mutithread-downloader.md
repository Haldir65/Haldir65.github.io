---
title: 多线程断点续传原理及实现
date: 2017-08-01 22:19:31
tags: [java]
---

主要讲一下在java中实现多线程断点续传的原理,主要讲断点下载的原理。
![](http://odzl05jxx.bkt.clouddn.com/4b52d8db2e9d86b95c730af1db127a81.jpg?imageView2/2/w/600)
<!--more-->


其实就是在Http请求里面加上一个"range"的header，HttpUrlConnection可以这么干：

- conn.setRequestProperty("Range", "bytes=" + 500 + "-" + 1000);

也就是告诉服务器上次下载到的位置，本地写文件可以使用RandomAccessFile。本地需要记录下上次中断后停下来的位置。可以用db记录，也可以用sp记录。


这里面的难点在于多线程同步问题，高效率锁。还得要使用ArrayBlockingQueue。

## 1. 获取要下载的内容的contentLength
HttpUrlConnection有一个connection.getContentLength()方法，用于获取内容大小(bytes)


## 2. 大文件上传避免oom
```java
Caused by java.lang.OutOfMemoryError: Failed to allocate a 65548 byte allocation with 32012 free bytes and 31KB until OOM
at com.android.okio.Segment.<init>(Segment.java:37)
at com.android.okio.SegmentPool.take(SegmentPool.java:48)
at com.android.okio.OkBuffer.writableSegment(OkBuffer.java:511)
at com.android.okio.OkBuffer.write(OkBuffer.java:424)
at com.android.okio.OkBuffer.clone(OkBuffer.java:740)
at com.android.okhttp.internal.http.RetryableSink.writeToSocket(RetryableSink.java:77)
at com.android.okhttp.internal.http.HttpConnection.writeRequestBody(HttpConnection.java:263)
at com.android.okhttp.internal.http.HttpTransport.writeRequestBody(HttpTransport.java:84)
at com.android.okhttp.internal.http.HttpEngine.readResponse(HttpEngine.java:790)
at com.android.okhttp.internal.http.HttpURLConnectionImpl.execute(HttpURLConnectionImpl.java:405)
at com.android.okhttp.internal.http.HttpURLConnectionImpl.getResponse(HttpURLConnectionImpl.java:349)
at com.android.okhttp.internal.http.HttpURLConnectionImpl.getResponseCode(HttpURLConnectionImpl.java:517)
at com.android.okhttp.internal.http.DelegatingHttpsURLConnection.getResponseCode(DelegatingHttpsURLConnection.java:105)
```

[参考](http://blog.sina.com.cn/s/blog_bfdb961b0101mkbo.html) con.setChunkedStreamingMode(1024);//内部缓冲区---分段上传防止oom
[解决方案](https://github.com/square/retrofit/issues/2270),RequestBody的contentLength设置为-1就好了
[HttpURLConnection教程](http://www.cnblogs.com/begin1949/p/5060802.html)


## 3. 现有的实现方案
非常优秀的library，英语流利说喜欢搞多进程。
[Aspsine](https://github.com/Aspsine/MultiThreadDownload)
[英语流利说](https://github.com/lingochamp/FileDownloader)
下载文件的本质是inputstream.read

## 参考
- [简书](http://www.jianshu.com/p/2b82db0a5181)
- [Demo](https://github.com/AriaLyy/Aria)
- [MultiThreadDownload for Android](https://github.com/Aspsine/MultiThreadDownload)
- [csdn](http://blog.csdn.net/zhaokaiqiang1992/article/details/43939279)
- [断点上传麻烦点，要自己搭server](http://blog.csdn.net/chenrunhua/article/details/50113993)
