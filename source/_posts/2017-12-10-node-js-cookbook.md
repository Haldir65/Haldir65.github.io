---
title: 2017-12-10-node-js-cookbook
date: 2017-12-10 16:13:30
tags:
---

npm = node package manager
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/scenery1511100694324.jpg?imageView2/2/w/600)
<!--more-->

npm的configuration非常方便设置,首先是[设置proxy](https://stackoverflow.com/questions/7559648/is-there-a-way-to-make-npm-install-the-command-to-work-behind-proxy)
> npm config set strict-ssl false
> npm config set registry "http://registry.npmjs.org/"
> npm config set proxy http://127.0.0.1:1080 ## 以上三句话设置代理
> npm config list ##列出当前所有的设置
> npm config get stuff ##比如说registry等等


用过的module
path(core module, 无需安装)
http(core module, 无需安装)
express
nodemon // 实时监控本地文件变化，重启服务，安装npm install nodemon -g
body-parser
ejs
pm2 //starting an node app as a bcakground service
