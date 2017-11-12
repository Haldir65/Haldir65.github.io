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

### 1.2 BubbleSort
把较大的元素挪到右边，较小的元素挪到左边。
每次从左到右边，两个两个的比较，大的往右挪，第一次完成后，最大的一个一定已经挪到最后了。接下里对n-1个元素进行同样的操作。
java代码
```java
public static void bubbleSort(int[] numArray) {

    int n = numArray.length;
    int temp = 0;

    for (int i = 0; i < n; i++) {
        for (int j = 1; j < (n - i); j++) {

            if (numArray[j - 1] > numArray[j]) {
                temp = numArray[j - 1];
                numArray[j - 1] = numArray[j];
                numArray[j] = temp;
            }

        }
    }
}
```

the worst case scenario ：array完全倒序 o(n^2)
the best case scenario : array已经排序好 Ω（n）


### 1.3 Insertion Sort
基本上就是把一个数组从左到右迭代，第一遍声明第一个元素是sorted，第二遍看下第二个和第一个是不是有序的，第二遍完成后第二个元素是sorted。第三遍把前三个排序好。
下面这段代码是从[华盛顿大学教程](https://courses.cs.washington.edu/courses/cse373/02wi/slides/Measurement/sld010.htm)抄的，应该没问题。
```java
public static void insertionSort(int[] a){
    for (int i=1;i<a.length;i++){
        int temp = a[i];
        int j;
        for(j=i-1;j>=0&&temp<a[j];j--)
            a[j+1] = a[j]
        a[j+1] = temp;

    }
}
```
核心算法就是第N此排序完成后，前N个元素已经排序完毕。

the worst case scenario ：array完全倒序 o(n^2)
the best case scenario : array已经排序好 Ω（n）


### 1.4 Merge Sort
这个算法比较复杂，一图胜千言
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/merge_sort.png)
[参考](http://www.java2novice.com/java-sorting-algorithms/merge-sort/)
其实就是把array打成一半一半，直到变成多个大小为2的数组，然后再合并起来。java代码直接复制粘贴了，保留包名是对作者的尊重：
```java
package com.java2novice.sorting;

public class MyMergeSort {

    private int[] array;
    private int[] tempMergArr;
    private int length;

    public static void main(String a[]){

        int[] inputArr = {45,23,11,89,77,98,4,28,65,43};
        MyMergeSort mms = new MyMergeSort();
        mms.sort(inputArr);
        for(int i:inputArr){
            System.out.print(i);
            System.out.print(" ");
        }
    }

    public void sort(int inputArr[]) {
        this.array = inputArr;
        this.length = inputArr.length;
        this.tempMergArr = new int[length];
        doMergeSort(0, length - 1);
    }

    private void doMergeSort(int lowerIndex, int higherIndex) {

        if (lowerIndex < higherIndex) {
            int middle = lowerIndex + (higherIndex - lowerIndex) / 2;
            // Below step sorts the left side of the array
            doMergeSort(lowerIndex, middle);
            // Below step sorts the right side of the array
            doMergeSort(middle + 1, higherIndex);
            // Now merge both sides
            mergeParts(lowerIndex, middle, higherIndex);
        }
    }

    private void mergeParts(int lowerIndex, int middle, int higherIndex) {

        for (int i = lowerIndex; i <= higherIndex; i++) {
            tempMergArr[i] = array[i];
        }
        int i = lowerIndex;
        int j = middle + 1;
        int k = lowerIndex;
        while (i <= middle && j <= higherIndex) {
            if (tempMergArr[i] <= tempMergArr[j]) {
                array[k] = tempMergArr[i];
                i++;
            } else {
                array[k] = tempMergArr[j];
                j++;
            }
            k++;
        }
        while (i <= middle) {
            array[k] = tempMergArr[i];
            k++;
            i++;
        }

    }
}
```
[看视频比较方便](https://www.youtube.com/watch?v=sWtYJv_YXbo)

### 1.5 Selection Sort
每次把数组里面最小的元素挪到最左边,图片是从[这里](http://www.java2novice.com/java-sorting-algorithms/selection-sort/)抄的
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/selectionsort.jpg)
java代码也是抄的
```java
package com.java2novice.algos;

public class MySelectionSort {

    public static int[] doSelectionSort(int[] arr){

        for (int i = 0; i < arr.length - 1; i++)
        {
            int index = i;
            for (int j = i + 1; j < arr.length; j++)
                if (arr[j] < arr[index])
                    index = j;

            int smallerNumber = arr[index];  
            arr[index] = arr[i];
            arr[i] = smallerNumber;
        }
        return arr;
    }

    public static void main(String a[]){

        int[] arr1 = {10,34,2,56,7,67,88,42};
        int[] arr2 = doSelectionSort(arr1);
        for(int i:arr2){
            System.out.print(i);
            System.out.print(", ");
        }
    }
}
```
注意，每次遍历都都会意味着数组分为有序和无序两部分，遍历是从无序的数组第一个开始的，并且将无序数组中的最小值与无序数组第一个元素swap一下。
就是很直观的每次把最小的拿到最左边的做法。

### 1.6 Quicksort
一种比较快速的排序方法
[视频](https://www.youtube.com/watch?v=aQiWF4E8flQ)
选中数组最后一个元素，称之为pivot。然后从左到右找，把所有小于pivot的元素挪到左边。然后把pivot挪到刚才那个元素右边，一直重复下去。

### 1.7 TimSort
java的Collections.sort的算法，
[Comparison Method Violates Its General Contract!]((https://www.youtube.com/watch?v=bvnmbRo7a1Y))
