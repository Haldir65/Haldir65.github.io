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

>webpack is basically pulling  all external js files into on build.js file that we can bundle into our html.
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
todo : webpack boilerplate
