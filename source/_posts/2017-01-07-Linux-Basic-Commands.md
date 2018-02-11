---
title: linux基本命令介绍
date: 2017-01-07 15:38:43
categories: blog
tags: [置顶,linux,tools]
---

一些常用的linux基本命令,仅作为参考。
>  nohup node server.js > /dev/null 2>&1 &


![](http://odzl05jxx.bkt.clouddn.com/image/jpg/bamboo-buds-wallpaper-53859567dd31a.jpg?imageView2/2/w/600)

 <!--more-->



首先是连接vps的ssh(Secure Shell)工具，putty或者xshell都可以,putty改颜色[教程](http://www.cnblogs.com/nayitian/archive/2013/01/18/2866690.html)。

重启 reboot
关机 shutdown -h now #
或者 halt

## 速查手册
1. [文件操作](#1-文件操作常用命令)
2. [Vi文本编辑器](#2-Vi文本编辑器)
3. [bash脚本怎么写](#3-linux下shell脚本语句的语法)
4. [用户和用户组的问题](#4-用户和用户组的问题)
5. [文件权限](#5-文件权限的问题)
6. [管道](#6-管道)
7. [硬件相关的命令](#7-硬件相关的命令)
8. [软件的安装，卸载](#8-软件的安装，卸载)
9.  [网络监控](#9-网络监控)
10. [查看进程](#10-查看进程)
11. [通用配置](#11-常用配置)

    [参考](#参考)

 另外一篇关于[linux命令的补充](http://haldir65.github.io/2017/06/18/2017-06-18-linux-commands-extended/)


### 1. 文件操作常用命令

```shell
- > cd //进入目录
- > cd /  返回根目录
- > pwd // 显示当前目录
- > ls // 显示当前目录下内容
# ls -halt is for human readable, show hidden, print details, sort by date

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
另外,touch 命令主要是用来改文件的时间戳的
- > touch -t 201707081238.34 file.txt //把这个文件的时间戳改成2017年XXX。。。

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



### 重定向

```shell
重定向输出 >
ls  > lsoutput.txt #用于将输出的结果写入一个新的文本文件中

cat > newfile // 所以重定向也能用于创建新的文件
echo 'hey man' # 类似于print
echo 'hello' > log.txt #把这句话写入到文本中 ，覆盖其原有内容
>> 表示追加，不覆盖,append

重定向输入 <
wall < aa.txt # wall是向所有用户发广播， 即从aa.txt中读取内容，然后广播发出去

#service命令
service XXX start/stop/status #原理是将这些程序注册成为系统服务，这样调用这些程序的时候就不需要写一大堆绝对路径了，具体用法help已经很详细了。

zip –q –r video.zip /home/video
zip –q –r video.zip .  # .代表当前目录
建议加上-v，不然等很久
```

### 2. Vi文本编辑器
```shell
- > vi 3.txt // 如果有则编辑，没有则直接创建
## 跳到文件开头处
[[

##跳到文件结尾处
]]

##Vi分为命令模式和编辑模式，一进来是命令模式，输入'a'进入编辑模式
##切换回命令模式按'esc'
## 命令模式下 :w 表示存盘
- :q 退出
- :wq 保存并退出
- :q! 不保存退出（无内容变化）

yy、Y 复制当前光标所在的行
nyy 复制当前光标所在处以及以下的n行

dd     ：剪切当前光标所在处的行
ndd   ：剪切当前光标所在处及以下的n行

p：在当前光标处下面粘贴内容。
P：在当前光标处上面粘贴内容。
```


在编辑模式下,输入 'dd'删除一行 ，输入'dw'删除一个词
输入'o'插入一行。。。。。。

```shell
- > more filename//查看文件内容(一页一页的显示档案内容)

- > less filename// 也是查看(less 与 more 类似，但是比 more 更好的是，他可以[pg dn][pg up]翻页！)

- > cat filename //正序查看文件内容
- > tac filename //逆序查看文件内容
- > nl： 显示的时候，随便输出行号！
- > more： 一页一页的显示档案内容
- > less 与 more 类似，但是比 more 更好的是，他可以[pg dn][pg up]翻页！对less显示出的内容中可以使用 /'字符' 输入需要查找的字符或者字符串并高亮显示，而more 不具备(亲测很好用)
- > head： 查看头几行
- > tail： 查看尾几行


- > head - 3 filename //只查看文件前面三行
- > tail - 3 filename //只查看倒数后三行
- > tail -n 3 filename //和上面是一样的

- > xxd -b fileName // 看binaryFile不能用cat

- > od： 通常使用od命令查看特殊格式的文件内容。通过指定该命令的不同选项可以以十进制、八进制、十六进制和ASCII码来显示文件。
d 十进制
o 八进制（系统默认值）
x 十六进制
n 不打印位移值

od -c filename(以字符方式显示)
od -Ax -tcx4 filename(以十六进制和字符同时显示)

```

tail还有一个好处，可以实时查看文件内容，比如文件正在更新，可以实时查看最新的日志
> tail -f /var/log/messages

亲测，一个10MB的log文件，就这么cat的话，会把putty搞死

***所以后台开发就喜欢这么干: tail一个日志，狂按回车键，然后用客户端访问某个url，看下有没有报错。***

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
id userName // 查看当前用户的信息，比如是不是sudo之类的

useradd user //添加用户，(-g 指定用户所在用户组)/home目录下会多一个user的目录，作为该用户的主目录

sudo su - userName // 从root直接切到userName，具有sudo权限
给一个user管理员权限:
usermod -aG sudo userName

passwd user //设置user的密码，会提示输入密码，密码不会显示在窗口中

cd /etc >>> more passwd  ，这里面会显示所有的用户
more group ,显示用户组的信息
groupadd groupname //添加一个用户组

//删除用户
userdel user //删除一个用户
这么删除还没删干净，需要把/home/username删掉
还需要删除该用户的主目录(rm -rf user)

重启机器，登录页面选择新用户即可完成用户切换

或者使用 su testuser 切换到testuser身份
exit就回到root用户的身份

禁止某个用户登录的原理
在/etc/shadow中存储了每个用户的密码的hash值，在前面有!的都是不能登录的
加!的方法: usermod -L username
解锁的方法: passwd username

/etc/group存储了用户组的信息
/etc/shadow存储了密码的hash值
/etc/passwd存储了系统中所有用户的主目录路径，例如/home/username

新用户登录时，默认的是该用户的主目录 ~/
```




### 5. 文件权限的问题
ls命令执行显示的文件前一般带有一串信息
第一位：
- 代表文件
l代表链接
d代表目录

后面九位划分为三块，可能的权限有这么几种
r(read权限)w(写权限)-(无权限)x(执行权限)

第一组代表所有者(u)权限，第二组代表与所有者一个用户组的用户(g)的权限，第三组代表其他用户(O)的权限
user,user group还有other

更改文件权限命令: chmod(个人测下来要加sudo才行)
```shell
sudo chmod +x filename //加上可执行权限，所有用户都加上了
sudo chmod u+x filename //给当前用户加上可执行权限
u：用户
g：组
o：其它用户
a：所有用户

```shell
$chmod a+x main         对所有用户给文件main增加可执行权限
$chmod g+w blogs        对组用户给文件blogs增加可写权限
```

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

> chown username filename


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
查看硬盘存储空间:
```shell
df -h //h的意思是human-readable
du -sh //查看当前directory的大小
du -h //查看当前目录下各个子目录分别的大小
dh -h img// 查看img目录下文件及文件夹的大小
dh -h img/1.jpg //查看指定文件的大小
du -hsBM //查看当前目录的大小(s表示summary)，以MB为单位
du -hsBM /var/* | sort -n //查看/var目录下全部文件，从小到大排列
```
```
查看cpu信息
> cat /proc/cpuinfo

查看内存
> cat /proc/meminfo | grep Mem
>free -m
free -h # human readable

修改默认安全设置
> vi /etc/ssh/ssd_config
```

添加或修改
```shell
Port 22 (ssh默认端口修改)
PermitRootLogin without-Password no
AllowUsers userName
```
把登录端口改大一点还是很有必要的，亲测不难
```
vi /etc/ssh/sshd_config
service ssh restart
```
搞定

看下成功登录历史
```shell
- last | less | sort -rn

### who 命令更好，是指wtmp文件创建以来的登录记录
who /var/log/wtmp
```

压缩文件命令
将/home/video/ 这个目录下所有文件和文件夹打包为当前目录下的video.zip
```
zip –q –r -v video.zip . #加上一个-v主要是为了能够实时查看输出
```
文件传输（linux ->windows）： 一般使用putty ssh到Linux主机，想要把Linux上的文件弄到Windows中，需要使用pscp工具。下载好pscp.exe后，放到c:/windows/system32下面。打开cmd。输入命令
```shell
 pscp -r root@202.123.123.123:"/root/fileonServer.mp4" d:/whateveriwantonmyPc.mp4  
```
 ，确认后输入root密码就好了。我主要是用来下载视频的。
有时候会出现Connection Refused Error。
```shell
> netstat -anp | grep sshd
```

看下跑在哪个端口
然后
> pscp -P 12345-r root@202.123.123.123:"/root/fileonServer.mp4" d:/whateveriwantonmyPc.mp4  ## -p要大写

### 8. 软件的安装，卸载(dpkg命令，不要只会apt-get)
 在debian下，你可以使用dpkg(Debian package system)来安装和卸载软件包。
 还是那句话，没事不要手贱升级软件
```shell
### （1）移除式卸载：
apt-get remove softname1 softname2 …; （移除软件包，当包尾部有+时，意为安装）
### （2）清除式卸载 ：
apt-get --purge remove softname1 softname2...;(同时清除配置)
### 清除式卸载：
apt-get purge sofname1 softname2...;(同上，也清除配置文件)

### （1）移除式卸载：
dpkg -r pkg1 pkg2 ...;

###（2）清除式卸载：
dpkg -P pkg1 pkg2...;

### 使用dpkg安装deb包
dpkg -i tcl8.4_8.4.19-2_amd64.deb  

###使用kpkg -r来删除deb包
dpkg -r tcl8.4
```
参考[Ubuntu 中软件的安装、卸载以及查看的方法总结](http://qiuye.iteye.com/blog/461394)

关于apt-get
```shell
apt-cache search # ------(package 搜索包)就是看下符合这个名称的在repository中包有哪些
apt-cache show #------(package 获取包的相关信息，如说明、大小、版本等)
apt-get install # ------(package 安装包)
apt-get install # -----(package --reinstall 重新安装包)
apt-get -f install # -----(强制安装, "-f = --fix-missing"当是修复安装吧...)
apt-get remove #-----(package 删除包)
apt-get remove --purge # ------(package 删除包，包括删除配置文件等)
apt-get autoremove --purge # ----(package 删除包及其依赖的软件包+配置文件等（只对6.10有效，强烈推荐）)
apt-get update #------更新源
apt-get upgrade #------更新已安装的包
apt-get dist-upgrade # ---------升级系统
apt-get dselect-upgrade #------使用 dselect 升级
apt-cache depends #-------(package 了解使用依赖)
apt-cache rdepends # ------(package 了解某个具体的依赖,当是查看该包被哪些包依赖吧...)
apt-get build-dep # ------(package 安装相关的编译环境)
apt-get source #------(package 下载该包的源代码)
apt-get clean && apt-get autoclean # --------清理下载文件的存档 && 只清理过时的包
apt-get check #-------检查是否有损坏的依赖
dpkg -S filename -----查找filename属于哪个软件包
apt-file search filename -----查找filename属于哪个软件包
apt-file list packagename -----列出软件包的内容
apt-file update --更新apt-file的数据库

dpkg --info "软件包名" --列出软件包解包后的包名称.
dpkg -l --列出当前系统中所有的包.可以和参数less一起使用在分屏查看. (类似于rpm -qa)
dpkg -l |grep -i "软件包名" --查看系统中与"软件包名"相关联的包.
dpkg -s 查询已安装的包的详细信息.
dpkg -L 查询系统中已安装的软件包所安装的位置. (类似于rpm -ql)
dpkg -S 查询系统中某个文件属于哪个软件包. (类似于rpm -qf)
dpkg -I 查询deb包的详细信息,在一个软件包下载到本地之后看看用不用安装(看一下呗).
dpkg -i 手动安装软件包(这个命令并不能解决软件包之前的依赖性问题),如果在安装某一个软件包的时候遇到了软件依赖的问题,可以用apt-get -f install在解决信赖性这个问题.
dpkg -r 卸载软件包.不是完全的卸载,它的配置文件还存在.
dpkg -P 全部卸载(但是还是不能解决软件包的依赖性的问题)
dpkg -reconfigure 重新配置
```


### 9. 网络监控
tcpdump结合wireshark可实现完整的网络抓包，这个放在下面写。




```shell
netstat
netstat -i ## 查看某个网络接口发出和接收了多少byte的数据
netstat -ta ##当前active的网络连接  t: tcp a: all u: udp p:process
netstat -tan ##以ip地址的方式展示出来 n: 禁止域名解析，就是不显示域名，直接显示ip
netstat -tupln ##tcp+udp+program name+监听的端口+numerically
netstat -ie ##比较友好的方式展示当前各个端口的流量，就是显示每个网卡发送的流量，接收的流量一共多少MB,这种
netstat -nlpt ##获取进程名、进程号以及用户 ID
netstat -s ##可以打印出网络统计数据，包括某个协议下的收发包数量。
netstat -ct ## c:持续输出

## 使用watch命令监视active状态的连接，实时显示网络流量
watch -d -n0 "netstat -atnp | grep ESTA"
```


```shell
ifconfig ## 查看机器上的网卡
en01 ##Ethernet
##注意 RX bytes(接收到的数据)和TX bytes(发送出去的数据)后面的数字


sudo curl ifconfig.me ## 需要sudo，查看本机的外网地址，有点慢
```

### 10.查看进程

[起一个进程，后台运行，关掉终端照样跑的那种](https://stackoverflow.com/questions/4797050/how-to-run-process-as-background-and-never-die)

>  nohup node server.js > /dev/null 2>&1 &

```
nohup node server.js > /dev/null 2>&1 &

1. nohup means: Do not terminate this process even when the stty is cut off.
2. > /dev/null means: stdout goes to /dev/null (which is a dummy device that does not record any output).
3. 2>&1 means: stderr also goes to the stdout (which is already redirected to /dev/null). You may replace &1 with a file path to keep a log of errors, e.g.: 2>/tmp/myLog
4. & at the end means: run this command as a background task.
```


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
```
```shell
#列出所有端口的占用情况
netstat -anp
lsof -i # 这个也行
#查看哪个进程占了http端口(其实就是80了)
lsof -i:80
#查看某个进程占了哪些端口
netstat -anp|grep pid
lsof //list opened files
## 查看端口占用

## 杀进程（如果进程不属于当前用户，要sudo）
## 杀进程，慎用。
kill -9 进程id // 9直接干掉进程，慎用。。。
kill pid // 这个和kill 15是一样的 //15表示terminate,请求进程停下来  

kill -l //列出进程及id

killall nginx ->> 干掉nginx的所有进程

pkill -u username //干掉所有属于某一个用户的ps

Signal (信号)  man signal

进程状态
runnable、sleeping、zombie、stop

//更改友善度,数字越小越不友好
nice -n 15 /.....   命令path。启动的时候确定nice
renice -s pid //更改友善度

df -ah  // 查看mounted文件系统
proc
```

### 11 .常用配置
 ***查看登陆失败日志***
> grep "Failed password for root" /var/log/auth.log | awk '{print $11}' | sort | uniq -c | sort -nr | more

防范措施
修改登陆端口号
```
sudo vi /etc/ssh/sshd_config
Port 4484
PermitRootLogin no

###改了sshd_config之后千万记得重启ssh服务，不然会出现connection refused.
/etc/init.d/ssh restart

##CentOS 重启SSH ：
service sshd restart
###DeBian重启SSH：
service ssh restart
```
查看系统release版本
```shell
more /etc/*release
### 这个也行
lsb_release -a
```

[编码的修改](https://perlgeek.de/en/article/set-up-a-clean-utf8-environment)
更改locale为utf-8(ubuntu)
```shell
vi ~/.bashrc

# add these lines
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

sudo locale-gen "en_US.UTF-8"
sudo dpkg-reconfigure locales
```

### 12. sed命令
sed 是一种在线编辑器，***它一次处理一行内容***。处理时，把当前处理的行存储在临时缓冲区中，称为“模式空间”（pattern space），接着用sed命令处理缓冲区中的内容，处理完成后，把缓冲区的内容送往屏幕。接着处理下一行，这样不断重复，直到文件末尾。文件内容并没有 改变，除非你使用重定向存储输出。
本身是不会更改文件内容的。
```shell
##把一段字符串插入文件的第四行和第五行之间，默认是送到了标准输出，加一个重定向更改了文件内容
sed -e 4a\/"this will be append to the 5th line" sample.txt >> sample.txt ## 注意这个斜杠是为了语法高亮加的

## 将 /etc/passwd 的内容列出并且列印行号，同时，请将第 2~5 行删除！
nl /etc/passwd | sed '2,5d'
```

### 13. iptable
> iptables -L -n -v ## 查看已添加的iptables规则

默认是全部接受的
```
Chain INPUT (policy ACCEPT) ## 允许进入这台电脑
target     prot opt source               destination

Chain FORWARD (policy ACCEPT)  ## 路由相关
target     prot opt source               destination

Chain OUTPUT (policy ACCEPT) ## 允许发出这台电脑
target     prot opt source               destination
```

```shell
iptables -P FORWARD DROP ## 把forward 一律改为drop
iptables -A INPUT -s  192.168.1.3  ## A是append s是source，拒绝接受192.168.1.3的访问，就是黑名单了
iptables -A INPUT -s  192.168.0.0/24 -p tcp --destination-port 25 -j DROP  ## block all devices on this network ,  p是protocol,SMTP一般是25端口

iptables -A INPUT -s 192.168.0.66 -j ACCEPT  ## 白名单
iptables -D INPUT 3 ##这个3是当前INPUT表的第3条规则
iptables -I INPUT -s 192.168.0.66 -j ACCEPT  ## 白名单，和-A不同，A是加到尾部，I是加到list的头部，顺序很重要。

iptables -I INPUT -s 123.45.6.7 -j DROP       #屏蔽单个IP的命令
iptables -I INPUT -s 123.0.0.0/8 -j DROP      #封整个段即从123.0.0.1到123.255.255.254的命令
iptables -I INPUT -s 124.45.0.0/16 -j DROP    #封IP段即从123.45.0.1到123.45.255.254的命令

## 清除已有iptables规则
iptables -F
iptables -X
iptables -Z
```

### 14. 多个tty(TeleTYpewriter)
[how-to-multitask-in-the-linux-terminal-3-ways-to-use-multiple-shells-at-once](https://www.howtogeek.com/111417/how-to-multitask-in-the-linux-terminal-3-ways-to-use-multiple-shells-at-once/)
> sudo apt-get install screen
> screen 。进入一个新的GNU screen // 可以执行耗时指令
> 按住ctrl +a ，再按d 。退出screen
> screen -r // 重新进刚才的screen

### 15. ipv6 howto
```shell
## 首先在开启ipv6的机器上确认是否开启了ipv6
ifconfig ## 看下是否有ipv6 address
netstat -tuln ## 看下当前连接中是否有ipv6 addr
ifconfig的输出大致如下：

inet6 addr: 2001:xxxx:xxxx:xxxx:xxxx:xxxx:xxxx/64 Scope:Global
inet6 addr: fe80::xxxx:xxxx:xxxx:xxxx/64 Scope:Link
[What’s that % sign after ipconfig IPv6 address?](https://howdoesinternetwork.com/2013/ipv6-zone-id)
## 那个/64不要管，2001.xxx粘贴到[ipv6now](http://ipv6now.com.au/pingme.php)
## 然后用一些online ipv6 website ping一下
```


### 16.netcat , cryptcat
[oracle page](https://docs.oracle.com/cd/E56344_01/html/E54075/netcat-1.html)
netcat是网络工具中的瑞士军刀，它能通过TCP和UDP在网络中读写数据。netcat所做的就是在两台电脑之间建立链接并返回两个数据流。
netcat = nc
```shell
nc -z -v -n 172.31.100.7 21-100  ##用来扫描这台机器上开放的端口，用来识别漏洞
z 参数告诉netcat使用0 IO,连接成功后立即关闭连接， 不进行数据交换
v 参数指使用冗余选项 verbose
n 参数告诉netcat 不要使用DNS反向查询IP地址的域名 numeric
u 参数使用udp ，默认是tcp

## on the server side ，创建一个chat 服务器
netcat -l -p 38929 ## l listen p port ，大写的L表示socket断了之后自动重连
## client
nc 172.31.100.7 38929

### now the server and client can talk to each other

## 文件传输
### server
nc -l 1567 < file.txt
## client
nc -n 172.31.100.7 1567 > file.txt

### 传输目录
### server
tar -cvf – dir_name | nc -l 1567
### client
nc -n 172.31.100.7 1567 | tar -xvf -
```
[Linux Netcat 命令——网络工具中的瑞士军刀 ](http://www.oschina.net/translate/linux-netcat-command)


### 17. WireShark and netcap
首先是wireShark和fiddle的对比[Wireshark vs Firebug vs Fiddler - pros and cons?](https://stackoverflow.com/questions/4263116/wireshark-vs-firebug-vs-fiddler-pros-and-cons)

> Wireshark, Firebug, Fiddler all do similar things - capture network traffic.
Wireshark captures any kind of a network packet. It can capture packet details below TCP/IP(Http is at the top). It does have filters to reduce the noise it captures.
Fiddler works as a http/https proxy. It captures each http request the computer makes and records everything associated with it. Does allow things like converting post varibles to a table form and editing/replaying requests. It doesn't, by default, capture localhost traffic in IE, see the FAQ for the workaround.
The benefit of WireShark is that it could possibly show you errors in levels below the HTTP protocol. Fiddler will show you errors in the HTTP protocol.

简单来说就是fiddle只抓http(s)层的packet,wireShark抓的是tcp(udp)层的。 wireShark > fiddler(Charles 也差不多，只抓http层的)

基本的流程是：首先在linux上生成dump.pcap文件，然后在wireShark中打开(对了要先去wireshark官网下windows的安装文件，注意不要装上全家桶就是了)；

[聊聊tcpdump与Wireshark抓包分析](https://my.oschina.net/xianggao/blog/678644)
```shell
sudo tcpdump -i "venet0:0"  //tcpdump需要sudo权限
sudo tcpdump -c 10 //count
sudo tcpdump -c -A  //Asicii码形式展示出来每个package
sudo tcpdump -c 5 -i wlo1 // 监听某一个网卡
sudo tcpdump -c 5 -i wlo1 port 22// 监听某一个网卡某一个端口
sudo tcpdump -i eth0 -w dump.pcap -v //w表示要保存的文件的位置
// 注意运行上述指令的时候，会显示Got 18 这种提示，意味着已经抓到了多少个包，这个数其实也是随着时间流逝一直增长的。
ctrl+c停止抓包，会生成一个dump.pcap文件(不要尝试着去cat 或者less，是一个binary 文件，会崩的)。


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



==================================================================================
## [shell script tutorial](https://www.youtube.com/watch?v=hwrnmQumtPw)


### 参考

- ![](http://odzl05jxx.bkt.clouddn.com/fork_you_git.jpg)
- [工具参考](http://linuxtools-rst.readthedocs.io/zh_CN/latest/tool/sar.html)
- [文件大小查看命令](https://my.oschina.net/liting/blog/392051)
- [文件压缩命令](http://blog.sina.com.cn/s/blog_7479f7990100zwkp.html)
- [硬件查询](https://my.oschina.net/hunterli/blog/140783)
- [Python源码编译安装ss](http://www.jianshu.com/p/3d80c7cb7b17)
- [源码编译安装ss](http://blog.csdn.net/program_thinker/article/details/45787395)
- [修改系统编码为utf-8](https://askubuntu.com/questions/162391/how-do-i-fix-my-locale-issue)
- [Linux工具快速教程](http://linuxtools-rst.readthedocs.io/zh_CN/latest/index.html)
