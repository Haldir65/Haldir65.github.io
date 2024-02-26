---
title: React语法及Redux实践笔记
date: 2018-03-17 23:56:45
tags: [前端]
---

![](https://api1.reindeer36.shop/static/imgs/food-knife-green-kitchen-city-life.jpg)
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


```js
//支持纯函数式的Component
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

## State的更改
State是在constructor里面初始化的，想要更改其中的值的话，不能直接赋值，需要使用setState方法
> this.setState({comment: 'Hello'});

[setState](https://reactjs.org/docs/react-component.html#setstate)方法其实有第二个optional参数，是callback.这个callback会在render完成之后执行
```
The second parameter to setState() is an optional callback function that will be executed once setState is completed and the component is re-rendered. Generally we recommend using componentDidUpdate() for such logic instead.
```

> React does not guarantee that the state changes are applied immediately.//可能是异步的,多次setState可能会别batch。

```
This makes reading this.state right after calling setState() a potential pitfall. Instead, use componentDidUpdate or a setState callback (setState(updater, callback)), either of which are guaranteed to fire after the update has been applied.
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
页面发生变化时，React只更新需要刷新的部分。从视觉上来看，state更改之后，确实是局部刷新。


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

```js
As of react v16.3.2 these methods are not "safe" to use:

componentWillMount
componentWillReceiveProps
componentWillUpdate
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

//在一个Component中，事件监听最后要加上bind(this)
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

[react推荐使用组合而不是继承来实现code reuse](https://reactjs.org/docs/composition-vs-inheritance.html)
组件的props中有一个特殊的key(children),可以理解为直接在一个组件上设置内部的内容。实际上,props可以添加其他的key以容纳多个children
```js
function FancyBorder(props) {
  return (
    <div className={'FancyBorder FancyBorder-' + props.color}>
      {props.children}
    </div>
  );
}

//例如下面的例子，FancyBorder里面的内容实际上就等于上面的props.children
function WelcomeDialog() {
  return (
    <FancyBorder color="blue">
      <h1 className="Dialog-title">
        Welcome
      </h1>
      <p className="Dialog-message">
        Thank you for visiting our spacecraft!
      </p>
    </FancyBorder>
  );
}
```
可以这样做的原因是components可以接受任何形式的props，例如基本数据类型，react elemets，以及函数
> Remember that components may accept arbitrary props, including primitive values, React elements, or functions.

```js
class SignUpDialog extends React.Component {
  constructor(props) {
    super(props);
    this.handleChange = this.handleChange.bind(this); //为什么这里要写一句bind(this)，因为如果不加的话，handleChange方法里的this将会是这个
    this.handleSignUp = this.handleSignUp.bind(this);
    this.state = {login: ''};
  }

  render() {
    return (
      <Dialog title="Mars Exploration Program"
              message="How should we refer to you?">
        <input value={this.state.login}
               onChange={this.handleChange} />

        <button onClick={this.handleSignUp}>
          Sign Me Up!
        </button>
      </Dialog>
    );
  }

  handleChange(e) {
    this.setState({login: e.target.value});
  }

  handleSignUp() {
    alert(`Welcome aboard, ${this.state.login}!`);
  }
}
```

### redux的一些点
react-redux和redux的源码都很短，但是js语法写的非常6🍉
enhancer（典型如applyMiddleWare）

reducer的定义
> Speaking of the code that uses the action to update our application state, in Redux terminology this part is called a "reducer."


react-redux的connect方法主要就是能够让UI Component里面可以免去持有store，而是通过一个mapDispatchToProps去发起事件




## 参考
[redux tutorial](https://read.reduxbook.com/markdown/part1/05-middleware-and-enhancers.html)







