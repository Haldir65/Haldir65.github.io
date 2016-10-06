---
title: android使用selectableItemBackground的一些坑
date: 2016-09-23 19:56:39
categories: [技术]
tags: [随笔,foreground,android]
---

> android:foreground="?android:attr/selectableItemBackground"

或是
> android:background="?android:attr/selectableItemBackground"

这个xml属性最早是我学着写recyclerVeiw的item xml的时候接触到的，简单来说就是，在API 21及以上，用户点击这个itemView时候会出现一个Ripple效果
非常好看，而在API 21以下则会表现为MonoChrome的类似按压色的效果![](https://cloud.githubusercontent.com/assets/12274855/18787855/2a6d93f2-81d7-11e6-8026-58cdbd8583d4.JPG) </br> 
而这个点击时的水波纹颜色也是可以Customize的
```
<item name="android:colorControlHighlight">@color/my_ripple_color</item>
```
//这个要写在自己的Activity的Theme(style-v21)里，注意，当前Activity的Theme必须继承自Appcompat!!
于是，我写了这样的xml
```xml
<LinearLayout
        android:id="@+id/item_root"
        android:layout_width="match_parent"
        android:layout_height="?android:attr/listPreferredItemHeight"
        android:orientation="vertical"
        android:gravity="center"
        android:onClick="@{(view) -> callback.onClick(view,data)}"
        android:elevation="2dp"
        android:background="@color/md_amber_200"
        android:foreground="?android:attr/selectableItemBackground"
        />
```
然而，点击之后并没有出现水波纹(模拟器 API 21)，换成CardView或是将foreground改为background之后才有效。查了很多博客，最后得出结论:
android:foreground在API 23之前只对FrameLayout有效(CardView继承自FrameLayout当然有效)。
<!--more-->

##所以正确的做法是

> android:foreground="?android:attr/selectableItemBackground"

改为
> android:background="?android:attr/selectableItemBackground"

或者使用FrameLayout。

- 关于foreground 
 之前看google io2016时，[Chris Banes](https://github.com/chrisbanes)给了这样的解释。
 ![](https://cloud.githubusercontent.com/assets/12274855/18787841/1d0b2d82-81d7-11e6-916e-b4113772c3a2.JPG),
android:foreground在API 1 的FrameLayout中就有了，但直到API 23才将这个属性添加到View中。
所以，换成API 23的手机上面那段代码foreground也是可以出现Ripple的,至于23之前为什么foreground无效，并不清楚为什么

- 首先是一种简单的模拟这种视觉效果的尝试：[如何创建兼容的Forefround drawable selector](http://effmx.com/articles/ru-he-chuang-jian-jian-rong-de-foreground-drawable-selectorshi-xian-layoutdian-ji-xiao-guo/) 这篇文章提到了:
    > 简单来讲，Foreground 定义了绘制于当前内容之上的 Drawable，类似一层覆盖物。所以我们可以为设置 Foreground 的值为 drawable或者color， 那如果将 Froeground 设置为 drawable selector，自然就可以为控件实现点击响应效果了。 比较奇怪的是在 sdk 23 以前，foregrond 属性只对 Framelayout 生效，但这个问题现在得到了解决，所以也请确保你的 compileSdkVersion 大于等于23
    这篇文章的做法是针对21以下的版本使用slelector Drawable实现类似的效果

- 如何真正实现为API23之前的View,ViewGroup添加foreground?
随后我找到了[这篇博客](https://dzone.com/articles/adding-foreground-selector)，具体的逻辑并不太多。
这里插一句，任何Drawable对象，在你调用setDrawable之后，该Drawable都会保留一个最后一个调用对象的callback
> Drawable->View->Context //leak!
//所以Drawable也有可能导致Activity leak

- 随后我发现了更多有意思的讨论
首先是[Chris Banes](https://github.com/chrisbanes)在G+上的Post : [Foreground Doge](https://plus.google.com/+ChrisBanes/posts/DRerZ8wEFuF)
他给出了两种方案,Chris作为Google员工，给出的解决方案应该是比较官方的了
1. 如果想利用FrameLayout的foreground特性来实现点击特效的话，完全可以在自己的xml外面再包裹一层FrameLayout
2. 自己动手写一个实现foreground的Viewgroup , [代码](https://gist.github.com/chrisbanes/9091754)
- attrs:
```<?xml version="1.0" encoding="utf-8"?>
<resources>
    <declare-styleable name="ForegroundLinearLayout">
        <attr name="android:foreground" />
        <attr name="android:foregroundInsidePadding" />
        <attr name="android:foregroundGravity" />
    </declare-styleable>
</resources>```

```java
/* 
 * Copyright (C) 2006 The Android Open Source Project 
 * 
 * Licensed under the Apache License, Version 2.0 (the "License"); 
 * you may not use this file except in compliance with the License. 
 * You may obtain a copy of the License at 
 * 
 *      http://www.apache.org/licenses/LICENSE-2.0 
 * 
 * Unless required by applicable law or agreed to in writing, software 
 * distributed under the License is distributed on an "AS IS" BASIS, 
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
 * See the License for the specific language governing permissions and 
 * limitations under the License. 
 */ 
 
package your.package; 
 
import android.content.Context;
import android.content.res.TypedArray;
import android.graphics.Canvas;
import android.graphics.Rect;
import android.graphics.drawable.Drawable;
import android.util.AttributeSet;
import android.view.Gravity;
import android.widget.LinearLayout;
 
import your.package.R; 
 
public class ForegroundLinearLayout extends LinearLayout {
 
    private Drawable mForeground;
 
    private final Rect mSelfBounds = new Rect();
    private final Rect mOverlayBounds = new Rect();
 
    private int mForegroundGravity = Gravity.FILL;
 
    protected boolean mForegroundInPadding = true;
 
    boolean mForegroundBoundsChanged = false;
 
    public ForegroundLinearLayout(Context context) {
        super(context);
    } 
 
    public ForegroundLinearLayout(Context context, AttributeSet attrs) {
        this(context, attrs, 0);
    } 
 
    public ForegroundLinearLayout(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);
 
        TypedArray a = context.obtainStyledAttributes(attrs, R.styleable.ForegroundLinearLayout,
                defStyle, 0);
 
        mForegroundGravity = a.getInt(
                R.styleable.ForegroundLinearLayout_android_foregroundGravity, mForegroundGravity);
 
        final Drawable d = a.getDrawable(R.styleable.ForegroundLinearLayout_android_foreground);
        if (d != null) {
            setForeground(d);
        } 
 
        mForegroundInPadding = a.getBoolean(
                R.styleable.ForegroundLinearLayout_android_foregroundInsidePadding, true);
 
        a.recycle();
    } 
 
    /** 
     * Describes how the foreground is positioned. 
     * 
     * @return foreground gravity. 
     * 
     * @see #setForegroundGravity(int) 
     */ 
    public int getForegroundGravity() { 
        return mForegroundGravity;
    } 
 
    /** 
     * Describes how the foreground is positioned. Defaults to START and TOP. 
     * 
     * @param foregroundGravity See {@link android.view.Gravity} 
     * 
     * @see #getForegroundGravity() 
     */ 
    public void setForegroundGravity(int foregroundGravity) {
        if (mForegroundGravity != foregroundGravity) {
            if ((foregroundGravity & Gravity.RELATIVE_HORIZONTAL_GRAVITY_MASK) == 0) {
                foregroundGravity |= Gravity.START;
            } 
 
            if ((foregroundGravity & Gravity.VERTICAL_GRAVITY_MASK) == 0) {
                foregroundGravity |= Gravity.TOP;
            } 
 
            mForegroundGravity = foregroundGravity;
 
 
            if (mForegroundGravity == Gravity.FILL && mForeground != null) {
                Rect padding = new Rect();
                mForeground.getPadding(padding);
            } 
 
            requestLayout();
        } 
    } 
 
    @Override 
    protected boolean verifyDrawable(Drawable who) {
        return super.verifyDrawable(who) || (who == mForeground);
    } 
 
    @Override 
    public void jumpDrawablesToCurrentState() { 
        super.jumpDrawablesToCurrentState(); 
        if (mForeground != null) mForeground.jumpToCurrentState();
    } 
 
    @Override 
    protected void drawableStateChanged() { 
        super.drawableStateChanged(); 
        if (mForeground != null && mForeground.isStateful()) {
            mForeground.setState(getDrawableState());
        } 
    } 
 
    /** 
     * Supply a Drawable that is to be rendered on top of all of the child 
     * views in the frame layout.  Any padding in the Drawable will be taken 
     * into account by ensuring that the children are inset to be placed 
     * inside of the padding area. 
     * 
     * @param drawable The Drawable to be drawn on top of the children. 
     */ 
    public void setForeground(Drawable drawable) {
        if (mForeground != drawable) {
            if (mForeground != null) {
                mForeground.setCallback(null);
                unscheduleDrawable(mForeground);
            } 
 
            mForeground = drawable;
 
            if (drawable != null) {
                setWillNotDraw(false);
                drawable.setCallback(this);
                if (drawable.isStateful()) {
                    drawable.setState(getDrawableState());
                } 
                if (mForegroundGravity == Gravity.FILL) {
                    Rect padding = new Rect();
                    drawable.getPadding(padding);
                } 
            }  else { 
                setWillNotDraw(true);
            } 
            requestLayout();
            invalidate();
        } 
    } 
 
    /** 
     * Returns the drawable used as the foreground of this FrameLayout. The 
     * foreground drawable, if non-null, is always drawn on top of the children. 
     * 
     * @return A Drawable or null if no foreground was set. 
     */ 
    public Drawable getForeground() {
        return mForeground;
    } 
 
    @Override 
    protected void onLayout(boolean changed, int left, int top, int right, int bottom) {
        super.onLayout(changed, left, top, right, bottom);
        mForegroundBoundsChanged = changed;
    } 
 
    @Override 
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        super.onSizeChanged(w, h, oldw, oldh);
        mForegroundBoundsChanged = true;
    } 
 
    @Override 
    public void draw(Canvas canvas) {
        super.draw(canvas);
 
        if (mForeground != null) {
            final Drawable foreground = mForeground;
 
            if (mForegroundBoundsChanged) {
                mForegroundBoundsChanged = false;
                final Rect selfBounds = mSelfBounds;
                final Rect overlayBounds = mOverlayBounds;
 
                final int w = getRight() - getLeft();
                final int h = getBottom() - getTop();
 
                if (mForegroundInPadding) {
                    selfBounds.set(0, 0, w, h);
                } else { 
                    selfBounds.set(getPaddingLeft(), getPaddingTop(),
                            w - getPaddingRight(), h - getPaddingBottom());
                } 
 
                Gravity.apply(mForegroundGravity, foreground.getIntrinsicWidth(),
                        foreground.getIntrinsicHeight(), selfBounds, overlayBounds);
                foreground.setBounds(overlayBounds);
            } 
 
            foreground.draw(canvas);
        } 
    } 
} 
```
- 使用方式
``` xml 
<your.package.ForegroundLinearLayout
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:foreground="?android:selectableItemBackground">

    <ImageView
        android:id=”@+id/imageview_opaque”
        android:layout_width="match_parent"
        android:layout_height="wrap_content" />

    ... other views ...
/>
```

- 接着是[Jack Wharton](https://github.com/JakeWharton)的[ForegroundImageView](https://gist.github.com/JakeWharton/0a251d67649305d84e8a)</br>

- attrs
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
  <declare-styleable name="ForegroundImageView">
    <attr name="android:foreground"/>
  </declare-styleable>
</resources>
```

```java
    import android.content.Context;
    import android.content.res.TypedArray;
    import android.graphics.Canvas;
    import android.graphics.drawable.Drawable;
    import android.util.AttributeSet;
    import android.widget.ImageView;
     
    public class ForegroundImageView extends ImageView {
      private Drawable foreground;
     
      public ForegroundImageView(Context context) {
        this(context, null);
      } 
     
      public ForegroundImageView(Context context, AttributeSet attrs) {
        super(context, attrs);
     
        TypedArray a = context.obtainStyledAttributes(attrs, R.styleable.ForegroundImageView);
        Drawable foreground = a.getDrawable(R.styleable.ForegroundImageView_android_foreground);
        if (foreground != null) {
          setForeground(foreground);
        } 
        a.recycle();
      } 
     
      /** 
       * Supply a drawable resource that is to be rendered on top of all of the child 
       * views in the frame layout. 
       * 
       * @param drawableResId The drawable resource to be drawn on top of the children. 
       */ 
      public void setForegroundResource(int drawableResId) {
        setForeground(getContext().getResources().getDrawable(drawableResId));
      } 
     
      /** 
       * Supply a Drawable that is to be rendered on top of all of the child 
       * views in the frame layout. 
       * 
       * @param drawable The Drawable to be drawn on top of the children. 
       */ 
      public void setForeground(Drawable drawable) {
        if (foreground == drawable) {
          return; 
        } 
        if (foreground != null) {
          foreground.setCallback(null);
          unscheduleDrawable(foreground);
        } 
     
        foreground = drawable;
     
        if (drawable != null) {
          drawable.setCallback(this);
          if (drawable.isStateful()) {
            drawable.setState(getDrawableState());
          } 
        } 
        requestLayout();
        invalidate();
      } 
     
      @Override protected boolean verifyDrawable(Drawable who) {
        return super.verifyDrawable(who) || who == foreground;
      } 
     
      @Override public void jumpDrawablesToCurrentState() { 
        super.jumpDrawablesToCurrentState(); 
        if (foreground != null) foreground.jumpToCurrentState();
      } 
     
      @Override protected void drawableStateChanged() { 
        super.drawableStateChanged(); 
        if (foreground != null && foreground.isStateful()) {
          foreground.setState(getDrawableState());
        } 
      } 
     
      @Override protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec);
        if (foreground != null) {
          foreground.setBounds(0, 0, getMeasuredWidth(), getMeasuredHeight());
          invalidate();
        } 
      } 
     
      @Override protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        super.onSizeChanged(w, h, oldw, oldh);
        if (foreground != null) {
          foreground.setBounds(0, 0, w, h);
          invalidate();
        } 
      } 
     
      @Override public void draw(Canvas canvas) {
        super.draw(canvas);
     
        if (foreground != null) {
          foreground.draw(canvas);
        } 
      } 
    } 
```


----------

最后，还有人给出据说更好的[解决方案](https://github.com/cesards/ForegroundViews)
没有测试过，不了解

##reference
 - [Android themes and styles demisfied](https://www.youtube.com/watch?v=TIHXGwRTMWI) 关于Theme和Style的区别的很好的学习资料
 - [Chris Banes G+ post](https://plus.google.com/108967384991768947849/posts/aHPVDtr6mcp) 评论很精彩
 - [RelativeLayout with foreGround](https://gist.github.com/shakalaca/6199283) 没测试过
 - [Ripple Effect](https://github.com/traex/RippleEffect) 将Ripple的动画兼容到API 9+ ，很出色的一个库。之前项目中用过，就是一个继承自RelativeLayout的自定义ViewGroup。

 
