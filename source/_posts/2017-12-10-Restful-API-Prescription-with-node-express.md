---
title: 2017-12-10-Restful-API-Prescription-with-node-express
date: 2017-12-10 16:20:16
tags:
---


[使用nodejs 和express搭建本地API服务器](http://blog.desmondyao.com/fake-server/)
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/sceneryc7fd99f667c9d98a583a174872d58d13.jpg?imageView2/2/w/600)
<!--more-->
[Nginx 是前端工程师的好帮手](http://www.restran.net/2015/08/19/nginx-frontend-helper/)


we need a new blog post on vps and ssserver,entitled

```
  1. 刚装好的ubuntu需要执行以下步骤
  安装git > apt-get install git
  安装python > apt-get install python-2.7
  安装python-setuptools > apt-get install python-setuptools
  检查是否安装好： python --version


  2. 下载shadowsocks源码编译
 > git clone https://github.com/shadowsocks/shadowsocks
  # 记得切换到master分支
  python setup.py build
  python setup.py install

  检查下版本 ssserver --version

  3. 编辑配置文件
  vim config.json
  {
   "server":"my_server_ip",
   "server_port":8388,
   "local_address": "127.0.0.1",
   "local_port":1080,
   "password":"mypassword",
   "timeout":300,
   "method":"aes-256-cfb",
   "fast_open": false
}

ssserver -c config.json -d start #启动完成

检查下是否启动了
ps -ef |grep sss

ss 命令
ssserver -c /etc/shadowsocks/config.json # 前台运行

- 后台运行和停止
ssserver -c /etc/shadowsocks.json -d start
ssserver -c /etc/shadowsocks.json -d stop

- 加入开机启动

在/etc/rc.local中加入
sudo ssserver -c /etc/shadowsocks.json --user username -d start - 不要总是用root用户做事，adduser来做，给sudo权限即可

[ShadowsocksR](https://github.com/breakwa11/shadowsocks-rss/wiki)启动后台运行命令
> python server.py -p 443 -k password -m aes-256-cfb -O auth_sha1_v4 -o http_simple -d start

[net-speeder](https://zhgcao.github.io/2016/05/26/ubuntu-install-net-speeder/)
venetX，OpenVZ架构

cd net-speeder-master/
sh build.sh -DCOOKED

Xen，KVM，物理机
cd net-speeder-master/
sh build.sh


加速所有ip协议数据

> ./net_speeder venet0 "ip"

只加速指定端口，例如只加速TCP协议的 8989端口
前提是切换到net-speeder的目录下
> ./net_speeder venet0:0 "tcp src port 8989"

./net_speeder venet0 "ip"

只加速指定端口，例如只加速TCP协议的 8989端口
前提是切换到net-speeder的目录下
 ./net_speeder venet0:0 "tcp src port 8989"

 [KVM架构升级内核开启BBR](https://qiujunya.com/linodebbr.html)


```

[ubuntu 16.4安装shadowsocks-libev](http://www.itfanr.cc/2016/10/02/use-shadowsocks-to-have-better-internet-experience/)

参考github[官方教程](https://github.com/shadowsocks/shadowsocks-libev)安装
```

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
在/etc/rc.local中加入
sudo /etc/init.d/shadowsocks-libev start

```
其实跟安装ss很像的


[VPS跑分软件](https://github.com/Teddysun/across)


> git clone下来
> cd across
> wget -qO- bench.sh | bash （亲测可用，也可以自己看Readme）
或者 > curl -Lso- bench.sh | bash


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
