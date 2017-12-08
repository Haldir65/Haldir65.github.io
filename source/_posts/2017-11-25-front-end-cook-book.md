---
title: 前端速查手册
date: 2017-11-25 23:26:29
tags: [前端]
---

每一个领域都有些不知道该放哪的零碎的点，这里开辟一个新的地方，作为前端杂乱知识的汇总。
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/scenery1511100729187.jpg?imageView2/2/w/600)

<!--more-->
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/scenery1511100809920.jpg?imageView2/2/w/600)
## html一些容易忽视的点

p tag 里面能够放一个小的Strong tag
```html
<p>You Know <strong>No</strong> Mystery</p>
```
亲测，这些tag不分大小的，不是说div就一定是最外面的parent
```html
<p>
  new css PlayGround
  <div>哈哈</div>
</p>
```
## Vanilla js要点
## css要点
## jQuery要点
## Vue知识点

Babel是一个可以把ES6代码打包成ES5代码的插件，毕竟要兼容老的浏览器。
[ua-parser-js](https://github.com/faisalman/ua-parser-js)是一个很好用的检测ua的library。
[Backbone](http://www.css88.com/doc/backbone/)是一个mvc框架
[移动开发中的一些有用meta标签](http://www.html-js.com/article/The-front-end-of-mobile-terminal-meta-tag-set-of-notes-the-role-of)

npm的configuration非常方便设置,首先是[设置proxy](https://stackoverflow.com/questions/7559648/is-there-a-way-to-make-npm-install-the-command-to-work-behind-proxy)
> npm config set strict-ssl false
> npm config set registry "http://registry.npmjs.org/"
> npm config set proxy http://127.0.0.1:1080 ## 以上三句话设置代理
> npm config list ##列出当前所有的设置
> npm config get stuff ##比如说registry等等

VS Code好用

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
> npm install -g grunt --save-dev # 安装，成为全局(-g)module，保存为dev-dependencies(--save-dev)
> npm install -g grunt --save # 安装，保存为dependencies

> npm run dev # 打开发环境包
> npm run build # 打release包




atom的emmet插件很好用
比如想要创建一个
```html
<div class='test'></div>
```
只需要输入div.test或者.test然后按tab键
[好玩的Atom插件](https://www.youtube.com/watch?v=aiXNKHKWlmY)
minimap,emmet,file icons，atom liveserver,atom beautify

atom中输入vue,会自动提示生成vue模板,输入re会生成react Boilplate。前提是在js,vue,html文件中。

## 参考


![](http://odzl05jxx.bkt.clouddn.com/image/jpg/lith/IMG_0766.jpg?imageView2/2/w/600)

***再过几天就要生日了，想到又要变老，挺舍不得的。
送给，这两年来的你，不负韶华***
