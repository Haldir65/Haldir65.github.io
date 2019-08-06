---
title: 各种编程语言与c、c++的交互
date: 2019-07-31 22:11:55
tags:
---

![](https://www.haldir66.ga/static/imgs/SutherlandFalls_ZH-CN4602884079_1920x1080.jpg)
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
首先，在浏览器中运行c语言的代码，似乎可以将C编成webassembly在浏览器中运行。
而在Node js中，可以使用[n-api](https://nodejs.org/api/n-api.html)这个module。
> N-API (pronounced N as in the letter, followed by API) is an API for building native Addons. It is independent from the underlying JavaScript runtime (for example, V8) and is maintained as part of Node.js itself. This API will be Application Binary Interface (ABI) stable across versions of Node.js. It is intended to insulate Addons from changes in the underlying JavaScript engine and allow modules compiled for one major version to run on later major versions of Node.js without recompilation. 

就是说保持了binary compatibility，比如说在node6上编译通过之后，假如后面出了node10，不需要重新编译也能继续运行。

下面看如何使用:
[how-to-call-c-c-code-from-node-js](https://medium.com/@tarkus/how-to-call-c-c-code-from-node-js-86a773033892)
很多大型js项目都有一个binging.gyp文件（一定是这个名字）

gyp其实是一个用来生成项目文件的工具，一开始是设计给chromium项目使用的，后来大家发现比较好用就用到了其他地方。生成项目文件后就可以调用GCC, vsbuild, xcode等编译平台来编译。至于为什么要有node-gyp，是由于node程序中需要调用一些其他语言编写的工具甚至是dll，需要先编译一下，否则就会有跨平台的问题，例如在windows上运行的软件copy到mac上就不能用了，但是如果源码支持，编译一下，在mac上还是可以用的。


### 2.2 C、C++调用javascript代码

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
### 3.1 java调用C、C++代码
就是jni了

### 3.2 C、C++调用java代码
c、c++层调用java也是可以的

### 3.3 java调用系统方法
java有一个Process api
### 38. java中Process的Api
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