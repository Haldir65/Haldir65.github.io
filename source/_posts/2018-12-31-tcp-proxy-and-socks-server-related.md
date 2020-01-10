---
title: tcp-proxy简单实现及socks协议相关
date: 2018-12-31 18:45:38
tags: [python]
---

python实现简易的tcp-proxy server及socks代理学习笔记

![](https://www.haldir66.ga/static/imgs/MountainDayJapan_EN-AU8690491173_1920x1080.jpg)
<!--more-->


首先是基本的流程
本地起一个tcp代理，监听0.0.0.0的1090端口,接收到任何数据之后原封不动发送到远程服务器。接着本机或者局域网内其他机器使用telnet往这个1090端口发数据。这样的proxy其实也就是实质上的一个tcp跳板机。


## 先介绍一下telnet的使用教程
在windows上telnet好像默认关闭了。在mac上：
> telnet 127.0.0.1 1090 // 这句话类似于连接到这个port，但是还没有发送数据。接下来可以发送数据

在mac上ctrl+]是进入命令模式，可以输入一些比较好玩的命令:
比如help，比如quit。
send ayt //原封不动发送are you there 这几个字符
send ? //查看可以使用send发送哪些指令，其实就是发送字符
telnet的输出按删除键是不会清除的，输入cls就可以了。

另外,telnet是明文发送的，ssh会加密一下
Telnet data is sent in clear text. It's certainly a good idea to use SSH to access network devices especially when going through a public network like Internet. As you are probably aware SSH would encrypt all data between the client/server and even if someone gets a hand on the data it's of no use.


### 然后就是如何实现这个本地代理了
1. 本地先绑定一个socket在1090端口
2. 1090端口每次接收到一个新的sock连接，起一个新的线程，去处理和这个新的client的一次会话
3. 在这个会话里面，同时启动两个线程（一个从local client读数据，然后发给remote server；另一个从remote server读取数据，发给local client）
4. 这里面每个会话的remote server都是一个一个固定的ip:port，但是local client的port是变来变去的

看看第三步，其实就是一个往返，所以顺序掉个头就行了，而且彼此互相不干扰（在只有一个会话的时候，remote.recv可以认为就是对当前client.send的回应）
这个往返用代码描述一下就是:

```python
def sock_proxy(remote, local):
    local_request = local.recv(4096) ## 如果local和remote对调一下，这里就是从remote读数据
    ## ....
    remote.sendAll(local_request.encode()) ## 这里就是 GET / HTTP1.1 ...这种字符串，如果local和remote对调一下，就是发数据给local client
```
省略了一些try except和socket.close的代码。上面写了4096，是说最大接收数据量是4096字节，不是一次读取4096个字节的意思。下面是python中这几个函数的定义
```
s.recv(bufsize[,flag])

接受TCP套接字的数据。数据以字符串形式返回，bufsize指定要接收的最大数据量。flag提供有关消息的其他信息，通常可以忽略。

s.send(string[,flag])

发送TCP数据。将string中的数据发送到连接的套接字。返回值是要发送的字节数量，该数量可能小于string的字节大小。

s.sendall(string[,flag])

完整发送TCP数据。将string中的数据发送到连接的套接字，但在返回之前会尝试发送所有数据。成功返回None，失败则抛出异常。
```

具体用什么语言来实现，其实都没什么大的差别了。用Python好在跨平台，代码量少。
- 使用方式
> python tcp_proxy -l 0.0.0.0:1090 -r zhihu.com:80 -v //代码是在别人的基础上改的，直接用别人的argument parser了

意思就是在本地监听1090端口，任何发到本地1090端口的包都会被发到zhihu.com这个host的80端口(测试了下，知乎返回的response是正常的)

本地另外起一个telnet
> telnet 127.0.0.1 1090
> GET / HTTP 1.1 \r\n\r\n //事实上在telnet里面输入换行符有点困难，因为按下回车的时候会顺带在后面加上换行符
...然后这里就会出现远程服务器的回应。

因为直接从client的报文中提取请求信息其实挺没意思的，所以暂时在python代码里写死了发送给远程的content

发现curl原来可以直接往任意host:port发送http格式的请求
> curl localhost:1090


在proxy一侧收到的请求报文：
```
GET / HTTP/1.1
Host: localhost:1090
User-Agent: curl/7.54.0
Accept: */* 

```
最后是有俩换行的

用nc(netcat)也能往1090端口发数据
> nc 127.0.0.1 1090 
GET / HTTP 1.1 \r\n\r\n 这个可以直接打换行，更方便


直接用nc发起http请求
```
printf "GET /status/200 HTTP/1.1\r\nHost: httpbin.org\r\n\r\n" | nc httpbin.org 80

cat <(printf "GET /status/200 HTTP/1.1\r\nHost: httpbin.org\r\nConnection: close\r\n\r\n") | nc httpbin.org 80
```
第一输出报文后，不会断开，第二段直接断开，原因是远程直接断开连接了。

