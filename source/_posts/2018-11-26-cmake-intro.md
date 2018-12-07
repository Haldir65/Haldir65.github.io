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


## Autotools and Make教程
GNU Autotools 一般指的是3个 GNU 工具包：Autoconf，Automake 和 Libtool (本文先介绍前两个工具，Libtool留到今后介绍)
它们能解决什么问题，要先从 GNU 开源软件的 Build 系统说起。一般来说。GNU 软件的安装过程都是：

解压源代码包
./configure
make
make install
这个过程中， 需要有一个 configure 脚本，同时也需要一个 Makefile 文件。

而 Autoconf 和 Automake 就是一套自动生成 configure 脚本和 Makefile 文件的工具。

## 
[cmake的教程，非常好](https://mirkokiefer.com/cmake-by-example-f95eb47d45b1)
[Useful CMake Examples](https://github.com/ttroy50/cmake-examples)本文来自这里的实例
[autotools教程](http://www.lugod.org/presentations/autotools/presentation/autotools.pdf)
