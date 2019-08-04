---
title: 各种编程语言与c、c++的交互
date: 2019-07-31 22:11:55
tags:
---

![](https://www.haldir66.ga/static/imgs/SutherlandFalls_ZH-CN4602884079_1920x1080.jpg)
<!--more-->

## 1. cpython
### 1.1 pythont调用C、C++代码

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
好像是process module

cython(python c extension)和cpython(c语言实现的python）是两件事

## 2. javascript
### 2.1 javascript调用C、C++代码

### 2.2 C、C++调用javascript代码

### 2.3 javascript调用系统方法



## 3. java
### 3.1 java调用C、C++代码
就是jni了

### 3.2 C、C++调用java代码

### 3.3 java调用系统方法
