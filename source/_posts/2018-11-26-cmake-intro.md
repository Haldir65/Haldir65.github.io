---
title: cmake实用手册
date: 2018-11-26 13:42:16
tags: [C,linux]
---


当我们敲下cmake命令的时候，cmake会在当前目录下找CMakeLists.txt这个文件


![](https://www.haldir66.ga/static/imgs/fresh-sparkle-dew-drops-on-red-flower-wallpaper-53861cf580909.jpg)
<!--more-->

[CMake好在跨平台](https://hulinhong.com/2018/04/21/cmake_tutorial/)
>你或许听过好几种 Make 工具，例如 GNU Make ，QT 的 qmake ，微软的 MS nmake，BSD Make（pmake），Makepp，等等。这些 Make 工具遵循着不同的规范和标准，所执行的 Makefile 格式也千差万别。这样就带来了一个严峻的问题：如果软件想跨平台，必须要保证能够在不同平台编译。而如果使用上面的 Make 工具，就得为每一种标准写一次 Makefile ，这将是一件让人抓狂的工作。
就是针对上面问题所设计的工具：它首先允许开发者编写一种平台无关的 CMakeList.txt 文件来定制整个编译流程，然后再根据目标用户的平台进一步生成所需的本地化 Makefile 和工程文件，如 Unix 的 Makefile 或 Windows 的 Visual Studio 工程。从而做到“Write once, run everywhere”。

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


内置的一些变量能够帮助判断当前运行在哪种系统中
```shell
cmake_minimum_required(VERSION 3.9.1)
project(CMakeHello)
set(CMAKE_CXX_STANDARD 14)
# UNIX, WIN32, WINRT, CYGWIN, APPLE are environment variables as flags set by default system
if(UNIX)
    message("This is a ${CMAKE_SYSTEM_NAME} system")
elseif(WIN32)
    message("This is a Windows System")
endif()
# or use MATCHES to see if actual system name 
# Darwin is Apple's system name
if(${CMAKE_SYSTEM_NAME} MATCHES Darwin)
    message("This is a ${CMAKE_SYSTEM_NAME} system")
elseif(${CMAKE_SYSTEM_NAME} MATCHES Windows)
    message("This is a Windows System")
endif()
add_executable(cmake_hello main.cpp)
```

还可以在cmake中定义变量，在c++代码中引用
CMakeLists.txt 
```shell
cmake_minimum_required(VERSION 3.9.1)
project(CMakeHello)
set(CMAKE_CXX_STANDARD 14)
# or use MATCHES to see if actual system name 
# Darwin is Apple's system name
if(${CMAKE_SYSTEM_NAME} MATCHES Darwin)
    add_definitions(-DCMAKEMACROSAMPLE="Apple MacOS")
elseif(${CMAKE_SYSTEM_NAME} MATCHES Windows)
    add_definitions(-DCMAKEMACROSAMPLE="Windows PC")
endif()
add_executable(cmake_hello main.cpp)
```

```c++
#include <iostream>
#ifndef CMAKEMACROSAMPLE
    #define CMAKEMACROSAMPLE "NO SYSTEM NAME"
#endif
auto sum(int a, int b){
        return a + b;
}
int main() {
        std::cout<<"Hello CMake!"<<std::endl;
		std::cout<<CMAKEMACROSAMPLE<<std::endl;
        std::cout<<"Sum of 3 + 4 :"<<sum(3, 4)<<std::endl;
        return 0;
}
```


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

### 接下来是make install (将生成的可执行文件安装到系统中，就是复制到CMAKE_INSTALL_PREFIX里面)
CMAKE_INSTALL_PREFIX默认值是 usr/locals
默认情况下cmake会把生成的可执行文件安装到系统中，我们可以指定安装到特定的位置，推荐方案是放到用户目录下的.local文件夹下面
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


## 查找系统中已安装的library
如果没有找到，停止编译过程
```shell
find_package(Boost 1.66)
# Check for libray, if found print message, include dirs and link libraries.
if(Boost_FOUND)  ## 直接判断是否找到
    message("Boost Found")
    include_directories(${Boost_INCLUDE_DIRS})
    target_link_libraries(cmake_hello ${Boost_LIBRARIES})
elseif(NOT Boost_FOUND)
    error("Boost Not Found")
endif()
```




## 参考
[cmake的教程，非常好](https://mirkokiefer.com/cmake-by-example-f95eb47d45b1)
[Useful CMake Examples](https://github.com/ttroy50/cmake-examples)本文来自这里的实例
[完整教程](https://medium.com/@onur.dundar1/cmake-tutorial-585dd180109b)
