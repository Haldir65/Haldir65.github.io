---
title: pragmatic-java-chetsheet
date: 2018-07-05 23:05:52
tags: [java]
---

![](https://haldir66.ga/static/imgs/20160720094529840.jpg)
<!--more-->

## 反射

> 如何获得一个class对象

```java
Class class1 = null;
Class class2 = null;
Class class3 = null;
try {
    class1 = Class.forName("com.example.test.javareflect.ReflectClass");
    // java语言中任何一个java对象都有getClass 方法
    class2 = new ReflectClass().getClass();
    //java中每个类型都有class 属性
    class3 = ReflectClass.class;
    // 由于class是单例，所以class1 == class2 == class3
} catch (ClassNotFoundException e) {
    e.printStackTrace();
}
```

> 如何检查一个Class中的所有constructor

```java
package com.me.reflection._001_basic;

public class MyObject {
    public String name;
    public int age;

    public MyObject(String name) {
        this.name = name;
    }

    public MyObject(String name, int age) {
        this.name = name;
        this.age = age;
    }

    public MyObject(int age) {
        this.age = age;
    }

    public MyObject() {
    }
}

 public void checkInitParams(){
        Constructor<?> constructor[] = MyObject.class.getConstructors();
        for (int i = 0; i < constructor.length; i++) { // 运行期这个length是4，如果上面的Object中不手动添加构造函数的话，这个数是1
            Class arrayClass[] = constructor[i].getParameterTypes();
            System.out.print("cons[" + i + "] (");
            for (int j = 0; j < arrayClass.length; j++) {
                if (j == arrayClass.length - 1)
                    System.out.print(arrayClass[j].getName());
                else
                    System.out.print(arrayClass[j].getName() + ", ");
            }
            System.out.println(")");
        }
    }
```
输出(我怀疑这个顺序是按照字母顺序来的)
>cons[0] ()
cons[1] (int)
cons[2] (java.lang.String, int)
cons[3] (java.lang.String)


> 实例化一个object，假设有很多个构造函数的话

```java
    public void createViaReflection(){
        String className = "com.me.reflection._001_basic.MyObject";
        try {
            Class clazz = Class.forName(className);
            Constructor cons = clazz.getConstructor(String.class); //我们希望要获得一个String参数的构造函数
            Object obj = cons.newInstance("passing value via constructor is ok -ish");
            System.out.println(obj);
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        } catch (NoSuchMethodException e) {
            e.printStackTrace();
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        } catch (InstantiationException e) {
            e.printStackTrace();
        } catch (InvocationTargetException e) {
            e.printStackTrace();
        }
    }
```
> MyObject{name='passing value via constructor is ok -ish', age=0}

> 获取一个class中所有的Fileds（private的也能拿到）


```java
    public void getAllFields(){
        try {
            String className = "com.me.reflection._001_basic.MyObject";
            Class rClass = Class.forName(className);
            // Field: 获取属性，下面还会讲到获取类的方法，注意区分
            Field field[] = rClass.getDeclaredFields();
            for (int i = 0; i < field.length; i++) {
                System.out.println(field[i].getName());
                // 获取修饰权限符
                int mo = field[i].getModifiers();
                System.out.println("mo: "+mo);
                String priv = Modifier.toString(mo);
                // 属性类型
                Class type = field[i].getType();
                System.out.println(priv + " " + type.getName() + " " + field[i].getName());
            }
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
    }
```
输出：
>name
mo: 1
public java.lang.String name
age
mo: 2
private int age

> 获得一个class中所有的方法(拿不到private的和构造函数，父类的wait,notfy这些反而能够拿到),getMethod只能拿到public的方法，getDeclaredMethod基本上是什么类型的都能拿到(getDeclaredMethods，有个s)

```java
    public void getAllMethods(){
        try {
            String className = "com.me.reflection._001_basic.MyObject";
            Class fClass = Class.forName(className);
            // Method[]: 方法数组
            Method method[] = fClass.getMethods();
            for (int i = 0; i < method.length; i++) {
                // returnType :返回类型
                Class returnType = method[i].getReturnType();
                System.out.println("ReturnType: "+returnType);
                // 获取参数类型
                Class para[] = method[i].getParameterTypes();

                int temp = method[i].getModifiers();
                System.out.print("Modifier.toString: "+Modifier.toString(temp) + " ");
                System.out.print(returnType.getName() + "  ");
                System.out.print(method[i].getName() + " ");
                System.out.print("(");
                for (int j = 0; j < para.length; ++j) {
                    System.out.print(para[j].getName() + " " + "arg" + j);
                    if (j < para.length - 1) {
                        System.out.print(",");
                    }
                }
                // 获取异常类型
                Class<?> exce[] = method[i].getExceptionTypes();
                if (exce.length > 0) {
                    System.out.print(") throws ");
                    for (int k = 0; k < exce.length; ++k) {
                        System.out.print(exce[k].getName() + " ");
                        if (k < exce.length - 1) {
                            System.out.print(",");
                        }
                    }
                } else {
                    System.out.print(")");
                }
                System.out.println();
            }
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
}
```
测试下来，这个方法能够拿到自己写的public方法，private方法似乎拿不到,还有，这里面似乎拿不到构造函数

> ReturnType: void
Modifier.toString: public final void  wait (long arg0,int arg1) throws java.lang.InterruptedException 
ReturnType: void
Modifier.toString: public final native void  wait (long arg0) throws java.lang.InterruptedException 
ReturnType: void
Modifier.toString: public final void  wait () throws java.lang.InterruptedException 
ReturnType: boolean
Modifier.toString: public boolean  equals (java.lang.Object arg0)
ReturnType: class java.lang.String
Modifier.toString: public java.lang.String  toString ()
ReturnType: int
Modifier.toString: public native int  hashCode ()
ReturnType: class java.lang.Class
Modifier.toString: public final native java.lang.Class  getClass ()
ReturnType: void
Modifier.toString: public final native void  notify ()
ReturnType: void
Modifier.toString: public final native void  notifyAll ()


拿到方法（Method对象之后就要invoke了），不管是private还是public的
```java
// 假设我们的class有这么两个方法,也是可以区分开来的
public void echo(String name){
    System.out.println(name);
}

public void echo(){
    System.out.println("some kind of echo ");
}


 public void callMethodViaReflection(){
        String className = "com.me.reflection._001_basic.MyObject";
        try {
            Class<?> fClass = Class.forName(className);
            Method method = fClass.getDeclaredMethod("greet");
            method.setAccessible(true); //如果这是一个private的method的话，要setAccessible
            method.invoke(fClass.newInstance());

            Method public_method_with_params = fClass.getMethod("echo",String.class);
            public_method_with_params.invoke(fClass.newInstance(),"this is params from reflection");

            Method public_method_without_params = fClass.getMethod("echo");
            public_method_without_params.invoke(fClass.newInstance());

        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        } catch (NoSuchMethodException e) {
            e.printStackTrace();
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        } catch (InstantiationException e) {
            e.printStackTrace();
        } catch (InvocationTargetException e) {
            e.printStackTrace();
        }
    }
```
hello method without parameters
this is params from reflection
some kind of echo 

>用反射给class的某个field赋值

```java

    public void setFiledWithReflection(){
        String className = "com.me.reflection._001_basic.MyObject";
        try {
            Class clss = Class.forName(className);
            Object obj = clss.newInstance();
            Field field = clss.getDeclaredField("name");
            field.setAccessible(true);
            System.out.println(field.get(obj));

            field.set(obj,"this is some reflected filed");
            System.out.println(field.get(obj));

        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        } catch (InstantiationException e) {
            e.printStackTrace();
        } catch (NoSuchFieldException e) {
            e.printStackTrace();
        }
    }
```

反射相关的东西基本到此完事，实际生产中当然推荐使用成熟的框架，比如**Spring Framework的ReflectionUtils**.当然有些东西是没法用反射去修改的（用InvocationHandler只是夹带了私活），比如函数的内部逻辑，比如常量(因为编译器直接把常量换成对应的值了)。

比如从Tinker的代码库里面抄来这么一段：
```java
/**
     * Locates a given field anywhere in the class inheritance hierarchy.
     *
     * @param instance an object to search the field into.
     * @param name     field name
     * @return a field object
     * @throws NoSuchFieldException if the field cannot be located
     */
    public static Field findField(Object instance, String name) throws NoSuchFieldException {
        for (Class<?> clazz = instance.getClass(); clazz != null; clazz = clazz.getSuperclass()) {
            try {
                Field field = clazz.getDeclaredField(name);

                if (!field.isAccessible()) {
                    field.setAccessible(true);
                }

                return field;
            } catch (NoSuchFieldException e) {
                // ignore and search next
            }
        }

        throw new NoSuchFieldException("Field " + name + " not found in " + instance.getClass());
    }

    public static Field findField(Class<?> originClazz, String name) throws NoSuchFieldException {
        for (Class<?> clazz = originClazz; clazz != null; clazz = clazz.getSuperclass()) {
            try {
                Field field = clazz.getDeclaredField(name);

                if (!field.isAccessible()) {
                    field.setAccessible(true);
                }

                return field;
            } catch (NoSuchFieldException e) {
                // ignore and search next
            }
        }

        throw new NoSuchFieldException("Field " + name + " not found in " + originClazz);
    }

    /**
     * Locates a given method anywhere in the class inheritance hierarchy.
     *
     * @param instance       an object to search the method into.
     * @param name           method name
     * @param parameterTypes method parameter types
     * @return a method object
     * @throws NoSuchMethodException if the method cannot be located
     */
    public static Method findMethod(Object instance, String name, Class<?>... parameterTypes)
        throws NoSuchMethodException {
        for (Class<?> clazz = instance.getClass(); clazz != null; clazz = clazz.getSuperclass()) {
            try {
                Method method = clazz.getDeclaredMethod(name, parameterTypes);

                if (!method.isAccessible()) {
                    method.setAccessible(true);
                }

                return method;
            } catch (NoSuchMethodException e) {
                // ignore and search next
            }
        }

        throw new NoSuchMethodException("Method "
            + name
            + " with parameters "
            + Arrays.asList(parameterTypes)
            + " not found in " + instance.getClass());
    }

    /**
     * Locates a given method anywhere in the class inheritance hierarchy.
     *
     * @param clazz          a class to search the method into.
     * @param name           method name
     * @param parameterTypes method parameter types
     * @return a method object
     * @throws NoSuchMethodException if the method cannot be located
     */
    public static Method findMethod(Class<?> clazz, String name, Class<?>... parameterTypes)
            throws NoSuchMethodException {
        for (; clazz != null; clazz = clazz.getSuperclass()) {
            try {
                Method method = clazz.getDeclaredMethod(name, parameterTypes);

                if (!method.isAccessible()) {
                    method.setAccessible(true);
                }

                return method;
            } catch (NoSuchMethodException e) {
                // ignore and search next
            }
        }

        throw new NoSuchMethodException("Method "
                + name
                + " with parameters "
                + Arrays.asList(parameterTypes)
                + " not found in " + clazz);
    }

    /**
     * Locates a given constructor anywhere in the class inheritance hierarchy.
     *
     * @param instance       an object to search the constructor into.
     * @param parameterTypes constructor parameter types
     * @return a constructor object
     * @throws NoSuchMethodException if the constructor cannot be located
     */
    public static Constructor<?> findConstructor(Object instance, Class<?>... parameterTypes)
            throws NoSuchMethodException {
        for (Class<?> clazz = instance.getClass(); clazz != null; clazz = clazz.getSuperclass()) {
            try {
                Constructor<?> ctor = clazz.getDeclaredConstructor(parameterTypes);

                if (!ctor.isAccessible()) {
                    ctor.setAccessible(true);
                }

                return ctor;
            } catch (NoSuchMethodException e) {
                // ignore and search next
            }
        }

        throw new NoSuchMethodException("Constructor"
                + " with parameters "
                + Arrays.asList(parameterTypes)
                + " not found in " + instance.getClass());
    }
```

和反射相关的类应该还有Type，关于Type，最有名的就是从一个泛型类中获取泛型里面T的class对象。但这是有条件的。需要泛型定义在一个父类上，子类对象在初始化的时候确定一个T,后面就可以通过这个子类对象的实例来获得刚才这个T的class.
```java
 Class<?> classType = Integer.TYPE; //这其实是一个class

 // 从泛型class中获取T的类型
public void someMethod(){
    HashMap<String,Integer> map = new HashMap<String, Integer>(){};
    Type mySuperclass = map.getClass().getGenericSuperclass();
    Type type = ((ParameterizedType)mySuperclass).getActualTypeArguments()[0];
    Type type2 = ((ParameterizedType)mySuperclass).getActualTypeArguments()[1];
    System.out.println(mySuperclass);// java.util.HashMap<java.lang.String, java.lang.Integer>
    System.out.println(type+" "+type2); //class java.lang.String class java.lang.Integer
}

public void someMethod2(){
    HashMap<String,Integer> map = new HashMap<>(); // 类型擦除
    Type mySuperclass = map.getClass().getGenericSuperclass();
    Type type = ((ParameterizedType)mySuperclass).getActualTypeArguments()[0];
    Type type2 = ((ParameterizedType)mySuperclass).getActualTypeArguments()[1];
    System.out.println(mySuperclass); // java.util.AbstractMap<K, V>
    System.out.println(type+" "+type2); //K V
}


// 或者

public static abstract class Foo<T> {
    //content
}

public static class FooChild extends Foo<String> {
    //content
}

public static Type[] getParameterizedTypes(Object object) {
    Type superclassType = object.getClass().getGenericSuperclass();
    if (!ParameterizedType.class.isAssignableFrom(superclassType.getClass())) {
        return null;
    }
    return ((ParameterizedType)superclassType).getActualTypeArguments();
}

public static void main(String[] args) {
        Foo foo = new FooChild();
        Type[] types=  getParameterizedTypes(foo);
        System.out.println(types[0] == String.class); // true ,Type是一个接口，实现类只有Class
    }
```
看下来都是需要一个支持泛型的父类，然后子类继承这个父类并指定泛型中的T是哪个class，外部就可以拿着这个父类的指针(指向填充了T类型的子类的Object)调用getGenericSuperclass方法再转成ParameterizedType去调用getActualTypeArguments方法了。

这里面涉及到的类和接口包括:
ParameterizedType,TypeVariable,GenericArrayType,WildcardType（这四个全部是接口）等
[Type详解](http://loveshisong.cn/%E7%BC%96%E7%A8%8B%E6%8A%80%E6%9C%AF/2016-02-16-Type%E8%AF%A6%E8%A7%A3.html)
由于类型擦除，class对象中并不能保有编译前的类的信息，引入Type似乎是为了迎合反射的需要。


### nio及DirectByteBuffer相关操作
[以下内容来自知乎专栏](https://zhuanlan.zhihu.com/p/27625923)的复制粘贴
nio包含了很多东西，核心的应该是selector
DirectBuffer这个东西很容易讲，一句话就能说清楚：这是一块在Java堆外分配的，可以在Java程序中访问的内存。
先来解释一下几个堆是什么。以32位系统为例（64位系统也是一样的，只是地址空间更大而已，写起来没有32位系统看上去那么简洁），操作系统会为一个进程提供4G的地址空间，换句话说，一个进程可用的内存是4G。在Linux上，又为内核空间留了1G，剩下的3G是可以供用户使用的(粗略来看是这样的)。这1G就叫做内核空间，3G被称为用户空间。
一个java进程下不过对于操作系统而言，肯定是一个用户进程。所以jva也就有了这3G的使用权。jvm想要使用这些内存的时候，会使用malloc方法去找操作系统去要（其实中间还隔了一个C runtime，我们不去管这个细节，只把malloc往下都看成是操作系统的功能，并不会带来太大的问题）
而JVM要来的这些的内存，有一块是专门供Java程序创建对象使用的，这块内存在JVM中被称为堆(heap)。堆这个词快被用烂了，操作系统有堆的概念，C runtime也有，JVM里也有，然后还有一种数据结构也叫堆（参看本课程堆排序部分），为了区别，我在以后的文章里只称JVM中的堆为Java堆。关于Java堆的结构和管理，在后面GC调优部分，我会详细地讲，这里我只介绍一下本节课所需要的内容。
我们使用普通的ByteBuffer，那么这个ByteBuffer就会在Java堆内，被JVM所管理：
```java
ByteBuffer buf = ByteBuffer.allocate(1024);
```
在执行GC的时候，JVM实际上会做一些整理内存的工作，也就说buf这个对象在内存中的实际地址是会发生变化的。有些时候，ByteBuffer里都是大量的字节，这些字节在JVM GC整理内存时就显得很笨重，把它们在内存中拷来拷去显然不是一个好主意。
那这时候，我们就会想能不能给我一块内存，可以脱离JVM的管理呢？在这样的背景下，就有了DirectBuffer。先看一下用法：
```java
ByteBuffer buf = ByteBuffer.allocateDirect(1024);
```
这两个函数的实现是有区别的:
```java
public static ByteBuffer allocateDirect(int capacity) {
        return new DirectByteBuffer(capacity);
    }

    public static ByteBuffer allocate(int capacity) {
        if (capacity < 0)
            throw new IllegalArgumentException();
        return new HeapByteBuffer(capacity, capacity);
    }
```
DirectByteBuffer的核心就是调用了 unsafe.allocateMemory(size)方法。
Java对象在Java堆里申请内存的时候，实际上是比malloc要快的，所以DirectBuffer的创建效率往往是比Heap Buffer差的。
但是，如果进行网络读写或者文件读写的时候，DirectBuffer就会比较快了，说起来好笑，这个快是因为JDK故意把非DirectBuffer的读写搞慢的，我们看一下JDK的源代码。
share/classes/sun/nio/ch/IOUtil.java
```java
static int write(FileDescriptor fd, ByteBuffer src, long position,
                     NativeDispatcher nd) 
        throws IOException
    {   
        if (src instanceof DirectBuffer)
            return writeFromNativeBuffer(fd, src, position, nd);

        // Substitute a native buffer
        int pos = src.position();
        int lim = src.limit();
        assert (pos <= lim);
        int rem = (pos <= lim ? lim - pos : 0); 
        ByteBuffer bb = Util.getTemporaryDirectBuffer(rem);
        try {
            bb.put(src);
            bb.flip();
        // ................略
```
如果src是DirectBuffer，就直接调用writeFromNativeBuffer，如果不是，则要先创建一个临时的DirectBuffer，把src拷进去，然后再调用真正的写操作。为什么要这么干呢？还是要从DirectBuffer不会被GC移动说起。writeFromNativeBuffer的实现，最终会把Buffer的address传给操作系统，让操作系统把address开始的那一段内存发送到网络上。这就要求在操作系统进行发送的时候，这块内存是不能动的(jni调用传递的是地址，地址不能乱动)。而我们知道，GC是会乱搬Java堆里的东西的，所以无奈，我们必须得弄一块地址不会变化的内存，然后把这个地址发给操作系统。


常用的ByteBuffer本质上是一个byte[]，包括这么几个变量
容量（Capacity） 缓冲区能够容纳的数据元素的最大数量。容量在缓冲区创建时被设定，并且永远不能被改变。
上界（Limit） 缓冲区里的数据的总数，代表了当前缓冲区中一共有多少数据。
位置（Position） 下一个要被读或写的元素的位置。Position会自动由相应的 get( )和 put( )函数更新。
标记（Mark） 一个备忘位置。用于记录上一次读写的位置。一会儿，我会通过reset方法来说明这个属性的含义。
ByteBuffer是一个抽象类，不能new出来
```java
ByteBuffer byteBuffer = ByteBuffer.allocate(256);
```
以上的语句可以创建一个大小为256字节的ByteBuffer，此时，mark = -1, pos = 0, limit = 256, capacity = 256。capacity在初始化的时候确定了，运行时就不会再变化了，而另外三个变量是随着程序的执行而不断变化的。

由于本质上就是一个byte[]，读数据的时候position放到0, limit放到当前已经存放的数据的位置，读完为止。写数据的时候也差不多，position放到当前已经存放的数据的curIndex+1，limit放到capicity的位置，填满为止。

从读变成写可以这么干
```java
byteBuffer.limit(byteBuffer.position())
byteBuffer.position(0);

//由于这个方法实在太频繁,jdk就帮忙封装了一个叫做flip的方法
public final Buffer flip() {
        limit = position;
        position = 0;
        mark = -1;
        return this;
    }
```
显然连续调用flip会导致limit变成0，不能读也不能写了。
mark方法类似于打一个标记，待会儿通过reset回到这个position。


### java的byte数组在内存层面不一定是连续的，C的是连续的
原因是GC会挪动内存

## nio的channel
在Java IO中，基本上可以分为文件类和Stream类两大类。Channel 也相应地分为了FileChannel 和 Socket Channel，其中 socket channel 又分为三大类，一个是用于监听端口的ServerSocketChannel，第二类是用于TCP通信的SocketChannel，第三类是用于UDP通信的DatagramChannel。channel 最主要的作用还是用于非阻塞式读写。可以使用Channel结合ByteBuffer进行读写。
一个简单的client server echo程序可以这样写
```java
// server

public class WebServer {
    public static void main(String args[]) {
        try {
            ServerSocketChannel ssc = ServerSocketChannel.open();
            ssc.socket().bind(new InetSocketAddress("127.0.0.1", 8000));
            SocketChannel socketChannel = ssc.accept();

            ByteBuffer readBuffer = ByteBuffer.allocate(128);
            socketChannel.read(readBuffer);

            readBuffer.flip();
            while (readBuffer.hasRemaining()) {
                System.out.println((char)readBuffer.get());
            }

            socketChannel.close();
            ssc.close();
        }
        catch (IOException e) {
            e.printStackTrace();
        }
    }
}

// client
public class WebClient {
    public static void main(String[] args) {
        SocketChannel socketChannel = null;
        try {
            socketChannel = SocketChannel.open();
            socketChannel.connect(new InetSocketAddress("127.0.0.1", 8000));

            ByteBuffer writeBuffer = ByteBuffer.allocate(128);
            writeBuffer.put("hello world".getBytes());

            writeBuffer.flip();
            socketChannel.write(writeBuffer);
            socketChannel.close();
        } catch (IOException e) {
        }
    }
}
```



todo
反编译java代码的基本套路
[有直接去看hotspot源码来分析的](https://www.zhihu.com/question/60892134)


![](https://www.haldir66.ga/static/imgs/1279081126453.jpg)

