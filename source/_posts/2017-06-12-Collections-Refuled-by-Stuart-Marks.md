---
title: Java集合类的一些整理 
date: 2017-06-25 22:56:33
categories: blog
tags: [java]
---

根据网上的大部分博客的分类，集合框架分为Collections(具有类似数组的功能)和Map(存储键值对)这两大部分。针对jdk1.8的java.util里面的一些常用的或者不常用的集合做一些分析。写这篇文章的过程中，我慢慢发现不同版本jdk的同一个class的实现是有一些差异的(LinkedList)，由于对照的是java1.8的代码，里面会多一些since 1.8的代码，这个暂时不管。
![](http://odzl05jxx.bkt.clouddn.com/16d714eb6e8ecc23e4d6ba20d0be17a0.jpg?imageView2/2/w/600)
 
<!--more-->


## List
ArrayList (建议new出来的时候给定一个适当的size，不然每次扩容很慢的)
LinkedList(not recommended，增删元素的时候快一点)
Vector（线程安全,重同步，不推荐）

## Set
HashSet
TreeSet
LinekedHashSet

## Queue

Stack ArrayDeque

---------------------------------Map-------------------------
## HashMap （LinkedHashMap ）
## TreeMap
## HashTable
SparseArray



[类型擦除原理](http://blog.csdn.net/lonelyroamer/article/details/7868820)


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
public boolean retainAll(Collection<?> c) //  给定一个集合，从list中删除所有不在这个集合里面的元素

public void trimToSize() // 内存压力大的时候可以释放掉一部分内存，记得那个1.5倍的默认扩容嘛，释放的就是这0.5的内存
```


多线程场景下要注意的问题

> 和Vector不同，ArrayList中的操作不是线程安全的！所以，建议在单线程中才使用ArrayList，而在多线程中可以选择Vector或者CopyOnWriteArrayList。

1.2 LinkedList的一些点
LinkedList是双向链表实现的，可以想象成一帮小孩左手拉右手绕成一个圈，只不过这里面的每一个小孩并不是你放进去的 T 类型数据，而是一个Node<T> 。所以LinkedList是可以放进去一个Null的。
LinkedList往往被人诟病的就是除了添加和删除快之外，get和set很慢。
来看下add的实现（jdk 1.8）

```java
   public boolean add(E e) {
        linkLast(e);
        return true;
    }

/**
     * Links e as last element.
     */
    void linkLast(E e) {
        final Node<E> l = last;  //先把链表的尾巴找出来
        final Node<E> newNode = new Node<>(l, e, null); // 可以想象每次add都有new的操作，并将原来的尾巴作为这个新的Entry的头部
        last = newNode; //新的Node将成为新的尾巴
        if (l == null) //这种情况是原来没有尾巴，也就是说size = 0
            first = newNode; //这时候就只有一个Node，头和尾都是Null
        else
            l.next = newNode; //不然的话，旧的尾巴变成了倒数第二个，它的next指向了新的Entry.

        size++;
        modCount++;
    }

```

add的过程看起来很快，new一个entery，确定下前后的指针就可以了。remove也差不多，取消指针引用即可。

来看比较慢的get

```java
 public E get(int index) {
        checkElementIndex(index);
        return node(index).item;
    }

  /**
     * Returns the (non-null) Node at the specified element index.
     */
    Node<E> node(int index) {
        // assert isElementIndex(index);

        if (index < (size >> 1)) {
            Node<E> x = first;
            for (int i = 0; i < index; i++)
                x = x.next; //一直遍历到这个index才返回，慢
            return x;
        } else {
            Node<E> x = last;
            for (int i = size - 1; i > index; i--)
                x = x.prev;
            return x;
        }
    }

```

值得注意的一点小事：
ArrayList implement RandomAccess接口，而LinkedList并没有。RandomAccess接口的定义如下

> * Marker interface used by <tt>List</tt> implementations to indicate that
 * they support fast (generally constant time) random access.  The primary
 * purpose of this interface is to allow generic algorithms to alter their
 * behavior to provide good performance when applied to either random or
 * sequential access lists.
 *
 * <p>The best algorithms for manipulating random access lists (such as
 * <tt>ArrayList</tt>) can produce quadratic behavior when applied to
 * sequential access lists (such as <tt>LinkedList</tt>).  Generic list
 * algorithms are encouraged to check whether the given list is an
 * <tt>instanceof</tt> this interface before applying an algorithm that would
 * provide poor performance if it were applied to a sequential access list,
 * and to alter their behavior if necessary to guarantee acceptable
 * performance.
 *
 * <p>It is recognized that the distinction between random and sequential
 * access is often fuzzy.  For example, some <tt>List</tt> implementations
 * provide asymptotically linear access times if they get huge, but constant
 * access times in practice.  Such a <tt>List</tt> implementation
 * should generally implement this interface.  As a rule of thumb, a
 * <tt>List</tt> implementation should implement this interface if,
 * for typical instances of the class, this loop:
 * <pre>
 *     for (int i=0, n=list.size(); i &lt; n; i++)
 *         list.get(i); //get的速度应该是恒定的
 * </pre>
 * runs faster than this loop:
 * <pre>
 *     for (Iterator i=list.iterator(); i.hasNext(); )
 *         i.next(); 
 * </pre>
```
这种接口就是给外界使用者看的，用来说明该集合支持这种通过下标查找（速度不变）的快速操作

实践表明，对于linkedList，采用for loop的方式要很慢，但使用ListIterator<T>的方式，速度并不慢，简单来想，沿着链表的一个方向一致往下走就是了嘛。
一些经验表明(摘自简书作者嘟爷MD的文章)
> [ArryList和LinkedList的对比结论](http://www.jianshu.com/p/d5ec2ff72b33) 
> 1、顺序插入速度ArrayList会比较快
> 2、LinkedList将比ArrayList更耗费一些内存
> 3、ArrayList的遍历效率会比LinkedList的遍历效率高一些
> 4、有些说法认为LinkedList做插入和删除更快，这种说法其实是不准确的：如果增加或者删除的元素在前半部分的时候，ArrayList会频繁调用System.arrayCopy方法，虽然native方法快，但高频率调用肯定慢，至少比不上移动指针。



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
 

### Reference 
1. [Collections Refuled by Stuart Marks](https://www.youtube.com/watch?v=q6zF3vf114M)
2. [From Java Code to Java Heap: Understanding the Memory Usage of Your Application](https://www.youtube.com/watch?v=FLcXf9pO27w)
3. [Java集合干货系列](http://www.jianshu.com/p/2cd7be850540)
4. [Arrays.asList()返回的List不是jva.util.ArrayList](http://www.programcreek.com/2014/01/java%E7%A8%8B%E5%BA%8F%E5%91%98%E5%B8%B8%E7%8A%AF%E7%9A%8410%E4%B8%AA%E9%94%99%E8%AF%AF/)
