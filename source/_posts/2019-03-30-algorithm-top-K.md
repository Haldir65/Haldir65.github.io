---
title: 算法-Top-K问题
date: 2019-03-30 22:17:37
tags: [算法]
---

10亿个数中找出最大的10000个数（top K问题）
![](https://www.haldir66.ga/static/imgs/WolfeCreekCrater_ZH-CN10953577427_1920x1080.jpg)

<!--more-->

## 1. 直接排序然后取最大的K个数
总的时间复杂度为O(N*logN)+O(K)=O(N*logN)。该算法存在以下问题：

快速排序的平均复杂度为O(N*logN)，但最坏时间复杂度为O(n2)，不能始终保证较好的复杂度
只需要前k大或k小的数,，实际对其余不需要的数也进行了排序，浪费了大量排序时间

## 2. 利用快速排序的特点
在数组中随机找一个元素key，将数组分成两部分Sa和Sb，其中Sa的元素>=key，Sb的元素<key

若Sa中元素的个数大于或等于k，则在Sa中查找最大的k个数
若Sa中元素的个数小于k，其个数为len，则在Sb中查找k-len个数字
```java
public static int findTopK(int[] array, int left, int right, int k) {
    int index = -1;
    if (left < right) {
        int pos = partition(array, left, right);
        int len = pos - left + 1;
        if (len == k) {
            index = pos;
        } else if (len < k) {//Sa中元素个数小于K，到Sb中查找k-len个数字
            index = findTopK(array, pos + 1, right, k - len);
        } else {//Sa中元素的个数大于或等于k
            index = findTopK(array, left, pos - 1, k);
        }
    }
    return index;
}

/**
 * 按基准点划分数组，左边的元素大于基准点，右边的元素小于基准点
 *
 * @param array
 * @param left
 * @param right
 * @return
 */
public static int partition(int[] array, int left, int right) {
    int x = array[left];//基准点，随机选择
    do {
        while (array[right] < x && left < right)//从后向前扫描，找到第一个比基准点大的元素
            right--;
        if (left < right) {
            array[left] = array[right];//大元素前移
            left++; 
        }
        while (array[left] >= x && left < right) //从前向后扫描，找到第一个比基准点小的元素
            left++;
        if (left < right) {
            array[right] = array[left];//小元素后移
            right--;
        }
    } while (left < right);
    array[left] = x;
    return left;
}
```

## 3. 小顶堆
堆排序在处理海量数据的时候十分有效
查找最大的K个数，其实就是建立一个大小为K的小顶堆，每次出现比顶部大的元素时，替换，并重新调整堆
代码实现如下
下面这个是找出最小的K个元素，并且是构建小顶堆

```java
public static int[] findTopK(int[] array, int k) {
    int heapArray[] = new int[k];
    for (int i = 0; i < k; i++) {
        heapArray[i] = array[i];
    }
    buildMaxHeap(heapArray);
    for (int i = k; i < array.length; i++) {
        if (array[i] < heapArray[0]) {
            heapArray[0] = array[i];//更新堆顶
            adjustMaxHeap(heapArray, 0, heapArray.length);
        }
    }
    return heapArray;
}
/**
 * 构建小顶堆
 *
 * @param array
 */
public static void buildMaxHeap(int[] array) {
    for (int i = array.length / 2 - 1; i >= 0; i--) {
        adjustMaxHeap(array, i, array.length);
    }
}
/**
 * 调整堆结构
 *
 * @param array
 * @param root   根节点
 * @param length
 */
public static void adjustMaxHeap(int[] array, int root, int length) {
    int left = root * 2 + 1; //左节点下标，数组下标从0开始，所以加1
    int right = left + 1; //右节点下标
    int largest = root;// 存放三个节点中最大节点的下标
    if (left < length && array[left] > array[root]) { //左节点大于根节点，更新最大节点的下标
        largest = left;
    }
    if (right < length && array[right] > array[largest]) {//右节点大于根节点，最大节点的下标
        largest = right;
    }
    if (root != largest) {
        swap(array, largest, root);
        adjustMaxHeap(array, largest, length);
    }
}
/**
 * 交换
 *
 * @param arr
 * @param i
 * @param j
 */
public static void swap(int[] arr, int i, int j) {
    int temp = arr[i];
    arr[i] = arr[j];
    arr[j] = temp;
}
```
算法的时间复杂度为O(N * logk)

## 4. 假如数据的最大值和最小值差距不大，都是整数的话，可以考虑申请一个数组，存放每个元素出现的次数，结束后对这个数组从后往前统计，碰到count大于0的说明出现过，统计到了K个就结束
```java
public static List<Integer> findTopK(int[] array, int k) {
    int max = array[0];
    for (int i = 0; i < array.length; i++) {
        if (max < array[i]) {
            max = array[i];
        }
    }
    int count[] = new int[max + 1];
    for (int i = 0; i < array.length; i++) {
        count[array[i]] += 1;
    }
    List<Integer> topKList = new ArrayList<>();
    for (int sumCount = 0, j = count.length - 1; j >= 0; j--) {
        int c = count[j];
        sumCount += c;
        if (c > 0) {
            for (int i = 0; i < c; i++) {
                topKList.add(j);
            }
        }
        if (sumCount >= k) {
            break;
        }

    }
    return topKList;
}
```
该算法还可以用bitmap算法优化，用一个int表示32个整数。