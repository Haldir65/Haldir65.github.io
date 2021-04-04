---
title: css3速查手册
date: 2017-12-09 17:56:06
tags: [前端]
---

一份css3知识汇总
![](https://api1.foster57.tk/static/imgs/scenery1511100802774.jpg)
<!--more-->


### Animation
```css
.box{
    background: white;
    width: 200px;
    height: 200px;
    position: relative;
    animation-name: mayanimation;
    animation-duration: 4s;
    animation-iteration-count: 1;
    animation-fill-mode: forwards; /* forwards表示动画完成后，stay as the end of animation */
    animation-delay: 2s;
    animation-direction: alternate;
    animation-timing-function: ease-out;
}


@keyframes myanimation {
  0% {background-color: white;left:0px;top:0px;border-radius: 0 0 0 0 ;}
  25%{background-color: red;left: 300px;top: 0px;border-radius: 50% 0 0 0 }
  50%{background-color: green;left: 300px;top: 300px;border-radius: 50% 50% 0 0 }
  75%{background-color: blue;left: 0px;top: 300px;border-radius: 50% 50% 50% 0}
  100% {background-color: white;left: 0px;top: 0px;border-radius: 50% 50% 50% 50%}
}
```

***需要注意的是，如果animation的duration不写的话，是不会生效的***

### Transition
基本就是pseudo selector之间相互变化的时候，在新的状态和原本的状态之间属性变化切换的动画。
Transition这个词应该是卡通中使用的，用于显示from state到to state之间的过渡。

```css
.box{
    background: white;
    width: 300px;
    height: 300px;
    position: relative;
    margin: auto;
    top: 200px;
    text-align: center;
    vertical-align: middle;
    transition-property: all;
    transition-duration: 1s;
    transition-timing-function: linear;
}

.box:hover{
    background: red;
    border-radius: 50%;
    transform: rotateY(180deg);
}
```

***和animation一样，如果transition的duration不写的话，是不会起效的***

[prefers-color-scheme: Hello darkness, my old friend](https://web.dev/prefers-color-scheme/)
prefers-color-scheme这个media

- [css-flex-box-guide](https://css-tricks.com/snippets/css/a-guide-to-flexbox/)
