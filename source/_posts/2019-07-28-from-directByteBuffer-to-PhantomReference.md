---
title: 堆外内存，weakHashMap以及四种引用类型的研究
date: 2019-07-28 22:34:37
tags: [java,tbd]
---

DirectByteBuffer（堆外内存）是分配在jvm以外的内存，这个java对象本身是受jvm gc控制的，但是其指向的堆外内存是如何回收的
![](https://www.haldir66.ga/static/imgs/JovianCloudscape_EN-AU11726040455_1920x1080.jpg)
<!--more-->


java中有四种引用

Strong Reference
Soft Reference （软引用）
Weak Reference （弱引用）
PhantomReference Reference（虚引用）

除了强引用，另外三个class都继承自Reference这个父类，其构造函数有两个
```java
//referent 为引用指向的对象
Reference(T referent) {
    this(referent, null);
}
//ReferenceQueue对象，可以简单理解为一个队列
//GC 在检测到appropriate reachability changes之后，
//会把引用对象本身添加到这个queue中，便于清理引用对象本身
Reference(T referent, ReferenceQueue<? super T> queue) {
    this.referent = referent;
    this.queue = (queue == null) ? ReferenceQueue.NULL : queue;
}
```

调用虚引用的get方法，总会返回null，与软引用和弱引用不同的是，虚引用被enqueued时，GC 并不会自动清理虚引用指向的对象，只有当指向该对象的所有虚引用全部被清理（enqueued后）后或其本身不可达时，该对象才会被清理。

如果一个对象只具有虚引用，那么它就和没有任何引用一样，任何时候都可能被gc回收。
软（弱、虚）引用必须和一个引用队列（ReferenceQueue）一起使用，当gc回收这个软（弱、虚）引用引用的对象时，会把这个软（弱、虚）引用放到这个引用队列中。
比如，上述的Entry是一个弱引用，它引用的对象是key，当key被回收时，Entry会被放到queue中。


## WeakHashMap 
```java
public class WeakHashMap<K,V>
    extends AbstractMap<K,V>
    implements Map<K,V> {

        private final ReferenceQueue<Object> queue = new ReferenceQueue<>();

    /**
     * Constructs a new, empty <tt>WeakHashMap</tt> with the default initial
     * capacity (16) and load factor (0.75).
     */
    public WeakHashMap() {
        this(DEFAULT_INITIAL_CAPACITY, DEFAULT_LOAD_FACTOR);
    }
    //这是openjdk1.8的源码
    //至少从构造函数可以看出来，默认的容量是16。

    }
```
值得注意的是内部有一个ReferenceQueue。
WeakHashMap的核心定义是： 一旦key不再被外部持有，这个Entry将在未来的某一时刻被干掉。
[oracle java doc for weakHashMap](https://docs.oracle.com/javase/8/docs/api/java/util/WeakHashMap.html)中提到，WeakHashMap的key最好是那种equals是直接使用==的，当然使用String这种equals是比较实际内容的也可以。但会带来一些confusing的现象。
>This class is intended primarily for use with key objects whose equals methods test for object identity using the == operator. Once such a key is discarded it can never be recreated, so it is impossible to do a lookup of that key in a WeakHashMap at some later time and be surprised that its entry has been removed. This class will work perfectly well with key objects whose equals methods are not based upon object identity, such as String instances. With such recreatable key objects, however, the automatic removal of WeakHashMap entries whose keys have been discarded may prove to be confusing.


在内部结构方面，和jdk1.7的HashMap差不多，都是拉链法来解决哈希冲突
WeakHashMap奇怪的点看下面这个例子就知道了
```java
public class TestWeakHashMap
{
    private String str1 = new String("newString1"); //this entry will be removed soon
    private String str2 = "literalString2";
    private String str3 = "literalString3";
    private String str4 = new String("newString4"); //this entry will be removed soon
    private Map map = new WeakHashMap();

     void testGC() throws IOException
    {
        map.put(str1, new Object());
        map.put(str2, new Object());
        map.put(str3, new Object());
        map.put(str4, new Object());

        /**
         * Discard the strong reference to all the keys
         */
        str1 = null;
        str2 = null;
        str3 = null;
        str4 = null;

        while (true) {
            System.gc();
            /**
             * Verify Full GC with the -verbose:gc option
             * We expect the map to be emptied as the strong references to
             * all the keys are discarded.
             */
            System.out.println("map.size(); = " + map.size() + "  " + map);
            // map.size(); = 2  {literalString3=java.lang.Object@266474c2, literalString2=java.lang.Object@6f94fa3e}
        }
    }

    public static void main(String[] args) {
        try {
            new TestWeakHashMap().testGC();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```
这里提一句，如果是用string.intern搞出来的key，那么永远都不会被移除。

WeakHashMap看上去就像有一条专门的线程在后台悄悄的清理那些key已经没有其他引用的Entry。
这个清理Entry的方法叫做expungeStaleEntries，就是专门用于清除那些失效的Entry的。WeakHashmap中的key被包进一个WeakReference中，**当这个reference出现在ReferenceQueue中的时候，就意味着这个key已经没有地方用到了**。但是这个WeakReference对象还要干掉，expungeStaleEntries就是从queue中取出所有的WeakReference(Entry)，这里当然不会调用WeakReference的get方法，而是使用hash，找到其在tables中的位置，再从链表中找到这个entry，null掉value(因为value被entry强引用，这一步只是帮助gc)，将这个entry从链表中移除。(那么这个WeakReference对象就彻底没有任何引用了，后面gc会free掉这部分的memory)

这个方法会在很多方法里直接或者间接调用到
put,get,size,remove几乎所有的crud方法都会在方法的最开头调用这个方法来移除stale的Entry。

上面说到**好像有一条线程专门在后台悄悄的把不用的reference放到queue里面**，这条线程是存在的。
java.lang.ref.Reference.ReferenceHandler,是Reference的private static 内部class
```java
 /* High-priority thread to enqueue pending References
     */
private static class ReferenceHandler extends Thread {
   public void run() {
            while (true) {
                tryHandlePending(true);
            }
        }
}


//上面的注释提到high priority，多高的优先级呢。
//这段话写在Reference.java里面
 static {
        ThreadGroup tg = Thread.currentThread().getThreadGroup();
        for (ThreadGroup tgn = tg;
             tgn != null;
             tg = tgn, tgn = tg.getParent());
        Thread handler = new ReferenceHandler(tg, "Reference Handler");
        /* If there were a special system-only priority greater than
         * MAX_PRIORITY, it would be used here
         */
        handler.setPriority(Thread.MAX_PRIORITY); //总之就是很高的优先级
        handler.setDaemon(true); // 守护线程一般在程序运行的时候在后台提供一种通用服务的线程
        handler.start();
}

```

## 重点:
四种状态(出处见参考)

每一时刻，Reference对象都处于下面四种状态中。这四种状态用Reference的成员变量queue与next（类似于单链表中的next）来表示。


> ReferenceQueue<? super T> queue;
Reference next;

- <font color="red">Active</font>。新创建的引用对象都是这个状态，在 GC 检测到引用对象已经到达合适的reachability时，GC 会根据引用对象是否在创建时制定ReferenceQueue参数进行状态转移，如果指定了，那么转移到Pending，如果没指定，转移到Inactive。在这个状态中

> //如果构造参数中没指定queue，那么queue为ReferenceQueue.NULL，否则为构造参数中传递过来的queue
queue = ReferenceQueue || ReferenceQueue.NULL
next = null

- <font color="orange">Pending</font>。pending-Reference列表中的引用都是这个状态，它们等着被内部线程ReferenceHandler处理（会调用ReferenceQueue.enqueue方法）。没有注册的实例不会进入这个状态。在这个状态中

> //构造参数参数中传递过来的queue
queue = ReferenceQueue
next = 该queue中的下一个引用，如果是该队列中的最后一个，那么为this

- <font color="green">Enqueued</font>。调用ReferenceQueue.enqueued方法后的引用处于这个状态中。没有注册的实例不会进入这个状态(就是没有走两个参数的构造函数的那种)。在这个状态中
>queue = ReferenceQueue.ENQUEUED
next = 该queue中的下一个引用，如果是该队列中的最后一个，那么为this

- <font color="blue">Inactive</font>。最终状态，处于这个状态的引用对象，状态不会再改变。在这个状态中
>queue = ReferenceQueue.NULL
next = this

有了这些约束，GC 只需要检测next字段就可以知道是否需要对该引用对象采取特殊处理

>如果next为null，那么说明该引用为Active状态
如果next不为null，那么 GC 应该按其正常逻辑处理该引用（就是走加入queue那一套）。

### 如果构造函数中指定了ReferenceQueue，那么事后程序员可以通过该队列清理引用
### 如果构造函数中没有指定了ReferenceQueue，那么 GC 会自动清理引用

***tryHandlePending会将当前的static的一个Reference(pending)加入到r.queue里面,同时设置pending为pending.discovered。(这个discovered是vm赋值的，gc给java层留了个口子，将没有其他引用的Reference赋值到这里了，前提是Reference是调用带ReferenceQueue的构造函数创建的)***
这里头肯定有jni调用，具体原理不清楚。


tryHandlePending判断提取出来的Reference是否是Cleaner这个class，
如果是的话，直接调用Cleaner.clean（）
否则执行将这个Reference加入到Queue（这个Reference的Queue）里面

```java
public class Cleaner
    extends PhantomReference<Object>
{
    // cleaner一般用这种静态函数创建出来可以认为是提供一个回调了
    public static Cleaner create(Object ob, Runnable thunk) {
        if (thunk == null)
            return null;
        return add(new Cleaner(ob, thunk));
    }
}
```
至于为什么tryHandlePending这个方法从这个链表里面捞元素的时候会捞出来一个Cleaner呢，因为Cleaner都是这么创建出来的，都是用带Queue的构造函数创建的。
```java
private Cleaner(Object referent, Runnable thunk) {
    super(referent, dummyQueue); //这个Super是PhantomReference，再往上是Reference
    this.thunk = thunk;
}
```
PhantomReference是最弱的引用了。
DirectByteBuffer是这样创建Cleaner的：

> cleaner = Cleaner.create(this, new Deallocator(base, size, cap));

Deallocator的run方法里面就是调用Unsafe的方法根据address去free内存
，这就是nio的DirectByteBuffer是如何管理堆外内存的原理了。

于是stackoverflow上就出现了"如何释放DirectByteBuffer的native memory"的方案

```java
import sun.misc.Cleaner;
import sun.nio.ch.DirectBuffer;

public static void clean(ByteBuffer bb) {
    if(bb == null) return;
    Cleaner cleaner = ((DirectBuffer) bb).cleaner();
    if (cleaner != null) cleaner.clean();
}
```

```java
import sun.misc.Cleaner;
import java.lang.reflect.Field;
import java.nio.ByteBuffer;
...

public static void main(String[] args) throws Exception {
    ByteBuffer direct = ByteBuffer.allocateDirect(1024);
    Field cleanerField = direct.getClass().getDeclaredField("cleaner");
    cleanerField.setAccessible(true);
    Cleaner cleaner = (Cleaner) cleanerField.get(direct);
    cleaner.clean();
}
```
不注意就用到了sun的package了，因为sun.xxx这些package下面的class都是在rt.jar里面，由BootStrapClassLaoder加载，所以可以使用这个package。不过好像java9开始sun这个包下面的东西默认不能用了。


### 经验
1. WeakHashMap的key倾向于使用那种equals是直接比较==的，而不是自己实现hashCode的那一套
2. debug的时候有时候会看见“Reference Handler”这么一条线程，就是负责迭代引用链表的
3. Reference的构造函数如果传入了ReferenceQueue，相当于给这个Reference的gc事件挂了个钩子,大致相当于reference.addWillGCListener，DirectByteBuffer就是这么干的。很熟悉是吗，finalizer（只是更加轻量级）。
4. WeakHashMap的value是强引用，不要去持有key。

### 最后

从注释里面可以看出来，java.lan.ref这下面的很多class是Mark Reinhold写的。

Mark Reinhold is Chief Architect of the Java Platform Group at Oracle. His past contributions to the platform include character-stream readers and writers, reference objects, shutdown hooks, the NIO high-performance I/O APIs, library generification, and service loaders. Mark was the lead engineer for the JDK 1.2 and 5.0 releases, the JCP specification lead for Java SE 6, and both the project and specification lead for JDK 7 (Java SE 7) and JDK 8 (Java SE 8). He currently leads the JDK 9 and Jigsaw projects in the OpenJDK Community, where he also serves on the Governing Board. Mark holds a Ph.D. in computer science from the Massachusetts Institute of Technology.

Brian Goetz is the Java Language Architect at Oracle, and was the specification lead for JSR-335 (Lambda Expressions for the Java Programming Language.) He is the author of the best-selling Java Concurrency in Practice, as well as over 75 articles on Java development, and has been fascinated by programming since Jimmy Carter was President.




## 参考
[java WeakHashMap](https://liujiacai.net/blog/2015/09/27/java-weakhashmap/)


