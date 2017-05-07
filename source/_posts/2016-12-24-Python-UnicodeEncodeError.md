---
title: Python 3 学习记录
date: 2016-12-24 22:06:37
categories: blog 
tags: [python]
---


#### 人生苦短，Python是岸

![implementing dumb features](http://odzl05jxx.bkt.clouddn.com/implementingdumbfeatures-big.png?imageView2/2/w/500)


<!-- more -->


### 1. Python的一些缺点
引用[廖雪峰的官方网站](http://www.liaoxuefeng.com/)上的话，Python一个是慢，一个是代码不能加密

> 第一个缺点就是运行速度慢，和C程序相比非常慢，因为Python是解释型语言，你的代码在执行时会一行一行地翻译成CPU能理解的机器码，这个翻译过程非常耗时，所以很慢。而C程序是运行前直接编译成CPU能执行的机器码，所以非常快。


> 第二个缺点就是代码不能加密

> GIL导致的多线程低效率

以下内容出自[静觅 » Python爬虫进阶五之多线程的用法](http://cuiqingcai.com/3325.html)
```text
1、GIL是什么？

GIL的全称是Global Interpreter Lock(全局解释器锁)，来源是python设计之初的考虑，为了数据安全所做的决定。

2、每个CPU在同一时间只能执行一个线程（在单核CPU下的多线程其实都只是并发，不是并行，并发和并行从宏观上来讲都是同时处理多路请求的概念。但并发和并行又有区别，并行是指两个或者多个事件在同一时刻发生；而并发是指两个或多个事件在同一时间间隔内发生。）

在Python多线程下，每个线程的执行方式：

获取GIL
执行代码直到sleep或者是python虚拟机将其挂起。
释放GIL
可见，某个线程想要执行，必须先拿到GIL，我们可以把GIL看作是“通行证”，并且在一个python进程中，GIL只有一个。拿不到通行证的线程，就不允许进入CPU执行。

在Python2.x里，GIL的释放逻辑是当前线程遇见IO操作或者ticks计数达到100（ticks可以看作是Python自身的一个计数器，专门做用于GIL，每次释放后归零，这个计数可以通过 sys.setcheckinterval 来调整），进行释放。

而每次释放GIL锁，线程进行锁竞争、切换线程，会消耗资源。并且由于GIL锁存在，python里一个进程永远只能同时执行一个线程(拿到GIL的线程才能执行)，这就是为什么在多核CPU上，python的多线程效率并不高。
```

### 2. 安装package各种can't resolve XXX
[no module named urllib2](http://stackoverflow.com/questions/2792650/python3-error-import-error-no-module-name-urllib2)

> The urllib2 module has been split across several modules in Python 3 named urllib.request and urllib.error. The 2to3 tool will automatically adapt imports when converting your sources to Python 3.

This is what look like on py 2.7

```python
import urllib2
req = urllib2.Request(url,headers=header)
html = urllib2.urlopen(req)
html_data = html.read
html_path = etree.HTML(html_data)	
```   

on Python 3.X 
```python
from urllib.request import urlopen
from urllib.request import Request

req = Request(img_url, headers=headers)
urlhtml = urlopen(req)
```


### 3. pip install XXXX 
安装package的方式 pip install xxxx....
#### if not working
![](http://odzl05jxx.bkt.clouddn.com/Googling%20the%20Error%20Message.jpg?imageView2/2/w/500)


### 4. List、tuple、dict、set以及基本的数据类型

```python
 list   mylist = ['Tom','Jerry','Henry']
        mylist[0] = 'Tom'

 tuple  mytuple = ('rock','pop','jazz')
         mytuple[0] = 'rock' 

 tuple在初始化时就已经确定，不能修改

 dict: d={'name':'tom','job':'doctor','age',99}
        d['name'] = 'tom'

 set:  s = set([1,2,3]) # 需要传入一个list作为参数
    >> s
    {1,2,3}
    set无序，不可有重复元素
    set和dict的区别在于前者没有存储value，两者内部都不能有重复元素(key)
```
tuple用的比较多，例如有多个返回值的函数，Python其实返回了一个Tuple。

#### 类名应该写成驼峰样式，变量名应该小写
class name should be cammelCase, Arguments,variable name should be lowercase

循环
```python
 for i in range(2, 5):
        print(i)
>>> result: 2 3 4 左闭右开

条件判断

def add_end(L=None):
    if L is None:
        L = []
    L.append('END')
    return L
```

##### 函数参数相关，函数组合（一共五种）
位置参数，默认参数，可变参数，关键字参数，命名关键字参数

定义一个函数可以带上默认值，默认值是一个固定的对象，上次操作的值会保留到下一次调用
```python
def sell(name,price,amount=1):
    print(price*amount)

sell('product',26)
sell('product',26,2)

>>> 26    
>>> 52    
```

默认参数函数
```python
def power(x, n=2): #这里的n=2就是默认参数，注意，默认参数应该是不可变对象,例如str、None这种
    s = 1
    while n > 0:
        n = n - 1
        s = s * x
    return s

power(5) >> 25
power(5,2) >>>25    
```

可变参数函数# 定义的时候在参数前面加一个*号就可以了，内部会默认组装成一个tuple
```python
def calc(*numbers): #函数内部接收到的是一个tuple
    sum = 0
    for n in numbers:
        sum = sum + n * n
    return sum

calc(1,2)

calc(2,3,5)    

nums = [1,2,3]
cal(*nums)#把tuple内的元素作为参数传进去
```
关键字参数
```python
def person(name, age, **kw):
    print('name:', name, 'age:', age, 'other:', kw)

>>> person('Michael', 30)
name: Michael age: 30 other: {}

内部自动将关键字参数转换成一个dict    
```
命名关键字函数
```python
def shoppping(name,time,*,price,count)# price可以有默认值
    print(price*count)

>> shopping(john,0325,price=39,count=5)
>> 195
```






### 5. 爬虫相关
Chrome自带开发者工具，可以查看每一个request的header，cookies等信息。模拟浏览器行为比较有效。



todo 

<!-- install mongoDb(better performance than sql) -->
<!-- install pip -->
grep log in command console
basic grammars
network, disk ,database, io , dic, list ,etc
class object orientated  



### Reference
- [廖雪峰的官方网站](http://www.liaoxuefeng.com/)
- [use python and mongoDb as backend](https://zhuanlan.zhihu.com/p/20488077?columnSlug=kotandroid)
- [静觅](http://cuiqingcai.com/category/technique/python) 

