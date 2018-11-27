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


todo
反编译java代码的基本套路


![](https://www.haldir66.ga/static/imgs/1279081126453.jpg)

