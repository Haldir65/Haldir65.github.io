---
title: cmake实用手册
date: 2018-11-26 13:42:16
tags: [C,linux,tools]
---


CMakeLists.txt这个文件的写法以及cmake这个executable的参数


![](https://api1.foster66.xyz/static/imgs/fresh-sparkle-dew-drops-on-red-flower-wallpaper-53861cf580909.jpg)
<!--more-->

[CMake好在跨平台](https://hulinhong.com/2018/04/21/cmake_tutorial/)
>你或许听过好几种 Make 工具，例如 GNU Make ，QT 的 qmake ，微软的 MS nmake，BSD Make（pmake），Makepp，等等。这些 Make 工具遵循着不同的规范和标准，所执行的 Makefile 格式也千差万别。这样就带来了一个严峻的问题：如果软件想跨平台，必须要保证能够在不同平台编译。而如果使用上面的 Make 工具，就得为每一种标准写一次 Makefile ，这将是一件让人抓狂的工作。
就是针对上面问题所设计的工具：它首先允许开发者编写一种平台无关的 CMakeList.txt 文件来定制整个编译流程，然后再根据目标用户的平台进一步生成所需的本地化 Makefile 和工程文件，如 Unix 的 Makefile 或 Windows 的 Visual Studio 工程。从而做到“Write once, run everywhere”。

下面就是最简单的一个CMakeLists.txt的例子，project(app_project)是一个函数，该函数生成了PROJECT_NAME这个变量，所以下面直接用了。add_executable（）第一个参数是要生成的可执行文件的名字，第二个参数(其实可以包括所有编译需要的源文件)


一个简单的CMakeLists.txt如下
```
cmake_minimum_required(VERSION 3.5)
project(app_project)
add_executable(myapp main.c)
install(TARGETS myapp DESTINATION bin)
```

其实就可以拿来用了，先不要急着敲cmake
```
mkdir _build && cd _build && cmake .. -DCMAKE_INSTALL_PREFIX=../_install
make && make install（install其实就是把可执行文件复制到/usr/bin里面，或者把.so文件复制到/usr/lib里，或者把/usr/include里面）
```


之所以没有直接在当前目录下敲cmake的原因是，cmake会在当前目录下生成一大堆中间产物，还不如挪到一个专门的目录下。所以一般都是推荐自己建一个build文件夹，避免弄乱自己的source tree
DCMAKE_INSTALL_PREFIX这个变量用于指定install复制的目的地，否则会把生成的可执行文件复制到/usr/bin这些目录里


cmake支持In-Place Build和Out-of-Source Build。前者是直接在当前文件夹（CMAKE_BINARY_DIR）中生成一大堆文件（太乱了），后者则是在一个指定的文件夹中生成文件。 (我觉得这一段知道有这么回事就行了)
Out-of-source build其实很简单
mkdir build && cd build/ && cmake .. (在build文件夹中会生成一个Makefile)
make && ./hello_cmake 

CMakeLists.txt文件也支持设置不允许IN_SOURCE_BUILD
set(CMAKE_DISABLE_IN_SOURCE_BUILD ON)

## cmake --help一类的东西吧
```
$ cmake -H. -Bbuild
$ cmake CMakeLists.txt //指定文件位置
# H indicates source directory
# B indicates build directory
```

### CMakeLists.txt里面一堆内置的变量供参考

| Variable | Info |
| ------ | ------ |
| CMAKE_SOURCE_DIR | The root source directory |
| CMAKE_CURRENT_SOURCE_DIR | The current source directory if using sub-projects and directories. |
| PROJECT_SOURCE_DIR |The source directory of the current cmake project. |
| CMAKE_BINARY_DIR | The root binary / build directory. This is the directory where you ran the cmake command. |
| CMAKE_CURRENT_BINARY_DIR | The build directory you are currently in. |
| PROJECT_BINARY_DIR | The build directory for the current project. |
| CMAKE_LIBRARY_OUTPUT_DIRECTORY | 生成的.dll或者.so文件的目录 |
| LIBRARY_OUTPUT_PATH | 生成的.dll或者.so文件的路径 |
| CMAKE_ARCHIVE_OUTPUT_DIRECTORY | 生成的.a或者.lib文件的目录 |
| ARCHIVE_OUTPUT_PATH | 生成的.a或者.lib文件的路径 |


###  还有一堆函数，比如strcmp这种,if else也是可以写的
这种自己查一下就行了

### 内置的一些变量结合函数能够帮助判断当前运行在哪种系统中
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

不希望把source tree搞乱
```
# Disable in-source builds to prevent source tree corruption.
if(" ${CMAKE_SOURCE_DIR}" STREQUAL " ${CMAKE_BINARY_DIR}")
  message(FATAL_ERROR "
FATAL: In-source builds are not allowed.
       You should create a separate directory for build files.
")
endif()
```

## 通过cmake运行test，例如make test
[make test](https://stackoverflow.com/questions/38436661/cmake-and-add-test-program-command)
```
project (TextMining)

enable_testing() //这一句一定要放在最外面的CMakeList.txt里面

set_tests_properties(TestProgram1 PROPERTIES DEPENDS TestProgram2) //甚至可以要求TestProgram2先跑，跑完再跑TestProgram1
```


## 看看一些开源项目的CMakeLists.txt是怎么写的,看看实际项目比看文档快点
[cJSON](https://github.com/DaveGamble/cJSON/blob/master/CMakeLists.txt)
[多个source文件夹的问题](https://stackoverflow.com/questions/8304190/cmake-with-include-and-source-paths-basic-setup) 实际工程中可能source directory或者library directory有多个，这时往往会在每一个对应的文件夹里面都看到一个CMakeLists.txt文件，这个才是工程中实际使用的。每一个CMakeLists.txt都指明了自己所在的文件夹中文件的关系，轻易不要瞎改。
[例如这样一个生成多个Target的项目](https://github.com/srdja/Collections-C/blob/master/test/CMakeLists.txt)
[再例如ss的CMakeList.txt](https://github.com/shadowsocks/shadowsocks-libev/blob/master/CMakeLists.txt)
[json-c的cmake](https://github.com/json-c/json-c/blob/master/CMakeLists.txt)

## 总结
1. [这个repo](https://github.com/ttroy50/cmake-examples)总结了各种各样的场景，例如编译单个binary，编译library，link第三方library，调整linker参数。。。。需要的时候照着这个写就是了
2. 自己参照着[介绍了build app, build library以及link_library的基本操作](https://mirkokiefer.com/cmake-by-example-f95eb47d45b1)写了几个[example](https://github.com/Haldir65/Channel/tree/master/tool_write_cmake)，分别是build binary，build library 和link library，分别cd到对应文件夹下面运行shell脚本就行了
3. cmake .. 会导致install到/usr/lib里面， 我个人不是很喜欢这种把系统目录弄乱的方式。还是cmake -DCMAKE_INSTALL_PREFIX=../install。
4. 这只是个工具，我知道需要的时候去哪里查资料,这就足够了


## 参考
[介绍了很多的内置变量](https://medium.com/@onur.dundar1/cmake-tutorial-585dd180109b) 比较长，话说这些变量需要的时候再查也不是不行
[cmake 2020年更新](https://cliutils.gitlab.io/modern-cmake/chapters/basics.html) 不是很推荐，太深层次了。

