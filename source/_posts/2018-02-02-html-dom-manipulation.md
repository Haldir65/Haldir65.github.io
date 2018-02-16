---
title: DOM操作手册
date: 2018-02-02 23:30:25
tags: [前端]
---

HTML Document操作手册
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/2138000245bee1e3cc14.jpg?imageView2/2/w/600)

<!--more-->
使用javaScript操作dom的记录
## 拦截form的submit
[how-to-prevent-form-from-being-submitted](https://stackoverflow.com/questions/3350247/how-to-prevent-form-from-being-submitted)
```html
<form onsubmit="return mySubmitFunction()">
  <label for="this is the text before the value"type='text'></label>
  <label type='text'></label>
</form>
```
在mySubmitFunction()中return false并不能阻止表单被提交。
正确的做法
```js
const element = document.querySelector('form');
element.addEventListener('submit', event => {
  event.preventDefault();
  // actual logic, e.g. validate the form
  console.log('Form submission cancelled.');
});
```

### a标签的事件绑定
```html
<a href="javascript:;"></a>
<a href="javascript:void(0)"></a>
```

## input file选出来的图片路径
[c-fakepath](https://stackoverflow.com/questions/4851595/how-to-resolve-the-c-fakepath).浏览器并不会将底层的文件实际路径暴露给开发者，这是出于安全考虑。所以使用
```js
document.querySelectorAll('input')[3].value
"C:\fakepath\image_7.jpg" //所以一般要用string.split('\\')处理一下
```

### 被document.getElementById坑了
一个html页面只能有一个id的规则都知道，可是偏偏一个页面写了两个id一样的tag，网页照样跑，console没有任何报错。但是使用document.getElementById的时候，拿到的就是第一个。浏览器还真是能容错啊。
顺便记录下vanilla js和jQuery detect 一个file input的方法
```js
const input2 = document.getElementById('file_2');
input2.addEventListener('change', () => {
  showPreview2(this.id,'portrait2');
})

$('#file_2').on('change', () => {
  showPreview2('file_2','portrait2');
})

$('#file_2').change( () => {
  showPreview2(this.id,'portrait2');
})
```

### 为毛浏览器内嵌视频要用iframe
因为video source是host在其他的sites的啊，因为跨域的问题，不得不使用iframe。因为就算用iframe，里面其实还是一个vide的tg。
