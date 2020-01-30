---
title: javaScript中的common mistakes
date: 2020-01-29 17:20:16
tags: [前端]
---

javaScript中的一些容易犯错的地方
![](https://www.haldir66.ga/static/imgs/guoqing_ZH-CN10903461145_1920x1080.jpg)

<!--more-->

[从w3school学到一些新的知识](https://www.w3schools.com/js/js_let.asp)

5种基本数据类型
```
string
number
boolean
object
function
```

6种object 类型
```
Object
Date
Array
String
Number
Boolean
```

两种比较特殊的，不含value的类型
null
undefined

使用typeof关键字可以查看对应的类型，typeof是一个操作符，返回值一定是一个string
```js
typeof "John"                 // Returns "string"
typeof 3.14                   // Returns "number"
typeof NaN                    // Returns "number"
typeof false                  // Returns "boolean"
typeof [1,2,3,4]              // Returns "object"
typeof {name:'John', age:34}  // Returns "object"
typeof new Date()             // Returns "object"
typeof function () {}         // Returns "function"
typeof myCar                  // Returns "undefined" *
typeof null                   // Returns "object"
typeof undefined              // Return "undefined"
```

//但是typeof无法判断一个object是不是array或者是不是date
```js
function isArray(myArray) {
  return myArray.constructor.toString().indexOf("Array") > -1;
}
//或者
function isArray(myArray) {
  return myArray.constructor === Array;
}
//Date就得这么判断
function isDate(myDate) {
  return myDate.constructor === Date;
}

Array.isArray() //The isArray() method checks whether an object is an array

//string转int，居然这也行
parseInt("10 years")
10

//一些自动的类型转换很奇怪
"5" + 2 // "52"
"5" - 2  // 3

// number转string
let n = 10.001
n.toFixed(2) // "10.00" 可以认为toFixed就是保留小数点后几位数字了
n.toFixed(3) // "10.001"
n.toPrecision(6) // "10.0030" 可以认为toPrecision是连带整数位保留几位数字

```

### 一个函数的返回值可以是多种类型
[Javascript: Different return types](https://stackoverflow.com/questions/5849256/javascript-different-return-types)

```js
somefn = function(e) {
    switch (e.type) 
    {
       case 'mousedown':
         return false;
       case 'mousemove':
         return {x:10, y:20};
    }
 };

somefn({type: 'foo'});  //undefined
```
以上函数完全可以运行


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
变量名前面加个_，例如_carname，这样get和set方法就可以用对应的名字了。
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

### js的array的一些方法，都是很早就有的
[js array](https://www.w3schools.com/js/js_array_iteration.asp)
例如map,reduce和reduceRight不会更改原有的array。



### js里面variable的类型是可以改变的
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

### 和所有的计算机语言一样都存在浮点数精确度问题
```js
var x = 0.1;
var y = 0.2;
var z = x + y            // the result in z will not be 0.3

//这是一种解决办法
var z = (x * 10 + y * 10) / 10;       // z will be 0.3
```

### variable的类型变化是自动的
下面这个例子就是object变成了array
```js
var person = [];
person["firstName"] = "John";
person["lastName"] = "Doe";
person["age"] = 46;
var x = person.length;      // person.length will return 0
var y = person[0];          // person[0] will return undefined
```

### Undefined is Not Null(如何判断一个object存在)
```js
if (typeof myObj === "undefined") // You can test if an object exists by testing if the type is undefined:

// incorrect !
if (myObj === null) //But you cannot test if an object is null, because this will throw an error if the object is undefined:

// To solve this problem, you must test if an object is not null, and not undefined.
// incorrect !
if (myObj !== null && typeof myObj !== "undefined") 

// correct。 要先判断undefined再判断null
if (typeof myObj !== "undefined" && myObj !== null) 
```

### 一种在html文件中把script tag写在底部来加快load的方式
```
Putting your scripts at the bottom of the page body lets the browser load the page first.

While a script is downloading, the browser will not start any other downloads. In addition all parsing and rendering activity might be blocked.

The HTTP specification defines that browsers should not download more than two components in parallel.
```

An alternative is to use defer="true" in the script tag. The defer attribute specifies that the script should be executed after the page has finished parsing, but it only works for external scripts.

```js
<script>
window.onload = function() {
  var element = document.createElement("script");
  element.src = "myScript.js";
  document.body.appendChild(element);
};
</script>
```


[complete es6 features](https://babeljs.io/docs/en/learn#ecmascript-2015-features)


[how-do-i-remove-a-property-from-a-javascript-object](https://stackoverflow.com/questions/208105/how-do-i-remove-a-property-from-a-javascript-object?rq=1)
[javascript clone ,shallow copy可以使用JSON.stringfy，也可以使用lodash的deepclone函数](https://stackoverflow.com/questions/122102/what-is-the-most-efficient-way-to-deep-clone-an-object-in-javascript?rq=1)

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

### Object.prototype
这些都是ES5就有的特性[prototypes](https://www.w3schools.com/js/js_object_prototypes.asp)
Object.defineProperty() is a new Object method in ES5.

It lets you define an object property and/or change a property's value and/or metadata.
```js
// Create an Object:
var person = {
  firstName: "John",
  lastName : "Doe",
  language : "NO",
};

// Change a Property:
Object.defineProperty(person, "language", {
  value: "EN",
  writable : true,
  enumerable : true,
  configurable : true
});

// Enumerate Properties
var txt = "";
for (var x in person) {
  txt += person[x] + "<br>";
}
document.getElementById("demo").innerHTML = txt;

// Adding or changing an object property
Object.defineProperty(object, property, descriptor)

// Adding or changing many object properties
Object.defineProperties(object, descriptors)

// Accessing Properties
Object.getOwnPropertyDescriptor(object, property)

// Returns all properties as an array
Object.getOwnPropertyNames(object)

// Returns enumerable properties as an array
Object.keys(object)

// Accessing the prototype
Object.getPrototypeOf(object)

// Prevents adding properties to an object
Object.preventExtensions(object)
// Returns true if properties can be added to an object
Object.isExtensible(object)

// Prevents changes of object properties (not values)
Object.seal(object)
// Returns true if object is sealed
Object.isSealed(object)

// Prevents any changes to an object
Object.freeze(object)
// Returns true if object is frozen
Object.isFrozen(object)
```

### es6的spread syntax
[Spread syntax ](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Spread_syntax)
```
Spread syntax allows an iterable such as an array expression or string to be expanded in places where zero or more arguments (for function calls) or elements (for array literals) are expected, or an object expression to be expanded in places where zero or more key-value pairs (for object literals) are expected.
```

syntax
```js
// For function calls:
myFunction(...iterableObj);
//For array literals or strings:
[...iterableObj, '4', 'five', 6]; 
// For object literals (new in ECMAScript 2018):
let objClone = { ...obj };
```

### 但是不要跟destructuring assignment混淆了
[destructuring assignment](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Destructuring_assignment)
The destructuring assignment syntax is a JavaScript expression that makes it possible to unpack values from arrays, or properties from objects, into distinct variables.
```js
let a, b, rest;
[a, b] = [10, 20];

console.log(a);
// expected output: 10

console.log(b);
// expected output: 20

[a, b, ...rest] = [10, 20, 30, 40, 50];

console.log(rest);
// expected output: Array [30,40,50]
```
像极了kotlin的triple
有了spread operator，array.push可以换一种写法
```js
const arr1 = [0, 1, 2];
const arr2 = [3, 4, 5];

//  Append all items from arr2 onto arr1
arr1 = arr1.concat(arr2);

const arr1 = [0, 1, 2];
const arr2 = [3, 4, 5];

arr1 = [...arr1, ...arr2]; 
//  arr1 is now [0, 1, 2, 3, 4, 5]
```

object的shallow clone也变了
```js
const obj1 = { foo: 'bar', x: 42 };
const obj2 = { foo: 'baz', y: 13 };

const clonedObj = { ...obj1 };
// Object { foo: "bar", x: 42 }

const mergedObj = { ...obj1, ...obj2 };// 注意这里foo被覆盖了
// Object { foo: "baz", x: 42, y: 13 }
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

[挑一个redux的reducer代码来看](https://github.com/reduxjs/redux/blob/master/examples/todos/src/reducers/todos.js) es6或者更高的语法，习惯就好
```js
const todos = (state = [], action) => { // arrow function,  参数的默认值 
  switch (action.type) {
    case 'ADD_TODO':
      return [
        ...state, // spread 就是把一个iterable object拆散 es 2018的
        {
          id: action.id,
          text: action.text,
          completed: false
        }
      ]
    case 'TOGGLE_TODO':
      return state.map(todo =>
        (todo.id === action.id)
          ? {...todo, completed: !todo.completed} // 拆开一个todo obj，返回一个新的obj,completed被覆盖？
          : todo
      )
    default:
      return state
  }
}

export default todos
```

### arrow function的syntax
Basic syntax
```js
(param1, param2, …, paramN) => { statements } 
(param1, param2, …, paramN) => expression
// equivalent to: => { return expression; }

// Parentheses are optional when there's only one parameter name:
(singleParam) => { statements }
singleParam => { statements }

// The parameter list for a function with no parameters should be written with a pair of parentheses.
() => { statements }
```


// Advanced syntax
```js
// Parenthesize the body of a function to return an object literal expression:
params => ({foo: bar})

// Rest parameters and default parameters are supported
(param1, param2, ...rest) => { statements } // 其他语言常见的var args也有
(param1 = defaultValue1, param2, …, paramN = defaultValueN) => { 
statements }

// Destructuring within the parameter list is also supported
var f = ([a, b] = [1, 2], {x: c} = {x: a + b}) => a + b + c;
f(); // 6
```


### 因为到处是undefined，所以函数的调用或者传参也有一些奇怪的语法
看上去照着shell的pipe去理解就是了
```js
obj.dispatch(someMethod(maybeUndefined || {}));

method && method()

//例如选择性的显示某个View可以这么干
<View>
  {show && <Warning style={styles.warning}>这一块只有在show的时候才会显示</Warning>}
</View>

```


### 参考
[You-Dont-Know-JS](https://github.com/getify/You-Dont-Know-JS/)

