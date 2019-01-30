---
title: Vanilla JS Tips
date: 2017-10-29 22:10:27
tags: [javaScript,前端]
---

Vanilla JS其实就是原生javascript了。论运行速度，在Vanilla JS面前，所有的js library都要慢很多。
![](https://www.haldir66.ga/static/imgs/scenery04e31f5513d62958957b4caa1d944ae4.jpg)

<!--more-->


关于js的历史，根据Patrick Dubroy在2014年的一次[演讲](https://www.youtube.com/watch?v=34cw-XRknWM)，ES3是1999年出来的，ES3之前的版本简直是翔。ES4设计的实在太牛逼，一直拖到2008年也没搞定，所以大家决定直接跳过ES4(历史上也从未有过ES4)，推出了ES5（只把ES4中的一部分实现了），实际上2015年6月ES6(也就是2008年那帮人所称呼的harmony)才发布。关于Patrick Dubroy，这人在2011年的Google IO上做过关于用mat检测Android Memory Leak的演讲，老外真是全才。

## TakeAways
1. [基本语法](#1-一些作为一门语言基本的操作都有)
2. [操作html的一些点](#2-操作HTML-DOM的一些方法)
3. [交互事件的注册，捕获，拦截](#3-从onclick开始到整个交互事件模型)
4. [异步](#4-异步的实现)
5. [ES6新增的东西](#5-ES6新增的一些东西)
6. [我也不知道归到哪一类的问题](#6-我也不知道归到哪一类的问题)
7. [一些tricks](#7-小测试)


## 1. 一些作为一门语言基本的操作都有

![](https://www.haldir66.ga/static/imgs/scenery151110078544.jpg)

### 1.1 比如说module（就是import，export这种，虽然是ES6才补上的）
 <del>js中好像没有像java中那种javaBean的特殊的数据类型的存在。</del>其实也不需要，js并不是一种用class来model real world object的语言。
ES6开始可以使用import和export语法，有类似的效果，[参考](https://stackoverflow.com/questions/34741111/exporting-importing-json-object-in-es6)
但node js目前(version 8.x)还不支持es 2015的import export语法，偏偏node对于其他es2015的特性都支持到位了。

```js
// states.js
export default {
  STATES: {
    'AU' : {...},
    'US' : {...}
  }
};

// accept.js
import { STATES } from './states';  //undefined
import  STATES  from './states';  // concrete object ,this works
import whatever from 'states'; // concrete object, this works


// 另一种情况
var STATES = {};
STATES.AU = {...};
STATES.US = {...};
export STATES;

import { STATES } from 'states';//如果输出方使用export default，接收方不应加上大括号。此时输出方输出的是匿名Object，接收方随便起什么名字都行。
// 如果输出方输出有明确定义的function, object，接收方需要添加大括号。
```

es6的import和export需要注意
```js
// A.js
export default function greet(params) {
    console.log('hello');
}

// B.js
import firstGreet from '.A.js'; //this works
import { firstGreet } from '.A.js'; // undefined !

// A.js
const sayHi = function hi() {
    console.log("hi");
}
export { sayHi }

// B.js
import { firstGreet } from '.A.js'; // this works
```

原因就在于第一种方式是使用匿名export的。

### 1.2 基本的操作符，dynanic type,函数，变量，oop,class（ES6）,for循环,while这些都有
- js里面判断两个变量相等的方式，建议一律使用三个等号（严格相等）

```js
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


### 1.3 一些工具，时间,Math，io操作（文件系统、网络）也有
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
![](https://www.haldir66.ga/static/imgs/magnolia_1920x1440.jpg)

网络请求，Ajax(Asynchronous javaScript & xml)请求的套路也有(AJAX命名上就是异步的)
XMLHttpRequest缩写是(XHR)
关于XHR Object的一些特点
- API In the form of an object
- Provided by the browser's js environment
- can be used with other protocols than http
- Can work with data other than XML(Json ,plain text)

有很多的<del>Library</del>能干ajax一样的事情:
jQuery,Axios,Superagent,Fetch API,Prototype,Node HTTP

ajax的onload只会在onreadystatechange==4的时候才会触发
MDN文档上说ajax的readyState有五种：
0	UNSENT	代理被创建，但尚未调用 open() 方法。
1	OPENED	open() 方法已经被调用。
2	HEADERS_RECEIVED	send() 方法已经被调用，并且头部和状态已经可获得。
3	LOADING	下载中； responseText 属性已经包含部分数据。
4	DONE	下载操作已完成。

xhr.onProgress的readyState是3，这个时候显示加载进入条就可以了。


表单的操作
```html
<h1>Normal get form</h1>
<form method="GET" action="process.php">
  <input type="text" name='name'>
  <input type="submit" value="Submit">
</form>

<h1>Ajax get form</h1>
<form id='getForm' >
  <input type="text" name='name' id='name1'>
  <input type="submit" value="Submit">
</form>

<h1>Normal post form</h1>
<form method="POST" action="process.php">
  <input type="text" name='name'>
  <input type="submit" value="Submit">
</form>

<h1>Ajax post form</h1>
<form id='postForm' name='name' id='name2'>
  <input type="text" name='name'>
  <input type="submit" value="Submit">
</form>
```

```js
document.getElementById('getForm').addEventListener('submit',
getName);

function getName(e){
  e.preventDefault();
  var name = document.getElementById('name1').value;//用户输入的内容
  var xhr = new XMLHttpRequest();
  xhr.open('GET','process.php?name='+name,true);
  xhr.onload = function(){
    console.log(this.responseText);
  }
  xhr.send();
}

document.getElementById('postForm').addEventListener('submit',
postName);

function postName(e){
  e.preventDefault();
  var name = document.getElementById('name2').value;//用户输入的内容
  var params ="name="+name;
  var xhr = new XMLHttpRequest();
  xhr.open('POST','process.php',true);
  xhr.setRequestHeader('Content-type','application/x-www-form-urlencoded')
  xhr.onload = function(){
    console.log(this.responseText);
  }
  xhr.send();
}
```

JavaScript random方法得到随机整数
```js
document.write(Math.ceil(Math.random()*3))  //得到1-3的整数

document.write(Math.floor(Math.random()*4)); //得到0-3的整数

Math.round() //当小数是0.5或者大于0.5的时候向上一位
Math.ceil() //始终向上一位
Math.floor() // 始终向下舍入
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

首先js里面也是有callback hell这种概念的，一个接口好了请求另一个接口，好了之后在请求第三个接口，这样一层套一层谁也不喜欢。
```js
var http = new XMLHttpRequest();
   http.onreadystatechange=function(){
       if(http.readyState==4&&http.status==200){
           console.log(JSON.parse(http.response))
       }
   };

   http.open("GET",'data/tweets.json',true);
   http.send();
```
上面这段直接在chrome里面跑的话会出错： Cross origin requests are only supported
 for protocol schemes: http, data, chrome, chrome-extension, https
 Chrome 默认不支持跨域请求，启动时要加上个flag就行了

> ajax的readyState有四种
0.  request not initialized
1. request has been set up
2. request has been set
3. request is in process
4. request is complete

ajax的open第三个参数表示是异步还是同步，一般都得异步。由于js是单线程的，
所以会把实际的网络请求工作放到一条js以外的线程中，完成后丢到当前js线程任务池的最后。 当前线程的任务完成后就可以执行这段回调


ES6提供了Promise，能够将事情简化。
xhr用Promise包装一下是这样的：
```js
//promise(ES6) is a placeholder for something that will happen in the future
function getViaPromise(url) {
    var promise = new Promise((resolve ,reject) => {
        let client = new XMLHttpRequest();
        client.open('GET',url,true);
        client.onreadystatechange = () => {
           if(client.readyState === 4 ) {
               if(client.status === 200 ){
                   resolve(client.responseText);
                  //  console.log("response of GET Arrived");
               } else {
                   var reason = { code : client.status, response: client.resonse };
                   reject(reason);
               }
           }
        };
        client.send()
    });
    return promise;
}


function postViaPromise(url ,data) {
    return new Promise((resolve,reject) => {
        let client = new XMLHttpRequest();
        client.open("POST", url ,true);
        client.setRequestHeader("Content-type","application/x-www-form-urlencoded");
        client.onreadystatechange = () => {
            if (client.readyState === 4) {
                if(client.status >=200  && client.status <=400 ){
                    resolve(client.responseText);
                    // console.log("response of POST Arrived");
                } else {
                    let reason = { 'code': client.status, "response": client.response}
                    reject(reason);
                }
            }
        }
        client.send();
    });
}

//使用的时候：
//可以把两个promise合并在一起，等到两个都执行完毕再去做一些操作
let p1 =  getViaPromise("https://jsonplaceholder.typicode.com/posts");
let data =   {
  "userId": 1,
  "id": 2,
  "title": "dumb post",
  "body": "this is some dumb post , dont care"
}     
let p2 = postViaPromise("https://jsonplaceholder.typicode.com/posts",data);

Promise.all([p1,p2]).then(values => {
  console.log(values);
});

//也可以在一个完成之后再去执行另外一个
let data =   {
  "userId": 1,
  "id": 2,
  "title": "dumb post",
  "body": "this is some dumb post , dont care"
};
let p1 =  getViaPromise("https://jsonplaceholder.typicode.com/posts");
let p2 = postViaPromise("https://jsonplaceholder.typicode.com/posts",data);
p1.then( data => {
  console.log(`data of Promise1 is ${data}` );
  return p2;
}
).then(data => {
  console.log(`data of promise2 is ${data}`);
}).catch(err => {
  console.log(err);
});
```

更加有效的方式是使用generator，还不是很了解
```js
function* gen() {
  yield 10;
}

var myGen = gen()
// myGen.done
//myGen.value()
```


## 5. ES6新增的一些东西
let(lexical)的用法就在一个循环里给function赋值，很常见。
注意的是var的作用域是跨大括号的。所以大括号里面的var是能被大括号外面访问的，let就不行。
async await 都是ES2017（比ES2015更高的版本）中出现的。
default parameters： 默认参数，和python中很像
```js
function myLog(name,age,id){

}

function myDefaultFunction(name='john',age=27,id =100){

}

// 调用：
myDefalutFunction()// 不传参也可
```


spread operator
```js
var num1 = [1,2,3]
var num2 = [num1,5,6]
console.log(num2)
// var num2 = [num1,5,6]
var num2 = [...num1,5,6] //三个点
console.log(num2)
// (5) [1, 2, 3, 5, 6]

//另外一个用处
var num3 = [1,2,3]
function acceptAnArray(a,b,c){
  console.log(a+b+c)
}

//调用
acceptAnArray(...num3) // 输出6
```

template String(这个不是引号，是在tab键上面那个)
```js
var myString = `This is an template String ,
          note we have some line break here,that will be honored. Also there are some whiteSpace afront , which will be honored too`
console.log(myString)          
var nextString = `This is `

function logLiteralString(name,age) {
  console.log(`the name is ${name} and the age is ${10+12}`);
}
// the name is hhaha and the age is 22 。 String literals.
```

String新增了一些方法
```js
var str = 'hahhaha'
console.log(str.repeat(3));
// hahhahahahhahahahhaha

var str2 = 'goodbye'
console.log(str2.startWith('good')); // true
console.log(str2.startWith('bye',4)); // true
console.log(str2.endsWith('good')); //false
console.log(str2.endsWith('good',str2.length-3)); //true

var str3 = 'Good Day'
console.log(str3.includes('Day')); //true
```

Object Literal notation
```js
// es5得这么写
var name = 'Josh'
var age = 27

var person = {
  name: name,
  age: age,
  greet: function (X) {
    console.log(`you say ${X} in your greets`);
  }
}

// es6这样就行了
var person = {
  name,age,
  greet(X){
    console.log(`you say ${X} in your greets`);
  }
}
```
简明很多

Arrow Function（箭头函数）
```js
window.onload = function () {
  var stuff = function () {
    console.log('say Stuff');
  }
  var stuff2 = () =>{
    console.log('this is more precise');
  }
  var stuff3 = () =>   console.log('只有一行的话可以不要大括号');

  var stuff4 = (name) => console.log(`the name is ${name} and hi`);

  var stuff5 = name => console.log(`只有一个参数 ${name}的话，参数的小括号也不要了`);
}
```
还有一个好处就是: the arrow function will bind the this keyword lexically.
```js
window.onload = function () {
  var jam = {
    name : 'Jane',
    greeting: function (X) {
      window.setInterval(function () {
          if (X>0) {
            console.log(this.name+' greet you');
          }
      },500)
    }
  }
  jam.greeting(3)
}
// 输出 greet you
```
原因是this已经不是jam这个object了，也就是闭包问题.es6之前用下面这种方式规避一下
```js
window.onload = function () {
  var jam = {
    name : 'Jane',
    greeting(X) {
      var _this =this;
      window.setInterval(function () {
          if (X>0) {
            console.log(_this.name+' greet you');
            X--;
          }
      },500)
    }
  }
  jam.greeting(3)
}

window.onload = function () {
  var jam = {
    name : 'Jane',
    greeting(X) {
      window.setInterval(() => {
          if (X>0) {
            console.log(this.name+' greet you');
            X--;
          }
      },500)
    }
  }
  jam.greeting(3)
}
```

class definition
es6 新增了class的概念，还有extends的概念
```js
class Band {
  constructor(name ,location) {
    this.name = name;
    this.location = location;
  }

  function greet() {
    console.log(this.name);
  }
}


class SubBand extends Band {
  construcor(name ,location,popularity) {
    super(name ,location); // this is essential , 如果后面想要使用parent 的属性的话，需要加上super()
    this.popularity = popularity;
  }
}


// 调用

let garage = new Band('john', 'Doe');
garage.greet();
```


Sets是新增的用于存储unique数据的集合(元素不能重复)
```js
var names = new Set();
names.add("josh").add('bob').add('neo')
console.log(names);
console.log(names.size);
names.delete('bob') // 返回true表示删除成功，false表示删除失败
names.clear()
names.has('bob') //就是contains的意思

var duplicatedArray = [1,2,'jane','harry',2];
var undepulicatedSet = new Set(duplicatedArray);
console.log(undepulicatedSet);
duplicatedArray = [...undepulicatedSet] //使用spread operater将set变成各个单一的元素
console.log(duplicatedArray);
```
add的时候如果存在重复元素直接无视新增的重复元素



## 6. 我也不知道归到哪一类的问题
- js语法上虽说不用加分号，但实际应用中为避免压缩js文件时出现歧义，还是得老老实实加上分号

- js 是大小写敏感的

- IIFE(Immediately Invoked Function Expression) Library use this to avoid polluting global environment
声明了之后立刻调用该函数执行

iife的例子:
```js
(function () {console.log('this is invoked!')})();

// iife的好处是只对外提供必要功能，内部成员不用暴露给外部(这在模块化里面就很重要了，作为一个module，一些内部的private method不希望对外公开，就可以用iife写，同时这也避免了polluting global nameSpace)。 Javascript模块的基本写法
var module1 = (function(){

　　　　var _count = 0;

　　　　var m1 = function(){
　　　　　　//...
　　　　};

　　　　var m2 = function(){
　　　　　　//...
　　　　};

　　　　return {
　　　　　　m1 : m1,
　　　　　　m2 : m2
　　　　};

　　})();
console.info(module1._count); //undefined

// 放大模式"（augmentation），一个模块继承另一个模块
var module1 = (function (mod){

　　　　mod.m3 = function () {
　　　　　　//...
　　　　};

　　　　return mod;

　　})(module1);

// 宽放大模式（Loose augmentation）
var module1 = ( function (mod){

　　　　//...

　　　　return mod;

　　})(window.module1 || {});
```
[Javascript模块化编程（一）：模块的写法](http://www.ruanyifeng.com/blog/2012/10/javascript_module.html)
[iife的一篇翻译的文章](http://web.jobbole.com/82520/)

Paul Irish的视频中提到了jQuery的Source中用到了这种做法。

- 如果引用一个未声明的变量，js会直接创建一个（除非使用use strict）


```js
'use strict';

new Promise(function () {});
```
use strict是什么意思？

在正常模式中，如果一个变量没有声明就赋值，默认是全局变量。严格模式禁止这种用法，全局变量必须显式声明。
```python
"use strict";

　　v = 1; // 报错，v未声明

　　for(i = 0; i < 2; i++) { // 报错，i未声明
　　}
```
意思大概就是
```js
"use strict";
x = 3.14;                // 报错 (x 未定义)但正常不会报错的
```
不允许删除变量或对象。不允许删除函数。不允许变量重名:。。。。总之感觉跟lint有点像



- undefined和null的关系
null: absence of value for a variable; undefined: absence of variable itself;
[what-is-the-difference-between-null-and-undefined-in-javascript](https://stackoverflow.com/questions/5076944/what-is-the-difference-between-null-and-undefined-in-javascript) undefined的意思是事先声明了一个var但没有给赋值，null是一个object，表示no value。
typeof(Undefined) = 'undefined', typeof('Null') = 'object'
[why-is-there-a-null-value-in-javascript](https://stackoverflow.com/questions/461966/why-is-there-a-null-value-in-javascript)
[null is a special keyword that indicates an absence of value.](https://stackoverflow.com/questions/5076944/what-is-the-difference-between-null-and-undefined-in-javascript)

```js
var foo;
defined empty variable is null of datatype undefined //这种声明了但是没给赋值的变量的值是null,数据类型是undefined

var a = '';
console.log(typeof a); // string
console.log(a == null); //false
console.log(a == undefined); // false

// 两个等号表示只检查value
var a;
console.log(a == null); //true
console.log(a == undefined); //true

// 三个等号表示既检查value也检查type
var a;
console.log(a === null); //false
console.log(a === undefined); // true

var a = 'javascript';
a = null ; // will change the type of variable "a" from string to object
```
js的数据类型包括：
Number,String,Boolean,Object,Function,Undefined和Null

js中是存在一些全局属性和全局函数的
比如Infinity(代表正的无穷大),NaN(指某个值是不是数字)
全局的函数比如decodeURI(),escape(),eval(),parseInt(),parseFloat()，这些方法不属于任何对象

这两个函数都接受String作为参数

```js
parseInt("10");  //返回 10，官方文档说返回的是integer(也就是Number了)
parseFloat("10.33") // 返回10.33
```

## 9. 交互事件的捕获，拦截，消费（冒泡）

```js
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

### 事件注册的时机
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

```js
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

## 7. 小测试
[如何用js反转一个String](https://stackoverflow.com/questions/958908/how-do-you-reverse-a-string-in-place-in-javascript)
```js
function reverse(s){
    return s.split("").reverse().join("");
}

// 另一种方式
function revserse2(s){
  let revString = "";
  for(let i = s.length; i>=0;i--) {
    revString = revString+str[i];
  }
  return revString;
}

// 用forEach的话
function reverse3(string) {
  let revString = "";
  string.split('').forEach((c) => {
    revString = c + revString;
  });
  return revString;
}

function reverse4(string){
  return string.split('').reduce(function(revString, char) {
    return char + revString;
  },'');
}
```

### 反转一个int
```js
function reverseInt(int) {
  const revString = int.toString().split('').reverse().join('');
  return parseInt(revString)*Math.sign(int);
}
```

### 首字母大写
```js
function capitalizedLetters(str){
  const strArr = str.toLowerCase().split(' ');
  for(let i=0;i<strArr.length;i++){
    strArr[i] = strArr[i].subString(0,1).toUpperCase()+
    strArr[i].subString(1);
  }
  return strArr.join(' ');
}

function capitalizedLetters2(str){
  return str
  .toLowerCase()
  .split(' ')
  .map( (word) => word[0].toUpperCase()+word.subString[1])
  .join(' ');
}
```


### how about shuffle an array
```js
/**
 * Shuffles array in place.
 * @param {Array} a items An array containing the items.
 */
function shuffle(a) {
    var j, x, i;
    for (i = a.length - 1; i > 0; i--) {
        j = Math.floor(Math.random() * (i + 1));
        x = a[i];
        a[i] = a[j];
        a[j] = x;
    }
}

// Used like so
var arr = [2, 11, 37, 42];
shuffle(arr);
console.log(arr);
```



8. js去刷新当前页面，返回上级页面。。

```html
<a href="javascript:history.go(-1)">返回上一页</a>
<a href="javascript:location.reload()">刷新当前页面</a>
<a href="javascript:" onclick="history.go(-2); ">返回前两页</a>
<a href="javascript:" onclick="self.location=document.referrer;">返回上一页并刷新</a>
<a href="javascript:" onclick="history.back(); ">返回上一页</a>
```



### 10. 监听关闭窗口事件

```js
window.onbeforeunload = function () {
       return "Bye now!"
   }
```   
[JavaScript使用哪一种编码？](http://www.ruanyifeng.com/blog/2014/12/unicode.html),不是utf-8

[atom安装插件被墙问题](http://blog.csdn.net/qianghaohao/article/details/52331432)
Atom推荐插件
[atom-beautify](https://atom.io/packages/atom-beautify)




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

8.  json object有一个prototype属性，表面其所代表的类型。


9. js迭代一个数组的方法：

```js
for (var i = 0; i < array.length; i++) {
  // array[i]
}

for (var i = 0,len=array.length; i < len; i++) {
  // array[i]
}

array.forEach(function(item){
  // item
})

// 用于列出对象所有的属性
var obj = {
    name: 'test',
    color: 'red',
    day: 'sunday',
    number: 5
}
for (var key in obj) {
    console.log(obj[key])
}
//


// es6
for (variable of iterable) {

}

array.map(function(item){

})

array.filter(function(item){

})
```
基本上就这些了[参考](https://juejin.im/post/5a3a59e7518825698e72376b)





异常捕获(try catch也有)

javaScript操作cookie:


这种方式就是给String全局添加一个方法，当然不是说推荐这么干
```js
String.prototype.hashCode = function() {
  var hash = 0,
    i,
    chr;
  if (this.length === 0) return hash;
  for (i = 0; i < this.length; i++) {
    chr = this.charCodeAt(i);
    hash = (hash << 5) - hash + chr;
    hash |= 0; // Convert to 32bit integer
  }
  return hash;
};

```
string concatnate的方法也有，然而[最快的方式](https://stackoverflow.com/questions/16696632/best-way-to-concatenate-strings-in-javascript)还是使用+=这种
```js
var hello = 'Hello, ';
console.log(hello.concat('Kevin', '. Have a nice day.'));
```

XMLHttpRequest Level 2添加了一个新的接口FormData.利用FormData对象,我们可以通过JavaScript用一些键值对来模拟一系列表单控件,我们还可以使用XMLHttpRequest的send()方法来异步的提交这个"表单".比起普通的ajax,使用FormData的最大优点就是我们可以异步上传一个二进制文件.



[FileReader api](https://developer.mozilla.org/en-US/docs/Web/API/FileReader)
```html
<head>
    <meta charset="UTF-8">
</head>

<form onsubmit="return false;">
    <input type="hidden" name="file_base64" id="file_base64">
    <input type="file" id="fileup">
    <input type="submit" value="submit" onclick="$.post('./uploader.php', $(this).parent().serialize());">
</form>

<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>
<script>
$(document).ready(function(){
    $("#fileup").change(function(){
        var v = $(this).val();
        var reader = new FileReader();
        reader.readAsDataURL(this.files[0]);
        reader.onload = function(e){
            console.log(e.target.result);
            $('#file_base64').val(e.target.result);
        };
    });
});
</script>
```

indexed db api


html里面有一些奇怪的符号
" &amp; " 在html里面等同于"&"
[ampersand](https://stackoverflow.com/questions/9084237/what-is-amp-used-for)
冒号(")会变成"  &quot;   "这种


web api有一些用的不多的东西:
File,Blob,ArrayBuffer
createObjectURL方法

TextUtils.java
```java
 /**
     * Html-encode the string.
     * @param s the string to be encoded
     * @return the encoded string
     */
    public static String htmlEncode(String s) {
        StringBuilder sb = new StringBuilder();
        char c;
        for (int i = 0; i < s.length(); i++) {
            c = s.charAt(i);
            switch (c) {
            case '<':
                sb.append("&lt;"); //$NON-NLS-1$
                break;
            case '>':
                sb.append("&gt;"); //$NON-NLS-1$
                break;
            case '&':
                sb.append("&amp;"); //$NON-NLS-1$
                break;
            case '\'':
                //http://www.w3.org/TR/xhtml1
                // The named character reference &apos; (the apostrophe, U+0027) was introduced in
                // XML 1.0 but does not appear in HTML. Authors should therefore use &#39; instead
                // of &apos; to work as expected in HTML 4 user agents.
                sb.append("&#39;"); //$NON-NLS-1$
                break;
            case '"':
                sb.append("&quot;"); //$NON-NLS-1$
                break;
            default:
                sb.append(c);
            }
        }
        return sb.toString();
    }

    /**
```

触控事件对象中包含了事件的坐标，这个有event.x,event.pageX,event.clientX等等


### 参考
[5 分钟彻底明白 JSONP](https://tonghuashuo.github.io/blog/jsonp.html)
[javaScript algorithms](https://github.com/trekhleb/javascript-algorithms)

两个关于asynchronous javaScript的视频，一个解释了Event Loop的感念，另一个讲到了Promise基于microTask的原理。
[菲利普·罗伯茨：到底什么是Event Loop呢？ | 欧洲 JSConf 2014](https://www.youtube.com/watch?v=8aGhZQkoFbQ)
[Asynchrony: Under the Hood - Shelley Vohr - JSConf EU 2018](https://www.youtube.com/watch?v=SrNQS8J67zc)

## 使用Atom的时候，按下ctrl+shift+i ，会发现原来atom编辑页面就特么是一个网页。

[javaScript自己的Utils](https://juejin.im/post/5a2a7a5051882535cd4abfce)

12. MicroTask和MacroTask的执行顺序是：Stack -> MacroTask -> MicroTask [参考](https://juejin.im/entry/59e95b4c518825579d131fad)

由于javaScript使用的是UCS-2编码（使用两个字节表示码点，只能表示Unicode基本平面内的码点），碰到emoji这类字符的时候，[string.length就靠不住了,可以使用Array.from(str).length](https://icymind.com/sizeof/)

## tbd

[ES6 Proxy]
