---
title: 使用RecyclerView的Animation
date: 2016-10-20 16:16:49
categories: blog  
tags: [android,RecyclerView]
---

From the talk
RecyclerView Animations and Behind the Scenes
Yigit Biyar & Chet Haase
on Anroid Dev Summit 2015

### 1. RecyclerView架构

RecyclerView is Flexible , Pluggable and Customizeable
内部很多功能都交给了各个组件去完成
![](http://www.haldir66.ga/static/imgs/snapshot20161020135353.jpg)
ChildHelper 、AdapterHelper 、Recycler对于开发者来说并不常用，但它们在内部负责了许多针对Child View的管理。<!--more-->


- ViewHolder的创建
![](http://www.haldir66.ga/static/imgs/viewHolder_step_1.jpg)
1 .LayoutManager首先检查getViewForPosition，RecyclerView查找Cache(getViewForPosition)，如果找到了。直接交给LayoutManager,这一过程甚至不需要与Adapter接触。
2. 如果Cache中未找到，RecyclerView调用Adpter的getViewType，并去Recycled Pool中getViewHolderByType。
3. 如果在Pool中未找到，RecyclerView将调用Adapter的createViewHolder。
4. 如果在Pool中这种Type的ViewHolder已经有了，或者步骤3中创建了一个新的viewHolder，bindViewHolder并交给LayoutManager。
![](http://www.haldir66.ga/static/imgs/viewHolder_step_2.jpg)
5. 最终LayoutManager将把这个View添加到UI，这时会调用RecyclerView的onViewAttachedToWindow回调（生命周期）。


- ViewHolder的回收(Reserves)
![](http://www.haldir66.ga/static/imgs/viewHolder_step_3.jpg)
1. LayoutManager调用removeAndRecycleView，RecyclerView会在这里收到回调onViewDetachedFromWindow
2. 检查这个View.isValid。这一点很重要，在scroll过程中，如果一个View是Valid的话，可以将View添加到Cache中，随后可以简单将其复用。Cache将会invalidate oldest one，并告诉Adapter(onViewRecycled)。
3. 如果不是Valid的View，将会被添加到Pool中，Adapter会收到onViewRecycled回调。

- ViewHolder的另一种更好的回收方式(Fancy Reserves!)
![](http://www.haldir66.ga/static/imgs/snapshot20161020124442.jpg)
1. LayoutManager调用onLayoutChildren
2. Layout完成后，RecyclerView检查那些之前已经被layout了的但不再存在于屏幕上了。RecyclerView将这些View重新添加到ViewGroup中，这些View此时对LayoutManager不可见。重新添加的目的在于动画。
3. RecyclerView这时候把这些本不该add的View交给ItemAnimator，后者调用动画效果，300ms(安卓中大部分默认动画时间是300ms)之后，调用onAnimationFinished，告诉RecyclerView.
4. 接着RecyclerView通知Adapter(onViewDetachedFromWindow)
5. 最后将这些View添加到Cache或者Recycled Pool。

- ViewHolder的销毁
![](http://www.haldir66.ga/static/imgs/snapshot20161020124836.jpg)
1. LayoutManager调用removeAndRecycleView，RecyclerView检查View是否valid
2. 如果不是Valid，添加到RecycledPool中，但在这之前先检查是否 hasTransientState（例如正在运行动画）
3. 如果这个View正好处在Animation中，一些属性被Animating， Pool会调用Adapter的onFailedToRecycle(Adapter中应该复写这个方法，取消动画)
4. onFailedToRecycle(ViewHolder)返回true的话，Pool将无视View的TransientState并回收这个View(可能处在动画中)

- 另一种可能导致ViewHolder被销毁的方式
![](http://www.haldir66.ga/static/imgs/snapshot20161020143554.jpg)
RecyclerView将View添加到Pool中(实际调用的是addViewHolderToRecycledViewPool(ViewHolder))，Pool会检查这种type的ViewHolder是否还放得下（例如type x的ViewHolder已经有5个了，实在太多了），这种情况下就会Kill这种View,这种情况是我们希望避免的。开发者可以调用pool.setMaxRecycledViews(type,count)来让Pool放更多的Holder per type。

一些需要注意的，Pool是基于一个Activity Context的。

### 2. 使用LayoutManager配合ItemAnimator自定义ItemView的动画的步骤

perdictiveItemAnimation的关键在于RecyclerView的list并不局限于屏幕。
在LayoutManager中复写
> supportPredictiveItemAnimations()，返回true。

LinearLayoutManger的实现

```java
 @Override
    public boolean supportsPredictiveItemAnimations() {
        return mPendingSavedState == null && mLastStackFromEnd == mStackFromEnd;
    }
```
可以认为返回值就是true

onLayoutChildern在这种情况下会被调用两次，(之前提到本该被移除的View需要重新添加到ViewGroup中，实现就在这里)
参考LinearLayoutManager的实现，源代码实在太长，只复制一些注释
```java
 @Override
    public void onLayoutChildren(RecyclerView.Recycler recycler, RecyclerView.State state) {
        // layout algorithm:
        // 1) by checking children and other variables, find an anchor coordinate and an anchor
        //  item position.
        // 2) fill towards start, stacking from bottom
        // 3) fill towards end, stacking from top
        // 4) scroll to fulfill requirements like stack from bottom.
        // create layout state
        //omitted....
        }
```
简单来说一共三步:

1. detach and Scrap Views
2. layout那些需要出现在list中的View(包括将要消失的View)
3. 接下来进入第二步layout，在这里确定那些将出现在屏幕外的View的实际位置。

这样LayoutManager就能将必要的信息传递给ItemAnimator

- 进入ItemAnimator
大部分的需要实现的函数在SimpleItemAnimator或者DefaultItemAnimator里面都已经实现好了，所以大部分人的选择就是：
1. 使用DefaultItemAnimator(默认已经设置好了)
2. Implement SimpleItemAnimator(或者DeafaultItemAnimator)，复写一些必要的方法

Animator需要做的一些事
```java
record[Pre|Post]LayoutInformation//记录动画开始和结束的layout信息
animate[Appearance|Disappearance]
animatePersistence()//不会改变位置
animateChange()//实际的动画添加位置
```
这些在DefaultItemAnimator中都有默认的实现
动画完成后一定要调用
> DispatchAnimationFinished(ViewHolder)

记录动画开始前和结束后的信息，实例代码:
```java
  @NonNull
        @Override
        public ItemHolderInfo recordPreLayoutInformation(RecyclerView.State state,
                RecyclerView.ViewHolder viewHolder, int changeFlags, List<Object> payloads) {
            ColorTextInfo info = (ColorTextInfo) super.recordPreLayoutInformation(state, viewHolder,
                    changeFlags, payloads);
            return getItemHolderInfo((MyViewHolder) viewHolder, info);
        }

        @NonNull
        @Override
        public ItemHolderInfo recordPostLayoutInformation(@NonNull RecyclerView.State state,
                @NonNull RecyclerView.ViewHolder viewHolder) {
            ColorTextInfo info = (ColorTextInfo) super.recordPostLayoutInformation(state, viewHolder);
            return getItemHolderInfo((MyViewHolder) viewHolder, info);
        }

        @Override
        public ItemHolderInfo obtainHolderInfo() {
            return new ColorTextInfo();
        }

```


- canReuseViewHolder的作用:
例如notifyItemChanged(position)后，只是某个位置的viewHolder发生了信息改变，那就没有必要创建一个新的ViewHolder，直接提供原有的ViewHolder，提升性能。

### 3. 常见错误
1. mAdapter.notifyItemMoved(1,5)
不会调用onBindViewHolder，不会invalidate

2. 不要在onBindViewHolder中添加onClickListener(以匿名内部类的方式,这会使得position变成final),想象一下，mAdapter.notifyItemMoved(1,5)调用后不会调用onBindViewHolder，这使得点击pos 1时实际传递给listener的是pos 5。

3. 检查RecyclerView.NO_POSITION
这个Int值为-1，其实就是itemView被removed，但用户手够快，在View被移除前点击了这个View，那这个onClickListener还是会被调用。

4. mAdapter.notifyItemChanged(position,payload)
如果某个ViewHolder中只是一部分信息改变，将更新内容丢到payload中，最终会调用到onBindViewHolder(ViewHolder,position,List Payloads)，在这里只需要把ViewHolder中的一小部分改变就可以了，这有助于优化新能。

5. onCreateViewHolder*必须*返回一个new ViewHolder，不能在本地作为成员变量返回。

6. RecyclerView.setRecycledViewPool(pool)
一个pool只能为为同一个context(Activity)中的RecyclerView使用，因为这些View是与Context相关的，而不同的Activity可能有不同的Theme，Style。

7. Pro RecyclerView
最近看到yigit在relam作的关于recyclerView的演讲，记录下来一些比较重要的点

- view:: requestLayout的效果，requestLayout会一直地向上请求直到根视图，next Frame开始时，所有的子View都将调用自身的measure(onMeasure)和layout(onLayout)方法
如果子View不曾requestLayout,之前的measure结果会被cache下来，节省measure和layout的时间。

- 在RecyclerView中，在itemView的onBIndView方法中调用ImageLoader的加载图片方法，由于图片加载是异步操作，最终会调用ImageView的setImageBitmap方法。而在ImageView的实现中，setImageBitmap方法最终会调用requestLayout方法，最终会一层层向上传递到recyclerView中，就像这样
```java
imageView setImageBitmap

imageView requestLayout

itemView requestLayout

recyclerView requestLayout
```
而recyclerView的requestLayout方法会在next Frame重新position所有的child(very expensive!)为此，recyclerView提供了一个setHasFixedSize方法，设置为true表明recyclerView自身不会因为childView的变化而resize，这样recyclerVeiw就不会调用requestLayout方法(如果去看RecyclerView的源码，可以看到mEatRequestLayout这个变量，也就是避免重复调用requestLayout造成性能损耗。)，不会造成所有的childView都被重新测量一遍。在ImageView(2011年之后的版本)中，setImageDrawable方法大致长这样：
```java
void setImageDrawable(Drawable drawable){
    if(mDrawable != drawable){
    int oldWidth = mDrawableWidth;
    int oldHeight = mDrawableHeight;
    updateDrawable(drawable)
        if(oldWidth!=mDrawableWidth||oldHeight!=mDrawableHeight){
            requestLayout();
        }
        invalidate();
    }
}

```
简单来说就是判断下前后图像的宽度或高度是否发生了变化，如果无变化则不需调用requestLayout方法，只需要reDraw。也就避免了这种性能的损耗。但是，TextView的implementation则复杂的多，并没有这种优化。实际操作中，API应该能够告诉客户端图片的width和Height,使用AspectRationImageView加载图片。在图片加载完成之前优先使用PlaceHolder，并设定好加载完成应有的尺寸，这样就避免了后期图片加载完成后的requestLayout。

- 使用SortedList用于进行List变更
```java
SortedList<Item> mSortedList = new SortedList<Item>(Item.class,
    new SortedListAdapterCallback<Item>(mAdapter)){
    //override三个方法，懒得抄了

}
使用方式十分简单，后面的数据更新操作包括notifyDataChange都被处理好了。
onNetwokCallback(List<News> news){
    mSortedList.addAll(news);
}
```
对于未发生变化的Item，将直接跳过，实现了最优化的列表数据更新。

- DiffUtil(added in 24.2.0)用于对比数据变更前后的两个List
```java
DiffResult result = DiffUtil.calculateDiff(
    new MyCallback(oldList,newList));
mAdapter.setItems(newList);
result.dispatchTo(mAdapter);
```
只需调用上述方法即可实现列表Item更新及Adapter的notify。DiffUtil的callback有四个方法需要复写，另外有一个方法用于单个Item的部分payload更新。在[medium](https://medium.com/@iammert/using-diffutil-in-android-recyclerview-bdca8e4fbb00#.rbtzmmtbg)上找到一个现成的，直接借用了。
```java
public class MyDiffCallback extends DiffUtil.Callback{

    List<Person> oldPersons;
    List<Person> newPersons;

    public MyDiffCallback(List<Person> newPersons, List<Person> oldPersons) {
        this.newPersons = newPersons;
        this.oldPersons = oldPersons;
    }

    @Override
    public int getOldListSize() {
        return oldPersons.size();
    }

    @Override
    public int getNewListSize() {
        return newPersons.size();
    }

    @Override
    public boolean areItemsTheSame(int oldItemPosition, int newItemPosition) {
        return oldPersons.get(oldItemPosition).id == newPersons.get(newItemPosition).id;
    }

    @Override
    public boolean areContentsTheSame(int oldItemPosition, int newItemPosition) {
        return oldPersons.get(oldItemPosition).equals(newPersons.get(newItemPosition));
    }

    @Nullable
    @Override
    public Object getChangePayload(int oldItemPosition, int newItemPosition) {
        //you can return particular field for changed item.//这里的object会被带到onBindViewHolder中
        return super.getChangePayload(oldItemPosition, newItemPosition);
    }
}
```
这些方法会帮助完成remove和add等方法。

- viewHolder的生命周期

onCreate
onBindViewHolder(获取video资源)
onViewAttachedToWindow(可以在这里开始播放视频)
onViewDetachedFromWindow(可以在这里停止播放视频，随时有可能重新被直接attach，这过程中不会调用onBind方法)
onRecycled(可以在这里释放Video资源或者释放Bitmap引用，这之后再使用该ViewHolder需要调用onBind方法)


- recyclerView的一些defer操作对于日常开发的帮助
recyclerView会将一些pending操作defer到next frame。eg:
```java
recyclerView.scrollToPosition(15);
int x = layoutManager.getFirstVisiblePosition();//此时x并不等于15，因为下一帧并未开始。真正的执行scroll操作需要等到nextFrame执行后才能生效，具体一点的话，就是下一个执行layout的message的callback还未被执行。
// 又例如，在onCreate中调用
recyclerView.scrollToPosition(15);
//在netWorkCallback中调用setAdapter，这时recyclerView会利用pending的15 position。原因在于recyclerView会判断如果layoutManager和adapter是否为null，如果都为null。skip layout。

// - 在getItemViewType中返回R.layout.itemLayout的好处。
onCreateViewHolder(ViewGroup viewParent,int ViewType) {
    View itemView = inflate.inflate(ViewType,parent,false);
    return XXXHolder(itemView);//aapt可以确保R.layout.xxxx是unique的。
}
```

- ClickListener的实现
在onCreateViewHolder中传一个callback，不要在onBindViewHolder中传，不要把onBindViewHolder中的position变为final的。getAdapterPositon可能为NO_POSITION(-1)，因为RecyclerView的UI更新会被defer到next Frame，在下一帧更新被执行前，用户可能已经点击了item，这时的position就有可能是-1(这种情况发生在点击后删除了所有的item数据，这时获得的position就类似于list的indexAt，当然是-1。).

- LayoutManager只知道LayoutPosition，并不知道AdapterPosition
Items在Adapter的数据集中的顺序可能会随时变更，但recyclerView可能并不会调用onBindViewHolder方法，这也就是onBindViewHolder中的position并不可靠的原因。因为viewHolder本身是backed by Item的，而viewHolder的getAdapterPosition能够正确地反应Item在数据集中的顺序。



## 4.更新
RecyclerView 26.1.0源码摘取部分分析

### 4.1 TouchEvent的处理逻辑
关于RecyclerView 的TouchEvent的处理逻辑：
直接来看onTouchEvent中的ACTION_MOVE的处理吧：
```java
  if (mScrollState == SCROLL_STATE_DRAGGING) {
                    mLastTouchX = x - mScrollOffset[0];
                    mLastTouchY = y - mScrollOffset[1];

                    if (scrollByInternal(
                            canScrollHorizontally ? dx : 0,
                            canScrollVertically ? dy : 0,
                            vtev)) {
                        getParent().requestDisallowInterceptTouchEvent(true);
                    }
                    if (mGapWorker != null && (dx != 0 || dy != 0)) {
                        mGapWorker.postFromTraversal(this, dx, dy);
                    }
                }

 boolean scrollByInternal(int x, int y, MotionEvent ev) {
        int unconsumedX = 0, unconsumedY = 0;
        int consumedX = 0, consumedY = 0;

        consumePendingUpdateOperations();
        if (mAdapter != null) {
            eatRequestLayout();
            onEnterLayoutOrScroll();
            TraceCompat.beginSection(TRACE_SCROLL_TAG);
            fillRemainingScrollValues(mState);//从viewFlinger的overScroller中查询还剩多少distance,赋值给mState
            if (x != 0) {
                consumedX = mLayout.scrollHorizontallyBy(x, mRecycler, mState);
                unconsumedX = x - consumedX;
            }
            if (y != 0) {
                consumedY = mLayout.scrollVerticallyBy(y, mRecycler, mState);
                unconsumedY = y - consumedY; 
                // 以scrollVerticallyBy为例，内部调用了scrollBy方法。
                //这里面分两步，一个是fill，一个是offsetChildrenVertical
            }
            TraceCompat.endSection();
            repositionShadowingViews();
            onExitLayoutOrScroll();
            resumeRequestLayout(false);
        }
        if (!mItemDecorations.isEmpty()) {
            invalidate();
        }

        if (dispatchNestedScroll(consumedX, consumedY, unconsumedX, unconsumedY, mScrollOffset,
                TYPE_TOUCH)) {
            // Update the last touch co-ords, taking any scroll offset into account
            mLastTouchX -= mScrollOffset[0];
            mLastTouchY -= mScrollOffset[1];
            if (ev != null) {
                ev.offsetLocation(mScrollOffset[0], mScrollOffset[1]);
            }
            mNestedOffsets[0] += mScrollOffset[0];
            mNestedOffsets[1] += mScrollOffset[1];
        } else if (getOverScrollMode() != View.OVER_SCROLL_NEVER) {
            if (ev != null && !MotionEventCompat.isFromSource(ev, InputDevice.SOURCE_MOUSE)) {
                pullGlows(ev.getX(), unconsumedX, ev.getY(), unconsumedY);
            }
            considerReleasingGlowsOnScroll(x, y);
        }
        if (consumedX != 0 || consumedY != 0) {
            //通知onScrollListner事实上滑动了多少距离
            dispatchOnScrolled(consumedX, consumedY);
        }
        if (!awakenScrollBars()) {
            invalidate();
        }
//只要layoutmanager消费的x和y有一个不为0，就请求requestDisallowInterceptTouchEvent.
        return consumedX != 0 || consumedY != 0;
    }
```
在scrollBy方法中
亲测，在一个veticalLinearLayoutManager中，手指往上走的时候,dy是>0的

```java
final int scrolled = absDy > consumed ? layoutDirection * consumed : dy;
//layoutDirection在dy>0时为1，在dy<0时为-1
//比如手指往上走，view照理说也该往上走，如果实际消费的移动距离小于外部要求的移动距离绝对值，则使用消费了的distance。所以RecyclerView实际消费了的滑动距离（也就是在onScrollListener中获取到的距离)就是在这里决定的。

//下面这个scrolled就是RecyclerView中所有child实际上滑动的距离。

final int consumed = mLayoutState.mScrollingOffset
        + fill(recycler, mLayoutState, state, false);
if (consumed < 0) {
    if (DEBUG) {
        Log.d(TAG, "Don't have any more elements to scroll");
    }
    return 0;
}
final int scrolled = absDy > consumed ? layoutDirection * consumed : dy;
mOrientationHelper.offsetChildren(-scrolled);
//亲测，手指往上走的时候，这个scrolled是>0的，也就是传给offsetChildren的参数是负数，所以view在视觉上会往上走。这里面也是实际上调用了view.offsetTopAndBottom方法。
```
再看这个fill方法
```java
   int fill(RecyclerView.Recycler recycler, LayoutState layoutState,
            RecyclerView.State state, boolean stopOnFocusable) {
        // max offset we should set is mFastScroll + available
        final int start = layoutState.mAvailable; //手指往上走的时候这个是负数
        //关于这个available，注释里说的是 Number of pixels that we should fill, in the layout direction.
        if (layoutState.mScrollingOffset != LayoutState.SCROLLING_OFFSET_NaN) {
            // TODO ugly bug fix. should not happen
            if (layoutState.mAvailable < 0) {
                //手指往上走的时候因为mAvailable<0会走到这里
                layoutState.mScrollingOffset += layoutState.mAvailable;
                // mScrollingOffset的注释说的是：Used when LayoutState is constructed in a scrolling state.
                // It should be set the amount of scrolling we can make without creating a new view.
                // Settings this is required for efficient view recycling.
            }
            recycleByLayoutState(recycler, layoutState);
            // 这里面就是根据layoutState的direction开始回收view
            //比如手指往上走，就调用recycleViewsFromStart，手指往下走就调用recycleViewsFromEnd。也说得通，手指往上走，顶部的view被滑出屏幕，当然可以开始回收流程

        }
        int remainingSpace = layoutState.mAvailable + layoutState.mExtra;
        LayoutChunkResult layoutChunkResult = mLayoutChunkResult;
        while ((layoutState.mInfinite || remainingSpace > 0) && layoutState.hasMore(state)) {
            layoutChunkResult.resetInternal();
            if (VERBOSE_TRACING) {
                TraceCompat.beginSection("LLM LayoutChunk");
            }
            layoutChunk(recycler, state, layoutState, layoutChunkResult);
            //主要的工作就在layoutChunk里面完成
            if (VERBOSE_TRACING) {
                TraceCompat.endSection();
            }
            if (layoutChunkResult.mFinished) {
                break;
            }
            layoutState.mOffset += layoutChunkResult.mConsumed * layoutState.mLayoutDirection;
            /**
             * Consume the available space if:
             * * layoutChunk did not request to be ignored
             * * OR we are laying out scrap children
             * * OR we are not doing pre-layout
             */
            if (!layoutChunkResult.mIgnoreConsumed || mLayoutState.mScrapList != null
                    || !state.isPreLayout()) {
                layoutState.mAvailable -= layoutChunkResult.mConsumed;
                // we keep a separate remaining space because mAvailable is important for recycling
                remainingSpace -= layoutChunkResult.mConsumed;
            }

            if (layoutState.mScrollingOffset != LayoutState.SCROLLING_OFFSET_NaN) {
                layoutState.mScrollingOffset += layoutChunkResult.mConsumed;
                if (layoutState.mAvailable < 0) {
                    layoutState.mScrollingOffset += layoutState.mAvailable;
                }
                recycleByLayoutState(recycler, layoutState);//这里是回收View的入口
            }
            if (stopOnFocusable && layoutChunkResult.mFocusable) {
                break;
            }
        }
        return start - layoutState.mAvailable;
    }
```

打断点发现，在scrollBy的过程中通过layoutChunk方法一直走到Recycler.tryGetViewHolderForPositionByDeadline

1. tryGetViewHolderForPositionByDeadline方法用于获取一个viewHolder

```java
// 0) If there is a changed scrap, try to find from there
 holder = getChangedScrapViewForPosition(position);

// 1) Find by position from scrap/hidden list/cache
 holder = getScrapOrHiddenOrCachedHolderForPosition(position, dryRun);

// 2) Find from scrap/cache via stable ids, if exists
if (mAdapter.hasStableIds()) {
    holder = getScrapOrCachedViewForId(mAdapter.getItemId(offsetPosition), type, dryRun);
}

//这中间还有一个
 final View view = mViewCacheExtension.getViewForPositionAndType(this, position, type);

// fallback to pool
holder = getRecycledViewPool().getRecycledView(type);

//last resort
holder = mAdapter.createViewHolder(RecyclerView.this, type);
```

以上即为获取holder的优先顺序，获取到holder之后就是bindViewHolder了


### 回收过程
在LinearLayoutManager的scrollBy -> fill ->recycleByLayoutState ->recycleViewsFromStart(遍历children,确保移除不可见的child)
处置view的逻辑在recycleViewHolderInternal中
首先是尝试mCachedViews（ ArrayList<ViewHolder>，默认最大mViewCacheMax = 2，实际debug中是3）
```java
// Retire oldest cached view
int cachedViewSize = mCachedViews.size();
if (cachedViewSize >= mViewCacheMax && cachedViewSize > 0) {
    recycleCachedViewAt(0); // 将list中第一个viewHolder踢到Pool ->这里面调用了addViewHolderToRecycledViewPool
    cachedViewSize--;
}
// 这之后将新来的这个holder加到list的尾部，现在看来就是3
//接下来应该是从recyclerViewPool中根据对应的类型找到合适的ScrapHeap，添加进去。目前看来，pool就是根据不同的viewType维持了不同的ArrayList<ViewHolder>,
```

### view被recycle的时候是否可以去移除对应的View中ImageView的drawable?答案是不能
亲测下来，在onViewDetachedFromWindow中去setImageDrawable(null)的话。手指慢慢将一个ImageView滑出屏幕，然后再滑回来的话。这个ImageView的背景就没有了。显然这个过程中没有重新去走onBindViewHolder方法。但是滑动出屏幕确实调用到了mAdapter.onViewDetachedFromWindow(viewHolder)方法。

***那么detach下来的View被丢到哪里了？***

从源码来看：
整个的调用流程应该是这样的：
RecyclerView.onTouchEvent -> RecyclerView.scrollByInternal -> RecyclerView.scrollVerticallyBy -> LinearLayoutManager.scrollBy -> LinearLayoutManager.fill -> LinearLayoutManger.recycleByLayoutSate ->
LinearLayoutManager.recycleViewFromStart -> LinearLayoutManager.recycleChildren ->
LayoutManager.removeAndRecycleViewAt(index,recycler) 

```java
public void removeAndRecycleViewAt(int index, Recycler recycler) {
    final View view = getChildAt(index);
    removeViewAt(index);
    recycler.recycleView(view);
}
```
removeViewAt方法长这样：
```java
 @Override
            public void removeViewAt(int index) {
                final View child = RecyclerView.this.getChildAt(index);
                if (child != null) {
                    dispatchChildDetached(child);

                    // Clear any android.view.animation.Animation that may prevent the item from
                    // detaching when being removed. If a child is re-added before the
                    // lazy detach occurs, it will receive invalid attach/detach sequencing.
                    child.clearAnimation();
                }
                if (VERBOSE_TRACING) {
                    TraceCompat.beginSection("RV removeViewAt");
                }
                RecyclerView.this.removeViewAt(index); //这一步执行完,getParent() =null
                if (VERBOSE_TRACING) {
                    TraceCompat.endSection();
                }
            }
```

而dispatchChildDetached是在parent.removeChild之前调用的
```java
 void dispatchChildDetached(View child) {
        final ViewHolder viewHolder = getChildViewHolderInt(child);
        onChildDetachedFromWindow(child);
        if (mAdapter != null && viewHolder != null) {
            mAdapter.onViewDetachedFromWindow(viewHolder);// 走到这里getParent还不会为null
        }
        if (mOnChildAttachStateListeners != null) {
            final int cnt = mOnChildAttachStateListeners.size();
            for (int i = cnt - 1; i >= 0; i--) {
                mOnChildAttachStateListeners.get(i).onChildViewDetachedFromWindow(child);
            }
        }
    }
```

remove完之后就是recycler.recycleView(view)了，具体实现在recycleViewHolderInternal里面.mCachedViews,viewCacheExtension或者recyclerPool中。
先看下recycler的内部成员变量结构
```java
 public final class Recycler {
        final ArrayList<ViewHolder> mAttachedScrap = new ArrayList<>();
        ArrayList<ViewHolder> mChangedScrap = null;

        final ArrayList<ViewHolder> mCachedViews = new ArrayList<ViewHolder>();

        private final List<ViewHolder>
                mUnmodifiableAttachedScrap = Collections.unmodifiableList(mAttachedScrap);

        private int mRequestedCacheMax = DEFAULT_CACHE_SIZE;
        int mViewCacheMax = DEFAULT_CACHE_SIZE;

        RecycledViewPool mRecyclerPool;

        private ViewCacheExtension mViewCacheExtension;

        static final int DEFAULT_CACHE_SIZE = 2;

        //.... 下面就是一些method了，可以看到缓存全部都是以ViewHolder为单位的
        }
```

Recycler.recycleViewHolderInternal(ViewHolder holder)
```java
   /**
         * internal implementation checks if view is scrapped or attached and throws an exception
         * if so.
         * Public version un-scraps before calling recycle.
         */
        void recycleViewHolderInternal(ViewHolder holder) {
            if (holder.isScrap() || holder.itemView.getParent() != null) {
                //从这里也可以看出来，到了这个时候,parent已经为null了
                throw new IllegalArgumentException(
                        "Scrapped or attached views may not be recycled. isScrap:"
                                + holder.isScrap() + " isAttached:"
                                + (holder.itemView.getParent() != null) + exceptionLabel());
            }

            if (holder.isTmpDetached()) {
                throw new IllegalArgumentException("Tmp detached view should be removed "
                        + "from RecyclerView before it can be recycled: " + holder
                        + exceptionLabel());
            }

            if (holder.shouldIgnore()) {
                throw new IllegalArgumentException("Trying to recycle an ignored view holder. You"
                        + " should first call stopIgnoringView(view) before calling recycle."
                        + exceptionLabel());
            }
            //上面这些exception就不看了
            //noinspection unchecked
            final boolean transientStatePreventsRecycling = holder
                    .doesTransientStatePreventRecycling();
            final boolean forceRecycle = mAdapter != null
                    && transientStatePreventsRecycling
                    && mAdapter.onFailedToRecycleView(holder);
                    //onFailedToRecycleView就是在这个时候调用到的
            boolean cached = false;
            boolean recycled = false;
            if (DEBUG && mCachedViews.contains(holder)) {
                throw new IllegalArgumentException("cached view received recycle internal? "
                        + holder + exceptionLabel());
            }
            //强调一下，走到这里，view.getParent() = null
            if (forceRecycle || holder.isRecyclable()) { //forceRecycle 到这里是false
                if (mViewCacheMax > 0 //什么都不做的话，mViewCacheMax=3
                        && !holder.hasAnyOfTheFlags(ViewHolder.FLAG_INVALID
                        | ViewHolder.FLAG_REMOVED
                        | ViewHolder.FLAG_UPDATE
                        | ViewHolder.FLAG_ADAPTER_POSITION_UNKNOWN)) {
                    // Retire oldest cached view
                    int cachedViewSize = mCachedViews.size();//什么都不做的话，这里是3
                    if (cachedViewSize >= mViewCacheMax && cachedViewSize > 0) {
                        //这里其实就是mCachedViews已经满了
                        recycleCachedViewAt(0); //因为是一个ArrayList,在已经满了的情况下，直接把最老的（第一个）删掉
                        cachedViewSize--;
                    }

                    int targetCacheIndex = cachedViewSize;
                    if (ALLOW_THREAD_GAP_WORK
                            && cachedViewSize > 0
                            && !mPrefetchRegistry.lastPrefetchIncludedPosition(holder.mPosition)) {
                        // when adding the view, skip past most recently prefetched views
                        int cacheIndex = cachedViewSize - 1;
                        while (cacheIndex >= 0) {
                            int cachedPos = mCachedViews.get(cacheIndex).mPosition;
                            if (!mPrefetchRegistry.lastPrefetchIncludedPosition(cachedPos)) {
                                break;
                            }
                            cacheIndex--;
                        }
                        targetCacheIndex = cacheIndex + 1;
                    }
                    mCachedViews.add(targetCacheIndex, holder);//刚才不是把第一个位置的holder从mCachedViews中删除掉了吗，现在就可以把新来的这个holder加进去了。
                    cached = true;
                }
                if (!cached) {
                    addViewHolderToRecycledViewPool(holder, true);
                    recycled = true;
                }
            } else {
                // NOTE: A view can fail to be recycled when it is scrolled off while an animation
                // runs. In this case, the item is eventually recycled by
                // ItemAnimatorRestoreListener#onAnimationFinished.

                // TODO: consider cancelling an animation when an item is removed scrollBy,
                // to return it to the pool faster
                if (DEBUG) {
                    Log.d(TAG, "trying to recycle a non-recycleable holder. Hopefully, it will "
                            + "re-visit here. We are still removing it from animation lists"
                            + exceptionLabel());
                }
            }
            // even if the holder is not removed, we still call this method so that it is removed
            // from view holder lists.
            mViewInfoStore.removeViewHolder(holder);
            if (!cached && !recycled && transientStatePreventsRecycling) {
                holder.mOwnerRecyclerView = null;
            }
        }
```

recycleCachedViewAt这个方法里面
```java
 void recycleCachedViewAt(int cachedViewIndex) {
            if (DEBUG) {
                Log.d(TAG, "Recycling cached view at index " + cachedViewIndex);
            }
            ViewHolder viewHolder = mCachedViews.get(cachedViewIndex);
            if (DEBUG) {
                Log.d(TAG, "CachedViewHolder to be recycled: " + viewHolder);
            }
            addViewHolderToRecycledViewPool(viewHolder, true);
            mCachedViews.remove(cachedViewIndex); //丢进recyelcerPool的viewHolder就可以从mCachedView中挪掉了
        }


/**
* Prepares the ViewHolder to be removed/recycled, and inserts it into the RecycledViewPool.
*
* Pass false to dispatchRecycled for views that have not been bound.
*
* @param holder Holder to be added to the pool.
* @param dispatchRecycled True to dispatch View recycled callbacks.
*/
void addViewHolderToRecycledViewPool(ViewHolder holder, boolean dispatchRecycled) {
    clearNestedRecyclerViewIfNotNested(holder);
    if (holder.hasAnyOfTheFlags(ViewHolder.FLAG_SET_A11Y_ITEM_DELEGATE)) {
        holder.setFlags(0, ViewHolder.FLAG_SET_A11Y_ITEM_DELEGATE);
        ViewCompat.setAccessibilityDelegate(holder.itemView, null);
    }
    if (dispatchRecycled) {
        dispatchViewRecycled(holder);// mRecyclerListener.onViewRecycled(holder); mAdapter.onViewRecycled(holder);这些方法
    }
    holder.mOwnerRecyclerView = null;
    //接下来开始丢到recyclerPool中
    getRecycledViewPool().putRecycledView(holder);
}
```

recyclerpool中的成员变量如下:
```java
   */
    public static class RecycledViewPool {
        private static final int DEFAULT_MAX_SCRAP = 5;

        /**
         * Tracks both pooled holders, as well as create/bind timing metadata for the given type.
         *
         * Note that this tracks running averages of create/bind time across all RecyclerViews
         * (and, indirectly, Adapters) that use this pool.
         *
         * 1) This enables us to track average create and bind times across multiple adapters. Even
         * though create (and especially bind) may behave differently for different Adapter
         * subclasses, sharing the pool is a strong signal that they'll perform similarly, per type.
         *
         * 2) If {@link #willBindInTime(int, long, long)} returns false for one view, it will return
         * false for all other views of its type for the same deadline. This prevents items
         * constructed by {@link GapWorker} prefetch from being bound to a lower priority prefetch.
         */
        static class ScrapData {
            ArrayList<ViewHolder> mScrapHeap = new ArrayList<>();
            int mMaxScrap = DEFAULT_MAX_SCRAP;
            long mCreateRunningAverageNs = 0; //这个是为prefetcher准备的，prefetcher会根据这种viewType的Holder的平均bindViewHolder时间推断是否能够在下一个Frame前完成bind操作
            long mBindRunningAverageNs = 0;
        }
        SparseArray<ScrapData> mScrap = new SparseArray<>();

        private int mAttachCount = 0;
}
```
所以整个RecyclerPool的缓存就是一个SparseArray，ViewType作为key，一个ArrayList<ViewHolder>作为value。每种类型的viewHolder都维持了一个ArrayList，默认ArrayList的最大容量为5。

所以整个缓存结构就是三层。mCachedViews（List<ViewHolder>)是一层，recyclerPool中的sparseArray是第三层，中间还有一个ViewCacheExtension需要用户自定义，不过只需要重写getViewForPositionAndType这一个方法就行。

**回收view的过程到此结束，再利用的过程呢?**

GapWorker.run  -> GapWorker.prefetch  -> GapWorker.flushTasksWithDeadLine -> GapWorker.flushTaskWithDeadLine -> GapWorker.prefetchPositionWithDeadLine -> Recycler.tryGetViewHolderForPositionByDeadline


打断点发现，在scrollBy的过程中通过layoutChunk方法一直走到Recycler.tryGetViewHolderForPositionByDeadline

1. tryGetViewHolderForPositionByDeadline方法用于获取一个viewHolder
```java
// 0) If there is a changed scrap, try to find from there
 holder = getChangedScrapViewForPosition(position);
// 1) Find by position from scrap/hidden list/cache
 holder = getScrapOrHiddenOrCachedHolderForPosition(position, dryRun);
// 2) Find from scrap/cache via stable ids, if exists
if (mAdapter.hasStableIds()) {
    holder = getScrapOrCachedViewForId(mAdapter.getItemId(offsetPosition), type, dryRun);
}
//这中间还有一个
 final View view = mViewCacheExtension.getViewForPositionAndType(this, position, type);

// fallback to pool
holder = getRecycledViewPool().getRecycledView(type);

//last resort
holder = mAdapter.createViewHolder(RecyclerView.this, type);

```
以上即为获取holder的优先顺序，获取到holder之后就是bindViewHolder了

接下来看获得到holder之后，无论是从mCachedViews还是recyclerpool中获得的holder，下面决定是否需要绑定

```java
boolean bound = false;
if (mState.isPreLayout() && holder.isBound()) {
    //如果已经调用过BindViewHolder方法，就不再去onBindViewHolder了。而是直接将这个viewholder的itemView返回给getViewPosition函数
    // do not update unless we absolutely have to.
    holder.mPreLayoutPosition = position;
} else if (!holder.isBound() || holder.needsUpdate() || holder.isInvalid()) {
    if (DEBUG && holder.isRemoved()) {
        throw new IllegalStateException("Removed holder should be bound and it should"
                + " come here only in pre-layout. Holder: " + holder
                + exceptionLabel());
    }
    final int offsetPosition = mAdapterHelper.findPositionOffset(position);
    bound = tryBindViewHolderByDeadline(holder, offsetPosition, position, deadlineNs);// 这是唯一的onBindViewHolder会被调用到的地方
}
```
 
 mAttachedScrap是一个ArrayList<ViewHolder>，在RecyclerView的dispatchLayoutStep2中会走到，LayoutManager的onLayoutChildren中会调用
 detachAndScrapAttachedViews(recycler)这个方法，其实就是将当前RecyclerView的所有child从后往前添加到这个mAttachedScrap中。
 onLayoutChildren继续走，调用到fill ->layoutChunk -> addView ->addViewInt -> unScrap -> unScrapView（这个时候就从mAttachedScrap中移除掉刚才加进去的viewHolder）
到这里viewHolder的itemView.getParent = null(而视觉上这个View是明明存在的)

在unScrapView之后，调用
> mChildHelper.attachViewToParent(child, index, child.getLayoutParams(), false)

就是重新调用recyclerView.attachViewToParent()方法，这是一个ViewGroup的方法，这里面调用了addInArray方法。
而attachViewToParent方法会触发requestLayout，在RecyclerView的requestLayout方法中
```java
 @Override
    public void requestLayout() {
        if (mEatRequestLayout == 0 && !mLayoutFrozen) {
            super.requestLayout();//多数情况下，attachViewToParent不会触发这个方法
        } else {
            mLayoutRequestEaten = true;
        }
    }
```


从命名来看，这里存放的是没有被滑出屏幕的View,也就是当前屏幕上正显示着的View。debug来看，也确实如此。


所以直接在tryGetViewHolderForPositionByDeadline中打断点，发现：
>1. 龟速拖动RecylerView的时候，Holder是在getScrapOrHiddenOrCachedHolderForPosition中从mCachedViews中找到的
2. 大概率情况下，从mCachedViews中获取到的viewHolder不会走到上面tryBindViewHolderByDeadline里面，也就是可以直接拿来用的那种。而从viewPool中回收得到的viewHolder都会走onBindViewHolder方法。（不是很确定，打断点几乎都是这种情况）.这么说吧，mCacheViews中拿出来的viewHolder是不需要bind的,recyclerPool里面拿出来的viewHolder是需要重新bind的。
3. 如果想要减少onBindViewHolder的次数的话，可以把mCachedViews的大小设置大一点。这个api应该叫做Recycler.setViewCacheSize()。默认传进去的是2.也就是说RecyclerView顶部和底部默认还藏着一个随时准备被滑动出来的View.每次layoutManager尝试去获取一个View的时候，会更加容易从mCachedViews中获得viewHolder。
4. mCachedViews和recyclerPool中的view.getParent都为Null。
5. onViewDetachedFromWindow时只不过才刚刚加入mCachedViews，onViewRecycled才是view被移动到pool中了(这个时候剔除view的一些资源是完全OK（比如setImageDrawable(null)，比如videoPlayer stop）的，因为下次重新取出来的时候反正又要重新bind一遍).
6. RecylerView的缓存提供了viewCacheExtension这个接口，开发者可以自定义一层View的缓存
7. 准确来讲，缓存一共有四层，mAttachedScrap,mCachedViews,viewCacheExtension还有recyclerPool



package private的变量是否就不能访问到？
比如V7包里的RecyclerView，里面的Recycler是package-private权限。
于是新建一个package android.support.v7.widget这样的包。
接下来在这个包里面的class就能直接访问RecyclerView中的package-private权限的成员变量了。
亲测可行。


### 4 . 一些参考资料
- [RecyclerView Animations and Behind the Scenes (Android Dev Summit 2015)](https://www.youtube.com/watch?v=imsr8NrIAMs)
- [ItemAnimator模板](https://github.com/wasabeef/recyclerview-animators)
- [UI ToolKit Demo](https://github.com/google/android-ui-toolkit-demos)
- [Yigit Boyar: Pro RecyclerView](https://www.youtube.com/watch?v=KhLVD6iiZQs)
