---
title: VPS维护的日常
date: 2017-12-11 16:20:16
tags: [tools,linux]
---

![](https://haldir66.ga/static/imgs/scenery1511100756208.jpg)

<!--more-->

以下在 ubuntu 16.04.3 LTS 上通过

## 1. 小硬盘清理垃圾

> sudo apt-get autoclean 清理旧版本的软件缓存
> sudo apt-get clean 清理所有软件缓存
> sudo apt-get autoremove 删除系统不再使用的孤立软件
>  sudo rm -rf /var/tmp ## 一般来说/tmp和/var/tmp/文件夹里面的东西可以随便删除，稳妥起见还是先看下这个目录下有没有什么文件被正在跑的程序使用：
> sudo lsof +D /var ## 我看到一大堆mysql的东西 ，另外说一下，为什么/tmp文件夹这么小，因为ubuntu系统每次重启都会把这里面清一下

### 把本机的一个文件上传到vps上
如果之前改过ssh端口的话，这里端口自己可以改，目的地位置也可以指定
```
scp -P 22 porn.mp4 username@xxx.xxx.xxx.xxx:/home/username/
```

## 2.必要软件

刚装好的 ubuntu 需要执行以下步骤,都是些常用的软件

> 安装 git > apt-get install git
> 安装 python > apt-get install python-2.7
> 安装 python-setuptools > apt-get install python-setuptools
> 检查是否安装好： python --version

还有一些，比如 htop
htop中各个process的state[参考](https://stackoverflow.com/questions/18470215/what-does-a-c-process-status-mean-in-htop)
> D uninterruptible sleep (usually IO)
R running or runnable (on run queue)
S interruptible sleep (waiting for an event to complete)
T stopped, either by a job control signal or because it is being traced.
W paging (not valid since the 2.6.xx kernel)
X dead (should never be seen)
Z defunct ("zombie") process, terminated but not reaped by its parent.


只安装security update
> sudo unattended-upgrades -d ## 加上-d和verbose的意思差不多

有些软件不是经常用就禁止开机启动吧
> sudo systemctl disable mysql ##因为这事redis老是装不上

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
  "fast_open": true
}
```

使用ipv6的话(把"my_server_ip"改成"::"),这样访问通过ss访问ipv6.google.com就ok了(当然这要在确认host已有ipv6的前提下)
这跟nginx ipv6 server block很像：
> listen 80 default_server;
listen [::]:80 default_server ipv6only=on;

如果你的服务器Linux 内核在3.7+，可以开启fast_open 以降低延迟。
linux 内核版本查看：
> cat /proc/version

> ssserver -c config.json -d start #启动完成

检查下是否启动了

> ps -ef | grep sss

ss 命令

```bash
ssserver -c /etc/shadowsocks/config.json # 前台运行

### 后台运行和停止
ssserver -c /etc/shadowsocks.json -d start -q ##加上-q是quiet的意思，only show warning and error
ssserver -c /etc/shadowsocks.json -d stop

###  加入开机启动
### 在/etc/rc.local中加入
sudo ssserver -c /etc/shadowsocks.json --user username -d start - 不要总是用root用户做事，adduser来做，给sudo权限即可
```
如果使用systemd来管理的话，就不要使用 -d参数，因为需要root权限，此时应该将ssserver的生命周期管理交给systemd

nohup /net-speeder/net-speeder/net_speeder eth0 "tcp src port 12345" > /dev/null 2>&1 &

慎用！！一不小心会把自己的ip加到iptable黑名单里面
//防止暴力扫描ss端口
[nohup tail -F /var/log/shadowsocks.log | python autoban.py >log 2>log &](https://github.com/shadowsocks/shadowsocks/wiki/Ban-Brute-Force-Crackers)

其实就是找“can not parse header when handling connection from”这句话，超过次数的加到iptable的ban rule里面，可以看下哪些ip被拉黑了
iptables -L -n ## 查看已添加的iptables规则

### 2.2 SSR 以及一些衍生的软件

[ShadowsocksR](https://github.com/breakwa11/shadowsocks-rss/wiki)启动后台运行命令

> python server.py -p 443 -k password -m aes-256-cfb -O auth_sha1_v4 -o http_simple -d start

[net-speeder](https://zhgcao.github.io/2016/05/26/ubuntu-install-net-speeder/)
> apt-get install libnet1-dev
apt-get install libpcap0.8-dev

> venetX，OpenVZ 架构

```bash
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
[net-speeder写入开机脚本](https://blog.kuoruan.com/48.html)

### 2.3 升级内核开启 BBR

[KVM 架构升级内核开启 BBR](https://qiujunya.com/linodebbr.html)

[ubuntu 16.4 安装 shadowsocks-libev](http://www.itfanr.cc/2016/10/02/use-shadowsocks-to-have-better-internet-experience/)

参考 github[官方教程](https://github.com/shadowsocks/shadowsocks-libev)安装

```bash
sudo apt-get install software-properties-common -y
sudo add-apt-repository ppa:max-c-lv/shadowsocks-libev -y
sudo apt-get update
sudo apt install shadowsocks-libev

apt-get install --only-upgrade <packagename> ## 只更新这一个程序
apt list --upgradable ## 看一下哪些程序可以更新

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
sudo ss-server -c /etc/shadowsocks-libev/config.json -u ## 开启udp转发  netstat -lnp确认ss-server确实监听了udp端口
```

其实跟安装 ss 很像的
用iptables限制到shadowsocks端口的最大连接数
```
# Up to 32 connections are enough for normal usage
iptables -A INPUT -p tcp --syn --dport ${SHADOWSOCKS_PORT} -m connlimit --connlimit-above 32 -j REJECT --reject-with tcp-reset
```

## 2.4 安装libsodium
转自[逗比](https://doub.io/ss-jc51/)
```bash
## debian系列
apt-get update
## 安装 编译所需组件包：
apt-get install -y build-essential
### 获取 libsodium最新版本：
Libsodiumr_ver=$(wget -qO- "https://github.com/jedisct1/libsodium/tags"|grep "/jedisct1/libsodium/releases/tag/"|head -1|sed -r 's/.*tag\/(.+)\">.*/\1/') && echo "${Libsodiumr_ver}"
## 下载最新 libsodium版本编译文件：
wget --no-check-certificate -N "https://github.com/jedisct1/libsodium/releases/download/${Libsodiumr_ver}/libsodium-${Libsodiumr_ver}.tar.gz"
tar -xzf libsodium-${Libsodiumr_ver}.tar.gz && cd libsodium-${Libsodiumr_ver}
./configure --disable-maintainer-mode && make -j2 && make install ## 这段最好sudo 去做
ldconfig
## 删掉之前下载的文件
cd .. && rm -rf libsodium-${Libsodiumr_ver}.tar.gz && rm -rf libsodium-${Libsodiumr_ver}
```
现在就可以去config.json文件中将加密方式改成: chacha20 了，重启下ss即可

### 2.5 查看日志
日志文件的位置在/var/log/shadowsocks.log 
下面这条命令用于查看访问了哪些网站
cat  shadowsocks.log | awk '{ print $5}' |grep -o '^[^:]*' | sort | uniq -c | sort -n

查看尝试连接本服务器的客户端
cat shadowsocks.log | awk '{ print $NF }'| grep -o '^[^:]*' | sort | uniq -c | sort -n

### 2.6 simple-obfs
sudo apt-get install simple-obfs
/etc/shadowsocks-libev/config.json文件中添加
```
"plugin":"obfs-server",
"plugin_opts": "obfs=tls;obfs-host=www.bing.com",
"fast_open":true,
"reuse_port":true
```

### 2.7 ss-local提供正向代理
//curl使用代理，在ss-local监听1080端口的前提下，这条命令可以正常访问google

> curl -4sSkL -x socks5h://127.0.0.1:1080 https://www.google.com
> curl --socks5 127.0.0.1:1080 http://stackoverflow.com/ //这个更简单


// 有两种方式
> $ export http_proxy="vivek:myPasswordHere@10.12.249.194:3128/"
> $ curl -v -O http://dl.cyberciti.biz/pdfdownloads/b8bf71be9da19d3feeee27a0a6960cb3/569b7f08/cms/631.pdf


> curl -x 'http://vivek:myPasswordHere@10.12.249.194:3128' -v -O https://dl.cyberciti.biz/pdfdownloads/b8bf71be9da19d3feeee27a0a6960cb3/569b7f08/cms/631.pdf

[如何让 curl 命令通过代理访问](https://linux.cn/article-9223-1.html)
curl -x socks5://[user:password@]proxyhost[:port]/ url
curl --socks5 192.168.1.254:3099 https://www.cyberciti.biz/


## 3. ubuntu自带的防火墙叫做ufw(Uncomplicated Firewall)，用起来也很简单
[digital ocean的ufw教程](https://www.digitalocean.com/community/tutorials/ufw-essentials-common-firewall-rules-and-commands)

## 4.跑分

[VPS 跑分软件](https://github.com/Teddysun/across)
git clone 下来

```bash
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

### DigitalOcean Sinapore (ip address lokks like Russian)

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

![](https://www.haldir66.ga/static/imgs/scenery1511100809920.jpg)

###  跑java？
算了吧，简单读个文本文件print出来cpu就飙到50%。
安装jdk的话
sudo apt install openjdk-8-jdk //只装这个的话在intelij里面是看不了jdk源码的
sudo apt install openjdk-8-source //这样就能在linux desktop的intelij里面看jdk源码了



### 5. 关于 docker

docker image 是snapshot, 而container是docker image的运行实例

youtube 上有人在 Digital Ocean 的 vps 上安装 docker，主要作用就是将一个复杂的操作系统打包成一个下载即用的容器。进入容器中，可以像在实际的操作系统中一样运行指令。所以虚拟化的机器随时可以使用其他操作系统。[how-to-install-and-use-docker-on-ubuntu-16-04](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-16-04)
[用docker host一个node js app](https://nodejs.org/en/docs/guides/nodejs-docker-webapp/)。实测下来image大小在600MB左右，内存占用200MB左右。

docker常用的命令有那么几条
>docker run hello-world
docker search ubuntu
docker pull ubuntu 
docker run ubuntu ## 进入ubuntu这个container
docker images
docker run -it ubuntu
exit

##这两条命令用于自己在本地打一个docker image
docker build -t <your username>/node-web-app .
docker build -t packsdkandroiddocker.image -f ./scripts/PackSdkDockerfile .
## 注意你修改了Dockerfile之后要重新跑一遍docker build -t <your username>/node-web-app .
[每次修改之后重新打image](https://stackoverflow.com/questions/18804124/docker-updating-image-along-when-dockerfile-changes)


docker会在/var/lib/docker文件夹里吃掉大量空间，释放空间的话
> docker system prune -a

[用docker运行一个node mongodb应用](https://medium.com/@kahana.hagai/docker-compose-with-node-js-and-mongodb-dbdadab5ce0a) 亲测有效
[node的官方image太大了，alpine-node占用的磁盘空间更小](https://hub.docker.com/r/mhart/alpine-node/)

docker run -p 3000:3000 -ti dummy-app ## 每次都需要输入一大段命令行参数很烦人的，所以把配置写在一个docker-compose.yml文件里面，每次只需要docker-compose up就可以了。

[使用textmate在vscode中编辑远程linux server中的文件](https://medium.com/@prtdomingo/editing-files-in-your-linux-virtual-machine-made-a-lot-easier-with-remote-vscode-6bb98d0639a4)


关于ubuntu添加ppa
[debian系的package management方式](https://www.digitalocean.com/community/tutorials/ubuntu-and-debian-package-management-essentials).
ppa(personal package archives)
添加ppa的方式
> sudo add-apt-repository ppa:owner_name/ppa_name

### Dnsmasq vps自建DNS服务器
[tips onserver optimization](https://www.digitalocean.com/community/tags/server-optimization?type=tutorials)

### 参考

[vps 优化](https://www.vpser.net/opt/vps-add-swap.html)

> egrep -e "via tcp:xxx.xxx.xxx:[0-9]{5}$" -o client_debug.log | sed "s/via tcp:xxx.xxx.xxx://g" | sort | uniq -c | sort -k 1 -nr
[egrep 和sed 命令的使用](https://github.com/v2ray/v2ray-core/issues/574)


egrep 的使用（偏向正则表达式方面）
cat stuff.log
> 2018/9/15 01:52:26 udp:123.123.123.123:35021 accepted tcp:api-dash.ins.io:443
2018/9/15 01:52:27 udp:123.123.123.123:29932 accepted tcp:www.google-analytics.com:443
2018/9/15 01:52:28 udp:123.123.123.123:35283 accepted tcp:notifications.google.com:443
2018/9/15 01:52:29 udp:123.123.123.123:29932 accepted tcp:fonts.gstatic.com:443

sudo egrep "udp:123.123.123.123:[0-9]{5}" -o stuff.log
udp:123.123.123.123:35021
udp:123.123.123.123:29932
udp:123.123.123.123:35283
udp:123.123.123.123:29932

中括号的意思是0-9之间的任一数字，花括号包起来的5表示重复5次，也就是五位数的意思了


## 6. fail2ban的使用
[照着digitalocean上的教程配置就行了](https://www.digitalocean.com/community/tutorials/how-to-protect-an-nginx-server-with-fail2ban-on-ubuntu-14-04)

本质上都是某个ip触犯了某条规则，就被iptable添加到drop里面。所以对于发起请求的人来说，看到的是connection refused。
对于服务器这边，nginx的日志里都没有。因为ip包还没有到nginx就被拦住了。
日志在/var/log/fail2ban.log这里
iptables -nL
sudo service fail2ban restart ##重启一下让规则生效
sudo fail2ban-client status ## 看下我都添加了哪些规则
sudo iptables -S ##看下fail2ban都添加了哪些iptable规则
sudo fail2ban-client status nginx-http-auth ##看看撞上这个规则的ip有哪些ip
sudo fail2ban-client set nginx-http-auth unbanip 111.111.111.111 ##把这条规则放出小黑屋


sudo fail2ban-client reload ## Reloads Fail2ban’s configuration files.在restart之前先用这个测试一下配置文件是否写错了
sudo fail2ban-client start ##Starts the Fail2ban server and jails.
sudo fail2ban-client status ##Will show the status of the server, and enable jails.
sudo fail2ban-client status nginx-http-auth ## 哪些ip被这个规则ban了

##还可以手动测试正则是否符合
fail2ban-regex 'string' 'regex' //上面的jail也是用了filter.d里面的正则

[fail2ban防止ddos](https://bitmingw.com/2017/05/22/nginx-fail2ban-survive-ddos-attack/)

[fail2ban保护shadowsocks](http://blog.zedyeung.com/2018/08/14/Ubuntu-18-04-set-up-Shadowsocks-server-with-fail2ban/)

[fail2ban-regex](https://www.the-art-of-web.com/system/fail2ban-filters/)
> # fail2ban-regex <logfile> <failregex> <ignoreregex>
# fail2ban-regex /var/log/auth.log /etc/fail2ban/filter.d/sshd.conf --print-all-matched
--print-all-missed
--print-all-ignored

sudo fail2ban-regex /var/log/nginx/access.log /etc/fail2ban/filter.d/nginx-x00.conf --print-all-matched

匹配成功
|  139.162.184.185 - - [29/Oct/2018:20:02:19 -0400] "\x15\x03\x03\x00\x02\x01\x00" 400 166 "-" "-"


[iperf是linux下的一个tcp测速软件](https://github.com/shadowsocks/shadowsocks-libev/blob/master/scripts/iperf.sh)

[vps挂下载](http://frankchen.xyz/2018/04/08/private-BT-server/)。注意transmission每次修改设置文件
sudo vim /etc/transmission-daemon/settings.json之前要先把transmission这个进程关掉，不然设置文件会被修改。
另外，设置文件中显示的rpc-password其实是hash之后的值，记住自己实际上写了什么就好。

## 参考
[国外的超级ping](https://asm.ca.com/en/ping.php)
[快速检测 IP 地址是否可用](https://ipcheck.need.sh/)

