---
title: 使用Node和express开发Restful API
date: 2017-12-10 16:20:16
tags: [前端]
---

![](http://odzl05jxx.bkt.clouddn.com/image/jpg/sceneryc7fd99f667c9d98a583a174872d58d13.jpg?imageView2/2/w/600)
<!--more-->


## 1. 安装
> yarn add express body-parser

mongoose安装




## 2. 配置

MiddleWare(中间件)的概念：
从Request到response之间的流程中，任何组件都可以对这个过程中的数据进行修改，所以router其实也是中间件。中间件需要注意的就是***顺序很重要***。


调试使用postMan

### Request

get请求的参数怎么拿，get的参数本身都是写在url里面的

比如
> GET /student/getById/27 这样一个get请求

```js
app.get('/getById/:age',functin(req,res){
    res.send(req.prarms.age);
})
```

在postMan发起post请求
```
POST /api/personal?age=10 HTTP/1.1
Host: localhost:8080
Content-Type: application/x-www-form-urlencoded
Cache-Control: no-cache
Postman-Token: 79c6d9a1-de8d-3b0b-8d3d-0ed6e1910f69

name=Josn&age=12
```

POST请求中的body数据从req.body中拿就好了
```js
req.params   //  Object ，Json.String = {}
req.body    //  {name:'Josn',age:'12'}  //这个是post里面发送的body数据
req.query  // {"age","10"}  // 显然这是url里面的query
```


## 3. Serving static files
照说serving static file这种事应该交给nginx类似的反向代理来做，express只是提供了一种选择。
```javaScript
app.use(express.static(path.join(__dirname,'public')))
```
然后在当前目录新建一个public文件夹，添加img文件夹，里面放一张porn.jpg。
浏览器访问： localhost:port/img/porn.jpg 。 就能看到放进去的的那张图片了。

```js
app.use('/jquery', express.static(__dirname + '/node_modules/jquery/dist/'));
```
这意思就是请求/jquery这个目录下的资源就等于访问/node_modules/jquery/dist/目录下同名的资源

## 4. response
response.redirect('/all'); //在浏览器里面看，response的header是这样的

>HTTP/1.1 302 Found
X-Powered-By: Express
Location: /all
Vary: Accept
Content-Type: text/html; charset=utf-8
Content-Length: 68
Date: Sun, 14 Jan 2018 10:08:50 GMT
Connection: keep-alive


>response.direction();
和window.location.href差不多


```js
/* GET  /api/user */ much extra information you can set on its header
app.get("/user",function (req,res) {
    res.set({
        'Content-Type': 'application/json',
        'Content-Length': '123',
        'ETag': '12345',
        'Cache-Control': 'max-age=5',
        "Access-Control-Allow-Origin": 'http://127.0.0.1:8080'
    });
    res.cookie('name', 'tobi', { domain: '.example.com', path: '/admin', secure: true });
    console.log('response send');
    res.json({
        "name":"John",
        "age":10
    });
});
```



简单的session处理:
> yarn add express cookie-parser express-session
```js
router.get("/", function(req, res, next) {
  if (req.session.user) {
    var user = req.session.user;
    var name = user.name;
    res.send("你好" + name + "，欢迎来到我的家园。");
  } else {
    let user = {
      name: "Chen-xy",
      age: "22",
      address: "bj"
    };
    req.session.user = user;
    res.send("你还没有登录，先登录下再试试！");
  }

  // res.render("index", {
  //   title: "the test for nodejs session",
  //   name: "sessiontest"
  // });
});
```



======================================================
how about error handling

```js
app.get("/user",function (req,res,next) {

};
```

另一种选择，graphQl是和restful功能类似的模式


在linux server上使用pm2 deploy node project
> 1.  nohup node /home/zhoujie/ops/app.js & ## nohup就是不挂起的意思( no hang up)。 ignoring input and appending output to nohup.out // 输出被写入当前目录下的nohup.out文件中
> 2. screen ## 新开一个screen
> 3. pm2
npm install -g pm2
pm2 start app.js

[Configure Nginx as a web server and reverse proxy for Nodejs application on AWS Ubuntu 16.04 server](https://medium.com/@utkarsh_verma/configure-nginx-as-a-web-server-and-reverse-proxy-for-nodejs-application-on-aws-ubuntu-16-04-server-872922e21d38)





## 参考

[Nginx 是前端工程师的好帮手](http://www.restran.net/2015/08/19/nginx-frontend-helper/)


[Express Api book](http://expressjs.jser.us/api#req.param)

[在NodeJs中玩转protoBuffer](http://imweb.io/topic/570130a306f2400432c1396c)

[使用nodejs 和express搭建本地API服务器](http://blog.desmondyao.com/fake-server/)
