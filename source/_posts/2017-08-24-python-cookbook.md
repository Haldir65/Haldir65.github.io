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


dict的创建方法[参考](https://www.linuxzen.com/python-you-ya-de-cao-zuo-zi-dian.html)
```python
>>> info = {"name" : 'cold'}
>>> info = dict(name = 'cold')       # 更优雅,注意这里的key不需要带双引号了
```

操作数据库的话，在python文件里面写sql语句也行。sqlite3还是官方自带包，mysql要装个包。但是实际开发中应该大多数都使用orm框架，很少会自己去写sql语句吧.

orm(object relation mapping)框架： sqlalchemy
> pip install sqlalchemy

[python cheetsheet](https://www.pythonsheets.com/notes/python-sqlalchemy.html)




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

## 3. Error Handling
try except是可以拿到exception的原因的
```python
try:
    1 + '1'
    f = open('该文档不存在')
    print(f.read())
    f.close()
except OSError as reason:
    print('文件出错了T_T')
    print('出错原因是%s'%str(reason))
except TypeError as reason:
    print('求和出错了T_T')
    print('出错原因是%s'%str(reason))
```

![](http://odzl05jxx.bkt.clouddn.com/79a65f1911c81d736be0704904de8ea1.jpg?imageView2/2/w/600)


时间的函数有datetime和time包
datetime在windows上和在mac上有表现不一致的现象[python-time-formatting-different-in-windows](https://stackoverflow.com/questions/10807164/python-time-formatting-different-in-windows)
亲测下来,
```python
import datetime
dt = datetime.datetime.now()
expire_time = dt.strftime('%s') ## 亲测，mac上没问题,windows上会崩,把s改成S就不会在windows上崩了。
## 后来干脆改成这样
expire = int(round(dt.timestamp()))
```

时间相关的操作在这里：
```python
import datetime

datetime.now().strftime("%Y年-%m月-%d日 %H %m %S")
## '2018年-07月-03日 11 07 34'

### 明天
tomorrow = datetime.date.today() + datetime.timedelta(days=1) ## 要是传个-1就是昨天了
## 这个获取的是一个datetime.date对象

## 来看看这个datatime.date对象能干嘛吧
tomorrow.year
##2018
tomorrow.day
#4
tomorrow.ctime()
## 'Wed Jul  4 00:00:00 2018'
>>> tomorrow.isoformat()
'2018-07-04'

如何创建一个datetime.date对象：
>>> someday = datetime.datetime(2015,7,23,0,0)
>>> someday
datetime.datetime(2015, 7, 23, 0, 0)
>>> someday.day
23
>>> someday.month
7
>>> someday.year
2015

今天是周几啊
>>> someday.isoweekday()
4 ##周四，看了下日历，确实是周四


someday = datetime.datetime.strptime("2015-10-1 18:20:31","%Y-%m-%d %H:%M:%S")
>>> someday
datetime.datetime(2015, 10, 1, 18, 20, 31)

##timetuple的概念
>>> someday.timetuple()
time.struct_time(tm_year=2015, tm_mon=10, tm_mday=1, tm_hour=18, tm_min=20, tm_sec=31, tm_wday=3, tm_yday=274, tm_isdst=-1)
## 这个struct也是能用的
>>> someday.timetuple().tm_year
2015


## 纯粹想要获得时间戳可以用这个
import time
>>> time.time()
1530587669.796551 ##注意这个获得的是秒为单位的

##这种方式也能获得时间戳
>>> timestamp = time.mktime(datetime.datetime.now().timetuple())
>>> timestamp
1530588755.0

##有了时间戳想要转回object:
>>>time.gmtime(timestamp)
time.struct_time(tm_year=2018, tm_mon=7, tm_mday=3, tm_hour=3, tm_min=32, tm_sec=55, tm_wday=1, tm_yday=184, tm_isdst=0)

##fromtimestamp也行
>>> datetime.datetime.fromtimestamp(time.time())
datetime.datetime(2018, 7, 3, 11, 36, 53, 58164)

## 然而datetime包下面还有一个
>>> datetime.time
<class 'datetime.time'>
```


自带的Log使用
```python
import logging

logging.warning('this is awesome')
```

[下划线的意义很多种](https://dbader.org/blog/meaning-of-underscores-in-python)
这其中就包含了magic_method，直接看吧
```python
    ## 一般__init__是写一个class时经常用到的方法，但其实还有一个__new__的方法
    ## 当调用x = SomeClass()的时候，__init__并不是第一个被调用的方法，实际上还有一个
    ## __new__方法，__new__方法是用来创建类病返回这个类的实例，而__init__只是拿着传入的参数来初始化这个实例 http://python.jobbole.com/88367/
    ##在对象生命周期调用结束时，__del__ 方法会被调用，可以在这里释放资源
  class MyDict(object):
    def __init__(self):
        print'call fun __init__'
        self.item = {}

    def __getitem__(self,key):
        print'call fun __getItem__'
        return self.item.get(key)

    def __setitem__(self,key,value):

        print'call fun __setItem__'

        self.item[key] =value

    def __delitem__(self,key):
        print'cal fun __delitem__'
        del self.item[key]

    def __len__(self):
        returnlen(self.item)
```
上面这些主要是创建类似于dict或者映射的类，可以像操作字典一样进行使用
```python
myDict = MyDict()
myDict[2] = 'ch' ##会调用到__setitem__方法
del myDict[2] ##会调用到__delitem方法，其实也等于对外提供了一个钩子

__getattr__(self, name)：
    ## python不支持私有变量，但其实可以在这里去拦截
    ## 定义当用户试图获取一个不存在的属性时的行为。这适用于对普通拼写错误的获取和重定向，对获取一些不建议的属性时候给出警告(如果你愿意你也可以计算并且给出一个值)或者处理一个 AttributeError 。只有当调用不存在的属性的时候会被返回。
    pass

##__getattribute__定义了你的属性被访问时的行为，相比较，__getattr__只有该属性不存在时才会起作用。因此，在支持__getattribute__的Python版本,调用__getattr__前必定会调用 __getattribute__。__getattribute__同样要避免”无限递归”的错误。需要提醒的是，最好不要尝试去实现__getattribute__,因为很少见到这种做法，而且很容易出bug。

#  错误用法，因为会导致无限递归
def __setattr__(self, name, value):
    self.name = value
    # 每当属性被赋值的时候(如self.name = value)， ``__setattr__()`` 会被调用，这样就造成了递归调用。
    # 这意味这会调用 ``self.__setattr__('name', value)`` ，每次方法会调用自己。这样会造成程序崩溃。
 
#  正确用法
def __setattr__(self, name, value):
    self.__dict__[name] = value  # 给类中的属性名分配值
    ## __dict__是 A dictionary or other mapping object used to store an object’s (writable) attributes.
    # 定制特有属性    
```

关于__dict__：
```python
def func():
    pass
func.temp = 1 ## in python , everything is an object,everything !

print func.__dict__

class TempClass(object):
    a = 1
    def tempFunction(self):
        pass

print TempClass.__dict__
```
>{'temp': 1}
>{'a': 1, '__module__': '__main__', 'tempFunction': <function tempFunction at 0x7f77951a95f0>, '__dict__': <attribute '__dict__' of 'TempClass' objects>, '__weakref__': <attribute '__weakref__' of 'TempClass' objects>, '__doc__': None}

[底层应该是和descriptor相关](http://hbprotoss.github.io/posts/python-descriptor.html)
[以及__dict__.__dict__](https://stackoverflow.com/questions/4877290/what-is-the-dict-dict-attribute-of-a-python-class)
还有__slots__

一些比较常见的magic method:
```python

def __init__(self):
    pass

def __del__(self):
    pass
 
def __call__(self,*args):## 实现了这个方法，外部调用callable(instance)就返回True，表示这个instance是可以instance()这么用的
    pass
```
[关于magic method的详解比较好的文章](http://python.jobbole.com/88367/)

### python descriptor
就是在存取变量的时候做一个hook
```python
class RevealAccess(object):
    def __init__(self, initval=None, name='var'):
        self.val = initval
        self.name = name

    def __get__(self, obj, objtype):
        print 'Retrieving', self.name
        return self.val

    def __set__(self, obj, val):
        print 'Updating' , self.name
        self.val = val
```

>>> class MyClass(object):
    x = RevealAccess(10, 'var "x"')
    y = 5

>>> m = MyClass() ##个人感觉这个descriptor是把原始的value包装了一层，在get和set的时候去拦截一下
## 这么说吧，就是调用到descriptorinstance的时候，会走到这个class的__get__方法
>>> m.x
Retrieving var "x"
10
>>> m.x = 20
Updating var "x"
>>> m.x
Retrieving var "x"
20
>>> m.y
5

这个RevealAccess的对象就是一个descriptor，其作用就是在存取变量的时候做了一个hook。访问属性m.x就是调用__get__方法，设置属性值就是调用__set__方法。还可以有一个__delete__方法，在del m.x时被调用。

只要一个类定义了以上三种方法，其对象就是一个descriptor。我们把同时定义__get__和__set__方法的descriptor叫做data descriptor，把只定义__get__方法的叫non-data descriptor

一些比较实用的魔术方法
比方说：
```
infos = [1,2,3]
info2 = [1,2,3]

## 这俩其实干了同一件事
>>> infos<=info2
True
>>> infos.__le__(info2)
True

## 第一个其实调用了第二个
len(infos)
3
>>> infos.__len__()
3

## 这就很广泛了
>>> site = 'http://www.outofmemory.cn/'
>>> "www" in site
True
>>> site.find("www")
7
##现在觉得还去写str.__contains__("something")确实啰嗦了
```

hasattr和getattr方法
```python
class Example():
    def __init__(self):
        self.name = "example stuff"
    def prints(self,*args,**kwargs):
        print('stuffs')    

def main():
    pass
    ex = Example()
    name_exists = hasattr(ex,"name")
    print(" Example has attribute %s" % hasattr(ex,"name")) ## True
    print("Example has function %s" % hasattr(ex,"prints")) ## True
    f = getattr(ex,"prints")
    f()
    fakeattr = getattr(ex,"no_existing_attr",None) ## 还可以设置一个找不到的时候的默认值
```


```python
class Post(db.Model):
    title = db.Column(db.String(80), nullable=False)
 def __repr__(self):
        return '<Post %r>' % self.title
```

__repr__()就是在print的时候打印出的内容，和django里面model的__str__方法差不多


isinstance和type的区别,isinstance要好一点
```python
class A:
    pass

class B(A):
    pass

isinstance(A(), A)  # returns True
type(A()) == A      # returns True
isinstance(B(), A)    # returns True
type(B()) == A        # returns False ，type判断不了一个子类是不是其父类
```

isinstance(instance,类型)，这第二个参数可选值包括str,int,long,float,list,tuple,dict
```
>>>a = 2
>>> isinstance (a,int)
True
>>> isinstance (a,str)
False
>>> isinstance (a,(str,int,list))    # 是元组中的一个返回 True
True

>>> num = 3
>>> num.__class__.__name__
'int' ##isinstance这后面的第二个参数就是这么来的
```

try except是可以catch住import error的
```python
try:
    from _foo import *
except ImportError:
    raise ImportError('<any message you want here>')
```

很多开源库都提供了setup.py的安装方式：
```git
$ git clone https://github.com/user/foo  
$ cd foo
$ python setup.py install
```

> pip freeze | xargs pip uninstall -y ## 在venv下，删除所有安装的pip包


[如何制作setup.py](https://stackoverflow.com/questions/1471994/what-is-setup-py)