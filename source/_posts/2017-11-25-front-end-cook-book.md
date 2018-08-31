---
title: 前端速查手册
date: 2017-11-25 23:26:29
tags: [前端]
---

每一个领域都有些不知道该放哪的零碎的点，这里开辟一个新的地方，作为前端杂乱知识的汇总。
![](https://www.haldir66.ga/static/imgs/coffee art life nature living drip dark bw.jpg)

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

网页表单提交数据中包含+号的时候，加号直接变成空格
java这边URLDecoder去decode一个未编码的带加号的string的时候，“+”直接变成了空格。而encode的时候，空格被编码成了+号，+号变成了%2b。
> 常规的表单提交content-type有两种：application/x-www-form-urlencoded和multipart/form-data,如果表单提交时不设置任何类型，默认以第一种方式提交数据；第二种属于带附件的表单提交，当表单中有附件时，必须设置表单的enctype为multipart/form-data.
例如 JQuery的 Ajax，Content-Type 默认值为application/x-www-form-urlencoded;charset=utf-8。

Content-Type:application/x-www-form-urlencoded; charset=UTF-8这句话其实就是告诉ajax，在post的时候去把data用utf-8编码一遍（把“+”变成了"%2b"）。所以，如果默认写一个程序去post一个未经编码的带加号的string的话，服务器这边接收到的string中,"+"就变成了空格（因为后台是会用UrlDecoder去decode的，从源码来看，碰到了“+”直接换成了空格)

### url中带"+"号的问题[陈年老坑之 URL Encoding](https://blog.jamespan.me/2015/05/17/url-encoding)
> 在正常的编码解码流程中，编码的时候先把加号替换为 %2B，然后把空格替换为加号；解码的时候先把加号替换为空格，再把 %2B 替换为加号，天衣无缝。
假如我在一个经过编码的 URI 中直接添加加号，然后直接被拿去解码，加号就会妥妥的被替换成空格了。

