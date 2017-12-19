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
                          android:duration="@integer/button_pressed_animation_duration"
                          android:valueTo="@dimen/button_pressed_z_material"
                          android:valueType="floatType"/>
          <objectAnimator android:propertyName="elevation"
                          android:duration="0"
                          android:valueTo="@dimen/button_elevation_material"
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
                          android:valueTo="@dimen/button_elevation_material"
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



=============================================================================
### 9. Facebook出品的BUCK能够用于编译Android 项目，速度比较快。

[一个具有网络传输的FileExplorer](https://github.com/1hakr/AnExplorer)
