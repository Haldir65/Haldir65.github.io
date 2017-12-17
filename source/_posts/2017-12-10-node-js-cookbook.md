---
title: nodejs学习记录
date: 2017-12-10 16:13:30
tags: [前端]
---

npm = node package manager
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/scenery1511100694324.jpg?imageView2/2/w/600)
<!--more-->


npm的configuration非常方便设置,首先是[设置proxy](https://stackoverflow.com/questions/7559648/is-there-a-way-to-make-npm-install-the-command-to-work-behind-proxy)
> npm config set strict-ssl false
> npm config set registry "http://registry.npmjs.org/"
> npm config set proxy http://127.0.0.1:1080 ## 以上三句话设置代理
> npm config list ##列出当前所有的设置
> npm config get stuff ##比如说registry等等


用过的module
path(core module, 无需安装)
http(core module, 无需安装)
express
nodemon // 实时监控本地文件变化，重启服务，安装npm install nodemon -g
body-parser
ejs
pm2 //starting an node app as a bcakground service
mongoose



npm有个dependencies的概念，此外还有dev-dependencies的概念，主要看package.json这个文件
```json
{
  "name": "foo",
  "version": "0.0.0",
  "scripts": {
    "dev": "node build/dev-server.js",
    "build": "node build/build.js",
    "test": "",
    "lint": "eslint --ext .js,.vue src test/unit/specs test/e2e/specs"
  },
  "dependencies": {
    "axios": "^0.15.3",
    "jsonp": "^0.2.1"
  },
  "devDependencies": {
    "webpack": "^2.6.1",
    "webpack-dev-middleware": "^1.10.0",
    "webpack-hot-middleware": "^2.18.0",
    "webpack-merge": "^4.1.0"
  }
}
/*script的意思是输入npm run dev = node build/dev-server.js  类似于 linux下的alias*/

/*向上箭头的意思是安装的时候会自动去查找安装最新的minor version。关于版本号，第一位表示major version，may incur code imcompatibility,第二位表示minor version，代表new features,第三位表示bug fixes.所以向上箭头意味着安装时不会动第一位，只会升级为第二位最新的版本*/
```
[stackoverflow上的解释](https://stackoverflow.com/questions/22343224/whats-the-difference-between-tilde-and-caret-in-package-json)

> npm install -g grunt --save-dev # 安装，成为全局(-g)module，保存为dev-dependencies(--save-dev)
> npm install -g grunt --save # 安装，保存为dependencies

> npm run dev # 打开发环境包
> npm run build # 打release包
=======
node is based on chrome v8 engine,it's javaScript without the browser.

## 安装

## 示例
app.js
```js
console.log('hello!');
```
> node app.js
hello!

## 创建node project
> npm init
会提示一些信息，生成一个package.json文件

```json
{
  "name": "test",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "",
  "license": "ISC"
}
```
main是指程序的运行入口
script是指可以自己设置启动的命令，有点像alias
比如 vue-cli的package.json里面就是这样的
> "dev": "node build/dev-server.js",
"build": "node build/build.js"

所以用户只要输入
> npm run dev
就等同于
> node build/dev-server.js


```js
const = require('http');
// http is a core module ,so we do't need install

const hostname = '127.0.0.1';

const port = 3000;

cost server = http.createServer((req,res) => {
	res.statusCode = 200;
	res.setHeader('Content-type','text/plain');
	res.end('Hello there!');
});

server.listen(port,hostname,() =>{
	console.log('Server started on port '+ port);
})
```

此时去浏览器中打开'localhost:3000'，会返回'Hello there!'

想要返回一个html并在浏览器中渲染，
ctrl+c停止服务器，修改代码如下。

```js
const http = require('http');
const fs =require('fs');

const hostname = '127.0.0.1';

const port = 3000;

fs.readFile('index.html',(err,html) => {
	if (err) {
		throw err;
	}
	const server = http.createServer((req,res) => {
		res.statusCode = 200;
		res.setHeader('Content-type','text/html');
		res.write(html);
		res.end();
	});

	server.listen(port,hostname,() =>{
		console.log('Server started on port '+ port);
	})
})
```
现在重新运行node index，打开浏览器，在3000端口就能看到html网页了。

```json
{
  "name": "api",
  "version": "1.0.0",
  "description": "",
  "main": "app.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "",
  "license": "ISC",
  "dependencies": {
    "body-parser": "^1.18.2"
  }
}
```
dependencies里面向上箭头表示安装最新的minor version。而使用"\*"号的话就表示想要使用latest version


=============================================================================
Compile ES6 ES2017 Code to ES5 Code
> npm install --save-dev webpack webpack-dev-server babel-core babel-loader babel-preset-env
