---
title: 2017-10-29-pure-javaScript
date: 2017-10-29 22:10:27
tags: [javaScript]
---

少一点Web，多一些原生javaScript
<!--more-->
![](http://odzl05jxx.bkt.clouddn.com/unclassified_unclassified--115_07-1920x1440.jpg?imageView2/2/w/600)

## 1. js跨域请求
[cors的概念](http://www.ruanyifeng.com/blog/2016/04/cors.html)
> search "原生javaScript跨域"、'jsonp跨域请求豆瓣250'

[jsonp跨域获取豆瓣250接口](http://www.jianshu.com/p/1f32c9a96064)
[MDN上的corz](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Access_control_CORS)



## 使用Atom的时候，按下ctrl+shift+i ，会发现原来atom编辑页面就特么是一个网页。


12. MicroTask和MacroTask的执行顺序是：Stack -> MacroTask -> MicroTask [参考](https://juejin.im/entry/59e95b4c518825579d131fad)

9. setTimeout是schedule一个task，setInterval是设定一个周期性执行的任务。

8. 可以检测是ES5还是ES6
```javaScript
function f() { console.log('I am outside!'); }
(function () {
if(false) {
// 重复声明一次函数f,ES5会输出'i am insider', ES6会输出'i am outsider'
function f() { console.log('I am inside!'); }
}
f();
}());
```

7. javaScript debug的方法：选中一个html 的tag，break on 。。。 自然会在执行到的时候停下来，evalulate value需要自己在console里面敲（注意此时应该位于Sources标签页下）。
8. HTML DOM的一些方法
通过 id 找到 HTML 元素 window.document.getElementById()
通过标签名找到 HTML 元素 window.document.getElementsByTagName()
通过类名找到 HTML 元素 window.document.getElementsByClassName()
9.交互事件的捕获，拦截，消费（冒泡）
```javaScript
function cancelEvent(e) {
    if(e) {
        e.stopPropagation();  //非IE
    } else {
        window.event.cancelBubble = true;  //IE
    }
}
```
在一个元素上触发事件，如果此元素定义了处理程序，那么此次事件就会被捕获，根据程序进行该事件的处理。否则这个事件会根据DOM树向父节点逐级传播，如果从始至终都没有被处理，那么最终会到达document或window根元素。所以事件是往上传递的，即冒泡。
