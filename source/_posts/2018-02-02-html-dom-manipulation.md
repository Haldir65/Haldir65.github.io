---
title: DOM操作手册
date: 2018-02-02 23:30:25
tags: [前端]
---

HTML Document操作手册
![](https://www.haldir66.ga/static/imgs/2138000245bee1e3cc14.jpg)

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
因为video source是host在其他的sites的啊，因为跨域的问题，不得不使用iframe。因为就算用iframe，里面其实还是一个video的tg。

### html js是不能写文件的
node js提供了fs api来进行文件读写，浏览器中js不能读写本地文件。(html5提供了localStorage api，但最大容量好像是5MB，通过浏览器读文件也必须用户手动触发选择)

### 头一次听说noscript这种东西
```html
<html>
   <body>

      <script language="javascript" type="text/javascript">
         <!--
            document.write("Hello World!")
         //-->
      </script>

      <noscript>
         Sorry...JavaScript is needed to go ahead.
      </noscript>

   </body>
</html>
```
如果浏览器不支持javascript的话，noScript中的内容就会显示出来

### document对象的所有方法在[mdn](https://developer.mozilla.org/zh-CN/docs/Web/API/Document/createTextNode)上都有

### js操作cookie的方式
随便开一个网页，在console中输入document.cookie就可以看到设置的cookie
或者在chrome的resource tab中也能看到
js能够操作cookie的前提是cookie中没有HttpOnly=true 字段
```js
document.cookie = "key1=value1;key2=value2;expires=date";
```

[js里面没有deleteCookieByNameOrDomain这种方法](https://jameshfisher.com/2018/12/22/what-is-document-cookie/) 都是用设置expire的方法删掉cookie，还有一些坑


### 浏览器信息一般在Navigator对象里面拿
```js
var browsername=navigator.appName;
if( browsername == "Netscape" )
{
   window.location="http://www.location.com/ns.htm";
}
else if ( browsername =="Microsoft Internet Explorer")
{
   window.location="http://www.location.com/ie.htm";
}
else
{
   window.location="http://www.location.com/other.htm";
}
```
navigator里面常用的还有platform,userAgent等
随便在chrome里面试了下
navigator.appName ==> Netscape
navigator.platform ==> win32

[在浏览器里操作cookie可以用原生api自己去操作string，但推荐使用成熟的库](https://github.com/js-cookie/js-cookie)


文件上传一般使用file tag就可以了
这种是单文件的
```html
<form action="" method=post enctype=multipart/form-data>
      <input type=file name=file>
      <input type=submit value=Upload>
</form>
```
```html
<form action="/upload" method="post">
选择图片：<input type="file" name="img" multiple="multiple" />
<input type="submit" />
</form>
<p>请尝试在浏览文件时选取一个以上的文件。</p>
```

html中有data标签[文档](https://developer.mozilla.org/en-US/docs/Learn/HTML/Howto/Use_data_attributes)
```html
<article
  id="electriccars"
  data-columns="3"
  data-index-number="12314"
  data-parent="cars">
...
</article>
```

js里面可以这样去获取对应的值
```js
var article = document.getElementById('electriccars');
 
article.dataset.columns // "3"
article.dataset.indexNumber // "12314" 注意dash被替换成了CamelCase
article.dataset.parent // "cars"
```