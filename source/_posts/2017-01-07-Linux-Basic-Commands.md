---
title: linux基本命令介绍
date: 2017-01-07 15:38:43
categories: blog
tags: [置顶]
top : 1
---

一些常用的linux基本命令,仅作为参考。</br>
![](http://odzl05jxx.bkt.clouddn.com/rationalizingyourhoriiblehack-big.png?imageView2/2/w/500)
 <!--more-->

首先是连接vps的ssh(Secure Shell)工具，putty或者xshell都可以。


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
重命名

-> mv a.mp4 b.mp4 //mv虽然是移动（Windows中的剪切）操作，但这种情况下就等同于重命名了，亲测有效
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


文件传输（linux ->windows）： 一般使用putty ssh到Linux主机，想要把Linux上的文件弄到Windows中，需要使用pscp工具。下载好pscp.exe后，放到c:/windows/system32下面。打开cmd。输入命令
pscp -r root@202.123.123.123:"/root/fileonServer.mp4" d:/whateveriwantonmyPc.mp4  ，确认后输入root密码就好了。我主要是用来下载视频的。
有时候会出现Connection Refused Error。
netstat -anp | grep sshd
看下跑在哪个端口
然后
pscp -P 12345-r root@202.123.123.123:"/root/fileonServer.mp4" d:/whateveriwantonmyPc.mp4 # -p要大写

查看硬盘存储空间:
df -h //h的意思是human-readable
du -sh //查看当前directory的大小
du -h //查看当前目录下各个子目录分别的大小
dh -h img// 查看img目录下文件及文件夹的大小
dh -h img/1.jpg //查看指定文件的大小


压缩文件命令
将/home/video/ 这个目录下所有文件和文件夹打包为当前目录下的video.zip

zip –q –r video.zip /home/video/video.zip

```



### 2. Vi文本编辑器
```shell
- > vi 3.txt // 如果有则编辑，没有则直接创建

Vi分为命令模式和编辑模式，一进来是命令模式，输入'a'进入编辑模式
切换回命令模式按'esc' 
命令模式下 :w 表示存盘
- :q 退出
- :!q 不保存退出
- :wq 保存并退出
```


在编辑模式下,输入 'dd'删除一行 ，输入'dw'删除一个词
输入'o'插入一行。。。。。。
```shell
- > more filename//查看文件内容

- > cat filename //正序查看文件内容

- > tac filename //逆序查看文件内容

- > head - 3 filename //只查看文件前面三行
- > tail - 3 filename //只查看倒数后三行 

ss 命令 
ssserver -c /etc/shadowsocks/config.json # 前台运行

#后台运行和停止
ssserver -c /etc/shadowsocks.json -d start
ssserver -c /etc/shadowsocks.json -d stop

#加入开机启动
在/etc/rc.local中加入
sudo ssserver -c /etc/shadowsocks.json --user username -d start #不要总是用root用户做事，adduser来做，给sudo权限即可

[ShadowsocksR](https://github.com/breakwa11/shadowsocks-rss/wiki)启动后台运行命令
> python server.py -p 443 -k password -m aes-256-cfb -O auth_sha1_v4 -o http_simple -d start

[net-speeder](https://zhgcao.github.io/2016/05/26/ubuntu-install-net-speeder/)
venetX，OpenVZ架构
```
cd net-speeder-master/
sh build.sh -DCOOKED

Xen，KVM，物理机
cd net-speeder-master/
sh build.sh
```

加速所有ip协议数据
./net_speeder venet0 "ip"

只加速指定端口，例如只加速TCP协议的 8989端口
#前提是切换到net-speeder的目录下
# ./net_speeder venet0:0 "tcp src port 8989"


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

第一组代表所有者权限，第二组代表与所有者一个用户组的用户的权限，第三组代表其他用户的权限

更改文件权限命令: chmod
```shell
chmod +x filename //加上可执行权限，所有用户都加上了
chmod u+x filename //给当前用户加上可执行权限
//其他命令不一一列举

chmod 755 filename  
chmod 777 filename //全部权限都有了，其实上面的9位就是这三位数每一位的二进制拼起来的
755 就是 111101101,也就对应上面的权限九位字母


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


### 7. 磁盘分区的问题

### 8. 配置sql,Tomcat


## ref 
鸟哥

![](http://odzl05jxx.bkt.clouddn.com/fork_you_git.jpg)
[文件大小查看命令](https://my.oschina.net/liting/blog/392051)
[文件压缩命令](http://blog.sina.com.cn/s/blog_7479f7990100zwkp.html)
[硬件查询](https://my.oschina.net/hunterli/blog/140783)