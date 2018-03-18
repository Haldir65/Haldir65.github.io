---
title: React语法及Redux实践笔记
date: 2018-03-17 23:56:45
tags: [前端]
---

![](http://odzl05jxx.bkt.clouddn.com/image/jpg/food%20knife%20green%20kitchen%20city%20life.jpg?imageView2/2/w/600)
介绍React语法及一些Redux的使用方法
<!--more-->


***Take Away***
基本的流程就是创建一个继承React.Component的class，设定state，添加点击事件。
最重要的是在render()函数中返回一个element，比如说这样
```js
class LoginControl extends React.Component{
  constructor(props){
    super(props);
  }

  const myelement= <button>hello 这就是jsx语法 there</button>
       return(
           // <div>
           //     <Greeting isLoggedIn={isLoggedIn}/>
           //     {button}
           // </div>
           myelement // 这里把html tag提取到外面也行，写在里面也行，混着写的话，{myelement}，加上大括号就是了
           // 官方guide上的原话是: You may embed any expressions in JSX by wrapping them in curly braces(大括号).

       )
}
// return里面只能返回一个tag
```
***props是只读的***

***JSX allows embedding any expressions ,就是说jsx语句中，大括号包起来的地方，什么js都能写***





## 安装
> yarn global add create-react-app
create-react-app my-app
cd my-app
npm start

## 程序入口
在html文件中添加这样一个tag
```html
<div id="root"></div>
```
在index.js中添加这样一段
```js
const element = <h1>Hello, world</h1>;
ReactDOM.render(element, document.getElementById('root'));
```

**可以认为ReactDOM.render方法就是程序的入口**

## Element和Component的概念
Element感觉上就像一个或者多个UI控件的集合
```js
const element = <h1>Hello, world</h1>; //这就算一个Element,用于描述将要展示在屏幕上的效果
```

Component就像javaScript函数一样，它们接收任意输入，输出React element以显示在屏幕上。需要注意的是，Component的名字一定要 **首字母大写** ，因为React把小写字母开头的当做正常的html element来处理了。
```js
//一个返回Element的函数就算作是Component了
function Welcome(props) {
  return <h1>Hello, {props.name}</h1>;
}

// 或者用es6语法
class Welcome extends React.Component {
  render() {
    return <h1>Hello, {this.props.name}</h1>;
  }
}

```
还有就是props是immutable的，想要改的话用State吧。也即Component应该表现为纯粹的function，不修改状态。

## State的更改
State是在constructor里面初始化的，想要更改其中的值的话，不能直接赋值，需要使用setState方法
> this.setState({comment: 'Hello'});

但有时State的更新是异步的，所以要使用两个参数的setState方法
```js
this.setState((prevState, props) => ({
  counter: prevState.counter + props.increment
}));
```

## JSX语法
```js
const element = (
  <h1 className="greeting">
    Hello, world!
  </h1>
);
// 这俩其实是一样的
const element = React.createElement(
  'h1',
  {className: 'greeting'},
  'Hello, world!'
);

// jsx语句最终都是被用在component的return语句中的：

function WarningBanner(props) {
  if (!props.warn) {
    return null;
  }

  return (
    <div className="warning">
      Warning!
    </div>
  );
}
```



### 局部更新
页面发生变化时，React只更新需要刷新的部分


## 生命周期钩子函数
```js
componentDidMount() {
  fetchPosts().then(response => {
    this.setState({
      posts: response.posts
    });
  });

  fetchComments().then(response => {
    this.setState({
      comments: response.comments
    });
  });
}
```

## 事件处理
```js
function ActionLink() {
  function handleClick(e) {
    e.preventDefault();
    console.log('The link was clicked.');
  }

  return (
    <a href="#" onClick={handleClick}>
      Click me
    </a>
  );
}

const element = <h1>Hello, world</h1>;
ReactDOM.render(<ActionLink/>, document.getElementById('root'));

// 或者是使用箭头函数 以及  Function.prototype.bind
<button onClick={(e) => this.deleteRow(id, e)}>Delete Row</button>
<button onClick={this.deleteRow.bind(this, id)}>Delete Row</button>

//在一个Component中，时间监听最后要加上bind(this)
class Calculator extends React.Component {
  constructor(props) {
    super(props);
    this.handleChange = this.handleChange.bind(this);
    this.state = {temperature: ''};
  }

  handleChange(e) {
    this.setState({temperature: e.target.value});
  }

  render() {
    const temperature = this.state.temperature;
    return (
      <fieldset>
        <legend>Enter temperature in Celsius:</legend>
        <input
          value={temperature}
          onChange={this.handleChange} />

        <BoilingVerdict
          celsius={parseFloat(temperature)} />

      </fieldset>
    );
  }
}
```

## 组件之间通信
In React, sharing state is accomplished by moving it up to the closest common ancestor of the components that need it. 也就是说，要把state提取到最近的公用父组件中。事件发生时，子组件调用this.props.onXXX(由父组件提供)通知父组件，子组件不再维护自身state，父组件的state成为两个子组件唯一的共有的single source of truth



渲染list的时候记得要加上一个key，这是规定
```js
//错误
const listItems = numbers.map((number) =>
  <li>{number}</li>
);

//正确
const listItems = numbers.map((number) =>
  <li key={number.toString()}>{number}</li>
);
//一个List element中的list元素应当具有独一无二的key，但不同List element实例之间，元素的key没必要遵守这一规则


```

## 常见错误
> Super expression must either be null or a function, not undefined
```js
class LoginControl extends component{

}
// 应该是
class LoginControl extends React.Component{

}
```
