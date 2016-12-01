---
title: wrap_content到底多大
date: 2016-11-27 16:46:44
tags: android
---

转眼就十一月了，java的分析越来越少，虽然常常在业务上碰到不少坑。。。

#### 问题的由来
这周碰到一个需要画时间轴样式的自定义View的需求，大概像这样(图片来自网络)：
![](http://odzl05jxx.bkt.clouddn.com/timelineView.png)

要求，左侧的圆形节点可以自定义Drawable，右侧的文字高度随文字数量变化自适应。

想想也就是自定义ViewGroup的那一套老样子。抄起键盘就开始研(Copy)究(Paste)，写着写着发现不对劲，主要的问题包括: 

> 1. 在onMeasure里面拿到的height == 0 , 具体一点就是:
整个ViewGroup包含多个Item，每个Item包括左侧的自定义View(CustomView)，高度是wrap_content，右边的TextView高度是wrap_content(自适应嘛)。可是debug时发现左侧的自定义View拿到的高度是0，简直日了哈士奇了。随后拿着关键词去Google搜索，还是没有什么收获。


```java
 protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        final int widthMode = MeasureSpec.getMode(widthMeasureSpec);
        final int heightMode = MeasureSpec.getMode(heightMeasureSpec);// 这里是UNSPECIFIED, 常规概念里wrap_content对应的应该是AT_MOST
        final int widthSize = MeasureSpec.getSize(widthMeasureSpec);
        final int heightSize = MeasureSpec.getSize(heightMeasureSpec); // 居然等于0
    }

```
回顾这个Item的实现，Item继承自RelativeLayout，左边的View是调用addView(view,RelativeLayout.Layoutparams)加进去的,params设置了一些rules，像是AlignParentLeft这种，记得给左边的View和右边的TextView都设置一个id就好。TextView也是这样addView进去的。后来查到了秋百万对于MeasureSpec的介绍，我想到RelativeLayout的onMeasure会调用两次，在第一次测量的时候，左边的View和右边的TextView都把高度设置为wrap_content了。要命的是这个Item本身添加到UI的方式也是类似的addView(view,RelativeLayout.Layoutparams)方式，这里的height也是wrap_content。即Item本身高度需要由其child决定，左边的child决定不了，只有右边的TextView才能决定。所以第一轮测量下来，左边的View的高度只能是0，右边的TextView高度倒是确定了。这时候Item本身的高度也就能确定了。在第二遍测量的时候，就能顺利拿到高度了。

> 2. 左侧的每个节点上的drawable不画出来
后来查了下，原因在于我对传进来的drawable检查了大小，太大的话用一个ScaleDrawable转一下。但是，scaleDrawable需要调用setLevel方法才会draw，我这里偷懒直接设置为1了。


> 3. Item本身是继承自RelativeLayout，想要使onDraw方法被调用需要在构造函数里设置
setWillNotDraw(false) 
这个boolean值默认是true，主要是顾及到性能的原因。



### ref 
- [How Android caculates view size](https://www.liaohuqiu.net/posts/how-does-android-caculate-the-size-of-child-view/)