---
title: 多线程断点续传原理及实现
date: 2017-08-01 22:19:31
tags: [java]
---

主要讲一下在java中实现多线程断点续传的原理,主要讲断点下载的原理。
![](http://www.haldir66.ga/static/imgs/4b52d8db2e9d86b95c730af1db127a81.jpg)
<!--more-->


其实就是在Http请求里面加上一个"range"的header，HttpUrlConnection可以这么干：

- conn.setRequestProperty("Range", "bytes=" + 500 + "-" + 1000);

也就是告诉服务器上次下载到的位置，本地写文件可以使用RandomAccessFile。本地需要记录下上次中断后停下来的位置。可以用db记录，也可以用sp记录。
实践中肯定要发两次请求，第一次是为了读content-Length，确定每一份下载任务需要下载多少bytes。
第二步，就是根据线程数量，总数除以线程数，用一个线程池(或者直接开多条线程)去执行这么多份任务。每一份任务的请求都要带上上面那个Range的Header。


nginx里面可能要设置一下,当然前提是下载服务本身支持range请求
```conf
proxy_cache_key $host&uri&is_args&args$http_range;
proxy_set_header Range $http_range;
proxy_set_header If-Range $http_if_range;
proxy_cache_valid 200 206; 
```
proxy_set_header就是Nginx在将请求传递给server的时候添加一些header，可以是文本，变量或者是二者的组合
可能还涉及到一些[proxy_cache](https://blog.csdn.net/dengjiexian123/article/details/53386586)模块的原理

另外这种情况下的http response header应该是206 Partial Requests,印象中网易云音乐网页端听歌的媒体文件是partial request


[HTTP文件断点续传的原理](http://www.cnblogs.com/Creator/p/5490929.html)
其实要注意的是，断点续传，下次开始下载前，需要根据ETag判断下服务器上的这个文件是否更改过了，如果改过了
>  httpURLConnection.getHeaderField("ETag");
>  httpURLConnection.getHeaderField("ETag"); //这是从零开始下载的时候获取Etag，本地保存
>
> httpURLConnection.setRequestProperty(“If-None-Match”, "b428eab9654aa7c87091e"); // 下载恢复之后，重新发请求，如果后返回一个304的状态码，那么可以继续执行。如果发生了更改，那么需要使用新的资源重新下载。


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
[HttpURLConnection教程](http://www.cnblogs.com/begin1949/p/5060802.html)
[上传的时候不走HttpUrlConnection，直接创建Socket模拟POST避免大文件OOM](http://blog.csdn.net/lmj623565791/article/details/23781773)

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
