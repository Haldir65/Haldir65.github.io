---
title: Vanilla JS Tips
date: 2017-10-29 22:10:27
tags: [javaScript,前端]
---

论运行速度，在Vanilla JS面前，所有的js library都是渣
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/scenery04e31f5513d62958957b4caa1d944ae4.jpg?imageView2/2/w/600)

<!--more-->


关于js的历史，根据Patrick Dubroy在2014年的一次[演讲](https://www.youtube.com/watch?v=34cw-XRknWM)，ES3是1999年出来的，ES3之前的版本简直是翔。ES4设计的实在太牛逼，一直拖到2008年也没搞定，所以大家决定直接跳过ES4(历史上也从未有过ES4)，推出了ES5（只把ES4中的一部分实现了），实际上2015年6月ES6(也就是2008年那帮人所称呼的harmony)才发布。关于Patrick Dubroy，这人在2011年的Google IO上做过关于用mat检测Android Memory Leak的演讲，老外真是全才。

## TakeAways
1. [基本语法](#1-一些作为一门语言基本的操作都有)
2. [操作html的一些点](#2-操作HTML-DOM的一些方法)
3. [交互事件的注册，捕获，拦截](#3-从onclick开始到整个交互事件模型)
4. [异步](#4-异步的实现)
5. [ES6新增的东西](#5-ES6新增的一些东西)
6. [我也不知道归到哪一类的问题](#6-我也不知道归到哪一类的问题)


## 1. 一些作为一门语言基本的操作都有

![](http://odzl05jxx.bkt.clouddn.com/image/jpg/scenery151110078544.jpg?imageView2/2/w/600)

### 1.1 比如说module（就是import，export这种，虽然是ES6才补上的）
 js中好像没有像java中那种javaBean的特殊的数据类型的存在。
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

### 1.2 基本的操作符，dynanic type,函数，变量，oop,class（ES6）,for循环,while这些都有
- js里面判断两个变量相等的方式，建议一律使用三个等号（严格相等）
```javaScript
var a = 3;
var b = "3";
a==b 返回 true
a===b 返回 false

// 因为a,b的类型不一样
// ==只比较了值
// ===只有在值和类型完全相同的时候才为true，用来进行严格的比较判断
// !=（只检查值）和!==（检查值和类型）也差不多的意思。
= 赋值运算符
== 等于
=== 严格等于
&&和||也有，!=也有

- true和false也有
// truthy的概念是js里面特有的
// 在console里面输入：
Boolan(5)  > 输出true
Boolean(-5) >输出false
Boolean(7>5) > 输出true
Boolean('someword') > true
Boolean('') > false
// 只有Boolan(0)才是false
```

- string，number,array也有
```javaScript
// var myString = 'i 'm a "funny" string' #这样是不行的
var myString = 'i \'m a "funny" string';//加一个转义就好了

var a = 'abc'
var b = 'bcd'
a<b // true,因为ASCII表里面，a在b前面

var str = 'hello world'
var str2 = str.slice(2,9);
str2 // 'llo,wo'

var tags = 'meat,ham ,salami,prok,beef,chicken'
var tagsArray = tags.split(",")
//生成
["meat","ham","salami","prok","beef","chicken"]
```

*js的Array里面能够装不同类型的数据，跟Python很像*
```javaScript
//创建Array的方式很多
var array = []
var array1 = ['stuff','jeff',20]
var array2 = new Array()

var myArray = []// 初始化就好了，无需指定容量
myArray[0] ='stuff'
myArray[1] = 70
myArray > ['stuff',70]

myArray[30] = true

// 以下为亲测console中的输出就这样
myArray > (31) ["stuff", 70, empty × 28, true]
myArray[12] > 'undefined'
myArray.length > 31
myArray.sort() > (31) [70, "stuff", true, empty × 28]
```

*Object，class这种oop的特性也有*
```javaScript
var myCaR = new Car()
VM315:1 Uncaught ReferenceError: Car is not defined
    at <anonymous>:1:13
var myString = new String()
myString = 'hello'    
myString.length > 5
var mystring23 = new String('stuff')//这也是行的

// 直接在console里写
var myCar = new Object()
undefined
myCar.speed = 20
20
myCar.speed
20
myCar.name = 'benz'
"benz"
myCar.name
"benz"
myCar
{speed: 20, name: "benz"} //json即object

var car2 = {speed: 30, name: "tesla"}

car2
{speed: 30, name: "tesla"}
```
*上下文的概念也有，this关键字，但要注意闭包*
```javaScript
// console直接输入
this
Window {frames: Window, postMessage: ƒ, blur: ƒ, focus: ƒ, close: ƒ, …}//window是一个有很多变量(function也是变量)的对象，在当前语义下，就是window

car2.test = function(){console.log(this)}
car2
{speed: 30, name: "tesla", test: ƒ}

car2.test
ƒ (){console.log(this)}

car2.test()//这时候this就是car2这个Object了
VM592:1 {speed: 30, name: "tesla", test: ƒ}
```
this应该是当前上下文

 *Construction function，函数也是一个object的成员*
```javaScript
var Car = function (name,speed) {
  this.name = name
  this.speed = speed
  this.test = function () {
    console.log('speed is '+speed)
  }
}
var car24 = new Car('jim',40)
car24
Car {name: "jim", speed: 40, test: ƒ}
car24.test()
VM621:5 speed is 40
```

- Object definition(construcor)，class也有
- 还有随便用的log


### 1.3 一些工具，时间,Math，io操作也有
Date Object的使用
```javaScript
let past = new Date(2007,11,9)
undefined
past
// Sun Dec 09 2007 00:00:00 GMT+0800 (中国标准时间)
past.getDay
ƒ getDay() { [native code] }
past.getDay()
0
past.getFullYear()
2007
past.getDate
ƒ getDate() { [native code] }
past.getDate()
9
```
![](http://odzl05jxx.bkt.clouddn.com/unclassified_unclassified--115_07-1920x1440.jpg?imageView2/2/w/600)

网络请求，Ajax请求的套路也有
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


## 2. 操作HTML-DOM的一些方法
通过 id 找到 HTML 元素 window.document.getElementById()
通过标签名找到 HTML 元素 window.document.getElementsByTagName()//比如说'h2'这种
通过类名找到 HTML 元素 window.document.getElementsByClassName()
注意方法名称，带s的返回的是一个数组，不带s返回一个object
找form 标签的话，还有一种方法:
先手写一段html
```html
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <title>有时候手写html不是坏事</title>
  <link href="style.css" type="text/css" rel="stylesheet"></link>
</head>
<body>
  <div>
    <form id='my-form' name='myForm' action="#">
      <label for="name">Name: </label>
      <input type="text" name="name"><br/>
      <label>Hobbies: </label<br/>
      <input type="checkbox" name="biking" value="biking">Biking</br>
      <input type="checkbox" name="sking" value="sking">Sking</br>
      <input type="checkbox" name="diving" value="diving">Diving</br>
      <label for="colour">Fav colour: </label>
      <select name="colour">
        <option>Red</option>
        <option>Blue</option>
        <option>Green</option>
      </select>
      <input type="submit" name="submit" value='Submit'>
    </form>
  </div>
  <script src="test.js"></script>
</body>
</html>
```
```javaScript
var myForm = document.forms.myForm//myForm是这个Form标签的name属性,form是跟input配合使用的
myForm.name  > 那个input标
myForm.name.value  > 那个input标签，其实也就是那个输入框里面的文字
myForm.colour.vaule > 显示当前选中的select值
```
还是上面那个表单
```javaScript
var myForm = document.forms.myForm
var message = document.getElementById('message')

myForm.onsubmit = function () {//就是上面那个submit被点击时触发
  if(myForm.name.value === ''){
    message.innerHtml = 'please enter an not empty name'
    return false //summit事件被终止
  }else {
    message.innerHtml = ''
    return true
  }
}
```

div.innerHtml（把整个html对象都返回了）和div.textContent(只返回文字)。所以innerHtml可以用来把一个div里面的tag全部替换掉（比如原来是个p，现在换成h1），而textContent只能把某一个tag里面的文字改掉。
想要[改href](https://stackoverflow.com/questions/4365246/how-to-change-href-of-a-tag-on-button-click-through-javascript)的话，得这样：
```javaScript
var link = document.getElementById("abc");
link.setAttribute("href", "xyz.php");
```
setAttribute()可以用于设置一个在当前tag上不存在的attr
设置class可以用setAttribute('class','XXX')，也可以用div.className = 'XXX'
对于一个a标签
```html
<a href="/subpage">Some Thing</a>
```
这时候调用a.href > 会输出'http://www.host.com/subpage'，即输出完整的路径
但是如果使用a.getAttribute('href') > 输出'/subpage'


改一个tag的背景元素不能这么改：
```javaScript
a.style.background-color= 'blue'
//得这样
a.style.backgroundColor= 'blue'//其实就是横线换成CammelCase
```

18. 在dom中新增一个element的方法
```javaScript
var li = document.createElement('li') //创建一个新的li标签,
parentTag.appendChild(li)//添加到尾部
parentTag.insertBefore(li,parentTag.getElementsByTagName('li')[0])//添加到原来的0元素前面

//删除一个tag的话
var removed = parentTag.removeChild(li)//移除方法会返回被移除的元素
```

## 3.从onclick开始到整个交互事件模型

## 4. 异步的实现

## 5. ES6新增的一些东西

## 6. 我也不知道归到哪一类的问题


9. 交互事件的捕获，拦截，消费（冒泡）
```javaScript
//添加点击事件点击事件：
var button = document.getElementById('btn')
button.onclick = function () {
  console.log('you click this button');
}
button.onfocus = function() {
  // body...
}
button.onblur = function () {
  //
}

function cancelEvent(e) {
    if(e) {
        e.stopPropagation();  //非IE
    } else {
        window.event.cancelBubble = true;  //IE
    }
}
```
在一个元素上触发事件，如果此元素定义了处理程序，那么此次事件就会被捕获，根据程序进行该事件的处理。否则这个事件会根据DOM树向父节点逐级传播，如果从始至终都没有被处理，那么最终会到达document或window根元素。所以事件是往上传递的，即冒泡。

//事件注册的时机
对于简单的script，需要在body的最后一行，因为浏览器是从上到下解析的，轮到script解析的时候，需要操作dom，这就要求dom元素已经建立好。有时候，就算你把script写在body最后一行，轮到解析script的时候，前面的html还在加载（比如说非常大的html什么的，总之是有可能的）。所以一般用window.onLoad来注册事件。

复杂点的script放在外面，用src引用。 也要用window.onLoad来注册事件。所以，一般的js长这样（假如的你js要操作dom）：
```javaScript
function setUpEvents() {
  var button = ....
  var ....
  button.onclick = function () {
    //
  }

  button.
}

window.onLoad = function () {
  setUpEvents()
}
```


9. this的作用范围
代码[来源](https://cn.vuejs.org/v2/guide/computed.html)
```javaScript
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






8. js去刷新当前页面，返回上级页面。。
```html
<a href="javascript:history.go(-1)">返回上一页</a>
<a href="javascript:location.reload()">刷新当前页面</a>
<a href="javascript:" onclick="history.go(-2); ">返回前两页</a>
<a href="javascript:" onclick="self.location=document.referrer;">返回上一页并刷新</a>
<a href="javascript:" onclick="history.back(); ">返回上一页</a>
```



10. 监听关闭窗口事件
```javaScript
window.onbeforeunload = function () {
       return "Bye now!"
   }
```   
[JavaScript使用哪一种编码？](http://www.ruanyifeng.com/blog/2014/12/unicode.html),不是utf-8

[atom安装插件被墙问题](http://blog.csdn.net/qianghaohao/article/details/52331432)
Atom推荐插件
[atom-beautify](https://atom.io/packages/atom-beautify)


===============================================================================================
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

## 1. js跨域请求
[cors的概念](http://www.ruanyifeng.com/blog/2016/04/cors.html)
> search "原生javaScript跨域"、'jsonp跨域请求豆瓣250'

[jsonp跨域获取豆瓣250接口](http://www.jianshu.com/p/1f32c9a96064)，豆瓣能支持jsonp是因为豆瓣服务器响应了
> http://api.douban.com/v2/movie/top250?callback=anything这个query,这个anything是我们自己网页里面script里面定义的方法，豆瓣会返回一个: anything({json})的数据回来，直接调用anything方法
json【JavaScript Object Notation】
[MDN上的corz](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Access_control_CORS)

[jsonp的解释](http://schock.net/articles/2013/02/05/how-jsonp-really-works-examples/)

亲测，Flask里面给response添加Header:
>  response.headers['Access-Control-Allow-Origin'] = 'http://localhost:8080'

在8080端口的web页面发起请求就能成功



### 参考
