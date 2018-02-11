---
title: Python localHost部署命令
date: 2017-05-01 08:57:27
categories: blog
tags: [python]
---

一行命令即可
>  python -m http.server 8000 --bind 127.0.0.1

打开浏览器，输入127.0.0.1 ， 即可浏览当前目录下的文件，以GET的方式进行，命令行窗口会出现浏览记录。
![](http://odzl05jxx.bkt.clouddn.com/ChMkJ1fAMmKIIFpWAA_5Us41gQkAAUv1QE2Pp8AD_lq599.jpg?imageView2/2/w/600)
<!--more-->

据说SimpleHttpServer也可以，
```python
#!/usr/bin/python
# -*- coding: UTF-8 -*-
import sys
from http.server import SimpleHTTPRequestHandler
from http.server import BaseHTTPRequestHandler, HTTPServer


def test(HandlerClass=SimpleHTTPRequestHandler,
         ServerClass=HTTPServer):
    protocol = "HTTP/1.0"
    host = ''
    port = 8000
    if len(sys.argv) > 1:
        arg = sys.argv[1]
        if ':' in arg:
            host, port = arg.split(':')
            port = int(port)
        else:
            try:
                port = int(sys.argv[1])
            except:
                host = sys.argv[1]

    server_address = (host, port)

    HandlerClass.protocol_version = protocol
    httpd = ServerClass(server_address, HandlerClass)

    sa = httpd.socket.getsockname()
    print("Serving HTTP on", sa[0], "port", sa[1], "...")
    httpd.serve_forever()


if __name__ == "__main__":
    test()
```


### 2 .sys.args[]的使用
cmd中
> python

Python 3.6.1 (v3.6.1:69c0db5, Mar 21 2017, 17:54:52) [MSC v.1900 32 bit (Intel)] on win32
Type "help", "copyright", "credits" or "license" for more information.

退出方式 ctrl+Z

切换到脚本所在目录 ,例如test.py

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys

# sys.argv接收参数，第一个参数是文件名，第二个参数开始是用户输入的参数，以空格隔开
# cmd到该文件位置

def run1():
    print('I\'m action1')


def run2():
    print('I\'m action2')


if 2 > len(sys.argv):
    print('none')
else:
    action1 = sys.argv[0]
    action2 = sys.argv[1]
    <!-- if 'run1' == action1:
        run1()
    if 'run2' == action2:
        run2() -->

    print(action1)
    print(action2)    

```

输入 python test.py run1
输出 test.py 'run1'
