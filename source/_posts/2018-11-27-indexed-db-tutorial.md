---
title: 浏览器indexedDb使用示例
date: 2018-11-27 10:33:01
tags: [javaScript,前端]
---

浏览器indexedDb使用方式及注意的点
![](https://api1.reindeer36.shop/static/imgs/black-mountains.jpg)
<!--more-->

[浏览器上可供使用的数据持久化选择就这些](https://medium.com/@filipvitas/indexeddb-with-promises-and-async-await-3d047dddd313)

> 1) Store all data on server database (SQL or NoSQL)
2) LocalStorage / SessionStorage - limited memory (around 5MB)
3) WebSQL - it has been deprecated in favor of IndexedDB
4) IndexedDB - designed as “one true” browser database with 50MB and more
tl;dr Use some library from conclusion section to make your life easier.


## 一些重要的概念
Database(通常一个app只有一个database)
127.0.0.1:8080和127.0.0.1：8000 是两个不同的Application
创建出来的数据库在Application->Storage->IndexedDB里面有

Object Stores(就像数据库里的table或者collections一样，但是同一个store中存储的数据类型不一定是相同的)

transaction（所有对IndexDb的操作必须通过transaction）

接下来是CURD的实例

db.open返回的是一个IDBRequest对象，没有promise的方式是这样使用的
```js
var db;

// Let us open our database
var DBOpenRequest = window.indexedDB.open("toDoList", 4);

// these two event handlers act on the database being
// opened successfully, or not
DBOpenRequest.onerror = function(event) {
  note.innerHTML += '<li>Error loading database.</li>';
};

DBOpenRequest.onsuccess = function(event) {
  note.innerHTML += '<li>Database initialised.</li>';
 
  // store the result of opening the database.
  db = DBOpenRequest.result;
};
```

### (Create)创建db的代码:
indexedDB.open('db-name', 1) //第二个参数是数据库版本

### 添加数据的方式
```js
function putSomeData() {
    let indexedDB = window.indexedDB || window.mozIndexedDB || window.webkitIndexedDB || window.msIndexedDB

    let open = indexedDB.open('db-name', 1)

    open.onupgradeneeded = function() {
        let db = open.result
        db.createObjectStore('objectStoreName', { autoIncrement: true })
    }

    open.onsuccess = function() {
        let db = open.result
        let tx = db.transaction('objectStoreName', 'readwrite')
        let store = tx.objectStore('objectStoreName')

        store.put({ firstname: 'John', lastname: 'Doe', age: 33 })

        tx.oncomplete = function() {
            db.close()
        }
    }
}
```

真啰嗦，还是用第三方库吧，用[idb](https://github.com/jakearchibald/idb)好了
```js
async function putSomeData() {
    let db = await idb.open('db-name', 1, upgradeDB => upgradeDB.createObjectStore('objectStoreName', { autoIncrement: true }))

    let tx = db.transaction('objectStoreName', 'readwrite')
    let store = tx.objectStore('objectStoreName')

    await store.put({ firstname: 'John', lastname: 'Doe', age: 33 })

    await tx.complete
    db.close()
}

async function getAllData() {
    let db = await idb.open('db-name', 1)

    let tx = db.transaction('objectStoreName', 'readonly')
    let store = tx.objectStore('objectStoreName')

    // add, clear, count, delete, get, getAll, getAllKeys, getKey, put
    let allSavedItems = await store.getAll()

    console.log(allSavedItems)

    db.close()
}
```

### 扯一点关于存储的东西
当浏览器进入私人模式(private browsing mode，Google Chrome 上对应的应该是叫隐身模式)的时候，会创建一个新的、临时的、空的数据库，用以存储本地数据(local storage data)。当浏览器关闭时，里面的所有数据都将被丢弃。

判断方式
```js
//隐身模式下和localStorage满了都会报同样的错误
try {
  window.localStorage.setItem('test', 'test')
} catch (e)  {
  console.log(e) //QuotaExceddedError(DOM Exception 22):The quota has been exceeded.
}
```


