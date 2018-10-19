---
title: Python localHost部署命令
date: 2017-05-01 08:57:27
categories: blog
tags: [python]
---

一行命令即可
>  python -m http.server 8000 --bind 127.0.0.1

打开浏览器，输入127.0.0.1 ， 即可浏览当前目录下的文件，以GET的方式进行，命令行窗口会出现浏览记录。
![](https://www.haldir66.ga/static/imgs/ChMkJ1fAMmKIIFpWAA_5Us41gQkAAUv1QE2Pp8AD_lq599.jpg)
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





### Documenting your api like a boss

> pip install flasgger
[使用swaggi这个库，写一个yml文件就能自动生成api文档了](http://brunorocha.org/python/flask/flasgger-api-playground-with-flask-and-swagger-ui.html) swagger似乎并不只限于python，也有用于SpringBoot中的java package.yml文件怎么写参考[这个库](https://github.com/rochacbruno/flasgger)的doc
swagger ui和OpenAPI Specification有关，大概是用于制作api doc的一套标准[swagger-ui](https://github.com/swagger-api/swagger-ui)
[flask apispec](https://github.com/jmcarp/flask-apispec)
[flask-rest-plus documenting with swagger](http://michal.karzynski.pl/blog/2016/06/19/building-beautiful-restful-apis-using-flask-swagger-ui-flask-restplus/)

[flask realworld app](https://github.com/gothinkster/flask-realworld-example-app)
中需要修改的几点：

requirements/prod.txt
```
-flask_apispec==0.3.2
+flask_apispec==0.7.0
```
接下来就是这几条命令
>flask db migrate 
flask db upgrade    
flask run --with-threads

windows下也能跑起来
需要pip install pymysql


curl其实也能实现和postman一样的效果
```
curl -X POST -d '{"email":"user3@gmail.com","username":"user3","password":"useronepwd"}' --header "Content-Type:application/json" "http://127.0.0.1:3333/login"

curl -X GET -d  --header "Content-Type:application/json" --header "Authorization:JWT eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE1MzEzMDMxMTQsImlhdCI6MTUzMTMwMzA4NCwiaXNzIjoia2VuIiwiZGF0YSI6eyJpZCI6MiwibG9naW5fdGltZSI6MTUzMTMwMzA4NH19.04xDT6H2qoKzXpMZygFDIf8kpo4ksEl8J_mzvotgOoA" "http://127.0.0.1:3333/user"
```
当然实际开发中还是图形化界面最方便


flask设置status code似乎只需要在return后面加上一个200这样的code就可以了

[How Do Python Coroutines Work?](https://www.youtube.com/watch?v=7sCu4gEjH5I)
[关于python的socket api，这里有一篇介绍](https://realpython.com/python-sockets/)