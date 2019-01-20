---
title: 如何写shell脚本
date: 2018-11-04 08:50:58
tags: [linux,tools,tbd]

---

linux下shell脚本语句的语法
，脚本以[Shebang](https://en.wikipedia.org/wiki/Shebang_(Unix))开始
> #!/bin/sh


![](https://www.haldir66.ga/static/imgs/timg.jpg)
<!--more-->


### linux下shell脚本语句的语法
linux大小写敏感


eg: echo类似于print
```bash
##例：myvar=“Hi there！”

    echo $myvar  ## Hi there！

    echo "$myvar"  ## Hi there!

    echo ' $myvar' ## $myvar

    echo \$myvar ## $myvar
```

eg:
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


```bash
#!/bin/bashbash
echo "hello there"
foo="Hello"
foo="$foo World"  ## 拼接一个现成的string到另一个string的尾部，用冒号跟美元符号就好了
echo $foo
echo "Number of files in this directory: `ls | wc -l`"  ## 但是将ls | wc -l的输出作为一个String拼接到一个string中，用单引号
echo "all the files under the directory `ls  /usr/*/g* | head -n3`"

```

一个把文件夹（/public/imgs）下所有文件重命名为img-x.jpg的shell脚本
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
```
grep "aaa\|bbb"
grep -E "aaa|bbb"
grep -E aaa\|bbb
```
[how to grep](https://www.cyberciti.biz/faq/howto-use-grep-command-in-linux-unix/)

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
```

unix下查看环境变量命令：
> export

windows下查看环境变量:
> set



直接把一个curl的脚本导到bash去执行的方式
- bash <(curl -L -s https://install.direct/go.sh)


[在sh脚本中判断当前脚本所在的位置](https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within?rq=1))
```sh
#!/bin/bash
echo "The script you are running has basename `basename "$0"`, dirname `dirname "$0"`"
echo "The present working directory is `pwd`"
```
在c语言的main函数中,args[0]就是当前文件的路径，所以在shell里也差不多


//统计一下这个脚本耗时多久
> time bash -c 'echo "hey"'
> time somescript.sh


[LINUX下的21个特殊符号](http://blog.51cto.com/litaotao/1187983)
[Shell学习笔记](https://notes.wanghao.work/2015-06-02-Shell%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.html)
[how to use variables in shell scripts](https://www.youtube.com/watch?v=Lu-xzWajbFo)

## [shell script tutorial](https://www.youtube.com/watch?v=hwrnmQumtPw)