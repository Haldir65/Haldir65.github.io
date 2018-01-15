---
title: Webpack资源汇总
date: 2018-01-14 22:56:46
tags: [前端]
---

![](http://odzl05jxx.bkt.clouddn.com/image/jpg/hot coffee city life winter.jpg?imageView2/2/w/600)
<!--more-->


## 1.安装
yarn add webpack

## 2.使用
>
webpack is basically pulling  all external js files into on build.js file that we can bundle into our html.
这样做的好处很多，能够有效减少浏览器发出的请求数量。

minify js(删掉所有的空行) webpack -p即可

## 3. webpack.config.js
一个基本的config长这样
```javaScript
module.exports = {
    entry: './app.js',
    output: {
        filename: "./bundle.js"
    },
    watch: true,
    module:{
        rules: [
           {
            test: /\.js$/,
            exclude: /(node_modules|bower_components)/,
            use: {
                loader: 'babel-loader',
                options: {
                  presets: ['babel-preset-env']
                }
              }
           },
           {
            test: /\.css$/,
            use: [ 'style-loader', 'css-loader' ]
          }
        ]
    }
}
```

## 4. babel
首先需要知道的是mudule.exports那一套在浏览器里是不支持的。会出现"require is undefined..."。解决办法也有，安装babel就行了。
babel的作用是把es2015的代码编译成es5的代码, 安装方式
> yarn add babel-cli babel-preset-env

然后创建一个.babelrc文件
```json
{
  "presets": ["env"]
}
```

package.json中添加script:
babel : "babel"
命令行 ： npm run babel -- index.js -o bundle.js -w


## 5. loaders





## 6. babel, css precomiler


## 7. react cli

=======================================================================================================
> babel-node "index.js" "-o" "bundle.js" "-w" "source-maps"  // o的意思是输出文件 -w的意思是watch文件变化，babel要改成babel-node

babel能够把**一个**ES2015文件编译成**一个**es5的js文件。但假如有一大堆es2015文件，想要整合到一个es5文件中的话，就需要module loaders了。
webpack是一个module bundler(module loader),其作用就是把项目中所有的零散的文件整合到一个文件中。常见的包括gulp和webpack，后者更popular。
首先安装：
yarn add webpack babel-core babel-loader
```js
module.exports = {
    entry: './index.js',
    output: {
        path: __dirname,
        filename: 'bundle.js'
    },
    watch : true,
    module: {
        loaders: [
            {
                loader: "babel-loader",
                exclude: "/node_modules/"
            }
        ]
    }
}
```


webpack.config.js配置举例
webpack-dev-server 使用教程（本地起一个服务器，修改了js文件，不用在浏览器里F5，自动帮你刷新）[教程](https://www.youtube.com/watch?v=s1UdeDaEKo4) hot module replacement的概念就是，不是简单粗暴window.refresh。而是只刷新改动的一小点。
