---
title: react-native-cookbook
date: 2018-01-19 22:28:34
tags: [前端]
---

![](http://odzl05jxx.bkt.clouddn.com/image/jpg/iu kpop star music sony.jpg?imageView2/2/w/600)

<!--more-->

install cli

>npm install -g react-native-cli
react-native init myproject ## 最好全部小写字母
cd myproject
react-native run-android
注意，可能会报错
```
FAILURE: Build failed with an exception.
* What went wrong:
A problem occurred configuring project ':app'.
> SDK location not found. Define location with sdk.dir in the local.properties file or with an ANDROID_HOME environment variable.
```

新建一个local.properities文件，放到android 文件夹下面就好了

[unable-to-load-script-from-assets-index-android-bundle-on-windows](https://stackoverflow.com/questions/44446523/unable-to-load-script-from-assets-index-android-bundle-on-windows)

在android手机上打开显示布局边界，发现react-native app并不是一个webview，而是一个个实在的buttom,text。

### tips
目前暂不支持java 9
Double tap R on your keyboard to reload其实并不是按电脑键盘上的R，而是模拟器上的，所以需要鼠标上去，ctrl+m即可
如果是一台真实手机的话，需要摇一摇手机，就能显示菜单。但是每次都要摇一摇实在是太麻烦，所以点一下那个Enable LiveReload就能在每次保存文件后Reload。
注意，如果更改了state，那么hotReload没用，需要手动Reload

npm run start是用来起dev server的。
react-native run-android是用来向client端推更新的。

could not connect to development server...的原因就是没有运行npm start。

所以，正常的流程应该是npm start && react-native run-android

debug:
react-native run-android是把这个App安装到手机上，然后terminal就返回了，需要查看后续日志输出的话
react-native log-android // 这个是帮助在console中输出log


## styling
inline styling在每一个tag的后面跟上两个大括号，
styling as seprate file在后面跟一个大括号，引用style对象的properity


==========================
async storage
Navigator is deprecated,use stack navigator
camera Roll

<!-- <audio src="http://m10.music.126.net/20180121230941/8d878803b3b0542d9c5482ccf613a86b/ymusic/d95e/bab6/a7f5/864661168da79b309c3d2fac971d1698.mp3" autoplay="autoplay">
您的浏览器不支持 audio 标签。
</audio> -->
