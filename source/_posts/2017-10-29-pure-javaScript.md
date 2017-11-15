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

[jsonp跨域获取豆瓣250接口](http://www.jianshu.com/p/1f32c9a96064)，豆瓣能支持jsonp是因为豆瓣服务器响应了
> http://api.douban.com/v2/movie/top250?callback=anything这个query,这个anything是我们自己网页里面script里面定义的方法，豆瓣会返回一个: anything({json})的数据回来，直接调用anything方法

[MDN上的corz](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Access_control_CORS)

[jsonp的解释](http://schock.net/articles/2013/02/05/how-jsonp-really-works-examples/)

亲测，Flask里面给response添加Header:
>  response.headers['Access-Control-Allow-Origin'] = 'http://localhost:8080'

在8080端口的web页面发起请求就能成功

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
9. this的作用范围
代码[来源](https://cn.vuejs.org/v2/guide/computed.html)
```
<script src="https://cdn.jsdelivr.net/npm/axios@0.12.0/dist/axios.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/lodash@4.13.1/lodash.min.js"></script>
<script>
var watchExampleVM = new Vue({
  el: '#watch-example',
  data: {
    question: '',
    answer: 'I cannot give you an answer until you ask a question!'
  },
  watch: {
    // 如果 `question` 发生改变，这个函数就会运行
    question: function (newQuestion) {
      this.answer = 'Waiting for you to stop typing...'
      this.getAnswer()
    }
  },
  methods: {
    // `_.debounce` 是一个通过 Lodash 限制操作频率的函数。
    // 在这个例子中，我们希望限制访问 yesno.wtf/api 的频率
    // AJAX 请求直到用户输入完毕才会发出。想要了解更多关于
    // `_.debounce` 函数 (及其近亲 `_.throttle`) 的知识，
    // 请参考：https://lodash.com/docs#debounce
    getAnswer: _.debounce(
      function () {
        if (this.question.indexOf('?') === -1) {
          this.answer = 'Questions usually contain a question mark. ;-)'
          return
        }
        this.answer = 'Thinking...'
        var vm = this //这里需要把this（VewComponent）作为一个变量
        axios.get('https://yesno.wtf/api')
          .then(function (response) {
            vm.answer = _.capitalize(response.data.answer)
          })
          .catch(function (error) {
            vm.answer = 'Error! Could not reach the API. ' + error
          })
      },
      // 这是我们为判定用户停止输入等待的毫秒数
      500
    )
  }
})
</script>
```


10. Ajax请求的套路
```javaScript
var getJSON = function(url) {
  var promise = new Promise(function(resolve, reject){
    var client = new XMLHttpRequest();
    client.open("GET", url);
    client.onreadystatechange = handler;
    client.responseType = "json";
    client.setRequestHeader("Accept", "application/json");
    client.send();

    function handler() {
      if (this.status === 200) {
        resolve(this.response);
      } else {
        reject(new Error(this.statusText));
      }
    };
  });

  return promise;
};

getJSON("/posts.json").then(function(json) {
  console.log('Contents: ' + json);
}, function(error) {
  console.error('出错了', error);
});
```

11.js里面判断两个变量相等的方式，建议一律使用三个等号（严格相等）
= 赋值运算符
== 等于
=== 严格等于
例：
var a = 3;
var b = "3";

a==b 返回 true
a===b 返回 false

因为a,b的类型不一样
===用来进行严格的比较判断

在一个元素上触发事件，如果此元素定义了处理程序，那么此次事件就会被捕获，根据程序进行该事件的处理。否则这个事件会根据DOM树向父节点逐级传播，如果从始至终都没有被处理，那么最终会到达document或window根元素。所以事件是往上传递的，即冒泡。


8. js去刷新当前页面，返回上级页面。。
```html
<a href="javascript:history.go(-1)">返回上一页</a>
<a href="javascript:location.reload()">刷新当前页面</a>
<a href="javascript:" onclick="history.go(-2); ">返回前两页</a>
<a href="javascript:" onclick="self.location=document.referrer;">返回上一页并刷新</a>
<a href="javascript:" onclick="history.back(); ">返回上一页</a>
```

9. js中好像没有像java中那种javaBean的特殊的数据类型的存在。
ES6开始可以使用import和export语法，有类似的效果，[参考](https://stackoverflow.com/questions/34741111/exporting-importing-json-object-in-es6)
states.js
```javaScript
export default {
  STATES: {
    'AU' : {...},
    'US' : {...}
  }
};

import STATES from 'states';
// 或者
var STATES = {};
STATES.AU = {...};
STATES.US = {...};
export STATES;

import { STATES } from 'states';//接受方最好写上大括号包起来
//
import whatever from 'states';
// whatever会变成export default中的内容
```

10. 监听关闭窗口事件
```javaScript
window.onbeforeunload = function () {
       return "Bye now!"
   }
```   
[atom安装插件被墙问题](http://blog.csdn.net/qianghaohao/article/details/52331432)
Atom推荐插件
[atom-beautify](https://atom.io/packages/atom-beautify)
