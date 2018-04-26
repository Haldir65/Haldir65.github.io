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
![](http://odzl05jxx.bkt.clouddn.com/snapshot20161020135353.jpg?imageView2/2/w/600)
ChildHelper 、AdapterHelper 、Recycler对于开发者来说并不常用，但它们在内部负责了许多针对Child View的管理。<!--more-->


- ViewHolder的创建
![](http://odzl05jxx.bkt.clouddn.com/viewHolder_step_1.jpg?imageView2/2/w/600)
1 .LayoutManager首先检查getViewForPosition，RecyclerView查找Cache(getViewForPosition)，如果找到了。直接交给LayoutManager,这一过程甚至不需要与Adapter接触。
2. 如果Cache中未找到，RecyclerView调用Adpter的getViewType，并去Recycled Pool中getViewHolderByType。
3. 如果在Pool中未找到，RecyclerView将调用Adapter的createViewHolder。
4. 如果在Pool中这种Type的ViewHolder已经有了，或者步骤3中创建了一个新的viewHolder，bindViewHolder并交给LayoutManager。
![](http://odzl05jxx.bkt.clouddn.com/viewHolder_step_2.jpg?imageView2/2/w/600)
5. 最终LayoutManager将把这个View添加到UI，这时会调用RecyclerView的onViewAttachedToWindow回调（生命周期）。


- ViewHolder的回收(Reserves)
![](http://odzl05jxx.bkt.clouddn.com/viewHolder_step_3.jpg?imageView2/2/w/600)
1. LayoutManager调用removeAndRecycleView，RecyclerView会在这里收到回调onViewDetachedFromWindow
2. 检查这个View.isValid。这一点很重要，在scroll过程中，如果一个View是Valid的话，可以将View添加到Cache中，随后可以简单将其复用。Cache将会invalidate oldest one，并告诉Adapter(onViewRecycled)。
3. 如果不是Valid的View，将会被添加到Pool中，Adapter会收到onViewRecycled回调。

- ViewHolder的另一种更好的回收方式(Fancy Reserves!)
![](http://odzl05jxx.bkt.clouddn.com/snapshot20161020124442.jpg?imageView2/2/w/600)
1. LayoutManager调用onLayoutChildren
2. Layout完成后，RecyclerView检查那些之前已经被layout了的但不再存在于屏幕上了。RecyclerView将这些View重新添加到ViewGroup中，这些View此时对LayoutManager不可见。重新添加的目的在于动画。
3. RecyclerView这时候把这些本不该add的View交给ItemAnimator，后者调用动画效果，300ms(安卓中大部分默认动画时间是300ms)之后，调用onAnimationFinished，告诉RecyclerView.
4. 接着RecyclerView通知Adapter(onViewDetachedFromWindow)
5. 最后将这些View添加到Cache或者Recycled Pool。

- ViewHolder的销毁
![](http://odzl05jxx.bkt.clouddn.com/snapshot20161020124836.jpg?imageView2/2/w/600)
1. LayoutManager调用removeAndRecycleView，RecyclerView检查View是否valid
2. 如果不是Valid，添加到RecycledPool中，但在这之前先检查是否 hasTransientState（例如正在运行动画）
3. 如果这个View正好处在Animation中，一些属性被Animating， Pool会调用Adapter的onFailedToRecycle(Adapter中应该复写这个方法，取消动画)
4. onFailedToRecycle(ViewHolder)返回true的话，Pool将无视View的TransientState并回收这个View(可能处在动画中)

- 另一种可能导致ViewHolder被销毁的方式
![](http://odzl05jxx.bkt.clouddn.com/snapshot20161020143554.jpg?imageView2/2/w/600)
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



## 更新
RecylerView的缓存提供了viewCacheExtension这个接口，开发者可以自定义一层View的缓存

### 4 . 一些参考资料
- [RecyclerView Animations and Behind the Scenes (Android Dev Summit 2015)](https://www.youtube.com/watch?v=imsr8NrIAMs)
- [ItemAnimator模板](https://github.com/wasabeef/recyclerview-animators)
- [UI ToolKit Demo](https://github.com/google/android-ui-toolkit-demos)
- [Yigit Boyar: Pro RecyclerView](https://www.youtube.com/watch?v=KhLVD6iiZQs)
