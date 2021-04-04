---
title: automake教程
date: 2019-08-25 08:46:19
tags: [tools]
---

autotools的使用方式
![](https://api1.foster57.tk/static/imgs/SeaCliffBridge_ZH-CN5362667487_1920x1080.jpg)
<!--more-->

## 1.什么是AutoTools
The GNU build system, also known as the Autotools, is a suite of programming tools designed to assist in making source code packages portable to many Unix-like systems.——Wikipedia

从使用上来讲，多数unix软件的安装方式都是下载一个tarball,configure，make,make install，就这么简单。背后使用的就是autotools。 主要就是为了生成Makefile。

## 从最简单的helloworld开始说起吧
[参考](https://blog.csdn.net/thalo1204/article/details/49183911) 最终可以生成一个tar.gz。
（需要手写的就只有Makefile.am文件，configure.ac文件是从configure.scan文件重命名外加修改一点点过来的）

创建三份文件:
> cat main.c

```c
#include <stdio.h>

int
main(int argc, char* argv[])
{
    printf("Hello world\n");
    return 0;
}
```

> cat Makefile.am

```
AUTOMAKE_OPTIONS = foreign
bin_PROGRAMS = helloworld
helloworld_SOURCES = main.c
```

> cat configure.ac

```
AC_INIT([helloworld], [0.1], [myemail@example.com])
AM_INIT_AUTOMAKE
AC_PROG_CC
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
```

依次执行下面的命令：
aclocal # Set up an m4 environment
autoconf # Generate configure from configure.ac
automake --add-missing # Generate Makefile.in from Makefile.am
./configure # Generate Makefile from Makefile.in
make dist # 会生成一个.tar.gz文件
make distcheck # Use Makefile to build and test a tarball to distribute

想要使用生成的可执行文件的话, sudo make install(会复制可执行文件到 /usr/bin/local文件夹中) ，放心 make uninstall  也有，就是把这个可执行文件给删除掉


## 其他
GNU Autotools 一般指的是3个 GNU 工具包：Autoconf，Automake 和 Libtool 
它们能解决什么问题，要先从 GNU 开源软件的 Build 系统说起。一般来说。GNU 软件的安装过程都是：

解压源代码包
./configure
make
make install（可能要切root用户）
这个过程中， 需要有一个 configure 脚本，同时也需要一个 Makefile 文件。

而 Autoconf 和 Automake 就是一套自动生成 configure 脚本和 Makefile 文件的工具。

在ubuntu上安装autoconf,automake,libtool:
> sudo apt install build-essential autoconf automake libtool libtool-bin autotools-dev

configure文件是用autoconf根据configure.ac创建出来的，而configure.ac能用autoscan自动创建出来

随便创建一个文件夹

$ ls
epoch.c Makefile

$ cat epoch.c
```c
#include <stdio.h>
#include <sys/time.h>
#include <time.h>
#include "config.h"

double get_epoch()
{
  double sec;
  #ifdef HAVE_GETTIMEOFDAY
     struct timeval tv;
     gettimeofday(&tv, NULL);
     sec = tv.tv_sec;
     sec += tv.tv_usec / 1000000.0;
  #else
     sec = time(NULL);
  #endif
  return sec;
}

int main(int argc, char* argv[])
{
   printf("%f\n", get_epoch());
   return 0;
}
```
这么写的原因是gettimeofday()这个函数不是在所有的平台上都有，这种时候就要用time()函数了。

$ cat Makefile
```
# Makefile: A standard Makefile for epoch.c
all: epoch

clean:
    rm ­f epoch
```
这样其实已经可以直接make生成可执行文件了。但是我们用autoconf来生成试一下

1. 生成config.h文件
config.h文件是configure命令根据config.h.in文件生成的，config.h.in文件是由autoheader（C的source code）中生成的（总之也是自动的）
$ ls 
epoch.c Makefile
$ autoscan
$ ls
autoscan.log  configure.scan  epoch.c  Makefile
$  mv configure.scan configure.ac
$ ls
autoscan.log  configure.ac  epoch.c  Makefile
$ autoheader
$ ls
autom4te.cache  autoscan.log  config.h.in  configure.ac  epoch.c  Makefile
$  mv Makefile Makefile.in
$ autoconf
$ ls
autom4te.cache  autoscan.log  config.h.in  configure  configure.ac  epoch.c  Makefile.in
$ ./configure
checking for gcc... gcc
checking whether the C compiler works... yes
checking for C compiler default output file name... a.out
checking for suffix of executables...
checking whether we are cross compiling... no
checking for suffix of object files... o
checking whether we are using the GNU C compiler... yes
checking whether gcc accepts -g... yes
checking for gcc option to accept ISO C89... none needed
checking how to run the C preprocessor... gcc -E
checking for grep that handles long lines and -e... /bin/grep
checking for egrep... /bin/grep -E
checking for ANSI C header files... yes
checking for sys/types.h... yes
checking for sys/stat.h... yes
checking for stdlib.h... yes
checking for string.h... yes
checking for memory.h... yes
checking for strings.h... yes
checking for inttypes.h... yes
checking for stdint.h... yes
checking for unistd.h... yes
checking sys/time.h usability... yes
checking sys/time.h presence... yes
checking for sys/time.h... yes
checking for gettimeofday... yes
configure: creating ./config.status
config.status: creating Makefile
config.status: creating config.h
$  ls
autom4te.cache  autoscan.log  config.h  config.h.in  config.log  config.status  configure  configure.ac  epoch.c  Makefile  Makefile.in
$ make
$ ls
autom4te.cache  config.h     config.log     configure     epoch    Makefile
autoscan.log    config.h.in  config.status  configure.ac  epoch.c  Makefile.in
$  ./epoch
1544345416.704451

//到此结束（这样做的意义在于一份代码就能够拥有多平台兼容性）


另一种方式
手动创造“Makefile.am”文件
$ cat Makefile.am
# Makefile.am for epoch.c
bin_PROGRAMS=epoch
epoch_SOURCES=epoch.c

$ ls 
epoch.c  Makefile.am

$ autoscan
$  mv configure.scan configure.ac
$ autoheader
$ ls 
autom4te.cache  autoscan.log  config.h.in  configure.ac  epoch.c  Makefile.am
$ vim configure.ac
改成这样
```
#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.69])
AC_INIT([FULL-PACKAGE-NAME], [VERSION], [BUG-REPORT-ADDRESS])
AM_INIT_AUTOMAKE
AC_CONFIG_SRCDIR([epoch.c])
AC_CONFIG_HEADERS([config.h])

# Checks for programs.
AC_PROG_CC

# Checks for libraries.

# Checks for header files.
AC_CHECK_HEADERS([sys/time.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_HEADER_TIME

# Checks for library functions.
AC_CHECK_FUNCS([gettimeofday])

AC_CONFIG_FILES([Makefile])
AC_OUTPUT
```
其实就是加了AM_INIT_AUTOMAKE这一行还有AC_HEADER_TIME
$ aclocal
$ automake ­­add­missing ­­copy
$ autoconf
$ ./configure 在这一步因为没有生成Makefile.in所以停下来了


### pkg-config
pkg-config是能够从一个config文件中读取到一个library的相关信息的tool，该config文件由library提供，用于描述该library的include dir，binary dir等信息。
[具体教程](https://people.freedesktop.org/~dbn/pkg-config-guide.html)


## 参考
[helloworld](https://thoughtbot.com/blog/the-magic-behind-configure-make-make-install)
[autotools教程](https://www.gnu.org/software/automake/manual/automake.html)
[Autoconf Tutorial Part-1](http://www.idryman.org/blog/2016/03/10/autoconf-tutorial-1/)
[another autotools tutorial](https://digitalleaves.com/blog/2017/12/build-cross-platform-c-project-autotools/)