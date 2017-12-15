---
title: 前端速查手册
date: 2017-11-25 23:26:29
tags: [前端]
---

每一个领域都有些不知道该放哪的零碎的点，这里开辟一个新的地方，作为前端杂乱知识的汇总。
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/scenery1511100729187.jpg?imageView2/2/w/600)

<!--more-->
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/scenery1511100809920.jpg?imageView2/2/w/600)




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





***Third Party Library***

## Vue Related

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

- [ ]如何使用js显示一个Dialog
- [ ]Express js
- [ ] css3 属性大全



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


预处理语言
1. Sass 诞生于 2007 年，Ruby 编写，其语法功能都十分全面，可以说 它完全把 CSS 变成了一门编程语言。另外 在国内外都很受欢迎，并且它的项目团队很是强大 ，是一款十分优秀的预处理语言。
2. Stylus 诞生于 2010 年，来自 Node.js 社区，语法功能也和 Sass 不相伯仲，是一门十分独特的创新型语言。
3. Less 诞生于 2009 年，受Sass的影响创建的一个开源项目。 它扩充了 CSS 语言，增加了诸如变量、混合（mixin）、函数等功能，让 CSS 更易维护、方便制作主题、扩充（引用于官网）。

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
- [一个腾讯前端的博客](https://www.xuanfengge.com/page-back-does-not-cache.html)


![](http://odzl05jxx.bkt.clouddn.com/image/jpg/lith/IMG_0766.jpg?imageView2/2/w/600)

=======================================================================================
[TBS]腾讯浏览服务(Tencent Browsing Service, TBS)。网上很多人喷的微信浏览器慢就是这个






















***再过几天就要生日了，想到又要变老，挺舍不得的。
送给，这两年来的你，不负韶华***
