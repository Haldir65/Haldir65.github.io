---
title: tcpdump和wireshark使用手册
date: 2018-11-10 20:57:53
tags: [linux,tools]
---


![](https://api1.foster66.xyz/static/imgs/osi-model.png)
[wireshark expression cheetsheet](http://packetlife.net/media/library/13/Wireshark_Display_Filters.pdf)
[tcpdump cheet](http://packetlife.net/media/library/12/tcpdump.pdf)
wireshark能抓tcp,arp,http,dns,udp,icmp,dhcp...

<!--more-->

先从wireshark说起，在win10上安装wireshark需要顺带装上winpacp，不过现在的安装包默认都会提示去安装，所以也都很简单
tcpdump在Linux上比较容易安装，类似于wireshark的command line tool

### wireshark的filter
现在wireshark的filter都会自动提示了，所以基本上随手敲几个就行了

http ##只看http的
http.request
tcp.dstport == 443 ## 只看https的
tcp.port == 113 ## 不管是source还是destination，只要是port 113的都筛出来(113是一个特殊的端口 Identification Protocol, Ident)
udp.port== 53 ## 筛选出所有的dns查询
ip.addr eq 192.168.1.3 and ip.addr eq 192.168.1.1 //假设本机ip是192.168.1.3并且路由器是192.168.1.1的话，这个可以筛选出所有的ipv4包
ip.src == 192.168.1.3 && tcp.port == 80 //两个命令串联起来也是可以的
ip.addr //既包含src也包含dst
udp ||http // udp或者http的包
frame.len <=128 //显示所有体积小于128个字节的包



//如果一开始就只对特定协议感兴趣
capture -> filters 里面可以选择只抓某些协议的包。因为默认是什么都抓，这样会少很多

### 一些有用的操作
选中一个column，右键 -> follow ->tcpstream ，可以查看这个packet的来回信息。（如果是http的话，request和response都给出来了）
菜单栏上的Statistics -> conversatitons （查看所有的会话）
wireshark的结果可以save成.cap文件，下次可以打开
菜单栏上的Statistics -> protocol Hierarchy(查看所有的协议)
菜单栏view -> coloring rule（直接将特定的协议变成特定颜色的背景，方便识别）
view -> time displayformat(格式化packet的时间显示成便于识别的时间，因为默认的显示单位是毫秒)
Statistics -> endpoints // 查看所有连接过的ip

Statistics -> packet length //查看所有的packet length（多数时候包的大小在40-79和1280-2559这个区间里面，没有小于40的，因为最少得40个字节）

- arp(addression resolution protocol)
一台电脑在发出去一个包之前，已经知道dest的ip地址，但是不知道这个ip地址对于的mac地址是多少，于是会发出一份arp request。
在局域网内部，是这样的
- who has 192.168.1.1 ? Tell 192.168.1.7  //电脑发出arp请求
- 192.168.1.1 is at 00:xx:00:xe:b5 //很快得到了回应

[arp包结构](https://en.wikipedia.org/wiki/Address_Resolution_Protocol)

一个ipv4地址需要32个bit表示,192.168.1.1这种写法叫做base10
一般情况下，192.168这俩一般表示的是network address, .1.1这俩一般表示的是Host address(physical computer)
net mask(255.255.0.0) 192.168.1/16。


### 选中一个tcp包，查看Internet Protocol Version4 ..(这里就是第三层,network层了)。
![](https://api1.foster66.xyz/static/imgs/wire_shark_internet_protocol_version4.png)
从上到下依次是 
version: 4
Header length 20bytes
Differentiated Services Filed(不懂)
Total Length(这个是包含了)
Identification(类似于id)
Flags : 0x4000, Dont't fragment(这个牵涉到mtu,maximum transmission unit size, 这个数值在ethernet上是1500bytes。假如一个包大小超过这个数，切成两个,也就是fragment.这个Flags里面可以看到More fragment: not set （0），意思就是说这个包没有被切成两个。有两种情况下这个标志设为0，一是没有分包，而是这个包恰好是最后一个)
Fragment offset：0 (假如被切成两个了，这里就表示当前这个包是被切完之后的第一个还是第二个，就当是index吧)。
这个包是访问google时留下的


有一个Time to live:128 (就是说这个包最多走128hop，就是最多经手128个router就丢掉)

### 再看第四层（Transport layer），也就是tcp,udp这类了。
还是上面这个包
![](https://api1.foster66.xyz/static/imgs/wire_shark_capture_transmission_control_protocol.png)
从上到下依次是
Source Port
Destination Port :443 //https无疑
stream index: 4
sequence number 496 //确保数据没有丢失
Acknowledgement number : 4043 //下一个包的sequence number
Flags(urg:urgent,push:push,rst:reset,sin&fin(finished))这张图里面写的是Acknowledgment(显然是ack包)
window size value: 2053(这个是tcp receiver buffer，单位是byte，这个数值变来变去的)
checksum(检查数据完整)

## 说一说handshake
tcp packets始于一个handshake
检查端口，发送一个sequence number(随机的),客户端会发送一个syn packet到接受方。接受方会返回一个syn ack packet,接下来客户端发送一个ack packet。上述步骤每一次sequence number都会+1
![](https://api1.foster66.xyz/static/imgs/wireshark_tcp_handshake.png)
```
1. Client 发送 SYN 包（seq: x），告诉 Server：我要建立连接；Client 进入SYN-SENT状态；
2. Server 收到 SYN 包后，发送 SYN+ACK 包（seq: y; ack: x+1），告诉它：好的；Server 进入SYN-RCVD状态；
3. Client 收到 SYN+ACK 包后，发现 ack=x+1，于是进入ESTABLISHED状态，同时发送 ACK 包（seq: x+1; ack: y+1）给 Server；Server 发现 ack=y+1，于是也进入ESTABLISHED状态；
接下来就是互相发送数据、接收数据了……
```

### tcp teardown(四次挥手告别)
host发送给destination一个fin acknowledge packet
destination发挥一个ack packet和一个fin ack packet
host再发送一个ack(这些都可以从flags里面看到)
![](https://api1.foster66.xyz/static/imgs/wireshark_tcp_wave.png)
```
注意，可以是连接的任意一方主动 close，这里假设 Client 主动关闭连接：

1. Client 发送 FIN 包，告诉 Server：我已经没有数据要发送了；Client 进入FIN-WAIT-1状态；
2. Server 收到 FIN 包后，回复 ACK 包，告诉 Client：好的，不过你需要再等会，我可能还有数据要发送；Server 进入CLOSE-WAIT状态；而 Client 收到 ACK 包后，继续等待 Server 做好准备， Client 进入FIN-WAIT-2状态；
3. Server 准备完毕后，发送 FIN 包，告诉 Client：我也没有什么要发送了，准备关闭连接吧；Server 进入LAST-ACK状态；
4. Client 收到 FIN 包后，知道 Server 准备完毕了，于是给它回复 ACK 包，告诉它我知道了，于是进入TIME-WAIT状态；而 Server 收到 ACK 包后，即进入CLOSED状态；Client 等待 2MSL 时间后，没有再次收到 Server 的 FIN 包，于是确认 Server 收到了 ACK 包并且已关闭，于是 Client 也进入CLOSED状态；
```
MSL即报文最大生存时间，RFC793 中规定 MSL 为 2 分钟，但这完全是从工程上来考虑，对于现在的网络，MSL=2分钟可能太长了一些。实际应用中常用的是 30 秒、1 分钟、2 分钟等；可以修改/etc/sysctl.conf内核参数，来缩短TIME_WAIT的时间，避免不必要的资源浪费。

所以整个tcp传输的过程看起来像这样
![](https://api1.foster66.xyz/static/imgs/wireshark_tcp_handwave.jpg)

有时候会看到rest，意味着连接突然中断了（tcp会断掉这个sequence的所有packet，把flags里面的reset设置为1）

### DHCP (Dynamic Host Configuration Protocol)这个位于第7层


### DNS包结构
DNS走的是udp的53端口，发出去的请求的dst.port=53，收到的response的src.port = 53. 
在局域网内,dst就是路由ip(192.168.1.1)

访问tmall主页
![](https://api1.foster66.xyz/static/imgs/dns_query_round_trip.png)
一来一回的

先看request
![](https://api1.foster66.xyz/static/imgs/dns_query_request_detail.png)
在Domain Name System query的
Flags下有一个opcode(这个值可能是standard query，也可能是authoritated answers,如果response是从name server回来的话)
Flags下面还有一个Truncated(意思就是你发出的这个包是不是太大了，太大了塞不进一个packet)
还有Recursion desire:Do query recursively(这意味着servername支持recursive query，就是当前dns server找不到的话，会往上继续查找)

再来看response
![](https://api1.foster66.xyz/static/imgs/dns_query_response_detail.png)
结果在Answers里面



### https结构
wireshark上显示成tlsv1.2
找application data，在secure socket layer里面有encrypted Application Data(加密过的) 
如果是http的话，在hypertext transfer protocol里面最底下会显示html encoded的post的data

### tcp retransmission 
网速慢的时候(latency高)tcp会发现这些问题，重发
如果一个packet始终没有收到ack(在限定的时间内)，重发
两个packet之间的时间叫做round-trip time,每当出现retransmission的时候，z这个packet的rto直接double（windows上默认尝试5次，linux上有的达到15次），一直这样double的操作超过5次后，直接丢包


如果找到一个retransmission的包
rto time在transmission control protocol下面的expert info，里面有个
(the rto for this segment was: 0.220 seconds)
如果这次重发还不成功,0.44s后,0.88秒后。直到超过5次尝试

### tcp  duplicates
duplicate ack，这通常出现在receiver收到了out of order packet。
所有的tcp连接都有一个isn( initial sequence number)，就是初始序列号了。后续的packet会在这个数字的基础上,data payload传递了多少，这个数就加多少。比方说src这边的isn是1000，发送了200bytes的数据，那么我收到的ack应该是1200.

上述是一切正常的情况，但是假如src这边的isn是1000，发出去200bytes，dst那边返回1200的sequence number的ack。此时，src这边出了问题，发出去一个1400的packet，dst那边就会认为，你这不对，重来一遍（发回一个1200的ack，一直尝试3次，直到src终于反应过来发出1200的包，这个正确的包叫做fast retransmission）。
在wireshark里面，dst发回来的重复的ack会显示为tcp dup ack。src最后一次正确的packet显示为tcp fast retransmission

所以一旦出现了skip isn的情况，要么dst发回dup ack，要么src发出fast retransmission

### tcp flow control
即sliding window mechanism，原理是调整retransmission的速度（根据dst的recive window），因为dst那边是有一个tcp buffer space的，万一这个buffer溢出，就会造成丢包
wireshark中，在transmission control protocol下面，有一个window size.
比方说，src发送了一个isn =1的packet，window size = 8760。dst返回一个ack number = 2921的ack,同时window size变成5840.
这么来来回回，这个window迟早被消耗玩，tcp zero window（正常情况下dst的应用层能够读走这部分数据，但是如果接收方读取速度跟不上的话，会发送一个ack包，告诉src发送慢一点,src接收到了之后，就会一直发keep-alive packet(非常小的包，66byte).如果dst那边还没处理好的话，会一直返回Tcp Zero window 的ack，这样往返数次）。这个专门的名词叫做Zero Window Probe
在wireshark里面,tcp zero window的ack包里面会显示window size value: 0
**只要有等待的地方都可能出现DDoS攻击，Zero Window也不例外，一些攻击者会在和HTTP建好链发完GET请求后，就把Window设置为0，然后服务端就只能等待进行ZWP，于是攻击者会并发大量的这样的请求，把服务器端的资源耗尽。（关于这方面的攻击，大家可以移步看一下Wikipedia的SockStress词条）**

### high latency
这个主要的标志是time这一栏超过1秒，延迟的原因很多。可以分析是去程慢还是返程慢。也有可能是服务器处理很慢。
network baseline(正常的延迟是多少，比如国内到美国一般150ms以上是起码的，这是物理决定的)


## tcpdump
安装
>sudo apt-get install tcpdump

使用
sudo tcpdump -i wlan0 ##i的意思是指定某个网络接口，输出非常多
sudo tcpdump -D ##哪些接口可用
sudo tcpdump -i 2 ##只看-D显示的第二个设备
sudo tcpdump -v -A ## A的意思是ASCII，至少内容容易辨识
sudo tcpdump -i 2 -c 4 ##只抓4个包
sudo tcpdump -i 2 -c -4 -n arp ##只抓arp的包,n的意思是supress host name,也能用来指定协议
sudo tcpdump -i 2 -c -4 -n tcp ##只抓4个tcp
sudo tcpdump -i 2 -c -4 -n icmp ##只抓4个icmp
sudo tcpdump -i 2 -c -4 src 192.168.1.1 ##指定src

sudo tcpdump -i 2 -c -4 -w filename.pcap ##保存到文件,这个文件用tcpdump打开也是可以的
sudo tcpdump -r  filename.pcap ##读取这个文件


可以和egrep一起用
sudo tcpdump -A -i 2 | egrep -i 'pass=|pwd=|password=|username=' --color=auto --line-buffered 
//比方说抓到了md5过的密码，随便找个解密网站，就能解出来了


## tbd
抓包，json和protoBuf的payload区别，为什么同样的数据，后者更省流量？



[ARP欺骗](https://segmentfault.com/a/1190000009562333) arp cache poisoning attack
[常用的端口号](http://packetlife.net/media/library/23/common_ports.pdf)
[各种可能的pcap文件](https://github.com/chrissanders/packets)
[本文大量文字图片出处](https://zfl9.github.io/c-socket.html)








