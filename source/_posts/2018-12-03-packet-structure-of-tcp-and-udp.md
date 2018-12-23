---
title: tcp和udp包结构分析
date: 2018-12-03 13:42:25
tags: [linux,tools]
---

本文只针对ipv4网络进行分析
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

### 这里还只是tcp层面，如果加上tls初始化握手，这个速度会更慢一些
下面从[QUIC 在微博中的落地思考](https://www.infoq.cn/article/2018%2F03%2Fweibo-quic)文中摘抄一部分批判tcp

> TCP 协议在建立连接时，需要经历较为漫长的三次握手行为，而在关闭时，也有稍显冗余的 4 次摆手。而 HTTPS 初始连接需要至少 2 个 RTT 交互（添加了握手缓存就会变成了 1-RTT，这里指的是 TLS 1.2），外加 TCP 自身握手流程，最少需要 3 次 RTT 往返，才能够完整建立连接。而 QUIC 协议层面界定了 1-2 个 RTT 握手流程，再次连接为 0-RTT 握手优化流程（但需要添加握手缓存）


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
注意，这些参数修改了会影响所有的进程，修改还是慎重一些


### tcp buffer
关键字： tcp read buffer and write buffer
这里要分congestion window（发送方的window，对应congestion control）和receive window(接收方的window，对应flow control)
receive window
> Your Network Interface Card (NIC) is performing all of the necessary tasks of collecting packets and waiting for your OS to read them. Ultimately, when you do a stream read you're pulling from the memory that your OS has reserved and constantly stores the incoming information copy into.
To answer your question, yes. You are definitely doing a copy. A copy of a copy, the bits are read into a buffer within your NIC, your OS puts them somewhere, and you copy them when you do a stream read.

用wireshark抓包的话，在tcp header里面有个"window size value"，比方说这个数是2000，也就是发来这个包的一方告诉当前接受方，你下一次最多再发2000byte的数据过来，再多就装不下了。如果接收方处理速度跟不上，buffer慢慢填满，就会在ack包里调低window size，告诉对方发慢一点。
client处理速度够快的时候是这样的
![](https://www.haldir66.ga/static/imgs/TCP-window-syn.png)

如果不够快的话,这时候就是client在ack包里告诉server自己跟不上了
![](https://www.haldir66.ga/static/imgs/TCP-window-http.png)

## TCP Window Scaling
注意，window size是在ack包里的,另外,tcp header里面为这个window size准备的空间是2 bytes（65536 bytes,所以一个包最大也就65K?）。这样对于那些大带宽高延迟的连接来说是不利的。事实当然没这么简单，[RFC 1323](https://www.ietf.org/rfc/rfc1323.txt) enable the TCP receive window to be increased exponentially(指数增长)。这个功能是在握手的时候互相商定了一个增长的倍数(在tcp握手的header里面有一个window size scaling factor,比如下图这样的，一次乘以4)
![](https://www.haldir66.ga/static/imgs/Transmission-control-protocol-window-scaling.png)
> In the image above, the sender of this packet is advertising a TCP Window of 63,792 bytes and is using a scaling factor of four. This means that that the true window size is 63,792 x 4 (255,168 bytes). Using scaling windows allows endpoints to advertise a window size of over 1GB. To use window scaling, both sides of the connection must advertise this capability in the handshake process. If one side or the other cannot support scaling, then neither will use this function. The scale factor, or multiplier, will only be sent in the SYN packets during the handshake and will be used for the life of the connection. This is one reason why it is so important to capture the handshake process when performing TCP analysis.

就是说4这个数只会出现在握手的syn包中，并且只有在双方都能支持scaling的前提下才会用，而且这个4将会在这条连接的生命周期中一直是这个数，所以要分析的话，逮这个syn包去抓。

### TCP Zero window
![](https://www.haldir66.ga/static/imgs/TCP-Zero-Window-Performance-Vision.png)
意思就是说，这个window size变成0了。通常不会出现这种情况，一般是接收方的进程出问题了，这时候server会等着，随着client的应用层开始处理数据，client会慢慢发TCP Keep-Alive包，带上新的window size，告诉server说，自己正在处理数据，快了快了。

> The throughput of a communication is limited by two windows: the congestion window and the receive window. The congestion window tries not to exceed the capacity of the network (congestion control); the receive window tries not to exceed the capacity of the receiver to process data (flow control). The receiver may be overwhelmed by data if for example it is very busy (such as a Web server). Each TCP segment contains the current value of the receive window. If, for example, a sender receives an ack which acknowledges byte 4000 and specifies a receive window of 10000 (bytes), the sender will not send packets after byte 14000, even if the congestion window allows it.
总的来说，tcp传输的速度是由congestion window and the receive window控制的，前者控制发送方的发送速度，后者限制接收方的接收速度。

### 可靠性交付的实现到这里也就清楚了
滑动窗口(sliding window)
超时重传
流量控制 (flow control)
拥塞控制（congestion control）


## 一个tcp,udp或者ip包最大多大，最小多大
最小我们知道
传送TCP数据包的時候，TCP header 占 20 bytes， IPv4 header 占 20 bytes，所以最小40byte。
那么最大呢[TCP、UDP数据包大小的限制](https://blog.csdn.net/caoshangpa/article/details/51530685)
应用层udp最大1500-20-8 = 1472 字节(多了会被分片重组，万一分片丢失导致重组失败，就会被丢包)，1500是硬件决定的,20是ip头，8是udp的头
结论
UDP 包的大小就应该是 1500 - IP头(20) - UDP头(8) = 1472(Bytes)
TCP 包的大小就应该是 1500 - IP头(20) - TCP头(20) = 1460 (Bytes)
UDP数据报的长度是指包括报头和数据部分在内的总字节数，其中报头长度固定，数据部分可变。数据报的最大长度根据操作环境的不同而各异。从理论上说，包含报头在内的数据报的最大长度为65535字节(64K)。
用UDP协议发送时，用sendto函数最大能发送数据的长度为：65535- IP头(20) - UDP头(8)＝65507字节。用sendto函数发送数据时，如果发送数据长度大于该值，则函数会返回错误。  
MTU 最大传输单元（英语：Maximum Transmission Unit，缩写MTU）是指一种通信协议的某一层上面所能通过的最大数据包大小（以字节为单位），怎么看
> ping -l 1472 -f www.baidu.com ##根据提示去调小这个数就是了，一般1350以上是有的

从csdn搞来的图
![](https://haldir66.ga/static/imgs/tcp_and_udp_size_limit.png)
传输层： 
对于UDP协议来说，整个包的最大长度为65535，其中包头长度是65535-20=65515； 
对于TCP协议来说，整个包的最大长度是由最大传输大小（MSS，Maxitum Segment Size）决定，MSS就是TCP数据包每次能够传 
输的最大数据分段。为了达到最佳的传输效能TCP协议在建立连接的时候通常要协商双方的MSS值，这个值TCP协议在实现的时候往往用MTU值代替（需 
要减去IP数据包包头的大小20Bytes和TCP数据段的包头20Bytes）所以往往MSS为1460。通讯双方会根据双方提供的MSS值得最小值 
确定为这次连接的最大MSS值。 
IP层： 
对于IP协议来说，IP包的大小由MTU决定（IP数据包长度就是MTU-28（包头长度）。 MTU值越大，封包就越大，理论上可增加传送速率，但 
MTU值又不能设得太大，因为封包太大，传送时出现错误的机会大增。一般默认的设置，PPPoE连接的最高MTU值是1492, 而以太网 
（Ethernet）的最高MTU值则是1500,而在Internet上，默认的MTU大小是576字节





## 参考
[TCP 报文结构](https://jerryc8080.gitbooks.io/understand-tcp-and-udp/)
[tcp包结构](https://www.google.com/search?q=tcp%E5%8C%85%E7%BB%93%E6%9E%84)
[推广商业软件的文章，当做关于tcp协议的一整个series来看还是很好的](https://accedian.com/enterprises/blog/tcp-receive-window-everything-need-know/) 