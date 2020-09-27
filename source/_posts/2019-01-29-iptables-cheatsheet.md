---
title: iptables速查手册
date: 2019-01-29 11:46:11
tags: [linux,tools]
---

![](https://api1.foster66.xyz/static/imgs/lidongjieya_ZH-CN9263684179_1920x1080.jpg)
iptables是控制linux 内核netfilter的command line frontend tool，只存在于linux平台，是system admin常用的防火墙。(虽然已经被nftables取代了，学习点网络知识还是很有必要)
<!--more-->

iptables的manpage这么写的
> DESCRIPTION
Iptables and ip6tables are used to set up, maintain, and inspect  the  tables
of  IPv4 and IPv6 packet filter rules in the Linux kernel.  Several different
tables may be defined.  Each table contains a number of built-in  chains  and
may also contain user-defined chains.
Each  chain  is  a list of rules which can match a set of packets.  Each rule
specifies what to do with a packet that matches.  This is called a  `target',
which may be a jump to a user-defined chain in the same table.


## 概念:
**iptables命令需要root权限执行**
每个表包含有若干个不同的链，比如 filter 表默认包含有 INPUT，FORWARD，OUTPUT 三个链。iptables有四个表，分别是：raw，nat，mangle和filter，每个表都有自己专门的用处，比如最常用filter表就是专门用来做包过滤的，而 nat 表是专门用来做NAT的。

## Chain
默认的Chain包括
- INPUT ---> 所有进入这台主机的连接
- FORWARD  ---> 借由这台主机发出的（路由器）
- OUTPUT ---> 所有从这台主机发出去的连接
- PREROUTING / POSTROUTING

每一条Chain上都有一个rules的列表(用A去append,用I去Insert)
当然还可以自定义Chain



## table（table是一系列针对packet的同一类决策的集合，表是为了方便管理提出的逻辑概念）
Mangle is to change packets (Type Of Service, Time To Live etc) on traversal.
Nat is to put in NAT rules.
Raw is to be used for marking and connection tracking.
Filter is for filtering packets.(默认的，如果不加-t的话默认都是对这个表操作)

[表的优先级](https://zfl9.github.io/iptables.html)
所谓优先级就是处理的顺序，从左到右优先级依次降低：raw -> mangle -> nat -> filter；

raw，优先级最高，通常与NOTRACK一起使用，用于跳过连接跟踪（conntrack）和 nat 表的处理；
mangle，修改包头部的某些特殊条目，如 TOS、TTL、打上特殊标记 MARK 等，以影响后面的路由决策；
nat，用于进行网络地址转换，如 SNAT（修改源地址）、DNAT（修改目的地址）、REDIRECT 重定向等；
filter，用于过滤数据包，比如 ACCEPT（允许），DROP（丢弃）、REJECT（拒绝）、LOG（记录日志）；
raw 表除了 -j NOTRACK 外，还有一个常用的动作，那就是 -j TRACE，用于跟踪数据包，进行规则的调试，使用 dmesg 查看。

 一般来讲table是kernel的事情，外部无需关心。一般都是创建一个新的chain,然后在input或者output这种现有的chain后面append上去，比如这样：

iptables -N Services
iptables -A INPUT -j Services
iptables -A Services -m tcp -p tcp --dport 80 -j ACCEPT

意思就是说，默认的input chain走完了发现还没有匹配上，就全部丢给新创建的chain。

```
#~ iptables -L INPUT -n -v --line-numbers

Chain INPUT (policy DROP)
num  target     prot opt source               destination
1    DROP       all  --  202.54.1.1           0.0.0.0/0
2    DROP       all  --  202.54.1.2           0.0.0.0/0
3    ACCEPT     all  --  0.0.0.0/0            0.0.0.0/0           state NEW,ESTABLISHED
```
执行顺序(这个比较麻烦):

iptables执行规则时，是从从规则表中从上至下顺序执行的，如果没遇到匹配的规则，就一条一条往下执行，如果遇到匹配的规则后，那么就执行本规则，执行后根据本规则的动作(accept, reject, log等)，决定下一步执行的情况。
比如说上面这个，拉黑了202.54.1.2虽然第三条规则说全部接受，其实202.54.1.2的包是进不来的。
这也是很多教程建议把自己的iptables写在后面的原因，不要把系统现有规则覆盖掉。


> iptables -L -n -v //查看已添加的iptables规则

默认是全部接受的
```
Chain INPUT (policy ACCEPT) ## 允许进入这台电脑
target     prot opt source               destination

Chain FORWARD (policy ACCEPT)  ## 路由相关
target     prot opt source               destination

Chain OUTPUT (policy ACCEPT) ## 允许发出这台电脑
target     prot opt source               destination
```

### 允许所有连接
```bash
iptables --policy INPUT ACCEPT
iptables --policy OUTPUT ACCEPT
iptables --policy FORWARD ACCEPT
```
iptables后面可以跟的参数很多
```
# iptables -t mangle -X
# iptables -P INPUT ACCEPT
# iptables -P OUTPUT ACCEPT
# iptables -P FORWARD ACCEPT
```

### 来解释一下这些参数的意思
```
-L List rules的意思
-v verbose
-n numeric 不走dns，直接显示ip,这样会快一点
-F flushing（删除）所有的rules
-X delete chain
-t table_name(一般就nat和mangle两种)
-P 设置policy(比如说DROP , REJECT, REDIRECT)
--line-numbers //显示每条规则所在的行号
-s source iP
--sport 22 //源端口号22
--sport 513:65535 // port range也是可以的
--dport 22 //目标端口号22
--dport 513:65535 //port range
iptables -t nat -A POSTROUTING -j SNAT --to-source 192.168.1.100:2000-3000 //nat的时候加range也是可以的
-i interface，就是eth0这些网卡设备什么的
LOG --log-prefix "IP_SPOOF A: " //加日志,这个LOG关键词和DROP,ACCEPT都差不多的，跟在-j 屁股后面
-m mac --mac-source //-m 我猜是metrics ，就是说根据哪种评判标准，这里是mac地址
-m state --state NEW,ESTABLISHED RELATED
-p tcp protocol之类的，比方说tcp,udp,icmp(ping)等等
-m owner --uid-owner youruserid //所有由这个uid对应的进程创建的包
--set-mark 0x400 设置mark ，仅限于mangle表
-m mark --mark 0x400 后面可以用这个mark来匹配被打了标的包
```


拉黑一个ip
> iptables -I INPUT -s xxx.xxx.xxx.xxx -j DROP //这个拉黑的效果是tcp,udp,icmp全部不通。对方的curl,ping全部卡住

DROP是直接不回话了，REJECT则是会给对方发一个 ACK/RST （这跟不回应对方是有区别的）
REJECT differs to DROP that it does send a packet back, but the answer is as if a server is located on the IP, but does not have the port in a listening state. IPtables will sent a RST/ACK in case of TCP or with UDP an ICMP destination port unreachable.(对方收到后，看起了就像是这台http服务器没有listen在80端口上一样)
在互联网的服务器上，拉黑别人一般都是用DROP，因为没必要再去通知对方已被拉黑。


取消拉黑：也就是删除上面这条规则
>iptables -D INPUT -s xxx.xxx.xxx.xxx -j DROP

比方说我不小心把202.54.1.1拉黑了，怎么挽回
简单来说
> iptables -A ...

都可以用这一句撤销掉
> iptables -D ...

```
iptables -L OUTPUT -n --line-numbers | grep 202.54.1.1 //发现在条规则第四行
iptabels -D INPUT 4 //把这个第四行的规则删掉
iptables -D INPUT -s 202.54.1.1 -j DROP //这个也是一样的
```


只允许特定ip访问某个端口
> sudo iptables -I INPUT -p tcp ! -s 200.200.200.0/24 --destination-port 1080 -j DROP


上面说了，iptables的顺序是从上往下match，前面的如果匹配上了，后面的就不会有机会被匹配。所以假如第2条规则说全部接受，我想拉黑某个ip，就得用-I，把拉黑的规则插入到最前面（-I 1 就是插入到第一位）: 
iptables -I 1 INPUT -s xxx.xxx.xxx.xxx -j DROP


```bash
iptables -P FORWARD DROP ## 把forward 一律改为drop（走本机代理的包全部丢掉）
iptables -A INPUT -s  192.168.1.3  ## A是append s是source，拒绝接受192.168.1.3的访问，就是黑名单了
iptables -A INPUT -s  192.168.0.0/24 -p tcp --destination-port 25 -j DROP  ## block all devices on this network ,  p是protocol,SMTP一般是25端口

iptables -A INPUT -s 192.168.0.66 -j ACCEPT  ## 白名单
iptables -D INPUT 3 ##这个3是当前INPUT链的第3条规则，就是说删掉这个chain里面的第3条规则
iptables -I INPUT -s 192.168.0.66 -j ACCEPT  ## 白名单，和-A不同，A是加到尾部，I是加到list的头部，顺序很重要。

iptables -I INPUT -s 123.45.6.7 -j DROP       #屏蔽单个IP的命令
iptables -I INPUT -s 123.0.0.0/8 -j DROP      #封整个段即从123.0.0.1到123.255.255.254的命令
iptables -I INPUT -s 124.45.0.0/16 -j DROP    #封IP段即从123.45.0.1到123.45.255.254的命令
```

### public interface（对外提供服务的网卡应该把私有的ip拉黑掉）
//假如你的某个公共网卡专门对外服务，ip嗅探没什么的，但是下面这种私有ip号段应该禁止。non-routable source addresses的包都可以被DROP掉（就是说拒绝局域网内设备192.168.x.x就不要想着访问这台主机的eth1网卡了）

具体来说，这些都是保留的私有ip地址
```
iptables -A INPUT -i eth1 -s 192.168.0.0/24 -j DROP
10.0.0.0/8 -j (A)
172.16.0.0/12 (B)
192.168.0.0/16 (C)
224.0.0.0/4 (MULTICAST D)
240.0.0.0/5 (E)
127.0.0.0/8 (LOOPBACK) // See Wikipedia and RFC5735 for full list of reserved networks.
```


```bash
#允许所有本机向外的访问
iptables -A OUTPUT -j ACCEPT
# 允许访问22端口
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
#允许访问80端口
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
#允许访问443端口
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
#允许FTP服务的21和20端口
iptables -A INPUT -p tcp --dport 21 -j ACCEPT
iptables -A INPUT -p tcp --dport 20 -j ACCEPT
#如果有其他端口的话，规则也类似，稍微修改上述语句就行
#允许ping
iptables -A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT
#禁止其他未允许的规则访问
iptables -A INPUT -j REJECT  #（注意：如果22端口未加入允许规则，SSH链接会直接断开。）
iptables -A FORWARD -j REJECT
```

## CIDR（比如说封掉facebook.com）
```
# host -t a www.facebook.com
www.facebook.com has address 69.171.228.40
# whois 69.171.228.40 | grep CIDR
CIDR:           69.171.224.0/19 //就是说facebook的网端在69.171.224.0/19这个范围里
# iptables -A OUTPUT -p tcp -d 69.171.224.0/19 -j DROP 
// 这台主机没法上facebook了
# ping www.facebook.com
ping: sendmsg: Operation not permitted(就是被发出去的包被iptables拦下来了)

//上面这堆看起来挺麻烦的
iptables -A OUTPUT -p tcp -d www.facebook.com -j DROP //直接搞定,但是不推荐这么干
```

### 根据某个mac地址指定
```
# iptables -I INPUT -m mac --mac-source 3E:D7:88:A6:66:8E -j ACCEPT
# iptables -I INPUT -p tcp --dport 22 -m mac --mac-source 3E:D7:88:A6:66:8E -j ACCEPT
# iptables -I INPUT -p tcp --dport 22 -m mac --mac-source 3E:D7:88:A6:66:8E -j REJECT
# iptables -I INPUT -p tcp --port 22 -m mac ! --mac-source 3E:D7:88:A6:66:8E -j REJECT //除了特定mac以外都不允许访问
# iptables -A INPUT -m mac --mac-source 00:0F:EA:91:04:08 -j DROP
```

### 不允许别人ping我
```
# iptables -A INPUT -p icmp --icmp-type echo-request -j DROP
# iptables -A INPUT -i eth1 -p icmp --icmp-type echo-request -j DROP

iptables -A INPUT -s 192.168.1.0/24 -p icmp --icmp-type echo-request -j ACCEPT
### ** assumed that default INPUT policy set to DROP ** #############
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT
iptables -A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT
iptables -A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT
## ** all our server to respond to pings ** ##
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
```

## 打log
先照上面的做法把facebook给封了（所有发到facebook的包全部drop，只是我们这一次想要看日志）
```
iptables -A OUTPUT -p tcp -d 69.171.224.0/19 -j LOG --log-prefix "IP_SPOOF A: "
iptables -A OUTPUT -p tcp -d 69.171.224.0/19 -j DROP 

我们可以简单地使用下面的命令启用iptables的日志记录。
$ iptables -A INPUT -j LOG
我们还可以定义哪些日志将被创建的源IP或范围。
$ iptables -A INPUT -s 192.168.10.0/24 -j LOG
定义我们的iptables -log 生成的日志级别。
$ iptables -A INPUT -s 192.168.10.0/24 -j LOG --log-level 4
我们还可以添加一些前缀生成的日志，所以它会很容易在一个巨大的文件中搜索日志。
$ iptables -A INPUT -s 192.168.10.0/24 -j LOG --log-prefix '** SUSPECT **'
```
在Ubuntu和Debian
iptables的日志由内核生成的。因此，检查以下内核日志文件。
查看iptables的日志
[ubuntu上默认日志是进入了/var/log/sys.log文件中](https://askubuntu.com/questions/348439/where-can-i-find-the-iptables-log-file-and-how-can-i-change-its-location)
$ tail /var/log/sys.log 

### 只开7000-7010端口,只允许某个网段的ip发请求以及其他
```
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 7000:7010 -j ACCEPT

## only accept connection to tcp port 80 (Apache) if ip is between 192.168.1.100 and 192.168.1.200 ##
iptables -A INPUT -p tcp --destination-port 80 -m iprange --src-range 192.168.1.100-192.168.1.200 -j ACCEPT

## nat example ##
iptables -t nat -A POSTROUTING -j SNAT --to-source 192.168.1.20-192.168.1.25

Replace ACCEPT with DROP to block port:
## open port ssh tcp port 22 ##
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -s 192.168.1.0/24 -m state --state NEW -p tcp --dport 22 -j ACCEPT
 
## open cups (printing service) udp/tcp port 631 for LAN users ##
iptables -A INPUT -s 192.168.1.0/24 -p udp -m udp --dport 631 -j ACCEPT
iptables -A INPUT -s 192.168.1.0/24 -p tcp -m tcp --dport 631 -j ACCEPT
 
## allow time sync via NTP for lan users (open udp port 123) ##
iptables -A INPUT -s 192.168.1.0/24 -m state --state NEW -p udp --dport 123 -j ACCEPT
 
## open tcp port 25 (smtp) for all ##
iptables -A INPUT -m state --state NEW -p tcp --dport 25 -j ACCEPT
 
# open dns server ports for all ##
iptables -A INPUT -m state --state NEW -p udp --dport 53 -j ACCEPT
iptables -A INPUT -m state --state NEW -p tcp --dport 53 -j ACCEPT
 
## open http/https (Apache) server port to all ##
iptables -A INPUT -m state --state NEW -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -m state --state NEW -p tcp --dport 443 -j ACCEPT
 
## open tcp port 110 (pop3) for all ##
iptables -A INPUT -m state --state NEW -p tcp --dport 110 -j ACCEPT
 
## open tcp port 143 (imap) for all ##
iptables -A INPUT -m state --state NEW -p tcp --dport 143 -j ACCEPT
 
## open access to Samba file server for lan users only ##
iptables -A INPUT -s 192.168.1.0/24 -m state --state NEW -p tcp --dport 137 -j ACCEPT
iptables -A INPUT -s 192.168.1.0/24 -m state --state NEW -p tcp --dport 138 -j ACCEPT
iptables -A INPUT -s 192.168.1.0/24 -m state --state NEW -p tcp --dport 139 -j ACCEPT
iptables -A INPUT -s 192.168.1.0/24 -m state --state NEW -p tcp --dport 445 -j ACCEPT
 
## open access to proxy server for lan users only ##
iptables -A INPUT -s 192.168.1.0/24 -m state --state NEW -p tcp --dport 3128 -j ACCEPT
 
## open access to mysql server for lan users only ##
iptables -I INPUT -p tcp --dport 3306 -j ACCEPT
```

### 限制最大连接数
```
To allow 3 ssh connections per client host, enter:(一个client最多能够连3个ssh连接过来)
# iptables -A INPUT -p tcp --syn --dport 22 -m connlimit --connlimit-above 3 -j REJECT
http端口一个client最多20个连接
# iptables -p tcp --syn --dport 80 -m connlimit --connlimit-above 20 --connlimit-mask 24 -j DROP
```
### 使用iptables阻止syn-flood
一般在路由器里面都有这么一条
```
iptables -N syn-flood
iptables -A syn-flood -m limit --limit 50/s --limit-burst 10 -j RETURN
iptables -A syn-flood -j DROP
iptables -I INPUT -j syn-flood
```
```
-N 创建一个条新的链
--limit 50/s 表示每秒50次;1/m 则为每分钟一次
--limit-burst 表示允许触发 limit 限制的最大包个数 (预设5)，它就像是一个容器，最多装10个，超过10个就装不下了，这些包就给后面的规则了
-I INPUT -j syn-flood  把INPUT的包交给syn-flood链处理
这里的--limit-burst=10相当于说最开始有10个可以匹配的包去转发，然后匹配的包的个数是根据--limit=50/s进行限制的，也就是每秒限制转发50个数据包，多余的会被下面符合要求的DROP规则去处理，进行丢弃，这样就实现了对数据包的限速问题。
```

## 现在来看看fail2ban是怎么拉黑一个ip的
一般来说要拒绝一个ip访问http,https可以这么干

```
iptables -I INPUT -s xxx.xxx.xxx.xxx -p tcp --dport 80 -j DROP
iptables -I INPUT -s xxx.xxx.xxx.xxx -p tcp --dport 443 -j DROP

而事实上就是创建了一个action
~ cat /etc/fail2ban/action.d/iptables.conf
# Option:  actionban
# Notes.:  command executed when banning an IP. Take care that the
#          command is executed with Fail2Ban user rights.
# Tags:    See jail.conf(5) man page
# Values:  CMD
#
actionban = <iptables> -I f2b-<name> 1 -s <ip> -j <blocktype>
```

## REDIRECT (透明代理)
首先来看一个把所有走网卡eth0的数据包都转发到redSocks的规则
```
// 新建路由转发表中的一个链 REDSOCKS
sudo iptables -t nat -N REDSOCKS
// 设置不需要代理转发的网段
// 目的为墙外代理服务器的数据包一定不能转发
sudo iptables -t nat -A REDSOCKS -d $SS_SERVER_IP -j RETURN
// 目的为局域网和本地回环地址的数据包不用转发
sudo iptables -t nat -A REDSOCKS -d 172.0.0.0/24 -j RETURN
sudo iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j RETURN
// 将数据包转发到 redsocks
sudo iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports 12345
// 将 REDSOCKS 链的规则应用到经过 eth0 网卡的数据包
sudo iptables -t nat -A OUTPUT -p tcp -o eth0 -j REDSOCKS
```

[redirect不只局限于转发到本地特定端口，还支持转到局域网内另一台设备上](https://serverfault.com/questions/586486/how-to-do-the-port-forwarding-from-one-ip-to-another-ip-in-same-network)


经常会看到教程如何把一台局域网linux nas或者虚拟机变成软路由的教程，首先需要设备开启ip转发
```
cat /proc/sys/net/ipv4/ip_forward
1 // 这个值默认是0
```



比方说把所有incoming 流量(目标端口是80的)导向8080端口
```
iptables -t nat -I PREROUTING --src 0/0 --dst 192.168.1.5 -p tcp --dport 80 -j REDIRECT --to-ports 8080
```

然后根据v2ray的配置文件设置透明代理。
再接下来把所有nat表上的流量交给v2ray监听的端口

```
openwrt在/etc/firewall.user中添加如下脚本，实现本地透明代理（其实并不完美）
```sh
iptables -t nat -N V2RAY //在nat这个表里面创建一个V2RAY的chain
iptables -t nat -A V2RAY -d x.x.x.x -j RETURN ##xxx是vps的ip地址
iptables -t nat -A V2RAY -d 0.0.0.0/8 -j RETURN
iptables -t nat -A V2RAY -d 10.0.0.0/8 -j RETURN
iptables -t nat -A V2RAY -d 127.0.0.0/8 -j RETURN
iptables -t nat -A V2RAY -d 169.254.0.0/16 -j RETURN
iptables -t nat -A V2RAY -d 172.16.0.0/12 -j RETURN
iptables -t nat -A V2RAY -d 192.168.0.0/16 -j RETURN
iptables -t nat -A V2RAY -d 224.0.0.0/4 -j RETURN
iptables -t nat -A V2RAY -d 240.0.0.0/4 -j RETURN
iptables -t nat -A V2RAY -p tcp -j REDIRECT --to-ports 1060
iptables -t nat -A PREROUTING -p tcp -j V2RAY

//下面是把所有的udp包导到1080端口，为什么这么写我不知道
ip rule add fwmark 1 table 100
ip route add local 0.0.0.0/0 dev lo table 100
iptables -t mangle -N V2RAY_MASK
iptables -t mangle -A V2RAY_MASK -d 192.168.0.0/16 -j RETURN
iptables -t mangle -A V2RAY_MASK -p udp -j TPROXY --on-port 1080 --tproxy-mark 1
iptables -t mangle -A PREROUTING -p udp -j V2RAY_MASK
```

**亲测，透明代理的效果是可以的。只是比不上在windows上的速度,cpu占用达到50%以上，没什么意思。**


相比起来,shadowsocks-libev给出了这样一份transparent proxy的代码，更加清楚
```
# Create new chain
iptables -t nat -N SHADOWSOCKS
iptables -t mangle -N SHADOWSOCKS

# Ignore your shadowsocks server's addresses
# It's very IMPORTANT, just be careful.
iptables -t nat -A SHADOWSOCKS -d 123.123.123.123 -j RETURN

# Ignore LANs and any other addresses you'd like to bypass the proxy
# See Wikipedia and RFC5735 for full list of reserved networks.
# See ashi009/bestroutetb for a highly optimized CHN route list.
iptables -t nat -A SHADOWSOCKS -d 0.0.0.0/8 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 10.0.0.0/8 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 127.0.0.0/8 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 169.254.0.0/16 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 172.16.0.0/12 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 192.168.0.0/16 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 224.0.0.0/4 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 240.0.0.0/4 -j RETURN

# Anything else should be redirected to shadowsocks's local port
iptables -t nat -A SHADOWSOCKS -p tcp -j REDIRECT --to-ports 12345

# Add any UDP rules
ip route add local default dev lo table 100
ip rule add fwmark 1 lookup 100
iptables -t mangle -A SHADOWSOCKS -p udp --dport 53 -j TPROXY --on-port 12345 --tproxy-mark 0x01/0x01

# Apply the rules
iptables -t nat -A PREROUTING -p tcp -j SHADOWSOCKS
iptables -t mangle -A PREROUTING -j SHADOWSOCKS

# Start the shadowsocks-redir
ss-redir -u -c /etc/config/shadowsocks.json -f /var/run/shadowsocks.pid
```


代理的原理:参考[ss/ssr/v2ray/socks5 透明代理](https://paper.tuisec.win/detail/4f9d95db284d609)里面的解释
> ss-redir 是 ss-libev、ssr-libev 中的一个工具，配合 iptables 可以在 Linux 上实现 ss、ssr 透明代理，ss-redir 的透明代理是通过 DNAT 实现的，但是 udp 包在经过 DNAT 后会无法获取原目的地址，所以 ss-redir 无法代理经过 DNAT 的 udp 包；但是 ss-redir 提供了另一种 udp 透明代理方式：xt_TPROXY 内核模块（不涉及 NAT 操作），配合 iproute2 即可实现 udp 的透明代理，但缺点是只能代理来自内网主机的 udp 流量。强调一点，利用 ss-redir 实现透明代理必须使用 ss-libev 或 ssr-libev，python、go 等实现版本没有 ss-redir、ss-tunnel 程序。当然，ss、ssr 透明代理并不是只能用 ss-redir 来实现，使用 ss-local + redsocks/tun2socks 同样可以实现 socks5（ss-local 是 socks5 服务器）全局透明代理，ss-local + redsocks 实际上是 ss-redir 的分体实现，都是通过 NAT 进行代理的，因此也不能代理本机的 udp，当然内网的 udp 也不能代理，因为 redsocks 不支持 xt_TPROXY 方式（redsocks2 支持 TPROXY 模块，但是依旧无法代理本机 udp，不考虑）。所以这里只讨论 ss-local + tun2socks，这个组合方式其实和 Android 上的 VPN 模式差不多（ss-redir 或 ss-local + redsocks 则是 NAT 模式），因为不涉及 NAT 操作，所以能够代理所有 tcp、udp 流量（包括本机、内网的 udp）。很显然，利用 tun2socks 可以实现任意 socks5 透明代理（不只是 ss/ssr，ssh、v2ray 都可以，只要能提供 socks5 本地代理）。最后再说一下 v2ray 的透明代理，其实原理和 ss/ssr-libev 一样，v2ray 可以看作是 ss-local、ss-redir、ss-tunnel 三者的合体，因为一个 v2ray 客户端可以同时充当这三个角色（当然端口要不一样）；所以 v2ray 的透明代理也有两种实现方式，一是利用对应的 ss-redir/ss-tunnel + iptables，二是利用对应的 ss-local + tun2socks（这其实就是前面说的 socks5 代理）。


shell中全局的http代理可以这么设置
```
export http_proxy=http://127.0.0.1:8118; export https_proxy=$http_proxy
//如果是socks5协议的话可以改一下
export http_proxy=socks5://127.0.0.1:8118; export https_proxy=$http_proxy
//只对当前shell有效
```
接下来，git、curl、wget 等命令会自动从环境变量中读取 http 代理信息，然后通过 http 代理连接目的服务器。但有些软件是不认这个的。
那问题来了，ss-local 提供的是 socks5 代理，不能直接使用怎么办？也简单，Linux 中有很多将 socks5 包装为 http 代理的工具，比如 privoxy。只需要在 /etc/privoxy/config 里面添加一行 forward-socks5 / 127.0.0.1:1080 .，启动 privoxy，默认监听 127.0.0.1:8118 端口，注意别搞混了，8118 是 privoxy 提供的 http 代理地址，而 1080 是 ss-local 提供的 socks5 代理地址，发往 8118 端口的数据会被 privoxy 处理并转发给 ss-local。所以我们现在可以执行 export http_proxy=http://127.0.0.1:8118; export https_proxy=$http_proxy 来配置当前终端的 http 代理，这样 git、curl、wget 这些就会自动走 ss-local 出去了。

> Often, services on the computer communicate with each other by sending network packets to each other. They do this by utilizing a pseudo network interface called the loopback device, which directs traffic back to itself rather than to other computers.
同一台机器的不同进程之间有时候是通过一个虚拟的网络(loopback device)进行通信的，所以，必须要让iptables允许这些通信
$ sudo iptables -I INPUT 1 -i lo -j ACCEPT // -I的意思是插入，就是插入到INPUT这个规则里面。 1是说插到第一位，因为iptables排在前面的优先级高。 -i是interface的意思，lo就是loopback的简称。（也就是说，所有使用本地loopback这个interface发过来的包，放行）

**注意还需要将上述规则添加到开机启动中，想要持久化的话好像有一个iptables-persistent**，还有使用iptables屏蔽来自[某个国家的IP](https://www.vpser.net/security/iptables-block-countries-ip.html)的教程


### 透明代理的实现
[ss-libev的openwrt移植就是这么干的](https://github.com/shadowsocks/luci-app-shadowsocks)
在ss-rules(其实就是一个shell脚本)中
```bash
ipset -! restore create ss_spec_src_fw hash:ip hashsize 64
iptables-restore -n <<-EOF
nat
-A SS_SPEC_LAN_AC -m set --match-set ss_spec_src_fw src -j SS_SPEC_WAN_FW
-A SS_SPEC_WAN_AC -m set --match-set ss_spec_dst_fw dst -j SS_SPEC_WAN_FW
EOF
## 这个EOF主要为了方便换行，match src是gfwlist的转到SS_SPEC_WAN_FW这个chain上(外面的流量进来)，dst是gfwlist的也转到这个chain上。
## 而这个chain 只干了一件事 REDIRECT   tcp  --  anywhere             anywhere             redir ports 1080(比方说local ss-redir监听在这个端口的话)
iptables -t nat -A SS_SPEC_WAN_FW -p tcp \
		-j REDIRECT --to-ports $local_port //tcp流量导向ss-redir本地监听端口
iptables -t mangle -A SS_SPEC_WAN_FW -p udp \
		-j TPROXY --on-port $LOCAL_PORT --tproxy-mark 0x01/0x01   //udp转发    
```
[UDP 透明代理是通过 TPROXY 方式实现的](https://vvl.me/2018/06/09/from-ss-redir-to-linux-nat/) TPROXY是LINUX内核为支持透明代理而提供的一项新技术。
所以在部署了ss-libev-luci的路由器上iptables -t nat -L 都能看到这些东西。事实上在iptables没有看到udp的影子，使用的是TPROXY。
ss-redir的原理很简单：使用iptables对PREROUTING与OUTPUT的TCP/UDP流量进行REDIRECT（REDIRECT是DNAT的特例），ss—redir在捕获网络流量后，通过一些技术手段获取REDIRECT之前的目的地址（dst）与端口（port），连同网络流量一起转发至远程服务器。
为了在redirect UDP后还能够获取原本的dst和port，ss-redir采用了TPROXY。Linux系统有关TPROXY的设置是以下三条命令：
```
ip rule add fwmark 0x2333/0x2333 pref 100 table 100
ip route add local default dev lo table 100
iptables -t mangle -A PREROUTING -p udp -j TPROXY --tproxy-mark 0x2333/0x2333 --on-ip 127.0.0.1 --on-port 1080
```
大意就是在mangle表的PREROUTING中为每个UDP数据包打上0x2333/0x2333标志，之后在路由选择中将具有0x2333/0x2333标志的数据包投递到本地环回设备上的1080端口；对监听0.0.0.0地址的1080端口的socket启用IP_TRANSPARENT标志，使IPv4路由能够将非本机的数据报投递到传输层，传递给监听1080端口的ss-redir。


# 新建路由表 100，将所有数据包发往 loopback 网卡
ip route add local 0/0 dev lo table 100

# 添加路由策略，让所有经 TPROXY 标记的 0x2333/0x2333 udp 数据包使用路由表 100
ip rule add fwmark 0x2333/0x2333 lookup 100

### ipset的语法
就是一大堆ip的一个集合，但是存的是hash。 iptables的参数可以传 -m --match-set


netfilter是kernel的实现
> Iptables is a standard firewall included in most Linux distributions by default (a modern variant called nftables will begin to replace it). It is actually a front end to the kernel-level netfilter hooks that can manipulate the Linux network stack.

iptables的工作流程
> direct the packet to the appropriate chain, check it against each rule until one matches, issue the default policy of the chain if no match is found

[a-deep-dive-into-iptables-and-netfilter-architecture](https://www.digitalocean.com/community/tutorials/a-deep-dive-into-iptables-and-netfilter-architecture)

[iptable在透明代理中的原理就是修改了packet的destination address，同时还记住了原来的address](https://unix.stackexchange.com/questions/413545/what-does-iptables-j-redirect-actually-do-to-packet-headers)
> iptables overwrites the original destination address but it remembers the old one. The application code can then fetch it by asking for a special socket option, SO_ORIGINAL_DST
[著名tcp代理redsocks就是用SO_ORIGINAL_DST的](https://github.com/darkk/redsocks)



iptables规则生效后，不会掐断现有的tcp连接


[DNAT是在PREROUTING链上来进行的，而SNAT是在数据包发送出去的时候才进行，因此是在POSTROUTING链上进行的](https://blog.51cto.com/dengaosky/2129665)

[dnat打LOG只会走一次](https://networkengineering.stackexchange.com/questions/18461/very-simple-nat-question-how-does-a-packet-get-back-out)
The key thing to remember with iptables NAT is that only the first packet of each connection goes through the NAT tables. Once a connection is known any further packets for that connection (in both directions) are simply handled according to the existing mapping. (DNAT只会在连接建立之初走到)

保存
iptables-save -c > iptables-backup.txt
恢复
iptables-restore -c < iptables-backup.txt

Linux 默认会为所有连接都创建连接记录项，而维护连接跟踪表是有开销的，要命的是这个表还有大小限制；

cat /proc/sys/net/netfilter/nf_conntrack_max：允许的最大连接记录项的数目，超过此值后会直接拒绝新连接
cat /proc/sys/net/netfilter/nf_conntrack_count：查看当前已使用的连接记录项数目，如果居高不下则应考虑优化
cat /proc/sys/net/netfilter/nf_conntrack_buckets：查看存储记录项的哈希桶的数目，默认为 nf_conntrack_max / 4

先经过 NAT table 的 PREROUTING 链；
经由路由判断确定这个封包是要进入本机与否，若不进入本机，则下一步；
再经过 Filter table 的 FORWARD 链；
通过 NAT table 的 POSTROUTING 链，最后传送出去。
PREROUTING会修改目标IP， POSTROUTING链会修改来源 IP， 通常我们的 NAT 内网转外网是修改来源 IP（即内网 IP），成为来源 NAT（Source NAT, SNAT）。


流量quota限额
# iptables -A INPUT -p tcp --dport 80 -m quota --quota 52428800 -j ACCEPT
# iptables -A INPUT -p tcp --dport 80 -j DROP


### iptables从一台vps转到另外一台vps(亲测可行)
首先开启ip转发
```
echo -e "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
```
中转机器为1.1.1.1， 客户端填写的serverip是1.1.1.1,server port是10000，服务器2.2.2.2监听在30000端口。
```
iptables -t nat -A PREROUTING -p tcp -m tcp --dport 10000 -j DNAT --to-destination 1.1.1.1:30000
iptables -t nat -A PREROUTING -p udp -m udp --dport 10000 -j DNAT --to-destination 1.1.1.1:30000
iptables -t nat -A POSTROUTING -d 1.1.1.1 -p tcp -m tcp --dport 30000 -j SNAT --to-source 2.2.2.2
iptables -t nat -A POSTROUTING -d 1.1.1.1 -p udp -m udp --dport 30000 -j SNAT --to-source 2.2.2.2
```
可以把所有发往1.1.1.1:10000端口的流量转发到2.2.2.2:30000端口

## 参考
[linux-iptables-examples](https://www.cyberciti.biz/tips/linux-iptables-examples.html)
[网件R7800 OpenWrt使用V2Ray+mKcp+透明代理完美翻墙](https://blog.dreamtobe.cn/r7800-openwrt-v2ray/)
[list and delete iptables rules](https://www.digitalocean.com/community/tutorials/how-to-list-and-delete-iptables-firewall-rules)
[如何创建并管理自定义的iptables的chain](https://blog.sleeplessbeastie.eu/2018/06/21/how-to-create-iptables-firewall-using-custom-chains/)