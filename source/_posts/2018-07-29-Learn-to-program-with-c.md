---
title: C语言学习手册
date: 2018-07-29 17:47:28
tags: [C]
---


C语言实用指南，暂时不涉及cpp内容
![](http://haldir66.ga/static/imgs/pretty-orange-mushroom-wallpaper-5386b0c8c3459.jpg)
<!--more-->

gcc ,clang,llvm的历史

[参考教程](https://www.youtube.com/playlist?list=PLCNJWVn9MJuPtPyljb-hewNfwEGES2oIW)


.so文件其实是shared object的缩写


## Makefile怎么写
[几个简单的makefile实例](http://www.cs.colby.edu/maxwell/courses/tutorials/maketutor/)

[C Programming: Makefiles](https://www.youtube.com/watch?v=GExnnTaBELk)


make file automatic rule


[static and dynamic libraries](https://www.geeksforgeeks.org/static-vs-dynamic-libraries/)

static library把依赖的library都打包进去了，体积更大
dynamic libvrary只是写了依赖的library的名称，运行时需要去操作系统中去找，会慢一些


static libiray(compile time已完成link，而dynamic library需要在runtime完成link)

查看archive文件中的内容
ar -tv libmylib.a

nm somebinaryfile ## 查看动态和静态库中的符号表


ls /usr/lib ## 文件夹中又各种lib,包括so文件和.a文件
ls /usr/include # 这里也有一大堆头文件

clang wacky.c -L. -lwacky -o wacky ## -L. 表示在当前目录下查找后面的libwacky.so或者libwacky.a文件。所以完全可以link 系统中存在的(/usr/lib目录中)的library并compile到program中

Makefile for bundling static library（每一个chunk叫做recepie）
不能用空格，需要用Tab
```
default: wacky

wacky: libwacky.a  wacky.c
        clang wacky.c -L. -lwacky -o wacky

libwacky.a: wacky_math.o
        ar -rcv $@ $^
```


### dynamic library
wacky_math.o: wacky_math.c wacky_math.h
        clang -c -fPIC wacky_math.c -o $@

-fPIC使得生成的object file是relocateable的
同时还得告诉run time linke如何去找这个so文件

man ldpath ##  so文件查找目录
export LD_LIBRARY_PATH=. ## 添加当前目录为查找路径


//一般so文件都在/usr/lib或者/usr/local/lib文件夹下面
locate sodium.so


make wacky 也是可以的，可以指定编译target


### 
[C Programming: Makefiles](https://www.youtube.com/watch?v=GExnnTaBELk)

编译过程可以传一些flag(无论是gcc还是clang都是一样的)
preprocessor -E  ##handle #include define
compiler -S ##translate C to assembly(生成.s文件)
assembler -c ## translate assembly to object file(.o，文件是针对特定cpu,platform的,.o文件是不可执行的)
linker bring together object file to produce executable

[编译时发生了什么](https://mooc.guokr.com/note/13202/)

如果没有-E -S或者-c的话，就goes all the way down to executable
-O 是指定最终生成的executable的名称的


在c program中使用其他的library以及如何编译生成可执行文件

make clean

clean:
    rm -f *.o program_name

因为手动rm可能写成
rm -f * .o 中间多一个空格

[make file examples](https://www.tutorialspoint.com/makefile/makefile_example.htm)


经常会看到项目里面的安装指南包括./configure make..
GNU的AUTOCONF和AUTOMAKE

./config && make && sudo make install || exit 1

比如说awk的安装过程是这样的
wget http://ftp.gnu.org/gnu/gawk/gawk-4.1.1.tar.xz
tar xvf gawk-4.1.1.tar.xz
cd gawk-4.1.1 && ./configure
make
make check
sudo make install

如何生成一个auto build file
[auto build configure file](https://stackoverflow.com/questions/10999549/how-do-i-create-a-configure-script)

[Linux下安装、配置libevent](http://hahaya.github.io/build-libevent/)
[使用libevent输出Hello](http://hahaya.github.io/hello-in-libevent/)


todo read the manual page for gcc(clang) to see all the available command line arguments

如何使用C语言库
[以mysql的c库为例](https://blog.csdn.net/yanxiangtianji/article/details/20474155)
如果库在 usr/include/ 目录下，那么就用 #include < *.h >。这个目录下面放的都是些头文件

如果库在当前目录下，就用　#include "mylib.h"

gcc -v可以查看compile gcc时预设的链接静态库的搜索路径

```
默认情况下， GCC在链接时优先使用动态链接库，只有当动态链接库不存在时才考虑使用静态链接库，如果需要的话可以在编译时加上-static选项，强制使用静态链接库。
静态库链接时搜索路径顺序：

1. ld会去找GCC命令中的参数-L
2. 再找gcc的环境变量LIBRARY_PATH
3. 再找内定目录 /lib /usr/lib /usr/local/lib 这是当初compile gcc时写在程序内的

动态链接时、执行时搜索路径顺序:

1. 编译目标代码时指定的动态库搜索路径
2. 环境变量LD_LIBRARY_PATH指定的动态库搜索路径
3. 配置文件/etc/ld.so.conf中指定的动态库搜索路径
4. 默认的动态库搜索路径/lib
5. 默认的动态库搜索路径/usr/lib

有关环境变量：
LIBRARY_PATH环境变量：指定程序静态链接库文件搜索路径
LD_LIBRARY_PATH环境变量：指定程序动态链接库文件搜索路径

创建文件这边
mkdir并不会自动创建上层目录，所以就有了这样的方法
```c
#include<sys/stat.h>
#include<sys/types.h>
mkdir("head",0777);
mkdir("head/follow".0777);
mkdir("head/follow/end",0777);
```

或者自己写函数
```c
void mkdirs(char *muldir) 
{
    int i,len;
    char str[512];    
    strncpy(str, muldir, 512);
    len=strlen(str);
    for( i=0; i<len; i++ )
    {
        if( str[i]=='/' )
        {
            str[i] = '\0';
            if( access(str,0)!=0 ) // access函数判断是否有存取文件的权限
            {
                mkdir( str, 0777 );
            }
            str[i]='/';
        }
    }
    if( len>0 && access(str,0)!=0 )
    {
        mkdir( str, 0777 );
    }
    return;
}
```

c语言就是这样，好多功能都得自己实现
>c 语言有它的设计哲学，就是那著名的“Keep It Simple, Stupid”，语言本身仅仅实现最为基本的功能，然后标准库也仅仅带有最为基本的内存管理（更高效一点的内存池都必须要自己实现）、IO、断言等基本功能。 

社区提供了一些比较优秀的通用功能库
[1] http://developer.gnome.org/glib/stable/ 
[2] http://www.gnu.org/software/gnulib/ 
[3] http://apr.apache.org/

[automatic directory creation in make](http://ismail.badawi.io/blog/2017/03/28/automatic-directory-creation-in-make/)
```
