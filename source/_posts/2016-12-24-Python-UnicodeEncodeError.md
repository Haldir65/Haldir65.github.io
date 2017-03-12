---
title: Python 3 学习记录
date: 2016-12-24 22:06:37
tags: Python
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


### 4. Dic、List、Tuple、set以及基本的数据类型




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


