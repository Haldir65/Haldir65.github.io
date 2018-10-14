---
title: 从Socket入手写简单的httpServer
date: 2018-10-13 21:30:36
tags: [tools]
---

![](https://www.haldir66.ga/static/imgs/sun_rise_dim_grass.jpg)

收集几种语言中使用socket实现httpServer和httpClient的主要步骤
<!--more-->

## java
TBD


## Python
[我自己抄来的简易版](https://github.com/Haldir65/Jimmy/blob/rm/basics/simpleHttpServer/httpServer.py)
```python
## server 
import socket
import re
import os
import codecs,logging

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.bind((HOST, 18004))
sock.listen(100)


# infinite loop
while True:
    # maximum number of requests waiting
    conn, addr = sock.accept()
    request = conn.recv(1024)
    if isinstance(request,bytes):
        request = str(request)
        logging.error(request)

    splited = request.split(' ')    
    if(len(splited)<2):
        continue
    method = request.split(' ')[0]
    src = request.split(' ')[1]

    print('Connect by: ', addr)
    print('Request is:\n', request)

    # deal wiht GET method
    if method == 'GET' or method.__contains__('GET'):
        if src == '/index.html':
            content = index_content
        elif src == '/image/image_12.jpg':
            content = pic_content
        elif src == '/reg.html':
            content = reg_content
        elif re.match('^/\?.*$', src):
            entry = src.split('?')[1]  # main content of the request
            content = 'HTTP/1.x 200 ok\r\nContent-Type: text/html\r\n\r\n'
            content += entry
            content += '<br /><font color="green" size="7">register successs!</p>'
        else:
            continue

    # deal with POST method
    elif method == 'POST':
        form = request.split('\r\n')
        entry = form[-1]  # main content of the request
        content = 'HTTP/1.x 200 ok\r\nContent-Type: text/html\r\n\r\n'
        content += entry
        content += '<br /><font color="green" size="7">register successs!</p>'

    ######
    # More operations, such as put the form into database
    # ...
    ######

    else:
        continue
    if(type(content) is str):
        content = content.encode('utf-8')
    conn.sendall(content)
    # close connection
    conn.close()
```

本地浏览器访问localhost:10086应该就能看到结果了，值得一提的是自己在chrome里面访问"http://localhost:18004/index.html"这个地址的时候，事实上浏览器发送的数据是这样的
> b'GET /index.html HTTP/1.1\r\nHost: localhost:18004\r\nConnection: keep-alive\r\nCache-Control: max-age=0\r\nUpgrade-Insecure-Requests: 1\r\nUser-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Safari/537.36\r\nDNT: 1\r\nAccept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8\r\nAccept-Encoding: gzip, deflate, br\r\nAccept-Language: zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7\r\nCookie: _ga=GA1.1.dsadsa.dsadas; _gid=GA1.1.dsadsa.dsadasda\r\n\r\n'

对了，浏览器默认会请求favicon，所以在服务器这边看到了另一个请求
> b'GET /favicon.ico HTTP/1.1\r\nHost: localhost:18004\r\nConnection: keep-alive\r\nPragma: no-cache\r\nCache-Control: no-cache\r\nUser-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Safari/537.36\r\nDNT: 1\r\nAccept: image/webp,image/apng,image/*,*/*;q=0.8\r\nReferer: http://localhost:18004/index.html\r\nAccept-Encoding: gzip, deflate, br\r\nAccept-Language: zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7\r\nCookie: _ga=GA1.1.dsadsa.dsadas; _gid=GA1.1.dsadsa.dsadasda\r\n\r\n'


[高阶版](https://realpython.com/python-sockets/)



## C语言版本
C语言的应该最接近底层,C语言实现HTTP的GET和POST请求