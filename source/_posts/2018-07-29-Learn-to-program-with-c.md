---
title: C语言学习手册
date: 2018-07-29 17:47:28
tags: [C]
---


C语言实用指南，暂时不涉及cpp内容
![](https://haldir66.ga/static/imgs/pretty-orange-mushroom-wallpaper-5386b0c8c3459.jpg)
<!--more-->

## 先从最常用的字符串说起吧
[string in c](https://dev-notes.eu/2018/08/strings-in-c/)
char *name = "Bob"; //name指向的位置不能修改了，但是name可以指向别的东西.
// the value is stored in a read-only section in the binary file and cannot be modified
name[1] = 'e'; //这么干是不行的，编译是能通过，但运行期会造成undefined behavior，大概率是segment fault

```c
You can also define a string as a pointer to a char, initialised by a string literal. In this case, string literals are stored in a read only section of memory and are effectively constant. For example:

char *name = "Bob"
In this case, the value is stored in a read-only section in the binary file and cannot be modified. If you compile to an assembly file (use the -S compiler option in gcc), you can see the string literals in the .rodata section. In this context, rodata means “read-only data”.

/* main.s */
.file	"main.c"
.section	.rodata
.LC0:
.string	"Bob"
```

// 下面这种用数组形式声明的是可以随便改的
char name[] = "Alice"; //存在stack上，随便改
name[3] = 'n';
name[4] = 'a';

在C中，NULL表示的是指向0的指针
#define NULL    0

string.h 标准库中定义了空指针，NULL(数值0)
在C/C++中，当要给一个字符串添加结束标志时，都应该用‘\0’而不是NULL或0

‘\0’是一个“空字符”常量，它表示一个字符串的结束，它的ASCII码值为0。注意它与空格' '（ASCII码值为32）及'0'（ASCII码值为48）不一样的。


## 编译链接过程的一些注意事项：
编译过程可以传一些flag(无论是gcc还是clang都是一样的)
preprocessor -E  ##handle #include define
compiler -S ##translate C to assembly(生成.s文件)
assembler -c ## translate assembly to object file(.o，文件是针对特定cpu,platform的,.o文件是不可执行的)
linker bring together object file to produce executable

如果没有-E -S或者-c的话，就goes all the way down to executable
-O 是指定最终生成的executable的名称的

1. 链接过程中缺少了相关目标文件(.o)
测试代码:
```c
//main.c

int main()
{
    test();
}

//test.c
#include <stdio.h>
void test()
{
    printf("test\n");
}

//test.h
void test();
```

首先生成两个.o文件: 
gcc -c test.c //生成test.o
gcc -c main.c //生成main.o

然后试着链接两个.o文件
gcc -o main main.o

出错了！
main.o: In function `main':
main.c:(.text+0x15): undefined reference to `test'
collect2: error: ld returned 1 exit status

这就是典型的undefined reference错误，因为在链接的时候发现找不到test函数的实现。
改成下面这种就好了
gcc -o main main.o test.o

上面的过程其实是编译和链接两部分开了:
gcc -o main main.c // 其实是生成.o文件直接链接，然后在链接阶段还是会出现上面的错误
gcc -o main main.c test.c //这样就可以了

2. 链接时缺少相关的库文件(.a/.so文件)
以静态库为例
测试代码:
```c
//main.c

int main()
{
    test();
}

//test.c
#include <stdio.h>
void test()
{
    printf("test\n");
}
//test.h
void test();
```

先把test.c编译成静态库文件(.a)
gcc -c test.c
ar -rc test.a test.o //生成test.a文件

接下来开始编译main.c
gcc -c main.c

链接
gcc -o main main.o
报错！
➜  test (master) ✗ gcc -o main main.o
main.o: In function `main':
main.c:(.text+0x15): undefined reference to `test'
collect2: error: ld returned 1 exit status

原因也是找不到test函数的实现
改成下面这种就可以了
gcc -o main main.o ./test.a //其实就是告诉了它test.a的路径

也可以把两部分为一步： gcc -o main main.c ./test.a //加上test.a是为了告诉它test.a的路径

3. 链接的库文件中又使用了另一个库文件
还是上面的例子
```c
//main.c

int main()
{
    test();
}

//test.c
#include <stdio.h>
void test()
{
    printf("test\n");
}

//test.h
void test();

// func.h
void func();

//func.c
#include <stdio.h>
void func()
{
    printf("executing func!\n");
}
```

首先是生成.o文件
gcc -c func.c
gcc -c test.c
gcc -c main.c

然后打包静态库文件
ar -rc func.a func.o
ar -rc test.a test.o

接下里准备将main.o链接为可执行程序
gcc -o main main.o ./test.a
test.a(test.o): In function `test':  
test.c:(.text+0x13): undefined reference to `func'  
collect2: ld returned 1 exit status 

正确的做法是需要把func.a的路径也给添加进来
gcc -o main main.o test.a func.a 
所以如果我们的库或者在程序中引用到了第三方库，那么同样需要在链接的时候给出第三方库的路径和库文件，否则会得到undefined reference的错误

4. 多个库文件链接的顺序问题
依赖其他库的库一定要放到被依赖库的前面，这样才能真正避免undefined reference的错误
越是基础的库越要写在后面,无论是静态还动态

5.  在c++代码中链接c语言的库
```c
//test.c
#include <stdio.h>
void test()
{
    printf("hey there!\n");
}
//test.h
void test();
```
打包成静态库:
gcc -c test.c
ar -rc test.a test.o

接下来在c++里写main.cpp
```c++
// main.cpp
#include "test.h"
int main()
{
    test();
    return 1;
}
```
编译main.cpp生成可执行程序
g++ -o main main.cpp test.a
/tmp/ccJjiCoS.o: In function `main': 
main.cpp:(.text+0x7): undefined reference to `test()' 
collect2: ld returned 1 exit status 

原因是cpp代码调用C语言的函数时需要把include c相关的头文件用extern "C"包起来:
```c++
extern "C"
{
    #include "test.h"    
}

int main()
{
    test();
    return 1;
}
```
g++ -o main main.cpp test.a //就没有问题了



gcc ,clang,llvm的历史

[参考教程](https://www.youtube.com/playlist?list=PLCNJWVn9MJuPtPyljb-hewNfwEGES2oIW)


.so文件其实是shared object的缩写

## Makefile怎么写
[几个简单的makefile实例](http://www.cs.colby.edu/maxwell/courses/tutorials/maketutor/)

// 比方说写了三个文件,main.c,test.c,test.h。这是最简单的例子
main: main.c
    gcc -o main main.c test.c //ok,没问题了 

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


从项目结构来看,curl,ffmpeg这些都是一个文件夹里面放了所有的.h和.c文件。似乎没有其他语言的package的观念。我试了下，在Makefile里面带上文件夹的相对路径还是可以的。



[automatic directory creation in make](http://ismail.badawi.io/blog/2017/03/28/automatic-directory-creation-in-make/)

[C的基本数据类型还是很多的](https://zh.cppreference.com/w/cpp/language/types) 居然还有unsigned long long int 这种别扭的东西。


scanf方法存在内存溢出的可能性，微软提出了scanf_s函数，需要提供最多允许读取的长度，超出该长度的字符一律忽略掉。
[汇编语言](http://www.ruanyifeng.com/blog/2018/01/assembly-language-primer.html)

[windows平台使用visual studio创建C项目](https://www.youtube.com/watch?v=Slgwyta-JkA)
File -> new Project ->Windows DeskTop Wizard -> 选中Empty Project -> 取消选中Precompile Header
然后右侧，source File,右键，new item。创建main.c(任意名字.c都是行的),然后写主函数。
运行的话，点上面的local windows debugger是可以的，但是会一闪而过。按下ctrl +F5，会出现console。

visual studio中断点的step into是f11，step out of 是shift + f11 .step over是f10

evaluate expression在右下角的immediate window中输入表达式即可

visual studio中debug的时候有时候会出现Cannot find or open the PDB file
[intel说这种事不是error](https://software.intel.com/en-us/articles/visual-studio-debugger-cannot-find-or-open-the-pdb-file)。所以就不要去管好了。

在C语言中没有泛型。故采用void 指针来实现泛型的效果。

这段会core dump的

```c
char *s1 = "hello"; ##获得了一个指向字符串常量的指针
*s1 = 'hey'; ##尝试修改常量，会segmentfault
##这段也会core dump
char* s1 = "hello";
s1 += 1;
printf("content %s\n",*s1);##崩在这里
printf("content %s\n",s1);##改成这样就好了
```

preprocessor的套路一般是这样的
awesomeFunction.h
```C
#ifndef AWESOME_FUNCTION
#define AWESOME_FUNCTION

## 实际的函数声明

#endif //AWESOME_FUNCTION
```

c语言中不同头文件中的方法名或者外部变量是不能重名的（所以给方法起名字的时候要注意下），除非使用static关键字（只在该源文件内可以使用）  静态变量存放在全局数据区，不是在堆栈上，所以不存在堆栈溢出的问题。生命周期是整个程序的运行期。（static变量只在当前文件中可以使用，一旦退出当前文件的调用，就不可用，但如果运行期间又调用了该文件，那么static变量的值就会是刚才退出的时候的值，而不是default值）
设计和调用访问动态全局变量、静态全局变量、静态局部变量的函数时，需要考虑重入问题。
[函数名冲突的问题也可以用一个struct封起来](https://segmentfault.com/q/1010000002512553/a-1020000002512728)


[dlopen和soname](https://renenyffenegger.ch/notes/development/languages/C-C-plus-plus/GCC/create-libraries/index)
[c语言const关键字](https://www.jianshu.com/p/46926f2ffef0)有的时候是说指针指向的对象不能动，有的时候说的是指针指向的值不能动

size_t 和int差不多，估摸着是跨平台的一种表示。


autoconf和automake的使用教程

mac上查看某个library是否install了：
> ld -ljson-c ##看下json-c这个library是否已经安装了
d: library not found for -ljson-c ##这种就是没有找到


### 最后
c语言就是这样，好多功能都得自己实现
>c 语言有它的设计哲学，就是那著名的“Keep It Simple, Stupid”，语言本身仅仅实现最为基本的功能，然后标准库也仅仅带有最为基本的内存管理（更高效一点的内存池都必须要自己实现）、IO、断言等基本功能。 

社区提供了一些比较优秀的通用功能库
[1] http://developer.gnome.org/glib/stable/ 
[2] http://www.gnu.org/software/gnulib/ 
[3] http://apr.apache.org/

