---
title: Java集合类的一些整理 
date: 2017-06-25 22:56:33
categories: blog
tags: [java]
---

集合的实现原理
 

HashMap 
LinkedHashMap 
ArrayList 
LinkedList(not recommended)
HashSet

[类型擦除原理](http://blog.csdn.net/lonelyroamer/article/details/7868820)

<!--more-->
1. ArrayList源码解析
- 崩溃代码
```java
 public static void main(String[] args) {
    String[] array = new String[]{"a", "b", "c", "d"};
    List<String> l = Arrays.asList(array);
    l.add("d");
}
```
Exception in thread "main" java.lang.UnsupportedOperationException
    at java.util.AbstractList.add(AbstractList.java:148)
    at java.util.AbstractList.add(AbstractList.java:108)
    at com.example.demo.main(ConcurrentModificationListDemo.java:13)

问题出在Arrays.asList返回了一个**java.util.Arrays.ArrayList**，而不是**java.util.ArrayList**。前者只实现了List接口的有限的几个方法，并且是Arrays内部的一个private class。
正确的用法是new 一个ArrayList，把这个有限的list的元素(的指针)copy进去，即addAll()方法
ArrayList.toArray(T[] a)是把所有的elements通过System.arraycopy(elementData, 0, a, 0, size);复制到a数组中。

- System.arraycopy可以从自己的数组复制到自己的数组
```java
  public void add(int index, E element) {
        rangeCheckForAdd(index);
        ensureCapacityInternal(size + 1);  // Increments modCount!!
        System.arraycopy(elementData, index, elementData, index + 1,
                         size - index);  
        elementData[index] = element;
        size++;
    }
```
添加到指定位置，System.arrayCopy可以从同一个数组复制到同一个数组，几乎就是挪动指针了。

- 不常见的方法

```java
//下面这两个是因为ArrayList implements java.io.Serializable，是序列化时会调用的
private void writeObject(java.io.ObjectOutputStream s)
private void readObject(java.io.ObjectInputStream s)

protected void removeRange(int fromIndex, int toIndex) 
public boolean removeAll(Collection<?> c) //给一个集合，删除list与之的交集
```


多线程场景下要注意的问题

> 和Vector不同，ArrayList中的操作不是线程安全的！所以，建议在单线程中才使用ArrayList，而在多线程中可以选择Vector或者CopyOnWriteArrayList。
- 

2. HashMap源码解析 LinkedMap
3. HashSet原理
4. 一些不常用的类
    Vetor，Stack，ArrayDeque,queue
5. concurrentHashMap等
6. WeakHaskMap


HashMap的实现原理，LinkedHashMap的实现

list.replaceAll(String::toUpperCase) // can not change the elemeet type, for that you need an stream

```java
public static void dodtuff(){
    print()
    // show case awesome 
}
```
 

### ref 
1. Collections Refuled by Stuart Marks
2. IBM from java code to java heap
3. [Java集合干货系列](http://www.jianshu.com/p/2cd7be850540)
4. [Arrays.asList()返回的List](http://www.programcreek.com/2014/01/java%E7%A8%8B%E5%BA%8F%E5%91%98%E5%B8%B8%E7%8A%AF%E7%9A%8410%E4%B8%AA%E9%94%99%E8%AF%AF/)
