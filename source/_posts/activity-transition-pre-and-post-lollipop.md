---
title: activity transition pre and post lollipop
date: 2016-09-27 14:53:25
categories: [技术]
tags: [transition,android]
---

Lollipop开始引入了新的Activity Transition动画效果，比起常用的overridePendingTransaction() 效果要强大许多

测试环境
supportLibVersion = "24.2.1"
gradle plugin version : "classpath 'com.android.tools.build:gradle:2.2.0'"
gradle version : 3.1
compileSdkVersion 24
buildToolsVersion "24.0.2"

<!--more-->

- 常规用法:

A activity >>>> B activity

A activity中:

```java
 intent = new Intent(getActivity(), PictureDetailSubActivity2.class);
                intent.putExtra(EXTRA_IMAGE_URL, R.drawable.b2);
                intent.putExtra(EXTRA_IMAGE_TITLE, "使用ActivityCompat动画");
                ActivityOptionsCompat optionsCompat = ActivityOptionsCompat.
                        makeSceneTransitionAnimation(getActivity(), view, TRANSIT_PIC);
                try {
                    ActivityCompat.startActivity(getActivity(), intent, optionsCompat.toBundle()); //据说部分三星手机上会失效
                } catch (Exception e) {
                    e.printStackTrace();
                    ToastUtils.showTextShort(getActivity(), "ActivityCompat出错！！");
                    startActivity(intent);
                }
```

Pair这个class是v4包里的一个Util类，用来装载一组(pair)对象，支持泛型，很好用。由于都是v4包里的方法，省去了做API版本判断，在API 16以下，就只会调用普通的startActivity方法。上面加了try catch是避免部分手机上出现问题

B activity中onCreate调用

```java
 ViewCompat.setTransitionName(binding.imageDetail, TRANSIT_PIC);
```

就可实现普通的转场动画。

- 兼容方式(将连续的Transition带到API16以下)

  主要的原理: 在A activity中记录要带到B activity中的View的当前位置，在B activity中添加onPredrawListener(measure完毕，layout完毕，即将开始Draw的时候)，此时开始进行动画，将SharedView从原位置animate到B Activty中的位置

  原理及详细代码在这里:

   [Dev Bytes Activity Animations Youtube](https://www.youtube.com/watch?v=CPxkoe2MraA) 我照着写了一些关于Activity Transition的模板，[gitHub](https://github.com/Haldir65/CustomActivityTransition) 基本能实现兼容到API 16以下的效果

- 最后是这几天遇到的天坑

```java
@Override
public void onCreate(Bundle savedInstanceState, PersistableBundle persistentState) {
    super.onCreate(savedInstanceState, persistentState);
}
```

这样的Activity绝对会出ClassNotFoundException , 而且并不会主动出现在logcat中

- overridePendingTransaction要在startActivity以及finish之后才能调用



gitHub上有一个比较好的[兼容库](https://github.com/takahirom/PreLollipopTransition)，大致原理也是使用onPreDrawListener