### 接下来就是看如何处理多个client的session(sock5协议实现)
以上实现的只是一个tcp proxy，就是完全不检查通信内容的代理，是直接站在tcp层的。
现实中还有http proxy,sock proxy，彼此之间有一些差别。

多个client或者一个client的多个port同时走这个代理去访问远程时，代理服务器不可避免要记录下client和sever之间的连线，适当的还要在packet里面塞一些标记。业内成熟的方案当然是sock5协议,对应的标准是RFC 1928和RFC 1929。

从wiki上来看sock5是在sock4版本的基础上加了鉴定、IPv6、UDP支持。
> SOCKS工作在比HTTP代理更低的层次：SOCKS使用握手协议来通知代理软件其客户端试图进行的连接SOCKS，然后尽可能透明地进行操作，而常规代理可能会解释和重写报头（例如，使用另一种底层协议，例如FTP；然而，HTTP代理只是将HTTP请求转发到所需的HTTP服务器）。虽然HTTP代理有不同的使用模式，CONNECT方法允许转发TCP连接；然而，SOCKS代理还可以转发UDP流量和反向代理，而HTTP代理不能。HTTP代理通常更了解HTTP协议，执行更高层次的过滤（虽然通常只用于GET和POST方法，而不用于CONNECT方法）。

sock5_protocol协议包括:
协议
协商
客户端首先向SOCKS服务器自己的协议版本号，以及支持的认证方法。SOCKS服务器向客户端返回协议版本号以及选定的认证方法。

认证
客户端根据服务器端选定的方法进行认证，如果选定的方法是02,则根据RFC 1929定义的方法进行认证。RFC 1929定义的密码是明文传输，安全性较差。

请求
一旦指定认证方法的协商过程完成, 客户端发送详细的请求信息。经常使用 SOCKS 代理服务器的同志们会发现一种现象，即使 SOCKS 代理服务器设置正确，某些网站仍然无法访问,一般来说就是DNS污染造成的。SOCKS 5是通过将域名直接提交给 SOCKS 服务器来进行远端 DNS 解析的，即 Address Type 0x03。 DNS 服务是 Internet 的基础服务，要求 DNS 解析应当尽量地快，所以浏览器默认不会使用远端 DNS 解析。在Chrome的SwitchySharp 和Firefox里面的FoxyProxy可以支持远端DNS解析，可以避开DNS污染问题。

sock5协议其实在命令行里就能用上:
> curl --sock5 127.0.0.1:1080 http://www.google.com



整体的流程:
>客户端向服务器发送协议版本号及支持认证方式(在proxy server这边会收到几个字节的bind请求
05 01 00 xxxx)
服务器回应版本号及选定认证方式
客户端发送Connect请求
服务器对Connect的响应
客户端发送被代理的数据
服务器响应被代理的数据


