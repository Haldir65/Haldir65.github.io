---
title: fitSystemWindow和沉浸式状态栏的一些总结
date: 2016-10-14 17:15:47
categories: [技术]
tags: [Android,Window]
---
沉浸式状态栏是api 19之后引入的，KitKat应该算是一次比较大的更新了，像是Transition，art runtime,storage access FrameWork(这个有空研究下)，另外就是这个被官方称为Full-screen immersive mode的特性了。具体来说，App可以将展示的区域拓展到statusBar的位置了。我觉得直接叫statusBar就好了，大部分人应该也能理解这就是手机上显示"中国移动"还有显示手机电量那一块的长条，宽度是match_parent。高度的话，据说是25dp，然后6.0上给改成了24dp。不过，![](http://odzl05jxx.bkt.clouddn.com/4dab298b9f7ce29c43f9d8eaf686e02f.jpg)<!--more-->

### 1.最初的做法
看到有人推荐使用[SystemBarTint](https://github.com/jgilfelt/SystemBarTint)这个class,刚上来觉得也挺好用的，就是一个java class，直接复制粘贴到项目里，改一下package name，无脑使用即可。原理的话，看过源码后，大致明白是在statusBar的位置添加一个new View，然后持有这个view的引用，接下来就可以做常规的setBackground或者setBackgroundColor了。初始化时的关键代码。
```java
private void setupStatusBarView(Context context, ViewGroup decorViewGroup) {
        mStatusBarTintView = new View(context);
        LayoutParams params = new LayoutParams(LayoutParams.MATCH_PARENT, mConfig.getStatusBarHeight());
        params.gravity = Gravity.TOP;
        if (mNavBarAvailable && !mConfig.isNavigationAtBottom()) {
            params.rightMargin = mConfig.getNavigationBarWidth();
        }
        mStatusBarTintView.setLayoutParams(params);
        mStatusBarTintView.setBackgroundColor(DEFAULT_TINT_COLOR);
        mStatusBarTintView.setVisibility(View.GONE);
        decorViewGroup.addView(mStatusBarTintView);
    }
```
看起来一切都很美好


### 2. 直到碰到了fitSystemWindow = ture
几个月前曾经在项目里写过一个普通的Coordinatelayout内部CollapingToolbarLayout的沉浸式状态栏实现，当时为了赶进度一直试到夜里2点才尝试出在4.4和5.0以上手机都能满意的效果。现在想想有些事还是能够事先搞清楚的好，被动学习的代价实在太大。当时的方法是给Toolbar添加了一个顶部的padding，