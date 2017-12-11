---
title: Hexo部署个人博客记录
date: 2017-01-08 18:01:01
categories: blog
tags: [hexo,置顶]
top : 2
---

使用hexo写博客以来，记录下来的问题越来越多。只希望下次再碰到同样的问题时，不要再去浪费时间去查找。如果想要给自己的blog一个值得置顶的文章的话，我觉得一篇记录使用hexo过程中的一些解决问题的方法的文章是再合适不过的了。</br>
![](http://odzl05jxx.bkt.clouddn.com/40164340_40164340_1414330224938_mthumb.jpg?imageView2/2/w/600)


<!--more-->

## 1. 经常更新yilia的theme
[yilia](https://github.com/litten/hexo-theme-yilia)主题经常会更新，及时更新theme会发现很多新的特性及bug fix

## 2. 部署相关
- 部署到github
```javascript
hexo clean //清除缓存
hexo g -d //一步到位 = hexo g + hexo d
hexo s //localost:4000本地预览
```

- 部署过程中出现的一些错误

```javascript
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
找了好久，有说"\_config.xml" 文件 有空格的，有说title被乱改的，试了好长时间，改成这样就不再报错了。所以，**冒号后面一定要加空格，英文半角的**

```
---
title: adb常用命令手册
date: 2016-12-10 21:14:14
tags:
 - android
 - adb
---
```
tags有两种写法，一种是上面这样前面加横杠
另一种长这样，写成数组形式
```
---
title: my awesometitle
date: 2017-05-07 16:48:01
categories: blog
tags: [linux,python]
---
```


## 3. 一些功能的实现

- 置顶功能
    将node_modules/hexo-generator-index/lib/generator.js的文件内容替换成以下内容

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

## 4. SublimeText的一些快捷键
由于文章大部分都是使用SublimeText写的，Typroa这种所见即所得的编辑器也不错，但对于掌握MardkDown语法没有帮助。这里摘录一些SubLimeText的快捷键。

> **Ctrl+Shift+P：打开命令面板**
Ctrl+P：搜索项目中的文件
Ctrl+G：跳转到第几行
Ctrl+W：关闭当前打开文件 CTRL+F4也可以
Ctrl+Shift+W：关闭所有打开文件
Ctrl+Shift+V：粘贴并格式化
Ctrl+D：选择单词，重复可增加选择下一个相同的单词
**Ctrl+L：选择行，重复可依次增加选择下一行**
**Alt+Shift+数字：分屏显示**
**Ctrl+Shift+L：选择多行**
**Ctrl+Shift+D：复制粘贴当前行**
**Ctrl+X：删除当前行**
**Ctrl+Shift+左箭头 往左边选择内容**
**Shift+向左箭头 向左选择文本**
**Ctrl+B 编译，markDown生成html文件**
**Alt+2 切换到第二个Tab（打开的文件，记得chrome是ctrl+2）**
**Ctrl+R：前往 对应的方法的实现***
**快速加上[] 选中单词按 [ 即可**
**批量更改当前页面相同的单词 alt+F3 **
**Ctrl+Enter 在下一行插入新的一行**
**Ctrl+Shift+Enter 在上一行插入新的一行**
**Shift+ 向上箭头 向上选中多行**



Ctrl+Shift+D：复制粘贴当前行Ctrl+Shift+Enter：在当前行前插入新行
Ctrl+M：跳转到对应括号
Ctrl+U：软撤销，撤销光标位置
Ctrl+J：选择标签内容
Ctrl+F：查找内容
Ctrl+Shift+F：查找并替换
Ctrl+H：替换
Ctrl+N：新建窗口
Ctrl+K+B：开关侧栏
Ctrl+Shift+M：选中当前括号内容，重复可选着括号本身
Ctrl+F2：设置/删除标记
Ctrl+/：注释当前行
Ctrl+Shift+/：当前位置插入注释
Ctrl+Alt+/：块注释，并Focus到首行，写注释说明用的
Ctrl+Shift+A：选择当前标签前后，修改标签用的
F11：全屏
Shift+F11：全屏免打扰模式，只编辑当前文件
Alt+F3：选择所有相同的词
Alt+.：闭合标签
Shift+右键拖动：光标多不，用来更改或插入列内容
Alt+数字：切换打开第N个文件
鼠标的前进后退键可切换Tab文件
按Ctrl，依次点击或选取，可需要编辑的多个位置
按Ctrl+Shift+上下键，可替换行



## 5. title不能以[]开头
前面加上###确实能够让字号变大，但不要写4个#，后面的字母会大小写不分的


## 6. markdown语法
MarkDown页面内部跳转
[MarkDown技巧：两种方式实现页内跳转](http://www.cnblogs.com/JohnTsai/p/4027229.html)

> *一个星星包起来是斜体字*
**两个星星包起来是粗体字**
***那么三个星星呢***

## 7.github提交commit的时候显示Emoji
链接[在此](https://www.webpagefx.com/tools/emoji-cheat-sheet/)

## 8.换电脑了怎么办
亲测，把整个目录下所有文件全部复制粘贴到新电脑上，装上node，然后装上hexo，记得勾选添加到PATH,然后就可以了。需要注意的是小文件比较多，所以复制粘贴可能要十几分钟。

## 9. 有时候写的代码会给你在每一行前面加上true
比如写一段css的代码时候，很多时候预览会给每一行前面加上一个true，解决办法：用TAB键缩进即可

## 10. markdown-live是一个非常好用的node module
[项目地址](https://www.npmjs.com/package/markdown-live)
**前提是安装了node**
>  npm install -g markdown-live

>md-live

<br>
***编辑md文件的同时，保存就会同步刷新网页预览，非常好用***

### 参考
- [Hexo博文置顶技巧](http://yanhuili.github.io/2016/11/21/hexo%E5%8D%9A%E6%96%87%E7%BD%AE%E9%A1%B6%E6%8A%80%E5%B7%A7/)
- [SublimeText快捷键](http://www.daqianduan.com/4820.html)
- [MarkDown语法学起来很快的](http://itmyhome.com/markdown/article/syntax/emphasis.html)
