---
title: cmake实用手册
date: 2018-11-26 13:42:16
tags: [C,linux]
---


当我们敲下cmake命令的时候，cmake会在当前目录下找CMakeLists.txt这个文件，找不到会报错的

![](https://www.haldir66.ga/static/imgs/fresh-sparkle-dew-drops-on-red-flower-wallpaper-53861cf580909.jpg)
<!--more-->

下面就是最简单的一个CMakeLists.txt的例子，project(hello_cmake)是一个函数，该函数生成了PROJECT_NAME这个变量，所以下面直接用了。add_executable（）第一个参数是要生成的可执行文件的名字，第二个参数(其实可以包括所有编译需要的源文件)

> cmake_minimum_required(VERSION 3.5)
project (hello_cmake)
add_executable(${PROJECT_NAME} main.cpp)

这个更简单
> cmake_minimum_required(VERSION 2.8)
project(app_project)
add_executable(myapp main.c)
install(TARGETS myapp DESTINATION bin)

生成Makefile
mkdir _build && cd _build && cmake .. -DCMAKE_INSTALL_PREFIX=../_install
生成的Makefile拿来用:
make && make install
省的手写Makefile了

cmake支持In-Place Build和Out-of-Source Build。前者是直接在当前文件夹（CMAKE_BINARY_DIR）中生成一大堆文件（太乱了），后者则是在一个指定的文件夹中生成文件。
Out-of-source build其实很简单
mkdir build && cd build/ && cmake .. (在build文件夹中会生成一个Makefile)
make && ./hello_cmake 


一堆内置的变量供参考

| Variable | Info |
| ------ | ------ |
| CMAKE_SOURCE_DIR | The root source directory |
| CMAKE_CURRENT_SOURCE_DIR | The current source directory if using sub-projects and directories. |
| PROJECT_SOURCE_DIR |The source directory of the current cmake project. |
| CMAKE_BINARY_DIR | The root binary / build directory. This is the directory where you ran the cmake command. |
| CMAKE_CURRENT_BINARY_DIR | The build directory you are currently in. |
| PROJECT_BINARY_DIR | The build directory for the current project. |


### header文件的处理
可以指定多个源文件
> set(SOURCES
    src/Hello.cpp
    src/main.cpp
)
add_executable(${PROJECT_NAME} ${SOURCES})
//或者直接把src文件夹下面的所有.cpp文件加入进来
file(GLOB SOURCES "src/*.cpp")


### 对于include文件夹
> target_include_directories(target
    PRIVATE
        ${PROJECT_SOURCE_DIR}/include
)
这样编译器就会在编译参数上加上-I/directory/path这种东西


### static library的处理
```
cmake_minimum_required(VERSION 3.5)

project(hello_library)

############################################################
# Create a library
############################################################

#Generate the static library from the library sources
add_library(hello_library STATIC 
    src/Hello.cpp //创建一个libhello_library.a 的static library
)

target_include_directories(hello_library
    PUBLIC 
        ${PROJECT_SOURCE_DIR}/include
)


############################################################
# Create an executable
############################################################

# Add an executable with the above sources
add_executable(hello_binary 
    src/main.cpp
)

# link the new hello_library target with the hello_binary target
target_link_libraries( hello_binary
    PRIVATE 
        hello_library
)
```


### shared library的处理
```
cmake_minimum_required(VERSION 3.5)

project(hello_library)

############################################################
# Create a library
############################################################

#Generate the shared library from the library sources
add_library(hello_library SHARED 
    src/Hello.cpp  // 用传入该函数的文件创建一个 libhello_library.so Library
)
add_library(hello::library ALIAS hello_library)

target_include_directories(hello_library //hello_library需要这个include directory
    PUBLIC 
        ${PROJECT_SOURCE_DIR}/include  
)

############################################################
# Create an executable
############################################################

# Add an executable with the above sources
add_executable(hello_binary
    src/main.cpp
)

# link the new hello_library target with the hello_binary target
target_link_libraries( hello_binary // 接下来就是Link了，这里使用了上面的一个alias
    PRIVATE 
        hello::library
)
```

### 接下来是make install (将生成的可执行文件安装到系统中，似乎就是复制到/usr/bin里面)
默认情况下cmake会把生成的可执行文件安装到系统中，我们可以指定安装到特定的位置
cmake .. -DCMAKE_INSTALL_PREFIX=/install/location

```
install (TARGETS cmake_examples_inst_bin
    DESTINATION bin)
// target cmake_examples_inst_bin target to the destination ${CMAKE_INSTALL_PREFIX}/bin


install (TARGETS cmake_examples_inst
    LIBRARY DESTINATION lib) 
//install the shared library generated from the target cmake_examples_inst target to the destination ${CMAKE_INSTALL_PREFIX}/lib       
```

> $ ls /usr/local/bin/
cmake_examples_inst_bin

> $ ls /usr/local/lib
libcmake_examples_inst.so

> $ ls /usr/local/etc/
cmake-examples.conf

> $ LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib cmake_examples_inst_bin
Hello Install! //把生成的bin文件复制到/sur/local/bin目录下，再修改LDPATH,就能去/usr/locallib这个目录去找生成的library了


##  Autoconf/Automake教程
GNU Autotools 一般指的是3个 GNU 工具包：Autoconf，Automake 和 Libtool (本文先介绍前两个工具，Libtool留到今后介绍)
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




## 参考
[cmake的教程，非常好](https://mirkokiefer.com/cmake-by-example-f95eb47d45b1)
[Useful CMake Examples](https://github.com/ttroy50/cmake-examples)本文来自这里的实例
[autotools教程](http://www.lugod.org/presentations/autotools/presentation/autotools.pdf)
