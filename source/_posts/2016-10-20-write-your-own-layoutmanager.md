---
title: 自定义LayoutManager
date: 2016-10-20 16:37:42
categories: blog  
tags: [android]
---

### 1. 系统为我们提供了LinearLayoutManager、GridLayoutManager和StaggeredGridLayoutManager。
基本用法都很简单，这里记录一些重要的用法

![](https://www.haldir66.ga/static/imgs/Googling-the-Error-Message.jpg)
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
    );  
```
所以，一开始可以把这个2设置大一点，后面可以动态设置，看上去就会造成一种多种格子的错觉。

- GridLayoutManger的同一行的ItemView的itemHeight必须一致，否则同一行的ItemView底部会出现空隙。这种情况请使用StaggeredGridLayoutManager


## 坑
### 坑1
场景: 
一个column为4的gridLayoutManager，position为0和position为3的item的左右边距是20dp。其余每一个item之间的间隔为10dp，手机屏幕宽度为720px

于是尝试着这样写
```js
val offset = 10
when (position%4) {
                0 -> outRect?.set(offset*2, 0, 0, 0)
                1 -> outRect?.set(offset, 0, 0, 0)
                2 -> outRect?.set(offset, 0, 0, 0)
                3 -> outRect?.set(offset, 0, offset*2, 0)
}
```
没有用，
1. 强制在onCreateViewHodler中修改宽度为 (screenWidth- 20*2 - 10*3)/4f  依旧没有用
2. 将itemView的宽度设置为Match_Parent之后，到最后的一个View的宽度要小于实际的宽度 依旧没有用

结论似乎是GridLayoutManager不应该手动指定itemView的宽度，如果想要宽度一致，但是之间的gap又不相等。那么最好也是最简单的方法是在RecyclerView上下手，让getItemItemOffset中返回一个一致的rect宽度

GridLayoutManager 在指定了Column count之后，系统会自动根据当前宽度(比方说屏幕宽度)去除以columnCount计算实际item的宽度。添加了itemDecoration,并且在getItemOffset中设置了outRect的宽度之后，child的宽度计算结果就变得奇怪了。似乎是每一个child在getItemOffset中设置的左右宽度被被加权到最终宽度的计算中了。
我尝试手动精确计算每一个child在扣除了所有中间的gap之后的宽度，强制设置宽度为一致。最终得到的view的宽度是对的，但是left和right总是偏移了。

最终改成了这样才达到预期的效果
```js
recyclerView.layoutParms?.run {
    leftMargin = 15dp
    rightMargin = 15dp 
}
val offset = 10dp
when (position%4) {
                0 -> outRect?.set(offset/2, 0, offset/2, 0)
                1 -> outRect?.set(offset/2, 0, offset/2, 0)
                2 -> outRect?.set(offset/2, 0, offset/2, 0)
                3 -> outRect?.set(offset/2, 0, offset/2, 0)
}
```
RecyclerView的左右各使用15dp的边距，这样剩下的每一个横排的itemView，outRect的左右都需要设置为5dp。从而实现itemView宽度一致，gap大小不一致的效果。

### 坑2
Recylerview会在某一个child requestFocus之后莫名其妙的滑动一段距离
[onRequestChildFocus](https://developer.android.com/reference/android/support/v7/widget/RecyclerView.LayoutManager.html#onrequestchildfocus_1) 我理解这样的本意是用于chat这样的场景，自动focus到新的itemView上，解决方案是在onRequestChildFocus中返回true，这样就不会莫名其妙的滑动了
[recyclerView奇怪的滑动](https://stackoverflow.com/questions/45458054/why-does-recyclerview-scroll-to-top-of-view-when-view-is-focused)
我也是把断点打在canScrollVertically上才发现的


### 2. LayoutManager <-------> Recycler <--------> Adapter
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

这篇文章最初是打算翻译Dave Smith的一次演讲的，后面决定加上StaggeredGridLayoutManger的原理解析



### Reference
1. [Dave Smith](https://github.com/devunwired/recyclerview-playground)
2. [500px](https://github.com/500px/greedo-layout-for-android.git)
