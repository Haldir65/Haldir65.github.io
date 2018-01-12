---
title: 前端速查手册
date: 2017-11-25 23:26:29
tags: [前端]
---

每一个领域都有些不知道该放哪的零碎的点，这里开辟一个新的地方，作为前端杂乱知识的汇总。
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/coffee art life nature living drip dark bw.jpg?imageView2/2/w/600)

<!--more-->

# 常用网站
[cssmatic](https://www.cssmatic.com/box-shadow),一个可以用拖拽的方式生成css代码的神奇的网站
[不仅仅是font,还有很好的icon](http://fontawesome.io/)


[TBS]腾讯浏览服务(Tencent Browsing Service, TBS)。网上很多人喷的微信浏览器慢就是这个
[handlebars](https://github.com/wycats/handlebars.js)
[一个html里面有两个id一样的元素没问题](http://blog.csdn.net/lnn2007/article/details/8869057)
[awesome css UI Design](https://github.com/CodeFrogShow/UI-Design-Music-Player),[Video link here](https://www.youtube.com/watch?v=ExnD_KV5q5g)

***Index***
## html Related
html标签中可以添加data-XXX标签用于把数据和ui块绑定。

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

[什么在阻塞DOM？](https://juejin.im/post/587f4afb61ff4b00651b3c18)

## css Related

## Vanilla javaScript Related
Ajax(Asynchronous javaScript & xml)，从命名上来看就是异步的

json(JavaScript Object notation),摆明着就是给js用的

In JavaScript these two are equivalent:
>object.Property
object["Property"];


对于POST请求，如果Request中明确设置了:
>
xhr.setRequestHeader("Content-type","application/x-www-form-urlencoded");

后台会认为这是一个提交表单的请求，body就应该设置为''
[What is the difference between form data and request payload?](https://stackoverflow.com/questions/10494574/what-is-the-difference-between-form-data-and-request-payload)


## Webpack configuration
> 安装
yarn add webpack //官网不推荐global安装
// 初始化项目
npm init -y  
// 使用
webpack app.js bundle.js --watch // 将app.js编译成bundle.js， 实时监控文件变化。 Html文件中就可以引用bundle.js.
build的话，就是把bundle.js minify的话 webpack app.js bundle.js -p ,其实就是帮忙把所有的空格删掉了



a.js
```js
let resources = 'this is some external resources'; // let 能用是因为node 支持es6这个特性
module.exports = resources;   //如果不是用于浏览器的项目的话，node本身就支持require，只是浏览器不支持require
```
app.js
```js
alert(require('./a.js'));
```


可以为webpack提供config文件
webpack.config.js
```js
module.exports = {
  entry: './src/js/app.js',    // 提供了一个entry,app.js又引用了其他的Js，最终追根溯源，会把所有的自定义和第三方框架全部打到一个bundle.js里面
  outpath: {
    path: __dirname+'/dist',
    filename: 'bundle.js'
  },
  module: {
    loaders: {
      { test: /\.css$/,  //这个test的意思就是说这是个正则，webpack你自己拿去试，正斜杠表示当前目录下，反斜杠表示转义字符，就是后面那个点就把它当成"."好了
        loader: 'style-loader!css-loader'} // 前面那个正则意思是针对所有的css文件，后面是需要安装的loader名称。 这个loader的顺序是从右往左的！
    }
  }
}
```
有了config文件，只需要输入webpack，就能自动根据config文件编译。
在package.json文件中，添加script: "build": "webpack" ， npm run build ，会自动根据configuration文件编译生成可用于生产环境的编译后文件。

webpack-dev-server(提供一个development server，因为之前只是走的file system)
> 安装
yarn add webpack-dev-server
package.json中添加script :
start: webpack-dev-server --entry ./src/js/app.js --out-filename .dist/bundle.js
npm run start

babel-loader(前提是安装了babel)
安装参考[官方文档](https://webpack.js.org/loaders/babel-loader/)
babel就是把es6语法的js文件编译成es5文件的，单独使用的语法大概这样。 webpack的loader成百上千，babel-loader只是其中的一种
> npm run babel -- index.js -o bundle.js -w

安装好babel-loader之后，在webpack.config.js中添加loader(loaders本来就是一个数组)
```js
loaders {
    { test: /\.js$/,
      loader: 'babel-loader',
      exculde: /node_modules/, //排除所有node_modules下面的文件
      query: {preset: ['es2015']}} //这个正则的意思是所有js后缀的文件
}
```


***Third Party Library***

## Vue Related
[better-scroll](https://github.com/ustbhuangyi/better-scroll) 滴滴的员工写的

## jQuery Related
jQuery是一个Dom Manipulate Library


## Twitter BootStrap
[BootStrap速查手册](https://getbootstrap.com/docs/4.0/layout/grid/#stacked-to-horizontal)

## 工具
### vsCode插件推荐
- Auto Close tag
- Beautify
- HTML CSS supported
- Live Server
- Prettier
- Vetur
- Vue2 Snippets
- Bracket Pair Colorizer

VSCode快捷键(其实可以自己配置的，vs的设置文件就是一个很大的json)



在<del>不会自己搭服务</dev>的情况下只好拿一些免费的api凑合了
[posts](http://jsonplaceholder.typicode.com/posts)
[cnodejs](https://cnodejs.org/api/v1/topics)


## nginx使用
官方说nginx的windows版本只供测试使用，性能不怎么样，但用于前端部署还是够用的。去[nginx网站](http://nginx.org/en/docs/windows.html)下载windows版本的nginx，解压缩，双击可执行文件nginx.exe。在这之前，最好先打开conf文件夹，编辑nginx.conf。设置一下端口，因为默认的80说不定就给谁占用了。其实用命令行也能启动：
> start nginx
tasklist /fi "imagename eq nginx.exe" //这个是windows下查看当前在运行的nginx的命令
nginx -s stop // 立即关闭
nginx -s quit // graceful shutdown
这些东西官网上都写得很明白。

生产环境部署前端静态资源可以这么设置，参考知乎的[回答](https://www.zhihu.com/question/46630687)
>
用vue-cli搭建的做法:
1、npm run build
2、把dist里的文件打包上传至服务器 例 /data/www/，我一般把index.html放在static里
所以我的文件路径为：
/data/www/static    
|-----index.html   
|-----js    
|-----css    
|-----images   
 ....
3、配置nginx监听80端口，
location /static alias 到 /data/www/static，
重启nginx   
location /static {       
  alias  /data/www/static/;   
  }
4、浏览器访问http://ip/static/index.html即可



Babel是一个可以把ES6代码打包成ES5代码的插件，毕竟要兼容老的浏览器。
[ua-parser-js](https://github.com/faisalman/ua-parser-js)是一个很好用的检测ua的library。
[Backbone](http://www.css88.com/doc/backbone/)是一个mvc框架
[移动开发中的一些有用meta标签](http://www.html-js.com/article/The-front-end-of-mobile-terminal-meta-tag-set-of-notes-the-role-of)

- [X]如何使用js显示一个Dialog
- [ ]Express js
- [ ] css3 属性大全




atom的emmet插件很好用
比如想要创建一个
```html
<div class='test'></div>
```
只需要输入div.test或者.test然后按tab键
[好玩的Atom插件](https://www.youtube.com/watch?v=aiXNKHKWlmY)
minimap,emmet,file icons，atom liveserver,atom beautify

=======================================================================================
atom中输入vue,会自动提示生成vue模板,输入re会生成react Boilplate。前提是在js,vue,html文件中。
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/Cute%20and%20sexy%20asian%20girl%20in%20purple%20strapless%20gown.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/lith/IMG_0766.jpg?imageView2/2/w/600)

把vscode 加入command line，将'C:\\Program Files (x86)\\Microsoft VS Code\\bin'添加到windows的环境变量中即可。cmd里输入code即可打开当前目录。

## 参考
- [一个腾讯前端的博客](https://www.xuanfengge.com/page-back-does-not-cache.html)
- [Webpack Crash Course](https://www.youtube.com/watch?v=lziuNMk_8eQ)
- [Use Babel & Webpack To Compile ES2015 - ES2017](https://www.youtube.com/watch?v=iWUR04B42Hc)
