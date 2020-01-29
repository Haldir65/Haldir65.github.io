---
title: javaScript中的common mistakes
date: 2020-01-29 17:20:16
tags: [前端]
top : 1
---

javaScript中的一些容易犯错的地方
![](https://www.haldir66.ga/static/imgs/guoqing_ZH-CN10903461145_1920x1080.jpg)

<!--more-->

[从w3school学到一些新的知识](https://www.w3schools.com/js/js_let.asp)

[Hoisting is JavaScript's default behavior of moving all declarations to the top of the current scope (to the top of the current script or the current function](https://www.w3schools.com/js/js_hoisting.asp) 一个变量可以先使用再声明（使用var关键字的话），但是Variables and constants declared with let or const are not hoisted!

### js中的this
In HTML event handlers, this refers to the HTML element that received the event:
```html
<button onclick="this.style.display='none'">
  Click to Remove Me!
</button>
```
但是使用apply和call也可以改变this的语义
```js
var person1 = {
  fullName: function() {
    return this.firstName + " " + this.lastName;
  }
}
var person2 = {
  firstName:"John",
  lastName: "Doe",
}
person1.fullName.call(person2);  // Will return "John Doe"
```

**With a regular function this represents the object that calls the function:**
**With an arrow function this represents the owner of the function:**

### let和var的一个重要区别就是block scope
```js
{
  var x = 2;
}
// x CAN be used here

{
  let x = 2;
}
// x can NOT be used here
```

```js
var i = 5;
for (var i = 0; i < 10; i++) {
  // some statements
}
// Here i is 10

let i = 5;
for (let i = 0; i < 10; i++) {
  // some statements
}
// Here i is 5
```

### prototype的意思大概就是动态的给一个object添加instance方法或者field。不是static方法

### ES6的class的可以添加get和set方法
```js
class Car {
  constructor(brand) {
    this.carname = brand;
  }
  get cnam() {
    return this.carname;
  }
  set cnam(x) {
    this.carname = x;
  }
}

mycar = new Car("Ford");
mycar.cnam;
mycar.cnam();//不需要这样写
```
另外，get和set方法不能取和fieldName一样的，例如这里的carname()，所以很多开发者喜欢这么干
变量名前面加个_，例如_carname，这样就可以用getcarname了。
```js
class Car {
  constructor(brand) {
    this._carname = brand;
  }
  get carname() {
    return this._carname;
  }
  set carname(x) {
    this._carname = x;
  }
}

mycar = new Car("Ford");
mycar.carname;//这样就可以了
```

### string和String("")还是有点区别的
```js
var x = "John";             
var y = new String("John");
(x === y) // is false because x is a string and y is an object.

var x = new String("John");             
var y = new String("John");
(x == y) // is false because you cannot compare objects.
```
所以尽量使用primitives，不要使用Number, String,Boolean这种object
```
Use {} instead of new Object()
Use "" instead of new String()
Use 0 instead of new Number()
Use false instead of new Boolean()
Use [] instead of new Array()
Use /()/ instead of new RegExp()
Use function (){} instead of new Function()
```

### js里面varibale的类型是可以改变的
```js
var x = "Hello";     // typeof x is a string
x = 5;               // changes typeof x to a number
```

### es6里面函数的argument可以带default参数
```js
function (a=1, b=1) { /*function code*/ }
```

### 不要用eval，不安全


### 使用if的时候要注意
```js
var x = 0;
if (x = 0)
```
因为这是一个assignment,而An assignment always returns the value of the assignment.所以等同于true


### switch case用的比较是===
```js
var x = 10;
switch(x) {
  case 10: alert("Hello");
}

// 不生效
var x = 10;
switch(x) {
  case "10": alert("Hello");
}
```

### floating point number精确度问题
```js
var x = 0.1;
var y = 0.2;
var z = x + y            // the result in z will not be 0.3
```

[you don't know complete es6 features](https://babeljs.io/docs/en/learn#ecmascript-2015-features)
[如何处理touch event](https://facebook.github.io/react-native/docs/gesture-responder-system) react native把这个称之为gesture


[how-do-i-remove-a-property-from-a-javascript-object](https://stackoverflow.com/questions/208105/how-do-i-remove-a-property-from-a-javascript-object?rq=1)
[javascript clone ,shallow copy可以使用JSON.stringfy可以使用lodash的deepclone函数](https://stackoverflow.com/questions/122102/what-is-the-most-efficient-way-to-deep-clone-an-object-in-javascript?rq=1)

[strict-mode](https://stackoverflow.com/questions/1335851/what-does-use-strict-do-in-javascript-and-what-is-the-reasoning-behind-it?rq=1)
[ In JavaScript, if you use the function keyword inside another function, you are creating a closure](https://stackoverflow.com/questions/111102/how-do-javascript-closures-work?rq=1) 
[js 的function的bind方法](https://stackoverflow.com/a/10115970) 例如给document的一个element添加点击callback的时候，click方法中的this已经不是所预想的this了，因此，需要bind(this)，当然有了arrow function之后，不需要bind了
```js
Button.prototype.hookEvent(element) {
  // Use bind() to ensure 'this' is the 'this' inside click()
  element.addEventListener('click', this.click.bind(this));
};

//OR
Button.prototype.hookEvent(element) {
  // Use a new variable for 'this' since 'this' inside the function
  // will not be the 'this' inside hookEvent()
  var me = this;
  element.addEventListener('click', function() { me.click() });
}

//OR 
Button.prototype.hookEvent(element) {
  // => functions do not change 'this', so you can use it directly
  element.addEventListener('click', () => this.click());
}
```


let和var的区别也在这里有体现
```js
function buildList(list) {
    var result = [];
    for (var i = 0; i < list.length; i++) { // 把var换成let就不会都变成2了
        var item = 'item' + i;
        result.push( function() {console.log(item + ' ' + list[i])} );
    }
    return result;
}

function testList() {
    var fnlist = buildList([1,2,3]);
    // Using j only to help prevent confusion -- could use i.
    for (var j = 0; j < fnlist.length; j++) {
        fnlist[j]();
    }
}

 testList() //logs "item2 undefined" 3 times
```


[一些代码规范](https://www.w3schools.com/js/js_conventions.asp) 这些只是习惯，一些推荐的设置，不强求。各个语言社区都有自己的规范。
```
Underscores:

Many programmers prefer to use underscores (date_of_birth), especially in SQL databases.

Underscores are often used in PHP documentation.

PascalCase:

PascalCase is often preferred by C programmers.

camelCase:

camelCase is used by JavaScript itself, by jQuery, and other JavaScript libraries.
```


### 参考
[You-Dont-Know-JS](https://github.com/getify/You-Dont-Know-JS/)

