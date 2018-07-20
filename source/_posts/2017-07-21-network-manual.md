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

[Data URI scheme](https://en.wikipedia.org/wiki/Data_URI_scheme)


### 1.1 Http的GET请求的url长度是有限制的(服务器和浏览器都限制了)
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

### 1.2 GET和POST的一些小区别
GET只会发一个TCP包，POST发两个(一个是Header,一个是Body)。所以GET快一点，POST要求服务器长时间处于连接状态，可能造成服务器负载升高。
***一个比较实在的例子是，我在七牛的CDN上看到的收费价格1万次PUT/10万次GET的价格是一样的，不用想也知道GET对于服务器的压力要比PUT小***

GET请求最后跟不跟斜杠"/"无所谓，但是POST请求最后面得跟"/"(back slash)


## 2. http请求本质上是发送了一堆字符给服务器
另外,domain(域名)是指www.wikipedia.org这种，DNS会把它转成一个ip地址
而在http请求的header中经常或看到
Host: www.baidu.com\r\n 这样的一行，其实这是[Http头字段](https://zh.wikipedia.org/wiki/HTTP%E5%A4%B4%E5%AD%97%E6%AE%B5)的标准请求字段，总之就是标准。这个Host指的是服务器的域名，就是domian。
wiki上的[http名词解释](https://zh.wikipedia.org/wiki/%E8%B6%85%E6%96%87%E6%9C%AC%E4%BC%A0%E8%BE%93%E5%8D%8F%E8%AE%AE)

### 2.1 statusCode有些常用的还是要记住的：
[比较好的一个表格](http://www.cnblogs.com/mayingbao/archive/2007/11/30/978530.html)
> 101 Switching Protocols (注意WebSocket)
200 一切正常，对GET和POST请求的应答文档跟在后面。
201 Created 比如刚刚向服务器提交了一次POST请求创建了一项资源
301 Moved Permanently 客户请求的文档在其他地方，新的URL在Location头中给出，浏览器应该自动地访问新的URL。
302 Found 类似于301，但新的URL应该被视为临时性的替代，而不是永久性的。
304 Not Modified 客户端有缓冲的文档并发出了一个条件性的请求（一般是提供If-Modified-Since头表示客户只想比指定日期更新的文档）。服务器告诉客户，原来缓冲的文档还可以继续使用。
401 Unauthorized
403 Forbidden
404 Not Found
414 Request URI Too Long URI太长（HTTP 1.1新）。这就是上面说的Http的GET请求的url长度是有限制的，是服务器方做出的限制
500 Internal Server Error
502 Bad Gateway 服务器作为网关或者代理时，为了完成请求访问下一个服务器，但该服务器返回了非法的应答。
503 Service Unavailable 服务器由于维护或者负载过重未能应答。例如，Servlet可能在数据库连接池已满的情况下返回503。服务器返回503时可以提供一个Retry-After头。就是服务器扛不住了的意思
504 Gateway Timeout 由作为代理或网关的服务器使用，表示不能及时地从远程服务器获得应答。（HTTP 1.1新）

[http状态码451](https://juejin.im/entry/5770d05a2e958a0078f1d730)，由于法律上的原因不能显示网页内容

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

注意上面的“path=/”
document.cookie = "username=cfangxu;path=/;domain=qq.com"
如上：“www.qq.com" 与 "sports.qq.com" 公用一个关联的域名"qq.com"，我们如果想让 "sports.qq.com" 下的cookie被 "www.qq.com" 访问，我们就需要用到 cookie 的domain属性，并且需要把path属性设置为 "/"。
[cookie还有domain和path的概念](https://segmentfault.com/a/1190000012578794)


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
<!-- 示例 : Accept:image/webp,image/apng,image/*,*/*;q=0.8 -->

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
no-store 所有内容都不会被缓存到缓存或 Internet 临时文件中(和no-cache相比，“no-store”则要简单得多。它直接禁止浏览器以及所有中间缓存存储任何版本的返回响应，例如，包含个人隐私数据或银行业务数据的响应。每次用户请求该资产时，都会向服务器发送请求，并下载完整的响应。发现虽然设置了no-cache，但是没有设置ETag可以进行校验，最终还是从缓存里读取)。有些敏感信息，用户账户列表这种，就应该完全不缓存在本地。
max-age=xxx (xxx is numeric) 缓存的内容将在 xxx 秒后失效, 这个选项只在HTTP 1.1可用, 并如果和Last-Modified一起使用时, 优先级较高

实际过程中我看到了这种：
Cache-Control:private, no-cache, no-cache=Set-Cookie, no-store, proxy-revalidate，must-revalidate....

而浏览器的前进后退，默认会从缓存里读取，完全不发请求。

缓存的优先级是：
1. 先看缓存是否过期
2. 发送Etag(如果有的话，服务器决策时304还是200)，发送If-None-Match
3. 如果有Last-Modified的话，发送If-Modified-Since。
4. 上述都失效的话，就当是全新的请求

- Connection:keep-alive  http1.1 默认为keep-alive
http 1.0需要手动设置。原理就是服务器保持客户端到服务器的连接持续有效，避免了重新建立连接的开销(tcp三次握手)。这种情况下，客户端不能根据读取到EOF(-1)来判断传输完毕。有两种解决方案：对于静态文件，客户端和服务器能够知道其大小，使用content-length，根据这个判断数据是否已经接收完成；对于动态页面，不可能预先知道内容大小。可以使用Transfer-Encoding:chunked的模式进行传输。基本上就是服务器把文件分成几块，一块一块的发送过去。[参考](https://www.byvoid.com/zhs/blog/http-keep-alive-header)

- Content-Type  代表文件类型。request只有POST请求中会有，Response中也会有。
POST里面的Content-type有两种:
一： Content-type: application/x-www-form-urlencoded;charset:UTF-8 //缺省值，表示提交表单。只能传键值对。
比如
>tel=13637829200&password=123456

二： multipart/form-data //上传文件时用这种，既可以发送文本数据，也支持二进制上传。上面那个CharSet只是为了告诉服务器用的是哪种编码，能传二进制。
比方说
```text
------WebKitFormBoundaryw0ZREBdOiJbbwuAg
Content-Disposition: form-data; name="uploads[]"; filename="278a516893f31a16feee.jpg"
Content-Type: image/jpeg


------WebKitFormBoundaryw0ZREBdOiJbbwuAg--
```

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

Vary比较有意思：
server端每次接收到一个请求，会根据request的一些特定属性来确认之前有没有别的客户请求过同样的资源，要是有的话，直接返回就好了。而这个判定是否请求的同一个资源的标准就是Vary(上一次Response中会返回{Vary:Accept-Encoding,Vary:"SomeCustomHeaerKey"})，vary可以写多个。从百度的Response来看，一般这个值设定为Accept-Encoding就好了。
经常使用Vary: Accept-Encoding的一个原因是，有些客户端不支持gzip。Accept-Encoding一般长这样：
>Accept-Encoding:gzip,deflate,sdch
所以缓存服务器要是把gzip的资源发给了不支持gzip的客户端，那就是错误了。增加 Vary: Accept-Encoding 响应头，上游服务明确告知缓存服务器按照 Accept-Encoding 字段的内容，分别缓存不同的版本；nginx里面加上这一条就好了：gzip_vary on;[mozilla对于Vary这个header的描述是这样的，这个属于content-negotiation的一部分](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Headers/Vary).
所以这个Header是后端服务器写给缓存服务器看的，顺带暴露在客户端里面了.关于content-negotation，无非两种，服务端列出多项选择（这份资源可用版本的列表），返回Http300(multiple choices)这个header，让前端自己去选。另一种就是后台根据前段发来的request中的一些信息做出选择（server-driven negotiation，主要看Accept，Accept-Charset,Accept-Encoding,Accept-Language这些东西）。所以常常会看到请求中**Accept-Language: zh-CN,zh;q=0.9** 这个q表示有多少的权限，所以这个比重应该是参与了content-negotiation的计算。

[Vary:Origin和CORS的关系](https://zhuanlan.zhihu.com/p/38972475)
CORS请求会带上Origin请求头，用来向别人的网站表明自己是谁。Vary: Origin可以让同一个URL请求根据ORIGIN这个请求头返回不同的缓存版本。
实践中，如果Access-Control-Allow-Origin的响应头不是写成了*号的话，就应该加上Vary: Origin，以此避免不同的Origin获得的缓存版本错乱。

[WikI上比较完整](https://zh.wikipedia.org/wiki/HTTP%E5%A4%B4%E5%AD%97%E6%AE%B5)

**Transfer-Encoding: chunked 有时候要传输的Content-Length实在太大，服务器计算长度需要开很大的Buffer，干脆把文件分块传输。**
[wiki的解释](https://zh.wikipedia.org/wiki/%E5%88%86%E5%9D%97%E4%BC%A0%E8%BE%93%E7%BC%96%E7%A0%81)，注意此时content-length无效。
[浏览器对于缓存的实际处理](http://www.jianshu.com/p/fd00f0d02f5f)，是否过期由Cache-Control标识的max-age和Expires判断。Cache-Control的优先级较高。[From Chrome](https://developers.google.com/web/fundamentals/performance/optimizing-content-efficiency/http-caching?hl=zh-cn)
简单来说就是先看客户端是否Expire，然后去服务器看下Etag,最后看Last-Modified那个。

[一个response里面出现多个相同的key的header是符合标准的](https://stackoverflow.com/questions/4371328/are-duplicate-http-response-headers-acceptable)

[实际的例子](https://docs.oracle.com/javase/tutorial/deployment/jar/basicsindex.html)
```
X-Akamai-Session-Info: name=ADVPF_PREFETCHABLE_TRACE; value=docs.oracle.com: TDCOUPLED ANY
X-Akamai-Session-Info: name=ENABLE_SD_POC; value=yes
X-Akamai-Session-Info: name=NL_22357_ORACLEDEVELOPERIPBLOCKL_NAME; value=Oracle Developer IP Block List
X-Akamai-Session-Info: name=AKA_PM_NETSTORAGE_ROOT; value=/319188
X-Akamai-Session-Info: name=AKA_PM_SR_NODE_ID; value=0
X-Akamai-Session-Info: name=FASTTCP_RENO_FALLBACK_DISABLE_OPTOUT; value=on
X-Akamai-Session-Info: name=ADVPF_PREFETCHABLE_CATEGORY; value=TDCOUPLED_ANY
X-Akamai-Session-Info: name=PMUSER_COUNTRY_CODE; value=CN; full_location_id=country_code
X-Akamai-Session-Info: name=NL_23268_ORACLESHOPIPBLOCKLIST_NAME; value=Oracle Shop IP Block List
```
实际的效应等同于将所有的values filed用逗号分隔之后串在一起丢在一个header后面。

from wiki page: Akamai是一家总部位于美国马萨诸塞州剑桥市的内容分发网络和云服务提供商，是世界上最大的分布式计算平台之一，承担了全球15-30%的网络流量。


补上一个http statuscode = 302的实际例子吧，今晚看腾讯新闻的时候抓到的
```
Request URL:http://tdd.3g.qq.com/17421/e8475fe7-7418-43bf-9be7-c6b116730cac.gif?a=0.33637654883709955&b=1511790303321
Request Method:GET
Status Code:302 Found
Remote Address:123.151.152.123:80
Referrer Policy:no-referrer-when-downgrade


Request Header
Accept:image/webp,image/apng,image/*,*/*;q=0.8
Accept-Encoding:gzip, deflate
Accept-Language:zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7
Connection:keep-alive
Cookie:XX=SDSDSADSA0; SADSAD=21FDGFDGF; //cookie是我编的
DNT:1
Host:tdd.3g.qq.com
Referer:http://new.qq.com/omn/20171127A0OHHD00
User-Agent:Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.62 Safari/537.36

Response Header
Cache-Control:max-age=0
Connection:close
Content-Length:0
Date:Mon, 27 Nov 2017 13:45:04 GMT
Expires:Mon, 27 Nov 2017 13:45:04 GMT
Location:http://210.22.248.167/tdd.3g.qq.com/17421/e8475fe7-7418-43bf-9be7-c6b116730cac.gif?mkey=5a1c30156df5812a&f=4f20&c=0&a=0.33637654883709955&b=1511790303321&p=.gif //注意这个新的location
Server:nws 1.2.15
```


## 4. Cookie和Session

### 4.1 Cookie
先看[Wiki](https://zh.wikipedia.org/wiki/Cookie)上的解释:
- 指某些网站为了辨别用户身份而储存在用户本地终端（Client Side）上的数据（通常经过加密.主要是因为Http是无状态的，服务器不知道这一次连接和上一次连接是不是同一个客户端
Cookie总是保存在客户端中，按在客户端中的存储位置，可分为内存Cookie和硬盘Cookie。内存Cookie由浏览器维护，保存在内存中，浏览器关闭后就消失了，其存在时间是短暂的。硬盘Cookie保存在硬盘里，有一个过期时间，除非用户手工清理或到了过期时间，硬盘Cookie不会被删除，其存在时间是长期的。所以，按存在时间，可分为非持久Cookie和持久Cookie。

Cookie的一些缺点，直接照搬WiKi了
- Cookie会被附加在每个HTTP请求中，所以无形中增加了流量。(其实这里面只应该放“每次请求都要携带的信息”)
- 由于在HTTP请求中的Cookie是明文传递的，所以安全性成问题。（除非用HTTPS）
- Cookie的大小限制在4KB左右。对于复杂的存储需求来说是不够用的。
- 一个域名下存放的cookie的个数是有限制的，不同的浏览器存放的个数不一样,一般为20个。

cookie也可以设置过期的时间，默认是会话结束的时候，当时间到期自动销毁

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

因为sessionid一般是保存在cookie里面的，而且对应的cookie的key多半是session_id这样（百度首页的叫做BIDUPSID），这就出现了很多从cookie里面拿session_id去伪造身份的xss劫持session。（其实做法很简单：就是一段js去拿document.cookie，然后ajax偷偷上传这个session_id）：
防范的手段也很常见了：
1.过滤用户输入，防止xss漏洞
2.设置session_id这个cookie为http_only

[session在express js中是这么维护的](http://wiki.jikexueyuan.com/project/node-lessons/cookie-session.html)
> 这意思就是说，当你浏览一个网页时，服务端随机产生一个 1024 比特长的字符串，然后存在你 cookie 中的 connect.sid 字段中。当你下次访问时，cookie 会带有这个字符串，然后浏览器就知道你是上次访问过的某某某，然后从服务器的存储中取出上次记录在你身上的数据。由于字符串是随机产生的，而且位数足够多，所以也不担心有人能够伪造。伪造成功的概率比坐在家里编程时被邻居家的狗突然闯入并咬死的几率还低。

### 4.3 自动登录的实现
一些网站的“记住密码，自动登录功能”，据说discuz直接将加密的（可逆）uid和密码保存到cookie中。
另外一种做法是可以尝试将Session的过期时间设置的长一点，比如一年，下次访问网站的时候就能实现自动登录了。
更好一点的是是本地绝不保存用户敏感信息，登录生成一个有过期时间的的cookie或者token返回给客户端，下次打开浏览器判断下过期时间就好了。另外，现在浏览器大多带有记住密码的功能，这个锅还是丢给浏览器(用户)好了。

关于Token
[django jwt直接把token放在header里](https://chrisbartos.com/articles/how-to-implement-token-authentication-with-django-rest-framework/)。其实token也就是放在header中的一个key-value
```
GET /polls/api/questions/1 HTTP/1.1
Host: localhost:8000
Content-Type: application/json
Authorization: Token 93138ba960dfb4ef2eef6b907718ae04400f606a
Cache-Control: no-cache
Postman-Token: ddc99b57-f703-4d05-abbe-c0123d4f5fed
```
注意这个Authorization,后面的value是Token***加上一个空格*** 再加上一长段加密字符串。每一次请求需要认证的接口都得把这个token带上。所以在postman里面调试的话，每次请求都得手动加上这样一个HEADER。postman里面有authentication的选项，但好像都不是这种（目测bearerToken有点像）。所以得手动加上。

论Token为什么要[放在内存里](https://segmentfault.com/a/1190000013010835)
> 为了解决在操作过程不能让用户感到 Token 失效这个问题，有一种方案是在服务器端保存 Token 状态，用户每次操作都会自动刷新（推迟） Token 的过期时间——Session 就是采用这种策略来保持用户登录状态的。然而仍然存在这样一个问题，在前后端分离、单页 App 这些情况下，每秒种可能发起很多次请求，每次都去刷新过期时间会产生非常大的代价。如果 Token 的过期时间被持久化到数据库或文件，代价就更大了。所以通常为了提升效率，减少消耗，会把 Token 的过期时保存在缓存或者内存中。

这篇文章顺便提到了如果在Token过期的时候去实现重刷Token的操作，首先客户端**绝对不会**存账户密码这种敏感信息。第一次登录成功后，后台返回token(有一定时长有效期)和一个refreshToken(如果前面的token失效了，直接拿着这个去请求后台给个新的Token)。所以客户端基本上就是在onError里面判断如果是Token失效的话，拿着refreshToken去重新获取Token。

token的话，一般是和用户一一对应的， 放在http的header里也行，放在cookie里面也行（不大好，CSRF漏洞），放在post请求的body里面也行。

[session和简单的token本质上都是一串加密的字符串](https://segmentfault.com/q/1010000008903882)，只不过session一般放cookie里面，浏览器对这个支持比较好，android和ios一般不会一直维护一个webview专门用来存session_id，所以用token比较合适。[v2上有人讨论session和token的区别](https://www.v2ex.com/t/148426)。但要是说oAuth Token，这还是比session复杂得多的。



## 5. 长连接
像即时通讯软件，或者消息推送这种场景，都得维护一个长连接。
[HTTP长连接和短连接](http://blog.csdn.net/mr_liabill/article/details/50705130)


### 5.1长连接的实现原理
- 轮询
- 维护长连接的心跳(心跳的目的很简单：通过定期的数据包，对抗NAT超时)
- Tcp长连接


HTTP1.1规定了默认保持长连接（HTTP persistent connection ，也有翻译为持久连接），数据传输完成了保持TCP连接不断开（不发RST包、不四次握手），等待在同域名下继续用这个通道传输数据；相反的就是短连接。
TCP的keep alive是检查当前TCP连接是否活着；HTTP的Keep-alive是要让一个TCP连接活久点。它们是不同层次的概念。
TCP keep alive的表现：
当一个连接“一段时间”没有数据通讯时，一方会发出一个心跳包（Keep Alive包），如果对方有回包则表明当前连接有效，继续监控。
Http长连接不如说tcp长连接,Tcp是可以不断开的，http连接服务器给到response之后就断开了。[TCP连接](http://www.cnblogs.com/zuoxiaolong/p/life49.html)Http不过是做了tcp连接复用,http通道是一次性的，tcp不是的，这样做也是为了节省tcp通道。
长连接就是Connection  keep-Alive那玩意，客户端和服务器都得设置才有效。
长短轮询的间隔是服务器通过代码控制的。

> TCP 长连接是一种保持 TCP 连接的机制。当一个 TCP 连接建立之后，启用 TCP Keep Alive 的一端便会启动一个计时器，当这个计时器到达 0 之后，一个 TCP 探测包便会被发出。这个 TCP 探测包是一个纯 ACK 包，但是其 Seq 与上一个包是重复的。
打个比喻，TCP Keep Alive 是这样的：
TCP 连接两端好比两个人，这两个人之间保持通信往来（建立 TCP 连接）。如果他俩经常通信（经常发送 TCP 数据），那这个 TCP 连接自然是建立着的。但如果两人只是偶尔通信。那么，其中一个人（或两人同时）想知道对方是否还在，就会定期发送一份邮件（Keep Alive 探测包），这个邮件没有实质内容，只是问对方是否还在，如果对方收到，就会回复说还在（对这个探测包的 ACK 回应）。
需要注意的是，keep alive 技术只是 TCP 技术中的一个可选项。因为不当的配置可能会引起诸如一个正在被使用的 TCP 连接被提前关闭这样的问题，所以默认是关闭的

短连接： 每个连接的建立都是需要资源消耗和时间消耗.短连接都是连接建立后，client向server发送消息，server回应client，一次读写完成。连接的任意一方都可以关闭连接，一般是client主动关闭。前端网页一般用短连接，一个网页会发很多请求，如果这些全部作为长连接保留下来，服务器扛不住。这也就突出了短连接的好处，管理方便。

长连接：区别于短连接的是，完成一次读写后，后续的读写操作都继续使用这个连接。存在的问题是，如果一直保持着连接，服务器可能被拖垮，这时候可以限制单用户的最大连接数。长连接一般用于操作频繁，点对点的通讯，且连接数不能太多的情况。因为没有了耗时的三次握手及断开，适用于比较及时的应用场景。例如，与数据库的连接用长连接，短连接频繁的操作会造成Socket错误，并且频繁的Socket创建也是对操作系统资源的浪费。




### 5.2 keep-Alive和WebSocket的区别


![](http://odzl05jxx.bkt.clouddn.com/ed541bc1ed61ead0bf6ea8233ef01c0a.jpg?imageView2/2/w/600)


### 5.3 http2可以实现推送了

### 5.4 Http这玩意就不是为了视频流设计的
[HTTP wasn't really designed for streaming](https://stackoverflow.com/questions/14352599/how-to-send-chunks-of-video-for-streaming-using-http-protocol)


### 5.5 主流浏览器浏览器默认最大并发连接数
浏览器不可能同时发起10000个请求，所以主流浏览器都设定了限制,主要是http1.1,http2的话，只有一条connection。
[解释](https://www.zhihu.com/question/20474326)

### 5.6 TLS,SSL
https = Hyper Text Transfer Protocol over Secure Socket Layer 。是以安全为目标的http通道，简单讲是HTTP的安全办，即http下假如SSL层，HTTPS安全的基础是SSL。
https是可能被劫持的，只要导入了一个不知名的根证书


### 5.7 什么叫 Pipeline 管线化
 HTTP1.0 不支持管线化，同一个连接处理请求的顺序是逐个应答模式，处理一个请求就需要耗费一个 TTL，也就是客户端到服务器的往返时间，处理 N 个请求就是 N 个 TTL 时长。当页面的请求非常多时，页面加载速度就会非常缓慢。
 从 HTTP1.1 开始要求服务器支持管线化，可以同时将多个请求发送到服务器，然后逐个读取响应。这个管线化和 Redis 的管线化原理是一样的，响应的顺序必须和请求的顺序保持一致。


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

运营商劫持有两种：DNS劫持(这个都懂)和数据劫持(在返回的内容中强行插入广告等其他内容，这种一般是对http下手)
客户端反DNS劫持的手段(ip直连)： [遭遇DNS劫持](https://github.com/cheyiliu/All-in-One/wiki/%E9%81%AD%E9%81%87DNS%E5%8A%AB%E6%8C%81)
> IP直连，httpdns的原理非常简单，主要有两步：A、客户端直接访问HttpDNS接口(直接用ip地址访问)，获取业务在域名配置管理系统上配置的访问延迟最优的IP。（基于容灾考虑，还是保留次选使用运营商LocalDNS解析域名的方式）B、客户端向获取到的IP后就向直接往此IP发送业务协议请求。以Http请求为例，通过在header中指定host字段，向HttpDNS返回的IP发送标准的Http请求即可。
https，注意https是解决链路劫持的方案，并无法解决DNS劫持的问题。https安全但性能稍差

WebView中反运营商DNS劫持的手段


[今日头条、小米、腾讯等六公司联合抵制流量劫持 已有多项证据直接指向某些机构](http://finance.sina.com.cn/stock/t/2015-12-25/doc-ifxmxxst0459707.shtml)

### 8.Fiddler抓包
- 手机和电脑连接同一个wifi
- 从https://www.telerik.com/download/fiddler 下载Fiddler
- 启动并配置: Tools->Fiddler->Connections, check "allow remote computers to connect" and default port is 8888
- 配置手机：选择连接的网络->修改网络->代理设置:手动; 代理服务器主机名为电脑的ip，端口8888，ip DHCP
- 抓包查看


### 9.Ajax和jQuery发起POST请求的时候设置的Content-Type对于服务器很重要
[AJAX POST请求中参数以form data和request payload形式在servlet中的获取方式](http://blog.csdn.net/mhmyqn/article/details/25561535)
> 最近在看书时才真正搞明白，服务器为什么会对表单提交和文件上传做特殊处理，因为表单提交数据是名值对的方式，且Content-Type为application/x-www-form-urlencoded，而文件上传服务器需要特殊处理，普通的post请求（Content-Type不是application/x-www-form-urlencoded）数据格式不固定，不一定是名值对的方式，所以服务器无法知道具体的处理方式，所以只能通过获取原始数据流的方式来进行解析。
jquery在执行post请求时，会设置Content-Type为application/x-www-form-urlencoded，所以服务器能够正确解析，而使用原生ajax请求时，如果不显示的设置Content-Type，那么默认是text/plain，这时服务器就不知道怎么解析数据了，所以才只能通过获取原始数据流的方式来进行解析请求数据。

===========================trash here=====================================
经常说的网速 bps (bits per second)，所以跟byte比起来，要除以8。1024kbps的带宽就意味着每秒传递的数据大小为1024/8=128KB。
1024s就是128MB（这下清楚了）


[css sprites在http2的环境下并不完全无效](https://stackoverflow.com/questions/32160790/does-using-image-sprites-make-sense-in-http-2)

一些优化
[TTFB] TTFB（Time To First Byte），客户端发出请求到收到响应的第一个字节所花费的时间。一般浏览器里面都能看到，这也是服务端可以优化的指标。

GZip压缩文本还可以，图片就没必要开压缩了，因为图片本身就高度压缩了，再压只是浪费CPU。

网络协议，架构，规范，spdy,http2,url规范.
OSI七层网络体系结构 ： 物理层(IEEE 802.2)、数据链路层(ARP,RARP)、网络层(ip,icmp)、传输层(tcp,udp)、表示层、会话层(SSL,TLS)、应用层(HTTP,FTP,SMTP,POP3).
这里面Socket比较特殊，Socket是一组编程接口（API）。介于传输层和应用层，向应用层提供统一的编程接口。应用层不必了解TCP/IP协议细节。直接通过对Socket接口函数的调用完成数据在IP网络的传输。

**OSI Model**
> 7 - application /  firefox/chrome/email/HTTP
6 - Presentation OS / letters$numbers -> ASCII
5 - Session / Conversation between computers
4 - Transport / Packets are delived reliably(比如发送顺序和接受顺序一致)
3 - Network / Dtetermine best route for data
2 - Data link / NICS's(Network interface cards) checking for errors(比如switches)
1 - Physical Cabel / fiber optic cable / electronic signals

[论https位于osi的第几个层级](https://security.stackexchange.com/questions/19681/where-does-ssl-encryption-take-place)The SSL protocol is implemented as a transparent wrapper around the HTTP protocol. In terms of the OSI model, it's a bit of a grey area. It is usually implemented in the application layer, but strictly speaking is in the session layer.

Modem(调制解调器)：
调制解调器是一种计算机硬件，它能把计算机的数字信号翻译成可沿普通电话线传送的模拟信号，而这些模拟信号又可被线路另一端的另一个调制解调器接收，并译成计算机可懂的语言。这一简单过程完成了两台计算机间的通信(电流变化-> 无线电 这个过程叫做调制，无线电引起电磁场变化从而产生电流变化，这个过程叫做解调)。电信办宽带经常送的光猫的学名叫做
**光网络终端**
（俗称光猫或光modem），是指通过光纤介质进行传输，将光信号调制解调为其他协议信号的网络设备。光猫设备作为大型局域网、城域网和广域网的中继传输设备。不同于光纤收发器，光纤收发器只是收光和发光，不涉及到协议的转换。其实就是把0110这些二进制转换成在光纤中传输的光信号。

HLS直播流慢(延迟高)是因为基于HTTP，(http live streaming，苹果提出的)
如果要低延迟还得rmtp

应用层面的Http，SMTP,FTP,POP,TLS/SSL,IMAP

tcp三次握手，四次挥手
在UDP中，每次发送数据报时，需要附带上本机的socket描述符和接收端的socket描述符。而由于TCP是基于连接的协议，在通信的socket对之间需要在通信之前建立连接，因此会有建立连接这一耗时存在于TCP协议的socket编程。

在UDP中，数据报数据在**大小上有64KB**的限制。
而TCP中也不存在这样的限制。一旦TCP通信的socket对建立了连接，他们之间的通信就类似IO流，所有的数据会按照接受时的顺序读取。

UDP是一种不可靠的协议，发送的数据报不一定会按照其发送顺序被接收端的socket接受。
然而TCP是一种可靠的协议。接收端收到的包的顺序和包在发送端的顺序是一致的。

TCP适合于诸如远程登录(rlogin,telnet)和文件传输（FTP）这类的网络服务。因为这些需要传输的数据的大小不确定。而UDP相比TCP更加简单轻量一些。UDP用来实现实时性较高或者丢包不重要的一些服务。在局域网中UDP的丢包率都相对比较低。


tls,https加密过程，sha1和sha256加密算法

ping ,traceRouter

***tcp三次握手四次挥手，用人话说：***
因为HTTP是一个基于TCP的协议,而TCP是一种可靠的传输层协议.建立TCP连接时会发生:
三次握手(three-way handshake)
firefox > nginx [SYN] 在么
nginx > firefox [SYN, ACK] 在
firefox > nginx [ACK] 知道了

关闭TCP连接时会发生:四次挥手(four-way handshake)
firefox > nginx [FIN] 我要关闭连接了
nginx > firefox [ACK] 知道了,等我发完包先
nginx > firefox [FIN] 我也关闭连接了
firefox > nginx [ACK] 好的,知道了

几个报文的标识的解释:SYN: synchronization(同步)ACK: acknowledgement(确认:告知已收到)FIN: finish(结束)

作者：eechen
链接：https://www.zhihu.com/question/67772889/answer/257170215
来源：知乎
著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。


### 开启浏览器内支持webp[关于WebP接入方案](https://www.xuanfengge.com/webp-access-scheme.html)


[单个网卡最多65535个端口](https://www.google.com/search?q=%E5%8D%95%E4%B8%AA%E7%BD%91%E5%8D%A1%E6%9C%80%E5%A4%9A65535%E4%B8%AA%E7%AB%AF%E5%8F%A3)
2的16次方 = 65536。 2的32次方 = 4GB（大致是32位系统不能识别4G以上内存的原因）
[wiki上对于tcp的解释](https://en.wikipedia.org/wiki/Transmission_Control_Protocol)描述了一个数据包的结构中，前两个byte(16个bit，2的16次方)用于存储source port，第16-31个byte存储destination port(依旧是2个bytes，2的16次方)。这也就是65536个端口限制的由来。

[短网址(short URL)系统的原理及其实现](https://segmentfault.com/a/1190000012088345)
>301 是永久重定向，302 是临时重定向。短地址一经生成就不会变化，所以用 301 是符合 http 语义的。同时对服务器压力也会有一定减少。
但是如果使用了 301，我们就无法统计到短地址被点击的次数了。而这个点击次数是一个非常有意思的大数据分析数据源。能够分析出的东西非常非常多。所以选择302虽然会增加服务器压力，但是我想是一个更好的选择。

[Android微信智能心跳方案](https://mp.weixin.qq.com/s?__biz=MzAwNDY1ODY2OQ==&mid=207243549&idx=1&sn=4ebe4beb8123f1b5ab58810ac8bc5994)
[为什么基于TCP的应用需要心跳包（TCP keep-alive原理分析）](http://hengyunabc.github.io/why-we-need-heartbeat/)


ipv6 ping6
## 参考
- [谈谈HTTP协议中的短轮询、长轮询、长连接和短连接](http://www.cnblogs.com/zuoxiaolong/p/life49.html)
- [http请求的TCP瓶颈](https://bhsc881114.github.io/2015/06/23/HTTP%E8%AF%B7%E6%B1%82%E7%9A%84TCP%E7%93%B6%E9%A2%88%E5%88%86%E6%9E%90/)
- [Restfull架构详解](http://www.runoob.com/w3cnote/restful-architecture.html)
- [文件断点续传原理,CountdownLatch](http://blog.csdn.net/zhuhuiby/article/details/6725951)
- [断点续传实现](http://lcodecorex.github.io/2016/08/01/%E6%96%87%E4%BB%B6%E5%88%86%E7%89%87%E4%B8%8E%E6%96%AD%E7%82%B9%E7%BB%AD%E4%BC%A0%E5%8E%9F%E7%90%86%E4%B8%8E%E5%85%B7%E4%BD%93%E5%AE%9E%E7%8E%B0/)
- [一张非常好的解释status code的表格](http://www.cnblogs.com/mayingbao/archive/2007/11/30/978530.html)
- [tcp-ip较好的解释](https://juejin.im/entry/5a20ca8f5188254dd936320b)
- [基本算是计算机网络教程的](https://juejin.im/post/5a2614b8f265da432652af7d)
- [C10K问题](https://medium.com/@chijianqiang/%E7%A8%8B%E5%BA%8F%E5%91%98%E6%80%8E%E4%B9%88%E4%BC%9A%E4%B8%8D%E7%9F%A5%E9%81%93-c10k-%E9%97%AE%E9%A2%98%E5%91%A2-d024cb7880f3)


[服务器常用端口以及TCP/UDP端口列表](https://wsgzao.github.io/post/service-names-port-numbers/)

tcp dump + wireShark抓包
[详细教程](http://www.trinea.cn/android/tcpdump_wireshark/)


httpOnly：浏览器里面用js去调用document.cookie这个api时就不会拿到这个被设置了httponly的cookie了
```
Set-Cookie: =[; =]
[; expires=][; domain=]
[; path=][; secure][; HttpOnly]
```
HttpOnly就是在设置cookie时接受这样一个参数，一旦被设置，在浏览器的document对象中就看不到cookie了,主要是为了避免（cross-site scripting）XSS attack

[cookie 和 session参考](http://wiki.jikexueyuan.com/project/node-lessons/cookie-session.html)
### 签名(signedCookies)
server一般不会在client端cookie中保留敏感信息，所以比方说我们要存一个user_id，正常也应该存在session中（后台的redis根据请求头中的session_id自己去找）。假如非要存client端的cookie中，可以这么干：
sever端保留一段随机的String，server将用户的user_id(存在后台)用sha1算法加密
比如
```js
var secret = "some_very_important_key"; // 这段secret越长，暴力破解的难度越大
function sha1(real_user_id){
    return sha1(secret+real_user_id);
}
```
实际使用中:
user_id： John Doe
即 "some_very_important_keyJohn Doe" = 'a0d63c5c4194a1d2a67b96391d8d52954ac3512e';
[在线sha1工具](http://tool.oschina.net/encrypt?type=2)
所以client端最终保存的是"user_id_signed": "a0d63c5c4194a1d2a67b96391d8d52954ac3512e"
后台收到请求之后，在后台服务的数据库中SELECT * FROM USER_TABLE WHERE user_id_signed = "a0d63c5c4194a1d2a67b96391d8d52954ac3512e";
找到了的话就一切正常，找不到就403；
上述过程即"签名，专业点说，叫 信息摘要算法"。

在yahoo上找到这样的评论:
>SHA1通常不是用來加密資料，而是用來產生資料的特徵碼 (fingerprint)，你是不是用錯演算法啦 ??
是的~~sha-1是不可逆的

也即sha1过程是不可逆的
加密解密需要耗费cpu资源，暴力破解哈希值的成本太高。值得注意的是，上面那个在线加密网站中有些加密方法是可加密可解密(AES)的，有些根本没有解密的选项(SHA1,MD5),有些比较奇怪的(BASE64编码，BASE64解码，BASE64还能将图片转成一大串字符串)；


###  对称加密(cookie-session)
session 可以存在 cookie 中sessionData 中，丢到客户端。
var sessionData = {username: 'alsotang', age: 22, company: 'alibaba', location: 'hangzhou'}
用sha1算法加密之后丢到cookie的
>signedCookies 跟 cookie-session 还是有区别的：
1）是前者信息可见不可篡改，后者不可见也不可篡改
2）是前者一般是长期保存，而后者是 session cookie
cookie-session 的实现跟 signedCookies 差不多。
不过 cookie-session 我个人建议不要使用，有受到回放攻击的危险。
所以最好把cookie session 也丢进缓存

> 初学者容易犯的一个错误是，忘记了 session_id 在 cookie 中的存储方式是 session cookie。即，当用户一关闭浏览器，浏览器 cookie 中的 session_id 字段就会消失。
常见的场景就是在开发用户登陆状态保持时。


### GZIP是需要耗费cpu的，也就是一种以cpu资源换取带宽的策略
> If you keep gzip compression enabled here, note that you are trading increased CPU costs in exchange for your lower bandwidth use. Set the gzip_comp_level to a value between 1 and 9, where 9 requires the greatest amount of CPU resources and 1 requires the least. The default value is 1.


### windows下host文件修改很简单，linux下在/etc/hosts里。
这里面都写了一句映射： localhost : 127.0.0.1 ## the local loopback interface.

### 补上一个在windows上安装curl的方法
[how-do-i-install-set-up-and-use-curl-on-windows](https://stackoverflow.com/questions/9507353/how-do-i-install-set-up-and-use-curl-on-windows)。简单说就是下一个windows x64的版本，然后把curl.exe所在位置添加到环境变量的PATH中，重启cmd就好了。
然后开始测试一些主流网站

126邮箱返回301(Moved Permanently)，同时告诉浏览器去https站点访问
```
curl -v mail.126.com
* Rebuilt URL to: mail.126.com/
*   Trying 220.181.15.150...
* TCP_NODELAY set
* Connected to mail.126.com (220.181.15.150) port 80 (#0)
> GET / HTTP/1.1
> Host: mail.126.com
> User-Agent: curl/7.58.0
> Accept: */*
>
< HTTP/1.1 301 Moved Permanently
< Server: nginx
< Date: Sun, 11 Feb 2018 06:16:02 GMT
< Content-Type: text/html
< Content-Length: 178
< Connection: keep-alive
< Location: https://mail.126.com/
<
<html>
<head><title>301 Moved Permanently</title></head>
<body bgcolor="white">
<center><h1>301 Moved Permanently</h1></center>
<hr><center>nginx</center>
</body>
</html>
* Connection #0 to host mail.126.com left intact
```

wireshark在windows下也能抓包，首先安装，安装好之后如果没有检测出网卡，需要去下载一个[win10pcap](http://www.win10pcap.org/download/)。

wireShark抓包发现，每个package其实就是发送了一大堆hexoDecimal。 开头是本机网卡的mac地址(6个bytes)，紧跟着是ip(src和dst),最后一部分是tcp(包括port等)。
wikipedia上说 **MAC地址共48位（6个字节），以十六进制表示。前24位由IEEE决定如何分配，后24位由实际生产该网络设备的厂商自行指定。** 我已经猜到根据MAC地址识别网卡生产商了。

## NAT超时[这个主要是移动端保活的话题下需要关注的]
因为 IP v4 的 IP 量有限，运营商分配给手机终端的 IP 是运营商内网的 IP，手机要连接 Internet，就需要通过运营商的网关做一个网络地址转换(Network Address Translation，NAT)。简单的说运营商的网关需要维护一个外网 IP、端口到内网 IP、端口的对应关系，以确保内网的手机可以跟 Internet 的服务器通讯。
大部分移动无线网络运营商都在链路一段时间没有数据通讯时，会淘汰 NAT 表中的对应项，造成链路中断。
长连接心跳间隔必须要小于NAT超时时间(aging-time)，如果超过aging-time不做心跳，TCP长连接链路就会中断，Server就无法发送Push给手机，只能等到客户端下次心跳失败后，重建连接才能取到消息。

NAT映射(把192.168.1.xx转换成外部ip和port的方案)

TCP长连接本质上不需要心跳包来维持，因为无论客户端还是服务器都不知道两者之间的额通道是否断开了。心跳包一个主要的作用就是防止NAT超时的。

## 用java实现一个httpClient怎么样?
```java
public class HttpSocketClient {

    private Socket mSocket;

    public static void main(String[] args) {
        HttpSocketClient client = new HttpSocketClient();
        try {
            client.sendGet("www.baidu.com",80,"/");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }


    public HttpSocketClient() {
        this.mSocket = new Socket();

    }

    /** 在百度服务器面前，这就是一个正常的浏览器
     * @param host
     * @param port
     * @param path
     * @throws IOException
     */
    void sendGet(String host, int port, String path) throws IOException {
        SocketAddress dest = new InetSocketAddress(host, port);
        mSocket.connect(dest);
        OutputStreamWriter streamWriter = new OutputStreamWriter(mSocket.getOutputStream());
        BufferedWriter bufferedWriter = new BufferedWriter(streamWriter);

        bufferedWriter.write("GET " + path + " HTTP/1.1\r\n");
        bufferedWriter.write("Host: " + host + "\r\n");
        bufferedWriter.write("Connection: " + "keep-alive" + "\r\n");
        bufferedWriter.write("User-Agent: " + "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.140 Safari/537.36" + "\r\n");
        bufferedWriter.write("Accept: " + "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" + "\r\n");
        bufferedWriter.write("Accept-Language: " + "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7" + "\r\n");
        bufferedWriter.write("\r\n");
        bufferedWriter.flush(); //flush一下很重要，等于说已经写完了


        BufferedInputStream stream = new BufferedInputStream(mSocket.getInputStream());
        BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(stream));
        String line = null;
        while ((line = bufferedReader.readLine())!=null) {
            System.out.println(line);
        }
        bufferedReader.close();
        bufferedWriter.close();
        mSocket.close();
    }

}
```
输出
```
HTTP/1.1 302 Moved Temporarily
Date: Sat, 24 Mar 2018 06:44:20 GMT
Content-Type: text/html
Content-Length: 225
Connection: Keep-Alive
Set-Cookie: BAIDUID=259D5F393E329E8E44651C589037C093:FG=1; expires=Thu, 31-Dec-37 23:55:55 GMT; max-age=2147483647; path=/; domain=.baidu.com
Set-Cookie: BIDUPSID=259D5F393E329E8E44651C589037C093; expires=Thu, 31-Dec-37 23:55:55 GMT; max-age=2147483647; path=/; domain=.baidu.com
Set-Cookie: PSTM=1521873860; expires=Thu, 31-Dec-37 23:55:55 GMT; max-age=2147483647; path=/; domain=.baidu.com
Set-Cookie: BD_LAST_QID=10107339987852007720; path=/; Max-Age=1
P3P: CP=" OTI DSP COR IVA OUR IND COM "
Location: https://www.baidu.com/
Server: BWS/1.1
X-UA-Compatible: IE=Edge,chrome=1

<html>
<head><title>302 Found</title></head>
<body bgcolor="white">
<center><h1>302 Found</h1></center>
<hr><center>65d90fa34a5e777be72b3e20c859c335f9198cc2
Time : Thu Mar 15 16:20:59 CST 2018</center>
</body>
</html>
```
当然因为访问的是http，302是临时重定向，注意上面返回了Location字段，所以是符合规范的


===============================
服务器返回的Sst-Cookie可以像上面一样有很多个。
Set-Cookie: BAIDUID=259D5F393E329E8E44651C589037C093:FG=1; expires=Thu, 31-Dec-37 23:55:55 GMT; max-age=2147483647; path=/; domain=.baidu.com
基本上格式就是： 
> SOMEKEY=SOMEVALUE; expires=某个日期; path="某个路径"; domian="某个主站"

expires,path,domain这些东西都是规范，下一次请求是，只有当这个cookie的domian和path匹配的上才会发送这个Cookie。




m3u8就是很多ts文件的目录
[【腾讯bugly干货分享】HTML 5 视频直播一站式扫盲](https://juejin.im/entry/5779fa798ac24700534921b5)
.m3u8 文件，其实就是以 UTF-8 编码的 m3u 文件，这个文件本身不能播放，只是存放了播放信息的文本文件：