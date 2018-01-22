---
title: VPS维护的日常
date: 2017-12-11 16:20:16
tags: [tools,linux]
---

![](http://odzl05jxx.bkt.clouddn.com/image/jpg/scenery1511100756208.jpg?imageView2/2/w/600)

<!--more-->

以下在 ubuntu 16.04.3 LTS 上通过

## 1. 小硬盘清理垃圾

> sudo apt-get autoclean 清理旧版本的软件缓存
> sudo apt-get clean 清理所有软件缓存
> sudo apt-get autoremove 删除系统不再使用的孤立软件

## 2.必要软件

刚装好的 ubuntu 需要执行以下步骤,都是些常用的软件

> 安装 git > apt-get install git
> 安装 python > apt-get install python-2.7
> 安装 python-setuptools > apt-get install python-setuptools
> 检查是否安装好： python --version

还有一些，比如 htop

### 2.1 装 ss

> 下载 shadowsocks 源码编译
> git clone https://github.com/shadowsocks/shadowsocks

# 记得切换到 master 分支

```python
python setup.py build
python setup.py install
```

检查下版本

> ssserver --version

编辑配置文件

> vim config.json

```json
{
  "server": "my_server_ip",
  "server_port": 8388,
  "local_address": "127.0.0.1",
  "local_port": 1080,
  "password": "mypassword",
  "timeout": 300,
  "method": "aes-256-cfb",
  "fast_open": false
}
```

> ssserver -c config.json -d start #启动完成

检查下是否启动了

> ps -ef |grep sss

ss 命令

```shell
ssserver -c /etc/shadowsocks/config.json # 前台运行

### 后台运行和停止
ssserver -c /etc/shadowsocks.json -d start
ssserver -c /etc/shadowsocks.json -d stop

###  加入开机启动
### 在/etc/rc.local中加入
sudo ssserver -c /etc/shadowsocks.json --user username -d start - 不要总是用root用户做事，adduser来做，给sudo权限即可
```

### 2.2 SSR 以及一些衍生的软件

[ShadowsocksR](https://github.com/breakwa11/shadowsocks-rss/wiki)启动后台运行命令

> python server.py -p 443 -k password -m aes-256-cfb -O auth_sha1_v4 -o http_simple -d start

[net-speeder](https://zhgcao.github.io/2016/05/26/ubuntu-install-net-speeder/)

> venetX，OpenVZ 架构

```shell
cd net-speeder-master/
sh build.sh -DCOOKED

###Xen，KVM，物理机
cd net-speeder-master/
sh build.sh


### 加速所有ip协议数据

./net_speeder venet0 "ip"


###只加速指定端口，例如只加速TCP协议的 8989端口, 切换到net-speeder的目录下
./net_speeder venet0:0 "tcp src port 8989"

./net_speeder venet0 "ip"
```

### 2.3 升级内核开启 BBR

[KVM 架构升级内核开启 BBR](https://qiujunya.com/linodebbr.html)

[ubuntu 16.4 安装 shadowsocks-libev](http://www.itfanr.cc/2016/10/02/use-shadowsocks-to-have-better-internet-experience/)

参考 github[官方教程](https://github.com/shadowsocks/shadowsocks-libev)安装

```shell
sudo apt-get install software-properties-common -y
sudo add-apt-repository ppa:max-c-lv/shadowsocks-libev -y
sudo apt-get update
sudo apt install shadowsocks-libev

# Edit the configuration file
sudo vi /etc/shadowsocks-libev/config.json ## 这里记得把server address改成实际的ip

# Edit the default configuration for debian
sudo vi /etc/default/shadowsocks-libev

# Start the service
sudo /etc/init.d/shadowsocks-libev start    # for sysvinit, or
sudo systemctl start shadowsocks-libev      # for systemd

##加入开机启动
##在/etc/rc.local中加入
sudo /etc/init.d/shadowsocks-libev start
```

其实跟安装 ss 很像的

## 3. 一些常用的命令

> 写 alias 算了

## 10.跑分

[VPS 跑分软件](https://github.com/Teddysun/across)
git clone 下来

```shell
cd across
wget -qO- bench.sh | bash ###（亲测可用，也可以自己看Readme）
### 或者
curl -Lso- bench.sh | bash
```

下面是一些自己试过的

### BandWagon

```
----------------------------------------------------------------------
CPU model            : Intel(R) Xeon(R) CPU E3-1275 v5 @ 3.60GHz
Number of cores      : 1
CPU frequency        : 3600.041 MHz
Total size of Disk   : 12.0 GB (10.0 GB Used)
Total amount of Mem  : 256 MB (217 MB Used)
Total amount of Swap : 128 MB (122 MB Used)
System uptime        : 2 days, 4 hour 20 min
Load average         : 0.06, 0.05, 0.01
OS                   : Ubuntu 14.04.1 LTS
Arch                 : i686 (32 Bit)
Kernel               : 2.6.32-042stab123.3
----------------------------------------------------------------------
I/O speed(1st run)   : 855 MB/s
I/O speed(2nd run)   : 1.0 GB/s
I/O speed(3rd run)   : 1.0 GB/s
Average I/O speed    : 967.7 MB/s
----------------------------------------------------------------------
Node Name                       IPv4 address            Download Speed
CacheFly                        205.234.175.175         76.5MB/s
Linode, Tokyo, JP               106.187.96.148          17.6MB/s
Linode, Singapore, SG           139.162.23.4            8.18MB/s
Linode, London, UK              176.58.107.39           8.67MB/s
Linode, Frankfurt, DE           139.162.130.8           12.8MB/s
Linode, Fremont, CA             50.116.14.9             9.40MB/s
Softlayer, Dallas, TX           173.192.68.18           62.3MB/s
Softlayer, Seattle, WA          67.228.112.250          66.0MB/s
Softlayer, Frankfurt, DE        159.122.69.4            12.2MB/s
Softlayer, Singapore, SG        119.81.28.170           11.8MB/s
Softlayer, HongKong, CN         119.81.130.170          13.2MB/s
----------------------------------------------------------------------
```

### BuyVm

```
CPU model            : Intel(R) Xeon(R) CPU           L5639  @ 2.13GHz
Number of cores      : 1
CPU frequency        : 2000.070 MHz
Total size of Disk   : 15.0 GB (1.3 GB Used)
Total amount of Mem  : 128 MB (80 MB Used)
Total amount of Swap : 128 MB (32 MB Used)
System uptime        : 0 days, 22 hour 28 min
Load average         : 0.10, 0.04, 0.05
OS                   : Ubuntu 14.04.2 LTS
Arch                 : i686 (32 Bit)
Kernel               : 2.6.32-openvz-042stab116.2-amd64
----------------------------------------------------------------------
I/O speed(1st run)   : 102 MB/s
I/O speed(2nd run)   : 97.1 MB/s
I/O speed(3rd run)   : 147 MB/s
Average I/O speed    : 115.4 MB/s
----------------------------------------------------------------------
Node Name                       IPv4 address            Download Speed
CacheFly                        205.234.175.175         14.7MB/s
Linode, Tokyo, JP               106.187.96.148          6.15MB/s
Linode, Singapore, SG           139.162.23.4            2.54MB/s
Linode, London, UK              176.58.107.39           2.99MB/s
Linode, Frankfurt, DE           139.162.130.8           2.96MB/s
Linode, Fremont, CA             50.116.14.9             4.27MB/s
Softlayer, Dallas, TX           173.192.68.18           11.7MB/s
Softlayer, Seattle, WA          67.228.112.250          13.0MB/s
Softlayer, Frankfurt, DE        159.122.69.4            1.89MB/s
Softlayer, Singapore, SG        119.81.28.170           3.26MB/s
Softlayer, HongKong, CN         119.81.130.170          3.72MB/s
----------------------------------------------------------------------
```

### DigitalOcean Los Angeles

```
----------------------------------------------------------------------
CPU model            : Intel(R) Xeon(R) CPU E5-2650L v3 @ 1.80GHz
Number of cores      : 1
CPU frequency        : 1799.998 MHz
Total size of Disk   : 20.2 GB (1.0 GB Used)
Total amount of Mem  : 488 MB (33 MB Used)
Total amount of Swap : 0 MB (0 MB Used)
System uptime        : 0 days, 0 hour 3 min
Load average         : 0.16, 0.10, 0.03
OS                   : Ubuntu 16.04.2 LTS
Arch                 : x86_64 (64 Bit)
Kernel               : 4.4.0-78-generic
----------------------------------------------------------------------
I/O speed(1st run)   : 581 MB/s
I/O speed(2nd run)   : 711 MB/s
I/O speed(3rd run)   : 777 MB/s
Average I/O speed    : 689.7 MB/s
----------------------------------------------------------------------
Node Name                       IPv4 address            Download Speed
CacheFly                        205.234.175.175         161MB/s
Linode, Tokyo, JP               106.187.96.148          15.7MB/s
Linode, Singapore, SG           139.162.23.4            5.96MB/s
Linode, London, UK              176.58.107.39           5.71MB/s
Linode, Frankfurt, DE           139.162.130.8           6.45MB/s
Linode, Fremont, CA             50.116.14.9             30.4MB/s
Softlayer, Dallas, TX           173.192.68.18           29.9MB/s
Softlayer, Seattle, WA          67.228.112.250          57.7MB/s
Softlayer, Frankfurt, DE        159.122.69.4            3.64MB/s
Softlayer, Singapore, SG        119.81.28.170           7.59MB/s
Softlayer, HongKong, CN         119.81.130.170          8.84MB/s
----------------------------------------------------------------------
```

### DigitalOcean Sinapore (ip adress lokks like Russian)

```
----------------------------------------------------------------------
CPU model            : Intel(R) Xeon(R) CPU E5-2630L 0 @ 2.00GHz
Number of cores      : 1
CPU frequency        : 1999.999 MHz
Total size of Disk   : 20.2 GB (1.0 GB Used)
Total amount of Mem  : 488 MB (36 MB Used)
Total amount of Swap : 0 MB (0 MB Used)
System uptime        : 0 days, 0 hour 2 min
Load average         : 0.17, 0.20, 0.09
OS                   : Ubuntu 16.04.2 LTS
Arch                 : x86_64 (64 Bit)
Kernel               : 4.4.0-78-generic
----------------------------------------------------------------------
I/O speed(1st run)   : 662 MB/s
I/O speed(2nd run)   : 741 MB/s
I/O speed(3rd run)   : 728 MB/s
Average I/O speed    : 710.3 MB/s
----------------------------------------------------------------------
Node Name                       IPv4 address            Download Speed
CacheFly                        205.234.175.175         20.8MB/s
Linode, Tokyo, JP               106.187.96.148          18.6MB/s
Linode, Singapore, SG           139.162.23.4            83.8MB/s
Linode, London, UK              176.58.107.39           5.71MB/s
Linode, Frankfurt, DE           139.162.130.8           8.13MB/s
Linode, Fremont, CA             50.116.14.9             2.82MB/s
Softlayer, Dallas, TX           173.192.68.18           6.18MB/s
Softlayer, Seattle, WA          67.228.112.250          8.47MB/s
Softlayer, Frankfurt, DE        159.122.69.4            6.77MB/s
Softlayer, Singapore, SG        119.81.28.170           97.9MB/s
Softlayer, HongKong, CN         119.81.130.170          35.2MB/s
----------------------------------------------------------------------
```

![](http://odzl05jxx.bkt.clouddn.com/image/jpg/scenery1511100809920.jpg?imageView2/2/w/600)

### 关于 docker

youtube 上有人在 Digital Ocean 的 vps 上安装 docker，主要作用就是将一个复杂的操作系统打包成一个下载即用的容器。进入容器中，可以像在实际的操作系统中一样运行指令。所以虚拟化的机器随时可以使用其他操作系统。

### 参考

[vps 优化](https://www.vpser.net/opt/vps-add-swap.html)
