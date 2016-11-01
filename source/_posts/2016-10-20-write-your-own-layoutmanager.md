---
title: 自定义LayoutManager
date: 2016-10-20 16:37:42
tags:
---

### 1. 系统为我们提供了LinearLayoutManager、GridLayoutManager和StaggeredGridLayoutManager。
基本用法都很简单，这里记录一些重要的用法

![](http://odzl05jxx.bkt.clouddn.com/Googling%20the%20Error%20Message.jpg?imageView2/2/w/600)
<!--more-->

- GridLayoutManager可以设置某个Item在某一行占据的Column num（VERTICAL的情况下）
代码如下:
```java
GridLayoutManager manager = new GridLayoutManager(
   this,2 ,GridLayoutManager.VERTICAL,false)
   
manager.setSpanSizeLookup(){
        new GridLayoutManager.SpanSizeLookup(){
        @override
        public int getSpanSize(int position){
                return (position % 3 == 0 ? 2 : 1)
            }
        }
    }   
```
所以，一开始可以把这个2设置大一点，后面可以动态设置，看上去就会造成一种多种格子的错觉。

- GridLayoutManger的同一行的ItemView的itemHeight必须一致，否则同一行的ItemView底部会出现空隙。这种情况请使用StaggeredGridLayoutManager

#### 2. LayoutManager <-------> Recycler <--------> Adapter
LayoutManager永远永远永远不要碰Adapter!!!

### 3.Recycler构造
Recycler内部有两个集合:
1. Scrap Heap ： detachAndScrapView() 暂时不用的View丢到这里，随时取回使用
2. Recycle Pool: removeAndRecycleView() 确定不需要的View丢到这里，拿回来时position或者data变了

### 4.FillGaps,最重要的方法
1. Discover firstVisible position/location
2. 找到layout Gaps
```java
findFirstVisiblePosition
```

3. Scrap everything(丢到ScrapHeap)
```java
 /**
         * Temporarily detach and scrap all currently attached child views. Views will be scrapped
         * into the given Recycler. The Recycler may prefer to reuse scrap views before
         * other views that were previously recycled.
         *
         * @param recycler Recycler to scrap views into
         */
        public void detachAndScrapAttachedViews(Recycler recycler) {
            final int childCount = getChildCount();
            for (int i = childCount - 1; i >= 0; i--) {
                final View v = getChildAt(i);
                scrapOrRecycleView(recycler, i, v);
            }
        }
```
4. Lay out all visible positions

```java
for(...){
    int nextPosition = ...;
    View view = recycler.getViewForPosition(nextPosition);
    addView(view);
    
    //注意这里的Measure和Layout不是平时使用的measureChild和layout方法，原因是ItemDecoration
    measureChildWithMargin(view,...) 
    layoutDecorated(view,....)
    }
```
5. Recycle remaining views
```java
final List<RecyclerView.ViewHolder> scrapList =
    recycler.getScrapList();
for(int i=0;i<scrapList.size;i++){
    final View removingView = scrapList.get(i);
    recycler.recycleView(removingView);
    }    
```

注意: 丢到RecyclerPool的View的viewHolder、LayoutParams都被清除掉


### 4. Scroll事件
```java
   public int scrollHorizontallyBy(int dx, RecyclerView.Recycler recycler, RecyclerView.State state) {
   
   //dx 表示系统根据传入的TouchEvent告诉你应该滑动多少
   dx <0 内容向右滑动
   dx > 0内容向左滑动
   //这个正负号和ScrollBy那个是一样的邪门
   //返回值是你告诉系统你实际滑动了多少
   offsetChildrenHorizontal(delta);//调用该方法会帮助你移动所有的ChildView，比一个个Iterate方便多了
   }
```
### 5.notifyDataSetChanged()调用了什么函数
最终会走到onLayoutChildren这里面，就跟重新走一遍layout就可以了

### 6.ScrollToPosition()和SmoothScrollToPosition()
两者的实现的不同:
scrollToPosition:Track Requested Position、Trigger requestLayout
SmoothscrollToPosition: Create a SmoothScroller instance、Set the Target Position、invoke startSmoothScroll
SmoothScroller是一个接口，在里面实现computeScrollVectorForPosition返回需要到达的位置

### 7. supportPredictiveItemAnimation主要用于ItemChange Animation
主要在发生变化时展示动画。如果想要在滑动过程中展示动画的话，可以考虑在onViewAttachedToWindow或者onBindViewHolder里面给View添加TranslationX（从左边出来），Alpha(透明度从0变成1)，或者ScaleX等等



### Reference
1. [Dave Smith](https://github.com/devunwired/recyclerview-playground)
2. [500px](https://github.com/500px/greedo-layout-for-android.git)