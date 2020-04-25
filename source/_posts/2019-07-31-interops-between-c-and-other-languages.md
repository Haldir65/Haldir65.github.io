---
title: 各种编程语言与c、c++的交互
date: 2019-07-31 22:11:55
tags:
---

![](https://api1.foster66.xyz/static/imgs/SutherlandFalls_ZH-CN4602884079_1920x1080.jpg)
<!--more-->

## 1. cpython
### 1.1 python中调用C、C++代码

方法一：
Python中的ctypes模块可能是调用C方法最简单的一种。ctypes模块提供了和C语言兼容的数据类型了函数来加载dll或者so文件。

c语言代码: add.c
```c
#include <stdio.h>

int add_int(int, int);
float add_float(float, float);
 
int add_int(int num1, int num2){
    return num1 + num2;
}
 
float add_float(float num1, float num2){
    return num1 + num2;
}
```
下面的命令生成一个adder.so的文件
#For Linux
$  gcc -shared -Wl,-soname,adder -o adder.so -fPIC add.c
 
#For Mac
$ gcc -shared -Wl,-install_name,adder.so -o adder.so -fPIC add.c

python代码
```python
from ctypes import *
 
#load the shared object file
adder = CDLL('./adder.so')
 
#Find sum of integers
res_int = adder.add_int(4,5)
print "Sum of 4 and 5 = " + str(res_int)
 
#Find sum of floats
a = c_float(5.5)
b = c_float(4.1)
 
add_float = adder.add_float
add_float.restype = c_float
print "Sum of 5.5 and 4.1 = ", str(add_float(a, b))
```


方法二：Python/C API（c python extension  ）
其实就是自己写python c extension了
```python
#Though it looks like an ordinary python import, the addList module is implemented in C
import addList
 
l = [1,2,3,4,5]
print "Sum of List - " + str(l) + " = " +  str(addList.add(l))
```

```c
//Python.h has all the required function definitions to manipulate the Python objects
#include <Python.h>
 
//This is the function that is called from your python code
static PyObject* addList_add(PyObject* self, PyObject* args){
 
    PyObject * listObj;
 
    //The input arguments come as a tuple, we parse the args to get the various variables
    //In this case it's only one list variable, which will now be referenced by listObj
    if (! PyArg_ParseTuple( args, "O", &listObj ))
        return NULL;
 
    //length of the list
    long length = PyList_Size(listObj);
 
    //iterate over all the elements
    int i, sum =0;
    for (i = 0; i < length; i++) {
        //get an element out of the list - the element is also a python objects
        PyObject* temp = PyList_GetItem(listObj, i);
        //we know that object represents an integer - so convert it into C long
        long elem = PyInt_AsLong(temp);
        sum += elem;
    }
 
    //value returned back to python code - another python object
    //build value here converts the C long to a python integer
    return Py_BuildValue("i", sum);
 
}
 
//This is the docstring that corresponds to our 'add' function.
static char addList_docs[] =
"add(  ): add all elements of the list\n";
 
/* This table contains the relavent info mapping -
   <function-name in python module>, <actual-function>,
   <type-of-args the function expects>, <docstring associated with the function>
 */
static PyMethodDef addList_funcs[] = {
    {"add", (PyCFunction)addList_add, METH_VARARGS, addList_docs},
    {NULL, NULL, 0, NULL}
 
};
 
/*
   addList is the module name, and this is the initialization block of the module.
   <desired module name>, <the-info-table>, <module's-docstring>
 */
PyMODINIT_FUNC initaddList(void){
    Py_InitModule3("addList", addList_funcs,
            "Add all ze lists");
 
}
```
### 1.2 C、C++调用python代码
参考上面的python c extension方法，可以在c语言中操作python对象


### 1.3 python调用系统方法
```py
##　第一种
os.system(command)

## 第二种
import subprocess
subprocess.Popen(args, bufsize=0, executable=None, stdin=None, stdout=None, stderr=None, preexec_fn=None, close_fds=False, shell=False, cwd=None, env=None, universal_newlines=False, startupinfo=None, creationflags=0)

subprocess.call(["cmd", "arg1", "arg2"],shell=True)
```
目前python官方推荐的调用方法的方式还是subprocess。


cython(python c extension)和cpython(c语言实现的python）是两件事

## 2. javascript
### 2.1 javascript调用C、C++代码
首先，在浏览器中运行c语言的代码，似乎可以将C编成WebAssembly在浏览器中运行。
而在Node js中，可以使用[n-api](https://nodejs.org/api/n-api.html)这个module。
> N-API (pronounced N as in the letter, followed by API) is an API for building native Addons. It is independent from the underlying JavaScript runtime (for example, V8) and is maintained as part of Node.js itself. This API will be Application Binary Interface (ABI) stable across versions of Node.js. It is intended to insulate Addons from changes in the underlying JavaScript engine and allow modules compiled for one major version to run on later major versions of Node.js without recompilation. 

就是说保持了binary compatibility，比如说在node6上编译通过之后，假如后面出了node10，不需要重新编译也能继续运行。

node-gyp(gyp是generate your project的意思)可以编译生成node js addon，其实也就是在host机器上生成对应的机器码
下面看如何使用:
[how-to-call-c-c-code-from-node-js](https://medium.com/@tarkus/how-to-call-c-c-code-from-node-js-86a773033892)
很多大型js项目都有一个binging.gyp文件（一定是这个名字）

[node js addon](https://jameshfisher.com/2019/04/20/nodejs-addon-hello-world/) 在js代码中还是import的方式

[youtube上有一个2019年的windows上的教程](https://www.youtube.com/watch?v=O4Rlq_NSkoM)

gyp其实是一个用来生成项目文件的工具，一开始是设计给chromium项目使用的，后来大家发现比较好用就用到了其他地方。生成项目文件后就可以调用GCC, vsbuild, xcode等编译平台来编译。至于为什么要有node-gyp，是由于node程序中需要调用一些其他语言编写的工具甚至是dll，需要先编译一下，否则就会有跨平台的问题，例如在windows上运行的软件copy到mac上就不能用了，但是如果源码支持，编译一下，在mac上还是可以用的。


### 2.2 C、C++调用javascript代码
[JavaScript is not a compiled language](https://stackoverflow.com/questions/2713289/how-to-execute-javascript-function-in-c) 所以这么做虽然可行，但是比较麻烦。且网上的教程多数是c++的。

### 2.3 javascript调用系统方法
在node js 中可以使用[child_process模块](https://nodejs.org/api/child_process.html#child_process_child_process_execfile_file_args_options_callback)

```c
// myProgram.c
#include <stdio.h>
int main(void){
    puts("4");
    return 0;
}
```
gcc -o myProgram myProgram.c

```js
const { exec } = require("child_process");
exec("./myProgram", (error, stdout, stderr) => console.log(stdout));
```


## 3. java
其实就是jni了，[To be honest, if you have any other choice besides using JNI, do that other thing.](https://medium.com/@bschlining/a-simple-java-native-interface-jni-example-in-java-and-scala-68fdafe76f5f)
如果不是没有java的解决方法，不要使用jni，一个是麻烦，另一个是我们彻底失去了跨平台兼容性

[这篇文章是我见识过的最新手友好的jni解释](https://www.zfl9.com/java-jni.html)

JNI的流程网上有一大堆，注意的是不同的平台gcc的参数是不一样的，三步直接搞定,在linux上亲测这样是可以的
```shell
## 生成头文件其实也很简单
javac -h . HelloJNI2.java 
## 先是生成.o文件
gcc -c -I /usr/lib/jvm/java-8-openjdk-amd64/include -I /usr/lib/jvm/java-8-openjdk-amd64/include/linux jni/hellojni.c  
## 然后打成sharedLibrary
gcc -rdynamic -shared -o libhellojni.so hellojni.o

## 在intelij里面class文件都放在target/classes目录下，这么一句话就能把代码跑起来
java -cp .:target/classes com.me.harris.jupiter.channel.HelloJNI
```

这两步走完，就在当前目录下生成了libhellojni.so文件，接下来看java代码这边
使用System.loadLibrary的前提是把这个so文件扔到/usr/lib这一类的文件夹里面，或者使用-Djava.library.path指定
具体点的话：

```java
System.out.println(System.getProperty("java.library.path"));
// 打印出来 /usr/java/packages/lib/amd64:/usr/lib/x86_64-linux-gnu/jni:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/usr/lib/jni:/lib:/usr/lib
// loadLibrary("hello")就是去上述目录里面找一个叫做libhello.so的文件，没有的话就报错
//java -cp . -Djava.library.path=/NATIVE_SHARED_LIB_FOLDER com.xxx.xxx

String currentDir = System.getProperty("user.dir"); //这个就是pwd
System.load(currentDir+"/"+"libhellojni.so"); //load则是给出文件的绝对路径,这里面的斜线照说也要依据平台区分的,System.getProperty("line.separator")
```

### 3.1 java调用C、C++代码
[详细教程](https://www.baeldung.com/jni)
这个没什么好说的

### 3.2 C、C++调用java代码
c、c++层调用java也是可以的,甚至可以在native层创建一个java实例返回给java层，所以创建一个java对象的方法至少包括new,unsafe,Constructor.newInstance以及jni。 unsafe的方式只是分配内存，并不调用构造函数。

```java
//1. 用new关键字，这个没什么好说的

//2. 用unsafe
Unsafe#allocateInstance(Class<?>) 

//3. 用java.lang.reflect.Constructor.newInstance(Object... initargs) 
public T newInstance(Object... initargs) throws InstantiationException,
IllegalAccessException, IllegalArgumentException, InvocationTargetException

public native T newInstance() throws InstantiationException, IllegalAccessException;

区别:
class.newInstance()只能反射无参的构造函数(只能public的),对于捕获的或者未捕获的异常均由构造函数抛出(底层调用的是Constructor.newInstance((Object[])null)，所以是可以传一个null进去的)
Constructor.newInstance()可以反射任何构造函数(包括私有)，通常会把抛出的异常封装成InvocationTargetException抛出。

// 4.jni直接操作
//关键就这么一句，注意这一句是不会调用到无参的构造函数的。
env->AllocObject(userDataClass);
```

好奇看了眼unsafe的[hotspot源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/tip/src/share/vm/prims/unsafe.cpp) 原来用的也是AllocObject
```cpp
UNSAFE_ENTRY(jobject, Unsafe_AllocateInstance(JNIEnv *env, jobject unsafe, jclass cls))
  UnsafeWrapper("Unsafe_AllocateInstance");
  {
    ThreadToNativeFromVM ttnfv(thread);
    return env->AllocObject(cls);
  }
UNSAFE_END
```

比方说入口文件叫做com.me.harris.jupiter.channel.HelloJNI2.java
生成的头文件就叫做
com_me_harris_jupiter_channel_HelloJNI2.h
g++的参数有一点点区别
```shell
g++ -c -fPIC -I${JAVA_HOME}/include -I${JAVA_HOME}/include/linux com_me_harris_jupiter_channel_HelloJNI2.cpp -o com_me_harris_jupiter_channel_HelloJNI2.o
g++ -shared -fPIC -o libnative.so com_me_harris_jupiter_channel_HelloJNI2.o -lc
mv libnative.so  jni
java -cp .:target/classes -Djava.library.path=jni com.me.harris.jupiter.channel.HelloJNI2 ## java命令行参数一个比较烦人的地方就是com.example.Main这个class非得要去一个com/example文件夹下面有这个class文件
##cp的意思就是classpath了，这个命令要能跑成功，前提是target文件夹下有个com/me/harris/jupiter/channel/这么一连串的文件夹 
```

java classpath的分隔符,在windows上是;  在unix上是: 


[自己参考着写了jni的一些用例，剩下的就是照着oracle的doc一个个去尝试参数和方法了](https://github.com/Haldir65/scripts/tree/master/jnistuff)

比如从jni层返回一个java对象
比如在jni层查看java native方法穿过来的参数的值
比如通过jni修改一个final 变量的值。其实照着doc来几乎不会出错
比如在jni层在一条c++线程中通过AttachCurrentThread方法回调java

### 3.3 java调用系统方法
java有一个Process api
java中Process的Api
关键词：ProcessBuilder , java9提供了新的Api。另外还有Runtime.exec这个方法
亲测，下面的命令可以在mac上执行uname -a 命令
```java
//用ProcessBuilder是一种做法
 try {
        Runtime r = Runtime.getRuntime();
        Process p = r.exec("uname -a");
        p.waitFor();
        BufferedReader b = new BufferedReader(new InputStreamReader(p.getInputStream()));
        String line = "";

        while ((line = b.readLine()) != null) {
            System.out.println(line);
        }

        b.close();
    }catch (IOException | InterruptedException e){
        
    }

//  下面这个也行
String s = null;

try {

    // run the Unix "ps -ef" command
    // using the Runtime exec method:
    Process p = Runtime.getRuntime().exec("ps -ef");

    BufferedReader stdInput = new BufferedReader(new
            InputStreamReader(p.getInputStream()));

    BufferedReader stdError = new BufferedReader(new
            InputStreamReader(p.getErrorStream()));

    // read the output from the command
    System.out.println("Here is the standard output of the command:\n");
    while ((s = stdInput.readLine()) != null) {
        System.out.println(s);
    }

    // read any errors from the attempted command
    System.out.println("Here is the standard error of the command (if any):\n");
    while ((s = stdError.readLine()) != null) {
        System.out.println(s);
    }

    System.exit(0);
}
catch (IOException e) {
    System.out.println("exception happened - here's what I know: ");
    e.printStackTrace();
    System.exit(-1);
}

```
只不过很少见过用java去调用系统接口的
