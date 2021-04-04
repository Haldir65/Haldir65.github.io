---
title: 使用Node和express开发Restful API
date: 2017-12-10 16:20:16
tags: [前端]
---

![](https://api1.foster57.tk/static/imgs/sceneryc7fd99f667c9d98a583a174872d58d13.jpg)
<!--more-->

一个最简单的express app如下：
```js
var express = require('express');
var app = express();

app.get('/', function(req, res){
  res.send('hello world');
});

app.listen(3000);
```

## 1. 安装
> yarn add express body-parser



## 2. 配置
MiddleWare(中间件)的概念：
从Request到response之间的流程中，任何组件都可以对这个过程中的数据进行修改，所以router其实也是中间件。中间件需要注意的就是***顺序很重要***。

### 2.1 路由设置
```js
var router = express.Router([options]);//首先创建router对象，默认urlpath是大小写不敏感的
router.use("/api",function(req,res){
  return "hey there";
});

//所以这个router会默认处理所有/api开头的请求，但是在这个router内部还是分的清的
router.get("/",...)
router.get("/detail",...)


// 上面的例子，router会匹配上所有/api开头的url， app.use('/apple', ...) will match “/apple”, “/apple/images”, “/apple/images/news”, and so on.
app.use(function (req, res, next) { //path默认是'/'，所以下面这个router会匹配上所有的请求
  console.log('Time: %d', Date.now());
  next();
});


//明确区分get和post
router.get('/', function(req, res, next)) {

};
router.post('/',function(req,res,next)){

};

router.all() //这种是所有的HTTP METHOD都接受的
```




### 2.2 body-parser
一般这样使用就行了,[bodyParser只是指明了能够parse那些content-type的request body](http://expressjs.com/en/resources/middleware/body-parser.html)
```js
// parse application/x-www-form-urlencoded
app.use(bodyParser.urlencoded({ extended: false }))
// parse application/json
app.use(bodyParser.json())
```
添加了bodyParser之后就能获取客户端传来的数据了

- 获取GET请求的参数
比如 GET /student/getById/27 这样一个get请求

```js
app.get('/getById/:age',function(req,res){
    res.send(req.params.age);
})
```

- 获取POST请求的参数
在postMan发起post请求


```config
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

> 获取请求头
req.header(headerName)
console.log(JSON.stringify(req.headers));

## 2.3 处理response
可以设置header什么的
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

可以直接一个404打回去
res.sendStatus(404)

还可以重定向
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

在router中主要就是业务逻辑处理了，在所有的需要认证的接口前添加jwt鉴权处理，使用三个函数的方法，例如
```js
var jwt = require('express-jwt');

app.get('/protected',
  jwt({secret: 'shhhhhhared-secret'}),
  function(req, res) {
    if (!req.user.admin) return res.sendStatus(401);
    res.sendStatus(200);
  });
```

在业务处理中使用Promise
```js
router.get('/', auth.optional, function(req, res, next) {
  Promise.all([promise1,promise2])
  .then(values => {
    return res.json({key1:values});
  }).catch(next);
}
```

### 2.4 错误处理
四个参数
```js
app.use(function(err, req, res, next) {
  console.error(err.stack);
  res.status(500).send('Something broke!');
});
```


## 3 Serving static files
照说serving static file这种事应该交给nginx类似的反向代理来做，express只是提供了一种选择。
```javaScript
app.use(express.static(path.join(__dirname,'public')))
```
然后在当前目录新建一个public文件夹，添加img文件夹，里面放一张porn.jpg。
浏览器访问： localhost:port/img/porn.jpg 。 就能看到放进去的的那张图片了。

```js
app.use('/jquery', express.static(__dirname + '/node_modules/jquery/dist/'));
app.use(express.static(__dirname + '/public')); //这样的语法也可以
```
这意思就是请求/jquery这个目录下的资源就等于访问/node_modules/jquery/dist/目录下同名的资源

express4.x的文档上还有详尽的设置:
```js
var options = {
  dotfiles: 'ignore',
  etag: false,
  extensions: ['htm', 'html'],
  index: false,
  maxAge: '1d',
  redirect: false,
  setHeaders: function (res, path, stat) {
    res.set('x-timestamp', Date.now())
  }
}

app.use(express.static('public', options))
```



## 4. 数据库连接
mongoose是连接node和mongodb的库，[官方文档](http://mongoosejs.com/)
```
const mongoose = require('mongoose');
mongoose.connect('mongodb://localhost/test');

const Cat = mongoose.model('Cat', { name: String });
const kitty = new Cat({ name: 'Zildjian' });
kitty.save().then(() => console.log('meow'));
```
[看上去查询和promise有点像，但不要当做Promise](http://mongoosejs.com/docs/queries.html#queries-are-not-promises)


简单的session处理:
> yarn add express cookie-parser express-session

```javaScript
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

## 5. Deploying node app on linux server
在linux server上使用pm2 deploy node project
> 1.  nohup node /home/zhoujie/ops/app.js & ## nohup就是不挂起的意思( no hang up)。 ignoring input and appending output to nohup.out // 输出被写入当前目录下的nohup.out文件中
> 2. screen ## 新开一个screen
> 3. pm2
npm install -g pm2
pm2 start app.js

[Configure Nginx as a web server and reverse proxy for Nodejs application on AWS Ubuntu 16.04 server](https://medium.com/@utkarsh_verma/configure-nginx-as-a-web-server-and-reverse-proxy-for-nodejs-application-on-aws-ubuntu-16-04-server-872922e21d38)


[real world express backend server](https://github.com/gothinkster/node-express-realworld-example-app)
[用swagger ui写后端api文档，极度简单](https://www.cnblogs.com/zzsdream/p/6895893.html)

## 参考

[Nginx 是前端工程师的好帮手](http://www.restran.net/2015/08/19/nginx-frontend-helper/)

[Express Api book](http://expressjs.jser.us/api#req.param)
[在NodeJs中玩转protoBuffer](http://imweb.io/topic/570130a306f2400432c1396c)

