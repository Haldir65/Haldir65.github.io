---
title: tcp-nagel-algorithm-and-delay-ack
date: 2018-11-06 13:25:55
tags:
---

Nagle’s Algorithm 和 Delayed ACK 一起用在特定场景下可能会造成网速不必要的延迟
傳送 TCP 封包的時候， TCP header 占 20 bytes， IPv4 header 占 20 bytes，若傳送的資料太小， TCP/IPv4 headers 造成的 overhead (40bytes) 並不划算。想像傳送資料只有 1 byte，卻要另外傳 40 bytes header，這是很大的浪費。若網路上有大量小封包，會占去網路頻寬，可能會造成網路擁塞 。这个是针对发送方而言的。

![](https://api1.foster66.xyz/static/imgs/nature-grass-wet-plants-high-resolution-wallpaper-573f2c6413708.jpg)
<!--more-->


一个TCP数据包的传输至少需要固定的40字节头部信息(20字节TCP + 20字节IP)，如果数据包实际负载都比较小的话，那么传输的效率就非常低，但是如果将这些小包的负载都尽量集中起来，封装到一个TCP数据包中进行传输，那么传输效率势必将会大大提高。此处我们再次强调，TCP传输的是一个字节流，本身不存在所谓的离散形式的数据包的概念，协议可以任意组合、拆分每次调用实际传输的数据长度。



Nagle算法的思路在[wiki](https://zh.wikipedia.org/wiki/%E7%B4%8D%E6%A0%BC%E7%AE%97%E6%B3%95)上也能找到
```
if there is new data to send

  if the window size >= MSS and available data is >= MSS

    send complete MSS segment now

  else

    if there is unconfirmed data still in the pipe

      enqueue data in the buffer until an acknowledge is received

    else

      send data immediately

    end if

  end if

end if
```
如果发送内容大于1个MSS， 立即发送；
如果之前没有包未被确认， 立即发送；
如果之前有包未被确认， 缓存发送内容；
如果收到ack， 立即发送缓存的内容。

概括地说来，其流程表述为：(a)不考虑窗口流量控制的限制，一旦累积的数据达到MSS就立即执行传输；(b)否则如果当前有未ACK的数据，就将数据堆积到发送队列里延迟发送；(c)如果没有待需要ACK的数据，就立即发送。简单说来，就是在数据没有累积到MSS的大小情况下，整个连接中允许有未ACK的数据。
　　Nagel算法本质上就是个时间换带宽的方法，所以对于那些带宽要求不大但对实时性要求高的程序，比如类似网络游戏类，需要使用TCP_NODELAY这个socket选项来关闭这个特性以减小延时发生。不过话外说来，对于这类程序或许使用UDP协议也是个选择。

想象一下，同时丢出去一大堆只有50个字节的包还是会造成带宽的浪费，还不如攒在一起发出去。


在Nagle算法中参数MSS(maximum segment size，IPv4默认值是576-20-20 = 536)
[Maximum_segment_size在wiki上还有专门的介绍](https://en.wikipedia.org/wiki/Maximum_segment_size)

一些关键词：

acknowledged: TCP 傳送封包時會帶有流水號 ，起始值隨機，後面每傳 1 byte 就 +1。對方收到後會回傳 ACK 封包，帶有最後收到 byte 的數字。比方說收到 100 bytes，再收到 200 bytes，只要 ACK「起始值+300」即可。

sliding window: 允許傳送 unacked bytes 的最大值，確保在網路不佳的情況下，傳送端不會傳送過多封包加重擁塞。sliding window 的最大值是 2¹⁶ = 64 (KB)



### Delay ACK
ACK 也是小封包，為了避免產生太多小封包，所以接收端不會每次收到封包都立即發 ACK，如果之後剛好需要送資料 ，順便帶上 ACK去可以省去小封包。實例: telnet server 會回傳使用者剛打的字，順便送 ACK 就可以省去小封包。

Linux的实现在 [__tcp_ack_snd_check](https://github.com/torvalds/linux/blob/master/net/ipv4/tcp_input.c#L5066)这个方法

通常最多延遲 200ms，RFC 規定不能超過 500ms。
每收到兩個 full-sized packet，一定要回一次 ACK。

### 兩者合用的問題
假設傳送端有開 Nagle’s Algorithm，接收端有開 delayed ACK (兩者在 Linux 都是預設值)。

以 HTTP 為例，若 server 的 response 被切成兩次 send，一次送 header，一次送 body，兩者都 <MSS。

server 送完 header 後，因為 client 沒有回 ACK (delayed ACK)，server 也不會送 body (應用層覺得它已經送出了，但 kernel 還沒送)。
client 過了 200ms，送出收到 header 的 ACK。
server 收到 ACK 後，送出 body。
於是 client 多等了 200ms 才收到完整的 response。



### tcp缓冲的概念
[tcp缓冲](https://www.cnblogs.com/promise6522/archive/2012/03/03/2377935.html)
这些东西对于应用层来说是无感的

socket支持blocking(默认)和non-blocking模式，读写都存在阻塞问题
```c
#include <unistd.h>
ssize_t write(int fd, const void *buf, size_t count);
```
牵涉到tcp缓冲层大小

首先，write成功返回，只是buf中的数据被复制到了kernel中的TCP发送缓冲区。至于数据什么时候被发往网络，什么时候被对方主机接收，什么时候被对方进程读取，系统调用层面不会给予任何保证和通知。
已经发送到网络的数据依然需要暂存在send buffer中，只有收到对方的ack后，kernel才从buffer中清除这一部分数据，为后续发送数据腾出空间。接收端将收到的数据暂存在receive buffer中，自动进行确认。但如果socket所在的进程不及时将数据从receive buffer中取出，最终导致receive buffer填满，由于TCP的滑动窗口和拥塞控制，接收端会阻止发送端向其发送数据。这些控制皆发生在TCP/IP栈中，对应用程序是透明的，应用程序继续发送数据，最终导致send buffer填满，write调用阻塞。

一般来说，由于接收端进程从socket读数据的速度跟不上发送端进程向socket写数据的速度，最终导致发送端write调用阻塞。

而read调用的行为相对容易理解，从socket的receive buffer中拷贝数据到应用程序的buffer中。read调用阻塞，通常是发送端的数据没有到达。

- read总是在接收缓冲区有数据时立即返回，而不是等到给定的read buffer填满时返回。只有当receive buffer为空时，blocking模式才会等待，而nonblock模式下会立即返回-1（errno = EAGAIN或EWOULDBLOCK）
- blocking的write只有在缓冲区足以放下整个buffer时才返回（与blocking read并不相同）
- nonblock write则是返回能够放下的字节数，之后调用则返回-1（errno = EAGAIN或EWOULDBLOCK）

 对于blocking的write有个特例：当write正阻塞等待时对面关闭了socket，则write则会立即将剩余缓冲区填满并返回所写的字节数，再次调用则write失败（connection reset by peer）


## 最后
启示就是应用层进行开发的时候不要零零散散的发数据，尽量攒成一个大一点的包再发出去。不要让系统层去做这件事。
TCP_NODELAY 是可以关闭Nagle算法的


## todo
window congestion
超时重传
阻塞，超时，



## 参考
[Nagle和Delayed ACK优化算法合用导致的死锁问题](http://taozj.net/201808/nagle-and-delayed-ack.html)
[Nagle’s Algorithm 和 Delayed ACK 以及 Minshall 的加強版](https://medium.com/fcamels-notes/nagles-algorithm-%E5%92%8C-delayed-ack-%E4%BB%A5%E5%8F%8A-minshall-%E7%9A%84%E5%8A%A0%E5%BC%B7%E7%89%88-8fadcb84d96f)
[再说TCP神奇的40ms](https://cloud.tencent.com/developer/article/1004431)
[tcp缓冲非常好的文章](https://www.cnblogs.com/promise6522/archive/2012/03/03/2377935.html)
[TCP 的那些事儿（下）](https://coolshell.cn/articles/11609.html)