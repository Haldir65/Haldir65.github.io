---
title: 安卓坐标系常用方法
date: 2016-10-13 18:17:02
categories: blog
tags: [android,TouchEvent]
---
记录一些Android系统坐标系的常用方法，因为日常开发中难免会碰到需要单独计算View系统坐标的情况。

![](http://www.haldir66.ga/static/imgs/minion.jpg)
<!--more-->

ScrollTo，ScrollBy，getVisibleRect这些方法平时想要用的时候总要去网上查找，这里记录下来，方便今后直接参考
首先是一张很多人都见过的图
![](http://www.haldir66.ga/static/imgs/android_screen_coordinate_system.png)
中间的蓝色的点是TouchEvent发生时，获得的MotionEvent.getX()、getY()。
### 1. 坐标原点和坐标轴方向
坐标原点有两种，屏幕左上角（statusBar也包含其中）和父控件左上角
坐标轴方向：X轴向右，Y轴向下，Z轴(5.0增加)向上。


### 2. Left,Top,Right,Bottom
而Top，left，bottom,down分别对应着其其相对于父控件的距离，由此可以计算得到View的宽度width = getRight()-getLeft() ,View的高度 height = getBottom()-getTop()
而实际上view.getHeight()方法的实现也就是mBottom-mTop.


### 3. X , Y
X代表的是当前View的左上角那个点的横坐标，Y代表的是纵坐标。
X = left + getTranslationX  
Y = Top + getTranslationY
通常在动画中使用setTranslationX来实现偏移效果，注意，这是不会改变left的。在滑动过程中，x, y会随着改变。

### 4. 几个跟Rect相关的
获得的是当前View左上角距离屏幕左上角的位置，为此我专门测试了一下
>  W/ViewAnimationActivity.java: [32 | onWindowFocusChanged]statusBarHeight = 75
>  W/ViewAnimationActivity.java: [35 | onWindowFocusChanged]getLocationInWindow  x = 0 y = 75
>  W/ViewAnimationActivity.java: [38 | onWindowFocusChanged]getLocationOnScreen x = 0 y = 75
可以看到返回的就是View左上角的坐标，一般情况下两者区别不重要，stackoverFlow上有[讨论](http://stackoverflow.com/questions/17672891/getlocationonscreen-vs-getlocationinwindow)

```java
View.getLocationInWindow(pos); //获取在当前window内的绝对坐标
View.getLocationOnScreen(pos); //包括statusBar，以屏幕左上角为坐标原点
View.getLocalVisibleRect()  
//以view自身的左上角为坐标原点，这个很有用，
//返回的坐标一定是(0,0,xxx,xxx)这样的，可以判断当前View是否完全可见
View.getGlobalVisibleRect()  // 以屏幕左上角为坐标原点
```
以上四个方法在onCreate里面返回的值都是0，需要在Activity的onWindowFocusChanged(true)中去获得
这里需要扯一点关于window的问题，根据大部分博客的介绍：DecorView是FrameLayout的子类，是View视图层级树的根节点。
一般会有一个LinearLayout的child

为此，我在setContentView里面放了一个CoordinateLayout,使用Hierarchy View截图的到这样的结果。
图片有点大
![](http://www.haldir66.ga/static/imgs/view_hirearchy_1013.png)

在ViewHirearchy中可以看到，Activity中View视图层级从上到下依次为：

> PhoneWindow$DecorView（有三个child,分别是LinearLayout，View(id/statusBarBackground)和View(id/navigationBarBackground)）
> LinearLayout
> FrameLayout
> FitWindowsLinearLayout
> ContentFrameLayout(id/android.R.id.content) //这在开发过程中有时会用到
> setContentView设置的view

关于window，DecorWindow的文章网上有很多，仔细研究下会对理解View的测量机制有一定好处，这对于View的工作原理也能够更彻底的理解。
[参考文章](http://blog.csdn.net/qibin0506/article/details/49245601)
日常开发中，setContentView这个方法只是将我们自己写的activiy_main.xml布局文件inflate出来的view添加到
android.R.id.content这个ViewGroup中，实践下来发现这是一个ContentFrameLayout的实例，它的child只有一个，就是我们通过setContentView添加的View

### 5. 让View滑动起来
> offsetLeftAndRight(int offset) //给left和right加上一个值，改变的是View的位置
> offsetTopAndBottom(int offset)

> scrollTo(int x,int y)  // 将View中的内容移动，坐标原点为parentView左上角，注意，参数为正，效果为反
例如scrollTo(-100,0) 在手机上看效果是往右移动了

> scrollBy(int x, int y)

scrollBy的源码如下:
```java
  public void scrollBy(int x, int y) {
        scrollTo(mScrollX + x, mScrollY + y);
    }
```
还有一些不常用的：
```java
public void setScrollX(int value) {
        scrollTo(value, mScrollY);
    }
```

### 6. 改变LayoutParams的margin让View移动
这是一种很生硬的方式，不常用
```java
MarginLayoutParams params = (MarginLayoutParams)mTextView.getLayoutParams(); //可能为null
params.leftMargin + = 100;
mTextView.setLayoutParams();// 这里面调用了requestLayout
```


### 7.使用Animation让View动起来
根据官方文档的[定义](https://developer.android.com/guide/topics/graphics/overview.html)Android中一共两种Animation:
> Property Animation
> View Animation(包括Tween animation, Frame animation)

首先从package的位置来看
属性动画都位于android.animation这个package下面，常见的如ObjectAnimator继承自ValueAnimator
View动画则位于android.view.animation这个package下，常见的如TranslateA,AlphaAnimation等

View Animation可以代码创建，也可以写在R.anim文件夹下,用法很简单
```java
ImageView image = (ImageView) findViewById(R.id.image);
Animation hyperspaceJump = AnimationUtils.loadAnimation(this, R.anim.hyperspace_jump);
image.startAnimation(hyperspaceJump);
```
属性动画可以代码创建，也可以写在R.animator文件夹下,用法:
```java
AnimatorSet set = (AnimatorSet) AnimatorInflater.loadAnimator(myContext,
    R.anim.property_animator);
set.setTarget(myObject);
set.start();
```
推荐使用ViewPropertyAnimator，这是一个位于android.view下面的class，感觉更像是一个Util,大部分的方法都是在API 12 ,API 14引入的，
实际开发中推荐使用ViewCompat.animate() 返回一个ViewPropertyAnimator对象，省去了开发者版本判断的麻烦
语法更为简单：
```java
ViewCompat.animate(view).x(500).y(500).setDuration(5000).setInterpolator(new DecelaratorInterpolator());  //不需要调用start()
```
据说这种方式性能最好，Google官方强烈推荐,参考DevByte。
另外，据说大部分Google的App使用的都是DecelaratorInterpolator，当然这跟设计有关。

### 8.使用Scroller实现smoothScroll
View有一个方法computeScroll(),复写，像这样就可以了
```java
Scroller scroller = new Scroller(mContext);

 private void smoothScrollTo(int dstX, int dstY) {
      int scrollX = getScrollX();
      int delta = dstX - scrollX;
      scroller.startScroll(scrollX, 0, delta, 0, 1000);
      invalidate();
 }

 @Override
 public void computeScroll() {
     if (scroller.computeScrollOffset()) {
         scrollTo(scroller.getCurrX(), scroller.getCurY());
         postInvalidate();
     }
 }
```

### 9. 补充几个好玩的函数
View.canScrollVertically(int)
```java
 public static boolean canChildScrollUp(View view) {
        if (android.os.Build.VERSION.SDK_INT < 14) {
            if (view instanceof AbsListView) {
                final AbsListView absListView = (AbsListView) view;
                return absListView.getChildCount() > 0
                        && (absListView.getFirstVisiblePosition() > 0 || absListView.getChildAt(0)
                        .getTop() < absListView.getPaddingTop());
            } else {
                return view.getScrollY() > 0;
            }
        } else {
            return view.canScrollVertically(-1);
        }
    }
```
这段是我在秋百万的android-ultra-pulltorefresh里面找到的，想当初为了自己写下拉刷新，一遍一遍的打Log，最后甚至用上getVisibleRect才算搞定。
其实很多东西前人已经帮我们整理好了。
对了这东西在v4包里有ViewCompat.canScrollVertically，v4包除了方法数有点多(10k+好像)这点不好以外，一直都很好用
附上supportLibrary各个包的方法数，如果对65536这个数字熟悉的话，还是会注意点的。
![pic](http://www.haldir66.ga/static/imgs/support_lib_methods_summary.jpg)



### 总结
- 使用getLocalVisibleRect可以判断一个view是否完全可见
- scrollBy,setScrollX等内部都是调用了scrollTo方法，ScrollTo方法传参数与实际效果是相反的

## updates
Android device Monitor里面有一个Dump UI Hierarchy for UI Automator，直接查看视图层级




### Reference
1. [Android应用坐标系统全面详解](http://blog.csdn.net/yanbober/article/details/50419117)
2. ​[如何取得View的位置之View.getLocationInWindow()的小秘密](http://blog.csdn.net/imyfriend/article/details/8564781
3. [详解实现Android中实现View滑动的几种方式](http://www.cnblogs.com/absfree/p/5352258.html)
