---
title: 即刻备忘录
date: 2046-12-18 22:58:14
tags: [tools]
top : 1
---

一个待办事项的仓库
![](https://haldir66.ga/static/imgs/girlfriend lake green nature water cold.jpg)

<!--more-->

### 期待能够完成的
- [个人分享--web 前端学习资源分享](https://juejin.im/post/5a0c1956f265da430a501f51)
- [PWA 所代表的 Web 开发应是未来](https://huangxuan.me/2017/02/09/nextgen-web-pwa/)据说Electron要被PWA干掉
- [js 循环闭包的解决方法](https://segmentfault.com/a/1190000003818163)
- 动态类型一时爽，代码重构火葬场
- iview，elementUi
- [ ] shadowsocks-android源码（据说是起了一个c进程守护）
- [ ] chromium net移植到Android平台[cronet是最简单的方式](https://github.com/GoogleChromeLabs/cronet-sample) [更多下载仓库](https://console.cloud.google.com/storage/browser/chromium-cronet?pli=1)
- [embeed video with iframe](https://css-tricks.com/NetMag/FluidWidthVideo/Article-FluidWidthVideo.php)
- [ ] Paul Irish from google
- [ ] [lightbox一个很好看的js图片查看库](http://lokeshdhakar.com/projects/lightbox2/)
- [ ] [一个很好看的h5音乐播放器](https://github.com/wangpengfei15975/skPlayer/)
- [ ] [仿门户网站js相册](https://www.js-css.cn/a/jscode/album/2014/0915/1319.html)， [js相册2](https://www.js-css.cn/a/jscode/album/2014/0914/1318.html)
- [ ] [八大排序算法的python实现](http://python.jobbole.com/82270/)
- [ ] Redux和Flux很像,react context api
- [ ] [一个展示如何在宿主App中提取一个apk文件并加载代码和资源](https://www.jianshu.com/p/a4ab102fa4ac)
- [ ] nodejs ,go ,protobuf rpc(proto更多的是作为一种协议来进行rpc数据传输)
- [ ]一致性哈希原理
- [ ] [使用redis实现低粒度的分布式锁](http://afghl.github.io/2018/06/17/distributed-lock-and-granarity.html)
- [ ] Coordinator behavior以及scroll原理，完善blog
- [ ] instagram好像通过注解的方式自己写了一个json解析器[ig-json-parser](https://github.com/Instagram/ig-json-parser)
- [ ] when it comes to design , how do we translate px, pt, em  into sp,dp and others(设计方面的，各种单位之间的转换)?
- [ ] learning how textView works is painful yet necessary
- [ ] linux环境下多进程通讯方式(管道，共享内存，信号,unix domian socket)
- [ ] mqtt接入实践[mqtt是建立在tcp基础上的应用层协议](https://github.com/mcxiaoke/mqtt)，[netty](https://github.com/netty/netty)也做了实现
- [ ] play around with xposed
- [ ] python gui编程
- [ ] [Kotlin Coroutines Tutorial (STABLE VERSION) ](https://www.youtube.com/watch?v=jYuK1qzFrJg)
- [ ] 宇宙第一ide熟悉使用
- [ ] js的闭包等面试常谈
- [ ] java的aspectJ教程，Spring AOP 与AspectJ 实现原理上并不完全一致，但功能上是相似的
- [ ] autoWired, autovalue这些java 的library
- [ ] code generator(代码生成器)
- [ ][content-disposition](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers)
- [ ] 用正则检测或者解析json(jQuery源码里有) 在线正则检测网站
- [ ] awk，正则表达式还有数据库这些也算一门编程语言
- [ ] 来来来，[手写一个vm](https://www.youtube.com/watch?v=DUNkdl0Jhgs)
- [ ] [chromium提供了如何在windows上编译chromium的教程](https://chromium.googlesource.com/chromium/src/+/master/docs/windows_build_instructions.md#System-requirements)
- [ ][How the JVM compiles bytecode into machine code](https://www.youtube.com/watch?v=M8LiOANu3Nk)
- [ ] WebSocket协议及数据帧
- [ ]Lua脚本是一个很轻量级的脚本，也是号称性能最高的脚本。路由器上都有运行环境，语法和c语言差不多
- [腾讯的mmkv是shared preference的有效替代品](https://juejin.im/post/5baf8ae8f265da0ae92a7df5) mmap的使用值得学习
- [简单的组件化方案](https://www.jianshu.com/p/5f9a7bc902e1)
- [mvc,mvp,mvvm](https://www.tianmaying.com/tutorial/AndroidMVC)这些关键术语的掌握还是必要的
- Parcelable 是怎么实现跨进程的? ipc并不仅限于后台，客户端不同进程间也会有类似的概念。
- jdk8 standard Library implementation detail(java代码的实现 --> hotspot代码的c语言实现)
- [] 安装并使用MAT 分析java应用内存。


### 已完成
* 用 express 转接一个知乎 Api，添加 Access-control-allow-origin,或许还可以用 redis 缓存数据结果（一个就好）由此想到一篇文章"How to use Python to build a restful Web Service".只不过用的是 Tornado
* git hook (github travis 持续集成，git push 会触发服务器的一系列操作)
* 基于前后端分离的理念，后台只负责提供数据，render page 的任务应该交给前端。（所以用 express-handlebars 写页面的方式写着很累）
* 集成 travis-ci，记得 after-success script 的结果并不会影响 build 的结果（即，after-success 执行脚本发生了错误，在日志里有输出 error，但实际显示的 build result 仍为 success），还有 travis 的输出 log 需要默认是折叠的，要展开才能看清楚，但在 afterSuccess 里面的指令的输出一定是有的。
* 随便放一个文件到/usr/bin/就可以直接调用这个文件名来起这个命令了吗？（实际操作只需要建立一个symbolic link就好了）
* 单个网卡最多65535个端口，c10K。[65536其实不是操作系统限制的，而是tcp协议就只给port留了2个bytes给source port，只留了2个bytes给destination port](https://www.zhihu.com/question/66553828)端口号写在tcp包里，ip地址不是，ip地址是ip层的事情
* oAuth2原理，其实流程上和很多客户端的微信登陆，新浪微博登陆很像的
* 在Android手机上尝试用一个unix domain socket用于localhost进程间ipc(其实就是保证端口号一致，给网络权限就好了)
* 写 groovy 用intelij全家桶就可以了，groovy的[语法](https://www.tutorialspoint.com/groovy/groovy_closures.htm)其实没什么，主要是了解编译的流程和基本原理，这个需要看[official doc](https://docs.gradle.org/current/userguide/build_lifecycle.html#sec:build_phases)
* [开发gradle plugin优化MultiDex](https://github.com/JLLK/gradle-android-maindexlist-plugin)。长远来看，5.0以后的手机越来越多，MultiDex也不值得过于关注。
* intelij 点击run 实际调用的command line是两个，一个是javac，编译出来的class文件放到了target文件夹，紧接着用java命令带上一大串classpath去调用主函数
* [Android Studio 编译过程](https://fucknmb.com/2017/05/11/Android-Studio-Library%E6%A8%A1%E5%9D%97%E4%B8%ADNative%E4%BB%A3%E7%A0%81%E8%BF%9B%E8%A1%8Cdebug%E7%9A%84%E4%B8%80%E4%BA%9B%E5%9D%91/)，其实就是gradle assembleXXX 好了之后adb push到手机上，再安装，最后起主界面
* [Android 编译及 Dex 过程源码分析](http://mouxuejie.com/blog/2016-06-21/multidex-compile-and-dex-source-analysis/)
* [如何调试 Android 打包流程？](http://www.wangyuwei.me/)，一个remote的事
* [一个用于优化 png 图片的 gradle 插件](https://github.com/chenenyu/img-optimizer-gradle-plugin)，用来看 groovy 语法挺好的。以及 [How to write gradle plugin](http://yuanfentiank789.github.io/2017/09/20/%E5%9C%A8AndroidStudio%E4%B8%AD%E8%87%AA%E5%AE%9A%E4%B9%89Gradle%E6%8F%92%E4%BB%B6/)
* XSS 攻击,DOM based和Stored XSS,基本上就是不要相信用户的输入，除了合法输入以外一律过滤掉
- websocket nodejs，局限性就是前后台都得用socket.io的库。前端是浏览器的话还好，app的话java,Android都有对应的实现.[其实就是socket io] 
- [X]一直不会maven是在是太丢人了[看文档就行了](https://maven.apache.org/guides/getting-started/index.html#How_do_I_make_my_first_Maven_project)，其他的[教程](https://www.tutorialspoint.com/maven/maven_build_life_cycle.htm)也不错
- [使用Spring boot后台提供protobuf接口实现客户端通信] 不要使用protobf-gradle-plugin了。直接写脚本用protoc去生成文件，指定生成文件的路径要和proto里面写的包名对的上。另外就是客户端和server端依赖的protobuf版本以及protoc工具的版本得一致，比如都是3.5。还有就是protoc的语法，什么import的比较烦。
- [X] 使用jinja2生成文件。[一个比较好玩的代码生成器](https://github.com/guokr/swagger-py-codegen)
- [X] URL Encoding,就是那个在网址里把字符转成百分号加上UTF-8的[找到了阮一峰老师的解释](http://www.ruanyifeng.com/blog/2010/02/url_encoding.html)
- [X] 通过file input上传图片，原生ajax以及Ajax，自己搭建上传服务器[大概能猜到暴风影音的局域网传输实现了](https://zhuanlan.zhihu.com/p/24513281?refer=flask)用flask的话自己搭建好后台最简单了，最多再使用flask-wtf和flask-upload规范操作
- [X]Promise 链式调用与终止，异常处理(只是一个工具而已)
- [X] Android 应用接入bugly热修复，上线之后就不用背锅了（有兴趣看看sevenZip.jar，暂时没看）
- [X] [简直碉堡了的博客](http://normanmaurer.me/blog/2013/11/09/The-hidden-performance-costs-of-instantiating-Throwables/)以及jvm 的inline等优化
- [ ] [如何写makefile](https://seisman.github.io/how-to-write-makefile/introduction.html)其实[这个更加friendly](http://www.cs.colby.edu/maxwell/courses/tutorials/maketutor/)
- [X] [libmp3lame移植到Android](https://www.jianshu.com/p/534741f5151c),该教程针对的lame版本是3.99.5
- [scheme 这东西算跨客户端平台的](https://sspai.com/post/31500)，比如在 App 中调起支付宝(用的是 alipayqr://)。其实就是一个系统内跨应用调用。[用法](http://blog.csdn.net/qq_23547831/article/details/51685310)
这个主要是ios app之间通信的协议，以及快速跳转某个app某个页面的功能实现，还有x-callback-URL这样类似的协议。不过有了3d-touch之后，很多app都能长按图标进入页面，所以url scheme这个功能只能说是不复往日辉煌了
- [X]linux的sed命令(文本替换比较常用)
- [nio](https://juejin.im/post/59fffdb76fb9a0450a66bd58) 还是netty好。也可以看点别的[并发编程网](http://ifeve.com/java-nio%E7%B3%BB%E5%88%97%E6%95%99%E7%A8%8B%EF%BC%88%E5%8D%81%E5%85%AD%EF%BC%89-java-nio-files/)
- [X]js 的async await,就是一个async修饰一个method，里面随便写await
- [X] Linux下TCP延迟确认机制
- [X]c语言的[libevent使用教程](https://yq.aliyun.com/articles/413601) eventloop，添加回调，大致的流程就是这样
- [X] [indexed DB](http://www.ruanyifeng.com/blog/2018/07/indexeddb.html),浏览器端数据库，还是用第三方库好
- [X] [block size vs page size](http://forums.justlinux.com/showthread.php?3261-Block-size-vs-page-size) Page是内存相关，block是硬盘相关的
- [X] python 的asyncio(eventloop , generator, coroutine)
- [X][Vim cheet sheet](https://vim.rtorr.com/) vim多用用就熟悉了。
- [X] python dunder class复习。知道有python descriptor这回事就行了。
- [X] form表单可以跨域一个是历史原因要保持兼容性（就是说跨域这件事，一个域名的 JS ，在未经允许的情况下，不得读取另一个域名的内容。但浏览器并不阻止你向另一个域名发送请求。所以post的表单可以发出去，但是别指望能够拿到response）
- [X] a new article on open-gl intro(在Android平台上要和MediaCodec相关的音视频格式结合着来一起看)
- [X] JavaScript中new FileReader(属于html5的东西)，以及canvas api(lineTo,quardTo这些都是相近的),以及[js进行图片缩放和裁剪](https://juejin.im/post/5a98c5c26fb9a028d82b34ee) 
- [X] tcp-proxy实用教程 
- [X]Exoplayer and the MediaCodec api[building-a-video-player-app-in-android](https://medium.com/androiddevelopers/building-a-video-player-app-in-android-part-3-5-19543ea9d416) 
- [AC2016腾讯前端技术大会 1 1 1 H5直播那些事](https://www.youtube.com/watch?v=g3F7Imjcd4k)
- [X] tcp-proxy实用教程(tcp replay or udp relay)
- [X] render-script utility
- [X]C语言fork进程以及进程之间通信的套路
- [X] flex,grid. css的box-size真是坑人
- [X] rxjava是如何切换线程的以及源码解析，ObserveOnObserver和ObservableSubscribeOn实例是桥梁
- [X] jdk7开始提供fork join pool方法，将任务分配到多个线程上处理(不适合io密集型操作)
- [X] [openjdk的C语言实现可以随便调几处来看看](https://github.com/keerath/openjdk-8-source/blob/master/jdk/src/windows/native/java/net/SocketOutputStream.c)


 
### Good For Nothing
- [ ] 用GDB调试程序
- [ ] npm install graphql(mostly a server side javascript stuff)
- 使用 express 模拟网络延迟
- [基于 Docker 打造前端持续集成开发环境](https://juejin.im/post/5a157b7a5188257bfe457ff0)
- vS Code Vender Prefix plugin => auto prefix loader
- 前后端分离
- sql漏洞
- [深入浅出腾讯云 CDN：缓存篇](https://cloud.tencent.com/developer/article/1004755)不管SSD盘或者SATA盘都有最小的操作单位，可能是512B，4KB，8KB。如果读写过程中不进行对齐，底层的硬件或者驱动就需要替应用层来做对齐操作，并将一次读写操作分裂为多次读写操作。
- Android进程的[加载流程](https://juejin.im/post/5a646211f265da3e3f4cc997)
- 前后端同构
- [install nginx , jenkin ci, deploying nginx in docker(Http Load Balaning with Docker and nginx)](https://www.digitalocean.com/community/tutorials/how-to-configure-nginx-with-ssl-as-a-reverse-proxy-for-jenkins)
- [ ] 网易云音乐API
- [X] Django部署个人网站(Gunicorn，Nginx)。django写template就不是前后端分离了
- [ ] Docker[intro-to-docker-building-android-app](https://medium.com/@elye.project/intro-to-docker-building-android-app-cb7fb1b97602) 这篇文章其实是两件事，一个是Build docker image(docker build xxxx),另一个是run (docker run xxx)
- [ ] [和网页类似，Activity也有一个referer的概念](https://blog.csdn.net/u013553529/article/details/53856800)，用于判断当前页面是由谁发起请求的
OpenType® is a cross-platform font file format developed jointly by Adobe and Microsoft.
- [ ][deploying owncloud using docker](https://blog.securem.eu/serverside/2015/08/25/setting-up-owncloud-server-in-a-docker-container/)
- [owncloud官方的配合docker安装教程](https://doc.owncloud.org/server/10.0/admin_manual/installation/docker/)网盘这种东西看个人喜好了
- [ ]CloudFlare cdn解析以及DNS防护 
- [ ] [python c extension](https://www.tutorialspoint.com/python/python_further_extensions.htm) 
- [ ] [最简单的一个用go写出来的rest api大概长这样](https://github.com/elliotforbes/tutorialedge-rest-api)
- [ ][分词器](https://lxneng.com/posts/201)
- [ ][LOGSTASH+ELASTICSEARCH+KIBANA处理NGINX访问日志](http://www.wklken.me/posts/2015/04/26/elk-for-nginx-log.html)ELK全家桶, logstash接管软件日志
- [ ] [如何编写 jQuery 插件](https://gist.github.com/quexer/3619237)
- netfilter框架(imbedded in linux server)


[jsonplaceholder](https://jsonplaceholder.typicode.com/)懒得自己写api的话
就用这个吧


<script>console.log("hey there")</script>


