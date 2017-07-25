---
title: java对象内存占用分析
date: 2017-07-23 19:02:52
tags: [java]
---


![](http://odzl05jxx.bkt.clouddn.com/9b157a7acab582078ac1fabada5c8009.jpg?imageView2/2/w/600)
面向对象语言就意味着对象要占用内存空间，那么，java中随便new 出来的东西到底多大？还有，new出来的东西全都都放在heap上吗？
<!--more-->
首先给出java中各种primitive types的大小。
![](http://odzl05jxx.bkt.clouddn.com/java_primitives_size.png)
首先给出一个判断Java Object大小的方法
比较精准的确定一个对象的大小的[方法](https://github.com/liaohuqiu/java-object-size):


```java
public class ObjectSizeFetcher {

    private static Instrumentation instrumentation;

    public static void premain(String args, Instrumentation inst) {
        instrumentation = inst;
    }

    public static long getObjectSize(Object o) {
        return instrumentation.getObjectSize(o);
    }
}



public class TestSize {

    public static void main(String[] args) throws IOException {
        TestObject1 testObject1 = new TestObject1();
        TestObject2 testObject2 = new TestObject2();

        System.out.printf("size of object with int: %s\n", ObjectSizeFetcher.getObjectSize(testObject1));
        System.out.printf("size of object with 2 int: %s\n", ObjectSizeFetcher.getObjectSize(testObject2));
        System.out.printf("size of HashMapEntry: %s\n", ObjectSizeFetcher.getObjectSize(new HashMapEntry<String, String>("", "", 0, null)));
        System.out.printf("size of SimpleHashMapEntry: %s\n", ObjectSizeFetcher.getObjectSize(new SimpleHashSetEntry<String>(0, null)));
        System.out.println("wait");
        System.in.read();
    }

    static class HashMapEntry<K, V> {
        final K key;
        final int hash;
        V value;
        HashMapEntry<K, V> next;

        HashMapEntry(K key, V value, int hash, HashMapEntry<K, V> next) {
            this.key = key;
            this.value = value;
            this.hash = hash;
            this.next = next;
        }
    }

    static class SimpleHashSetEntry<T> {

        private int mHash;
        private T mKey;
        private SimpleHashSetEntry<T> mNext;

        private SimpleHashSetEntry(int hash, T key) {
            mHash = hash;
            mKey = key;
        }
    }

    private static class TestObject1 {
        private int mInt1;
    }

    private static class TestObject2 {
        private int mInt1;
        private int mInt2;
    }
}

```



