---
title: MongoDB手册
date: 2017-12-10 16:13:54
tags:
---
![](https://www.haldir66.ga/static/imgs/scenery1511100794441.jpg)
<!--more-->


MongoDB可以作为Spring boot的数据库DAO，也可以和node平台的express module结合。作为后台开发的数据库，应用很广。



## 安装(windows平台下)
MongoDB默认装到C盘的program files文件夹里面,需要一个data文件夹
[official on installation](https://docs.mongodb.com/v3.4/tutorial/install-mongodb-on-windows/)
这个文件夹不一定要在c盘，可以放f盘，比如"f://mongndb//data"
//这样启动server时记得把--dbpath传一下
默认安装的时候dbpath被设置为了"c://data//db"，所以可能需要创建这个目录

## establish connection
```bash
// start db server
"C:\Program Files\MongoDB\Server\3.4\bin\mongod.exe" --dbpath d:\test\mongodb\data
// open another shell window to connect to server
"C:\Program Files\MongoDB\Server\3.4\bin\mongo.exe"
// then you can start interact with mongo db server
```


## 速查手册
[Tutorial, not official](https://www.tutorialspoint.com/mongodb/mongodb_create_collection.htm)
[Mongoose教程](https://code.tutsplus.com/articles/an-introduction-to-mongoose-for-mongodb-and-nodejs--cms-29527)
[官方手册](https://docs.mongodb.com/manual/reference/method/db.collection.findOneAndDelete/#db.collection.findOneAndDelete)
[Mongoose CURD](https://scotch.io/tutorials/using-mongoosejs-in-node-js-and-mongodb-applications#what-is-mongoose)
[支持多种语言环境调用mongodb api](https://docs.mongodb.com/ecosystem/drivers/)


语法(不像mysql后面要跟一个;分号,mongo shell并不要求)：
>  
```ruby
use mydb ## 创建一个名mydb的数据库
db.createCollection("students") ## 创建一个students的collections(类似于sql的table)
show databases ##显示当前系统中所有db
show collections  ## 显示当前数据库中的所有collections
db.students.insert({name: 'Json',age: 22,title:['teacher','professor','versatile']}) ## 往数据库里添加一条数据
db.students.find().pretty() // 显示students的collection中的所有元素，pretty只是好看点
db.students.updateOne( { "name": "Bob" }, { $set: {"age" : 99}} ); // UPDATE语句 set
db.students.find( { age : { $gt:24, $lt: 28} } )  // QUERY 语句 greater than and less than
db.students.deleteOne( { "_id" : ObjectId("5a584a109f157d455472ff11") } ); // DELETE 语句

## batchInsert
try {
   db.products.insertMany( [
      { item: "card", qty: 15 },
      { item: "envelope", qty: 20 },
      { item: "stamps" , qty: 30 }
   ] );
} catch (e) {
   print (e);
}

```




## 在node环境下可以使用
Mongoose // a wrapper around the mongo db interface


schema  definition
```js
// correct
var studentSchema = mongoose.Schema({
    _id: String,
    name: String,
    age: Number
});

// wrong
var studentSchema = mongoose.Schema({
    name: String,
    age: Number
});
```


[在linux上安装mongodb-server会占用200多MB的磁盘空间，原因是db使用了journal file，但这种journal 要区别于实际的文件，并未写入实际的文件存储](https://stackoverflow.com/questions/19533019/is-it-safe-to-delete-the-journal-file-of-mongodb)
具体的文件名字好像叫WiredTigerLog什么的
是这么找出来的
sudo find / -size +10M  -exec du -h {} \; | sort -n
===========================================================================
// todo validate request data, error handling.

[Uploading Files to MongoDB With GridFS (Node.js App)](https://www.youtube.com/watch?v=3f5Q9wDePzY)
