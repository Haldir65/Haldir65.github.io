---
title: bytecode基本解读
date: 2018-12-12 11:11:02
tags: [java,tbd]
---

python中可以使用diss module 轻易的查看byte code。那么在java中呢
![](https://api1.foster57.tk/static/imgs/BadlandsBday_EN-AU10299777329_1920x1080.jpg)
<!--more-->

interpreting the talk from 
[Sinking Your Teeth Into Bytecode](https://jakewharton.com/sinking-your-teeth-into-bytecode/)


java 有一个关键字叫做goto，在java代码中好像不能用，但是其实在生成的bytecode里面有goto关键字(c语言也有)

javap -c someclass
jmap等jdk的bin文件下面的功能

jps
jstack 12345 > thread.txt

JDK 中的 jps，jstat，jstack，jmap 很有用

[从反编译角度来看string常量池的问题](https://www.cnblogs.com/paddix/p/5326863.html)

invoke dynamic是第五种，jdk7加入的

## 参考
[JVM bytecode engineering 101](https://www.youtube.com/watch?v=lP4ED_dN16g)
[JVM Bytecode for Dummies (and the Rest of Us Too)](https://www.youtube.com/watch?v=rPyqB1l4gko)
[实例分析JAVA CLASS的文件结构](https://coolshell.cn/articles/9229.html)
[从字节码层面看“HelloWorld”](https://www.cnblogs.com/paddix/p/5282004.html)


### 39. javap一般用来反编译class文件
> javap Animal.class
> javap -c Animal.class  //直接看字节码
> javap -help 可以看更多命令行参数的含义

不过一般不这么直接看字节码，因为都是有规则的，已经有人做出了gui的工具，比如[jad](http://www.javadecompilers.com/jad)
> ./jad -sjava Animal.class

```java
public enum Animal {
    DOG,CAT
}

// 通过jad翻译过后的字节码其实长这样
public final class Animal extends Enum
{

    public static Animal[] values()
    {
        return (Animal[])$VALUES.clone();
    }

    public static Animal valueOf(String s)
    {
        return (Animal)Enum.valueOf(Animal, s);
    }

    private Animal(String s, int i)
    {
        super(s, i);
    }

    public static final Animal DOG;
    public static final Animal CAT;
    private static final Animal $VALUES[];

    static
    {
        DOG = new Animal("DOG", 0);
        CAT = new Animal("CAT", 1);
        $VALUES = (new Animal[] {
            DOG, CAT
        });
    }
}
```

## asm使用
ASM 是一个 Java 字节码操控框架。它能被用来动态生成类或者增强既有类的功能。ASM 可以直接产生二进制 class 文件，也可以在类被加载入 Java 虚拟机之前动态改变类行为。Java class 被存储在严格格式定义的 .class 文件里，这些类文件拥有足够的元数据来解析类中的所有元素：类名称、方法、属性以及 Java 字节码（指令）。ASM 从类文件中读入信息后，能够改变类行为，分析类信息，甚至能够根据用户要求生成新类。
[创建出一个class](https://blog.csdn.net/mn960mn/article/details/51418236)
fastjson在获取java bean的属性值的时候，为了避免反射，才使用的asm。fastjson中的asm是照着 org.objectweb的asm改造的。
fastjson中还有一段ThreadLocalCache，缓存了char数组，所以可以一定程度上避免大量的内存分配
[class文件结构以及使用asm教程](https://www.ibm.com/developerworks/cn/java/j-lo-asm30/)




## 参考
[美团技术博客关于java byte code 的介绍](https://tech.meituan.com/2019/09/05/java-bytecode-enhancement.html)
[jav-class-viewer](https://www.codeproject.com/Articles/35915/Java-Class-Viewer) 一个gui工具，能够非常直观地展示class文件的结构
