---
title: css预处理语言
date: 2017-12-26 22:36:49
tags: [前端]
---

css预处理语言简介
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/bokeh street lights city art blue.jpg?imageView2/2/w/600)
<!--more-->


css预处理语言允许我们以更简单的方式编写样式，通过编译生成浏览器能够使用的css文件。

1. [Sass](http://sass-lang.com/) 诞生于 2007 年，Ruby 编写，其语法功能都十分全面，可以说 它完全把 CSS 变成了一门编程语言。另外 在国内外都很受欢迎，并且它的项目团队很是强大 ，是一款十分优秀的预处理语言。
2. [Stylus](http://stylus-lang.com/) 诞生于 2010 年，来自 Node.js 社区，语法功能也和 Sass 不相伯仲，是一门十分独特的创新型语言。
3. [Less](http://lesscss.org/) 诞生于 2009 年，受Sass的影响创建的一个开源项目。 它扩充了 CSS 语言，增加了诸如变量、混合（mixin）、函数等功能，让 CSS 更易维护、方便制作主题、扩充（引用于官网）。

[比较这三种预处理语言](http://www.oschina.net/question/12_44255)



## 1. Less
> 安装
yarn add less
/ or install globally  /
yarn global add less
// Dead Simple LESS CSS Watch Compiler，实时监控less文件变化，更新到css
yarn add less-watch-compiler


> 使用
lessc styles.less // 并不会生成任何css文件
lessc styles.less styles.css //生成一个styles.css文件
新建一个style.less文件

```less
@background-color: #f4f4f4;
body {
  background-color: @background-color;
}
```
生成的css文件长这样：
```css
body {
  background-color: #f4f4f4;
}
```

```less
//有变量，可以进行数学运算
@line-height: 1em+1em;

//可以嵌套
@secondary-color: #20B2AA;
ul {
  background-color: @background-color;
  li {
    color: @secondary-color;
    a {
      line-height: @line-height;
    }
  }
}

// 有继承
.btn {
    padding: 10px 15px;
    border: 0;
    .border-radius(10px);
}

.primary-btn:extend(.btn){
    background: @primary-color;
    .text-color(@primary-color);
}



// 有函数（mixin），有没有入参都行
.bordered{
    border-top: dotted 1px #000;
    border-bottom: solid2px #000;
}

.border-radius(@radius) {
    border-radius: @radius;
}

//还有if statement
.text-color(@a) when (lightness(@a) > = 50% ){
    color: black;
}

.text-color(@a) when (lightness(@a) < 50% ){
    color: white;
}

```

**filepath**
比如经常把一些文件挪到其他位置了，这下在css中引用的位置全部都要换，
```less
@images: "images/"
@homepage-images: "images/homepage/"

img {
  background: url("@{images}fruit.png");
}
```


**import功能**
在main.less文件中
> @import header.less
@import menu.less
直接用




更多的使用直接去[Less](http://lesscss.org/)查找就好了

## 2.Stylus
>安装
yarn add stylus
yarn add stylus-loader


>使用
stylus -w style.styl -o style.css //w表示watch

```stylus
line-height = 10px
body
    margin: 0
    padding: 0
    h1
     color: #5e5e5e
     line-height: line-height
```

生成的css文件长这样
```css
body {
  margin: 0;
  padding: 0;
}
body h1 {
  color: #5e5e5e;
  line-height: 10px;
}
```

```stylus
// mixin也有
border-radius(n)
  -webkit-border-radius n
  -moz-border-radius n
  border-radius n

form input[type=button]
  border-radius(5px)
```
[官网](http://stylus-lang.com/)



=======================================================================================
### 6. Sss和Scss
SCSS 是 Sass 3 引入新的语法，其语法完全兼容 CSS3，并且继承了 Sass 的强大功能。也就是说，任何标准的 CSS3 样式表都是具有相同语义的有效的 SCSS 文件。
```css
@mixin rounded($amount) {
  -moz-border-radius: $amount;
  -webkit-border-radius: $amount;
  border-radius: $amount;
}
```
Sass本身不带花括号，加上花括号和分号就成了SCSS了.
