---
title: Hexo部署个人博客记录
date: 2017-01-08 18:01:01
tags: hexo 
top : 2
---

去年九月份之前还觉得写个人blog是一件很奢侈的事情，现在几个月过去了，很多问题都能够自己在网上找到答案。记录下来的问题也越来越多，如果想要给自己的blog一个值得置顶的文章的话，我觉得一篇记录使用hexo过程中的一些解决问题的方法的文章是再合适不过的了。</br>
![](http://odzl05jxx.bkt.clouddn.com/163216sn1ziyyaef4zaeps.jpg?imageView2/2/w/500)

<!--more-->

### 1. 经常更新yilia的theme
[yilia](https://github.com/litten/hexo-theme-yilia)主题经常会更新，及时更新theme会发现很多新的特性及bug fix

### 2. 部署相关
- 部署到github
```javascript
hexo clean //清除缓存
hexo g -d //一步到位 = hexo g + hexo d
```

- 部署过程中出现的一些错误
```java
$ hexo g -d
INFO  Start processing
ERROR Process failed: _posts/2016-12-10-adb-command.md
YAMLException: can not read a block mapping entry; a multiline key may not be an implicit key at line 3, column 11:
    categories:  [技术]
              ^
    at generateError (D:\Blog\github\node_modules\hexo\node_modules\js-yaml\lib\js-yaml\loader.js:162:10)
    at throwError (D:\Blog\github\node_modules\hexo\node_modules\js-yaml\lib\js-yaml\loader.js:168:9)
    at readBlockMapping (D:\Blog\github\node_modules\hexo\node_modules\js-yaml\lib\js-yaml\loader.js:1040:9)
    at composeNode (D:\Blog\github\node_modules\hexo\node_modules\js-yaml\lib\js-yaml\loader.js:1326:12)
    at readDocument (D:\Blog\github\node_modules\hexo\node_modules\js-yaml\lib\js-yaml\loader.js:1488:3)
    at loadDocuments (D:\Blog\github\node_modules\hexo\node_modules\js-yaml\lib\js-yaml\loader.js:1544:5)
    at Object.load (D:\Blog\github\node_modules\hexo\node_modules\js-yaml\lib\js-yaml\loader.js:1561:19)
    at parseYAML (D:\Blog\github\node_modules\hexo\node_modules\hexo-front-matter\lib\front_matter.js:80:21)
    at parse (D:\Blog\github\node_modules\hexo\node_modules\hexo-front-matter\lib\front_matter.js:56:12)
    at D:\Blog\github\node_modules\hexo\lib\plugins\processor\post.js:52:18
    at tryCatcher (D:\Blog\github\node_modules\hexo\node_modules\bluebird\js\release\util.js:16:23)
    at Promise._settlePromiseFromHandler (D:\Blog\github\node_modules\hexo\node_modules\bluebird\js\release\promise.js:507:35)
    at Promise._settlePromise (D:\Blog\github\node_modules\hexo\node_modules\bluebird\js\release\promise.js:567:18)
    at Promise._settlePromise0 (D:\Blog\github\node_modules\hexo\node_modules\bluebird\js\release\promise.js:612:10)
    at Promise._settlePromises (D:\Blog\github\node_modules\hexo\node_modules\bluebird\js\release\promise.js:691:18)
    at Promise._fulfill (D:\Blog\github\node_modules\hexo\node_modules\bluebird\js\release\promise.js:636:18)
    at PromiseArray._resolve (D:\Blog\github\node_modules\hexo\node_modules\bluebird\js\release\promise_array.js:125:19)
    at PromiseArray._promiseFulfilled (D:\Blog\github\node_modules\hexo\node_modules\bluebird\js\release\promise_array.js:143:14)
    at PromiseArray._iterate (D:\Blog\github\node_modules\hexo\node_modules\bluebird\js\release\promise_array.js:113:31)
    at PromiseArray.init [as _init] (D:\Blog\github\node_modules\hexo\node_modules\bluebird\js\release\promise_array.js:77:10)
    at Promise._settlePromise (D:\Blog\github\node_modules\hexo\node_modules\bluebird\js\release\promise.js:564:21)
    at Promise._settlePromise0 (D:\Blog\github\node_modules\hexo\node_modules\bluebird\js\release\promise.js:612:10)
    at Promise._settlePromises (D:\Blog\github\node_modules\hexo\node_modules\bluebird\js\release\promise.js:691:18)
    at Promise._fulfill (D:\Blog\github\node_modules\hexo\node_modules\bluebird\js\release\promise.js:636:18)
    at PromiseArray._resolve (D:\Blog\github\node_modules\hexo\node_modules\bluebird\js\release\promise_array.js:125:19)
    at PromiseArray._promiseFulfilled (D:\Blog\github\node_modules\hexo\node_modules\bluebird\js\release\promise_array.js:143:14)
    at Promise._settlePromise (D:\Blog\github\node_modules\hexo\node_modules\bluebird\js\release\promise.js:572:26)
    at Promise._settlePromise0 (D:\Blog\github\node_modules\hexo\node_modules\bluebird\js\release\promise.js:612:10)
    at Promise._settlePromises (D:\Blog\github\node_modules\hexo\node_modules\bluebird\js\release\promise.js:691:18)
    at Promise._fulfill (D:\Blog\github\node_modules\hexo\node_modules\bluebird\js\release\promise.js:636:18)
    at Promise._resolveCallback (D:\Blog\github\node_modules\hexo\node_modules\bluebird\js\release\promise.js:431:57)
    at Promise._settlePromiseFromHandler (D:\Blog\github\node_modules\hexo\node_modules\bluebird\js\release\promise.js:522:17)
    at Promise._settlePromise (D:\Blog\github\node_modules\hexo\node_modules\bluebird\js\release\promise.js:567:18)
    at Promise._settlePromise0 (D:\Blog\github\node_modules\hexo\node_modules\bluebird\js\release\promise.js:612:10)
    at Promise._settlePromises (D:\Blog\github\node_modules\hexo\node_modules\bluebird\js\release\promise.js:691:18)
    at Promise._fulfill (D:\Blog\github\node_modules\hexo\node_modules\bluebird\js\release\promise.js:636:18)
    at D:\Blog\github\node_modules\hexo\node_modules\bluebird\js\release\nodeback.js:42:21
    at D:\Blog\github\node_modules\hexo\node_modules\hexo-fs\node_modules\graceful-fs\graceful-fs.js:78:16
    at tryToString (fs.js:455:3)
    at FSReqWrap.readFileAfterClose [as oncomplete] (fs.js:442:12)
INFO  Files loaded in 1.48 s
INFO  Generated: sitemap.xml
INFO  Generated: atom.xml
INFO  Generated: 2017/01/08/2017-01-08-trouble-shooting-with-my-blog/index.html
INFO  Generated: index.html
INFO  4 files generated in 2.26 s
INFO  Deploying: git

```


### 3. 一些功能的实现

- 置顶功能
    将node_modules/hexo-generator-index/lib/generator.js的文件内容替换成一下内容

```javascript
'use strict';
var pagination = require('hexo-pagination');
module.exports = function(locals){
  var config = this.config;
  var posts = locals.posts;
    posts.data = posts.data.sort(function(a, b) {
        if(a.top && b.top) { // 两篇文章top都有定义
            if(a.top == b.top) return b.date - a.date; // 若top值一样则按照文章日期降序排
            else return b.top - a.top; // 否则按照top值降序排
        }
        else if(a.top && !b.top) { // 以下是只有一篇文章top有定义，那么将有top的排在前面（这里用异或操作居然不行233）
            return -1;
        }
        else if(!a.top && b.top) {
            return 1;
        }
        else return b.date - a.date; // 都没定义按照文章日期降序排
    });
  var paginationDir = config.pagination_dir || 'page';
  return pagination('', posts, {
    perPage: config.index_generator.per_page,
    layout: ['index', 'archive'],
    format: paginationDir + '/%d/',
    data: {
    __index: true
    }
  });
};

```

- 同时在文章开头添加top : 1即可 ，实际排序按照这个数字从大到小排序
```java
 title: Hexo置顶文章
date: 2016-11-11 23:26:22
tags:[置顶]
categories: Hexo
top: 0 # 0或者1
```





### 4. markdown语法


### ref
- [Hexo博文置顶技巧](http://yanhuili.github.io/2016/11/21/hexo%E5%8D%9A%E6%96%87%E7%BD%AE%E9%A1%B6%E6%8A%80%E5%B7%A7/)