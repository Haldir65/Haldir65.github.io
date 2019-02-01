---
title: 如何写shell脚本
date: 2018-11-04 08:50:58
tags: [linux,tools,tbd]

---

总结linux下shell脚本语句的语法
Shell 是一个用 C 语言编写的程序，它是用户使用 Linux 的桥梁。Shell 既是一种命令语言，又是一种程序设计语言。
Shell 是指一种应用程序，这个应用程序提供了一个界面，用户通过这个界面访问操作系统内核的服务。
Ken Thompson 的 sh 是第一种 Unix Shell，Windows Explorer 是一个典型的图形界面 Shell。

![](https://www.haldir66.ga/static/imgs/timg.jpg)

<!--more-->

Linux 的 Shell 种类众多，常见的有：

- Bourne Shell（/usr/bin/sh或/bin/sh）
- Bourne Again Shell（/bin/bash）
- C Shell（/usr/bin/csh）
- K Shell（/usr/bin/ksh）
- Shell for Root（/sbin/sh）
……

## Shebang
脚本以[Shebang](https://en.wikipedia.org/wiki/Shebang_(Unix))开始
```
> #!/bin/sh
#! 是一个约定的标记，它告诉系统这个脚本需要什么解释器来执行，即使用哪一种 Shell。
这样的话chmod +X 之后直接./xxx.sh就可以执行了
```

## set -e 和set -x以及pipe fail
经常会在别人的bash脚本最前面看到一行 [set-e](http://www.ruanyifeng.com/blog/2017/11/bash-set.html)：在阮一峰老师的博客中找到了解释
```
#!/usr/bin/env bash
set -e ## 这个set -e的原因，因为bash一般对错误容忍度比较高，一行命令出了错还能往下走，可是实际生产中，我们希望出了错就此打住。在文件前面写这个就行了

## 总比下面这些这么写好吧
command || exit 1 
command || { echo "command failed"; exit 1; }

set -eo pipefail ##set -e对于管道无效，这么写就连管道的错误都拦下来了
```
$ set -e
这行代码之后的任何代码，如果返回一个非0的值，那么整个脚本立即退出，官方的说明是为了防止错误出现滚雪球的现象
$ set -o pipefail
原文解释如下：
If set, the return value of a pipeline is the value of the last (rightmost) command to exit with a non-zero status,or zero if all commands in the pipeline exit successfully. This option is disabled by default.
可理解为：
告诉 bash 返回从右到左第一个以非0状态退出的管道命令的返回值，如果所有命令都成功执行时才返回0
$ set -x //这句话能够在console中显示当前脚本执行了哪些语句


## shell中引用变量
首先变量是随便定义的，引用的时候前面加一个美元符号就可以了
```bash
## 
MY_VAR=100 ## 这中间不能有空格

##例：myvar=“Hi there！”

echo $myvar  ## Hi there！

echo "$myvar"  ## Hi there!

echo ' $myvar' ## $myvar

echo \$myvar ## $myvar
```
单引号里面的变量是不能输出变量的值的，所以尽量用双引号

## if else这种逻辑判断怎么写
```bash
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
if [ "$var1" == "$var2" ]; then  ##if 后面必须加then
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

## 字符串拼接是很重要的
```bash
#!/bin/bashbash
echo "hello there"
foo="Hello"
foo="$foo World"  ## 拼接一个现成的string到另一个string的尾部，用冒号跟美元符号就好了
echo $foo
echo "Number of files in this directory: `ls | wc -l`"  ## 但是将ls | wc -l的输出作为一个String拼接到一个string中，用单引号
echo "all the files under the directory `ls  /usr/*/g* | head -n3`"
```
想要在bash中设置一个variable为一个命令的输出
```bash
#!/bin/bash
OUTPUT="$(ls -1)"  ## 注意，这里等于号前后不能有空格
echo "${OUTPUT}"

##那如果就是平时在terminal里面随便敲敲呢，下面这些亲测无误
echo "$(ls -al | wc)"
"$(which java)" -h
## 比如说我想把java的路径填充到一段命令中间
echo "$(which java)"/something
>> /usr/bin/java/something

#!/bin/bash
java_stuff="$(which java)"
${java_stuff} --version
```


## 还有for循环
```bash
for file in `ls /etc`
##或
for file in $(ls /etc)
```



### 变量($其实就是美元符号了)
变量调用符号($)
```bash
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

## 亲测下面这种可用
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

```bash
echo $HOSTNAME
## unbutu
$? 最后一次执行的命令的返回状态。如果这个变量的值为0，证明上一个命令正确执行；如果这个变量的值非0（具体是哪个数，由命令自己决定），则证明上一个命令执行不正确了。
$$ 当前进程的进程号（PID）
$! 后台运行的最后一个进程的进程号（PID）

unix下查看环境变量命令：
> export

windows下查看环境变量:
> set
```

## shell里面判断一个命令是否执行成功
其实在terminal中执行命令的话，有一个小细节：注意看最左下方的符号。上一个命令如果成功的话，是绿色的，不成功的话是红色的。
c语言中有一个errornum,shell 里面有差不多的东西，用于判断上一个命令是否返回非0的return value。
```bash
# iptables -C INPUT -p tcp --dport 8080 --jump ACCEPT
iptables: Bad rule (does a matching rule exist in that chain?).
# echo $?
1

# iptables -A INPUT -p tcp --dport 8080 --jump ACCEPT

# iptables -C INPUT -p tcp --dport 8080 --jump ACCEPT
# echo $?
0
```
上面这个例子，未曾设置这个iptables rule ，这个命令返回1 ，否则返回0
shell里面判断if else就可以这么写

```bash
if [ $? -eq 0 ]; then
    echo "no error from last command"
else
    echo "some error from last command"    
fi

if [ $? != 0 ]; then
    echo "there's error from executing last command!"
else
    echo "no error from last command"    
fi
```


## sh xxx.sh出现下面这个错误
```
> [[: not found…………………..
```

[原因是sh不支持这种用法，bash支持。所以改成bash xxx.sh就可以了](https://superuser.com/questions/374406/why-do-i-get-not-found-when-running-a-script)
sh只是一个符号链接，最终指向是一个叫做dash的程序，自Ubuntu 6.10以后，系统的默认shell /bin/sh被改成了dash。dash(the Debian Almquist shell) 是一个比bash小很多但仍兼容POSIX标准的shell，它占用的磁盘空间更少，执行shell脚本比bash更快，依赖的库文件更少，当然，在功能上无法与bash相比。dash来自于NetBSD版本的Almquist Shell(ash)。
Ubuntu中将默认shell改为dash的主要原因是效率。由于Ubuntu启动过程中需要启动大量的shell脚本，为了优化启动速度和资源使用情况，Ubuntu做了这样的改动。


## shell脚本执行的时候不是可以带参数$0, $1什么的嘛
这实质上就是一个数组
```sh
#!/bin/bash
echo "The script you are running has basename `basename "$0"`, dirname `dirname "$0"`"
echo "The present working directory is `pwd`"
echo "参数个数为：$#";  ## 传进来的参数的个数
echo "传递的参数作为一个字符串显示：$*"; ## 就是把所有参数作为一整个字符串打印出来


echo "-- \$@ 传入的参数 ---"
for i in "$@"; do
    echo $i
done
```


在c语言的main函数中,args[0]就是当前文件的路径，所以在shell里也差不多

[在sh脚本中判断当前脚本所在的位置](https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within?rq=1))


## shell中的重定向
大于号是输出重定向，小于号是输入重定向

输入重定向就好玩了
直接把一个curl的脚本导到bash去执行的方式
```bash
- bash <(curl -L -s https://install.direct/go.sh)
$ curl get.pow.cx | sh  ##我也见过这种的
$ wc -l < users ## 假设这个users文件里就两行
 2
```
讲的深入一点
一般情况下，每个 Unix/Linux 命令运行时都会打开三个文件：
标准输入文件(stdin)：stdin的文件描述符为0，Unix程序默认从stdin读取数据。
标准输出文件(stdout)：stdout 的文件描述符为1，Unix程序默认向stdout输出数据。
标准错误文件(stderr)：stderr的文件描述符为2，Unix程序会向stderr流中写入错误信息。
如果希望将 stdout 和 stderr 合并后重定向到 file，可以这样写：
```bash
$ command > file 2>&1 ## 印象中这是把2导到1中
##或者
$ command >> file 2>&1
```

## here document
Here Document 是 Shell 中的一种特殊的重定向方式，用来将输入重定向到一个交互式 Shell 脚本或程序。

它的基本的形式如下：
```bash
command << delimiter
    document
delimiter
```
它的作用是将两个 delimiter 之间的内容(document) 作为输入传递给 command。(说人话就是有段命令特别长，塞到这里头就方便看了)
注意：
结尾的delimiter 一定要顶格写，前面不能有任何字符，后面也不能有任何字符，包括空格和 tab 缩进。
开始的delimiter前后的空格会被忽略掉。

[linux shell 的here document 用法 (cat << EOF) ](https://my.oschina.net/u/1032146/blog/146941)


```bash
:<<EOF
注释内容...
注释内容...
注释内容...
EOF
```

//统计一下这个脚本耗时多久
> time bash -c 'echo "hey"'
> time somescript.sh

shell脚本里面经常会看到mktemp函数，作用就是确保生成一个随机命名的文件


### 直接挑选几个可以用的脚本开始看吧

1. 一个把文件夹（/public/imgs）下所有文件重命名为img-x.jpg的shell脚本

```bash
#!/bin/bash
FORMAT_JPG="jpg"
FORMAT_JPEG="jpeg"
index=1
dir=$(eval pwd)/public/imgs
ALLIMGES=$(ls $dir | grep  ".$FORMAT_JPEG\|.$FORMAT_JPG")
for file in $ALLIMGES
        do
        name=img-${index}.jpg
        echo renaming $dir/$file to  $dir/$name
        mv $dir/$file $dir/$name
        ((index++))
        # name=$(ls $file | cut -d. -f1)
        # mv $dir/public/imgs/$file ${name}.$suffix
        done
echo "renaming $index image files =====> x.jpg done!"
```

同时grep多种文件的时候，比如又想要jpg又想要jpeg的话，grep 要加上反斜杠，或者下面这三种
```bash
grep "aaa\|bbb"
grep -E "aaa|bbb"
grep -E aaa\|bbb
```
[how to grep](https://www.cyberciti.biz/faq/howto-use-grep-command-in-linux-unix/)


2. [一个直接把gfwlist的bs64文本转换成dnsmasq配置文件的脚本](https://github.com/cokebar/gfwlist2dnsmasq/blob/master/gfwlist2dnsmasq.sh) 注意，base64在linux上是预装的
这个脚本分开几段来看:
### 首先是检查当前系统中依赖的软件是否都装了

```bash
check_depends(){
    which sed base64 mktemp >/dev/null
    if [ $? != 0 ]; then ## 美元加问号就是上一个命令的返回值
        _red 'Error: Missing Dependency.\nPlease check whether you have the following binaries on you system:\nwhich, sed, base64, mktemp.\n'
        exit 3
    fi
    which curl >/dev/null
    if [ $? != 0 ]; then
        which wget >/dev/null
        if [ $? != 0 ]; then
            _red 'Error: Missing Dependency.\nEither curl or wget required.\n'
            exit 3
        fi
        USE_WGET=1 ## 随便定义一个变量
    else
        USE_WGET=0
    fi

    SYS_KERNEL=`uname -s`
    if [ $SYS_KERNEL = "Darwin"  -o $SYS_KERNEL = "FreeBSD" ]; then ## if 语句里面or是这么写的
        BASE64_DECODE='base64 -D'
        SED_ERES='sed -E'
    else
        BASE64_DECODE='base64 -d'
        SED_ERES='sed -r'
    fi
}
```

### 接下来是从获取传进来的参数
```bash
get_args(){
    OUT_TYPE='DNSMASQ_RULES'
    DNS_IP='127.0.0.1'
    DNS_PORT='5353'
    IPSET_NAME=''
    FILE_FULLPATH=''
    CURL_EXTARG=''
    WGET_EXTARG=''
    WITH_IPSET=0
    EXTRA_DOMAIN_FILE=''
    EXCLUDE_DOMAIN_FILE=''
    IPV4_PATTERN='^((2[0-4][0-9]|25[0-5]|[01]?[0-9][0-9]?)\.){3}(2[0-4][0-9]|25[0-5]|[01]?[0-9][0-9]?)$'
    IPV6_PATTERN='^((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}))|:)))(%.+)?$'

    while [ ${#} -gt 0 ]; do
        case "${1}" in
            --help | -h)
                usage 0
                ;;
            --domain-list | -l)
                OUT_TYPE='DOMAIN_LIST'
                ;;
            --insecure | -i)
                CURL_EXTARG='--insecure'
                WGET_EXTARG='--no-check-certificate'
                ;;
            --dns | -d)
                DNS_IP="$2"
                shift
                ;;
            --port | -p)
                DNS_PORT="$2"
                shift
                ;;
            --ipset | -s)
                IPSET_NAME="$2"
                shift
                ;;
            --output | -o)
                OUT_FILE="$2"
                shift
                ;;
            --extra-domain-file)
                EXTRA_DOMAIN_FILE="$2"
                shift
                ;;
           --exclude-domain-file)
                EXCLUDE_DOMAIN_FILE="$2"
                shift
                ;;
            *)
                _red "Invalid argument: $1"
                usage 1
                ;;
        esac
        shift 1
    done

    # Check path & file name
    if [ -z $OUT_FILE ]; then
        _red 'Error: Please specify the path to the output file(using -o/--output argument).\n'
        exit 1
    else
        if [ -z ${OUT_FILE##*/} ]; then
            _red 'Error: '$OUT_FILE' is a path, not a file.\n'
            exit 1
        else
            if [ ${OUT_FILE}a != ${OUT_FILE%/*}a ] && [ ! -d ${OUT_FILE%/*} ]; then
                _red 'Error: Folder do not exist: '${OUT_FILE%/*}'\n'
                exit 1
            fi
        fi
    fi

    if [ $OUT_TYPE = 'DNSMASQ_RULES' ]; then
        # Check DNS IP
        IPV4_TEST=$(echo $DNS_IP | grep -E $IPV4_PATTERN)
        IPV6_TEST=$(echo $DNS_IP | grep -E $IPV6_PATTERN)
        if [ "$IPV4_TEST" != "$DNS_IP" -a "$IPV6_TEST" != "$DNS_IP" ]; then
            _red 'Error: Please enter a valid DNS server IP address.\n'
            exit 1
        fi

        # Check DNS port
        if [ $DNS_PORT -lt 1 -o $DNS_PORT -gt 65535 ]; then
            _red 'Error: Please enter a valid DNS server port.\n'
            exit 1
        fi

        # Check ipset name
        if [ -z $IPSET_NAME ]; then
            WITH_IPSET=0
        else
            IPSET_TEST=$(echo $IPSET_NAME | grep -E '^\w+$')
            if [ "$IPSET_TEST" != "$IPSET_NAME" ]; then
                _red 'Error: Please enter a valid IP set name.\n'
                exit 1
            else
                WITH_IPSET=1
            fi
        fi
    fi

    if [ ! -z $EXTRA_DOMAIN_FILE ] && [ ! -f $EXTRA_DOMAIN_FILE ]; then
        _yellow 'WARNING:\nExtra domain file does not exist, ignored.\n\n'
        EXTRA_DOMAIN_FILE=''
    fi

    if [ ! -z $EXCLUDE_DOMAIN_FILE ] && [ ! -f $EXCLUDE_DOMAIN_FILE ]; then
        _yellow 'WARNING:\nExclude domain file does not exist, ignored.\n\n'
        EXCLUDE_DOMAIN_FILE=''
    fi
}
```
懒得解释了，就是一个switch case和各种if else

![](https://www.haldir66.ga/static/imgs/PuffinWales_EN-AU12757555133_1920x1080.jpg)


[opt-script](https://github.com/hiboyhiboy/opt-script)
[shell script tutorial](https://www.youtube.com/watch?v=hwrnmQumtPw)
[LINUX下的21个特殊符号](http://blog.51cto.com/litaotao/1187983)
[Shell学习笔记](https://notes.wanghao.work/2015-06-02-Shell%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.html)
[how to use variables in shell scripts](https://www.youtube.com/watch?v=Lu-xzWajbFo)