我就碰到过那种后台传下来的url中包含'+'，然后用URLDecoder去decode一遍（这时候加号已经被替换成空格了），再去用正则match的时候，发现根本匹配不上这个url.
[那么如何判断一个string是否被encode过？](https://stackoverflow.com/questions/19650431/detect-whether-javasscript-string-has-been-encoded-using-encodeuricomponent)


由此想到url中出现汉字的情况，因为网络传输只能是0101这种，那么就可以用utf-8将汉字的unicode形式传输出去，后台再去根据商定好的encode format去解码。（所以java的URLDecoder的decode方法接受两个参数，一个是裸的文本,http本来就是text based，这没办法，第二个是encoding）。只要两端商定了同一种编码格式，那就能正常的通信。

> Ajax中文乱码

前端传参出现汉字的情况有两种，一种是汉字出现在URL中的一部分，另一种是汉字出现在GET请求的queryParameters里面。其实想想也对，http请求是一行一行写text的,第一行是path，后面才是queryParameters

ajax发送请求[Web编码总结](https://yanhaijing.com/web/2014/12/20/web-charset/)如果不指定CharSet,似乎会看页面编码,就是这个
```html
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
```
这里面还涉及到一个用get和post请求那个比较合适的问题，GET请求浏览器会帮忙encode，但是，有的浏览器(IE)是用系统自带编码格式（windows中文版本上是GB2312)去encode的，如果使用POST,开发者可以自定义数据编码格式（自己调用encodeURIComponent把所有的data都utf-8加密一遍）



### 跨域是一个比较大的知识点
```
about:1 Failed to load http://api.douban.com/v2/movie/top250: Response to preflight request doesn't pass access control check: No 'Access-Control-Allow-Origin' header is present on the requested resource. Origin 'http://localhost:8080' is therefore not allowed access.
```
查了好久，原因是CORS(Control of Shared Resources)，通过ajax发起另一个domain(port)资源的请求默认是不安全的。主要是在js里面代码请求另一个网站(只要不满足host和port完全相同就不是同一个网站)，默认是被[禁止](http://www.ruanyifeng.com/blog/2016/04/cors.html)的。chrome里面查看network的话，发现这条request确实发出去了，request header里面多了一个
> Origin:http://localhost:8080
显然这不是axios设置的，在看到这条header后，如果'/movie/top250'这个资源文件没有设置'Access-Control-Allow-Origin: http://localhost:8080'的话，浏览器就算拿到了服务器的回复也不会允许被开发者获取。这是CORS做出的策略，也是前端开发常提到的跨域问题。

解决方法：
1.和服务器商量好CORS
2.使用jsonp(跨域请求并不限制带src属性的tag，比如script img这些)
3.使用iframe跨域

CORS还是比较重要的东西，[详解](http://www.ruanyifeng.com/blog/2016/04/cors.html)，据说会发两次请求,且只支持GET请求。
[cors的概念](http://www.ruanyifeng.com/blog/2016/04/cors.html)
> search "原生javaScript跨域"、'jsonp跨域请求豆瓣250'

[jsonp跨域获取豆瓣250接口](http://www.jianshu.com/p/1f32c9a96064)
豆瓣能支持jsonp是因为豆瓣服务器响应了

> http://api.douban.com/v2/movie/top250?callback=anything这个query,这个anything是我们自己网页里面script里面定义的方法，豆瓣会返回一个: anything({json})的数据回来，直接调用anything方法


json【JavaScript Object Notation】
[MDN上的corz](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Access_control_CORS)

将网页设置为允许 XMLHttpRequest 跨域访问
```html
<meta http-equiv="Access-Control-Allow-Origin" content="*">

<meta http-equiv="Access-Control-Allow-Origin" content="http://www.1688hot.com:80">
```

跨域的方法有很多，iframe是一种，iframe是在一个网页中展示另一个url页面资源的方式
```html
<iframe id="video" width="420" height="315" src="https://www.baidu.com" frameborder="0" allowfullscreen></iframe>
```
然后在localhost起一个服务器预览，就能在页面中正常展示百度首页。

[jsonp的解释](http://schock.net/articles/2013/02/05/how-jsonp-really-works-examples/)

亲测，Flask里面给response添加Header:
>  response.headers['Access-Control-Allow-Origin'] = 'http://localhost:8080'

在8080端口的web页面发起请求就能成功



### 2.2 ajax跨域操作
[XMLHttpRequest cannot load http://localhost:5000/hello.
No 'Access-Control-Allow-Origin' header is present on the requested resource.](https://stackoverflow.com/questions/25860304/how-do-i-set-response-headers-in-flask)
用Flask做后台，大概的代码这样
<!--
```python
@app.route("/posts", methods=['GET'])
def create_post()
    resp = Response(json.dumps(post_lists), mimetype='application/json')
    resp.headers['Access-Control-Allow-Origin'] = '*'
    return resp    
``` -->


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
vs code 调整锁进的命令叫做reindent



在<del>不会自己搭服务</dev>的情况下只好拿一些免费的api凑合了
[posts](http://jsonplaceholder.typicode.com/posts)
[cnodejs](https://cnodejs.org/api/v1/topics)


## 使用nginx搭建本地服务器
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
- [X]Express js
- [ ] css3 属性大全


vscode disable eslint，在workspace setting中添加
> "jshint.enable" : false


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
![](https://www.haldir66.ga/static/imgs/Cute_and_sexy_asian_girl_in_purple_strapless_gown.jpg)
![](https://www.haldir66.ga/static/imgs/IMG_0766.jpg)

把vscode 加入command line，将'C:\\Program Files (x86)\\Microsoft VS Code\\bin'添加到windows的环境变量中即可。cmd里输入code即可打开当前目录。

handlebars渲染template的过程就是把写在模板里面的大括号包着的变量换成String。所以，在hbs文件里内嵌的js是[没有办法轻易拿到data的](https://stackoverflow.com/questions/19247150/is-it-possible-to-access-the-data-that-is-sent-to-handlebars-through-js-inside-t)。这跟flask很像。
这里顺便提到iffe的概念[Immediately-invoked_function_expression](https://stackoverflow.com/questions/8228281/what-is-the-function-construct-in-javascript)
```html
<script src="http://cdnjs.cloudflare.com/ajax/libs/handlebars.js/1.0.0/handlebars.min.js"></script>

<script id="test-template" type="text/x-handlebars-template">
  <label>Label here</label>
{{textField dataAttribs='{"text":"Hello", "class":"input"}'}}
</script>
```

```js
Handlebars.registerHelper('textField', function(options) {
    var dom = '<input type="text">', attribs;

    attribs = JSON.parse(options.hash.dataAttribs);
    console.log(attribs.text + " -- " + attribs.class);

    return new Handlebars.SafeString(dom);
});

$(function() {

    var markup = $('#test-template').html();
    var template = Handlebars.compile(markup);
    $('body').append(template());

});
```
来看看xss一般的手段
> <img src="#" onerror="alert(/xss/)" />

防范XSS攻击的手段中提到了，对于用户的输入，需要有条件的进行转换
比如说
```
< 变成 &lt;
> 变成 &gt;
& 变成  变成&quot;
```
就像这样
```java
private static String htmlEncode(char c) {
    switch(c) {
       case '&':
           return "&amp;";
       case '<':
           return "&lt;";
       case '>':
           return "&gt;";
       case '"':
           return "&quot;";
       case ' ':
           return "&nbsp;";
       default:
           return c + "";
    }
}
```
经过编码转换之后
```
<script>window.location.href=”http://www.baidu.com”;</script> ## 就变成了
&lt;script&gt;window.location.href=&quot;http://www.baidu.com&quot;&lt;/script&gt;
```
python flask里面类似的函数叫做escape.



[cms(content management sustem)参考](https://github.com/ximolang/QuillCMS)




## 参考
- [一个腾讯前端的博客](https://www.xuanfengge.com/page-back-does-not-cache.html)
- [Webpack Crash Course](https://www.youtube.com/watch?v=lziuNMk_8eQ)
- [Use Babel & Webpack To Compile ES2015 - ES2017](https://www.youtube.com/watch?v=iWUR04B42Hc)

[rel="dns-prefetch"](https://developer.mozilla.org/zh-CN/docs/Controlling_DNS_prefetching)