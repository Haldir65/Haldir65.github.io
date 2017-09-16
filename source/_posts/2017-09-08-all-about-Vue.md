---
title: VueJs学习笔记
date: 2017-09-08 21:41:43
tags: [javaScript,Vue]
---

Vue Js学习笔记
![](http://odzl05jxx.bkt.clouddn.com/VueJsLogo.jpg)
<!--more-->



## 1. 前提
使用cmder ,安装了nodejs 
基本命令 
- npm install 
- npm run dev

参考系列[教程](https://github.com/iamshaunjp/vuejs-playlist)



import语法:从别的vue文件中导入数据：
import Data from ./xxx/stuff.vue
其实和python很像

一些常用的标签
- template 标签用于显示模板，内部可以使用{{data}}获取json对象的数据
- data 标签用于存储json类型的数据
- methods 标签用于声明方法，内部使用this.xxx可以获得data中的json对象
- components 标签用于引入可复用的模板,用于注册
- computed computed就像一个template的一个属性


一些常用的事件绑定: 
- v-if='' //控制某个tag显示或者隐藏
- v-on:click='somefunction' //点击事件发生时触发某个method
- template v-is='some_template_name' //用于在页面模板中导入现成的模板



### 1.1 Dynamic Components
页面中需要随时展示不同template是，可以使用component标签。
```html

// Imports
import formOne from './components/formOne.vue';
import formTwo from './components/formTwo.vue';

<form-one></form-one> 
//这和下面这种写法是一样的
 <component v-bind:is='component'></component> //component标签注册在data中，可以随时改变。例如
 <button v-on:click="component='form-one'">Show form one</button>
 <button v-on:click="component='form-two'">Show form two</button>

```

### 1.2 InputBinding
将input标签中用户输入的文字显示在一个tag中
```html
//在template中
<input type="text" v-model.lazy='title' required/> //lazy是指preview部分只会在点击后显示内容
//在data中注册
data () {
    return {
      title :'',
      content: ''
    }
  }
在需要展示内容的标签中可以实时获取内容
如<p>{{title}}</p>>  

或者
data () {
    return {
      blog:{
      title :'',
      content: '',
      categories:[]
      }  
    }
  }
```
data中返回的是一个json object，json本身的定义就是(JavaScript Object Notation)。这样做的好处是可以将所有需要的变量存储在一个object,当然，这里面存数组也是可以的。

### 1.3 Checkbox Binding

```html
<div id="checkboxes">
    <label>Apple</label>
    <input type="checkbox" value="apple" v-model="blog.categories">
    <label>Juice</label>
    <input type="checkbox" value="juice" v-model="blog.categories">
    <label>Panda</label>
    <input type="checkbox" value="panda" v-model="blog.categories">
    <label>rocky</label>
    <input type="checkbox" value="rocky" v-model="blog.categories">
    <label>moon</label>
    <input type="checkbox" value="moon" v-model="blog.categories">
</div>

在预览区，可以这样展示
  <ul>
    <li v-for='cat in blog.categories'>{{cat}}</li>
  </ul>
 如果checkbox被选中，blog的categories数组中就加入了这个元素，取消选中则从数组中移除。 
```


### 1.4 Select Box Binding
SelctBox只能单选，绑定数据这样:
```html
<select v-model='blog.author'>
    <option v-for='a in authors' >{{a}}</option>
</select>

data{
    blog:{
        author:'default'
    },
    authors:['bob','Jessy','Jean','Jean','Dave']
}
```
SelectBox会从authors数组中提供选项，选中后，blog.author对象将会被赋予相应的值。




## 2.使用Http进行CURD操作
安装：[Repo](https://github.com/pagekit/vue-resource)
注意：需要在当前工作目录.
安装完成在package.json中看到
- "dependencies": {
    "vue": "^2.3.3",
    "Vue-resource":"^1.3.4"
  },
类似这样即可。

### 2.1 进行POST操作
[jsonPlaceHolder](https://jsonplaceholder.typicode.com/)是一个免费的API网站。
vue-resource提交表单的操作如下:
```javaScript
  post:function () {
      //use http here
      this.$http.post('https://jsonplaceholder.typicode.com/posts',{
        title:this.blog.title,
        body:this.blog.content,
        userId:1,
      }).then(function (data) {
        // body...
        console.log(data)
        this.summited = true
      });
    }
```
post方法返回的是一个promise，加回调即可打印出api返回结果。

### 2.2 ajax跨域操作
[XMLHttpRequest cannot load http://localhost:5000/hello. 
No 'Access-Control-Allow-Origin' header is present on the requested resource.](https://stackoverflow.com/questions/25860304/how-do-i-set-response-headers-in-flask)
用Flask做后台，大概的代码这样
```python
@app.route("/posts", methods=['GET'])
def create_post()
    resp = Response(json.dumps(post_lists), mimetype='application/json')
    resp.headers['Access-Control-Allow-Origin'] = '*'
    return resp    
```



## 3. Router
安装:
> npm install vue-router --save

---------------------------------------------------


###  基础复习
1. id和class的问题
html tag的class，不同tag可以有相同的class，引用的时候用.classname来查找
id这个tag唯一的，一个页面不能有两个tag有相同的id，引用的时候用#id来找
一个是点，一个是#
2. js 里面有一个promise的概念，和java8的一些流式理念有点像
3. 关闭ESlint，[Eslint](https://jingyan.baidu.com/article/4b52d702b5f490fc5d774b10.html)实在是太严格了，有点妨碍开发效率



![](http://odzl05jxx.bkt.clouddn.com/image/jpg/1102531047-2.jpg?imageView2/2/w/600)

## 参考
1. [Vue JS 2 Tutorial](https://www.youtube.com/watch?v=5LYrN_cAJoA&list=PL4cUxeGkcC9gQcYgjhBoeQH7wiAyZNrYa)
2. [github repo](https://github.com/iamshaunjp/vuejs-playlist)
3. [jsonPlaceHoder](https://jsonplaceholder.typicode.com/)
4. [css](https://mp.weixin.qq.com/s/wYTejsTjHldDMKJ7QqCYBA)

