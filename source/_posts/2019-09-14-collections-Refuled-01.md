---
title: jdk集合类源码分析[list]
date: 2019-09-14 15:44:09
tags: [java]
---

源码，以及jdk8中的一些有用的method。

![](https://api1.reindeer36.shop/static/imgs/SainteVictoireCezanneBirthday_ZH-CN8216109812_1920x1080.jpg)
<!--more-->

```java
public interface List<E> extends Collection<E> {
}
```

List的实现类包括ArrayList,LinkedList,CopyOnWriteArrayList,以及两个不怎么用的类<del>stack和Vector</del>

### 1. ArrayList

### 2. LinkedList

### 3.  CopyOnWriteArrayList
内部数组是一个volatile的。
所有的mutate操作都被一个ReentrantLock保护(all mutative
 operations ({@code add}, {@code set}, and so on) are implemented by
 making a fresh copy of the underlying array.) 此类操作都是创建一个新的array，再通过setArray方法设置这个volatile的值
所有的非mutate操作(get, size ,indexOf等)都是通过一个getArray方法先获取到这个
[确认CopyOnWriteArrayList是线程安全的](https://stackoverflow.com/a/2950898)。 任一线程对结构的修改都会直接被后续的读的线程看到。 缺点就是这种容器只适用于read 多 write少的场景。

> An important detail is that volatile only applies to the array reference itself, not to the content of the array. However because all changes to the array are made before its reference is published, the volatile guarantees extend to the content of the array

volatile只是保证了数组的指针是volatile的，但事实上因为修改array引用的地方只有setArray方法（改方法包在锁里，同时只有一条线程可以调用）。因此array的内容事实上等同于是volatile的。
由于happen-before原则的存在，add(obj)一定发生在indexOf(obj)之前。

***还是有崩的可能***
具体就是CopyOnWrite容器只能保证数据的最终一致性，不能保证数据的实时一致性。所以如果你希望写入的的数据，马上能读到，请不要使用CopyOnWrite容器。(CopyOnWriteArrayList只是保证了read能够反映上一次write的结果)
比如亲测下面这段代码会崩
```java
public class CrashOfCopyOnWriteArrayList {

    void test(){
        CopyOnWriteArrayList<String> list = new CopyOnWriteArrayList<>();
        for(int i = 0; i<10000; i++){
            list.add("string" + i);
        }

        new Thread(new Runnable() {
            @Override
            public void run() {
                while (true) {
                    int size = list.size();
                    if (size > 0) {
                        String content = list.get(size - 1); //崩在这里的数组越界
                    }else {
                        break;
                    }
                }
            }
        }).start();

        new Thread(new Runnable() {
            @Override
            public void run() {
                while (true) {
                    if(list.size() <= 0){
                        break;
                    }
                    list.remove(0);
                }
            }
        }).start();
    }

    public static void main(String[] args) {
        new CrashOfCopyOnWriteArrayList().test();
    }
}
```



## 参考
[【死磕 Java 集合】— 总结篇](http://cmsblogs.com/?p=4781)
[Java集合框架常见面试题](https://github.com/Snailclimb/JavaGuide/blob/master/docs/java/collection/Java集合框架常见面试题.md）

