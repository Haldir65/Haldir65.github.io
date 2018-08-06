---
title: jQuery手册
date: 2017-08-27 21:48:52
tags: [jQuery,tools,前端]
---

jQuery是一个dom manipulate library，非常大。jQuery能干的事情包括：

1. html 的元素选取
2. html的元素操作
3. html dom遍历和修改
4. js特效和动画效果
5. css操作
6. html事件操作
7. ajax异步请求方式,etc
![](http://www.haldir66.ga/static/imgs/a13262133_01000.jpg)

<!--more-->


## 1.安装
### 1.1 使用微软或者谷歌的CDN,放在head tag里面
这样做的好处是别的网站已经加载过的js文件可以直接读缓存，加快加载速度
其实自己下载一份，用src引用也行
```html
<head>
<script src="http://ajax.aspnetcdn.com/ajax/jQuery/jquery-1.8.0.js">
</script>
</head>
```
这一段必须放在head里面，用自己的src或者微软，谷歌的cdn都可以。如果自己的js文件引用到了jQuery，[需要把jQuery写在其他js前面](https://stackoverflow.com/questions/8886614/uncaught-referenceerror-jquery-is-not-defined)

这之后，在console中输入
>
window.jQuery
ƒ (a,b){return new r.fn.init(a,b)}

显然是已经注册了全局常量


### 2. 使用npm和express
> yarn add jquery express

然后在app.js中
```js
 app.use('/jquery', express.static(__dirname + '/node_modules/jquery/dist/'));
 ```
 在html里
 ```html
<script src="/jquery/jquery.js"></script>
```
### 1.1所有的jQuery函数都放在ready里面
这一段script放在body后面也行，放在head里面也行
```javascript
$(document).ready(function(){

--- jQuery functions go here ----

});
```
基本上就是window渲染完毕之后开始做一些事情，随便抄了一段知乎首页的Button
这里面双引号("")和单引号('')都行

```javascript
$('button#button1').css("background-color","#0f88eb")
.css('border-radius','8px').css('padding-right','14px')
.css('padding-left','14px').css('color','white')
.css('line-height','30px')
```
前提是body里面放了一个class = button1 的button tag.这里只是改变了按钮的css样式，
jQuery选择器有一些规则需要记住，主要就是如何选择html中的元素
- $(this)表示当前html对象
- $('p')表示所以<p>标签
- $('p.intro')表示所有class为intro的<p>标签
- $('.intro')表示所有class为intro的标签
- $('#intro')表示所有id为intro的元素
- $（'div#intro.head') 所有id= 'intro'的div中，找到class为'head'的元素

### 1.2 常用函数
在script tag里面添加这一段，因为比对框架可能使用了$符号，为避免冲突，用var替代$符号
```javascript
var jq=jQuery.noConflict()，
```

### 1.3 selector怎么写
写一个tag，后面要么写id=''，要么写class = ''，id要用"#"查找，class要用'.'查找。
所以
- <a id="2.2">文字</a> 这种id是不会有响应的

### 1.4 还可以加事件回调
可以在事件后面加回调，例如
```javascript
jq('.click_btn').slideUp(300)
//可以认为第二个参数是一个function
 jq('.click_btn').slideUp(300,function {
    alert('this will invoke after slideup finished')
 })
```
可以自己写函数，可以引用之前定义的函数。当然函数回调里面还可以加回调，当然会有callback hell。简单的解决方式，把作为第二个参数的函数提取成一个函数，引用函数名作为参数传进去就好了。
另外，在js里面var myFunction = function(){//stuff }是完全成立的，函数也是var。

## Todo
- 去复制一大堆文字，button，img的css样式，修改，继承，引用。手写实在太慢
- jQuery插件
- fx queue

## TakeAway
- jQuery必须写在最前面，如果网页中还有其他的js引用到了jQuery的话