### 所以最终实现的效果是实现使用代理访问知乎
因为走的是明文，这样的代理只是具有学习的性质。更多的需要参考shadowsocks的实现(tcp proxy,支持udp)。
另外，业内比较出名的tcp proxy有nginx，enovy以及[golang tcp proxy](https://github.com/google/tcpproxy)的实现。

## udp proxy的实现
[非常短的一个脚本](https://github.com/EtiennePerot/misc-scripts/blob/master/udp-relay.py)
```python
#!/usr/bin/env python
# Super simple script that listens to a local UDP port and relays all packets to an arbitrary remote host.
# Packets that the host sends back will also be relayed to the local UDP client.
# Works with Python 2 and 3

import sys, socket

def fail(reason):
	sys.stderr.write(reason + '\n')
	sys.exit(1)

if len(sys.argv) != 2 or len(sys.argv[1].split(':')) != 3:
	fail('Usage: udp-relay.py localPort:remoteHost:remotePort')

localPort, remoteHost, remotePort = sys.argv[1].split(':')

try:
	localPort = int(localPort)
except:
	fail('Invalid port number: ' + str(localPort))
try:
	remotePort = int(remotePort)
except:
	fail('Invalid port number: ' + str(remotePort))

try:
	s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
	s.bind(('', localPort))
except:
	fail('Failed to bind on port ' + str(localPort))

knownClient = None
knownServer = (remoteHost, remotePort)
sys.stderr.write('All set.\n')
while True:
	data, addr = s.recvfrom(32768)
	if knownClient is None:
		knownClient = addr
	if addr == knownClient:
		s.sendto(data, knownServer)
	else:
		s.sendto(data, knownClient)
```

### raw socket(原始套接字)

### 优化
server端监听在一个端口，client端发送数据的端口变来变去。数据量大的时候单线程阻塞式的server还是会有性能问题。python中可以使用selectors模块，在server端，每次socket.accept()之后，就register一个fileno for read and write event。
[参考udpRelayServer](https://github.com/linhua55/some_kcptun_tools/blob/master/udpRelay/udpRelayServer.py)
每次selector.select(这个函数是blocking的)，从端口上来看，client这边可以开多个port发数据给proxy， proxy这边只用一个port接受，对外部网络世界多个ip，开多个port。所以proxy内部应该维护一个external port <======> client port 的映射。
开始select之后，首先是select出来一个readable的client socket(port) ，读取信息，存储到一个{ clientport , [clientmessageOutList] } 的字典里。 然后根据clientmessage中暗示的remote ip和port去register一个socket， register的时候是可以带上一些自定义数据的，这里放上clientport. 当这个register的回调开始时，如果是可写，那么把刚才字典里的信息拿出来，del掉。 如果是可读，那么说明发出去的东西有回信了，这时候去自定义数据里面的port，存到一个{clientport, [messageToBeDelivedBackList] } 的字典里。在select本地port的时候，如果扫到一个writabel的client socket port，就根据这个port num 去字典里获取messageToBeDelivedBack，发送回去。到此结束一个流程。
任何时间段，proxy这边维持了两个字典，一头是面向client的，port => [要发送的msg1,要发送的msg2,...] , 一头是面向多个remote ip port组合的的。存储了 clientport => [要回复给client的msg1 ,要回复给client的msg2] . 
面向client只需要做一个selector操作，面向outside需要做多个selector操作（一个外部网站一般一个就够了）。不停的轮询。但实际上只需要一个selector就行了。
```python
try:
    while True:
        events = sel.select(timeout=1)
        if events:
            for key, mask in events:
                service_connection(key, mask) ## key.fileobj是socket, key,data是register的时候自定义的数据
```


[ss的tcp包结构](https://blessing.studio/why-do-shadowsocks-deprecate-ota/)
主动探测方法
[协议与结构](https://loggerhead.me/posts/shadowsocks-yuan-ma-fen-xi-xie-yi-yu-jie-gou.html)


## java里面有一个proxy类，事实上jdk本身对于sock代理是支持的
只不过java自带的proxy类会全局代理，鉴权是对整个jvm生效的。
```java
 Authenticator.setDefault(new Authenticator(){
  protected  PasswordAuthentication  getPasswordAuthentication(){
   PasswordAuthentication p=new PasswordAuthentication("xxx", "xxx".toCharArray());
   return p;
  }
 });
Proxy proxy = new Proxy(Proxy.Type.SOCKS, new InetSocketAddress("xxx.xx.xxx.xxx", xxx));

Socket sock = new Socket(proxy);

sock.connect(new InetSocketAddress(server,xx));
```

The side effect of the SOCKS support in JDK is that your whole JVM will go through the same SOCKS proxy.
The Authenticator affects all authentication in your JVM (HTTP auth, Proxy Auth).

所以等于说接管了整个jvm的请求
okHttp有一个比较友好的方式
```java
Proxy proxy = new Proxy(Proxy.Type.HTTP, new InetSocketAddress("127.0.0.1", 1086));
Authenticator proxyAuthenticator = new Authenticator() {
            @Override
            public Request authenticate(Route route, Response response) throws IOException {
                String credential = Credentials.basic(username, password);
                return response.request().newBuilder()
                        .header("Proxy-Authorization", credential)
                        .build();
            }
        };	
OkHttpClient client = new OkHttpClient().newBuilder().
                connectTimeout(120, TimeUnit.SECONDS).readTimeout(120, TimeUnit.SECONDS).proxy(proxy)
                .proxyAuthenticator(proxyAuthenticator)
				.build()		
```
感觉上像是通过将账户密码放到header里面去做的



SO_REUSEPORT选项支持多个进程同时监听一个port，在内核层面实现流量的负载均衡。（这是socket的一个选项，since linux 3.9）， java从jdk9才添加了支持，[也有hack的方式通过反射调用native方法去设置这个值的](https://colobu.com/2015/06/11/Socket-sharding-implemented-by-netty/)。 例如nginx的master进程和worker进程，例如多个ss-redir[同时监听一个端口](https://github.com/shadowsocks/shadowsocks-libev/issues/493)。


## 参考
[python小工具：tcp proxy和tcp hub](http://ichuan.net/post/22/tcp-proxy-and-tcp-hub-in-python/)
[Writing a simple SOCKS server in Python](https://rushter.com/blog/python-socks-server/)
[SOCKS 5协议简析](https://geesun.github.io/posts/2015/09/socks5_protocol.html)
[shadowsocks-netty](https://github.com/TongxiJi/shadowsocks-java)
[lightsocks-python](https://github.com/linw1995/lightsocks-python)