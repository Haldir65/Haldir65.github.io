---
title: Python localHost部署命令
date: 2017-05-01 08:57:27
tags:
---

一行命令即可
>  python -m http.server 8000 --bind 127.0.0.1 

打开浏览器，输入127.0.0.1 ， 即可浏览当前目录下的文件，以GET的方式进行，命令行窗口会出现浏览记录。
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
