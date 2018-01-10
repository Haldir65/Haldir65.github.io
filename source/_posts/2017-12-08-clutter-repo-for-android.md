---
title: Android知识集合[三]
date: 2017-12-08 22:33:26
tags: [android,tools]
---

之前的文章快装不下了，所以另外开一篇文章专门放Android相关的杂乱的知识点。
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/scenery1511100734648.jpg?imageView2/2/w/600)
<!--more-->


[Android Source code](https://android-review.googlesource.com)，能够实时看到提交信息
[From View to Pixel](https://www.youtube.com/watch?v=CMzCccqE_R0)讲了ViewRootImpl,SurfaceFlinger这些东西
[一个很长的关于显示原理的文章](https://juejin.im/post/5a1e8d5ef265da431280ae19)，基本上什么都讲了



### 1.基本上所有的Android System Event都是从ActivityThread中发起的
onDetachedFromWindow是从ActivityThread的handleDestoryActivity传下来的，走到windowManager.removeViewImediate,然后ViewRootImpl.doDie,然后ViewRootImpl.dispatchDetachedFromWindow，然后DecoreView.dispatchDetachedFromWindow，然后一个个child传下去。所有的View走完了之后，DecorView在onDetachedFromWindow中以Window.Callback的方式顺手通知了Activity的onDetachedFromWindow。其实打个断点看的话就快一点。

### 2. onSaveInstance对于有id的View，系统会自动帮忙存一点东西
当然onSaveInstance也是从ActivityThread里面传递下来的。还有就是onCreate(Bundle)和onRestroreSaveInstanceState(Bundle)里面的bundle是同一个object。romain Guy说最初onSaveInstance和onRestroreSaveInstanceState本来叫onIcy(冻结)和onThaw（解冻），确实很形象。
其实这个到现在还有一些痕迹:
ViewGroup.java
```java
protected void dispatchFreezeSelfOnly(SparseArray<Parcelable> container) {
     super.dispatchSaveInstanceState(container);
 }

 protected void dispatchThawSelfOnly(SparseArray<Parcelable> container) {
     super.dispatchRestoreInstanceState(container);
 }
```

### 3.android asset atlas
就是为了节省asset耗费的内存，将一些系统公用的资源作为一个服务先跑起来，所有app的process共用这部分资源。

### 4. ZygoteInit


### 5. Michael Bailey每年的演讲都很精彩
[Droidcon NYC 2015 - How the Main Thread works](https://www.youtube.com/watch?v=eAtMon8ndfk)
[Droidcon NYC 2016 - How LayoutInflater works](https://www.youtube.com/watch?v=Y06wmVIFlsw)
[droidcon NYC 2017 - How Espresso Works](https://www.youtube.com/watch?v=7lCsp84wVPM)

2016年的演讲中提到了LayoutInflater中的好玩的注释
LayoutInflater.java
```java
if (name.equals(TAG_1995)) {
            // Let's party like it's 1995!
            return new BlinkLayout(context, attrs);
        }
```

### 6. Chris Banes在2017年给出了关于状态栏的解释
[droidcon NYC 2017 - Becoming a master window fitter](https://www.youtube.com/watch?v=_mGDMVRO3iE)

### 7. Android默认的launcher的repo在
[Launcher3](https://android.googlesource.com/platform/packages/apps/Launcher3/),应该是属于System UI Team在维护。
todo 那个点击了icon进应用的点击事件在哪里。大致是在Launcher.java这个文件的startActivitySafely里面

### 8. 在string.xml里面放一些format的字符

```java
public static void main(String[] args) {
   String s1 = "这里面可以放多个字符串%1$s,%2$s前面加上一个百分号和数字，代表顺序";
   String s2 = "百分号的d和百分号的s可以混着%1$s用的，比如这个%2$d数字什么的，第三个是带百分号的数字%3$d%%这个由于需要显示百分号，所以加上两个百分号";

   System.out.println(String.format(s1,"XXXX","XXX"));
   System.out.println(String.format(s2,"XXX", 100, 100));
}
```
实际输出
> 这里面可以放多个字符串XXXX,XXX前面加上一个百分号和数字，代表顺序
百分号的d和百分号的s可以混着XXX用的，比如这个100数字什么的，第三个是带百分号的数字100%这个由于需要显示百分号，所以加上两个百分号

### 9.我记得Chet Haase说过Lollipop及以上的Button默认是有一个elevation的
记得Chet在一次演讲中说到Appcompat在5.0以上默认使用material Theme, Button的默认elevation好像是3dp。日常开发中也经常会看见button和设置elevation=0的button相比确实有些阴影。在Button的构造函数里面打了断点，在setElevation也打了断点，最后发现是在View创建之后Choregrapher在doFrame的时候run了一个Animation，在这个animation中设置了一个6px的elevation(2dp，原来Chet记错了)。
至于这个2dp是那来的呢：
```xml
<Button
    ...

    android:stateListAnimator="@null" />

    <Button
    ...

    android:stateListAnimator="@anim/my_animator" />
```
最终在网上[找到了](http://www.itmmd.com/201412/240.html)
core/res/res/anim/button_state_list_anim_material.xml
```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Copyright (C) 2014 The Android Open Source Project
   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at
        http://www.apache.org/licenses/LICENSE-2.0
   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
-->
<selector xmlns:android="http://schemas.android.com/apk/res/android">
  <item android:state_pressed="true" android:state_enabled="true">
      <set>
          <objectAnimator android:propertyName="translationZ"
                          android:duration="@integer/button_pressed_animation_duration" 100ms
                          android:valueTo="@dimen/button_pressed_z_material" ## 4dp 其实稍微注意下，手指按住一个Button的时候，Button底部的阴影会扩大，就是这个4dp的属性动画在跑
                          android:valueType="floatType"/>
          <objectAnimator android:propertyName="elevation"
                          android:duration="0"
                          android:valueTo="@dimen/button_elevation_material" ## 2dp
                          android:valueType="floatType"/>
      </set>
  </item>
  <!-- base state -->
  <item android:state_enabled="true">
      <set>
          <objectAnimator android:propertyName="translationZ"
                          android:duration="@integer/button_pressed_animation_duration"  ##100ms
                          android:valueTo="0"
                          android:startDelay="@integer/button_pressed_animation_delay" ## 100ms
                          android:valueType="floatType"/>
          <objectAnimator android:propertyName="elevation"
                          android:duration="0"
                          android:valueTo="@dimen/button_elevation_material" ## 2dp
                          android:valueType="floatType" />
      </set>
  </item>
  <item>
      <set>
          <objectAnimator android:propertyName="translationZ"
                          android:duration="0"
                          android:valueTo="0"
                          android:valueType="floatType"/>
          <objectAnimator android:propertyName="elevation"
                          android:duration="0"
                          android:valueTo="0"
                          android:valueType="floatType"/>
      </set>
  </item>
</selector>
```
注意那个button_elevation_material：
在[aosp](https://android.googlesource.com/platform/frameworks/base/+/master/core/res/res/values/dimens_material.xml)中
```xml
<!-- Elevation when button is pressed -->
    <dimen name="button_elevation_material">2dp</dimen>
    <!-- Z translation to apply when button is pressed -->
    <dimen name="button_pressed_z_material">4dp</dimen>
```
***所以Lollipop上使用Appcompat主题，什么都不改，button默认是会有2dp的elevation的***
至于这个elevation为什么不是在初始化的时候就设置的（打断点的时候走完构造函数,getElevation还是0），就在于这上面这个AnimationDelay(其实是100ms之后再去运行这个动画)，从堆栈来看，最终导致调用setElevation的地方是在drawableStateChange这个方法里面。

### 10. 内网传输功能的原理
有些App提供局域网内无限传输文件的能力：本质上是用了TCP或者UDP。在java层的话，TCP用的是java.net.Socket，UDP用的是java.net.DatagramSocket。由于数据传输是双向的，客户端和Server端都需要创建这样的Object Instance。
[一个比较好的Demo](https://github.com/xanarry/LanTrans-android)
Unix的输入输出(IO)系统遵循Open-Read-Write-Close这样的操作范本。


### 11.v7包里面的Toolbar只是一个自定义View
随便举一个例子，右上角的optionMenu点击跳出的弹窗里面其实是一个ListView，具体的class是android.support.v7.view.menu.ListMenuItemView。都是很常规的自定义View的做法，这个ListView的Adapter叫做MenuAdapter，这个Adapter的itemLayout布局文件叫做abc_popup_menu_item_layout.xml
abc_popup_menu_item_layout.xml
```xml
<android.support.v7.internal.view.menu.ListMenuItemView
        xmlns:android="http://schemas.android.com/apk/res/android"
        android:layout_width="fill_parent"
        android:layout_height="?attr/dropdownListPreferredItemHeight"
        android:minWidth="196dip"
        android:paddingRight="16dip">

    <!-- Icon will be inserted here. -->

    <!-- The title and summary have some gap between them, and this 'group' should be centered vertically. -->
    <RelativeLayout
            android:layout_width="0dip"
            android:layout_weight="1"
            android:layout_height="wrap_content"
            android:layout_gravity="center_vertical"
            android:layout_marginLeft="16dip"
            android:duplicateParentState="true">

        <TextView
                android:id="@+id/title"
                android:layout_width="fill_parent"
                android:layout_height="wrap_content"
                android:layout_alignParentTop="true"
                android:layout_alignParentLeft="true"
                android:textAppearance="?attr/textAppearanceLargePopupMenu"
                android:singleLine="true"
                android:duplicateParentState="true"
                android:ellipsize="marquee"
                android:fadingEdge="horizontal"/>

        <TextView
                android:id="@+id/shortcut"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:layout_below="@id/title"
                android:layout_alignParentLeft="true"
                android:textAppearance="?attr/textAppearanceSmallPopupMenu"
                android:singleLine="true"
                android:duplicateParentState="true"/>

    </RelativeLayout>

    <!-- Checkbox, and/or radio button will be inserted here. -->

</android.support.v7.internal.view.menu.ListMenuItemView>
```
一般来讲，MenuItem的字体大小，颜色都是需要在theme中写的。所以照说硬要用findViewById(ViewGroup的findViewTraversal)其实是能找到的。

### 12. Message.ontain以及相似的场景
MotionEvent.ontain()，TouchTarget.ontain(),HoverTarget.ontain()....
MotionEvent最多缓存10个，TouchTarget和HoverTarget这些都是在看ViewGroup源码的时候瞅到的，简单点。
稍微看下就知道这种ontain,recycle写法的套路。
```java
private static final class TouchTarget {
      private static final int MAX_RECYCLED = 32;
      private static final Object sRecycleLock = new Object[0];
      private static TouchTarget sRecycleBin;
      private static int sRecycledCount;

      public static final int ALL_POINTER_IDS = -1; // all ones

      // The touched child view.
      public View child;

      // The combined bit mask of pointer ids for all pointers captured by the target.
      public int pointerIdBits;

      // The next target in the target list.
      public TouchTarget next;

      private TouchTarget() {
      }

      public static TouchTarget obtain(@NonNull View child, int pointerIdBits) {
          if (child == null) {
              throw new IllegalArgumentException("child must be non-null");
          }

          final TouchTarget target;
          synchronized (sRecycleLock) {
              if (sRecycleBin == null) {
                  target = new TouchTarget();
              } else {
                  target = sRecycleBin;
                  sRecycleBin = target.next;
                   sRecycledCount--;
                  target.next = null;
              }
          }
          target.child = child;
          target.pointerIdBits = pointerIdBits;
          return target;
      }

      public void recycle() {
          if (child == null) {
              throw new IllegalStateException("already recycled once");
          }

          synchronized (sRecycleLock) {
              if (sRecycledCount < MAX_RECYCLED) {
                  next = sRecycleBin;
                  sRecycleBin = this;
                  sRecycledCount += 1;
              } else {
                  next = null;
              }
              child = null;
          }
      }
  }
```


### 13. 从点击Launcher到应用启动的过程
> 借助binder驱动
ActivityManagerService.startActivity-> (AMS)  
...
//一系类AMS的调用链和一些与Launcher通过Binder的互相调用过程，此时仍然未创建应用程序的进程。
...
 AMS创建一个新的进程，用来启动一个ActivityThread实例，
 即将要启动的Activity就是在这个ActivityThread实例中运行
Process.start("android.app.ActivityThread",...)->    
// 通过zygote机制创建一个新的进程    
Process.startViaZygote->调用新进程的main()
ActivityThread.main->

[Android 应用点击图标到Activity界面显示的过程分析](https://juejin.im/entry/5a0d02086fb9a045263b2387)

### 14. Context是什么
ActivityThread.java  
```java
createBaseContextForActivity{
  ContextImpl appContext = ContextImpl.createActivityContext(
                 this, r.packageInfo, r.activityInfo, r.token, displayId, r.overrideConfig);
}
```
ContextImpl包含资源信息、对Context的一些函数的实现等。每次创建Activity都会新建一个ContextImpl


### 15. Dex file explained
[The Dex File Format](https://blog.bugsnag.com/dex-and-d8/)


### 16 .PackageParser和Android.manifest文件有关
[Android APK应用安装原理(1)-解析AndroidManifest原理-](http://blog.csdn.net/zhbinary/article/details/7353739).

### 17. 在Dialog中getContext获取的是ContextThemeWrapper
ContextThemeWrapper是API 1就有了的，主要是包装一下context，将Context的外部调用添加一些包装。

### 18. 低版本的xml属性怎么写
mylayout.xml
```xml
<Button
       android:layout_width="wrap_content"
       android:layout_height="wrap_content"
       android:elevation="10dp"
       />
```
这样写的话，Lint肯定会报warning。
解决办法，alt+enter，Android studio自动生成一个/layout-v21/maylayout.xml。现在想起来很多项目里v-xx文件夹，其实是这个意思。
还有一种写法
> style="?android:attr/borderlessButtonStyle"
自己写style也是行的

### 19. LocalBroadCastManager<del>好像</del>确实是基于handler实现的
App内部全局拥有一个LocalBroadCastManager实例，内部持有一个handler，对外暴露功能sendBroadcast。就是往handler里丢一个message MSG_EXEC_PENDING_BROADCASTS，处理这个message就是executePendingBroadcasts。所以默认是在下一个message中处理的。如果想在当前message中就处理掉，还有一个sendBroadcastSync方法，但这会把当前持有的所有待处理消息全部flush掉。sendBroadcast，unregisterReceiver，registerReceiver内部用了synchronize，所以是线程安全的。




=============================================================================
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/scenery1511100809920.jpg?imageView2/2/w/600)


### 9. Facebook出品的BUCK能够用于编译Android 项目，速度比较快。

[一个具有网络传输的FileExplorer](https://github.com/1hakr/AnExplorer)
[MultiDex原理](http://mouxuejie.com/blog/2016-06-11/multidex-source-analysis/)
[偏向native层面的内存占用分析](http://wetest.qq.com/lab/view/359.html)
