---
title: linux常用命令扩展
date: 2017-06-18 16:51:49
categories: blog
tags:
  - linux
---
> 一些linux的常用命令，linux环境下运行server ,bash的语法
>  

![](http://haldir66.ga/static/imgs/ChMkJ1gq00WIXw_GAA47r_8gjqgAAXxJAH8qOMADjvH566.jpg)

<!--more-->

## 速查
1. [清理大文件](#5-linux删除垃圾文件（小硬盘linux磁盘要经常清理需要的命令）)


### 1. 常用软件安装
[utorrent](http://blog.topspeedsnail.com/archives/5752)
apache,mysql
没事不要手贱升级软件
> apt-get -u upgrade //就像这样，stable挺好的
sudo apt update
sudo apt full-upgrade ## 更新所有软件

### 2. 环境变量怎么改(这个有临时改和永久生效两种)

临时改（下次登录失效这种）
export PATH=$PATH:/home/directory/to/the/folder
echo $PATH ## 看下改好没

export FLASK_DEBUG=1
$FLASK_DEBUG
>> 1


永久生效（谨慎为之）
修改/etc/profile文件：（对所有用户都生效）
export PATH="$PATH:/home/directory/to/the/folder"

修改~/.bashrc文件： （对当前用户有效）
export PATH="$PATH:/home/directory/to/the/folder"

注： 在windows下export要换成set,echo $XXX 要换成echo %XXX%

这个有效一般都需要重新注销系统才能生效

set可以查看当前用户本地shell设置的所有变量，用unset可以取消变量:
> set
unset $SOME_PROGRAM 


平时在shell中输入sudo XXX ,系统是如何知道怎么执行这条指令的呢。首先，可以查看which XXX ，用于查找某项指令对应的文件的位置。而像sudo这种都放在PATH位置，系统会在几个关键位置查找sudo命令。用户本身完全可以创建一个叫做sudo的文件chmod+X ，然后运行这个sudo。
```
查看PATH : echo $PATH 
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games (注意，系统是按照这个顺序找的，如果在第一个目录下找到一个叫sudo的东西，就会直接执行了，所以这里是有潜在的危险的)
看下哪个命令对应的位置在哪里
which XXXk
比如sudo 就放在 /usr/bin/sudo


 $PATH
环境变量修改在~./bashrc或者 ~./profile里面
具体来说，比如要把/etc/apache/bin目录添加到PATH中
PATH=$PATH:/etc/apache/bin  #只对本次会话有效
或者  PATH=$PATH:/etc/apache/bin #在~./bashrc或者~./profile里面添加这句话
```
比如把facebook 的buck添加到环境变量：
```shell
$ cd ~
$ vim ~/.bash_profile
export PATH=$HOME/buck/bin:$PATH
$ source ~/.bash_profile ## 立刻生效
```
顺便说下widnows下怎么看环境变量： echo %path%


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

> touch ~/.bash_aliases  ## unbuntu建议把所有的alias写到一个 ~/.bash_aliases文件里。保存之后,source ~/.bash_aliases。立即生效

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

autoremove有时候会报错：
> The link /initrd.img.old is a damaged link
Removing symbolic link initrd.img.old
 you may need to re-run your boot loader[grub]

 根据[askubuntu](https://askubuntu.com/questions/518997/how-do-i-re-run-boot-loader)的解答，不用管

>
du --max-depth=1 -h # 查看当前路径下所有文件/文件夹的大小
du -k --max-depth=2 | sort -rn # 加上排序
find / -name core -print -exec rm -rf {} \; //分号也要，亲测
find / -size +100M：列出所有大于100M的文件，亲测。靠着这个找到了shadowsocks的日志文件,170MB
上面这个命令是不能列出文件大小的，还想要查看文件大小的话
find / -type f -size +50M -exec du -h {} \; | sort -n

删除/boot分区不需要的内核
先df -h看/boot分区使用情况；
然后 dpkg --get-selections|grep linux-image ;
查看当前使用的内核 uname -a ;
> lsb_release -a 

清理不用的内核 sudo apt-get purge linux-image-3.13.0-24-generic （注意，不要删正在使用的内核）
删除不要的内核文件
首先看下
> uname- a
dpkg --get-selections|grep linux //查找所有的文件，有image的就是内核文件
sudo apt-get remove 内核文件名 （例如：linux-image-4.4.0-92-generic）

sudo dpkg --get-selections | awk '$2 !~ /^install/' 查找那些状态是deinstall的内核，然后用这样的方式purge掉
sudo dpkg -P linux-image-3.5.0-51-generic


/var/log/btmp 这个文件是记录错误登录的日志，如果开放22端口的话，用不了多久这个文件就会变得很大
系统 /var/log 下面的文件：btmp, wtmp, utmp 等都是二进制文件，是不可以使用 tail 命令来读取的，[这样会导致终端出错](https://blog.lmlphp.com/archives/212/Modify_sshd_config_file_configuration_to_prevent_the_Linux_var_log_btmp_file_content_size_is_too_large)。一般使用 last 系列命令来读取，如 last, lastb, lastlog。

一个目录下按照文件大小排序
-  ls -Sralh ## 亲测，从小到大排序出来
加上-S参数，就可以根据文件的大小进行排序，默认是从大到小的顺序。在此基础上加上参数-r变成-Sr，就可以一自小到大的顺序打印出文件。-l参数表示打印出详细信息。



### 6. AWK文本分析工具
> AWK is a language for processing text files
awk was created at Bell labs released in 1977
Named after Alfred Aho, Peter Weinberger,and Brain Kernighan
TAPL= The AWK Programming Language

- awk '{print $0}' /etc/passwd # 和cat差不多，显示文本内容
查看恶意IP试图登录次数：
- lastb | awk '{ print $3 }' | sort | uniq -c | sort -n  ## 亲测可用,看上去挺吓人的

awk怎么用[Using Linux AWK Utility](https://www.youtube.com/watch?v=az6vd0tGhJI)，一个没有废话的教程，非常好。
[官方的古老的awk教程](ftp://ftp.gnu.org/old-gnu/Manuals/gawk-3.0.3/html_chapter/gawk_5.html)

> drwxr-xr-x  3 root root    4096 Mar 14  2017 ufw
-rw-r--r--  1 root root     338 Nov 18  2014 updatedb.conf
drwxr-xr-x  3 root root    4096 Aug 30 03:53 update-manager
drwxr-xr-x  2 root root    4096 Aug 30 03:53 update-motd.d
drwxr-xr-x  2 root root    4096 Mar 14  2017 update-notifier
drwxr-xr-x  2 root root    4096 Mar 14  2017 vim
drwxr-xr-x  3 root root    4096 Mar 14  2017 vmware-tools
lrwxrwxrwx  1 root root      23 Mar 14  2017 vtrgb -> /etc/alternatives/vtrgb
-rw-r--r--  1 root root    4942 Jun 14  2016 wgetrc
drwxr-xr-x  5 root root    4096 Mar 14  2017 X11
drwxr-xr-x  3 root root    4096 Mar 14  2017 xdg
drwxr-xr-x  2 root root    4096 Mar 14  2017 xml


假设你面对一个这样的文件test.txt
print 每一行 :  awk '{ print }' test.txt
print第一行 ： awk '{ print $1 }' test.txt
print第二行: awk '{ print $2 }' test.txt
print第一行和第二行 awk '{ print $1,$2 }' test.txt
print第一行和第二行中间不带空格 awk '{ print $1$2 }' test.txt
print包含'test'的行 awk '/test/ { print } test.txt'
print第二行包含'test'的行 awk '{if(2 ~ /test/) print }' test.txt
awk '/[a-z]/ { print }' test.txt  //包含a-z任一字母的
awk '/[0-8]/ { print }' test.txt // 包含0-8任一数字的
awk '/^[0-8]/ { print }' test.txt // 以0-8任一数字开头的
awk '/[0-8]$/ { print }' test.txt //以0-8任一数字结尾的


sudo last | awk '{ print $(NF-7)}' //我想看倒数第7列的数据

和管道结合的：
grep -i test test.txt | awk '/[0-9]/ { print }'
-i表示case insensitive,大小写都算.然后找出其中包含数字的。

想要找出系统内所有大小超出10MB的，合计一下这些大文件一共占用了多少MB的空间
sudo find / -size +10M -exec du -h {} \; | awk '{ s+=$1  } END { print s}'

awk -F '"' xxxxx ### 以双引号为分隔符的

[30个实用的awk命令](https://likegeeks.com/awk-command/)

awk正则
awk '$1 ~ /J/' inventory-shipped  ## 有大写字母J的话就打印出来
awk '$1 !~ /J/' inventory-shipped  ##排除所有包含J的内容




### 7.tar命令
主要是跟压缩和解压文件有关的,[参考](http://man.linuxde.net/tar)
```
tar -cvf log.tar log2012.log 仅打包，不压缩！
tar -zcvf log.tar.gz log2012.log 打包后，以 gzip 压缩
tar -jcvf log.tar.bz2 log2012.log 打包后，以 bzip2 压缩
```
[常用的tar命令就那么几个](https://www.jb51.net/LINUXjishu/43356.html)
tar -cvf all.tar.gz 和 tar -xf all.tar.gz这俩其实就够用了

对照手册来看：
-c //小写的c，--create，表示创建新的备份文件
-v //verbose,显示进度什么的
-f 指定备份文件
-z --gzip，通过gzip压缩或者解压文件

### 8.定时任务怎么写(crontab)
已经有网站把各种常用的[example](https://crontab.guru/every-6-hours)写出来了，直接照抄就是
后面跟上需要的命令，例如重启就是 /sbin/reboot

### 9. 查找相关(grep,find)
在文件中查找字符串，不区分大小写
- grep -i "sometext" filenname
在一个文件夹里面的所有文件中递归查找含有特定字符串的文件
- grep -r "sometext" *

[Linux 中 grep 命令的 12 个实践例子](http://blog.jobbole.com/112580/)

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

关于wc的一些参数
> -c 统计字节数。
-l 统计行数。
-m 统计字符数。这个标志不能与 -c 标志一起使用。
-w 统计字数。一个字被定义为由空白、跳格或换行字符分隔的字符串。
-L 打印最长行的长度。
-help 显示帮助信息
--version 显示版本信息
wc filename ##默认显示出来的三列分别是行数，字数，字节数

### 15. curl命令
写shell脚本可能会用到网络交互，curl可以发起网络请求，下载文件，上传文件，cookie处理，断点续传，分段下载,ftp下载文件
随便写两个：
- curl -o home.html http://www.baidu.com  #把百度首页抓下来，写到home.html中
- curl -d "user=nick&password=12345" http://www.xxx.com/login.jsp # 提交表单，发起POST请求
- [curl的几种常见用法](http://www.codebelief.com/article/2017/05/linux-command-line-curl-usage/)
- curl -i -H "Accept: application/json" "https://jsonplaceholder.typicode.com/posts" ## -i 表示include，就是说把header包含在response中
- 要是只需要header的话

下面是一个简单的通过CURL提交POST请求的方式
-X是指定HTTP method，默认是GET

>  curl --header "Content-Type: application/json" --request POST --data '{"userId":10,"title":"sometitle2","body":"somebody2"}' https://jsonplaceholder.typicode.com/posts
## 下面这个是简写
curl --header "Content-Type: application/json" -X POST -d '{"userId":10,"title":"sometitle2","body":"somebody2"}' https://jsonplaceholder.typicode.com/posts
## json规范不允许单引号
curl --header "Content-Type: application/json" -X POST -d '{"userId":10,"title":"sometitle2","body":"somebody2","hobby":[{"name":"bob","age":10},{"name":"sam","age":20}]}' http://127.0.0.1:5000/
### curl show raw response
curl -iv --raw https://www.google.com/ (#i是include header，v是verbose)

甚至还有直接一行行写html报文的：
```
echo 'GET / HTTP/1.1
Host: baidu.com
' | openssl s_client -quiet -connect baidu.com:443 2>/dev/null
```
 



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
find和exec命令结合起来能够实现指定（或者不指定）文件中查找特定字符的效果
比方说在sqlalchemy项目中，查找当前目录下所有的py文件，在里面扫描SQLALCHEMY_DATABASE_URI的值
>sudo find . -name "*.py" -exec grep "SQLALCHEMY_DATABASE_URI" {} \;
sudo find . -name "*.py" | xargs grep "SQLALCHEMY_DATABASE_URI"
grep SQLALCHEMY_DATABASE_URI . -R

上面这仨都是ok的 ,第一种不会把对应的文件名列出来，第二种和第三种会把文件名列出来。第三种的-R当然是递归(recursive)的意思

```shell
find /u03 -name server.xml -exec grep '9080' {}\;
find . -type f -exec ls -l {} \; ## exec执行删除之前最好先打印出来，避免删错了
find . -type f -mtime +14 -exec rm {} \;
find /etc -name "passwd*" -exec grep "root" {} \;
```
另外
> {} + 和 {} \; 这两种写法是有区别的[what-is-meaning-of-in-finds-exec-command(https://unix.stackexchange.com/questions/195939/what-is-meaning-of-in-finds-exec-command)


exec是和find一起使用的，分号是要执行的命令的终止标志，前面得加上斜杠。
简单来说，就是把exec前面的结果执行某项操作，语法上，大括号不能少，反斜杠不能少，分号不能少
感觉exec和find 命令的xargs差不多
find命令要结合着exec和xargs命令一起来看
[xargs命令](http://www.cnblogs.com/peida/archive/2012/11/15/2770888.html)
[exec命令](http://www.cnblogs.com/peida/archive/2012/11/14/2769248.html)
可以认为就是把find出来的所有结果填充到exec的大括号里面,因为平时实际从一个文件中查找字符的方式就是
grep "SQLALCHEMY_DATABASE_URI" somefilename
这也造成了使用exec经常出现语出错误，find命令把匹配到的文件传递给xargs命令，而xargs命令每次只获取一部分文件而不是全部，不像-exec选项那样。xargs是分批处理参数并传递给后续的命令。

xargs和grep一起用有时候会出现no such file or directory的错误
[why-does-grep-print-out-no-such-file-or-directory](https://stackoverflow.com/questions/44217298/why-does-grep-print-out-no-such-file-or-directory)
> find . -type f -print0 | xargs -0  fgrep "SQLALCHEMY_DATABASE_URI"

xargs的一些用法
find . -name "*.log" | xargs -i mv {} test4
find . -name "*.log" | xargs -p -i mv {} .. ## -p会提示用户是否要执行后续操作

find / -type ## 这个-type表示类型，f是普通文件,d是目录,c是字符设备文件,p是管道文件,l是符号链接文件

要想让系统高负荷运行，就从根目录开始查找所有的文件。  
find / -name "*" -print  
如果想在当前目录查找文件名以一个个小写字母开头，最后是4到9加上.log结束的文件：  
find . -name "[a-z]*[4-9].log" -print

find还可以根据文件权限来查找
find . -perm 755 -print ## 比如查找当前755权限的文件
find还可以忽略指定目录
-prune参数
还可以按照修改时间或者访问时间等来查找文件
sudo find / -size +10M -mtime -2 -exec du -h {} \; ## 查看最近两天修改的文件中那些大小超过了10M，并且列出来
sudo find / -name "*.log" -size +10k -mtime -2 -exec du -h {} \; | sort -n ## 把最近两天内修改的.log文件（超过10K的）按照文件大小从大到小排列出来
atime = accesstime(文件被read或者执行的时间)
ctime = changetime(文件状态改变时间，比如被chmod就算)
mtime = modify time，指的是文件内容被修改的时间
这些时间都能通过sta命令查看  


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
点击那个generate按钮，按照提示鼠标不停挪动，进度条走完。会生成公钥，点击Save private key生成私钥。提示保存在一个文件中，这个要保存好。暂时不要关闭puttygen,需要直接去复制粘贴那个public key(因为要是生成了一个public key，由于windows的原因，中间可能存在换行，就得在文本编辑器里面删掉所有的换行符，非常麻烦)
密码登录到服务器端，cd到~/.ssh/文件夹下，没有就mkdir一个，创建一个authorized_keys的文件，要是本来就有，echo > authorized_keys，把内容清除干净。
把自己刚才生成的public key粘贴进去，保存文件。
看下/etc/ssh/sshd_config中是否符合如下描述如下条件
```
RSAAuthentication yes
PubkeyAuthentication yes
PermitRootLogin yes
```
还要给权限
chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys
重启ssh服务： service sshd restart
putty登录窗口左侧有一个loggin-auth，进去选择自己windows上刚才保存的私钥文件。登录输入账户名即可自动登录成功。
[PUTTYGEN - KEY GENERATOR FOR PUTTY ON WINDOWS](https://www.ssh.com/ssh/putty/windows/puttygen)
[有什么问题的话看这个](https://stackoverflow.com/questions/6377009/adding-public-key-to-ssh-authorized-keys-does-not-log-me-in-automatically)

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


### 23. 变量($其实就是美元符号了)
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

### 24.  Linux软件安装目录惯例
转载自[](http://blog.csdn.net/aqxin/article/details/48324377)。
一般特定文件夹里放什么东西是有惯例的。
cd到根目录下长这样
drwxr-xr-x  26 root   root     4096 Jan 26 10:08 .
drwxr-xr-x  26 root   root     4096 Jan 26 10:08 ..
drwxr-xr-x   2 root   root    12288 Jan  5 22:52 bin ##sbin和bin一样，存executable programs
drwxr-xr-x   4 root   root     3072 Jan 26 10:08 boot
drwxr-xr-x  18 root   root     4060 Feb  3 17:00 dev
drwxr-xr-x 109 root   root     4096 Feb  4 04:18 etc ##configuration files , 比如passwd
drwxr-xr-x   3 root   root     4096 Aug  6 05:42 home ##所有用户的home directory
drwxr-xr-x  22 root   root     4096 Jan  5 22:53 lib ## 系统用的common library
drwxr-xr-x   2 root   root     4096 Jan 19 06:30 lib64 ##
drwx------   2 root   root    16384 Mar 14  2017 lost+found
drwxr-xr-x   3 root   root     4096 Mar 14  2017 media
drwxr-xr-x   2 root   root     4096 Feb 15  2017 mnt ##temp file systems are attached like cd rom or usb drive(就当优盘好了)
drwxr-xr-x   2 root   root     4096 Feb 15  2017 opt
dr-xr-xr-x 130 root   root        0 Feb  3 17:00 proc ##这个念procedure, 代表virtual file system stores kernel info，知道为什么看cpu型号要cat /proc了吧
drwx------   6 root   root     4096 Dec 21 02:16 root  ##root account的根目录
drwxr-xr-x  25 root   root      940 Feb  4 08:07 run
drwxr-xr-x   2 root   root    12288 Jan 19 06:30 sbin ##sbin和bin一样，存executable programs,s代表essential system binary
drwxr-xr-x   2 root   root     4096 Jan 14  2017 snap
drwxr-xr-x   2 root   root     4096 Feb 15  2017 srv
dr-xr-xr-x  13 root   root        0 Feb  4 08:08 sys
drwxrwxrwt   9 root   root     4096 Feb  4 08:05 tmp ## contain temporary data,注意，该目录下文件重启后被erased
drwxr-xr-x  11 root   root     4096 Dec 10 01:04 usr ##这里面有bin man sbin等目录，存放user program and other data(并不是user，而是universal system resources)
drwxr-xr-x  14 root   root     4096 Dec 10 22:21 var ## 全称variable，存放variable data where system must be able to write during operation(就是log)

/usr：系统级的目录，可以理解为C:/Windows/，/usr/lib理解为C:/Windows/System32。
/usr/local：用户级的程序目录，可以理解为C:/Progrem Files/。用户自己编译的软件默认会安装到这个目录下。
/opt：用户级的程序目录，可以理解为D:/Software，opt有可选的意思，这里可以用于放置第三方大型软件（或游戏），当你不需要时，直接rm -rf掉即可。在硬盘容量不够时，也可将/opt单独挂载到其他磁盘上使用。

/usr/src：系统级的源码目录。
/usr/local/src：用户级的源码目录。

各个目录
youtube-dl的安装途径就是下一个软件下来，然后chmod给权限，然后
/usr/local/bin/youtube-dl和直接敲youtube-dl是一个命令。好像放在这个目录下面就好了。
关于这些目录的[解释](http://blog.csdn.net/test1280/article/details/70143465)
/bin是系统的一些指令。bin为binary的简写；
/sbin一般是指超级用户指令。就是只有管理员才能执行的命令
/usr/bin：通常是一些非必要的，但是普通用户和超级用户都可能使用到的命令
/usr/local/bin：通常是用户后来安装的软件，可能被普通用户或超级用户使用


/var：某些大文件的溢出 区，比方说各种服务的日志文件。
/usr：最庞大的目录，要用 到的应用程序和文件几乎都在这个目录。
/usr/local: 本地安装的程序和其他东西在/usr/local下
一份比较全面的[Linux 下各文件夹的结构说明及用途介绍](http://blog.jobbole.com/113519/)

### 25. 一个往dropBox上传文件的Script
dropbox的网盘空间不用感觉有点浪费了，一个将本地文件上传到dropBox的脚本[Dropbox-Uploader](https://github.com/andreafabrizi/Dropbox-Uploader)
亲测可用，也不是一个需要启动时跑起来的程序，就是一个给参数就上传的脚本。
```shell
./dropbox_uploader.sh upload /localFileOrDir /dropBoxFileOrDir
```

### 26. fuser显示当前文件正在被哪些进程使用
fuser -m -u redis-server

### 27. 一些看上去比较玄的操作
```shell
bash <(curl -s https://codecov.io/bash) ##重定向还有这么玩的
```

### 28.htop怎么看
process state
图片[出处](https://codeahoy.com/2017/01/20/hhtop-explained-visually/)
![](http://www.haldir66.ga/static/imgs/htop-top.png)
![](http://www.haldir66.ga/static/imgs/htop-bottom.png)
> PROCESS STATE CODES
   R  running or runnable (on run queue)
   D  uninterruptible sleep (usually IO)
   S  interruptible sleep (waiting for an event to complete)
   Z  defunct/zombie, terminated but not reaped by its parent
   T  stopped, either by a job control signal or because
      it is being traced
   [...]

一般都是S比较多，Z属于Zombie进程，直接干掉   



Mere trash
===============================================================================
[LINUX下的21个特殊符号](http://blog.51cto.com/litaotao/1187983)
[Shell学习笔记](https://notes.wanghao.work/2015-06-02-Shell%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.html)
[gdb调试器,debug用的](http://blog.jobbole.com/112547/)
[chsh命令](http://man.linuxde.net/chsh)

文件描述符限制

ls -al = l -al（可以少敲一个字母,其实是alias）

small tricks
```shell
cat > filename.txt
then start typing your text content
ctrl +d to finish

pushd and popd can help you jump to some directory can come back later

gdebi ##  like dpkg command , will install required dependency if needed

cpulimit command  ##limit the cpu usage to certain process

htop中按f4可以filter，按f9可以杀进程。 按下空格键可以选中某个process（用于多选）

bleachbit可以帮助清理垃圾

rsync用于做系统备份
rsync -avz --delete Pictures/ 192.168.0.10:Pictures/  ## a表示archive，就是说保留源文件的permission,timestamp等等， v表示verbose, z表示zip(就像gzip一样，通过网络传输的时候能够节省流量),记得Pictures后面的斜杠不能少

ubuntu上使用sudo xxx ，输入密码后，下次sudo就不会再次要求密码了，但其实系统会起一个倒计时，如果接下来的30分钟（大概这个时间）内没有执行sudo命令，将会再次提示要求输入密码
解决方法sudo -s // 即后续sudo指令不需要秘密

打开tty的方法: ctrl + alt + (f1-f8)

sfpt cindy@192.168.0.2  ##以cindy的身份登录这台机器

## bash的窗口在等待输入的时候一般长这样:
john@server ~ $
john表示当前用户名称
sever表示当前主机名称
~表示当前所在目录
$表示没有特殊权限，就是说不是root previledge的意思


bash和sh的区别
> #!/bin/bash ## 一个井号加上一个感叹号在计算机领域叫做shebang.很多shell脚本的第一行都有：
#!/bin/bash 一定是bash，万一没装bash会报错,还有些系统的bash装载/usr/pkg/bin或者/usr/local/bin里面
或者是
#!/bin/sh 就会使用当前操作系统上的sh,不一定是bash.比如debian上sh是dash的symbolic link
比较可靠的方式是
#!/usr/bin/env bash 用的是$PATH

## file -h /bin/sh 这个命令用于查看文件
/bin/sh: symbolic link to dash

Because sh is a specification, not an implementation, /bin/sh is a symlink (or a hard link) to an actual implementation on most POSIX systems.(sh是POSIX标准规定的一套协议，并非实现.sh的实现有很多种，zsh,dash,bash等等。但在很多系统上，sh是bash的symbolic link).相比起来,bash的功能要比sh强大不少。Plain sh is a very minimalistic programming language.



### 下面这三个要跟ctrl+z一起用
bg ##看之前按ctrl+z退到后台的程序
jobs ##查看当前在跑的程序
fg job name ##把这个程序拉到前台

比方说当前目录下有一个dump.sh文件，想要执行的话，输入dump是没有用的。因为echo $PATH中并没有这个dump:目录/dusp.sh。
所以要执行这个sh，需要./dump.sh

或者建一个symbolic link到 /usr/local/bin下面，比如这样
sudo ln -s /full/path/to/your/file /usr/local/bin/name_of_new_command
想要可执行的话，记得给权限。chmod +x /full/path/to/your/file
当然，想要移除这个软链接的话.
sudo rm -rf /usr/local/bin/name_of_new_command

关于硬链接和软连接
-s 就是软链接。不加-s就是硬链接。
修改硬链接和软链接的内容都会同步到源文件，软链接和硬链接删掉了都不会影响源文件。有一个区别就是删掉源文件时，硬链接保有了源文件的内容。 软链接就broken了。

visudo //via sudo 这是一个控制用户权限的文件，比如说希望给特定用户一部分usdo特权，比如只给安装软件的权利，编辑这个文件就可以
为什么不要总以root权限做事:
sudo rm -rf /etc/dummyfile ## 看上去ok
sudo rm -rf / etc/dummyfile ## 不小心多了个空格，系统并不会拦着你，这样就删掉了所有的文件

raspberry Pi使用的是Raspbian -- 基于debian

查看内存除了free 和htop之外
sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches" ## 就是用sh执行一个command, 即dump memory cache，类似于windows上360那个点击清内存
sudo bash -c "echo 'vm.swappiness =15' >> /etc/sysctl.conf" ## -c表示让bash执行一个命令， swappiness默认值是60，意思是系统在用掉了60%的内存后就将开始启用swap
```

nmap可以用来扫描某台远程主机上open的port[直接看nmap cheetsheet好了](https://hackertarget.com/nmap-cheatsheet-a-quick-reference-guide/)
> nmap -p 1-100 192.168.1.1 ## 扫描1-100的port，非常慢

linux的swap文件需要经常读写，这对于ssd来说是一个需要注意的地方
[digital ocean在添加swap教程的最前面就写了不建议ssd用户添加swap,因为会费ssd](https://www.digitalocean.com/community/tutorials/how-to-add-swap-space-on-ubuntu-16-04)

[bash下的一些快捷键](https://stackoverflow.com/questions/12334526/on-bash-command-line-how-to-delete-all-letters-before-cursor)
```
Ctrl-u - Cut everything before the cursor // 清除光标之前所有文字
Ctrl-k  Cut everything after the cursor //删除光标后面的所有文字

Ctrl-a  Move cursor to beginning of line //光标挪到最前面
Ctrl-e  Move cursor to end of line // 挪到最右侧

Ctrl-b  Move cursor back one word //这个是一个字一个字的挪，不识别空格
Ctrl-f  Move cursor forward one word//这个是一个字一个字的挪，不识别空格

alt + → 一个单词一个单词的往右挪，往左挪自然就是向左箭头了。

Ctrl-w  Cut the last word
Ctrl-y  Paste the last thing to be cut
Ctrl-_  Undo

```

[supervisor](https://www.digitalocean.com/community/tutorials/how-to-install-and-manage-supervisor-on-ubuntu-and-debian-vps)可以用于管理一些程序的运行，挂了负责自动拉起来。很简单的，就是装一个软件，写一个conf。


apt-get的数据库放在 /var/lib/dpkg/info
```
dpkg: warning: files list file for package `x' missing; assuming package has no files currently installed

##出现上面的错误，这两条命令修复
sudo rm -f /var/lib/dpkg/info/format
sudo dpkg --configure -a
```

> windows的换行符是 \r\l，linux的是 \l，mac的是 \r



unix domain socket用于ipc

有时候cd进一个权限不够的目录会出现Permission Denied
>sudo su
cd directory
直接转成root就好了

nano直接跳到文本最后一行的方法是：
> Ctrl + _ 然后Ctrl +V

[装java](https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-get-on-ubuntu-16-04)
[装Jenkins](https://www.digitalocean.com/community/tutorials/how-to-install-jenkins-on-ubuntu-16-04)
<del>Could not find or load main class的问题</del>


🎧 

熟悉了bash之后，再来看zsh，似乎更加轻松
看一下我当前使用的是哪种sh: echo $SHELL
linux上目测没有默认安装zsh。
[安装完zsh一定要装上这个的，on-my-zsh](https://github.com/robbyrussell/oh-my-zsh)
[zsh有一个plugin的概念，这个是自动提示的插件](https://github.com/zsh-users/zsh-autosuggestions)
[zsh的主题个人偏好Dracula](https://draculatheme.com/)
[agnoster是另一款很多人都装上的主题](https://github.com/agnoster/agnoster-zsh-theme)，主题这种东西看个人喜好了。




## 参考
- [每天一个Linux命令](http://www.cnblogs.com/peida/archive/2012/12/05/2803591.html)
- [Linux命令大全](http://man.linuxde.net/xargs)
- [awk是三个人的名字](https://mp.weixin.qq.com/s/L0oViwqjIgudY-SrV0paRA)
- [树莓派搭建局域网媒体服务器，下载机](http://www.cnblogs.com/xiaowuyi/p/4051238.html)
- [Linux中国](https://linux.cn/tech/sa/index.php?page=4)
