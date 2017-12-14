---
title: linux基本命令介绍
date: 2017-01-07 15:38:43
categories: blog
tags: [置顶,linux,tools]
top : 1
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

```
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
- > xxd -b fileName // 看binaryFile不能用cat
```

tail还有一个好处，可以实时查看文件内容，比如文件正在更新，可以实时查看最新的日志
> tail -f /var/log/messages

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
apt-cache search # ------(package 搜索包)
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
```shell
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
netstat -tupln //tcp+udp+program name+监听的端口+numerically
netstat -ie //比较友好的方式展示当前各个端口的流量
```

```
ifconfig // 查看机器上的网卡
en01 //Ethernet
注意 RX bytes(接收到的数据)和TX bytes(发送出去的数据)后面的数字
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



### 参考

- ![](http://odzl05jxx.bkt.clouddn.com/fork_you_git.jpg)

- [文件大小查看命令](https://my.oschina.net/liting/blog/392051)
- [文件压缩命令](http://blog.sina.com.cn/s/blog_7479f7990100zwkp.html)
- [硬件查询](https://my.oschina.net/hunterli/blog/140783)
- [Python源码编译安装ss](http://www.jianshu.com/p/3d80c7cb7b17)
- [源码编译安装ss](http://blog.csdn.net/program_thinker/article/details/45787395)
- [修改系统编码为utf-8](https://askubuntu.com/questions/162391/how-do-i-fix-my-locale-issue)
