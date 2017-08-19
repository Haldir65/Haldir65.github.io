---
title: 数据结构之-算法手册
date: 2017-08-12 19:04:16
tags: [tools,algorithm]
---


![FlamingFlowers](http://odzl05jxx.bkt.clouddn.com/10013-1109230P20693.jpg?imageView2/2/w/600)
<!--more-->


## 1. 各种Search的原理及java代码实现
java.utils.Arrays这个类中有各种经典的实现，直接对照着学就好了。


### 1.1 BinarySearch
二分法查找，前提是数组中元素全部按照顺序(从小到大或者从大到小)排列好了。Android中SparseArray中用到了binarySearch

android.support.v4.util.ContainerHelpers
```
   // This is Arrays.binarySearch(), but doesn't do any argument validation.
    static int binarySearch(int[] array, int size, int value) {
        int lo = 0;
        int hi = size - 1;

        while (lo <= hi) {
            int mid = (lo + hi) >>> 1;
            int midVal = array[mid];

            if (midVal < value) {
                lo = mid + 1;
            } else if (midVal > value) {
                hi = mid - 1;
            } else {
                return mid;  // value found
            }
        }
        return ~lo;  // value not present（）
    }
```

最后一个用的是位非操作，就是把int(4 bytes)转成2进制所有的0变成1，所有的1变成0.