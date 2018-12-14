---
title: tcp和udp包结构分析
date: 2018-12-03 13:42:25
tags: [linux,tools]
---

![](https://www.haldir66.ga/static/imgs/AlanTuringNotebook_EN-AU7743633207_1920x1080.jpg)
<!--more-->

> 多数内容来自[TCP 报文结构](https://jerryc8080.gitbooks.io/understand-tcp-and-udp/chapter2.html)
同一台机器上的两个进程，可以通过管道，共享内存，信号量，消息队列等方式进行通信。通信的一个基本前提是每个进程都有唯一的标识，在同一台机器上，使用pid就可以了。两台不同的计算机之间通信，可以使用**ip地址 + 协议 +协议端口号** 来标识网络中的唯一进程。
tcp用16位端口号来标识一个端口，也就是两个bytes(65536就这么来的)。


什么是报文？
例如一个 100kb 的 HTML 文档需要传送到另外一台计算机，并不会整个文档直接传送过去，可能会切割成几个部分，比如四个分别为 25kb 的数据段。
而每个数据段再加上一个 TCP 首部，就组成了 TCP 报文。
一共四个 TCP 报文，发送到另外一个端。
另外一端收到数据包，然后再剔除 TCP 首部，组装起来。
等到四个数据包都收到了，就能还原出来一个完整的 HTML 文档了。
在 OSI 的七层协议中，第二层（数据链路层）的数据叫「Frame」，第三层（网络层）上的数据叫「Packet」，第四层（传输层）的数据叫「Segment」。
TCP 报文 (Segment)，包括首部和数据部分。

TCP 报文段首部的前20个字节是固定的，后面有 4N 字节是根据需要而增加的。
TCP 的首部包括以下内容：
- 源端口 source port
- 目的端口 destination port
- 序号 sequence number
- 确认号 acknowledgment number
- 数据偏移 offset
- 保留 reserved
- 标志位 tcp flags
- 窗口大小 window size
- 检验和 checksum
- 紧急指针 urgent pointer
- 选项 tcp options


### 连接建立过程
TCP 连接的建立采用客户服务器方式，主动发起连接建立的一方叫客户端（Client），被动等待连接建立的一方叫服务器（Server）。
最初的时候，两端都处于 CLOSED 的状态，然后服务器打开了 TCP 服务，进入 LISTEN 状态，监听特定端口，等待客户端的 TCP 请求。
第一次握手： 客户端主动打开连接，发送 TCP 报文，进行第一次握手，然后进入 SYN_SEND 状态，等待服务器发回确认报文。
这时首部的同步位 SYN = 1，同时初始化一个序号 Sequence Number = J。
TCP 规定，SYN 报文段不能携带数据，但会消耗一个序号。
第二次握手： 服务器收到了 SYN 报文，如果同意建立连接，则向客户端发送一个确认报文，然后服务器进入 SYN_RCVD 状态。
这时首部的 SYN = 1，ACK = 1，而确认号 Acknowledgemt Number = J + 1，同时也为自己初始化一个序号 Sequence Number = K。
这个报文同样不携带数据。
第三次握手：
客户端收到了服务器发过来的确认报文，还要向服务器给出确认，然后进入 ESTABLISHED 状态。
这时首部的 SYN 不再置为 1，而 ACK = 1，确认号 Acknowledgemt Number = K + 1，序号 Sequence Number = J + 1。
第三次握手，一般会携带真正需要传输的数据，当服务器收到该数据报文的时候，就会同样进入 ESTABLISHED 状态。 此时，TCP 连接已经建立。
对于建立连接的三次握手，主要目的是初始化序号 Sequence Number，并且通信的双方都需要告知对方自己的初始化序号，所以这个过程也叫 SYN。
这个序号要作为以后的数据通信的序号，以保证应用层接收到的数据不会因为网络上的传输问题而乱序，因为TCP 会用这个序号来拼接数据。

### TCP Flood 攻击
知道了 TCP 建立一个连接，需要进行三次握手。
但如果你开始思考「三次握手的必要性」的时候，就会知道，其实网络是很复杂的，一个信息在途中丢失的可能性是有的。
如果数据丢失了，那么，就需要重新发送，这时候就要知道数据是否真的送达了。
这就是三次握手的必要性。
但是再向深一层思考，你给我发信息，我收到了，我回复，因为我是君子。
如果是小人，你给我发信息，我就算收到了，我也不回复，你就一直等我着我的回复。
那么很多小人都这样做，你就要一直记住你在等待着小人1号、小人2号、小人3号......直到你的脑容量爆棚，烧坏脑袋。
黑客就是利用这样的设计缺陷，实施 TCP Flood 攻击，属于 DDOS 攻击的一种。


### 四次挥手，释放连接
TCP 有一个特别的概念叫做半关闭，这个概念是说，TCP 的连接是全双工（可以同时发送和接收）的连接，因此在关闭连接的时候，必须关闭传送和接收两个方向上的连接。
客户端给服务器发送一个携带 FIN 的 TCP 结束报文段，然后服务器返回给客户端一个 确认报文段，同时发送一个 结束报文段，当客户端回复一个 确认报文段 之后，连接就结束了。
释放连接过程
在结束之前，通信双方都是处于 ESTABLISHED 状态，然后其中一方主动断开连接。
下面假如客户端先主动断开连接。
第一次挥手：
客户端向服务器发送结束报文段，然后进入 FIN_WAIT_1 状态。
此报文段 FIN = 1， Sequence Number = M。
第二次挥手：
服务端收到客户端的结束报文段，然后发送确认报文段，进入 CLOSE_WAIT 状态。
此报文段 ACK = 1， Sequence Number = M + 1。
客户端收到该报文，会进入 FIN_WAIT_2 状态。
第三次挥手：
同时服务端向客户端发送结束报文段，然后进入 LAST_ACK 状态。
此报文段 FIN = 1，Sequence Number = N。
第四次挥手：
客户端收到服务端的结束报文段，然后发送确认报文段，进入 TIME_WAIT 状态，经过 2MSL 之后，自动进入 CLOSED 状态。
此报文段 ACK = 1, Sequence Number = N + 1。
服务端收到该报文之后，进入 CLOSED 状态。
关于 TIME_WAIT 过渡到 CLOSED 状态说明：
从 TIME_WAIT 进入 CLOSED 需要经过 2MSL，其中 MSL 就叫做 最长报文段寿命（Maxinum Segment Lifetime），根据 RFC 793 建议该值这是为 2 分钟，也就是说需要经过 4 分钟，才进入 CLOSED 状态。


### 可靠性交付的实现
滑动窗口
超时重传
流量控制
拥塞控制

##TBD

关键字： tcp read buffer
> Your Network Interface Card (NIC) is performing all of the necessary tasks of collecting packets and waiting for your OS to read them. Ultimately, when you do a stream read you're pulling from the memory that your OS has reserved and constantly stores the incoming information copy into.
To answer your question, yes. You are definitely doing a copy. A copy of a copy, the bits are read into a buffer within your NIC, your OS puts them somewhere, and you copy them when you do a stream read.


关于tcp read/write buffer，shadowsocks的参数优化提到了一些东西 
```
# max open files
fs.file-max = 1024000
# max read buffer
net.core.rmem_max = 67108864
# max write buffer
net.core.wmem_max = 67108864
# default read buffer
net.core.rmem_default = 65536
# default write buffer
net.core.wmem_default = 65536
# max processor input queue
net.core.netdev_max_backlog = 4096
# max backlog
net.core.somaxconn = 4096

# resist SYN flood attacks
net.ipv4.tcp_syncookies = 1
# reuse timewait sockets when safe
net.ipv4.tcp_tw_reuse = 1
# turn off fast timewait sockets recycling
net.ipv4.tcp_tw_recycle = 0
# short FIN timeout
net.ipv4.tcp_fin_timeout = 30
# short keepalive time
net.ipv4.tcp_keepalive_time = 1200
# outbound port range
net.ipv4.ip_local_port_range = 10000 65000
# max SYN backlog
net.ipv4.tcp_max_syn_backlog = 4096
# max timewait sockets held by system simultaneously
net.ipv4.tcp_max_tw_buckets = 5000
# TCP receive buffer
net.ipv4.tcp_rmem = 4096 87380 67108864
# TCP write buffer
net.ipv4.tcp_wmem = 4096 65536 67108864
# turn on path MTU discovery
net.ipv4.tcp_mtu_probing = 1

# for high-latency network
net.ipv4.tcp_congestion_control = hybla
# forward ipv4
net.ipv4.ip_forward = 1
```
[内核文档对于这些参数的定义](https://www.cyberciti.biz/files/linux-kernel/Documentation/networking/ip-sysctl.txt)



## 参考
[TCP 报文结构](https://jerryc8080.gitbooks.io/understand-tcp-and-udp/)
[tcp包结构](https://www.google.com/search?q=tcp%E5%8C%85%E7%BB%93%E6%9E%84)

[关于tcp协议的一整个series](https://accedian.com/enterprises/blog/tcp-receive-window-everything-need-know/)