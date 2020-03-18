---
title: pragmatic-java-chetsheet
date: 2018-07-05 23:05:52
tags: [java]
---

![](https://api1.foster66.xyz/static/imgs/20160720094529840.jpg)
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


拿到方法(Method对象之后就要invoke了)，不管是private还是public的
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
[Type详解](http://loveshisong.cn/编程技术/2016-02-16-Type详解.html)
由于类型擦除，class对象中并不能保有编译前的类的信息，引入Type似乎是为了迎合反射的需要。


### ClassLoader的使用套路
classloader和class的生命周期,[知乎专栏](https://zhuanlan.zhihu.com/p/51374915)
```
JVM 中内置了三个重要的 ClassLoader，分别是 BootstrapClassLoader、ExtensionClassLoader 和 AppClassLoader。
BootstrapClassLoader 负责加载 JVM 运行时核心类，这些类位于 JAVA_HOME/lib/rt.jar 文件中，我们常用内置库 java.xxx.* 都在里面，比如 java.util.*、java.io.*、java.nio.*、java.lang.* 等等。这个 ClassLoader 比较特殊，它是由 C 代码实现的，我们将它称之为「根加载器」。

ExtensionClassLoader 负责加载 JVM 扩展类，比如 swing 系列、内置的 js 引擎、xml 解析器 等等，这些库名通常以 javax 开头，它们的 jar 包位于 JAVA_HOME/lib/ext/*.jar 中，有很多 jar 包。

AppClassLoader 才是直接面向我们用户的加载器，它会加载 Classpath 环境变量里定义的路径中的 jar 包和目录。我们自己编写的代码以及使用的第三方 jar 包通常都是由它来加载的。

那些位于网络上静态文件服务器提供的 jar 包和 class文件，jdk 内置了一个 URLClassLoader，用户只需要传递规范的网络路径给构造器，就可以使用 URLClassLoader 来加载远程类库了。
ExtensionClassLoader 和 AppClassLoader 都是 URLClassLoader 的子类，它们都是从本地文件系统里加载类库。
```

双亲委派
```
AppClassLoader 在加载一个未知的类名时，它并不是立即去搜寻 Classpath，它会首先将这个类名称交给 ExtensionClassLoader 来加载，如果 ExtensionClassLoader 可以加载，那么 AppClassLoader 就不用麻烦了。否则它就会搜索 Classpath 。

而 ExtensionClassLoader 在加载一个未知的类名时，它也并不是立即搜寻 ext 路径，它会首先将类名称交给 BootstrapClassLoader 来加载，如果 BootstrapClassLoader 可以加载，那么 ExtensionClassLoader 也就不用麻烦了。否则它就会搜索 ext 路径下的 jar 包。

这三个 ClassLoader 之间形成了级联的父子关系，每个 ClassLoader 都很懒，尽量把工作交给父亲做，父亲干不了了自己才会干。每个 ClassLoader 对象内部都会有一个 parent 属性指向它的父加载器。
```

```java
$ cat ~/source/jcl/v1/Dep.java
public class Dep {
    public void print() {
        System.out.println("v1");
    }
}

$ cat ~/source/jcl/v2/Dep.java
public class Dep {
 public void print() {
  System.out.println("v1");
 }
}

$ cat ~/source/jcl/Test.java
public class Test {
    public static void main(String[] args) throws Exception {
        String v1dir = "file:///Users/qianwp/source/jcl/v1/";
        String v2dir = "file:///Users/qianwp/source/jcl/v2/";
        URLClassLoader v1 = new URLClassLoader(new URL[]{new URL(v1dir)});
        URLClassLoader v2 = new URLClassLoader(new URL[]{new URL(v2dir)});

        Class<?> depv1Class = v1.loadClass("Dep");
        Object depv1 = depv1Class.getConstructor().newInstance();
        depv1Class.getMethod("print").invoke(depv1);

        Class<?> depv2Class = v2.loadClass("Dep");
        Object depv2 = depv2Class.getConstructor().newInstance();
        depv2Class.getMethod("print").invoke(depv2);

        System.out.println(depv1Class.equals(depv2Class));
   }
}
```

上面的代码的运行结果是这样的
```
$ cd ~/source/jcl/v1
$ javac Dep.java
$ cd ~/source/jcl/v2
$ javac Dep.java
$ cd ~/source/jcl
$ javac Test.java
$ java Test
v1
v2
false
```



spi打破了双亲委派机制（如何在父加载器加载的类中，去调用子加载器去加载类？） 使用TThread.currentThread().getContextClassLoader()就可以实现在核心包里的基础类调用用户代码

反射替换final成员变量的时候要小心[一种全局拦截并监控 DNS 的方式](https://fucknmb.com/2018/04/16/一种全局拦截并监控DNS的方式/) 文中提到,要改一下Modifier的flag
```java
try {
    //获取InetAddress中的impl
    Field impl = InetAddress.class.getDeclaredField("impl");
    impl.setAccessible(true);
    //获取accessFlags
    Field modifiersField = Field.class.getDeclaredField("accessFlags");
    modifiersField.setAccessible(true);
    //去final
    modifiersField.setInt(impl, impl.getModifiers() & ~java.lang.reflect.Modifier.FINAL);
    //获取原始InetAddressImpl对象
    final Object originalImpl = impl.get(null);
    //构建动态代理InetAddressImpl对象
    Object dynamicImpl = Proxy.newProxyInstance(originalImpl.getClass().getClassLoader(), originalImpl.getClass().getInterfaces(), new InvocationHandler() {
        final Object lock = new Object();
        Constructor<Inet4Address> constructor = null;

        @Override
        public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
            //如果函数名为lookupAllHostAddr，并且参数长度为2，第一个参数是host，第二个参数是netId
            if (method.getName().equals("lookupAllHostAddr") && args != null && args.length == 2) {
                Log.e("TAG", "lookupAllHostAddr：" + Arrays.asList(args));
                //获取Inet4Address的构造函数，可能还需要Inet6Address的构造函数，为了演示，简单处理
                if (constructor == null) {
                    synchronized (lock) {
                        if (constructor == null) {
                            try {
                                constructor = Inet4Address.class.getDeclaredConstructor(String.class, byte[].class);
                                constructor.setAccessible(true);
                            } catch (Exception e) {
                                e.printStackTrace();
                            }
                        }
                    }
                }
                if (constructor != null) {
                    //这里实现自己的逻辑
                    //构造一个mock的dns解析并返回
                    if (args[0] != null && "www.baidu.com".equalsIgnoreCase(args[0].toString())) {
                        try {
                            Inet4Address inetAddress = constructor.newInstance(null, new byte[]{(byte) 61, (byte) 135, (byte) 169, (byte) 121});
                            return new InetAddress[]{inetAddress};
                        } catch (Exception e) {
                            e.printStackTrace();
                        }
                    }
                }
            }
            return method.invoke(originalImpl, args);
        }
    });
    //替换impl为动态代理对象
    impl.set(null, dynamicImpl);
    //还原final
    modifiersField.setInt(impl, impl.getModifiers() & java.lang.reflect.Modifier.FINAL);
} catch (Exception e) {
    e.printStackTrace();
}
```


classLoader在loadClass（无论是隐式的new XXX还是显式的classLoader.loadClass..）都会走缓存
缓存机制会将已经加载的class缓存起来，当程序中需要使用某个Class时，类加载器先从缓存区中搜寻该Class，只有当缓存中不存在该Class时，系统才会读取该类的二进制数据，并将其转换为Class对象，存入缓存中。这就是为什么更改了class后，需要重启JVM才生效的原因。

[能不能自己写个类叫java.lang.System？](https://blog.csdn.net/tang9140/article/details/42738433) 看了很多博客的摘抄，意思是不可能。进一步说,java.lang.xxx，甚至是java.xxx.xxx都不可能。
原因在java.lang.ClassLoader这个文件中有一个preDefineClass方法，
```java
// Note:  Checking logic in java.lang.invoke.MemberName.checkForTypeAlias
// relies on the fact that spoofing is impossible if a class has a name
// of the form "java.*"
if ((name != null) && name.startsWith("java.")) {
    throw new SecurityException
        ("Prohibited package name: " +
            name.substring(0, name.lastIndexOf('.')));
}
```
这个方法在defineClass前调用。实际上根据byte[]生成class对象的方法叫做defineClass0，defineClass1，defineClass2。BootStrapClassLoader(C++写的)负责加载rt.jar中的所有class(java.xxx.xxx,sun.xxx.xxx....等等都是，包括sun.misc.Unsafe以及sun.nio.ch.DirectBuffer等等。。)，所以这些由BootStrapClassLoader加载的class的getClassLoader方法返回的都是null.
BootStrapClassLoader(C++写的，负责加载rt.jar下面的所有class,就是包名以java.开头的以及sun.xxx开头的)
sun.misc.ExtClassLoader(负责java.ext.dirs这个位置，也就是jre/lib/ext文件夹下面的东西)
```
/c/Program Files/Java/jre1.8.0_201/lib/ext
λ ls
access-bridge-64.jar  dnsns.jar    jfxrt.jar       meta-index   sunec.jar            sunmscapi.jar  zipfs.jar
cldrdata.jar          jaccess.jar  localedata.jar  nashorn.jar  sunjce_provider.jar  sunpkcs11.jar
```
sun.misc.AppClassLoader(负责java.class.path这个位置，就是/c/Program Files/Java/jre1.8.0_201/lib/文件夹下面的所有jar包,以及/c/Program Files/Java/jre1.8.0_201/lib/ext中的所有jar包，这个其实是委托上去了)。


## java 的CLASSPATH
首先来看一下一台windows上的classPath长什么样
```shell
echo "${CLASSPATH}"
.;C:\Program Files\Java\jdk1.8.0_201\bin;C:\Program Files\Java\jdk1.8.0_201\lib\dt.jar;C:\Program Files\Java\jdk1.8.0_201\lib\tools.jar
```

分别是"."当前文件夹，bin文件夹，lib文件夹下面的dt.jar，以及lib下面的tools.jar
bin文件夹里放的都是些可执行文件(windows上是.exe文件),它们实际上仅仅相当于是一层代码的包装，这些工具的实现所要用到的类库都在tools.jar中(这些跟运行期没什么关系)
dt.jar 主要是Swing包,用解压缩软件看下就知道了

上述这些位置(".", "bin/"."lib/dt.jar", "lib/tools.jar")都是由Application ClassLoader加载的

"%JAVA_HOME%\jre\lib"，这个文件夹下面包括了rt.jar,resource.jar,该文件夹下所有class是由BootStrapClassLoader加载的
扩展类库在%JAVA_HOME%\jre\lib\ext目录下，该目录下的类是由Extension ClassLoader来加载的
代码为证
```java
public static void main(String[] args) {
        String property = System.getProperty("sun.boot.class.path");//BoostrapClassLoader
        String[] split = property.split(";");
        Arrays.asList(split).forEach(s -> System.out.println(s)); // jre/lib 文件夹下面的所有类
    } 

public static void main(String[] args) {
        String property = System.getProperty("java.ext.dirs");//ExtClassLoader
        String[] split = property.split(";");
        Arrays.asList(split).forEach(s -> System.out.println(s)); //jre/lib以及jre/lib/ext文件夹下面的所有类。这里面已经看出来委派了
    }

public static void main(String[] args) {
        String property = System.getProperty("java.class.path");//AppClassLoader
        String[] split = property.split(";");
        Arrays.asList(split).forEach(s -> System.out.println(s));// 这个打印出来的是上面的外加其他（.） 也是双亲委派
    }    
```

现实生活中，跑一个java应用都是java -cp xxx非常长甚至几百个jar的classpathxxx (好在ide帮开发者完成了这种处理)
[java这个可执行文件接收的参数](https://docs.oracle.com/javase/8/docs/technotes/tools/windows/java.html) 这里面介绍了，有些是标准的(所有vm implementaion都支持)，有些是非标准的(只在hotspot vm上支持)


[jdk bin 文件夹中的可执行文件的介绍](https://docs.oracle.com/javase/8/docs/technotes/tools/index.html) java的命令行参数


[fastjson等json序列化反序列化库对于key的大小写处理。](https://segmentfault.com/a/1190000015634321)（fastjson的大小写的坑）
具体来讲就是一个Age的field在被序列化之后变成了age的string，而一个age的string倒是可以反过来在反序列化得到Age。似乎fastjson默认策略是field首字母小写，序列化反序列化都是。结论就是，跟后台商量好，所有字段小写开头(听闻c#是大写开头)。后台不改的话，加JSONField注解。
要想让Age序列化为Age，一般是在get和set上面加JSONField，加在field的定义上没有用。

还做了一个好玩的小实验
```java
private static class Customer implements Serializable {
        private int age;
        private int Age;
        private boolean IsRegistered;
        public int getage() {
            return age;
        }

        public void setage(int age) {
            this.age= age;
        }
          public int getAge() {
            return Age;
        }

        public void setAge(int age) {
            Age = age;
        }

        public boolean isRegistered() {
            return IsRegistered;
        }

        public void setRegistered(boolean registered) {
            IsRegistered = registered;
        }

}

//给一这么串json， c2string = "{\"age\":21,\"Age\":22,\"registered\":true}"; 解析出来的结果是
c2string = "{\"age\":21,\"Age\":22,\"registered\":true}";
Customer c3 = JSON.parseObject(c2string,Customer.class);
System.out.println(c3.Age); // 21 似乎是fastjson根据setXXX后面的xxx找到了Age这个field
System.out.println(c3.age); // 0
System.out.println(c3.IsRegistered);
```
其他的json库，gson是没有这个现象的

### autoValue这个library的使用
autoValue主要是为了在java 1.6 以上生成immutable object的，原理是annotaion processor。在idea中使用的话，需要为当前project enable annotation processor。能够避免手动写java bean的时候写toString, equals犯错。当然如果使用的是kotlin的话，直接使用data class就可以了。还提供了builder模式。


Java 系统监控有一个小的技巧是，你可以使用kill -3 <pid> 发一个SIGQUIT的信号给JVM，可以把堆栈信息（包括垃圾回收的信息）dump到stderr/logs。


![](https://api1.foster66.xyz/static/imgs/1279081126453.jpg)



## 参考
[有直接去看hotspot源码来分析的](https://www.zhihu.com/question/60892134)
[classLoader related topics](https://zhuanlan.zhihu.com/p/51374915)



