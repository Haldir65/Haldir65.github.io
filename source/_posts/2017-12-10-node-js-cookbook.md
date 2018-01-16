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




[whats-the-difference-between-dependencies-devdependencies-and-peerdependencies](https://stackoverflow.com/questions/18875674/whats-the-difference-between-dependencies-devdependencies-and-peerdependencies)
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

> npm install -g grunt --save-dev # 安装，成为全局(-g)module，保存为dev-dependencies(--save-dev) 简写 -D 一个意思
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
npm install --save-dev babel-polyfill babel-preset-stage-0 ## 用async await的话需要安装polyfill

package.json
```json
{
  "name": "bable-assemble",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1",
    "build": "webpack",
    "start": "webpack-dev-server --output-public-path=/build/"
  },
  "author": "",
  "license": "ISC",
  "devDependencies": {
    "babel-cli": "^6.26.0",
    "babel-core": "^6.26.0",
    "babel-loader": "^7.1.2",
    "babel-polyfill": "^6.26.0",
    "babel-preset-env": "^1.6.1",
    "babel-preset-es2015": "^6.24.1",
    "babel-preset-stage-0": "^6.24.1",
    "http-server": "^0.10.0",
    "webpack": "^3.10.0",
    "webpack-dev-server": "^2.9.7"
  }
}
```
output的文件夹名有些人喜欢叫dist，有些人用build。都行，没有区别的。

如果手动敲webpack的话，会提示你找不到webpack，这是因为没有globally install webpack,webpack还只是个local file。 这也就是写在script里面的原因了: 让npm去node_modules里面找一个叫做webpack的依赖，然后运行webpack。

webpack.config.js
```js
const path = require('path');
module.exports = {
    entry:{
        app:['babel-polyfill','./src/app.js']
    },
    output:{
        path:path.resolve(__dirname,"build"),
        filename:"app.bundle.js"
    },
    module:{
        loaders:[
            {
                test:/\.js?$/,
                exclude:/node_modules/,
                loader:"babel-loader",
                query:{
                    presets:['env']
                }
            }
        ]
    }
};
```


yarn 是facebook设计的，yarn is faster than npm
npm install yarn -g

>npm install express
yarn add express

这俩是一样的,一些常用的command

>yarn init
yarn global add nodemon
yarn outdated
yarn cache clean
yarn run dev
yarn upgrade express


eslint修改配置，让js文件每一行后面都得加冒号(allow semi colons)
[allow semi colons in javascript eslint](https://stackoverflow.com/questions/40453894/allow-semi-colons-in-javascript-eslint)
在.eslintrc中，添加custom rules
```json
"rules": {
        "semi": [2, "always"]
    }
```


node js不支持es2015的import 和export语法，需要使用mudule的话，可使用commonJs，即:
```js
// library.js
module.export.awesome = function () {
  consle.log('awesome');
};

// index.js
var library = require('./library');
library.awesome();

// 需要注意两点，
// 1. require()后面跟的路径是('./library')，是指在当前路径下，而不是在node_modules那个大的文件夹里面找
// 2. require('./library') 和require('./library.js')没有区别
```




sourcemaps
开发过程中使用的是ES2015代码，编译之后就成了非常长的es5代码，在浏览器里面几乎无法断点。使用sourcemap就能在浏览器中将es5代码“反编译”成ES2015代码，还可以打断点。


好用的module
path(core module, 无需安装)
http(core module, 无需安装)
express
nodemon // 实时监控本地文件变化，重启服务，安装npm install nodemon -g
body-parser
ejs
pm2 //starting an node app as a bcakground service
mongoose

=============================================================================


```js
path.join(__dirname,'filename'); // ./filename
path.join(__dirname,"..",filename); // ../filename ,go to parent directory
```
node里面就不要用Ajax了，推荐axios，原生自带也有https。
[node社区最终决定使用mjs文件后缀](https://medium.com/dailyjs/es6-modules-node-js-and-the-michael-jackson-solution-828dc244b8b)
