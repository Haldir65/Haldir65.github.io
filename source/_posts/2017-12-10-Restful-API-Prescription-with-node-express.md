---
title: 使用Node和express开发Restful API
date: 2017-12-10 16:20:16
tags: [前端]
---

![](http://odzl05jxx.bkt.clouddn.com/image/jpg/sceneryc7fd99f667c9d98a583a174872d58d13.jpg?imageView2/2/w/600)
<!--more-->


## 1. 安装




## 2. 配置

MiddleWare(中间件)的概念：
从Request到response之间的流程中，任何组件都可以对这个过程中的数据进行修改，所以router其实也是中间件。中间件需要注意的就是***顺序很重要***。



[Nginx 是前端工程师的好帮手](http://www.restran.net/2015/08/19/nginx-frontend-helper/)


[Express Api book](http://expressjs.jser.us/api#req.param)

[在NodeJs中玩转protoBuffer](http://imweb.io/topic/570130a306f2400432c1396c)

[使用nodejs 和express搭建本地API服务器](http://blog.desmondyao.com/fake-server/)


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


## 3. Serving static files
```javaScript
app.use(express.static(path.join(__dirname,'public')))
```
然后在当前目录新建一个public文件夹，添加img文件夹，里面放一张porn.jpg。
浏览器访问： localhost:port/img/porn.jpg 。 就能看到放进去的的那张图片了。
