---
title: linux基本命令介绍
date: 2017-01-07 15:38:43
categories: blog
tags: [置顶,linux,notes]
top : 1
---

一些常用的linux基本命令,仅作为参考。</br>
![](http://odzl05jxx.bkt.clouddn.com/849c18412f8e7a0b18df09f6f87e6516.jpg?imageView2/2/w/600)
 <!--more-->

首先是连接vps的ssh(Secure Shell)工具，putty或者xshell都可以。

## 速查手册
1. [文件操作](#1-文件操作常用命令)
2. [Vi文本编辑器](#2-Vi文本编辑器)
3. [bash脚本怎么写](#3-linux下shell脚本语句的语法)
4. [用户和用户组的问题](#4-用户和用户组的问题)
5. [文件权限](#5-文件权限的问题)
6. [管道](#6-管道)
7. [硬件相关的命令](#7-硬件相关的命令)
8. [SS相关的命令](#8-SS相关的命令)
9. [网络监控](#9-网络监控)
10. [查看进程](#10-查看进程)
11.[通用配置](#11-常用配置)

[参考](#参考)


### 1. 文件操作常用命令

```shell
- > cd //进入目录
- > cd /  返回根目录
- > pwd // 显示当前目录
- > ls // 显示当前目录下内容 

- > mkdir //新建目录
- > rmdir //删除目录,如果目录不为空，
- >使用 rm -r //递归删除
- > rm -rf //强制删除

文件名一般不支持空格，如果真有的话得用单引号括起来，像这样:
-> rm -f 'my file'
-> mv a.mp4 b.mp4 //mv虽然是移动（Windows中的剪切）操作，但这种情况下就等同于重命名了，亲测有效

# 重命名
rename是实际意义上的重命名命令，但rename接受三个参数

- > touch filename //创建文件，后缀在linux下没意义

```



复制粘贴：
```shell
- > cp a b //把a复制一份，命名为b

- > cp d1 d2 // 这样是不行的，复制目录需要加上-r ，即
- > cp -r d1 d2

移动(左边是被移动的文件或目录，右边是目标路径)： 

- > mv d1 /  把d1移动到相对路径，也就是根目录下
- > mv d1 ../把d1往上移动一层
- > mv d1 ../../
```



###重定向

```
重定向输出 >
ls  > lsoutput.txt #用于将输出的结果写入一个新的文本文件中
echo 'hey man' # 类似于print
echo 'hello' > log.txt #把这句话写入到文本中 ，覆盖其原有内容

重定向输入 <
wall < aa.txt # wall是向所有用户发广播， 即从aa.txt中读取内容，然后广播发出去


#service命令
service XXX start/stop/status #原理是将这些程序注册成为系统服务，这样调用这些程序的时候就不需要写一大堆绝对路径了，具体用法help已经很详细了。

zip –q –r video.zip /home/video 
zip –q –r video.zip .  # .代表当前目录

```



### 2. Vi文本编辑器
```shell
- > vi 3.txt // 如果有则编辑，没有则直接创建

Vi分为命令模式和编辑模式，一进来是命令模式，输入'a'进入编辑模式
切换回命令模式按'esc' 
命令模式下 :w 表示存盘
- :q 退出

- :wq 保存并退出
- :q! 不保存退出（无内容变化）
```


在编辑模式下,输入 'dd'删除一行 ，输入'dw'删除一个词
输入'o'插入一行。。。。。。





```shell
- > more filename//查看文件内容

- > cat filename //正序查看文件内容

- > tac filename //逆序查看文件内容

- > head - 3 filename //只查看文件前面三行
- > tail - 3 filename //只查看倒数后三行 



```


更多命令如 find 、 whereis 、 Li(Link)
查找：
```shell
find / -name filename  //在根目录下查找文件
find /etc -name filename //在etc目录下查找文件

grep stringtofind filename //在指定的文本文件中查找指定的字符串

whereis ls //查看ls命令所执行的是哪个文件及其位置(查看系统文件所在路径)

```

### 3. linux下shell脚本语句的语法
linux大小写敏感
eg: 
```shell
#!/bin/sh
myPath="/var/log/httpd/"
myFile="/var /log/httpd/access.log"
#这里的-x 参数判断$myPath是否存在并且是否具有可执行权限
if [ ! -x "$myPath"]; then
mkdir "$myPath"
fi
#这里的-d 参数判断$myPath是否存在
if [ ! -d "$myPath"]; then
mkdir "$myPath"
fi
#这里的-f参数判断$myFile是否存在
if [ ! -f "$myFile" ]; then
touch "$myFile"
fi
#其他参数还有-n,-n是判断一个变量是否是否有值
if [ ! -n "$myVar" ]; then
echo "$myVar is empty"
exit 0
fi
#两个变量判断是否相等
if [ "$var1" == "$var2" ]; then  //if 后面必须加then
echo '$var1 eq $var2'
else
echo '$var1 not eq $var2'
fi //else后面必须加fi
 

       if list then
           do something here
       elif list then
           do another thing here
       else
         do something else here
       fi  
```

eg: echo类似于print
```shell
例：myvar=“Hi there！”

    echo $myvar

    echo "$myvar"

    echo ' $myvar'

    echo \$myvar

将会输出如下：Hi there！

              Hi there!

              $myvar

              $myvar
```


### 4. 用户和用户组的问题
```shell
useradd user //添加用户，(-g 指定用户所在用户组)/home目录下会多一个user的目录，作为该用户的主目录

passwd user //设置user的密码，会提示输入密码，密码不会显示在窗口中

cd /etc >>> more passwd  ，这里面会显示所有的用户
more group ,显示用户组的信息
groupadd groupname //添加一个用户组

//删除用户
userdel user //删除一个用户 
还需要删除该用户的主目录(rm -rf user) 

重启机器，登录页面选择新用户即可完成用户切换

或者使用 su testuser 切换到testuser身份
exit就回到root用户的身份

新用户登录时，默认的pwd是该用户的主目录
```




### 5. 文件权限的问题
ls命令执行显示的文件前一般带有一串信息
第一位：
- 代表文件
l代表链接
d代表目录

后面九位划分为三块，可能的权限有这么几种
r(read权限)w(写权限)-(无权限)x(执行权限)

第一组代表所有者(u)权限，第二组代表与所有者一个用户组的用户(g)的权限，第三组代表其他用户(0)的权限

更改文件权限命令: chmod
```shell
chmod +x filename //加上可执行权限，所有用户都加上了
chmod u+x filename //给当前用户加上可执行权限
//其他命令不一一列举

> u ：目录或者文件的当前的用户
  g ：目录或者文件的当前的群组
  o ：除了目录或者文件的当前用户或群组之外的用户或者群组
  a ：所有的用户及群组


> r ：读权限，用数字4表示
  w ：写权限，用数字2表示
  x ：执行权限，用数字1表示
  - ：删除权限，用数字0表示

所以给所有用户增加a.txt文件的可执行权限就像这样
chmod a+x a.txt 
#其余自行发挥
chmod a-x a.txt  #删除所有用户的可执行权限


chmod 755 filename  
751应该是读/写/执行
chomod 444 filename# 为所有用户分配读权限
chmod 777 filename //全部权限都有了，其实上面的9位就是这三位数每一位的二进制拼起来的
755 就是 111101101,也就对应上面的权限九位字母

chown -R Jane /foldername # 把flodername文件夹的所有者改为Jane， -R 表示递归，会保证所有子文件夹的所有者也被更改

```

更改文件所有者

- > chown username filename


### 6. 管道
将一个命令的输出传送给另一个命令，作为另一个命令的输入
eg: 中间那条竖线叫做管道连接符
```shell
$ cat /etc/passwd | grep usernametofind
$ ls -l | grep "^d"
$ ls -l * | grep "^-" | wc -|   //"^-"表示不列出目录或链接，只展示目录；wc是数行数
$ ls -l | grep "^d" //只列出目录
```


### 7. 硬件相关的命令

[VPS跑分软件](https://github.com/Teddysun/across)


> git clone下来
cd across
wget -qO- bench.sh | bash （亲测可用，也可以自己看Readme）
或者 > curl -Lso- bench.sh | bash 


#### BandWagon
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
#### BuyVm 
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

#### DigitalOcean Los Angeles

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

#### DigitalOcean Sinapore (ip adress lokks like Russian)
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


查看硬盘存储空间:
````
df -h //h的意思是human-readable
du -sh //查看当前directory的大小
du -h //查看当前目录下各个子目录分别的大小
dh -h img// 查看img目录下文件及文件夹的大小
dh -h img/1.jpg //查看指定文件的大小
````

查看cpu信息
> cat /proc/cpuinfo

查看内存
>free -m 
free -h # human readable

修改默认安全设置
> vi /etc/ssh/ssd_config


添加或修改

```
Port 22 (ssh默认端口修改)
PermitRootLogin without-Password no
AllowUsers userName
```
压缩文件命令
将/home/video/ 这个目录下所有文件和文件夹打包为当前目录下的video.zip

zip –q –r -v video.zip . #加上一个-v主要是为了能够实时查看输出


文件传输（linux ->windows）： 一般使用putty ssh到Linux主机，想要把Linux上的文件弄到Windows中，需要使用pscp工具。下载好pscp.exe后，放到c:/windows/system32下面。打开cmd。输入命令
pscp -r root@202.123.123.123:"/root/fileonServer.mp4" d:/whateveriwantonmyPc.mp4  ，确认后输入root密码就好了。我主要是用来下载视频的。
有时候会出现Connection Refused Error。
> netstat -anp | grep sshd


看下跑在哪个端口
然后
> pscp -P 12345-r root@202.123.123.123:"/root/fileonServer.mp4" d:/whateveriwantonmyPc.mp4  -p要大写




### 8. SS相关的命令
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

### 9. 网络监控


```
tcpdump -i "venet0:0"  //抓包的
tcpdump -c 10 //count
tcpdump -c -A  //Asicii码形式展示出来每个package
tcpdump -c 5 -i wlo1 // 监听某一个网卡
tcpdump -c 5 -i wlo1 port 22// 监听某一个网卡某一个端口

tcpdump version 4.5.1
libpcap version 1.5.3
Usage: tcpdump [-aAbdDefhHIJKlLnNOpqRStuUvxX] [ -B size ] [ -c count ]
                [ -C file_size ] [ -E algo:secret ] [ -F file ] [ -G seconds ]
                [ -i interface ] [ -j tstamptype ] [ -M secret ]
                [ -P in|out|inout ]
                [ -r file ] [ -s snaplen ] [ -T type ] [ -V file ] [ -w file ]
                [ -W filecount ] [ -y datalinktype ] [ -z command ]
                [ -Z user ] [ expression ]
```

tcpdump结合wireshark可实现完整的网络抓包

```
netstat
netstat -i // 查看某个网络接口发出和接收了多少byte的数据
netstat -ta //当前active的网络连接
netstat -tan //以ip地址的方式展示出来
```

```
ifconfig // 查看机器上的网卡
en01 //Ethernet 
注意 RX bytes(接收到的数据)和TX bytes(发送出去的数据)后面的数字
```




### 10.查看进程

[起一个进程，后台运行，关掉终端照样跑的那种](https://stackoverflow.com/questions/4797050/how-to-run-process-as-background-and-never-die)

> nohup node server.js > /dev/null 2>&1 &


```
top 动态显示
PID：进程的ID[参数解释](http://www.cnblogs.com/gaojun/p/3406096.html)
　　USER：进程所有者
　　PR：进程的优先级别，越小越优先被执行
　　NInice：值
　　VIRT：进程占用的虚拟内存
　　RES：进程占用的物理内存
　　SHR：进程使用的共享内存
　　S：进程的状态。S表示休眠，R表示正在运行，Z表示僵死状态，N表示该进程优先值为负数
　　%CPU：进程占用CPU的使用率
　　%MEM：进程使用的物理内存和总内存的百分比
　　TIME+：该进程启动后占用的总的CPU时间，即占用CPU使用时间的累加值。
　　COMMAND：进程启动命令名称

ps a 显示现行终端机下的所有程序，包括其他用户的程序。

**看下某个进程跑在哪个端口**
 netstat -anp | grep sshd

ps | grep 类似于 pgrep XXX //查找某个进程

进程命令
*实时监控，1秒刷新一次*
watch -n 1 ps -aux --sort=-pmem,-pcpu


nohup node server.js > /dev/null 2>&1 &

1. nohup means: Do not terminate this process even when the stty is cut off.
2. > /dev/null means: stdout goes to /dev/null (which is a dummy device that does not record any output).
3. 2>&1 means: stderr also goes to the stdout (which is already redirected to /dev/null). You may replace &1 with a file path to keep a log of errors, e.g.: 2>/tmp/myLog
4. & at the end means: run this command as a background task.

```


### 11 .常用配置

> 查看登陆失败日志
grep "Failed password for root" /var/log/auth.log | awk '{print $11}' | sort | uniq -c | sort -nr | more

防范措施
修改登陆端口号
sudo vi /etc/ssh/sshd_config
Port 4484
PermitRootLogin no

修改完成后重启ssh
/etc/init.d/ssh restart



编码的修改
更改locale为utf-8(ubuntu)
> 
vi ~/.bashrc 

# add these lines
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

sudo locale-gen "en_US.UTF-8"
sudo dpkg-reconfigure locales

添加XXX到环境变量
todo


### 参考


- ![](http://odzl05jxx.bkt.clouddn.com/fork_you_git.jpg)
- [文件大小查看命令](https://my.oschina.net/liting/blog/392051)
- [文件压缩命令](http://blog.sina.com.cn/s/blog_7479f7990100zwkp.html)
- [硬件查询](https://my.oschina.net/hunterli/blog/140783)
- [Python源码编译安装ss](http://www.jianshu.com/p/3d80c7cb7b17)
- [源码编译安装ss](http://blog.csdn.net/program_thinker/article/details/45787395)
- [修改系统编码为utf-8](https://askubuntu.com/questions/162391/how-do-i-fix-my-locale-issue)
