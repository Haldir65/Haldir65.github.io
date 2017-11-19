---
title: 网络通信手册
date: 2017-07-21 00:05:32
tags:
  - linux
  - tools
---

网络相关的查找手册
![](http://odzl05jxx.bkt.clouddn.com/b9ae1189145b4a4d9dfe4d0b89a21b47.jpg?imageView2/2/w/600)
<!--more-->


## 1. URI和URL是两件事
根据[wiki的解释](https://zh.wikipedia.org/wiki/%E7%BB%9F%E4%B8%80%E8%B5%84%E6%BA%90%E6%A0%87%E5%BF%97%E7%AC%A6)
URL是URI的子集，URL的一般格式包括三部分：资源类型、存放资源的主机域名，资源文件名。语法格式上,根据[百度百科](https://baike.baidu.com/item/URL%E6%A0%BC%E5%BC%8F/10056474?fr=aladdin)找到一个能用的：
```
protocol :// hostname[:port] / path / [;parameters][?query]#fragment
```

- protocol 指使用的传输协议(http、file、https、mailto、ed2k、thunder等)
hostname 是指存放资源的服务器的域名系统(DNS) 主机名或 IP 地址。有时，在主机名前也可以包含连接到服务器所需的用户名和密码（格式：username:password@hostname）。有时候是ip,有时候前面还带账号密码
port http默认是80，https是443 ,ssh默认端口号是20
path(路径) 由零或多个“/”符号隔开的字符串，一般用来表示主机上的一个目录或文件地址。
parameters（参数）这是用于指定特殊参数的可选项。
query(查询) 一般GET请求可以在这里面查找。可选，用于给动态网页（如使用CGI、ISAPI、PHP/JSP/ASP/ASP。NET等技术制作的网页）传递参数，可有多个参数，用“&”符号隔开，每个参数的名和值用“=”符号隔开。
fragment（信息片断）字符串，用于指定网络资源中的片断。例如一个网页中有多个名词解释，可使用fragment直接定位到某一名词解释。


### 1.1 Http的GET请求的url长度是有限制的
Http1.1协议中并没有做这个限制，但通信的两端，服务器(Nginx和Tomcat)和客户端(浏览器厂商)都做了限制。[参考](https://cnbin.github.io/blog/2016/02/20/httpxie-yi-zhong-de-ge-chong-chang-du-xian-zhi-zong-jie/)
一些浏览器的url长度限制，即url长度不能超过这么多个字符
- IE : 2803
- Firefox:65536
- Chrome:8182
- Safari:80000
- Opera:190000
再具体一点的话，就是下面这个我在百度里搜索zhihu这个词的时候
```
GET /s?ie=utf-8&f=8&rsv_bp=0&rsv_idx=1&tn=baidu&wd=zhihu&rsv_pq=d66519eb000157d4&rsv_t=4ce0B%2B8rfGgWxu9SAjGi7H5n5vylTydZebyyJXgD0JrPUSfBwp5zKxK9uKQ&rqlang=cn&rsv_enter=1&rsv_sug3=6&rsv_sug1=4&rsv_sug7=100&rsv_sug2=0&inputT=3737&rsv_sug4=4444 HTTP/1.1  （从GET到这里不能超过8182个字）
Host: www.baidu.com
Connection: keep-alive
Cache-Control: max-age=0
Upgrade-Insecure-Requests: 1
User-Agent: Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.101 Safari/537.36
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8
DNT: 1
Accept-Encoding: gzip, deflate, br
Accept-Language: zh-CN,zh;q=0.8
Cookie: BAIDUID=325243543:FG=1; PSTM=543534543; BIDUPSID=54353; pgv_pvi=5435; MCITY=-%3A; BD_HOME=0; BD_UPN=5435; H_PS_645EC=453453453; BDORZ=5435; BD_CK_SAM=1; PSINO=5; BDSVRTM=54; H_PS_PSSID=543; ispeed_lsm=2
```
另外，Cookie就是一个键值对，放在header里面，所以如果服务器对于Http请求头长度做了限制，Cookie也会受限制。

###1.2 GET和POST的一些小区别
GET只会发一个TCP包，POST发两个(一个是Header,一个是Body)。所以GET快一点，POST要求服务器长时间处于连接状态，可能造成服务器负载升高。
一个比较实在的例子是，我在七牛的CDN上看到的收费价格1万次PUT/10万次GET，不用想也知道GET对于服务器的压力要比PUT小


## 2. http请求本质上是发送了一堆字符给服务器
另外,domain(域名)是指www.wikipedia.org这种，DNS会把它转成一个ip地址
而在http请求的header中经常或看到
Host: www.baidu.com\r\n 这样的一行，其实这是[Http头字段](https://zh.wikipedia.org/wiki/HTTP%E5%A4%B4%E5%AD%97%E6%AE%B5)的标准请求字段，总之就是标准。这个Host指的是服务器的域名，就是domian。
wiki上的[http名词解释](https://zh.wikipedia.org/wiki/%E8%B6%85%E6%96%87%E6%9C%AC%E4%BC%A0%E8%BE%93%E5%8D%8F%E8%AE%AE)

## 3. Header相关的
首先看下请求百度首页的request和response

Request（其实发送的时候每一行后面都跟了一个\r\n用于换行）

```
GET / HTTP/1.1
Host: www.baidu.com
Connection: keep-alive
Cache-Control: max-age=0
Upgrade-Insecure-Requests: 1
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8
DNT: 1
Accept-Encoding: gzip, deflate, br
Accept-Language: zh-CN,zh;q=0.8,en-US;q=0.6,en;q=0.4
Cookie: BAIDUID=B41D39A8836273546754tC7F0C5DE315B64E2:FG=1; MCITY=-289%3A;
```

Response(同样，无线电传输的时候是没有换行的概念的，每一行末尾都有一个\r\n)

```
HTTP/1.1 200 OK
Bdpagetype: 1
Bdqid: 0xa1524365407b7
Bduserid: 0
Cache-Control: private
Connection: Keep-Alive
Content-Encoding: gzip
Content-Type: text/html; charset=utf-8
Cxy_all: baidu+9bdfb3567324332546a7cb482b3
Date: Sun, 23 Jul 2017 08:27:22 GMT
Expires: Sun, 23 Jul 2017 08:26:51 GMT
Server: BWS/1.1
Set-Cookie: BDSVRTM=0; path=/
Set-Cookie: BD_HOME=0; path=/
Set-Cookie: H_PS_PSSID=1430_210543_17001; path=/; domain=.baidu.com
Strict-Transport-Security: max-age=172800
Vary: Accept-Encoding
X-Powered-By: HPHP
X-Ua-Compatible: IE=Edge,chrome=1
Transfer-Encoding: chunked
```

报文的[语法](http://www.cnblogs.com/klguang/p/4618526.html)：
请求的格式

```
<method> <request-URL> <version>
<headers>
<entity-body>
```


响应的格式

```
<version> <status> <reason-phrase>
<headers>
<entity-body>
```

request中常见的请求头包括：

- Accept：指定客户端能够接收的内容类型
示例 : Accept:image/webp,image/apng,image/*,*/*;q=0.8

- Accept-Charset ：浏览器可以接受的字符编码集

- Accept-Encoding:gzip, deflate, br
客户端浏览器可以支持的压缩编码类型。比如gzip，用于压缩数据，节省带宽。

- Accept-Language 指定Http客户端浏览器用来优先展示的语言
示例: Accept-Language:zh-CN,zh;q=0.8,en-US;q=0.6,en;q=0.4

- Cache-Control： [参考](https://developers.google.com/web/fundamentals/performance/optimizing-content-efficiency/http-caching?hl=zh-cn)
具体操作[百度百科](https://baike.baidu.com/item/Cache-Control)写的很清楚
可能的值包括：

public 所有内容都将被缓存(客户端和代理服务器都可缓存)
private 内容只缓存到私有缓存中(仅客户端可以缓存，代理服务器不可缓存)
no-cache 必须先与服务器确认返回的响应是否被更改，然后才能使用该响应来满足后续对同一个网址的请求。因此，如果存在合适的验证令牌 (ETag)，no-cache 会发起往返通信来验证缓存的响应，如果资源未被更改，可以避免下载。
no-store 所有内容都不会被缓存到缓存或 Internet 临时文件中
max-age=xxx (xxx is numeric) 缓存的内容将在 xxx 秒后失效, 这个选项只在HTTP 1.1可用, 并如果和Last-Modified一起使用时, 优先级较高

实际过程中我看到了这种：
Cache-Control:private, no-cache, no-cache=Set-Cookie, no-store, proxy-revalidate

- Connection:keep-alive  http1.1 默认为keep-alive
http 1.0需要手动设置。原理就是服务器保持客户端到服务器的连接持续有效，避免了重新建立连接的开销(tcp三次握手)。这种情况下，客户端不能根据读取到EOF(-1)来判断传输完毕。有两种解决方案：对于静态文件，客户端和服务器能够知道其大小，使用content-length，根据这个判断数据是否已经接收完成；对于动态页面，不可能预先知道内容大小。可以使用Transfer-Encoding:chunked的模式进行传输。基本上就是服务器把文件分成几块，一块一块的发送过去。[参考](https://www.byvoid.com/zhs/blog/http-keep-alive-header)

- Content-Type  代表文件类型。request只有POST请求中会有，Response中也会有。
POST里面的Content-type有两种:
Content-type: application/x-www-form-urlencoded;charset:UTF-8 //缺省值，表示提交表单
multipart/form-data //上传文件时用这种，既可以发送文本数据，也支持二进制上传。上面那个CharSet只是为了告诉服务器用的是哪种编码
响应头中的Content-Type示例： Content-Type:image/gif或者Content-Type: text/html;charset=utf-8 [参考](http://www.runoob.com/http/http-content-type.html)

- Date:Sun, 23 Jul 2017 07:39:47 GMT 这就是当前的GMT时间

- DNT: 1 Do Not Track（当用户提出启用“请勿追踪”功能后，具有“请勿追踪”功能的浏览器会在http数据传输中添加一个“头信息”（headers），这个头信息向商业网站的服务器表明用户不希望被追踪。这样，遵守该规则的网站就不会追踪用户的个人信息来用于更精准的在线广告。）


- Etag 用于比较客户端请求的文件的内容是否发生了改变。跟Last-Modified的作用差不多。最简单的用hash值就可以了。

- Expires:Mon, 01 Jan 1990 00:00:00 GMT    过期时间，这里应该是永不过期

- HOST 服务器的域名(domian)或者ip地址
Host: www.baidu.com

- If-Modified-Since:Fri, 24 Feb 2017 12:37:22 GMT 这个跟缓存有关

- If-None-Match:"abf29cbe9a8ed21:0" 还是缓存

- Pramga 和Cache-Control一样
实例： Pramga: no-cache 相当于 Cache-Control： no-cache。

- User-Agent 这个代表用的是哪种浏览器(客户端)，写爬虫的时候找到一大堆
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36
Android设备发出来的可能长这样： Mozilla/5.0 (Linux; U; Android 4.4.4; zh-cn; HTC_D820u Build/KTU84P) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30
ios设备发出来的长这样: Mozilla/5.0 (iPhone; CPU iPhone OS 8_0 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12A365 Safari/600.1.4
至少Chrome团队给出了自家浏览器的[UA](https://developer.chrome.com/multidevice/user-agent#webview_user_agent)

- Referer 一般是一个url，代表当前请求时从哪个页面发出的，写爬虫有用

Header其实就是个字典，比较麻烦的就是Cache-Control了，这个还要结合If-None-Match，Etag来看。需要用的时候再看应该也不迟。


[WikI上比较完整](https://zh.wikipedia.org/wiki/HTTP%E5%A4%B4%E5%AD%97%E6%AE%B5)

**Transfer-Encoding: chunked 有时候要传输的Content-Length实在太大，服务器计算长度需要开很大的Buffer，干脆把文件分块传输。**

[浏览器对于缓存的实际处理](http://www.jianshu.com/p/fd00f0d02f5f)，是否过期由Cache-Control标识的max-age和Expires判断。Cache-Control的优先级较高。[From Chrome](https://developers.google.com/web/fundamentals/performance/optimizing-content-efficiency/http-caching?hl=zh-cn)
简单来说就是先看客户端是否Expire，然后去服务器看下Etag,最后看Last-Modified那个。

## 4. Cookie和Session

### 4.1 Cookie
先看[Wiki](https://zh.wikipedia.org/wiki/Cookie)上的解释:
- 指某些网站为了辨别用户身份而储存在用户本地终端（Client Side）上的数据（通常经过加密.主要是因为Http是无状态的，服务器不知道这一次连接和上一次连接是不是同一个客户端
Cookie总是保存在客户端中，按在客户端中的存储位置，可分为内存Cookie和硬盘Cookie。内存Cookie由浏览器维护，保存在内存中，浏览器关闭后就消失了，其存在时间是短暂的。硬盘Cookie保存在硬盘里，有一个过期时间，除非用户手工清理或到了过期时间，硬盘Cookie不会被删除，其存在时间是长期的。所以，按存在时间，可分为非持久Cookie和持久Cookie。

Cookie的一些缺点，直接照搬WiKi了
- Cookie会被附加在每个HTTP请求中，所以无形中增加了流量。
- 由于在HTTP请求中的Cookie是明文传递的，所以安全性成问题。（除非用HTTPS）
- Cookie的大小限制在4KB左右。对于复杂的存储需求来说是不够用的。

另外，不同域名是无法共享浏览器端本地信息，包括cookies，这即是跨域问题。百度是不能读取爱奇艺的Cookie的，这是安全性问题。
需要注意的是，虽然网站images.google.com与网站www.google.com同属于Google，但是域名不一样，二者同样不能互相操作彼此的Cookie。必须域名一样才能操作。
Java中把Cookie封装成了javax.servlet.http.Cookie类，直接用就可以了。

Cookie并不提供修改、删除操作。如果要修改某个Cookie，只需要新建一个同名的Cookie，添加到response中覆盖原来的Cookie。



对了，在众多的Header中Cookie一般长这样:

- Cookie:key1=value1;key_2=value2;key_3=value3;JSessionID=24DHFKDSFKJ324329NSANDI124EH
故意把最后一个JSESSION写出来是因为底下要讲Session了嘛



### 4.2 Session
[参考文章](http://lavasoft.blog.51cto.com/62575/275589)
Header(字典)里面装着一个Cookie(字典)，Cookie里面有个键值对:JSESSIONID:SESSIONID
宏观上就是这么个关系。

Cookie保存在客户端，Session保存在服务器端。Session是在客户端第一次访问的时候由服务器创建的，session一般存储在redis中（ram），客户端始终只有sessionId。第二次请求的时候(session还未过期)，浏览器会加上sessionId=XXXXX。服务器接收到请求后就得到该请求的sessionID，服务器找到该id的session返还给请求者（Servlet）使用。一个会话只能有一个session对象，对session来说是只认id不认人。

Session超时：超时指的是连续一定时间服务器没有收到该Session所对应客户端的请求，并且这个时间超过了服务器设置的Session超时的最大时间。
Session的maxAge一般为-1，表示仅当前浏览器内有效，关闭浏览器就会失效。

知乎上有一段比较好的[描述](https://www.zhihu.com/question/19786827/answer/66706108),这里直接引用了。
http是无状态的协议，客户每次读取web页面时，服务器都打开新的会话，而且服务器也不会自动维护客户的上下文信息，那么要怎么才能实现网上商店中的购物车呢，session就是一种保存上下文信息的机制，它是针对每一个用户的，变量的值保存在服务器端，通过SessionID来区分不同的客户,session是以cookie或URL重写为基础的，默认使用cookie来实现，系统会创造一个名为JSESSIONID的输出cookie，我们叫做session cookie,以区别persistent cookies,也就是我们通常所说的cookie,注意session cookie是存储于浏览器内存中的，并不是写到硬盘上的，这也就是我们刚才看到的JSESSIONID，我们通常情是看不到JSESSIONID的，但是当我们把浏览器的cookie禁止后，web服务器会采用URL重写的方式传递Sessionid，我们就可以在地址栏看到 sessionid=KWJHUG6JJM65HS2K6之类的字符串。
javax.servlet.http.HttpServletRequest.getSession() 将会返回当前request相关联的HttpSession对象，如果不存在，将会创建一个。翻译一下，当一个浏览器请求来到之后，Servlet处理程序（Servlet容器内部实现）将会主动检查请求信息Cookie当中是否有JSESSIONID，若有，找到对应JSESSION的HttpSession对象，如果没有，创建一个，具体的机制在Servlet容器的实现当中。

Session就是维护会话的。

### 4.3 自动登录的实现
一些网站的“记住密码，自动登录功能”，据说discuz直接将加密的（可逆）uid和密码保存到cookie中。
另外一种做法是可以尝试将Session的过期时间设置的长一点，比如一年，下次访问网站的时候就能实现自动登录了。
更好一点的是是本地绝不保存用户敏感信息，登录生成一个有过期时间的的cookie或者token返回给客户端，下次打开浏览器判断下过期时间就好了。另外，现在浏览器大多带有记住密码的功能，这个锅还是丢给浏览器(用户)好了。



## 5. 长连接
像即时通讯软件，或者消息推送这种场景，都得维护一个长连接。
[HTTP长连接和短连接](http://blog.csdn.net/mr_liabill/article/details/50705130)


### 5.1长连接的实现原理
- 轮询
- 心跳
- Tcp长连接

Http长连接不如说tcp长连接,Tcp是可以不断开的，http连接服务器给到response之后就断开了。[TCP连接](http://www.cnblogs.com/zuoxiaolong/p/life49.html)Http不过是做了tcp连接复用,http通道是一次性的，tcp不是的，这样做也是为了节省tcp通道。
长连接就是Connection  keep-Alive那玩意，客户端和服务器都得设置才有效。
长短轮询的间隔是服务器通过代码控制的。

### 5.2 keep-Alive和WebSocket的区别


![](http://odzl05jxx.bkt.clouddn.com/ed541bc1ed61ead0bf6ea8233ef01c0a.jpg?imageView2/2/w/600)


### 5.3 http2可以实现推送了

### 5.4 Http这玩意就不是为了视频流设计的
[HTTP wasn't really designed for streaming](https://stackoverflow.com/questions/14352599/how-to-send-chunks-of-video-for-streaming-using-http-protocol)


### 5.5 主流浏览器浏览器默认最大并发连接数
浏览器不可能同时发起10000个请求，所以主流浏览器都设定了限制,主要是http1.1,http2的话，只有一条connection。
[解释](https://www.zhihu.com/question/20474326)

### 5.6 TLS,SSL


## 6. WebSocket、SPDY、Http2
WebSocket一种在单个TCP 连接上进行全双工通讯的协议。
HTTP/2（超文本传输协议第2版，最初命名为HTTP 2.0），简称为h2（基于TLS/1.2或以上版本的加密连接）或h2c（非加密连接），是HTTP协议的的第二个主要版本
SPDY也就是HTTP/2的前身，一种开放的网络传输协议，由Google开发，用来发送网页内容。基于传输控制协议（TCP）的应用层协议


### 7. DNS(Domian Name System)
通过java代码调用DNS的方式
```java
public class Test {  
    public static void main(String[] args) throws UnknownHostException {  
        //获取本机IP地址  
        System.out.println(InetAddress.getLocalHost().getHostAddress());  
        //获取www.baidu.com的地址  
        System.out.println(InetAddress.getByName("www.baidu.com"));  
        //获取www.baidu.com的真实IP地址  
        System.out.println(InetAddress.getByName("www.baidu.com").getHostAddress());  
        //获取配置在HOST中的域名IP地址  
        System.out.println(InetAddress.getByName("TEST").getHostAddress());  
    }  
}  
```

### 8.Fiddler抓包
- 手机和电脑连接同一个wifi
- 从https://www.telerik.com/download/fiddler 下载Fiddler
- 启动并配置: Tools->Fiddler->Connections, check "allow remote computers to connect" and default port is 8888
- 配置手机：选择连接的网络->修改网络->代理设置:手动; 代理服务器主机名为电脑的ip，端口8888，ip DHCP
- 抓包查看
[详细教程](http://www.trinea.cn/android/tcpdump_wireshark/)

===========================trash here=====================================

一些优化
[TTFB] TTFB（Time To First Byte），客户端发出请求到收到响应的第一个字节所花费的时间。一般浏览器里面都能看到，这也是服务端可以优化的指标。

GZip压缩文本还可以，图片就没必要开压缩了，因为图片本身就高度压缩了，再压只是浪费CPU。

网络协议，架构，规范，spdy,http2,url规范.
OSI七层网络体系结构 ： 物理层、数据链路层、网络层、传输层、表示层、会话层、应用层

HLS直播流慢(延迟高)是因为基于HTTP，(http live streaming，苹果提出的)
如果要低延迟还得rmtp

应用层面的Http，SMTP,FTP,POP,TLS/SSL,IMAP

tcp三次握手，四次挥手
udp使用

tls,https加密过程，sha1和sha256加密算法

ping ,traceRouter

tcp三次握手四次挥手，用人话说：
因为HTTP是一个基于TCP的协议,而TCP是一种可靠的传输层协议.建立TCP连接时会发生:三次握手(three-way handshake)firefox > nginx [SYN] 在么nginx > firefox [SYN, ACK] 在firefox > nginx [ACK] 知道了关闭TCP连接时会发生:四次挥手(four-way handshake)firefox > nginx [FIN] 我要关闭连接了nginx > firefox [ACK] 知道了,等我发完包先nginx > firefox [FIN] 我也关闭连接了firefox > nginx [ACK] 好的,知道了几个报文的标识的解释:SYN: synchronization(同步)ACK: acknowledgement(确认:告知已收到)FIN: finish(结束)

作者：eechen
链接：https://www.zhihu.com/question/67772889/answer/257170215
来源：知乎
著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。

## 参考
- [谈谈HTTP协议中的短轮询、长轮询、长连接和短连接](http://www.cnblogs.com/zuoxiaolong/p/life49.html)
- [http请求的TCP瓶颈](https://bhsc881114.github.io/2015/06/23/HTTP%E8%AF%B7%E6%B1%82%E7%9A%84TCP%E7%93%B6%E9%A2%88%E5%88%86%E6%9E%90/)
- [Restfull架构详解](http://www.runoob.com/w3cnote/restful-architecture.html)
- [文件断点续传原理,CountdownLatch](http://blog.csdn.net/zhuhuiby/article/details/6725951)
- [断点续传实现](http://lcodecorex.github.io/2016/08/01/%E6%96%87%E4%BB%B6%E5%88%86%E7%89%87%E4%B8%8E%E6%96%AD%E7%82%B9%E7%BB%AD%E4%BC%A0%E5%8E%9F%E7%90%86%E4%B8%8E%E5%85%B7%E4%BD%93%E5%AE%9E%E7%8E%B0/)
- [一张非常好的解释status code的表格](http://www.cnblogs.com/mayingbao/archive/2007/11/30/978530.html)
