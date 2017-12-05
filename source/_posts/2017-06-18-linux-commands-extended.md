---
title: linux常用命令扩展
date: 2017-06-18 16:51:49
categories: blog
tags:
  - linux
---
> 一些linux的常用命令，linux环境下运行server ,bash的语法
>  

![](http://odzl05jxx.bkt.clouddn.com/ChMkJ1gq00WIXw_GAA47r_8gjqgAAXxJAH8qOMADjvH566.jpg?imageView2/2/w/600)

<!--more-->

## 速查
1. [清理大文件](#5-linux删除垃圾文件（小硬盘linux磁盘要经常清理需要的命令）)


### 1. 常用软件安装
[utorrent](http://blog.topspeedsnail.com/archives/5752)
apache,mysql
没事不要手贱升级软件
> apt-get -u upgrade //就像这样，stable挺好的

### 2. 环境变量怎么改
平时在shell中输入sudo XXX ,系统是如何知道怎么执行这条指令的呢。首先，可以查看which XXX ，用于查找某项指令对应的文件的位置。而像sudo这种都放在PATH位置，系统会在几个关键位置查找sudo命令。用户本身完全可以创建一个叫做sudo的文件chmod+X ，然后运行这个sudo。
```
查看PATH : echo $PATH
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games (注意，系统是按照这个顺序找的，如果在第一个目录下找到一个叫sudo的东西，就会直接执行了，所以这里是有潜在的危险的)
看下哪个命令对应的位置在哪里
which XXXk
比如sudo 就放在 /usr/bin/sudo


> $PATH
环境变量修改在~./bashrc或者 ~./profile里面
具体来说，比如要把/etc/apache/bin目录添加到PATH中
PATH=$PATH:/etc/apache/bin  #只对本次回话有效
或者  PATH=$PATH:/etc/apache/bin #在~./bashrc或者~./profile里面添加这句话
```


### 3. alias设置
查看已经设置过的alias：  alias或者 alias -p
vi 中输入 /XXX 可以搜索
```shell
vi ~/.bashrc  ## 这个是对当前用户生效的
/etc/bashrc 写到文件这里面是对所有用户生效
alias yourcommand='ls -alr' ##添加这一行，原来的命令也照样用
```
重开session即可生效
急着要想马上生效可以
source ~/.bashrc ## source命令其实就是执行一个脚本

据说alias是可以传参数的，不过加上> /dev/null 2>&1 & 就不行了。所以还是写个script算了。
```shell
#!/bin/bash
kwrite $1 > /dev/null 2>&1 &
```
然后chomod 755 fileName

### 4. pushd和popd（类似于文件夹stack）

### 5. linux删除垃圾文件（小硬盘linux磁盘要经常清理需要的命令）
IBM给出了删除一些垃圾文件的建议[使用 Linux 命令删除垃圾文件](https://www.ibm.com/developerworks/cn/linux/1310_caoyq_linuxdelete/index.html)

> sudo apt-get autoclean 清理旧版本的软件缓存
sudo apt-get clean 清理所有软件缓存
sudo apt-get autoremove 删除系统不再使用的孤立软件
du --max-depth=1 -h # 查看当前路径下所有文件/文件夹的大小
du -k --max-depth=2 | sort -rn # 加上排序
find / -name core -print -exec rm -rf {} \; //分号也要，亲测
find / -size +100M：列出所有大于100M的文件，亲测。靠着这个找到了shadowsocks的日志文件,170MB

删除/boot分区不需要的内核
先df -h看/boot分区使用情况；
然后 dpkg --get-selections|grep linux-image ;
查看当前使用的内核 uname -a ;
清理不用的内核 sudo apt-get purge linux-image-3.13.0-24-generic （注意，不要删正在使用的内核）
删除不要的内核文件
首先看下
> uname- a
dpkg --get-selections|grep linux //查找所有的文件，有image的就是内核文件
sudo apt-get remove 内核文件名 （例如：linux-image-4.4.0-92-generic）

/var/log/btmp 这个文件是记录错误登录的日志，如果开放22端口的话，用不了多久这个文件就会变得很大
系统 /var/log 下面的文件：btmp, wtmp, utmp 等都是二进制文件，是不可以使用 tail 命令来读取的，[这样会导致终端出错](https://blog.lmlphp.com/archives/212/Modify_sshd_config_file_configuration_to_prevent_the_Linux_var_log_btmp_file_content_size_is_too_large)。一般使用 last 系列命令来读取，如 last, lastb, lastlog。

一个目录下按照文件大小排序
-  ls -Sralh ## 亲测，从小到大排序出来
加上-S参数，就可以根据文件的大小进行排序，默认是从大到小的顺序。在此基础上加上参数-r变成-Sr，就可以一自小到大的顺序打印出文件。-l参数表示打印出详细信息。



### 6. AWK文本分析工具
- awk '{print $0}' /etc/passwd # 和cat差不多，显示文本内容
查看恶意IP试图登录次数：
- lastb | awk '{ print $3 }' | sort | uniq -c | sort -n  ## 亲测可用,看上去挺吓人的

### 7.tar命令
主要是跟压缩和解压文件有关的,[参考](http://man.linuxde.net/tar)
```
tar -cvf log.tar log2012.log 仅打包，不压缩！
tar -zcvf log.tar.gz log2012.log 打包后，以 gzip 压缩
tar -jcvf log.tar.bz2 log2012.log 打包后，以 bzip2 压缩
```

对照手册来看：
-c //小写的c，--create，表示创建新的备份文件
-v //verbose,显示进度什么的
-f 指定备份文件
-z --gzip，通过gzip压缩或者解压文件

### 8.定时任务怎么写
已经有网站把各种常用的[example](https://crontab.guru/every-6-hours)写出来了，直接照抄就是
后面跟上需要的命令，例如重启就是 /sbin/reboot

### 9. 查找相关(grep,find)
在文件中查找字符串，不区分大小写
- grep -i "sometext" filenname
在一个文件夹里面的所有文件中递归查找含有特定字符串的文件
- grep -r "sometext" *

find
根据文件名查找文件
```
- find -name *.config  #在当前目录下查找
- find / -name finename # 在根目录下查找filename的文件("filename"用双引号包起来)
```

### 10.已安装的软件
- sudo dpkg -l

### 11.Ping一个主机
- ping -c 5 gmail.com #只发送5次

### 12.Wget
下载文件
- wget url
下载文件并以指定的文件名保存下来
- wget -0 filename url

### 13.查看文件的时候显示行号
cat -n rsyslog.conf # 显示行号，报错的时候方便处理
-n   显示行号（包括空行）
-b   显示行号（不包括空行）

### 14.统计文件夹下特定文件类型的数目
- ls -l |grep "^-"|wc -l  ##统计某文件夹下文件的个数
- ls -l |grep "^ｄ"|wc -l ##统计当前目录中文件夹的数量
- ls -lR|grep "^-"|wc -l ##递归一层层往下找的话，加上一个R就可以了
统计某个目录下的所有js文件：
- ls -lR /home/user|grep js|wc -l
- ls -alh ## 亲测，可以显示当前目录下各个文件的大小

### 15. curl命令
写shell脚本可能会用到网络交互，curl可以发起网络请求，下载文件，上传文件，cookie处理，断点续传，分段下载,ftp下载文件
随便写两个：
- curl -o home.html http://www.baidu.com  #把百度首页抓下来，写到home.html中
- curl -d "user=nick&password=12345" http://www.xxx.com/login.jsp # 提交表单，发起POST请求
记得http statusCode 302是重定向什么 ：
- curl -v mail.qq.com
输出：
```
curl -v mail.qq.com
* Rebuilt URL to: mail.qq.com/
*   Trying 103.7.30.100...
* Connected to mail.qq.com (103.7.30.100) port 80 (#0)
> GET / HTTP/1.1
> Host: mail.qq.com
> User-Agent: curl/7.47.0
> Accept: */*
>
< HTTP/1.1 302 Found
< Server: TWS
< Connection: close
< Date: Sun, 19 Nov 2017 09:19:46 GMT
< Content-Type: text/html; charset=GB18030
< Location: https://mail.qq.com/cgi-bin/loginpage
< Content-Security-Policy: referrer origin; script-src 'self' https://hm.baidu.com http://hm.baidu.com *.google-analytics.com http://mat1.gtimg.com https://mat1.gtimg.com http://*.soso.com https://*.soso.com http://*.qq.com https://*.qq.com http://*.qqmail.com  https://*.qqmail.com http://pub.idqqimg.com blob: 'unsafe-inline' 'unsafe-eval'; report-uri https://mail.qq.com/cgi-bin/report_cgi?r_subtype=csp&nocheck=false
< Referrer-Policy: origin
< Content-Length: 0
<
* Closing connection 0
```
http 302的意思也就说明qq邮箱已经把http重定向到别的地方的

### 16. 搭建samba服务器
这个主要是用来从windows上访问linux主机上的文件的
- sudo apt-get install samba
剩下的就是设定要分享的目录，给权限，设定访问密码，启动服务这些了[教程](http://www.cnblogs.com/gzdaijie/p/5194033.html)

### 17. tee命令
- echo $(date) | tee -a date.log
tee命令能够吧程序的输出输出到stdo,同时还能将输出写进文件(-a 表示append，否则就是覆盖)

### 18.  missing argument to \`-exec'
```shell
find /u03 -name server.xml -exec grep '9080' {}\;
find . -type f -exec ls -l {} \; ## exec执行删除之前最好先打印出来，避免删错了
find . -type f -mtime +14 -exec rm {} \;
```
exec是和find一起使用的，分号是要执行的命令的终止标志，前面得加上斜杠。
简单来说，就是把exec前面的结果执行某项操作，语法上，大括号不能少，反斜杠不能少，分号不能少
感觉exec和find 命令的xargs差不多
[xargs命令](http://www.cnblogs.com/peida/archive/2012/11/15/2770888.html)
[exec命令](http://www.cnblogs.com/peida/archive/2012/11/14/2769248.html)

### 19. sort命令
sort命令排序什么的
```
ls -al | sort -n ## 按照文件名ASCII码值进行比较
ls -al | sort -rn ## 按照文件名倒序排序
du -hsBM ./* | sort -n  ##查看当前目录下所有文件，从小到大排序
```
-u(unique)是忽略相同行，查找登录记录的时候有用
-t 指定按照栏和栏之间的分隔符

### 20. history命令
```
history ## 列出曾经执行过的命令
!99 ##执行上面列表中第99条命令
!! ##执行上一条命令
history 10 ##列出最近执行的10条命令
```

### 21. 使用sshKeyGen免密码登录的方式
首先在windows上安装putty，默认会装上puttyGen。
在开始菜单里面总归能找到。
点击那个generate按钮，按照提示鼠标不停挪动，进度条走完。会生成公钥，点击Save private key生成私钥。提示保存在一个文件中，这个要保存好。
密码登录到服务器端，cd到~/.ssh/文件夹下，没有就mkdir一个，创建一个authorized_keys的文件，要是本来就有，echo > autorized_keys，把内容清除干净。
把自己刚才生成的public key粘贴进去，保存文件。
看下/etc/ssh/sshd_config中是否符合如下描述如下条件
```
RSAAuthentication yes
PubkeyAuthentication yes
PermitRootLogin yes
```

重启ssh服务： service sshd restart
putty登录窗口左侧有一个loggin-auth，进去选择自己windows上刚才保存的私钥文件。登录输入账户名即可自动登录成功。
[PUTTYGEN - KEY GENERATOR FOR PUTTY ON WINDOWS](https://www.ssh.com/ssh/putty/windows/puttygen)

### 22.iptables命令
用防火墙屏蔽掉指定ip

```shell
iptables -L -n ## 查看已添加的iptables规则
清除已有iptables规则
iptables -F
iptables -X
iptables -Z
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
**注意还需要将上述规则添加到开机启动中**，还有使用iptables屏蔽来自[某个国家的IP](https://www.vpser.net/security/iptables-block-countries-ip.html)的教程


## 23. 变量($其实就是美元符号了)
变量调用符号($)
```shell
LI=date
$LI ##
# Tue Dec  5 04:06:18 EST 2017

# 所以经常会有这样的脚本
# Check if user is root
if [ $(id -u) != "0" ]; then
    echo " Not the root user! Try using sudo Command ! "
    exit 1
fi
echo "Pass the test! You are the root user!"

## 亲测下面这种可用户
if [ `whoami` = "root" ];then  
    echo "root用户！"  
else  
    echo "非root用户！"  
fi
```
变量分为用户自定义的和环境变量（其实就是系统预设的）,有些区别
> 用户自定义变量只在当前的shell中生效，环境变量在当前shell和这个shell的所有子shell中生效。
环境变量是全局变量，用户自定义变量是局部变量。
对系统生效的环境变量名和变量作用是固定的。

### 常用的环境变量
> HOSTNAME：主机名
SHELL：当前的shell
TREM：终端环境
HISTSIZE：历史命令条数
SSH_CLIENT：当前操作环境是用ssh链接的，这里记录客户端的ip
SSH_TTY：ssh连接的终端是pts/1
USER:当前登录的用户

```shell
echo $HOSTNAME
## unbutu
$? 最后一次执行的命令的返回状态。如果这个变量的值为0，证明上一个命令正确执行；如果这个变量的值非0（具体是哪个数，由命令自己决定），则证明上一个命令执行不正确了。
$$ 当前进程的进程号（PID）
$! 后台运行的最后一个进程的进程号（PID）
```


Mere trash
===============================================================================
[LINUX下的21个特殊符号](http://blog.51cto.com/litaotao/1187983)
[Shell学习笔记](https://notes.wanghao.work/2015-06-02-Shell%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.html)




ls -al = l -al（可以少敲一个字母,其实是alias）



[装java](https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-get-on-ubuntu-16-04)
[装Jenkins](https://www.digitalocean.com/community/tutorials/how-to-install-jenkins-on-ubuntu-16-04)
Could not find or load main class的问题

## 参考
- [每天一个Linux命令](http://www.cnblogs.com/peida/archive/2012/12/05/2803591.html)
- [Linux命令大全](http://man.linuxde.net/xargs)
- [awk是三个人的名字](https://mp.weixin.qq.com/s/L0oViwqjIgudY-SrV0paRA)
- [树莓派搭建局域网媒体服务器，下载机](http://www.cnblogs.com/xiaowuyi/p/4051238.html)
- [Linux中国](https://linux.cn/tech/sa/index.php?page=4)
