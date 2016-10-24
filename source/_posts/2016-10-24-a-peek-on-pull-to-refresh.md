---
title: android-Ultra-pull-to-refresh分析
date: 2016-10-24 10:25:35
categories: blog  
tags: [android]
---
 最早开始接触安卓的时候就知道有Chris Banes的[Pull-To-Refresh](https://github.com/chrisbanes/Android-PullToRefresh)，当时这个库已经被标记被Deprecated了，后来出于寻找替代品的目的找到了秋百万的[android-Ultra-pull-toRefresh](https://github.com/liaohuqiu/android-Ultra-Pull-To-Refresh)，直接![fork](http://odzl05jxx.bkt.clouddn.com/687474703a2f2f692e696d6775722e636f6d2f4766746846417a2e706e67.png)

 当时甚至没有能力把一个Demo跑起来。之后的项目中，直接使用swipeRefreshLayout了。现在回头看，终于觉得可以尝试着分析一遍整个下拉刷新的过程。本文只针对[android-Ultra-pulltoRefresh](https://github.com/liaohuqiu/android-Ultra-Pull-To-Refresh)部分源码进行分析。拆一个轮子可能只需要花一天时间，但能够从无到有构思出这个框架并将项目搭建起来，长期维护真的是一件需要很强毅力的事情，向为开源社区贡献优秀代码的秋百万致敬。
 <!--more-->

 ### 1. 从Demo开始吧
从github clone下来之后，改一下gradle版本，compile sdk version什么的就可以运行项目自带的Demo了.
MainActivity 添加了一个PtrDemoHomeFragment,onCreateVie里面返回的View对应的xml文件为
fragment_ptr_home.xml
```xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical">

    <in.srain.cube.views.ptr.PtrFrameLayout
        android:id="@+id/fragment_ptr_home_ptr_frame"
        xmlns:cube_ptr="http://schemas.android.com/apk/res-auto"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        cube_ptr:ptr_duration_to_close="200"
        cube_ptr:ptr_duration_to_close_header="1000"
        cube_ptr:ptr_keep_header_when_refresh="true"
        cube_ptr:ptr_pull_to_fresh="false"
        cube_ptr:ptr_ratio_of_header_height_to_refresh="1.2"
        cube_ptr:ptr_resistance="1.7">

        <ScrollView
            android:id="@+id/fragment_block_menu_scroll_view"
            android:layout_width="match_parent"
            android:layout_height="match_parent"
            android:background="@color/cube_mints_white">

            <in.srain.cube.views.block.BlockListView
                android:id="@+id/fragment_block_menu_block_list"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:padding="@dimen/cube_mints_content_view_padding" />
        </ScrollView>

    </in.srain.cube.views.ptr.PtrFrameLayout>
</LinearLayout>
```
默认主页已经可以下拉刷新了，那么主要的事件拦截操作应该就在这个ptrFrameLayout里面


### 2. PtrFrameLayout源码
从注释来看 
> This layout view for "Pull to Refresh(Ptr)" support all of the view, you can contain everything you want.
  support: pull to refresh / release to refresh / auto refresh / keep header view while refreshing / hide header view while refreshing
  It defines {@link in.srain.cube.views.ptr.PtrUIHandler}, which allows you customize the UI easily.

能够容纳各种View，同时支持下拉刷新，下拉释放刷新，自动刷新，刷新时保留刷新动画，刷新时隐藏刷新动画

一步步来看

1. **构造函数**

```java
public class PtrFrameLayout extends ViewGroup {

 public PtrFrameLayout(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);
        //删除无关代码
        TypedArray arr = context.obtainStyledAttributes(attrs, R.styleable.PtrFrameLayout, 0, 0);
        if (arr != null) {
            mHeaderId = arr.getResourceId(R.styleable.PtrFrameLayout_ptr_header, mHeaderId); // HeaderView的layout文件id
            mContainerId = arr.getResourceId(R.styleable.PtrFrameLayout_ptr_content, mContainerId); // contentView的layout文件id
            mDurationToClose = arr.getInt(R.styleable.PtrFrameLayout_ptr_duration_to_close, mDurationToClose);// 维持刷新动画多久开始关闭HeaderView
            mDurationToCloseHeader = arr.getInt(R.styleable.PtrFrameLayout_ptr_duration_to_close_header, mDurationToCloseHeader);
            float ratio = mPtrIndicator.getRatioOfHeaderToHeightRefresh();
            ratio = arr.getFloat(R.styleable.PtrFrameLayout_ptr_ratio_of_header_height_to_refresh, ratio);
            mKeepHeaderWhenRefresh = arr.getBoolean(R.styleable.PtrFrameLayout_ptr_keep_header_when_refresh, mKeepHeaderWhenRefresh);
            mPullToRefresh = arr.getBoolean(R.styleable.PtrFrameLayout_ptr_pull_to_fresh, mPullToRefresh);
            arr.recycle();
        }
        //ViewConfiguration很常见了，mTouchSlop用于判断用户操作手势是否有效
        final ViewConfiguration conf = ViewConfiguration.get(getContext());
        mPagingTouchSlop = conf.getScaledTouchSlop() * 2;
    }

}
```

构造函数里面主要就是获得在xml中设定的一些自定义属性的值并保存为成员变量，实际用途后面再看。

2. **onFinishInflate**
 这个方法在inflate xml文件结束，所有的childView都已经添加之后调用
 PtrFrameLayout复写了这个方法，
- 首先检查ChildView数量，如果childCount >2 会报错
- 然后检查两个child(这里主要看childCount=2的情况下)
```java
//省略若干
if (child1 instanceof PtrUIHandler) {
                    mHeaderView = child1;
                    mContent = child2;
                } else if (child2 instanceof PtrUIHandler) {
                    mHeaderView = child2;
                    mContent = child1;
                } 
//省略若干                
```
来看一下这个ptrUIHandler
```java
public interface PtrUIHandler {

    /**
     * When the content view has reached top and refresh has been completed, view will be reset.
     *
     * @param frame
     */
    public void onUIReset(PtrFrameLayout frame);

    /**
     * prepare for loading
     *
     * @param frame
     */
    public void onUIRefreshPrepare(PtrFrameLayout frame);

    /**
     * perform refreshing UI
     */
    public void onUIRefreshBegin(PtrFrameLayout frame);

    /**
     * perform UI after refresh
     */
    public void onUIRefreshComplete(PtrFrameLayout frame);

    public void onUIPositionChange(PtrFrameLayout frame, boolean isUnderTouch, byte status, PtrIndicator ptrIndicator);
}
```
大概可以猜到这货是用来指定下拉过程中的刷新开始，刷新结束，刷新结束后复位等过程的实现者，具体的下拉过程中的动画，位移等特效都应该由这接口的实例(View)来完成。

3. **onMeasure**
```java
 @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec);
        //省略...
         measureContentView(mContent, widthMeasureSpec, heightMeasureSpec);
    }


     private void measureContentView(View child,
                                    int parentWidthMeasureSpec,
                                    int parentHeightMeasureSpec) {
        final MarginLayoutParams lp = (MarginLayoutParams) child.getLayoutParams();

        final int childWidthMeasureSpec = getChildMeasureSpec(parentWidthMeasureSpec,
                getPaddingLeft() + getPaddingRight() + lp.leftMargin + lp.rightMargin, lp.width);
        final int childHeightMeasureSpec = getChildMeasureSpec(parentHeightMeasureSpec,
                getPaddingTop() + getPaddingBottom() + lp.topMargin, lp.height);

        child.measure(childWidthMeasureSpec, childHeightMeasureSpec);
    }
```
主要就是调用了measureContentView方法，都是很中规中矩的实现

4. **onLayout**
代码就不贴了，根据LayoutParams计算出需要的margin,最主要的Top是由
>  int offset = mPtrIndicator.getCurrentPosY();

获得的，mPterIndicator是一个单独的组件，用于保存一些实时状态。
滑动过程中如果有动画效果，会走到这个方法里，所以及时更新最新的位置很重要，ptr将这一功能剥离出来，这大概就是我所理解的解耦吧。


5. **dispatchTouchEvent**
主要的手势处理逻辑都在这里，关于TouchEvent的分发处理，这里不再赘述。
简单列出执行顺序:
> ViewGroup.dispatchTouchEvent----ViewGroup.onInterceptTouchEvent---View.dispatchTouchEvent----- etc 、、、、

简书上有作者写出了非常好的关于TouchEvent分发的[文章](http://www.jianshu.com/p/e99b5e8bd67b)，忘记了的话可以去看看。
来看这部分的实现，有删节
```java
 @Override
    public boolean dispatchTouchEvent(MotionEvent e) {
    	//.....
        switch (action) {
            case MotionEvent.ACTION_UP:
            case MotionEvent.ACTION_CANCEL:
                if (mPtrIndicator.hasLeftStartPosition()) {
                    onRelease(false); //手指抬起后的操作
                    // ......
                    return dispatchTouchEventSupper(e);
                } else {
                    return dispatchTouchEventSupper(e);
                }

            case MotionEvent.ACTION_DOWN:
            	//取消之前还在运行的Scroller等等。。
                // The cancel event will be sent once the position is moved.
                // So let the event pass to children.
                // fix #93, #102
                dispatchTouchEventSupper(e);
                return true;//这里返回true，child将会受到ACTION_CANCEL

            case MotionEvent.ACTION_MOVE:
                mLastMoveEvent = e; //这里实时更新装填
                mPtrIndicator.onMove(e.getX(), e.getY());
                float offsetX = mPtrIndicator.getOffsetX();
                float offsetY = mPtrIndicator.getOffsetY();
               

                boolean moveDown = offsetY > 0;
                boolean moveUp = !moveDown;
                boolean canMoveUp = mPtrIndicator.hasLeftStartPosition();

                // disable move when header not reach top
                if (moveDown && mPtrHandler != null && !mPtrHandler.checkCanDoRefresh(this, mContent, mHeaderView)) {
                    return dispatchTouchEventSupper(e);
                }

                if ((moveUp && canMoveUp) || moveDown) {
                    movePos(offsetY); //实现滑动操作的代码
                    return true;// 后续事件将只会走到此方法，不会再往下传递，直到ACTION_UP，本次手势结束
                }
        }
        return dispatchTouchEventSupper(e);
    }

```
用户手指按下。。。。。手指滑动。。。。。手指抬起

**ACTION_DOWN** : 手指按下后将TouchEvent交给mPtrIndicator处理，后者保留了当前ptr的位置，高度等信息。在执行ACTION_DOWN时，并没有简单地使用Event.getY，而是保留了当前position的一个备份(这是必要的，因为对于下拉刷新来说，最终需要回到的位置是0，而用户按下的位置可能在contentView比较靠下面的位置。ACTION_DOWN的getY并没有太大意义)。随后调用Scroller的 mScroller.forceFinished(true)方法停止滑动，如果定义了页面自动刷新(就是进来会下拉刷新一次)，还会调用onRelease(true)方法，onRelease方法与ACTION_UP相关。

**ACTION_MOVE** : 手指开始在屏幕上滑动，首先将滑动距离的改变保留到mPtrIndicator中，这里作者将很多坐标计算的方法都拆出来放到这个mPtrIndicator中，暴露出get方法，也使得代码更清晰。在开始滑动之前，先检查下是否是横向滑动，以及是否在(mDisableWhenHorizontalMove，ViewPager需要消费横向手势，这个标志符是为了return super)。
往下走，来看这一段
```java
	boolean moveDown = offsetY > 0; 新的Event中的y值和mptrIndicator中保留的当前y的差值，所以手指往下拉的话，offset >0,也就是这里的moveDown
	boolean moveUp = !moveDown;
	boolean canMoveUp = mPtrIndicator.hasLeftStartPosition()// 检查下当前Event中的y是否大于0，即内容区域是否已经往下走了一点了
```
接下来，再次询问mPtrHandler能否DoRefresh,将自身和ChildView都交出去，所以可操作性很大
大部分的情况下，直接使用一个
>  return PtrDefaultHandler.checkContentCanBePulledDown(frame, content, header);

使用了一个类似于ViewCompat.canScollVertically的方法，但判断下如果是AbstractListView的话，会调用getFirstVisiblePosition等方法，因为AdapterView能否滑动应该是由其内容能否滑动来决定的。
如果这个方法返回true。接着往下走，开始执行View的滑动方法:
判断下是否手指在往上拉(moveUp && canMoveUp)或者往下拉(moveDown),return true，首先事件就不会再往下走，另外后续的ACTION_MOVE_ACTION_UP都只会传递到这个dispatchTouchEvent中
实现滑动操作的代码最后会执行这里
```java
  private void updatePos(int change) {
       

        boolean isUnderTouch = mPtrIndicator.isUnderTouch();

        // once moved, cancel event will be sent to child
        if (isUnderTouch && !mHasSendCancelEvent && mPtrIndicator.hasMovedAfterPressedDown()) {
            mHasSendCancelEvent = true;
            sendCancelEvent();
        }

        // leave initiated position or just refresh complete
        if ((mPtrIndicator.hasJustLeftStartPosition() && mStatus == PTR_STATUS_INIT) ||
                (mPtrIndicator.goDownCrossFinishPosition() && mStatus == PTR_STATUS_COMPLETE && isEnabledNextPtrAtOnce())) {

            mStatus = PTR_STATUS_PREPARE;
            mPtrUIHandlerHolder.onUIRefreshPrepare(this);//刚开始往下移一点点或者刚刚从下面回到0的位置，可以认为是下拉刷新刚开始和刚结束的时候。这个Holder的结构类似于一个链表，一个Holder里面有UIHandler，以及下一个Holder(next)。作用类似于一个集合，等于作者自己实现了这样一个不断循环的消息列表(看起来挺像Message的)。这个Holder的作用在于可以动态添加UIHanlder，相对应的方法都做好了(addHandler)。
            //再次强调，这里表示**刚开始往下移一点点或者刚刚从下面回到0的位置，可以认为是下拉刷新刚开始和刚结束的时候。**
        }

        // back to initiated position
        if (mPtrIndicator.hasJustBackToStartPosition()) {
            tryToNotifyReset();
            //**刚刚从下面回到0的位置，通知UIHandler的onUIReset()方法**
            //将整个过程划分的真详细
            // recover event to children，虽然手指还在屏幕上，处于ACTION_MOVE，但这里由于已经复位，需要把ACTION_DOWN传递下去，这一段比较复杂。
            if (isUnderTouch) {
                sendDownEvent();
            }
        }

        // Pull to Refresh
        if (mStatus == PTR_STATUS_PREPARE) {//从上到下依次为0 ， 出现动画临界值， HeadView高度
            // reach fresh height while moving from top to bottom
            if (isUnderTouch && !isAutoRefresh() && mPullToRefresh  // 手指还在屏幕上，不是自动刷新且允许ptr且到达了下滑出现动画效果的临界值，条件还是比较苛刻的
                    && mPtrIndicator.crossRefreshLineFromTopToBottom()) {
                tryToPerformRefresh();
            }
            // reach header height while auto refresh
            if (performAutoRefreshButLater() && mPtrIndicator.hasJustReachedHeaderHeightFromTopToBottom()) {//刚刚超过headerView高度一丁点
                tryToPerformRefresh();
            }
        }


        // 让一个View滑动的方式有很多种，这里采用的是改变X,Y的方式(X = left+translationX;Y = top+translationY) 
        mHeaderView.offsetTopAndBottom(change);
        if (!isPinContent()) {
            mContent.offsetTopAndBottom(change);
        }
        invalidate();

        if (mPtrUIHandlerHolder.hasHandler()) {
            mPtrUIHandlerHolder.onUIPositionChange(this, isUnderTouch, mStatus, mPtrIndicator);
        }
        onPositionChange(isUnderTouch, mStatus, mPtrIndicator);
    }
```

注意，在offset之前先调用了performRefresh方法
这里会调用
> mPtrUIHandlerHolder.onUIRefreshBegin(this);
> mPtrHandler.onRefreshBegin(this);

这里由于ChildView和ContentView即将开始滑动(offset),从手机上看的话就是ptr进入Loading状态，比如加载动画开始执行了。

**ACTION_UP**



