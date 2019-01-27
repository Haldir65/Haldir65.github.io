---
title: Hexo部署个人博客记录
date: 2217-01-08 18:01:01
categories: blog
tags: [hexo,置顶]
top : 2
---

使用 hexo 写博客以来，记录下来的问题越来越多。只希望下次再碰到同样的问题时，不要再去浪费时间去查找。如果想要给自己的 blog 一个值得置顶的文章的话，我觉得一篇记录使用 hexo 过程中的一些解决问题的方法的文章是再合适不过的了。</br>
![](https://haldir66.ga/static/imgs/40164340_40164340_1414330224938_mthumb.jpg)

<!--more-->

## 1. 经常更新 yilia 的 theme

[yilia](https://github.com/litten/hexo-theme-yilia)主题经常会更新，及时更新 theme 会发现很多新的特性及 bug fix

## 2. 部署相关

* 部署到 github

```javascript
hexo clean //清除缓存
hexo g -d //一步到位 = hexo g + hexo d
hexo s //localost:4000本地预览
```

* 部署过程中出现的一些错误

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

找了好久，有说"\_config.xml" 文件 有空格的，有说 title 被乱改的，试了好长时间，改成这样就不再报错了。所以，**冒号后面一定要加空格，英文半角的**

```
---
title: adb常用命令手册
date: 2016-12-10 21:14:14
tags:
 - android
 - adb
---
```

tags 有两种写法，一种是上面这样前面加横杠另一种长这样，写成数组形式

```
---
title: my awesometitle
date: 2017-05-07 16:48:01
categories: blog
tags: [linux,python]
---
```

## 3. 一些功能的实现

* 置顶功能将 node_modules/hexo-generator-index/lib/generator.js 的文件内容替换成以下内容

```javascript
"use strict";
var pagination = require("hexo-pagination");
module.exports = function(locals) {
  var config = this.config;
  var posts = locals.posts;
  posts.data = posts.data.sort(function(a, b) {
    if (a.top && b.top) {
      // 两篇文章top都有定义
      if (a.top == b.top)
        return b.date - a.date; // 若top值一样则按照文章日期降序排
      else return b.top - a.top; // 否则按照top值降序排
    } else if (a.top && !b.top) {
      // 以下是只有一篇文章top有定义，那么将有top的排在前面（这里用异或操作居然不行233）
      return -1;
    } else if (!a.top && b.top) {
      return 1;
    } else return b.date - a.date; // 都没定义按照文章日期降序排
  });
  var paginationDir = config.pagination_dir || "page";
  return pagination("", posts, {
    perPage: config.index_generator.per_page,
    layout: ["index", "archive"],
    format: paginationDir + "/%d/",
    data: {
      __index: true
    }
  });
};
```

* 同时在文章开头添加 top : 1 即可 ，实际排序按照这个数字从大到小排序

另一种做法是手动将date改大，日期越靠后的越在前面。

```java
 title: Hexo置顶文章
date: 2016-11-11 23:26:22
tags:[置顶]
categories: Hexo
top: 0 # 0或者1
```

个人建议：置顶不要太多

## 4. SublimeText 的一些快捷键

由于文章大部分都是使用 SublimeText 写的，Typroa 这种所见即所得的编辑器也不错，但对于掌握 MardkDown 语法没有帮助。这里摘录一些 SubLimeText 的快捷键。

> **Ctrl+Shift+P：打开命令面板**
> Ctrl+P：搜索项目中的文件
> Ctrl+G：跳转到第几行
> Ctrl+W：关闭当前打开文件 CTRL+F4 也可以
> Ctrl+Shift+W：关闭所有打开文件
> Ctrl+Shift+V：粘贴并格式化
> Ctrl+D：选择单词，重复可增加选择下一个相同的单词
> **Ctrl+L：选择行，重复可依次增加选择下一行**
 > **Alt+Shift+数字：分屏显示**
 > **Ctrl+Shift+L：选择多行**
 > **Ctrl+Shift+D：复制粘贴当前行**
 > **Ctrl+X：删除当前行**
 > **Ctrl+Shift+左箭头 往左边选择内容**
 > **Shift+向左箭头 向左选择文本**
 > **Ctrl+B 编译，markDown 生成 html 文件**
 > **Alt+2 切换到第二个 Tab（打开的文件，记得 chrome 是 ctrl+2）**
 > **Ctrl+R：前往 对应的方法的实现\***
 > **快速加上[] 选中单词按 [ 即可**
 > **批量更改当前页面相同的单词 alt+F3 **
 > **Ctrl+Enter 在下一行插入新的一行**
 > **Ctrl+Shift+Enter 在上一行插入新的一行**
 > **Shift+ 向上箭头 向上选中多行**

Ctrl+Shift+D：复制粘贴当前行 Ctrl+Shift+Enter：在当前行前插入新行
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
Ctrl+Alt+/：块注释，并 Focus 到首行，写注释说明用的
Ctrl+Shift+A：选择当前标签前后，修改标签用的
F11：全屏
Shift+F11：全屏免打扰模式，只编辑当前文件
Alt+F3：选择所有相同
Alt+.：闭合标签
Shift+右键拖动：光标多不，用来更改或插入列内容
Alt+数字：切换打开第 N 个文件鼠标的前进后退键可切换 Tab 文件按 Ctrl，依次点击或选取，可需要编辑的多个位置按 Ctrl+Shift+上下键，可替换行


vscode的快捷键最重要的一个是ctrl+shift+p,ctrl+p只是在全局查找文件

## 5. title 不能以[]开头

前面加上###确实能够让字号变大，但不要写 4 个#，后面的字母会大小写不分的

## 6. markdown 语法

MarkDown 页面内部跳转
[MarkDown 技巧：两种方式实现页内跳转](http://www.cnblogs.com/JohnTsai/p/4027229.html)

> *一个星星包起来是斜体字*
 > **两个星星包起来是粗体字**
 > ***_那么三个星星呢_***

## 7.github 提交 commit 的时候显示 Emoji

链接[在此](https://www.webpagefx.com/tools/emoji-cheat-sheet/)

## 8.换电脑了怎么办

亲测，把整个目录下所有文件全部复制粘贴到新电脑上，装上 node，然后装上 hexo，记得勾选添加到 PATH,然后就可以了。需要注意的是小文件比较多，所以复制粘贴可能要十几分钟。

## 9. 有时候写的代码会给你在每一行前面加上 true

比如写一段 css 的代码时候，很多时候预览会给每一行前面加上一个 true，解决办法：用 TAB 键缩进即可

## 10. markdown-live 是一个非常好用的 node module

[项目地址](https://www.npmjs.com/package/markdown-live)
**前提是安装了 node**

> npm install -g markdown-live

> md-live

<br>
***编辑md文件的同时，保存就会同步刷新网页预览，非常好用***

## 11. 如果运行 hexo g 生成的 index.html 是空的

输出

> WARN No layout: tags/service/index.html
> 原因是 themes/文件夹下没有 clone 对应的主题

换成travis之后，在travis.yml文件中，添加了
```config
cache:
  yarn: true
  directories:
  - node_modules
  - themes
```
cahe也就意味着后续，所有对于themes文件夹中的_config.yml文件的修改都不会生效。这也就是我一遍遍尝试更改theme文件夹中_config文件不生效的原因。
所以要么去掉cache ，要么自己写bash script一行行的改。

## 12. markdown写表格
直接在atom下面敲table，就会自动提示出来的

| 一个普通标题 | 一个普通标题 | 一个普通标题 |
| ------ | ------ | ------ |
| 短文本 | 中等文本 | 稍微长一点的文本 |
| 稍微长一点的文本 | 短文本 | 中等文本 |

中间的虚线左边的冒号表示下面的单元格左对齐，冒号放右边就右对齐，左右都放一个就表示居中


vscode的返回上一个文件快捷键是ctrl + -


## 13 . travis ci自动部署的一些问题

[travis ci加密文件无法在travis以外的地方解密，因为key,value都存在travis的数据库了](https://github.com/travis-ci/travis.rb/issues/437)

[travis加密文件后用openssl解密出现iv undefined的错误](https://github.com/travis-ci/travis-ci/issues/9668)

iv undefined

> travis env list 
encrypted_476ad15a8e52_key=[secure]
encrypted_476ad15a8e52_iv=[secure]
明明是存在的

在linux 里面运行travis endpoint
果然是 API endpoint: https://api.travis-ci.org/
而新的endpoint应该是 https://api.travis-ci.com/
于是travis encrypt-file --help
> --pro  short-cut for --api-endpoint 'https://api.travis-ci.com/'
--org short-cut for --api-endpoint 'https://api.travis-ci.org/'

所以
>travis encrypt-file super_secret.txt 应该改成
travis encrypt-file super_secret.txt --pro

因为默认的$encrypted_476ad15a8e52_key其实已经存储在travis-ci.org上了
所以在travis-ci.com上的项目当然找不到

[自动部署的另一个实例](https://github.com/openwrtio/openwrtio.github.io/blob/mkdocs/.travis.yml)


## 14. hexo server本地预览出现的问题
[hexo s 本地预览样式加载失败](Refused to execute script from 'http://localhost:4000/slider.e37972.js' because its MIME type ('text/html') is not executable, and strict MIME type checking is enabled.)

hexo server的意思是类似于express的serve static功能，[默认只处理public文件下的文件，所以如果本地运行hexo s 出现404的话，直接copy到public文件夹下就可以了](https://hexo.io/zh-cn/docs/server.html)注意hexo clear会删掉public文件夹

[Refused to Execute Script From Because Its MIME Type (Text/plain) Is Not Executable, and Strict MIME Type Checking Is Enabled]这句话的意思

## 15. yilia的主题里面badjs report的问题
yilia的主题里面有一个badjs的report，去掉的方法：
cd 到themes/yilia里面,rm -rf source/ , 然后把source-src里面的report.js里面的东西删掉。yarn install ,yarn dist ,然后回到上层目录。hexo clean , hexo g就可以了。
其实看下里面，就是一个webpack的配置，自己重新编译一下就好了。编译后会在source里面重新生成需要的js文件。
奇怪的是在windows上编译失败，在linux上编译失败，在mac上终于成功了。

## 16. hexo server 
[enospc的解决方式](https://stackoverflow.com/questions/22475849/node-js-what-is-enospc-error-and-how-to-solve)
由于需要监听多个文件，所以linux下允许监听的文件数有个上限，这里修改一下就可以了

### 参考

* [Hexo 博文置顶技巧](http://yanhuili.github.io/2016/11/21/hexo%E5%8D%9A%E6%96%87%E7%BD%AE%E9%A1%B6%E6%8A%80%E5%B7%A7/)
* [SublimeText 快捷键](http://www.daqianduan.com/4820.html)
* [MarkDown 语法学起来很快的](http://itmyhome.com/markdown/article/syntax/emphasis.html)
* [travis 自动部署](https://blessing.studio/deploy-hexo-blog-automatically-with-travis-ci/)
* [Legacy GitHub Services to GitHub Apps Migration Guide 2018年10月1号之后不再支持 Legacy GitHub Service](https://docs.travis-ci.com/user/legacy-services-to-github-apps-migration-guide/)


