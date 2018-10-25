---
title: 网络通信手册-2
date: 2018-04-26 13:00:02
tags: [tools]
---

OkHttp通过ConnectionPool做到tcp连接复用（在Timeout内）,所以并不是每个http都去建立一个tcp连接
自定义通讯协议，使用java socket实现客户端和服务端。需要注意的是分包问题和黏包问题
![](https://www.haldir66.ga/static/imgs/jpglight-and-shadow-2411321_960_720.jpg)
<!--more-->

## 1. http请求中tcp连接的复用(深入okHttp 3.9.1的connectionPool以及引用计数)
在高并发的请求连接情况下或者同个客户端多次频繁的请求操作，无限制的创建连接会导致性能低下。所以OkHttp做到了对socket的复用和及时清理。
从第四个intercepter开始
ConnectInterceptor.java
```java
public final class ConnectInterceptor implements Interceptor{

  @Override public Response intercept(Chain chain) throws IOException {
  RealInterceptorChain realChain = (RealInterceptorChain) chain;
  Request request = realChain.request();
  // 第一步，获取streamAllocation
  StreamAllocation streamAllocation = realChain.streamAllocation();

  // We need the network to satisfy this request. Possibly for validating a conditional GET.
  boolean doExtensiveHealthChecks = !request.method().equals("GET");
  // 第二步，使用streamAllocation创建(或者复用)一个httpCodec模型（即处理header和body的读写策略，具体实现包括Http1Codec和Http2Codec）
  HttpCodec httpCodec = streamAllocation.newStream(client, chain, doExtensiveHealthChecks);
  // 第三部，挑选出RealConnection,streamAllocation对象中的mConnection变量是在第二步里面赋值的
  RealConnection connection = streamAllocation.connection();

  return realChain.proceed(request, streamAllocation, httpCodec, connection);
  }
}
```

所以socket连接复用就在这句话里面了
> HttpCodec httpCodec = streamAllocation.newStream(client, chain, doExtensiveHealthChecks);

StreamAllocation.java
```java
public HttpCodec newStream(
    OkHttpClient client, Interceptor.Chain chain, boolean doExtensiveHealthChecks) {

      // 省略部分，主要是这两句话
      RealConnection resultConnection = findHealthyConnection(connectTimeout, readTimeout,
               writeTimeout, connectionRetryEnabled, doExtensiveHealthChecks);
      //
      HttpCodec resultCodec = resultConnection.newCodec(client, chain, this);
    }
```

findHealthyConnection最终走到这里
```java
// Attempt to get a connection from the pool.
for (RealConnection connection : connections) {
    if (connection.isEligible(address, route)) {
      streamAllocation.acquire(connection, true);
      return connection;
    }
  }

// 判断是否isEligible的方法在RealConnection里面

// If the non-host fields of the address don't overlap, we're done.
 if (!Internal.instance.equalsNonHost(this.route.address(), address)) return false;
// 只要DNS,port,protocols等host无关的参数中有一个不同就不能复用

 // If the host exactly matches, we're done: this connection can carry the address.
 if (address.url().host().equals(this.route().address().url().host())) {
   return true; // This connection is a perfect match.
 }
 // 这里说明host是相同的，上面的DNS什么的都是一样的，只有后面的path,query或者RequestBody不同，那么直接复用
```

所以这里socket复用的方式是直接使用RealConnection持有Socket对象的引用，每一次在RealConnection的connect成功后，都会讲这个socket包装成一个BufferedSource(读取Response)和BufferedSink(往外写Request)，在timeout时长内，socket不会被关闭。既然缓存就一定会有清理

在上面的findHealthyConnection中有一段
> streamAllocation.acquire(connection, true);

这里面的作用就是将这条请求（Stream）添加到当前连接承载的一个List<Reference<StreamAllocation>>中，也就是所谓的引用计数。提到这一点是要谈到清理的实现：
ConnectionPool中有一个Executor，目的就是执行一个cleanupRunnable的Runnable，这里面的清理操作大致如下：
```java
long cleanup(long now) {
   // Find either a connection to evict, or the time that the next eviction is due.
   synchronized (this) {
     for (Iterator<RealConnection> i = connections.iterator(); i.hasNext(); ) {
       RealConnection connection = i.next();

       // If the connection is in use, keep searching.
       if (pruneAndGetAllocationCount(connection, now) > 0) {
         inUseConnectionCount++; //这条连接还在用
         continue;
       }

       idleConnectionCount++; //这条连接现在空闲下来了

       // If the connection is ready to be evicted, we're done.
       long idleDurationNs = now - connection.idleAtNanos;// 这条连接已经多久没用到了，假如超过了闲置时间(默认5纳秒)，就准备干掉这个socket
       if (idleDurationNs > longestIdleDurationNs) {
         longestIdleDurationNs = idleDurationNs;
         longestIdleConnection = connection;
       }
     }
       // We've found a connection to evict. Remove it from the list, then close it below (outside
       // of the synchronized block).

       // A connection will be ready to evict soon.

       // All connections are in use. It'll be at least the keep alive duration 'til we run again.

       // No connections, idle or in use.
   }
  // 在这前面如果找不到一条该被干掉的连接，直接return
   closeQuietly(longestIdleConnection.socket());// 这里面就是socket.close了

   // Cleanup again immediately.
   return 0;
 }
```

观察一下ConnectionPool的构造函数
```java
/**
  * Create a new connection pool with tuning parameters appropriate for a single-user application.
  * The tuning parameters in this pool are subject to change in future OkHttp releases. Currently
  * this pool holds up to 5 idle connections which will be evicted after 5 minutes of inactivity.
  */
  // 最多保留5条闲置RealConnection(也就是底层5个Socket),每个连接(Socket)如果超过5分钟没有接客，直接干掉
 public ConnectionPool() {
   this(5, 5, TimeUnit.MINUTES);
 }
```
所以，在创建Client的时候，可以把socket的缓存数量写大一点，也可以自定义一个ConnectionPool，只要实现了put,get,remove等标准的CRD操作就行了。简单来说就是自己设计一个Cache，我觉得可以根据实际的endpoint数量来设定缓存的socket的数量。


## 2. 自定义通讯协议
http这种属于应用层的协议定义了每个数据包的结构是怎样的。在一些场合下，比如追求通讯速度，自定义加密手段，可能需要自定义结构体。
自己用Socket实现一套server-clinent通讯模型其实不难。
server这边，先确定自己对外公布的ip,port。然后起一个serverSocket，死循环去accept，每次accept到一个就添加到一个列表中，同时用线程池去执行一个死跑从socket中read的runnable。
client这边，根据server的ip和port去连接上，client主动发消息(byte，int,String类型都行)，server这边读到信息，给出response，clinent再读取server的回话，就跟两个人之间你一句我一句说话一样。整个过程中 **保持了长连接**,只要任何一方没有手动设置socket.setSoTimeout的话，放一晚上都不会断开。

一个重点是双方发送的消息格式，即两个人交流的语言，如果全部是String的话，那就跟http很像了，当然任何数据格式从socket发出去最终都是以byte的形式发出去的(比如string会用utf-8或者gbk编码成byte数组)。
google的protoBuffer最重要的两个方法writeTo(object转成byte数组)和parseFrom(byte数组转成object)。

[基于Java Socket的自定义协议，实现Android与服务器的长连接（二）](https://blog.csdn.net/u010818425/article/details/53448817)，基于这篇文章，可以将数据类型定义为统一的protocol，protocol的要素包括:
>协议版本
数据类型（数据类协议，数据ack类协议，心跳类协议，心跳ack类协议）
数据长度(这很重要)
消息id
扩展字段

协议版本要做到向后兼容，基本上只添加数据实体不删除数据实体就可以了
数据类型必需的三个要素是：
**长度，版本号，数据类型** (比方说0表示业务数据，1表示数据ack,2表示心跳，3表示心跳ack)。
扩展字段类似于extra，可以用json或者别的什么去实现。

## 3. tcp的分包和粘包问题

tcp发包的时候，如果一个包过大，会拆成两个包发(分包)。如果太小，发送方会攒着和下一个包一起发（粘包）。作为接收方并不知道收到的包是一个完整的包还是被拆分的还是由两个包合并而来。

可能发生分包和粘包的原因包括：
1、要发送的数据大于TCP发送缓冲区剩余空间大小，将会发生拆包。

2、待发送数据大于MSS（最大报文长度），TCP在传输前将进行拆包。

3、要发送的数据小于TCP发送缓冲区的大小，TCP将多次写入缓冲区的数据一次发送出去，将会发生粘包。

4、接收数据端的应用层没有及时读取接收缓冲区中的数据，将发生粘包。

我们都知道TCP属于传输层的协议，传输层除了有TCP协议外还有UDP协议。那么UDP是否会发生粘包或拆包的现象呢？答案是不会。UDP是基于报文发送的，从UDP的帧结构可以看出，在UDP首部采用了16bit来指示UDP数据报文的长度，因此在应用层能很好的将不同的数据报文区分开，从而避免粘包和拆包的问题。而TCP是基于字节流的，虽然应用层和TCP传输层之间的数据交互是大小不等的数据块，但是TCP把这些数据块仅仅看成一连串无结构的字节流，没有边界；另外从TCP的帧结构也可以看出，在TCP的首部没有表示数据长度的字段，基于上面两点，在使用TCP传输数据时，才有粘包或者拆包现象发生的可能。


虽然有分包和粘包问题，但是作为传输层的tcp能够保证发送出去的顺序和接收到的顺序是一致的。
那么基本的解决方法也很成熟了：
> 1、发送端给每个数据包添加包首部，首部中应该至少包含数据包的长度，这样接收端在接收到数据后，通过读取包首部的长度字段，便知道每一个数据包的实际长度了。
2、发送端将每个数据包封装为固定长度（不够的可以通过补0填充），这样接收端每次从接收缓冲区中读取固定长度的数据就自然而然的把每个数据包拆分开来。
3、可以在数据包之间设置边界，如添加特殊符号，这样，接收端通过这个边界就可以将不同的数据包拆分开。

另外，http协议是通过添加换行符“ /r/n”这种形式来解决上述问题的
参考[TCP粘包，拆包及解决方法](https://blog.csdn.net/Scythe666/article/details/51996268)

## 4. java这边socket的inputStream的read方法是会堵塞的
[就是read方法一直不返回](https://blog.csdn.net/cauchyweierstrass/article/details/49552053)，Socket只是一座桥梁，并不像本地文件一样，所以无法知道对方是否把话说完了。只有一方调用socket的close方法时才会发送EOF结束符，另一方的read = -1 才能成立，否则read方法就堵塞在那里。
InputStream有一个available()方法：
an estimate of the number of bytes that can be read (or skipped
over) from this input stream without blocking or  0 when it reaches the end of the input stream.
oves) 。不要把这个方法中的返回值当做这个流中所有可能数据的总和(多数情况下这种猜测是错误的)。

tcp的backlog变量

建立TCP连接时需要发送同步SYN报文，然后等待确认报文SYN+ACK，最后再发送确认报文ACK。

**如果应用层不能及时接受已被TCP接受的连接，这些连接可能占满整个连接队列，新的连接请求可能不被响应而会超时。如果一个连接请求SYN发送后，一段时间后没有收到确认SYN+ACK，TCP会重传这个连接请求SYN两次，每次重传的时间间隔加倍，在规定的时间内仍没有收到SYN+ACK，TCP将放弃这个连接请求，连接建立就超时了。**

[JAVA Socket超时浅析](https://blog.csdn.net/sureyonder/article/details/5633647)

BufferedWriter的主要原理是内部保留了一个char[]的数组，每次外部调用write的时候，不是直接写到underlying 的output中，而是system.arrayCopy到自己的char[]数组中，等发现char[]数组填满了，才去flushBuffer，就是把所有缓存的内容一次性写到底层的outputStream中。因为outputStream是一个字节一个字节去写的，每次写都要调用io操作，而io操作是很耗费资源的。所以bufferedWriter一次性写大量的数据，能够有效减少io次数，提高性能。


[以TCP/IP协议为例，如何通过wireshark抓包分析？](https://zhuanlan.zhihu.com/p/36414915)


[使用Nginx代理ws为wss协议](http://chown-jane-y.coding.me/2017/07/21/%E4%BD%BF%E7%94%A8Nginx%E4%BB%A3%E7%90%86ws%E4%B8%BAwss%E5%8D%8F%E8%AE%AE/)

[CRSF](https://zh.wikipedia.org/wiki/%E8%B7%A8%E7%AB%99%E8%AF%B7%E6%B1%82%E4%BC%AA%E9%80%A0)

[Content Security Policy 入门教程](http://www.ruanyifeng.com/blog/2016/09/csp.html)
两种方式设置csp白名单，一种是服务器在response的header中添加'Content-Security-Policy'这个header，另一种是在html中写meta标签
```html
<meta http-equiv="Content-Security-Policy" content="script-src 'self'; object-src 'none'; style-src cdn.example.org third-party.org; child-src https:">
```


[http请求是一行一行的文字，contentType only affects the body/document.you can use any ISO-8859-1 characters in the header.](https://stackoverflow.com/questions/19562501/ajax-what-is-the-default-character-encoding-for-http-header-values)。ISO-8859-1不支持中文，所以header里面的东西不能写中文。
body和path里面随意了

//网页上传excel表格的header
Content-Disposition: form-data; name="files[]" filename="sample.xls"
Content-Type: application/vnd.ms-excel

html里面上传文件一般是ajax对象send一个FormData出去，
也有Base64编码一遍然后在[服务端base64解码的](http://www.nickdesteffen.com/blog/file-uploading-over-ajax-using-html5)。主要是html5标准中添加了新的FileReader接口，可以读取客户端文件内容，所以很多开发就调用FileReader的readAsDataURL方法去将文件的内容变成[DATA URL形式的字符串](https://en.wikipedia.org/wiki/Data_URI_scheme)
不过这么干还是有缺点的
>1. Data URL形式的图片不会被浏览器缓存，这意味着每次访问这样页面时都被下载一次，
   但可通过在css文件的background-image样式规则使用Data URI Scheme，使其随css文件一同被浏览器缓存起来）。
2. Base64编码的数据体积通常是原数据的体积4/3，
   也就是Data URL形式的图片会比二进制格式的图片体积大1/3。
3. 移动端性能比较低。


[域名解析之dig,host,nslookup命令](http://luodw.cc/2015/12/27/dns03/)
好用的命令
> dig +trace baidu.com
nslookup -vc google.com 8.8.8.8 // -vc是指强制走tcp查询dns
nslookup -d www.163.com //显示ttl
nslookup -> set debug -> www.163.com //这三条走完是一样的，类似于交互模式
[dig挖出DNS的秘密](http://blogread.cn/it/article.php?id=5711)

[详细的http-content-type表格](http://www.runoob.com/http/http-content-type.html)
关于content-type,找到一篇[介绍](http://homeway.me/2015/07/19/understand-http-about-content-type/)
关于Http header常用字段[理解Http Header](http://zq210wl.github.io/2014/12/30/html-http-header-analysis/)
Http底层TCP ,ACK 等等需要tcpcump结合wireShark抓包

>下面是几个常见的Content-Type:
1.text/html
2.text/plain
3.text/css
4.text/javascript
5.application/x-www-form-urlencoded
6.multipart/form-data
7.application/json
8.application/xml
…
前面几个都很好理解，都是html，css，javascript的文件类型，后面四个是POST的发包方式。

[非官方的mime-type大全](https://www.sitepoint.com/mime-types-complete-list/)
[MDN上收录的mime-type](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Complete_list_of_MIME_types)
[X-Content-Type-Options:nosniff](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Content-Type-Optionshttps://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Content-Type-Options).就是说服务器返回的Response中如果包含这个header的话，script和styleSheet元素会拒绝错误的MIME类型的响应。主要是为了防止给予MIME类型的混淆攻击



Referrer Policy: unsafe-url
[unsafe-url](https://imququ.com/post/referrer-policy.html)
后台在response中返回一个302，并在response header中添加header:location。直接把前端网页重定向到新的位置


## 服务器压测工具
参考[DigitalOcean的文章]](https://www.digitalocean.com/community/tutorials/an-introduction-to-load-testing)

> npm install -g loadtest ##一个node的压力测试的web client
loadtest -n 100 -k  http://localhost:8000/api/somebackend # -n表示发送100次 -k 表示keep-alive
loadtest -c 10 --rps 200 http://mysite.com/  # -c表示client，创建10个client ， --rsp表示每秒的请求数量
loadtest -k -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8' -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36"  --rps 1 https://www.baidu.com/
注意： 这种短期创建大量外网连接的行为会对路由器造成一定压力。。。。


ab(ApacheBench) - a simple ,single-threaded command line tool for benchemarking an HTTP server.
因为是单线程的，所以并不能利用多核cpu的优势对server施加充分的负载。一般这么用
> ab -n 1000 -c 100 http://example.com/
ab -n <num_requests> -c <concurrency> <addr>:<port><path>


[属于netty的wrk](https://github.com/wg/wrk)
> wrk -H 'Host: localhost' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' -H 'Connection: keep-alive' -d 600 -c 1024 -t 8 http://127.0.0.1:8080/plaintext

wrk -H 'Host: localhost' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' -H 'Connection: keep-alive' -d 600 -c 1024 -t 8 http://127.0.0.1:8080/plaintext

[how-to-use-traceroute-and-mtr-to-diagnose-network-issues](https://www.digitalocean.com/community/tutorials/how-to-use-traceroute-and-mtr-to-diagnose-network-issues)

[.well-known的意思](https://serverfault.com/questions/795467/for-what-is-the-well-known-folder)，其实就跟robot.txt差不多。一种为了能够在客户端发起请求(但此时并不清楚url空间的允许策略，贸然访问万一侵权了呢)获得一些有用的信息。于是RFC就提出来搞一个专门的.well-known的path，这下面的位置都是广而周知的，大家都知道是特定的用途的。

[已经有人对shadowsocks的源码进行了分析](https://www.jianshu.com/p/a7ccaef0f465)

nc其实就是netcat了，功能比较强大
nc -vz 192.168.0.181 20060 //测试TCP端口可用性的方法
nc -vuz IP port //测试udp端口可用性的方式，但实际测下来，就算server上udp port没开，还是会返回succeeded，所以这个也不可靠

netcat还可以实现udp聊天
服务器上
nc -ul 1080 // 会卡在这里，等待新的消息到达1080端口
//客户端这边 
nc -u x.x.x.x 1080 //也会卡在这里，不过可以输入文字，按下回车，服务器这边就能收到消息了

wget --spider www.baidu.com //wget还有一个spider模式


[udp的MTU参数](http://yangtai.xunlei.com/?p=1326&cpage=6)

美团的技术博客还不错
[前端安全系列之二：如何防止CSRF攻击？](https://tech.meituan.com/fe_security_csrf.html)

[https的url是加密的吗？](https://stackoverflow.com/questions/499591/are-https-urls-encrypted)是的，
所以你可以把账户密码写在url后面发出去，这样是安全的，外界无法截获你的隐私信息.
但着实不应该这样做，
在浏览器地址栏和浏览器历史记录里面都留下了账户密码。可能会在http的referer里面带上你的url和隐私信息
但是第一次client hello的时候host还是会明文写在包里,后面的query Parameters由于跟client hello无关，所以是加密的.
[Server Name Indication](https://en.wikipedia.org/wiki/Server_Name_Indication)
SNI breaks the 'host' part of SSL encryption of URLs. You can test this yourself with wireshark. There is a selector for SNI

