---
title: MongoDB手册
date: 2017-12-10 16:13:54
tags:
---
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/scenery1511100794441.jpg?imageView2/2/w/600)
<!--more-->



MongoDB可以作为Spring boot的数据库DAO，也可以和node平台的express module结合。作为后台开发的数据库，应用很广。

Mongoose // a wrapper around the mongo db interface

## 安装(windows平台下)
MongoDB默认装到C盘的program files文件夹里面,需要一个data文件夹
[official on installation](https://docs.mongodb.com/v3.4/tutorial/install-mongodb-on-windows/)
这个文件夹不一定要在c盘，可以放f盘，比如"f://mongndb//data"
//这样启动server时记得把--dbpath传一下

## establish connection
```shell
// start db server
"C:\Program Files\MongoDB\Server\3.4\bin\mongod.exe" --dbpath d:\test\mongodb\data
// open another shell window to connect to server
"C:\Program Files\MongoDB\Server\3.4\bin\mongo.exe"
// then you can start interact with mongo db server
```


## 速查手册
[Tutorial, not official](https://www.tutorialspoint.com/mongodb/mongodb_create_collection.htm)
[Mongoose教程](https://code.tutsplus.com/articles/an-introduction-to-mongoose-for-mongodb-and-nodejs--cms-29527)


语法：
>            
use mydb ## 创建一个名mydb的数据库
mydb.createCollection("students") ## 创建一个students的collections(类似于sql的table)
show collections  ## 显示当前数据库中的所有collections
db.students.insert({name: 'Json',age: 22,title:['teacher','professor','versatile']}) ## 往数据库里添加一条数据
db.students.find().pretty() // 显示students的collection中的所有元素，pretty只是好看点
