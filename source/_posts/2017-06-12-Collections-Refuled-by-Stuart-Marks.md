---
title: Java集合类的一些整理
date: 2017-06-25 22:56:33
categories: blog
tags: [java]
---

根据网上的大部分博客的分类，集合框架分为Collections(具有类似数组的功能)和Map(存储键值对)这两大部分。针对jdk1.8的java.util里面的一些常用的或者不常用的集合做一些分析。写这篇文章的过程中，我慢慢发现不同版本jdk的同一个class的实现是有一些差异的(LinkedList)，由于对照的是java1.8的代码，里面会多一些since 1.8的代码，这里不作论述。
![](http://odzl05jxx.bkt.clouddn.com/16d714eb6e8ecc23e4d6ba20d0be17a0.jpg?imageView2/2/w/600)

<!--more-->

java集合的大致框架建议参考网上博客的总结，[Java集合干货系列](http://www.jianshu.com/p/2cd7be850540)写的比较好，图画的也不错，针对jdk 1.6源码讲的。我这里只是自己学习过程中的一些笔记。


## List
ArrayList (建议new出来的时候给定一个适当的size，不然每次扩容很慢的，可以放null)
LinkedList(not recommended，增删元素的时候快一点)
Vector（线程安全,重同步，不推荐）

## Set
HashSet (底层是HashMap)
TreeSet(排序存储)
LinkedHashSet(底层是LinkedHashMap)

## Queue

Stack ArrayDeque(不常用)

## Map
HashMap （键值都可以为null,底层是哈希表）
TreeMap(底层二叉树)
HashTable(线程安全，键值都不允许为null)
SparseArray(Android平台用)

关于集合，不得不提到泛型，Java 1.5引入了泛型，关于泛型，找到一篇很好的文章
[类型擦除原理](http://blog.csdn.net/lonelyroamer/article/details/7868820)。本质上只是提供了编译期类型检查。编译通过后都是Object，所以叫做[类型擦除](https://zh.wikipedia.org/wiki/%E7%B1%BB%E5%9E%8B%E6%93%A6%E9%99%A4)。

## 1. List的解析

### 1.1 ArrayList源码解析

- 先上一段崩溃代码
```java
 public static void main(String[] args) {
    String[] array = new String[]{"a", "b", "c", "d"};
    List<String> l = Arrays.asList(array);
    l.add("d");
}

Exception in thread "main" java.lang.UnsupportedOperationException
    at java.util.AbstractList.add(AbstractList.java:148)
    at java.util.AbstractList.add(AbstractList.java:108)
    at com.example.demo.main(ConcurrentModificationListDemo.java:13)
```
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


### 1.2 LinkedList的一些点
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
 * List implementation should implement this interface if,
 * for typical instances of the class, this loop:
 *     for (int i=0, n=list.size(); i &lt; n; i++)
 *         list.get(i); //get的速度应该是恒定的
 * runs faster than this loop:
 *     for (Iterator i=list.iterator(); i.hasNext(); )
 *         i.next();


这种接口就是给外界使用者看的，用来说明该集合支持这种通过下标查找（速度不变）的快速操作

实践表明，对于linkedList，采用for loop的方式要很慢，但使用ListIterator<T>的方式，速度并不慢，简单来想，沿着链表的一个方向一致往下走就是了嘛。
一些经验表明(摘自简书作者嘟爷MD的文章)

[ArryList和LinkedList的对比结论](http://www.jianshu.com/p/d5ec2ff72b33)

> 1、顺序插入速度ArrayList会比较快
> 2、LinkedList将比ArrayList更耗费一些内存
> 3、ArrayList的遍历效率会比LinkedList的遍历效率高一些
> 4、有些说法认为LinkedList做插入和删除更快，这种说法其实是不准确的：如果增加或者删除的元素在前半部分的时候，ArrayList会频繁调用System.arrayCopy方法，虽然native方法快，但高频率调用肯定慢，至少比不上移动指针。


## 2. Map的几个实现类
### 2.1 HashMap源码解析

>public class HashMap<K,V> extends AbstractMap<K,V>
    implements Map<K,V>, Cloneable, Serializable

HashMap不是线程安全的，Key和Value都有可能为null，存储数据不是有序的(get的顺序不是put的顺序)。比较专业的说法是 **链表数组结构**。

HashMap中有几个默认值常量

    默认初始容量是16
    static final int DEFAULT_INITIAL_CAPACITY = 1 << 4; // aka 16

    默认加载因子是0.75f ，加载因子是指Hashmap在自动扩容之前可以达到多满
    static final float DEFAULT_LOAD_FACTOR = 0.75f; //一般不需要改

构造函数有好几个

```java
 public HashMap(int initialCapacity, float loadFactor)  //自定义加载因子，比较玄学
 public HashMap(int initialCapacity) // 避免扩容，和ArrayList初始化指定容量类似的道理
 public HashMap() //直接把初始容量设置成16
 public HashMap(Map<? extends K, ? extends V> m)
```
[注意这个初始容量必须是2的n次方](https://stackoverflow.com/questions/8352378/why-does-hashmap-require-that-the-initial-capacity-be-a-power-of-two)

来看常见的CURD操作(jdk 1.8源码，和我在网上找到的jdk1.6源码有一些变化了)
```java
 public V put(K key, V value) {
        return putVal(hash(key), key, value, false, true); //HashMap允许key为null,key为null的话，直接放到数组的0的位置（hash方法返回的是0）
    }

    static final int hash(Object key) {
           int h;
           return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16); //如果是null，放到数组的第一个
// 这里面就是HashMap算法的高明之处  ，
//  1. 首先算出object的hashcode，
//2.然后根据上述公式将二进制的1尽量分散的均匀一点         
// 3. 在putVal的时候将这个值跟数组的长度length-1进行位运算，得到一个比length小的正数，作为这个新元素在数组中的index.但这样仍不免会产生冲突(hash Collision)
       }


 /**
     * Implements Map.put and related methods
     *
     * @param hash hash for key
     * @param key the key
     * @param value the value to put
     * @param onlyIfAbsent if true, don't change existing value
     * @param evict if false, the table is in creation mode.
     * @return previous value, or null if none
     */
    final V putVal(int hash, K key, V value, boolean onlyIfAbsent,
                   boolean evict) {
        Node<K,V>[] tab; Node<K,V> p; int n, i;
        if ((tab = table) == null || (n = tab.length) == 0)
            n = (tab = resize()).length; //table为成员变量，是一个Node数组，为空的话则创建 。在resize中创建
        if ((p = tab[i = (n - 1) & hash]) == null)
            tab[i] = newNode(hash, key, value, null);
        else {
            Node<K,V> e; K k;
            if (p.hash == hash &&
                ((k = p.key) == key || (key != null && key.equals(k))))
                e = p; //Table数组中找到了这个下标的元素，直接指定
            else if (p instanceof TreeNode)//p可以理解为previous 。 如果发现这个节点是一棵树（红黑树？）
                e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
            else {//否则该节点是链表，各个元素之间手拉手的那种
                for (int binCount = 0; ; ++binCount) {
                    if ((e = p.next) == null) {
                        p.next = newNode(hash, key, value, null); //找到这个链表的尾巴了
                        if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
                            treeifyBin(tab, hash);
                        break;
                    }
                    if (e.hash == hash &&
                        ((k = e.key) == key || (key != null && key.equals(k))))
                        break;
                    p = e;
                }
            }
            if (e != null) { // existing mapping for key
                V oldValue = e.value;
                if (!onlyIfAbsent || oldValue == null)
                    e.value = value;
                afterNodeAccess(e); //回调函数
                return oldValue;
            }
        }
        ++modCount;
        if (++size > threshold)
            resize();
        afterNodeInsertion(evict);//回调函数
        return null;
    }

```

get方法
```java
  public V get(Object key) {
        Node<K,V> e;
        return (e = getNode(hash(key), key)) == null ? null : e.value;//根据key来找value
    }
    /**
     * Implements Map.get and related methods
     *
     * @param hash hash for key
     * @param key the key
     * @return the node, or null if none
     */
    final Node<K,V> getNode(int hash, Object key) {
        Node<K,V>[] tab; Node<K,V> first, e; int n; K k;
        if ((tab = table) != null && (n = tab.length) > 0 &&
            (first = tab[(n - 1) & hash]) != null) { //table不为空说明曾经put过
            if (first.hash == hash && // always check first node
                ((k = first.key) == key || (key != null && key.equals(k))))
                return first;
            if ((e = first.next) != null) {
                if (first instanceof TreeNode)
                    return ((TreeNode<K,V>)first).getTreeNode(hash, key);
                do {
                    if (e.hash == hash &&
                        ((k = e.key) == key || (key != null && key.equals(k))))
                        return e;
                } while ((e = e.next) != null);
            }
        }
        return null;
    }


  public V get(Object key) {
        Node<K,V> e;
        return (e = getNode(hash(key), key)) == null ? null : e.value;
    }

    /**
     * Implements Map.get and related methods
     *
     * @param hash hash for key
     * @param key the key
     * @return the node, or null if none
     */
    final Node<K,V> getNode(int hash, Object key) {
        Node<K,V>[] tab; Node<K,V> first, e; int n; K k;
        if ((tab = table) != null && (n = tab.length) > 0 &&
            (first = tab[(n - 1) & hash]) != null) {
            if (first.hash == hash && // always check first node
                ((k = first.key) == key || (key != null && key.equals(k))))
                return first;
            if ((e = first.next) != null) {
                if (first instanceof TreeNode)
                    return ((TreeNode<K,V>)first).getTreeNode(hash, key);
                do {
                    if (e.hash == hash &&
                        ((k = e.key) == key || (key != null && key.equals(k))))
                        return e;
    //可以看出比较的方式就是hash（int）相等且key(指针相等)  或者key equals(所以经常说重写equals需要确保hashcode一致，这里至少反应了这一点)
                } while ((e = e.next) != null);
            }
        }
        return null;
    }

```

回想一下平时迭代一个HashMap的方式
```java
long i = 0;
Iterator<Map.Entry<Integer, Integer>> it = map.entrySet().iterator();
while (it.hasNext()) {
    Map.Entry<Integer, Integer> pair = it.next(); //上面的get也是这种不断查找next的方式
    i += pair.getKey() + pair.getValue();
}
```

entrySet方法是Map接口定义的
```
Set<Map.Entry<K, V>> entrySet();
   * Returns a Set view of the mappings contained in this map.
     * The set is backed by the map, so changes to the map are
     * reflected in the set, and vice-versa.  If the map is modified
     * while an iteration over the set is in progress (except through
     * the iterator's own <tt>remove</tt> operation, or through the
     * <tt>setValue</tt> operation on a map entry returned by the
     * iterator) the results of the iteration are undefined.  The set
     * supports element removal, which removes the corresponding
     * mapping from the map, via the <tt>Iterator.remove</tt>,
     * <tt>Set.remove</tt>, <tt>removeAll</tt>, <tt>retainAll</tt> and
     * <tt>clear</tt> operations.  It does not support the
     * <tt>add</tt> or <tt>addAll</tt> operations.
     *
     * @return a set view of the mappings contained in this map
```

大致意思是： 返回一个能够反映该map元素组合的一个Set，对这个Set的操作都将反映到原map上，反之亦然。在通过entrySet迭代这个map的时候，除了remove和操作操作都是不被支持的。返回的Set支持删除对应的mapping组合。但不支持add操作

HashMap内部保留了一个这样的成员变量：
transient Set<Map.Entry<K,V>> entrySet; //成员变量
具体实现enterySet方法的地方：
```java
  public Set<Map.Entry<K,V>> entrySet() {
        Set<Map.Entry<K,V>> es;
        return (es = entrySet) == null ? (entrySet = new EntrySet()) : es;
    }

// 这个EntrySet大致长这样
  final class EntrySet extends AbstractSet<Map.Entry<K,V>> {
        public final int size()                 { return size; }
        public final void clear()               { HashMap.this.clear(); }
        public final Iterator<Map.Entry<K,V>> iterator() {
            return new EntryIterator();
        }
        public final boolean contains(Object o) {
            if (!(o instanceof Map.Entry))
                return false;
            Map.Entry<?,?> e = (Map.Entry<?,?>) o;
            Object key = e.getKey();
            Node<K,V> candidate = getNode(hash(key), key);
            return candidate != null && candidate.equals(e);
        }
        public final boolean remove(Object o) {
            if (o instanceof Map.Entry) {
                Map.Entry<?,?> e = (Map.Entry<?,?>) o;
                Object key = e.getKey();
                Object value = e.getValue();
                return removeNode(hash(key), key, value, true, true) != null;
            }
            return false;
        }
    }

```
整理的关键在于removeNode方法，和getNode和putVal很像
```java
   final Node<K,V> removeNode(int hash, Object key, Object value,
                               boolean matchValue, boolean movable) {
        Node<K,V>[] tab; Node<K,V> p; int n, index;
        if ((tab = table) != null && (n = tab.length) > 0 &&
            (p = tab[index = (n - 1) & hash]) != null) {
            Node<K,V> node = null, e; K k; V v;
            if (p.hash == hash &&
                ((k = p.key) == key || (key != null && key.equals(k))))
                node = p;
            else if ((e = p.next) != null) {
                if (p instanceof TreeNode)
                    node = ((TreeNode<K,V>)p).getTreeNode(hash, key);
                else {
                    do {
                        if (e.hash == hash &&
                            ((k = e.key) == key ||
                             (key != null && key.equals(k)))) {
                            node = e;
                            break;
                        }
                        p = e;
                    } while ((e = e.next) != null);
                }
            } //先把p(previous)找出来，这里的matchValue和movable都是true
            // node 就是包含了要移出对象的Node
            if (node != null && (!matchValue || (v = node.value) == value ||
                                 (value != null && value.equals(v)))) {
                if (node instanceof TreeNode)
                    ((TreeNode<K,V>)node).removeTreeNode(this, tab, movable);
                else if (node == p) //数组这个位置就一个
                    tab[index] = node.next;//直接指向下一个
                else
                    p.next = node.next; //数组这个位置指向链表下一个节点，释放引用
                ++modCount;
                --size;
                afterNodeRemoval(node);
                return node;
            }
        }
        return null;
    }
```
比较元素是否相同的关键是
> e.hash == hash || (key!=null &&key.equals(k)) //后半部分其实也是比较hashCode

另外一些平时常用的方法包括：
```java
  public boolean containsKey(Object key) {
        return getNode(hash(key), key) != null; //就是检查下有没有这个key对应的Node
    }

   public boolean containsValue(Object value) {
        Node<K,V>[] tab; V v;
        if ((tab = table) != null && size > 0) {
            for (int i = 0; i < tab.length; ++i) {
                for (Node<K,V> e = tab[i]; e != null; e = e.next) {
                    if ((v = e.value) == value ||
                        (value != null && value.equals(v)))
                        return true; //遍历内部的数组，仅此而已
                }
            }
        }
        return false;
    }
```

和ArrayList、LinkedList比起来，HashMap的源码要麻烦许多，这里面涉及到hashCode，链表，红黑树。需要一点数据结构的知识。另外，HashMap还针对hashCode冲突（hash Collision，不同的Object居然有相同的hashCode）的情况作了[预处理](https://stackoverflow.com/questions/6493605/how-does-a-java-hashmap-handle-different-objects-with-the-same-hash-code)
通俗的来说，HashMap内部维护了一个数组，每一个数组元素内部不一定只有一个，有可能是一个链表。每次添加(key,value)不是盲目的往这个数组里面塞，而是算下key的hash值，放到对应的节点上。如果这个节点上还没有元素，直接放就好了。如果有的话，新加入的value将被作为原有元素的Next(外部调用get的时候，先根据传入的key的hashCode找到节点，然后根据key.equals来找)。简单如此，精致如斯。

### 2.2 LinkedHashMap

public class LinkedHashMap<K,V>
    extends HashMap<K,V>
    implements Map<K,V>
HashMap源码我看了下有两千多行，LinkedHashMap只有七百多行，显然这是继承带来的简便之处。
关键的成员变量  
final boolean accessOrder; 默认是false
> The iteration ordering method for this linked hash map: <tt>true</tt>
for access-order, false for insertion-order.

LinkedHashMap常用的属性就是它支持有序，这个有序是指迭代的时候有序
HashMap用来存放和获取对象，而双向链表用来实现有序

### 2.3 SparseArray
先来看一段崩溃日志
```
Fatal Exception: java.lang.ArrayIndexOutOfBoundsException: src.length=509 srcPos=60 dst.length=509 dstPos=61 length=-60
       at java.lang.System.arraycopy(System.java:388)
       at com.android.internal.util.GrowingArrayUtils.insert(GrowingArrayUtils.java:135)
       at android.util.SparseIntArray.put(SparseIntArray.java:144)
```

简单分析一下，
```
GrowingArrayUtils.java
  /**
     * Primitive int version of {@link #insert(Object[], int, int, Object)}.
     */
    public static int[] insert(int[] array, int currentSize, int index, int element) {
        assert currentSize <= array.length;

        if (currentSize + 1 <= array.length) {
          System.arraycopy(array, index, array, index + 1, currentSize -index);
          array[index] = element;
            return array;
        }

        int[] newArray = new int[growSize(currentSize)];
        System.arraycopy(array, 0, newArray, 0, index);
        newArray[index] = element;
        System.arraycopy(array, index, newArray, index + 1, array.length - index);
        return newArray;
    }

    public static void arraycopy(int[] src, int srcPos, int[] dst, int dstPos, int length) {
        if (src == null) {
            throw new NullPointerException("src == null");
        }
        if (dst == null) {
            throw new NullPointerException("dst == null");
        }
        if (srcPos < 0 || dstPos < 0 || length < 0 ||
            srcPos > src.length - length || dstPos > dst.length - length) {
            throw new ArrayIndexOutOfBoundsException(
                "src.length=" + src.length + " srcPos=" + srcPos +
                " dst.length=" + dst.length + " dstPos=" + dstPos + " length=" + length);
//对照着崩溃日志，length传了个-60进来，而srcPos = 60。显然是有其他线程在SparseArray.put调用后，在GrowingArrayUtils.insert调用前做了一次clear操作。怎么办，加锁呗。

        }
    }


```

很显然这段话是因为length= -60导致崩溃，应该是mSize被设置为0(其他线程调用了clear方法，clear只是设置mSize = 0)

重现了一下：
```java
 @Override
    public void onClick(View v) {
        executor = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors());
        for (int i = 0; i < 1000; i++) {
            if (i %2==0) {
                executor.execute(new closer(sparseIntArray));
                continue;
            }
            executor.execute(new writer(sparseIntArray, i));
        }
    }

    static class writer implements Runnable {

        SparseIntArray array;

        int index;

        public writer(SparseIntArray array, int index) {
            this.array = array;
            this.index = index;
        }


        @Override
        public void run() {
            array.put(index, (int) Thread.currentThread().getId());
            LogUtil.p("write to "+index);
        }
    }

    static class closer implements Runnable {

        SparseIntArray array;

        public closer(SparseIntArray array) {
            this.array = array;
        }

        @Override
        public void run() {
            array.clear();
            LogUtil.e("clear array");
        }
    }
```

果然:
```
08-21 15:26:27.600 23165-23207/com.harris.simplezhihu E/AndroidRuntime: FATAL EXCEPTION: pool-1-thread-4
        Process: com.harris.simplezhihu, PID: 23165
        java.lang.ArrayIndexOutOfBoundsException: src.length=21 srcPos=1 dst.length=21 dstPos=2 length=-1
        at java.lang.System.arraycopy(System.java:388)
        at com.android.internal.util.GrowingArrayUtils.insert(GrowingArrayUtils.java:135)
        at android.util.SparseIntArray.put(SparseIntArray.java:143)
        at com.harris.simplezhihu._07_sparsearry_concurrent.SpareArrayCrashActivity$writer.run(SpareArrayCrashActivity.java:61)
        at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1113)
        at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:588)
        at java.lang.Thread.run(Thread.java:818)
```



SparseArry提供了类似于HashMap的调用接口，

使用SparseArray的初衷还是在android这种内存比cpu金贵的平台中，使用SparseArry相比HashMap能够减轻内存压力，获得更好的性能。
[liaohuqiu指出SparseArry并不是任何时候都更快](https://www.liaohuqiu.net/cn/posts/sparse-array-in-android/)，主要是节省内存，避免autoBoxing，二分法查找对于cpu的消耗需要权衡。尤其是存储的量很大的时候，二分法查找的速度会很慢。

SparseArry类似的class有好几个，据说有八个，以SparseIntArry为例
SparseIntArry的几个常用方法,值得注意的是 clear方法只不过是把mSize设置为0。
remove(key)只是把这个key对应位置value设置为DELETED.
内部的mKeys是有序的int[],long[]。这样才能实现二分法查找。
```java
public int indexOfKey(int key)
public int indexOfValue(int value)
public int get(int key)
public void put(int key, int value)

public void clear() {
       mSize = 0;
   }
//迭代一个SparseArry的方法
for(int i = 0; i < sparseArray.size(); i++) {
   int key = sparseArray.keyAt(i);
   // get the object by the key.
   Object obj = sparseArray.get(key);
}

// 从源码来看变量结构
public class SparseIntArray implements Cloneable{
    private int[] mKeys;
    private int[] mValues;
    private int mSize;
}



public void put(int key, int value) {
     int i = ContainerHelpers.binarySearch(mKeys, mSize, key); //二分法查找

     if (i >= 0) {
         mValues[i] = value; //找到了在Value数组中的index,直接替换掉
     } else {
         i = ~i;
         mKeys = GrowingArrayUtils.insert(mKeys, mSize, i, key);
         mValues = GrowingArrayUtils.insert(mValues, mSize, i, value);
         mSize++;
     }
 }

  //  GrowwingArrayUtils.java
     /**
     * Primitive int version of {@link #insert(Object[], int, int, Object)}.
     */
    public static int[] insert(int[] array, int currentSize, int index, int element) {
        assert currentSize <= array.length;

        if (currentSize + 1 <= array.length) {
            System.arraycopy(array, index, array, index + 1, currentSize - index);
            array[index] = element;
            return array;
        }

        int[] newArray = new int[growSize(currentSize)];
        System.arraycopy(array, 0, newArray, 0, index);
        newArray[index] = element;
        System.arraycopy(array, index, newArray, index + 1, array.length - index);
        return newArray;
    }

```

SparseArray
廖祜秋 特地强调
1. SparseArray 是针对HashMap做的优化。
    1.HashMap 内部的存储结构，导致一些内存的浪费。
    2.在刚扩容完，SparseArray 和 HashMap 都会存在一些没被利用的内存。
2. SparseArray 并不是任何时候都会更快，有时反而会更慢
vauleAt和keyAt接收一个index参数(数组下标)，这个参数应该是key对应的BinarySearch得到的值。




### 2.4 ArrayMap






## 3. Set的介绍
Set用比较少，HashSet、TreeSet和LinkedHashSet是jdk的实现类

public class HashSet<E>
    extends AbstractSet<E>
    implements Set<E>, Cloneable, java.io.Serializable
Set的重要特点就是**不能放进去重复**的元素，Set中不会存在e1和e2，e1.equals(e2)的情况
HashSet的源码只有三百多行，内部有一个map（HashMap）相对来说是比较简单的。其实Set平时用的也不是那么多。。。

### 4. 一些不常用的类

    Vetor，Stack，ArrayDeque,Queue

    Vector属于List,线程安全，但效率低（就是简单的在所有方法前面加上了synchronized）

    Queue是一个interface，属于两端可以出入的List，通常是(FIFO模式)，实现类有
    PriorityQueue，
    java.util.concurrent.LinkedBlockingQueue
    java.util.concurrent.LinkedBlockingQueue
    java.util.concurrent.PriorityBlockingQueue
    作者都是大名鼎鼎的Doug Lea
    另外，LinkedList也能直接拿来当做queue使用

    Stack是Vector的子类(属于LIFO的栈)
    The Stack class represents a last-in-first-out (LIFO) stack of object

    Deque(双端队列)


### 5. concurrentHashMap等
jdk1.8的concurrentHashMap不是用synchronized实现的，是Doug Lea使用CAS操作写的，非常高效。

### 6. WeakHaskMap
WeakHashMap的Key是WeakReference，但Value不是。
常见用法

```java
String a = "a";
map.put(1,a);
a = null;
//map中的a可以出了map自身外没有其他地方被引用，a将被被gc回收
```

Android [官方开发文档](https://developer.android.com/reference/java/util/WeakHashMap.html)上指出了一点

> Implementation note: The value objects in a WeakHashMap are held by ordinary strong references. Thus care should be taken to ensure that value objects do not strongly refer to their own keys, either directly or indirectly, since that will prevent the keys from being discarded. Note that a value object may refer indirectly to its key via the WeakHashMap itself; that is, a value object may strongly refer to some other key object whose associated value object, in turn, strongly refers to the key of the first value object. If the values in the map do not rely on the map holding strong references to them, one way to deal with this is to wrap values themselves within WeakReferences before inserting, as in: m.put(key, new WeakReference(value)), and then unwrapping upon each get.

WeakHashMap的value不要持有key的强引用，否则，key永远不会被清除,value也别想被清除。


## 7. java 8的一些新的方法
list.replaceAll(String::toUpperCase) //method reference
can not change the elemeet type, for that you need an stream
[Collections Refuled by Stuart Marks](https://www.youtube.com/watch?v=q6zF3vf114M)
putIfAbsent是Atmmic的[Is putIfAbsent an atomic operation](http://forums.terracotta.org/forums/posts/list/7968.page)

## 8.结束语
8.1 [Doug Lea](https://en.wikipedia.org/wiki/Doug_Lea) 是非常聪明的人，估计并发经常会牵涉到集合，所以jdk里面很多集合都有他的作品
8.2 jdk只是定义了这些框架，像List，Map这些全都是接口，完全可以自己去实现。Apache就有一大堆适合特定场景的集合实现类。jdk只是帮助我们实现了一些常见的类。如果有现成的满足需求的框架，不要重复造轮子。
8.3 平时只要记住ArrayList和HashMap的**大致内部实现**就可以了，至于别的，除非面试，平时没必要记录。
8.4 [Stuart Mark](https://blogs.oracle.com/java/collections-refueled)特别喜欢把一个class搞成**@deprecated**
8.5 就连[Joshua Bloch](https://www.youtube.com/watch?v=V1vQf4qyMXg) 都承认，除非性能真的很重要的，平时没必要过度优化。By the way , he said Doug Lea is very smart .
8.6 [Stack这种东西有点过时了](https://stackoverflow.com/questions/1386275/why-is-java-vector-class-considered-obsolete-or-deprecated) 一个原因是Stack extends Vector（每个方法都加synchronized，多数场景下不需要，另外Vector是1.1还是1.0就有了）


### update
jdk 1.8对于长度超过8的链表改用红黑树。


### Reference
1. [Collections Refuled by Stuart Marks](https://www.youtube.com/watch?v=q6zF3vf114M)
2. [From Java Code to Java Heap: Understanding the Memory Usage of Your Application](https://www.youtube.com/watch?v=FLcXf9pO27w)
3. [Java集合干货系列](http://www.jianshu.com/p/2cd7be850540)
4. [Arrays.asList()返回的List不是jva.util.ArrayList](http://www.programcreek.com/2014/01/java%E7%A8%8B%E5%BA%8F%E5%91%98%E5%B8%B8%E7%8A%AF%E7%9A%8410%E4%B8%AA%E9%94%99%E8%AF%AF/)
5. [WeakHashMap和HashMap的区别](http://blog.csdn.net/yangzl2008/article/details/6980709)
6. [Hashmap的死锁问题](https://zhuanlan.zhihu.com/p/31614195)
7. [Young Pups: New Collections APIs for Java 9 by Stuart Marks](https://www.youtube.com/watch?v=OJrIMv4dAek)
