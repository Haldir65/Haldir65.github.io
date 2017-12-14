---
title: repository for thoughts on droid
date: 2017-12-08 22:33:26
tags: [android,tools]
---

之前的文章快装不下了，所以另外开一篇文章专门放Android相关的杂乱的知识点。
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/scenery1511100734648.jpg?imageView2/2/w/600)
<!--more-->


[Android Source code](https://android-review.googlesource.com)，能够实时看到提交信息
[From View to Pixel](https://www.youtube.com/watch?v=CMzCccqE_R0)讲了ViewRootImpl,SurfaceFlinger这些东西
[一个很长的关于显示原理的文章](https://juejin.im/post/5a1e8d5ef265da431280ae19)，基本上什么都讲了



### 1.基本上所有的Android System Event都是从ActivityThread中发起的
onDetachedFromWindow是从ActivityThread的handleDestoryActivity传下来的，走到windowManager.removeViewImediate,然后ViewRootImpl.doDie,然后ViewRootImpl.dispatchDetachedFromWindow，然后DecoreView.dispatchDetachedFromWindow，然后一个个child传下去。所有的View走完了之后，DecorView在onDetachedFromWindow中以Window.Callback的方式顺手通知了Activity的onDetachedFromWindow。其实打个断点看的话就快一点。

### 2. onSaveInstance对于有id的View，系统会自动帮忙存一点东西
当然onSaveInstance也是从ActivityThread里面传递下来的。还有就是onCreate(Bundle)和onRestroreSaveInstanceState(Bundle)里面的bundle是同一个object。romain Guy说最初onSaveInstance和onRestroreSaveInstanceState本来叫onIcy(冻结)和onThaw（解冻），确实很形象。

### 3.android asset atlas
就是为了节省asset耗费的内存，将一些系统公用的资源作为一个服务先跑起来，所有app的process共用这部分资源。

### 4. ZygoteInit


### 5. Michael Bailey每年的演讲都很精彩
[Droidcon NYC 2015 - How the Main Thread works](https://www.youtube.com/watch?v=eAtMon8ndfk)
[Droidcon NYC 2016 - How LayoutInflater works](https://www.youtube.com/watch?v=Y06wmVIFlsw)
[droidcon NYC 2017 - How Espresso Works](https://www.youtube.com/watch?v=7lCsp84wVPM)

### 6. Chris Banes在2017年给出了关于状态栏的解释
[droidcon NYC 2017 - Becoming a master window fitter](https://www.youtube.com/watch?v=_mGDMVRO3iE)

### 7. Android默认的launcher的repo在
[Launcher3](https://android.googlesource.com/platform/packages/apps/Launcher3/),应该是属于System UI Team在维护。

### 8. 在string.xml里面放一些format的字符

```java
public static void main(String[] args) {
   String s1 = "这里面可以放多个字符串%1$s,%2$s前面加上一个百分号和数字，代表顺序";
   String s2 = "百分号的d和百分号的s可以混着%1$s用的，比如这个%2$d数字什么的，第三个是带百分号的数字%3$d%%这个由于需要显示百分号，所以加上两个百分号";

   System.out.println(String.format(s1,"XXXX","XXX"));
   System.out.println(String.format(s2,"XXX", 100, 100));
}
```
实际输出
> 这里面可以放多个字符串XXXX,XXX前面加上一个百分号和数字，代表顺序
百分号的d和百分号的s可以混着XXX用的，比如这个100数字什么的，第三个是带百分号的数字100%这个由于需要显示百分号，所以加上两个百分号
