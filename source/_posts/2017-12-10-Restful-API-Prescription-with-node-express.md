---
title: 2017-12-10-Restful-API-Prescription-with-node-express
date: 2017-12-10 16:20:16
tags:
---



[使用nodejs 和express搭建本地API服务器](http://blog.desmondyao.com/fake-server/)
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/sceneryc7fd99f667c9d98a583a174872d58d13.jpg?imageView2/2/w/600)
<!--more-->
[Nginx 是前端工程师的好帮手](http://www.restran.net/2015/08/19/nginx-frontend-helper/)


[Express Api book](http://expressjs.jser.us/api#req.param)

调试使用postMan

### Request

在postMan发起post请求
```
POST /api/personal?age=10 HTTP/1.1
Host: localhost:8080
Content-Type: application/x-www-form-urlencoded
Cache-Control: no-cache
Postman-Token: 79c6d9a1-de8d-3b0b-8d3d-0ed6e1910f69

name=Josn&age=12
```


```js
req.params   //  Object ，Json.String = {}
req.body    //  {name:'Josn',age:'12'}  //这个是post里面发送的body数据
req.query  // {"age","10"}  // 显然这是url里面的query
```
