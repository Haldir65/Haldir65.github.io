---
title: CoordiantorLayout及滑动原理解析
date: 2018-09-24 19:35:11
tags: [android]
---

在Android平台上，掌握滑动事件是一件让人头疼的事情。
![](https://api1.foster57.tk/static/imgs/1513521623756.jpg)

<!--more-->

### 1.关于CoordinateLayout里面的东西（针对supportLibrary27.1.0代码）
```xml
<android.support.design.widget.CoordinatorLayout xmlns:android="http://schemas.android.com/apk/res/android"
    >
    <android.support.design.widget.AppBarLayout
       >
        <android.support.v7.widget.Toolbar
            app:layout_scrollFlags="scroll|enterAlways|snap" />
        <android.support.design.widget.TabLayout
           />
    </android.support.design.widget.AppBarLayout>
    <android.support.v4.view.ViewPager
        app:layout_behavior="@string/appbar_scrolling_view_behavior" />
    <android.support.design.widget.FloatingActionButton
        />
</android.support.design.widget.CoordinatorLayout>
```
剔除一些无关的属性后，可以观察到:
app:layout_scrollFlags是写给AppBarLayout看的
app:layout_behavior是写给CoordinatorLayout看的

app:layout_scrollFlags = scroll的时候，手指上滑下滑，加了flag的View只会在外层的ScrollingView(这里就是ViewPager了)滑动到头了才开始滑动

app:layout_scrollFlags = scroll|enterAlways的时候，手指上下滑动时，加了flag的view会立刻响应（还不等外部的ScrollingView滑到头就开始滑动，当然这里没有动画，手指慢慢的挪的话，可以让它停在一半的位置）。可以理解为手指上下滑动时，只要加了flag的view会优先消费完滑动距离


app:layout_scrollFlags = scroll|enterAlways|snap的时候，就加上动画了（手指往下拖，把toolbar拖出来不到一半的时候它会缩回去，超出一半的时候会动画弹出来）
这段动画的代码在AppBarLayout.Behavior的onStopNestedScroll方法里面判断了
```java
if ((flags & LayoutParams.FLAG_SNAP) == LayoutParams.FLAG_SNAP) {//所以flag这个东西其实是AppbarLayout.LayoutParams的一个属性。可以进行位运算操作
    // ...
    animateOffsetTo(coordinatorLayout, abl,
                            MathUtils.clamp(newOffset, -abl.getTotalScrollRange(), 0), 0);
}

//那个snap的动画长这样
if (mOffsetAnimator == null) {
    mOffsetAnimator = new ValueAnimator();
    mOffsetAnimator.setInterpolator(AnimationUtils.DECELERATE_INTERPOLATOR);
    mOffsetAnimator.addUpdateListener(new ValueAnimator.AnimatorUpdateListener() {
        @Override
        public void onAnimationUpdate(ValueAnimator animation) {
            setHeaderTopBottomOffset(coordinatorLayout, child,
                    (int) animation.getAnimatedValue()); //做动画的过程中调用AppbarLayout(其实就是一个LinearLayout)的offsetTopAndBottom方法
        }
    });
} else {
    mOffsetAnimator.cancel();
}

mOffsetAnimator.setDuration(Math.min(duration, MAX_OFFSET_ANIMATION_DURATION));
mOffsetAnimator.setIntValues(currentOffset, offset);
mOffsetAnimator.start();


```

在Cheesequare的首页，RecyclerView准备滑动(ActionMove)还没滑动时调用了
RecyclerView.dispatchNestedPreScroll -> CoordinateLayout.onNestedPreScroll ->
AppbarLayout.Beahvior.onNestedPreScroll ->AppbarLayout.offsetTopAndBottom

在RecyclerView的scrollByInternal里面调用了RecyclerView.dispatchNestedScroll ->
CoordinateLayout.onNestedScroll ->CoordinatorLayout.onChildViewChanged -> AppbarLayoutBehavior.onDependentViewChanged ->AppbarLayout.onNestedScroll -> AppbarLayout.Behavior.onNestedScroll

RecyclerView(Action_UP)的时候调用顺序:
RecyclerView.stopNestedScroll(这个其实不是让RecyclerView停下来，而是告诉parent应该停下来了)
CoordinateLayout.onStopNestedScroll
AppbarLayout.onStopNestedScroll
AppbarLayout.Behavior.onStopNestedScroll
AppbarLayout.Behavior.snapToChildIfNeeded(就是上面说的如果 scroll|enterAlways|snap都在时候的动画了)

```java
//注意AppbarLayout是有一个默认的behavior的
@CoordinatorLayout.DefaultBehavior(AppBarLayout.Behavior.class)
public class AppBarLayout extends LinearLayout {
    
}
//在AppbarLayout的语义里，上下滑动的距离用的是offset这个关键字
//这又是一个public static class

//在AppBarLayout.Behavior里面有这么一段
@Override
public boolean layoutDependsOn(CoordinatorLayout parent, View child, View dependency) {
    // We depend on any AppBarLayouts
    return dependency instanceof AppBarLayout;
}

@Override
public boolean onDependentViewChanged(CoordinatorLayout parent, View child,
        View dependency) {
    offsetChildAsNeeded(parent, child, dependency);//child就是底部在加了behavior的ViewPager,dependency是AppbarLayout.这里面就是调用了child.offsetTopAndBottom
    return false;
}

//从调用顺序来看，是加了behavior的View(底部的ViewPager)滑动时dispatchNestedPreScroll -> CoordinatorLayout.onNestedPreScroll -> CoordinatorLayout会一个个child去查，发现一个behavior不为Null的就会调用onChildViewsChanged-> 这里面还是一个个遍历child(一个个问layoutDependsOn，内部实现是遍历每个child，然后针对每个child，拿着当前加上了behavior的views一个个(mDependencySortedChildren)来问，询问加了behavior的child的behavior，这个child是否感兴趣。。。一旦感兴趣就走onDependentViewChanged)

// 在cheesequare的主页面，mDependencySortedChildren这个List<View>默认有三个元素AppBarLayout,ViewPager,FloatingActionButton(ViewPager是我们手动加上去的，其他两个都是default配备了behavior的)。由此看来，自己可以写一个behavior，加在CoordinatorLayout的child中，这样就能参与到mDependencySortedChildren这个过程中了

//在mDependencySortedChildren中，ViewPager是dependend on AppBarLayout的。也就是说加在ViewPager上的behavior
// :app:layout_behavior="@string/appbar_scrolling_view_behavior"  这玩意其实写在AppbarLayout中
 public static class ScrollingViewBehavior extends HeaderScrollingViewBehavior {

 }
 //调用顺序
 RecyclerView.onTouchEvent(ACTION_MOVE)
 RecyclerView.dispatchNestedPreScroll()
 NestedScrollChildHelper.dispatchNestedPreScroll()
CoordinatorLayout.onNestedPreScroll(View 那个RecyclerView, int dx, int dy, int[] consumed, int  type)//这里面一个个遍历child找加上了behavior的，调用behavior的onNestedPreScroll
CoordinatorLayout.onChildViewsChanged(EVENT_NESTED_SCROLL)//这里面就是一个个遍历child，拿着child去问加了bahavior的view“这是你想要的吗”，如果是肯定答复，会走到onDependentViewChanged（CoordinatorLayout,View 加了behavior的view,View behavior感兴趣的View）.所以多数的实现都可以在这里动手。又因为加了bahavior的view事实上是一个list，事实上可以随便加任意多个带behavior的view。

// https://github.com/saulmm/CoordinatorBehaviorExample中的实现如下。


@Override
public boolean layoutDependsOn(CoordinatorLayout parent, CircleImageView child, View dependency) {
    return dependency instanceof Toolbar;
}

@Override
public boolean onDependentViewChanged(CoordinatorLayout parent, CircleImageView child, View dependency) {
    maybeInitProperties(child, dependency);

    final int maxScrollDistance = (int) (mStartToolbarPosition);
    float expandedPercentageFactor = dependency.getY() / maxScrollDistance;

    if (expandedPercentageFactor < mChangeBehaviorPoint) {
        float heightFactor = (mChangeBehaviorPoint - expandedPercentageFactor) / mChangeBehaviorPoint;

        float distanceXToSubtract = ((mStartXPosition - mFinalXPosition)
                * heightFactor) + (child.getHeight()/2);
        float distanceYToSubtract = ((mStartYPosition - mFinalYPosition)
                * (1f - expandedPercentageFactor)) + (child.getHeight()/2);

        child.setX(mStartXPosition - distanceXToSubtract);
        child.setY(mStartYPosition - distanceYToSubtract);

        float heightToSubtract = ((mStartHeight - mCustomFinalHeight) * heightFactor);

        CoordinatorLayout.LayoutParams lp = (CoordinatorLayout.LayoutParams) child.getLayoutParams();
        lp.width = (int) (mStartHeight - heightToSubtract);
        lp.height = (int) (mStartHeight - heightToSubtract);
        child.setLayoutParams(lp);
    } else {
        float distanceYToSubtract = ((mStartYPosition - mFinalYPosition)
                * (1f - expandedPercentageFactor)) + (mStartHeight/2);

        child.setX(mStartXPosition - child.getWidth()/2);
        child.setY(mStartYPosition - distanceYToSubtract);

        CoordinatorLayout.LayoutParams lp = (CoordinatorLayout.LayoutParams) child.getLayoutParams();
        lp.width = (int) (mStartHeight);
        lp.height = (int) (mStartHeight);
        child.setLayoutParams(lp);
    }
    return true;
}
```
上述一个个询问加了behavior的child的过程其实叫做onChildViewChanged(EVENT_NESTED_SCROLL),该方法会在
CoordinatorLayout的onNestedFling,onNestedPreScroll,onNestedScroll,onChildViewRemoved,onPreDraw中都会调用到。
所以在这里相应滑动是足够的。上述例子里面就是在onDependentViewChanged中获取当前target的getY，对此作出textView的缩放。


接下来看一大堆接口:
```java
public interface NestedScrollingParent {
    boolean onStartNestedScroll(@NonNull View child, @NonNull View target, @ScrollAxis int axes);
    void onNestedScrollAccepted(@NonNull View child, @NonNull View target, @ScrollAxis int axes);
    void onStopNestedScroll(@NonNull View target);
    void onNestedScroll(@NonNull View target, int dxConsumed, int dyConsumed,
            int dxUnconsumed, int dyUnconsumed);
    void onNestedPreScroll(@NonNull View target, int dx, int dy, @NonNull int[] consumed);
    boolean onNestedFling(@NonNull View target, float velocityX, float velocityY, boolean consumed);
    boolean onNestedPreFling(@NonNull View target, float velocityX, float velocityY);
    int getNestedScrollAxes();
}

public interface NestedScrollingParent2 extends NestedScrollingParent {
    boolean onStartNestedScroll(@NonNull View child, @NonNull View target, @ScrollAxis int axes,
            @NestedScrollType int type);
    void onNestedScrollAccepted(@NonNull View child, @NonNull View target, @ScrollAxis int axes,
            @NestedScrollType int type);
    void onStopNestedScroll(@NonNull View target, @NestedScrollType int type);
    void onNestedScroll(@NonNull View target, int dxConsumed, int dyConsumed,
            int dxUnconsumed, int dyUnconsumed, @NestedScrollType int type);
    void onNestedPreScroll(@NonNull View target, int dx, int dy, @NonNull int[] consumed,
            @NestedScrollType int type);
}
// 似乎就是添加了一个NestedScrollType
@IntDef({TYPE_TOUCH, TYPE_NON_TOUCH})
@Retention(RetentionPolicy.SOURCE)
@RestrictTo(LIBRARY_GROUP)
public @interface NestedScrollType {}


public interface NestedScrollingChild {
    void setNestedScrollingEnabled(boolean enabled);
    boolean isNestedScrollingEnabled();
    boolean startNestedScroll(@ScrollAxis int axes);
    void stopNestedScroll();
    boolean hasNestedScrollingParent();
    boolean dispatchNestedScroll(int dxConsumed, int dyConsumed,
            int dxUnconsumed, int dyUnconsumed, @Nullable int[] offsetInWindow);
    boolean dispatchNestedPreScroll(int dx, int dy, @Nullable int[] consumed,
            @Nullable int[] offsetInWindow);
    boolean dispatchNestedFling(float velocityX, float velocityY, boolean consumed);
    boolean dispatchNestedPreFling(float velocityX, float velocityY);
}

public interface NestedScrollingChild2 extends NestedScrollingChild {
    boolean startNestedScroll(@ScrollAxis int axes, @NestedScrollType int type);
    void stopNestedScroll(@NestedScrollType int type);
    boolean hasNestedScrollingParent(@NestedScrollType int type);
    boolean dispatchNestedScroll(int dxConsumed, int dyConsumed,
            int dxUnconsumed, int dyUnconsumed, @Nullable int[] offsetInWindow,
            @NestedScrollType int type);
    boolean dispatchNestedPreScroll(int dx, int dy, @Nullable int[] consumed,
            @Nullable int[] offsetInWindow, @NestedScrollType int type);
}
//似乎也只是加了一个NestedScrollType，2是1的子类

//看一下继承关系
public class SwipeRefreshLayout extends ViewGroup implements NestedScrollingParent,
        NestedScrollingChild {

        }

public class NestedScrollView extends FrameLayout implements NestedScrollingParent,
        NestedScrollingChild2, ScrollingView {

        }   
public class RecyclerView extends ViewGroup implements ScrollingView, NestedScrollingChild2 {

}     

public class CoordinatorLayout extends ViewGroup implements NestedScrollingParent2 {

}
```
[关于CoordinatorLayout的比较好的教程](http://saulmm.github.io/mastering-coordinator)

### SwipeRefreshLayout里面有一个OnChildScrollUpCallback用于决定是否可以拦截实践，比setEnabled要好很多
CoordinateLayout inside SwipeRefreshLayout的问题似乎可以从这里去解决
