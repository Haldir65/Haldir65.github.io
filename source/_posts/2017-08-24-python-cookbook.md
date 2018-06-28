---
title: Python工具手册
date: 2017-08-24 22:25:18
tags: [python,tools]
---

## 苦海无涯，Python是岸

![](http://odzl05jxx.bkt.clouddn.com/image/jpg/essay-with-programming-lang.jpg)


<!--more-->

## 1. 基本数据操作，及语法

- 函数参数[默认参数、可变参数、关键字参数等](https://www.liaoxuefeng.com/wiki/0014316089557264a6b348958f449949df42a6d3a2e542c000/001431752945034eb82ac80a3e64b9bb4929b16eeed1eb9000)
- 集合类型(list是中括号，tuple是小括号)
- unicodeError
- 面向对象
- 多线程，多进程
多线程基本无用，基本语法很简单：
```python
import threading

def readIo()
    print('do stuff heavy')

for i in range(10):
    threading.Thread(target=readIo).start()
print('Finishing up')        
```

## 2. Flask相关
### 2.1 Flask Admin Pannel[Flask-Admin中文入门教程](http://flask123.sinaapp.com/article/57/)Please  run on linux

### 2.2.log上颜色
[博客](https://blog.phpgao.com/python_colorful_log.html)，Pycharm的console无效，内置Terminal有效

### 2.7 [小Web](http://www.jianshu.com/p/f9d668490bc6)





### 2.3 Pycharm里面import各种can't resolve 的解决方法
- from werkzeug import secure_filename
- from werkzeug.utils import secure_filename
只是因为这个文件的包的位置挪了，import只能用绝对路径

在class中调用parent class的方法
```py
class Grandparent(object):
    def my_method(self):
        print "Grandparent"

class Parent(Grandparent):
    def my_method(self):
        print "Parent"

class Child(Parent):
    def my_method(self):
        print "Hello Grandparent"
        super(Parent, self).my_method()
```

![](http://odzl05jxx.bkt.clouddn.com/79a65f1911c81d736be0704904de8ea1.jpg?imageView2/2/w/600)
