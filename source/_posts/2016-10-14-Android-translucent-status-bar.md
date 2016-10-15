---
title: fitSystemWindow和沉浸式状态栏的一些总结
date: 2016-10-14 17:15:47
categories: [技术]
tags: [Android,Window]
---
沉浸式状态栏是api 19之后引入的，KitKat应该算是一次比较大的更新了，像是Transition，art runtime,storage access FrameWork(这个有空研究下)，另外就是这个被官方称为Full-screen immersive mode的特性了。具体来说，App可以将展示的区域拓展到statusBar的位置了。我觉得直接叫statusBar就好了，大部分人应该也能理解这就是手机上显示"中国移动"还有显示手机电量那一块的长条，宽度是match_parent。高度的话，据说是25dp，然后6.0上给改成了24dp。不过![](http://odzl05jxx.bkt.clouddn.com/Trying%20stuff%20Untill%20it%20work.jpg?imageView2/2/w/600)<!--more-->

### 1.最初的做法
看到有人推荐使用[SystemBarTint](https://github.com/jgilfelt/SystemBarTint)这个class,刚上来觉得也挺好用的，就是一个java class，直接复制粘贴到项目里，改一下package name，无脑使用即可。原理的话，看过源码后，大致明白是在statusBar的位置添加一个new View，然后持有这个view的引用，接下来就可以做常规的setBackground或者setBackgroundColor了。初始化时的关键代码如下
```java
private void setupStatusBarView(Context context, ViewGroup decorViewGroup) {//这个decorViewGroup指的是activity.getWindow()
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
一切看起来都很美好


### 2. 直到碰到了fitSystemWindow = ture
几个月前曾经在项目里写过一个普通的Coordinatelayout内部CollapingToolbarLayout的沉浸式状态栏实现，当时为了赶进度一直试到夜里2点才尝试出在4.4和5.0以上手机都能满意的效果。现在想想有些事还是能够事先搞清楚的好，被动学习的代价实在太大。当时的方法是给Toolbar添加了一个顶部的padding，具体原理也不大清楚。
但实际上并不总能一直 trying stuff utill it work

### 3. 使用CollapsingToolbarLayout时的问题
1. 5.0以上的手机似乎很简单
```xml
<?xml version="1.0" encoding="utf-8"?>
    <android.support.design.widget.CoordinatorLayout
        xmlns:android="http://schemas.android.com/apk/res/android"
        xmlns:app="http://schemas.android.com/apk/res-auto"
        android:id="@+id/coordinateLayout"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:background="@android:color/background_light"
        android:fitsSystemWindows="true"
        >

        <android.support.design.widget.AppBarLayout
            android:id="@+id/appbarLayout"
            android:layout_width="match_parent"
            android:layout_height="300dp"
            android:theme="@style/ThemeOverlay.AppCompat.Dark.ActionBar"
            android:fitsSystemWindows="true"
            >

            <android.support.design.widget.CollapsingToolbarLayout
                android:id="@+id/collapsingToolbarLayout"
                android:layout_width="match_parent"
                android:layout_height="match_parent"
                app:contentScrim="?attr/colorPrimary"
                app:expandedTitleMarginEnd="64dp"
                app:expandedTitleMarginStart="48dp"
                app:layout_scrollFlags="scroll|exitUntilCollapsed"
                >

                <ImageView
                    android:id="@+id/backdrop"
                    android:layout_width="match_parent"
                    android:layout_height="match_parent"
                    android:scaleType="centerCrop"
                    android:src="@drawable/image_19"
                    app:layout_collapseMode="parallax"
                    android:fitsSystemWindows="true"
                    />

                <android.support.v7.widget.Toolbar
                    android:id="@+id/toolbar"
                    android:layout_width="match_parent"
                    android:layout_height="?attr/actionBarSize"
                    app:layout_collapseMode="pin"
                    app:popupTheme="@style/ThemeOverlay.AppCompat.Light"
                    />
            </android.support.design.widget.CollapsingToolbarLayout>
        </android.support.design.widget.AppBarLayout>

        <android.support.v4.widget.NestedScrollView
            android:id="@+id/nestedScrollView"
            android:layout_width="match_parent"
            android:layout_height="match_parent"
            app:layout_behavior="@string/appbar_scrolling_view_behavior"
            >

            <TextView
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:lineSpacingExtra="8dp"
                android:padding="@dimen/activity_horizontal_margin"
                android:text="@string/newsBody"
                android:textSize="20sp"
                />
        </android.support.v4.widget.NestedScrollView>

        <android.support.design.widget.FloatingActionButton
            android:id="@+id/fab"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_margin="@dimen/activity_horizontal_margin"
            android:src="@android:drawable/ic_menu_slideshow"
            app:layout_anchor="@id/appbarLayout"
            app:layout_anchorGravity="bottom|right|end"
            />
    </android.support.design.widget.CoordinatorLayout>
```
只要分别在CoordinateLayout，AppBarLayout和CollapsingToolbarLayout的xml属性中加上android:fitSystemWindwo = "true"
java代码里添加一句
> getWindow().addFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS); //注意下版本判断
或者在当前Activity的values-v19 styles中添加 <item name="android:windowTranslucentStatus">true</item>
就行了。实际效果就是图片完全展开时可以扩展到statusBar下面，图片收缩起来后可以让Toolbar停在statusBar下面。但同样的代码在4.4的手机上会使得实际绘图区域落到statusBar以下，statusBar位置变成带灰色遮罩的白色背景。

### 4. fitSystemWindow是什么意思
fitSystemWindows属性： 
官方描述: 
Boolean internal attribute to adjust view layout based on system windows such as the status bar. If true, adjusts the padding of this view to leave space for the system windows. Will only take effect if this view is in a non-embedded activity. 
简单来说就是如果设置为true,机会根据statusbar来添加一个padding.
假定:
布局文件只是一个普通的LinearLayout(fitSystemWindow = false（默认情况）),顶部include一个toolbar(fitSystemWindow = true )
就已经可以实现4.4以下，4.4-5.0，5.0以上的各种场景了,(前提，使用Appcompat 的Theme，因为它会使用colorPrimaryDark为statusBar着色)

但我的问题在于布局文件是
CoordinateLayout>AppBarLyout>CollapsingToolbarLayout>Toolbar&ImageView
这种情况下，照理说Toolbar应该顶部留有25dp的padding，也就是fitSystemWindow = true（假设就只是这么简单），而ImageView需要侵入到statusBar下面，也就是fitSystemWindow = false。
那就只要在toolbar的xml中添加fitSystemWindow这个属性好了。编译，运行，5.1手机，Toolbar的小箭头一部分跑到statusBar下面了，不可取。
