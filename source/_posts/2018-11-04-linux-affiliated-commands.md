---
title: linux常用命令(三)
date: 2018-11-04 08:44:22
categories: blog
tags: [linux,tools]
---

![](https://api1.reindeer36.shop/static/imgs/green_forset_alongside_river_2.jpg)

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

sed -i '' "/target text/d" annoying.txt // 所有包含target text的这一行文字都会被删掉

[intermediate training](https://www.digitalocean.com/community/tutorials/intermediate-sed-manipulating-streams-of-text-in-a-linux-environment)

[colshell的教程](https://coolshell.cn/articles/9104.html)

linux下查看一个文件的时间戳
> stat test

c语言下对应的函数在sys/stat.h头文件中
```C++
#include <stdio.h>
#include <sys/stat.h>

int main(int argc, char const *argv[])
{
    struct stat filestat;
    stat("/etc/sysctl.conf", &filestat);
    printf("size: %ld bytes, uid: %d, gid: %d, mode: %#o\n", filestat.st_size, filestat.st_uid, filestat.st_gid, filestat.st_mode);
    return 0;
}
```


> windows的换行符是 \r\l，linux的是 \l，mac的是 \r
从根本上讲，二进制文件和文本文件在磁盘中没有区别，都是以二进制的形式存储
二进制和文本模式的区别在于对换行符和一些非可见字符的转化上，如非必要，是使用二进制读取会比较安全一些

[换行和回车在不同平台上的解释](https://www.jianshu.com/p/8d33019d1c69)
> Dos 和 windows 采用“回车+换行，CR/LF”表示下一行；
UNIX/Linux 采用“换行符，LF”表示下一行；
苹果机(MAC OS 系统)则采用“回车符，CR”表示下一行。   
CR 用符号'\r'表示, 十进制ASCII代码是 13, 十六进制代码为 0x0D;
LF 使用'\n'符号表示，ASCII代码是 10, 十六制为 0x0A。
所以 Windows 平台上换行在文本文件中是使用 0d 0a 两个字节表示，而 UNIX 和苹果平台上换行则是使用 0a 或 0d 一个字节表示。
一般操作系统上的运行库会自动决定文本文件的换行格式，如一个程序在 windows 上运行就生成 CR/LF 换行格式的文本文件，而在 Linux 上运行就生成 LF 格式换行的文本文件。
在不同平台间使用 FTP 软件传送文件时，在 ASCII 文本模式传输模式下， 一些 FTP 客户端程序会自动对换行格式进行转换，经过这种传输的文件字节数可能会发生变化，如果你不想 FTP 修改原文件，可以使用 bin 模式（二进制模式）传输文本。
在计算机还没有出现之前，有一种叫做电传打字机（Teletype Model 33，Linux/Unix下的tty概念也来自于此）的玩意，每秒钟可以打 10 个字符。但是它有一个问题，就是打完一行换行的时候，要用去0.2秒，正好可以打两个字符。要是在这 0.2 秒里面，又有新的字符传过来，那么这个字符将丢失。
于是，研制人员想了个办法解决这个问题，就是在每行后面加两个表示结束的字符。一个叫做“回车”，告诉打字机把打印头定位在左边界；另一个叫做“换行”，告诉打字机把纸向下移一行。这就是“换行”和“回车”的来历，从它们的英语名字上也可以看出一二。
后来，计算机发明了，这两个概念也就被搬到了计算机上。那时，存储器很贵，一些科学家认为在每行结尾加两个字符太浪费了，加一个就可以。于是，就出现了分歧。
Unix系统里，每行结尾只有“<换行>”，即"\n"；
Mac系统里，每行结尾是“<回车>”，即"\r"；
Windows系统里面，每行结尾是“<换行><回车 >”，即“\n\r”。
一个直接后果是，Unix/Mac系统下的文件在 Windows里打开的话，所有文字会变成一行；而Windows里的文件在Unix/Mac下打开的话，在每行的结尾可能会多出一个^M符号。

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


linux上使用 Ctrl-R 而不是上下键搜索历史

[shell里面的重定向](https://robots.thoughtbot.com/input-output-redirection-in-the-shell)

## Standard output到底是个什么玩意
> Every Unix-based operating system has a concept of “a default place for output to go”. Since that phrase is a mouthful, everyone calls it “standard output”, or “stdout”, pronounced standard out. Your shell (probably bash or zsh) is constantly watching that default output place. When your shell sees new output there, it prints it out on the screen so that you, the human, can see it. Otherwise echo hello would send “hello” to that default place and it would stay there forever.

>Standard input (“stdin”, pronounced standard in) is the default place where commands listen for information. For example, if you type cat with no arguments, it listens for input on stdin, outputting what you type to stdout, until you send it an EOF character (CTRL+d):

>Standard error
Standard error (“stderr”) is like standard output and standard input, but it’s the place where error messages go. To see some stderr output, try catting a file that doesn’t exist:

$ cat does-not-exist | sed 's/No such/ROBOT SMASH/'
cat: does-not-exist: No such file or directory
Whoa - nothing changed! Remember, pipes take the stdout of the command to the left of the pipe. cat‘s error output went to stderr, not stdout, so nothing came through the pipe to sed. It’s good that stderr doesn’t go through the pipe by default: when we pipe output through something that doesn’t output stdout to the terminal, we still want to see errors immediately. For example, imagine a command that reads stdin and sends it to the printer: you wouldn’t want to have to walk over to the printer to see its errors.
We need to redirect cat’s stderr to stdout so that it goes through the pipe. And that means we need to learn about redirecting output.

## unix下redirect file descriptor
Redirecting output
A file descriptor, or FD, is a positive integer that refers to an input/output source. For example, stdin is 0, stdout is 1, and stderr is 2. Those might seem like arbitrary numbers, because they are: the POSIX standard defines them as such, and many operating systems (like OS X and Linux) implement at least this part of the POSIX standard.

 echo "hello there" >&2 // 这句话本来是应该显示在stdoutput中的，但是这里重定向到stderr了,可以把stderr这种看做特殊的file descriptor了。重定向的时候箭头后面要跟一个&号。
 
 下面这个例子，因为pipe默认是只监视stdout的, 送往stderr的东西是没有影响的
 # Redirect to stdout, so it comes through the pipe
$ echo "no changes" >&1 | sed "s/no/some/"
some changes
# Redirect to stderr, so it does not come through
$ echo "no changes" >&2 | sed "s/no/some/"
no changes

但是，对于zsh用户，由于zsh默认打开了MULTIOS option。 This is due to ZSH’s MULTIOS option, which is on by default. The MULTIOS option means that echo something >&1 | other_command will output to FD 1 and pipe the output to other_command, rather than only piping it. To turn this off, run unsetopt MULTIOS.
```
# ZSH with MULTIOS option on
$ echo "hello there" >&1 | sed "s/hello/hi/"
hi there //要是Bash的话，这一行就不会出现，第一个命令的输出直接被Pipe到下一个命令的输入了，都不会显示
hi there
$ echo "hello there" >&2 | sed "s/hello/hi/"
hello there
hi there
```

Let’s say you have stderr output mingled with stdout output – perhaps you’re running the same command over many files, and the command may output to stdout or stderr each time. For convenience, the command outputs “stdout” to stdout, and “stderr” to stderr, plus the file name. The visual output looks like this:
>$ ./command file1 file2 file3
stdout file1
stderr file2
stdout file3
We want to transform every line to have “Robot says: ” before it, but just piping the command to sed won’t work, because (again) pipes only grab stdout:
>$ ./command file1 file2 file3 | sed "s/^/Robot says: /"
stderr file2
Robot says: stdout file1
Robot says: stdout file3
This is a common use case for file descriptors: redirect stderr to stdout to combine stderr and stdout, so you can pipe everything as stdout to another process.
Let’s try it:
>$ ./command file1 file2 file3 2>&1 | sed "s/std/Robot says: std/"
Robot says: stderr file2
Robot says: stdout file1
Robot says: stdout file3

It worked! We successfully redirected stderr (FD 2) into stdout (FD 1), combining them and sending the combined output through stdout.这下知道nohup xxx > /dev/null 2>&1 & 是什么意思了吧(>dev/null是无底洞的意思， 2>&1 是吧file descriptor 2也就是stderr重定向到file descriptor 1也就是stdout , & 是后台运行的意思
)

```
# Correct
> log-file 2>&1
# Wrong
2>&1 > log-file
```
The correct version points stdout at the log file, then redirects stderr to stdout, so both stderr and stdout point at the log file. The wrong version points stderr at stdout (which outputs to the shell), then redirects stdout to the file. Thus only stdout is pointing at the file, because stderr is pointing to the “old” stdout.

Another common use for redirecting output is redirecting only stderr. To redirect a file descriptor, we use N>, where N is a file descriptor. If there’s no file descriptor, then stdout is used, like in echo hello > new-file.
We can use this new syntax to silence stderr by redirecting it to /dev/null, which happily swallows whatever it receives and does nothing with it. It’s the black hole of input/output. Let’s try it:
# Redirect stdout, because it's plain `>`
$ ./command file1 file2 file3 > log-file
stderr file2
# Redirect stderr, because it's `2>`
$ ./command file1 file2 file3 2> log-file
stdout file1
stdout file3

比方说这个命令
/tmp/test.sh > /tmp/test.log 2>&1
执行sh脚本，输出到log文件中，把错误信息也写进文件
所以经常看到的
nohup /mnt/Nand3/H2000G >/dev/null 2>&1 &
就是把输出丢进垃圾桶，跟着把错误也丢进垃圾桶，后面那个是后台运行的意思


使用 dmesg 来查看一些硬件或驱动程序的信息或问题。感觉像是查看系统启动日志

文件夹/sys/devices/system/cpu就是对cpu的文件映射。进入以后，随便进一个cpu核，可以看到cache文件夹，tree以后：
```
.
├── index0
│   ├── coherency_line_size
│   ├── level
│   ├── number_of_sets
│   ├── physical_line_partition
│   ├── shared_cpu_list
│   ├── shared_cpu_map
│   ├── size
│   ├── type
│   └── ways_of_associativity
├── index1
│   ├── coherency_line_size 
│   ├── level
│   ├── number_of_sets
│   ├── physical_line_partition
│   ├── shared_cpu_list
│   ├── shared_cpu_map
│   ├── size
│   ├── type
│   └── ways_of_associativity
├── index2
│   ├── coherency_line_size
...同上一个文件夹
│   └── ways_of_associativity
└── index3
    ├── coherency_line_size
...同上一个文件夹
    └── ways_of_associativity
```




