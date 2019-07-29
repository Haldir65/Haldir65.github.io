---
title: 堆外内存，weakHashMap以及四种引用类型的研究
date: 2019-07-28 22:34:37
tags: [java,tbd]
---

DiectByteBuffer（堆外内存）是分配在jvm以外的内存，这个java对象本身是受jvm gc控制的，但是其指向的堆外内存是如何回收的
![](https://www.haldir66.ga/static/imgs/JovianCloudscape_EN-AU11726040455_1920x1080.jpg)
<!--more-->




## weakHashMap 有一个ReferenceQueue的使用
WeakHashMap的核心定义是： 一旦key不再被外部持有，这个Entry将在未来的某一时刻被干掉
[oracle java doc for weakHashMap](https://docs.oracle.com/javase/8/docs/api/java/util/WeakHashMap.html)中提到，WeakHashMap的key最好是那种equals是直接使用==的，当然使用String这种比较实质内容的也可以。但会带来一些confusing的现象。
>
This class is intended primarily for use with key objects whose equals methods test for object identity using the == operator. Once such a key is discarded it can never be recreated, so it is impossible to do a lookup of that key in a WeakHashMap at some later time and be surprised that its entry has been removed. This class will work perfectly well with key objects whose equals methods are not based upon object identity, such as String instances. With such recreatable key objects, however, the automatic removal of WeakHashMap entries whose keys have been discarded may prove to be confusing.

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