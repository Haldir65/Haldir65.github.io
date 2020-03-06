---
title: Python中的集合类
date: 2019-07-26 22:21:38
tags: [python]
---


很多高级语言都有成熟的集合类，比如Java有很优秀的集合（自动扩容，快速失败，并发集合类），Python也不例外。
![](https://api1.foster66.xyz/static/imgs/WorldWaterDay_EN-AU11747740536_1920x1080.jpg)
<!--more-->

## 1. namedtuple()
```python
plain_tuple = (10,11,12,13)
plain_tuple[0]
##10
plain_tuple[3]
##13
```
普通的tuple只能根据下标来获取元素
namedtuple使得外部能够以自定义的key获取value
```python
from collections import namedtuple
fruit = namedtuple('fruit','number variety color')
guava = fruit(number=2,variety='HoneyCrisp',color='green')
apple = fruit(number=5,variety='Granny Smith',color='red')
##guava.color
##'green'
##apple.variety
##'Granny Smith'
```

## 2. Counter
Counter是dict的子类
```python
from collections import Counter
c = Counter('abcacdabcacd')
print(c)
## Counter({'a': 4, 'c': 4, 'b': 2, 'd': 2}) 其实就是计算每一个字母出现了几次

lst = [5,6,7,1,3,9,9,1,2,5,5,7,7]
c = Counter(lst)
print(c)
## Counter({5: 3, 7: 3, 1: 2, 9: 2, 6: 1, 3: 1, 2: 1})

s = 'the lazy dog jumped over another lazy dog'
words = s.split()
print(Counter(words).most_common(3))
##[('lazy', 2), ('dog', 2), ('the', 1)] most_common是counter的一个方法，给出前n个出现次数最多的
```

## 3. defaultdict

```python
d = {}
print(d['A']) ##   print(d['A']) KeyError: 'A'   

from collections import defaultdict
s = [('yellow', 1), ('blue', 2), ('yellow', 3), ('blue', 4), ('red', 1)]
d = defaultdict(list) ## 将一个list转成dict的方式
for k, v in s:
    d[k].append(v)
sorted(d.items())
```

## 4.OrderedDict
OrderedDict是dictionary的子类，迭代顺序与初始insert顺序保持一致。关于python的dictionary，2.x的时候是有序的，3.0-3.5的时候是无序的，3.6开始又变得有序了。[Modern Dictionaries by Raymond Hettinger](https://www.youtube.com/watch?v=p33CVV29OG8)

```python
d = {'banana': 3, 'apple': 4, 'pear': 1, 'orange': 2}
for k,v in d.items():
    print("key = {0}, value = {1}".format(k,v))
##key = banana, value = 3
# key = apple, value = 4
# key = pear, value = 1
# key = orange, value = 2    
d = OrderedDict(sorted(d.items(), key=lambda t: t[0]))
for k,v in d.items():
    print("key = {0}, value = {1}".format(k,v))  
# key = apple, value = 4
# key = banana, value = 3
# key = orange, value = 2
# key = pear, value = 1
```


[python3.6开始dictionary是有序的](https://stackoverflow.com/questions/327311/how-are-pythons-built-in-dictionaries-implemented) 以及其实现细节（主要是为了节省内存）


## 参考
[python collections](https://towardsdatascience.com/pythons-collections-module-high-performance-container-data-types-cb4187afb5fc)
[official docs for python builtin collections](https://docs.python.org/zh-cn/3/library/collections.html)


[official docs](https://docs.python.org/zh-cn/3/library/collections.html)