---
title: VueJs学习笔记
date: 2017-09-08 21:41:43
tags: [javaScript,Vue,前端]
---

Vue Js学习笔记

![](http://odzl05jxx.bkt.clouddn.com/image/jpg/scenery1511100775410.jpg?imageView2/2/w/600)

<!--more-->


>  有句话放在前面，所有的javaScript库都比不上Vanilla JS，即原生js代码。

## 1. 前提
使用cmder ,安装了nodejs
基本命令
- npm install
- npm run dev

npm 设置淘宝镜像
> npm config set registry https://registry.npm.taobao.org

或者直接用本地ss代理[设置proxy](https://stackoverflow.com/questions/7559648/is-there-a-way-to-make-npm-install-the-command-to-work-behind-proxy)
> npm config set strict-ssl false
> npm config set registry "http://registry.npmjs.org/"
> npm config set proxy http://127.0.0.1:1080 ## 以上三句话设置代理
> npm config list ##列出当前所有的设置
> npm config get stuff ##比如说registry等等

上面的npm run run dev只是为了方便本地开发，具有live reload功能。实际生产环境中，需要在CI服务器上运行
> npm run build

然后把dist文件夹中的静态文件推送到正式服务器
在本地起nginx，设置好config,port,location什么的，然后把dist文件夹下所有东西复制到ngix config的目录下。

```
error_page   500 502 503 504  /50x.html;
location = /50x.html {
    root   html;
}
```
然后直接在浏览器里面localhost打开查看，这是生产环境的大致描述，实际过程中代码还需要经历开发机器，编译机器，测试机器，cdn机器等等环节。



import语法:从别的vue文件中导入数据：
import Data from ./xxx/stuff.vue
其实和python很像

一些常用的标签
- template 标签用于显示模板，内部可以使用{{data}}获取json对象的数据
- data 普通属性，标签用于存储json类型的数据，是属于这个实例的变量
- methods 标签用于声明方法，内部使用this.xxx可以获得data中的json对象。在html里面不需要this，在export语句里面需要
- components 标签用于引入可复用的模板,用于注册
- computed 计算属性，computed和data一样，也是方法，只不过只是返回了变量的值的一份copy。不会影响data的值


```
var vm = new Vue({
  el: '#example',
  data: {
    message: 'Hello'
  },
  computed: {
    // 计算属性的 getter
    reversedMessage: function () {
      // `this` 指向 vm 实例
      return this.message.split('').reverse().join('')
    }
  }
})
```
你可以像绑定普通属性一样在模板中绑定计算属性。Vue 知道 vm.reversedMessage 依赖于 vm.message，因此当 vm.message 发生改变时，所有依赖 vm.reversedMessage 的绑定也会更新。而且最妙的是我们已经以声明的方式创建了这种依赖关系：计算属性的 getter 函数是没有副作用 (side effect) 的，这使它更易于测试和理解。
普通属性更改的话就真的改了，计算属性只是把这种操作预期的结果返回，并不会修改原来的值。
还有一个好处是，计算属性的值依赖于普通属性的值，前者不更改的话，后者直接返回缓存的值。所以这种获取时间的东西就不要放在计算属性里了。
```
computed: {
  now: function () {
    return Date.now()
  }
}
```


一些常用的事件绑定:
- v-if='' //移除或者显示某个Tag，(display:none是隐藏或显示)
- v-on:click='somefunction' //点击事件发生时触发某个method
- template v-is='some_template_name' //用于在页面模板中导入现成的模板

缩写：
- v-on的缩写是@符号
- v-bind:的缩写就是: 那个冒号

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



### 1.5 HTML模板复用
组件的意义就在于可以复用UI元素，就像Flask的renderTemplate方法里面可以接收若干参数，vue Component也是一样
```
1. 在父Component中引入子Component
2. 子Component中添加props:['variable1','variable2']数组
3. 在父控件中直接在html标签上添加 :variable1 ='' ，注意这个冒号其实是  v-bind: 的缩写，不能省略
4. 在子控件的html中就像引用data一样使用props
```

### 1.6各种引用
在vue组件中this指的是当前的VueComponent（也就是常说的vm），self指的是window对象，this.$el指的是所渲染的template

### 1.7 嵌套路由破坏了静态资源的引用路径
[nested-routes-breaks-the-static-path](https://stackoverflow.com/questions/45133669/nested-routes-breaks-the-static-path)
解决方法是在 html中置顶css或js等静态资源的location，从绝对路径，根路径开始



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
<!--
```python
@app.route("/posts", methods=['GET'])
def create_post()
    resp = Response(json.dumps(post_lists), mimetype='application/json')
    resp.headers['Access-Control-Allow-Origin'] = '*'
    return resp    
``` -->

## 3. Router,Eventbus,mixin，axios等

安装:
> npm install vue-router --save
> npm install vue-bus --save
---------------------------------------------------
### 3.1 关于Bus， 是用来在不同的Vue文件中传递事件(数据)用的，安装好后，main.js里面improt并使用
> import Vue from 'vue'
> import VueBus from 'vue-bus';
> Vue.use(VueBus);

A.vue中
``` javaScript
created(){
  this.$bus.emit('loadSuccess', '创建成功！');
},
beforedestory(){
  this.$bus.off('loadSuccess')
}
 // B.vue中
created(){
  this.$bus.on('loadSuccess',text=> {
      console.log('receieve msg from another vue component '+ text)
  })
}
```

3.2 关于mixin，有比较好的[介绍](https://css-tricks.com/using-mixins-vue-js/)
其实就是把一些公用的methods放到一个js文件中export掉，然后需要的vue文件，自己去import，在data中设置mixins: [] ,使用的时候就可以用this.method()使用这些共有的方法了。其实主要是为了复用。

3.3 添加全局变量(常量)的[方法](http://www.jianshu.com/p/7547ff8760c3)，vuex是官方的


3.4 router就是建立internal link 页面之间跳转的桥梁
在template中添加router-link的tag,会生成一个对应的a Tag,点击跳转即可。
router-view标签表示预先准备好的布局会被渲染进入这个标签内（将其取代）

3.5 axios取代vue-resource用于发起http请求
安装在官方介绍页有，子组件可以使用import从mainjs里面拿到。
于是，尝试在一个component里面去获取百度首页，结果出错，换成豆瓣电影250还是出错：
```
about:1 Failed to load http://api.douban.com/v2/movie/top250: Response to preflight request doesn't pass access control check: No 'Access-Control-Allow-Origin' header is present on the requested resource. Origin 'http://localhost:8080' is therefore not allowed access.
```
查了好久，原因是CORS(Control of Shared Resources)，通过ajax发起另一个domian(port)资源的请求默认是不安全的。主要是在js里面代码请求另一个网站(只要不满足host和port完全相同就不是同一个网站)，默认是被[禁止](http://www.ruanyifeng.com/blog/2016/04/cors.html)的。chrome里面查看network的话，发现这条request确实发出去了，request header里面多了一个
> Origin:http://localhost:8080
显然这不是axios设置的，在看到这条header后，如果'/movie/top250'这个资源文件没有设置'Access-Control-Allow-Origin: http://localhost:8080'的话，浏览器就算拿到了服务器的回复也不会允许被开发者获取。这是CORS做出的策略，也是前端开发常提到的跨域问题。
解决方法：
1.和服务器商量好CORS
2.使用jsonp(跨域请求并不限制带src属性的tag，比如script img这些)
3. 使用iframe跨域

CORS还是比较重要的东西，[详解](http://www.ruanyifeng.com/blog/2016/04/cors.html)，据说会发两次请求,且只支持GET请求。

回到axios，作者表示[不打算支持jsonp](https://github.com/axios/axios/issues/75)，想用jsonp的话可以用jquery,或者使用[jsonp插件](https://github.com/axios/axios/blob/master/COOKBOOK.md#jsonp)
```javaScript
 $ npm install jsonp --save
 var jsonp = require('jsonp');

jsonp('http://api.douban.com/v2/movie/top250', null, function (err, data) {
  if (err) {
    console.error(err.message);
  } else {
    console.log(data);
  }
});
```
亲测有效。

take aways:
```javaScript
##同源：
$.ajax({
    url:"persons.json",
    success:function(data){
　　　　console.log(data);
　　 　 //ToDo..
　 }
});

##跨域：
$.ajax({
    url:"http://www.B.com/open.php?callback=?",
    dataType:"jsonp",
    success:function(data){
        console.log(data);
        //ToDo..
    }
});
```
其实一开始没有callback=?这些个东西的，http://www.B.com/open.js 这个链接就是一个简单的js
```javaScript
foo({"name":"B","age":23});
```
所以A网站往document里面写一个script之后，直接就执行了A网站的foo() function。 但假如B网站还对C网站提供服务，C网站说foo()这个方法名已经被占用了。所以B就约定，不管是A,B,C D哪家网站，想要调各自的什么方法自己传上来，B负责调用以下。因为jsonp只能是GET，所以只好放在queryParameters里面了。[为什么叫callback的原因我也是最近才想清楚的](https://juejin.im/entry/5a45b363f265da431c709fc7)
上面那个callback不一定非要写callback，其实写什么都行，主要看对方网站是怎么定义的。就是对方这个链接是怎么拿这个url里面的queryParams的。


*XSS注入就是利用了CORS*

## 4. Vuex及状态管理
在js眼中，一段json字符串就是一个object。
这是vuex 中改变某项属性的代码：
```javaScript
mutations: {
  increment (state, payload) {
    state.count += payload.amount
  }
}
store.commit('increment', {
  amount: 10
})
两个花括号括起来的(json)，才是对象。这里，函数名叫做'increment'，传进去的payLoad即有效信息，是通过json转达的。
```

## 事件处理
点击时会发生MouseEvent,如果想要获取这里面的一些属性，比如点击位置screenX,ScreenY这些，可以在html中绑定事件时，使用$event这个符号将事件传递到方法中。


###  基础复习
1. id和class的问题
html tag的class，不同tag可以有相同的class，引用的时候用.classname来查找
id这个tag唯一的，一个页面不能有两个tag有相同的id，引用的时候用#id来找
一个是点，一个是#
2. js 里面有一个promise的概念，和java8的一些流式理念有点像
3. 关闭ESlint，[Eslint](https://jingyan.baidu.com/article/4b52d702b5f490fc5d774b10.html)实在是太严格了，有点妨碍开发效率
4. html中audio tag不识别本地文件，需要放在static文件下，放在src文件夹里就是404，一开始的时候我这么写"src='../assets/赵雷-成都.mp3'"，死活放不出来，换成"file://"开头也不行，换成网易云音乐的http地址就好了。最后换成'static目录下'。终于放出来了，“让我掉下眼泪的是，简直日了X”，还蛮押韵的。
5. atom可以同时预览两个选项卡，右键,split right，用于copy and paste比较方便
6. css里面可以写"background-image: url(./somefile.png)"，就是相对路径的意思。

10.css里面的class继承是同时在一个tag里面添加class="class_a class_b"，中间一个空格，需要什么拿什么
11. css分三种，外部样式表（写在另一个css文件里），内部样式表(写在header tag中)和内联样式表(写在单独的tag里面)


### 日常开发出错记录
1. [Vue warn]: Property or method is not defined on the instance but referenced during render](https://stackoverflow.com/questions/42908525/vue-warn-property-or-method-is-not-defined-on-the-instance-but-referenced-dur)。原来是template里面的html某个元素里面调用了XXX，而这个XXX并没有在当前Vue实例中声明。
2. [Cannot read property 'state' of undefined](https://forum.vuejs.org/t/vuex-error-state/1879/6).这其实就是在vue component中访问this.$store ===undefines了，需要确保Vue的声明中
```js
// root instance
new Vue({  // eslint-disable-line no-new
    el: "#app",
    store,
    router,
    render: h => h(App)
})
```
3.


### tools,tangiable takeaways
 1. atom plugin  ide-typescript sucks , after disable the plugin ,the autocomplete feature works againself.
 2. config atom behind a firewall :
 > apm config set https-proxy https://127.0.0.1:1080
  apm config set strict-ssl false


 官方的库
 Vuex是负责全局状态管理的，[参考](http://whutzkj.space/2017/10/24/vuex/#more)
 组件间[通信](https://juejin.im/post/59ec95006fb9a0451c398b1a)的方式





![](http://odzl05jxx.bkt.clouddn.com/image/jpg/1102531047-2.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/VueJsLogo.jpg)

## 参考
1. [Vue JS 2 Tutorial](https://www.youtube.com/watch?v=5LYrN_cAJoA&list=PL4cUxeGkcC9gQcYgjhBoeQH7wiAyZNrYa)
2. [github repo](https://github.com/iamshaunjp/vuejs-playlist)
3. [jsonPlaceHoder](https://jsonplaceholder.typicode.com/)
4. [css](https://mp.weixin.qq.com/s/wYTejsTjHldDMKJ7QqCYBA)
5. [Sass](https://zh.wikipedia.org/wiki/Sass)
6. [JavaScript 教程](http://www.w3school.com.cn/jsref/jsref_obj_array.asp)
7. [ES6相关](https://wohugb.gitbooks.io/ecmascript-6/content/docs/array.html)
8. [css教程](https://www.w3cschool.cn/css/css-padding.html)
9. [widgets](https://medium.com/the-web-tub/improve-ux-with-swiping-tab-bar-using-onsen-ui-for-vue-4c7d0e5171f0)
10. [2018 我所了解的 Vue 知识大全（一）](https://juejin.im/post/5a4b78226fb9a0451a76c1a1)
