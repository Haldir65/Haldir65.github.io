---
title: 安卓事件分发流程
date: 2016-10-06 23:32:30
tags: TouchEvent
---

![](http://odzl05jxx.bkt.clouddn.com/dispatch_touch_event_video.JPG)

图1 默认情况下事件传递的路径 

> Touch事件始于ACTION_DOWN, 终止于ACTION_UP, 这其中可能会伴随着ACTION_MOVE,ACTION_CANCEL等等。
<!--more-->

- 首先来关注ACTION_DOWN，用户触摸屏幕，MotionEvent开始传递：

> 1. Activity.dispatchTouchEvent
>
> 2. ViewGroup.dispatchTouchEvent
>
> 3. ViewGroup.onInterceptTouchEvent
>
>    .....中间省略n个视图层级 ....>>>
>
> 4. View.dispatchTouchEvent
>
> 5. View.onTouchEvent
>
> ​      ....中间省略n个视图层级....>>>
>
> 6. ViewGroup.onTouchEvent
> 7. Activity.onTouchEvent

这也就是本文最开始的图1内描述的内容，注意，在默认情况下(各个函数都返回super的情况下)才能将这个从上到下，再从下到上的循环走完整。这里讨论的还只是ACTION_DOWN。

- 接下来看ACTION_DOWN下发过程中各个函数返回值对于整个传递链走向的影响，我们在override这些函数的时候，返回值无非三种：

  > true , false ,super

  - return true：ACTION_DOWN事件分发到此结束(消费掉)，这里有一个要注意的是onInterceptTouchEvent,返回true表示该ViewGroup打算将事件拦截下来，底层View将接收到一个ACTION_CANCEL，事件传递给该ViewGroup的onTouchEvent
  - return false: 对于dispatchTouchEvent，返回false表明不再向下分发，ACTION_DOWN发送到上一层ViewGroup(Activity)的OnTouchEvent；对于onInterceptTouchEvent,返回false表明该ViewGroup不打算拦截，继续下发，对于onTouchEvent，返回false，事件继续上传至上一层级ViewGroup的OnTouchEvent 。
  - return super : 完成整个传递链，就像图1中展示的一样。

![](http://odzl05jxx.bkt.clouddn.com/touch_event_1.png)

图2 来自[图解安卓事件分发机制](http://www.jianshu.com/p/e99b5e8bd67b)  完美地解释了事件分发各个流程中返回值对于事件传递的影响。

![](http://odzl05jxx.bkt.clouddn.com/touch_event_2.png)

图3 来自[图解安卓事件分发机制](http://www.jianshu.com/p/e99b5e8bd67b) 

接下来看ACTION_DOWN时返回值对于后续ACTION_MOVE,ACTION_UP等传递路径的影响：

首先介绍概念：

> gesture = ACTION_DOWN+ a bounch of ACTIONS +ACTION_UP

一个gesture(手势)即从手指按下到手指离开这段过程中所有的事件的集合,swipe,click,fling等等

ACTION_DWON发生时，android将会在当前touch区域所有的View中确定一个Touch Target,后者将接管此次gesture中的所有ACTION_MOVE,ACTION_UP。（这样做有两点好处：1.一旦确定了Touch Target，系统将会把所有的后续事件全部传递到这个target为止，这就避免了复杂的view traversing，有助于提升性能; 2：传递链中第一个能够成为Touch Target的View将独立处理后续事件，不需要考虑其他View受到影响）。在在一个gesture开始时，OnTouchEvent（ACTION_DOWN）返回true,就意味着成为TouchTarget。借用简书[作者](http://www.jianshu.com/p/e99b5e8bd67b)的总结:

> ACTION_DOWN事件在哪个控件消费了（return true），  那么ACTION_MOVE和ACTION_UP就会从上往下（通过dispatchTouchEvent）做事件分发往下传，就只会传到这个控件，不会继续往下传，如果ACTION_DOWN事件是在dispatchTouchEvent消费，那么事件到此为止停止传递，如果ACTION_DOWN事件是在onTouchEvent消费的，那么会把ACTION_MOVE或ACTION_UP事件传给该控件的onTouchEvent处理并结束传递。

这里可以看到，事件依旧是从上往下一直分发到TouchTarget这一层，只是在TouchTarget这一层被消费了，***且不再往上传递***(有助于性能提升)。父ViewGroup的dispatchTouchEvent和onInterceptTouchEvent依旧会先于TouchTarget接收到ACTION_MOVE等事件。所以此时如果父ViewGroup在onInterceptTouchEvent中返回true，父ViewGroup将取代原有的子View成为新的ViewTarget,后续事件(ACTION_MOVE等)将传递到该父ViewGroup中，而子View将收到ACTION_CANCEL(可以在这里做一些恢复状态的工作，比如从foucused变成unfocused)。举一个例子：在ScrollView(不是Android自带的那个)中放一个Button，ACTION_DOWN时，BUTTON表示可以处理ACTION_DOWN,因为这可能会是一次click，于是Button就成了TouchTarget，后续事件将不会传递到ScrollView中，ScrollView也就无法滑动。为解决这个问题，在ScrollView的onInterceptTouchEvent中，如果看到ACTION_DWON，返回false(点击事件对于滑动毫无意义)，但如果看到ACTION_MOVE(滑动事件),返回true并成为新的TouchTarget。注意是在OnInterceptTouchEvent中拦截而不是dispatchTouchEvent中拦截，后者会将事件传递到上层ViewGroup的onTouchEvent中。想想看，不去dispatch了、、、android这种Api起名还是可以的。

### #onClick事件

接下来看onClick和onLongClick，onTouchListener这类事件何时触发

首先是View的dispatchTouchEvent源码部分

```java
case MotionEvent.ACTION_UP:
                    boolean prepressed = (mPrivateFlags & PFLAG_PREPRESSED) != 0;
                    if ((mPrivateFlags & PFLAG_PRESSED) != 0 || prepressed) {
                        // take focus if we don't have it already and we should in
                        // touch mode.
                        boolean focusTaken = false;
                        if (isFocusable() && isFocusableInTouchMode() && !isFocused()) {
                            focusTaken = requestFocus();
                        }

                        if (prepressed) {
                            // The button is being released before we actually
                            // showed it as pressed.  Make it show the pressed
                            // state now (before scheduling the click) to ensure
                            // the user sees it.
                            setPressed(true, x, y);
                       }

                        if (!mHasPerformedLongPress && !mIgnoreNextUpEvent) {
                            // This is a tap, so remove the longpress check
                            removeLongPressCallback();

                            // Only perform take click actions if we were in the pressed state
                            if (!focusTaken) {
                                // Use a Runnable and post this rather than calling
                                // performClick directly. This lets other visual state
                                // of the view update before click actions start.
                                if (mPerformClick == null) {
                                    mPerformClick = new PerformClick();
                                }
                                if (!post(mPerformClick)) {
                                    performClick();
                                }
                            }
                        }

                        if (mUnsetPressedState == null) {
                            mUnsetPressedState = new UnsetPressedState();
                        }

                        if (prepressed) {
                            postDelayed(mUnsetPressedState,
                                    ViewConfiguration.getPressedStateDuration());
                        } else if (!post(mUnsetPressedState)) {
                            // If the post failed, unpress right now
                            mUnsetPressedState.run();
                        }

                        removeTapCallback();
                    }
                    mIgnoreNextUpEvent = false;
                    break;
```

所以onClick事件是在ACTION_UP中执行的

而LongClick事件要看ACTION_DOWN了

```java
  case MotionEvent.ACTION_DOWN:
                    mHasPerformedLongPress = false;

                    if (performButtonActionOnTouchDown(event)) {
                        break;
                    }

                    // Walk up the hierarchy to determine if we're inside a scrolling container.
                    boolean isInScrollingContainer = isInScrollingContainer();

                    // For views inside a scrolling container, delay the pressed feedback for
                    // a short period in case this is a scroll.
                    if (isInScrollingContainer) {
                        mPrivateFlags |= PFLAG_PREPRESSED;
                        if (mPendingCheckForTap == null) {
                            mPendingCheckForTap = new CheckForTap();
                        }
                        mPendingCheckForTap.x = event.getX();
                        mPendingCheckForTap.y = event.getY();
                        postDelayed(mPendingCheckForTap, ViewConfiguration.getTapTimeout());
                    } else {
                        // Not inside a scrolling container, so show the feedback right away
                        setPressed(true, x, y);
                        checkForLongClick(0, x, y);
                    }
                    break;
```

关键看checkForLongClick, 不贴代码了，结论是：在ACTION_DOWN事件被捕捉后，系统会开始触发一个postDelayed操作，delay的时间为

> ```
> ViewConfiguration.getLongPressTimeout() - delayOffset
> ```

（这个值在Eclair2.1上为500ms），500ms后会触发CheckForLongPress线程的执行：

想想看，LongClick事件是在DOWN时开始计时，500ms假设，OnClick是在UP是发生，所以完全有可能同时发生OnClick和OnLongClick。这里看到当onLongClick的返回值为true时， *mHasPerformedLongPress* = true ,仔细看ACTION_UP中，如果HasPerformLongPress==true，就不会走到onClick事件里。所以在onLongClickListener里需要返回一个boolean值的原因就这么简单。

```java
 if (!mHasPerformedLongPress && !mIgnoreNextUpEvent) {
                            // This is a tap, so remove the longpress check
                            removeLongPressCallback();

                            // Only perform take click actions if we were in the pressed state
                            if (!focusTaken) {
                                // Use a Runnable and post this rather than calling
                                // performClick directly. This lets other visual state
                                // of the view update before click actions start.
                                if (mPerformClick == null) {
                                    mPerformClick = new PerformClick();
                                }
                                if (!post(mPerformClick)) {
                                    performClick();
                                }
                            }
                        }
```

接下来是OnTouchListener，直接上结论: onTouchListener里面的方法是在dispatchTouchEvent里面调用的，并且如果listener里面的onTouch返回true，事件将不会发送给onTouchEvent，因此OnTouchListener势必会优先级高于onClick和onLongClick。

## VelocityTracker

```java
velocityTracker = VelocityTracker.obtain()；
velocityTracker.addMovement(event);
velocityTracker.computeCurrentVelocity(1);  
velocityTracker.getXVelocity();
velocityTracker.recycle();
```

值得注意的是，VelocityTracker内部使用了大量的native方法，所以执行速度比java要快很多。

### 实现Fling效果 

```java
private void onFling(float velocityX,float velocityY){
  scroller.fling(getScrollX(),getScrollY(),(int)-velocityX
                (int)-velocityY,minScrollX,maxScrollX,
                minScrollY,maxScrollY);
  invalidate();
}
@overdide// 这是每个View都有的方法
private void computeScroll(){
  if(scroller.isFinished()){
    scroller.computeScrollOffset();
    scrollTo(scroller.getCurrX(),scroller.getCurrY());
    postInvalidateOnAnimation();
  }
}


```

### 捕获双击事件

```java
public class MyView extends View {
 
GestureDetector gestureDetector;
 
public MyView(Context context, AttributeSet attrs) {
    super(context, attrs);
            // creating new gesture detector 
    gestureDetector = new GestureDetector(context, new GestureListener());
} 
 
// skipping measure calculation and drawing 
 
    // delegate the event to the gesture detector 
@Override 
public boolean onTouchEvent(MotionEvent e) {
    return gestureDetector.onTouchEvent(e);
} 
 
 
private class GestureListener extends GestureDetector.SimpleOnGestureListener {
 
    @Override 
    public boolean onDown(MotionEvent e) {
        return true; 
    } 
    // event when double tap occurs 
    @Override 
    public boolean onDoubleTap(MotionEvent e) {
        float x = e.getX();
        float y = e.getY();
 
        Log.d("Double Tap", "Tapped at: (" + x + "," + y + ")");
 
        return true; 
    } 
} 
} 
```

 最后是关于ViewConfiguration的一些常量获取的静态方法：

int getScaledTouchSlop(); (if Math.abs(x*x+y*y)>mTouchSlop 就可以认为是滑动事件了)

```java
/**    
  * 包含了方法和标准的常量用来设置UI的超时、大小和距离    
  */ 
 public class ViewConfiguration {     
     // 设定水平滚动条的宽度和垂直滚动条的高度，单位是像素px     
     private static final int SCROLL_BAR_SIZE = 10;     
          
     //定义滚动条逐渐消失的时间，单位是毫秒     
     private static final int SCROLL_BAR_FADE_DURATION = 250;     
          
     // 默认的滚动条多少秒之后消失，单位是毫秒     
     private static final int SCROLL_BAR_DEFAULT_DELAY = 300;     
          
     // 定义边缘地方褪色的长度     
     private static final int FADING_EDGE_LENGTH = 12;     
          
     //定义子控件按下状态的持续事件     
     private static final int PRESSED_STATE_DURATION = 125;     
              
     //定义一个按下状态转变成长按状态的转变时间     
     private static final int LONG_PRESS_TIMEOUT = 500;     
              
     //定义用户在按住适当按钮，弹出全局的对话框的持续时间     
     private static final int GLOBAL_ACTIONS_KEY_TIMEOUT = 500;     
              
     //定义一个touch事件中是点击事件还是一个滑动事件所需的时间，如果用户在这个时间之内滑动，那么就认为是一个点击事件     
     private static final int TAP_TIMEOUT = 115;     
              
     /**    
      * Defines the duration in milliseconds we will wait to see if a touch event     
      * is a jump tap. If the user does not complete the jump tap within this interval, it is    
      * considered to be a tap.     
      */ 
     //定义一个touch事件时候是一个点击事件。如果用户在这个时间内没有完成这个点击，那么就认为是一个点击事件     
     private static final int JUMP_TAP_TIMEOUT = 500;     
          
     //定义双击事件的间隔时间     
     private static final int DOUBLE_TAP_TIMEOUT = 300;     
              
     //定义一个缩放控制反馈到用户界面的时间     
     private static final int ZOOM_CONTROLS_TIMEOUT = 3000;     
          
     /**    
      * Inset in pixels to look for touchable content when the user touches the edge of the screen    
      */ 
     private static final int EDGE_SLOP = 12;     
              
     /**    
      * Distance a touch can wander before we think the user is scrolling in pixels    
      */ 
     private static final int TOUCH_SLOP = 16;     
              
     /**    
      * Distance a touch can wander before we think the user is attempting a paged scroll    
      * (in dips)    
      */ 
     private static final int PAGING_TOUCH_SLOP = TOUCH_SLOP * 2;     
              
     /**    
      * Distance between the first touch and second touch to still be considered a double tap    
      */ 
     private static final int DOUBLE_TAP_SLOP = 100;     
              
     /**    
      * Distance a touch needs to be outside of a window's bounds for it to    
      * count as outside for purposes of dismissing the window.    
      */ 
     private static final int WINDOW_TOUCH_SLOP = 16;     
          
    //用来初始化fling的最小速度，单位是每秒多少像素     
     private static final int MINIMUM_FLING_VELOCITY = 50;     
              
     //用来初始化fling的最大速度，单位是每秒多少像素     
     private static final int MAXIMUM_FLING_VELOCITY = 4000;     
          
     //视图绘图缓存的最大尺寸，以字节表示。在ARGB888格式下，这个尺寸应至少等于屏幕的大小     
     @Deprecated     
     private static final int MAXIMUM_DRAWING_CACHE_SIZE = 320 * 480 * 4; // HVGA screen, ARGB8888     
          
     //flings和scrolls摩擦力度大小的系数     
     private static float SCROLL_FRICTION = 0.015f;     
          
     /**    
      * Max distance to over scroll for edge effects    
      */ 
     private static final int OVERSCROLL_DISTANCE = 0;     
          
     /**    
      * Max distance to over fling for edge effects    
      */ 
     private static final int OVERFLING_DISTANCE = 4;     
          
 }
```





- ## Reference

1. [图解安卓事件分发机制](http://www.jianshu.com/p/e99b5e8bd67b)
2. [making sense of the touch system](https://www.youtube.com/watch?v=usBaTHZdXSI)
3. [Android onTouchEvent, onClick及onLongClick的调用机制](http://blog.csdn.net/ddna/article/details/5451722)
4. [Android触摸事件机制(三)](http://wangkuiwu.github.io/2015/01/03/TouchEvent-View/)
5. [ViewConfiguration用法](http://www.jcodecraeer.com/a/anzhuokaifa/androidkaifa/2013/0225/907.html)
6. [触摸事件的分析与总结](http://glblong.blog.51cto.com/3058613/1559320)

   ​