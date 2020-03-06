---
title: TextView测量及渲染原理
date: 2018-11-29 16:11:54
tags: [android,tbd]
---

Android上的TextView分为java层和native层，java层包括
Layout,Paint,Canvas
native层包括各种开源库，Minikin,ICU,HarfBuzz,FreeType
关于文字的形体,排版等信息是native层计算出来的。

![](https://api1.foster66.xyz/static/imgs/textview_architecture.png)

<!--more-->

[tbd]

TextView是一个很重的控件，由于measure耗时通常很多，Android P提出了Precomputed Text的概念。类似的概念早几年instagram也提出过（如果只是想要展示一段文字，在一个子线程用Layout去计算。
我碰到的情况是：
layout.getDesiredwidth("一个字") > layout.getDesiredwidth("一") + layout.getDesiredwidth(“个”)+ layout.getDesiredwidth(“字”)。
多数情况下，左边的值和右边的width之和是相等的，但是出现中英文夹杂的时候左边会小于右边。不清楚这是否是提前换行的原因。

Layout有BoringLayout(一行文字),StaticLayout(多行文字)和DynamicLayout(文字会变)这三个子类


在某些版本的Android上，TextView碰到中英文夹杂的时候，会出现提前换行(普遍的看法是Layout这个类里面处理全角符号的时候算错了)


ActivityThread里面有一个freeTextLayoutCachesIfNeeded方法
```java
    static void freeTextLayoutCachesIfNeeded(int configDiff) {
        if (configDiff != 0) {
            // Ask text layout engine to free its caches if there is a locale change
            boolean hasLocaleConfigChange = ((configDiff & ActivityInfo.CONFIG_LOCALE) != 0);
            if (hasLocaleConfigChange) {
                Canvas.freeTextLayoutCaches();
                if (DEBUG_CONFIGURATION) Slog.v(TAG, "Cleared TextLayout Caches");
            }
        }
    }
```

## 参考
[Textview的高度ascent,descent这些的详细解说](https://stackoverflow.com/questions/27631736/meaning-of-top-ascent-baseline-descent-bottom-and-leading-in-androids-font)
[TextView预渲染研究](http://ragnraok.github.io/textview-pre-render-research.html)
[instagram的文章](https://instagram-engineering.com/improving-comment-rendering-on-android-a77d5db3d82e)
[Best practices for text on Android (Google I/O '18)](https://www.youtube.com/watch?v=x-FcOX6ErdI)
[Use Android Text Like a Pro (Android Dev Summit '18)](https://www.youtube.com/watch?v=vXqwRhjd7b4)