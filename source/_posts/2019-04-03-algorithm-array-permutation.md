---
title: 算法-数组全排列
date: 2019-04-03 13:44:25
tags: [算法]
---

问题描述
<!--more-->

全排列表示把集合中元素的所有按照一定的顺序排列起来，使用P(n, n) = n!表示n个元素全排列的个数。P(n, n)中的第一个n表示元素的个数，第二个n表示取多少个元素进行排列。
比方说[1,2,3]这个数组，全排列就有这6种结果
```
[1,2,3]
[1,3,2]
[2,1,3]
[2,3,1]
[3,1,2]
[3,2,1]
```
给定一个n个元素数组，其全排列的过程可以描述如下： 
（1）任意取一个元素放在第一个位置，则有n种选择； 
（2）再剩下的n-1个元素中再取一个元素放在第二个位置则有n-1种选择，此时可以看做对n-1个元素进行全排列； 
（3）重复第二步，直到对最后一个元素进行全排列，即最后一个元素放在最后一个位置，全排列结束。

以数组{1,2,3}为例，其全排列的过程如下： 
（1）1后面跟（2,3）的全排列； 
（2）2后面跟（1,3）的全排列； 
（3）3后面跟（1,2）的全排列。


## 递归版本的实现
```CPP
#include <iostream>
using namespace std;

int sum=0; //全排列个数

//打印数组内容
void print(int array[],int len){
    printf("{");
    for(int i=0; i<len;++i)
        cout<<array[i]<<" ";
    printf("}\n");
}

//实现两数交换
void swap(int* o,int i,int j){
    int tmp = o[i];
    o[i] = o[j];
    o[j] = tmp;
}

//递归实现数组全排列并打印
void permutation(int array[],int len,int index){
    if(index==len){//全排列结束
        ++sum;
        print(array,len);
    }
    else
        for(int i=index;i<len;++i){
            //将第i个元素交换至当前index下标处
            swap(array,index,i);

            //以递归的方式对剩下元素进行全排列
            permutation(array,len,index+1);

            //将第i个元素交换回原处
            swap(array,index,i);
        }
}

int main(){
    int array[3]={1,2,3};
    permutation(array,3,0);
    cout<<"sum:"<<sum<<endl;

    getchar();
}
```
### 考虑数组元素中有重复的元素
对于[1,2,2]这种数组，把第一个数1和第二个数2互换得到[2,1,2],接下来第一个数1与第三个数2互换就没有必要了。再考虑[2,1,2]，第二个数与第三个数互换得到[2,2,1],至此全排列结束。

<font color="red">这样我们也得到了在全排列中去掉重复的规则——去重的全排列就是从第一个数字起每个数分别与它后面非重复出现的数字交换。</font>

修改代码如下:
```cpp
//是否交换
bool isSwap(int array[],int len,int index){
        for(int i=index+1;i<len;++i)//从这个index开始，往后一旦出现了和该数字重复的，不用互换了
            if(array[index]==array[i])
                return false;
        return true;
}

//递归实现有重复元素的数组全排列
void permutation(int array[],int len,int index){
    if(index==len){//全排列结束
        ++sum;
        print(array,len); //如果只有一个的话，那必然已是全排列完成了的
    }
    else
        for(int i=index;i<len;++i){
            if(isSwap(array,len,i)){ //新增判断是否交换
                //将第i个元素交换至当前index下标处
                swap(array,index,i);

                //以递归的方式对剩下元素进行全排列
                permutation(array,len,index+1);//固定当前的首位元素，递归求剩下的全排列种类

                //将第i个元素交换回原处
                swap(array,index,i);
            }
        }
}
```

### 参考
[数组的全排列](https://blog.csdn.net/k346k346/article/details/51154786 )