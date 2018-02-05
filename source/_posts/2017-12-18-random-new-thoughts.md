---
title: 即刻备忘录
date: 2046-12-18 22:58:14
tags: [tools]
top : 1
---

一个待办事项的仓库
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/girlfriend lake green nature water cold.jpg?imageView2/2/w/600)

<!--more-->

* [x] flex,grid

- [WPA 所代表的 Web 开发应是未来](https://huangxuan.me/2017/02/09/nextgen-web-pwa/)
- [js 循环闭包的解决方法](https://segmentfault.com/a/1190000003818163)
- [Android Studio 编译过程](https://fucknmb.com/2017/05/11/Android-Studio-Library%E6%A8%A1%E5%9D%97%E4%B8%ADNative%E4%BB%A3%E7%A0%81%E8%BF%9B%E8%A1%8Cdebug%E7%9A%84%E4%B8%80%E4%BA%9B%E5%9D%91/)
- [个人分享--web 前端学习资源分享](https://juejin.im/post/5a0c1956f265da430a501f51)
- [Android 编译及 Dex 过程源码分析](http://mouxuejie.com/blog/2016-06-21/multidex-compile-and-dex-source-analysis/)
- [如何调试 Android 打包流程？](http://www.wangyuwei.me/)
- [一个用于优化 png 图片的 gradle 插件](https://github.com/chenenyu/img-optimizer-gradle-plugin)，用来看 groovy 语法挺好的。以及 [How to write gradle plugin](http://yuanfentiank789.github.io/2017/09/20/%E5%9C%A8AndroidStudio%E4%B8%AD%E8%87%AA%E5%AE%9A%E4%B9%89Gradle%E6%8F%92%E4%BB%B6/)
- [scheme 这东西算跨客户端平台的](https://sspai.com/post/31500)，比如在 App 中调起支付宝(用的是 alipayqr://)。其实就是一个系统内跨应用调用。[用法](http://blog.csdn.net/qq_23547831/article/details/51685310)
- [基于 Docker 打造前端持续集成开发环境](https://juejin.im/post/5a157b7a5188257bfe457ff0)
- 使用 express 模拟网络延迟
- Promise 链式调用与终止，异常处理
- 前后端同构
- 前后端分离
- iview，elementUi
- XSS 攻击
- [写 groovy 用 intelij 就可以了](https://www.jetbrains.com/help/idea/getting-started-with-groovy.html) 》 how to
- [ ] jQuery 插件
- [ ] vS Code Vender Prefix plugin => auto prefix loader
- [ ] websocket nodejs
- [ ]单个网卡最多65535个端口
- [ ] install nginx , jenkin ci, deploying nginx in docker(Http Load Balaning with Docker and nginx)(https://www.digitalocean.com/community/tutorials/how-to-configure-nginx-with-ssl-as-a-reverse-proxy-for-jenkins)
- [ ] 用GDB调试程序
- [ ] Paul Irish from google
- [ ] npm install graphql(mostly a server side javascript stuff)

已完成

* 用 express 转接一个知乎 Api，添加 Access-control-allow-origin,或许还可以用 redis 缓存数据结果（一个就好）由此想到一篇文章"How to use Pythonto build a restful Web Service".只不过用的是 Tornado
* git hook (github travis 持续集成，git push 会触发服务器的一系列操作)
* 基于前后端分离的理念，后台只负责提供数据，render page 的任务应该交给前端。（所以用 express-handlebars 写页面的方式写着很累）
* 集成 travis-ci，记得 after-success script 的结果并不会影响 build 的结果（即，after-success 执行脚本发生了错误，在日志里有输出 error，但实际显示的 build result 仍为 success），还有 travis 的输出 log 需要默认是折叠的，要展开才能看清楚，但在 afterSuccess 里面的指令的输出一定是有的。
