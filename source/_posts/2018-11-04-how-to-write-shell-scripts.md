---
title: 如何写shell脚本
date: 2018-11-04 08:50:58
tags: [linux,tools]

---

![](https://www.haldir66.ga/static/imgs/timg.jpg)
<!--more-->

### linux下shell脚本语句的语法
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
##例：myvar=“Hi there！”

    echo $myvar  ## Hi there！

    echo "$myvar"  ## Hi there!

    echo ' $myvar' ## $myvar

    echo \$myvar ## $myvar
```

```shell
#!/bin/bashbash
echo "hello there"
foo="Hello"
foo="$foo World"  ## 拼接一个现成的string到另一个string的尾部，用冒号跟美元符号就好了
echo $foo
echo "Number of files in this directory: `ls | wc -l`"  ## 但是将ls | wc -l的输出作为一个String拼接到一个string中，用单引号
echo "all the files under the directory `ls  /usr/*/g* | head -n3`"

```

一个把文件夹（/public/imgs）下所有文件重命名为img-x.jpg的shell脚本
```shell
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
```shell
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

