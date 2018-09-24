---
title: Webpack资源汇总
date: 2018-01-14 22:56:46
tags: [前端]
---

![](https://www.haldir66.ga/static/imgs/hot%20coffee%20city%20life%20winter.jpg)
<!--more-->


使用webpack的一个好处是，浏览器的并发请求资源数是有一个上限的，把所有资源打成一个包，能够减少请求数量。webpack更新的速度是真快，目前(2018年9月最新版本已经到4.19)

## 1.安装
> yarn add webpack

## 2.使用

>webpack is basically pulling  all external js files into on build.js file that we can bundle into our html.
这样做的好处很多，能够有效减少浏览器发出的请求数量。

webpack -p即可

## 3. webpack.config.js
从[webpack-example](https://github.com/WsmDyj/webpack)copy一个webpack.config.js过来，基本可以搞定es6,less,hot-reload,css-plugin还有asset文件copy这些常见的需求。
首先是package.json
```json
{
  "name": "try-webpack",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "build": "webpack --mode production",
    "start": "webpack-dev-server --mode development"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "devDependencies": {
    "babel-core": "^6.26.3",
    "babel-loader": "^7.1.5",
    "babel-preset-env": "^1.7.0",
    "copy-webpack-plugin": "^4.5.2",
    "css-loader": "^1.0.0",
    "extract-text-webpack-plugin": "^4.0.0-beta.0",
    "file-loader": "^1.1.11",
    "html-webpack-plugin": "^3.2.0",
    "less": "^3.7.0",
    "webpack": "^4.15.1",
    "webpack-cli": "^3.0.8",
    "webpack-dev-server": "^3.1.4"
  },
  "dependencies": {
    "less-loader": "^4.1.0",
    "lodash": "^4.17.10",
    "style-loader": "^0.21.0"
  }
}
```

webpack.config.js
```javaScript
const path = require('path');
const webpack = require('webpack'); //引入的webpack,使用lodash
const HtmlWebpackPlugin = require('html-webpack-plugin')  //将html打包
const ExtractTextPlugin = require('extract-text-webpack-plugin')     //打包的css拆分,将一部分抽离出来  
const CopyWebpackPlugin = require('copy-webpack-plugin')
// console.log(path.resolve(__dirname,'dist')); //物理地址拼接
module.exports = {
    entry: './src/index.js', //入口文件  在vue-cli main.js
    output: {       //webpack如何输出
        path: path.resolve(__dirname, 'dist'), //定位，输出文件的目标路径
        filename: '[name].js' //默认生成的是main.js
    },
    module: {       //模块的相关配置
        rules: [     //根据文件的后缀提供一个loader,解析规则
            {
                test: /\.js$/,  //es6 => es5 
                include: [
                    path.resolve(__dirname, 'src')
                ],
                // exclude:[], 不匹配选项（优先级高于test和include）
                use: 'babel-loader'
            },
            {
                test: /\.css/,
                use: ExtractTextPlugin.extract({
                    fallback: 'style-loader',
                    use: [
                        'css-loader'
                    ]
                })
            },
            {
                test: /\.less$/,
                use: ExtractTextPlugin.extract({
                    fallback: 'style-loader',
                    use: [
                    'css-loader',
                    'less-loader'
                    ]
                })
            },
            {       //图片loader
                test: /\.(png|jpg|gif)$/,
                use: [
                    {
                        loader: 'file-loader' //根据文件地址加载文件
                    }
                ]
            }
        ]                  
    },
    resolve: { //解析模块的可选项  
        // modules: [ ]//模块的查找目录 配置其他的css等文件
        extensions: [".js", ".json", ".jsx",".less", ".css"],  //用到文件的扩展名
        alias: { //模块别名列表
            utils: path.resolve(__dirname,'src/utils')
        }
    },
    plugins: [  //插进的引用, 压缩，分离美化
        new ExtractTextPlugin('[name].css'),  //[name] 默认  也可以自定义name  声明使用
        new HtmlWebpackPlugin({  //将模板的头部和尾部添加css和js模板,dist 目录发布到服务器上，项目包。可以直接上线
            file: 'index.html', //打造单页面运用 最后运行的不是这个
            template: 'src/index.html'  //vue-cli放在跟目录下
        }),
        new CopyWebpackPlugin([  //src下其他的文件直接复制到dist目录下
            { from:'src/assets/favicon.ico',to: 'favicon.ico' }
        ]),
        new webpack.ProvidePlugin({  //引用框架 jquery  lodash工具库是很多组件会复用的，省去了import
            '_': 'lodash'  //引用webpack
        })
    ],
    devServer: {  //服务于webpack-dev-server  内部封装了一个express 
        port: '1314',
        before(app) {
            app.get('/api/test.json', (req, res) => {
                res.json({
                    code: 200,
                    message: 'Hello World'
                })
            })
        }
    }
}
```

webpack devServer(内置一个express，在本地起一个local server)
> yarn add webpack-dev-server

webpack-dev-server的介绍页是这么说的：
> Use webpack with a development server that provides **live reloading**. This should be used for development only.
It uses webpack-dev-middleware under the hood, which provides fast in-memory access to the webpack assets.
关键是热更新(还有dev-server提供的内容，比方说html这些东西是放在内存里面的，不存在实际上的文件)

但是devServer 的hot reload 只能监视js文件的变化，并不能监视html或者server content的变化。这需要[browserSync](https://browsersync.io/)以及BrowserSync plugin for Webpack.
> yarn add browsersync browser-sync-webpack-plugin

HtmlWebpackPlugin目前已经可以做到和webpack-dev-server搭配实现html hot reload
有了HtmlWebpackPlugin,html文件里面已经不需要写script或者css的tag了。
直接在index.js里面去require("./styles/index")就行


## 4. babel(es 2015 -> es5)
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


==================trash ========================================================================

## 7. react cli and vue cli原理

## 8. common front end javaScript libraries
minify js(删掉所有的空行) 
underscore javaScript library
handlebars(模板)

## 参考
[请手写一个webpack4.0配置](http://web.jobbole.com/94944/)




