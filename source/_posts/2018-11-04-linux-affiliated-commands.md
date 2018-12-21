---
title: linux常用命令(三)
date: 2018-11-04 08:44:22
categories: blog
tags: [linux,tools]
---

![](https://www.haldir66.ga/static/imgs/green_forset_alongside_river_2.jpg)

<!--more-->

### linux sed命令
[basic sed](https://www.digitalocean.com/community/tutorials/the-basics-of-using-the-sed-stream-editor-to-manipulate-text-in-linux)
>  sed operates on a stream of text that it reads from either standard input or from a file.

基本命令格式
sed [options] commands [file-to-edit]

## 默认情况下,sed会把结果输出到standoutput里面
sed '' BSD ##等同于cat
cat BSD | sed '' ##操作cat的输出流
sed 'p' BSD ##p是命令，明确告诉它要去print，这会导致每一行都被打印两遍
sed -n 'p' BSD ##我不希望你自动打印，每行只被打印一遍
sed -n '1p' BSD ##只打印第一行
sed -n '1,5p' BSD ##打印前5行
sed -n '1,+4p' BSD ##这个也是打印前五行
sed -n '1~2p' BSD ##every other line，打印一行跳过一行，从第一行开始算
sed '1~2d' BSD ##也是隔一行进行操作，只不过这里的d表示删除，结果就是1，3，5...行被从cat的结果中删掉

默认情况下,sed不会修改源文件，加上-i就能改了
sed -i '1~2d' everyother.txt ##第1，3，5，...行被删掉
sed -i.bak '1~2d' everyother.txt ##在编辑文件之前保存一份.bak文件作为备份

sed最为常用的命令就是substituting text了
echo "http://www.example.com/index.html" | sed 's_com/index_org/home_'
http://www.example.org/home.html

命令是这么用的,首先s表示substitute
's/old_word/new_word/'

准备好这么一份text文件
echo "this is the song that never ends
yes, it goes on and on, my friend
some people started singing it
not knowing what it was
and they'll continue singing it forever
just because..." > annoying.txt

sed 's/on/forward/' annoying.txt ##把所有的on换成forward，同时打印出结果。但如果当前行已经替换过一次了，就跳到下一行。所以可能没有替换干净

sed 's/on/forward/g' annoying.txt ## 加上g就好了
sed 's/on/forward/2' annoying.txt ##每一行只替换第二个匹配上的
sed -n 's/on/forward/2p' annoying.text ## n是supress自动print，只打印出哪些被换了的
sed 's/SINGING/saying/i' annoying.txt ##希望大小写不敏感
sed 's/^.*at/REPLACED/' annoying.txt ##从每一行的开头到"at"
sed 's/^.*at/(&)/' annoying.txt ## 把那些会匹配上的文字用括号包起来

[intermediate training](https://www.digitalocean.com/community/tutorials/intermediate-sed-manipulating-streams-of-text-in-a-linux-environment)

linux下查看一个文件的时间戳
> stat test

c语言下对应的函数在sys/stat.h头文件中
```c
#include <stdio.h>
#include <sys/stat.h>

int main(void){
    struct stat filestat;
    stat("/etc/sysctl.conf", &filestat);
    printf("size: %ld bytes, uid: %d, gid: %d, mode: %#o\n", filestat.st_size, filestat.st_uid, filestat.st_gid, filestat.st_mode);
    return 0;
}
```


> windows的换行符是 \r\l，linux的是 \l，mac的是 \r
从根本上讲，二进制文件和文本文件在磁盘中没有区别，都是以二进制的形式存储
二进制和文本模式的区别在于对换行符和一些非可见字符的转化上，如非必要，是使用二进制读取会比较安全一些

因为 Windows 和 Linux 中的换行符不一致，前者使用CRLF(即\r\n)表示换行，后者则使用LF(即\n)表示换行
而C语言本身使用LF(即\n)表示换行，所以在文本模式下，需要转换格式(如Windows)，但是在 Linux 下，文本模式和二进制模式就没有什么区别

另外，以文本方式打开时，遇到结束符CTRLZ(0x1A)就认为文件已经结束
所以，若使用文本方式打开二进制文件，就很容易出现文件读不完整，或內容不对的错误
即使是用文本方式打开文本文件，也要谨慎使用，比如复制文件，就不应该使用文本方式


### signal处理
[HakTip - Linux Terminal 101: Controlling Processes](https://www.youtube.com/watch?v=XUhGdORXL54)

linux上信号有32种，多数在C语言中都有默认的处理方式（并且这种默认的处置方式也是可以更改的），除了SIGKILL(强行terminate)和SIGSTOP(debug遇到断点)不允许开发者更改处理方式。(kill -9也就是强杀非常有效)
c程序可以通过signal(比较老了)函数或者sigaction(推荐)函数注册收到信号之后的动作

[Linux by default use the RAM as disk cache](https://unix.stackexchange.com/questions/6593/force-directory-to-always-be-in-cache)
这里的回答解释了系统会默认在内存中缓存磁盘节点的信息，下一次进行find的操作时候，就会快很多。








