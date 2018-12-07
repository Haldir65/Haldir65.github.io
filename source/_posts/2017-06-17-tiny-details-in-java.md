---
title: For those tiny details in Java
date: 2017-06-17 21:24:48
tags: [java]
---
> interesting stuff in java that don't seem to get enough pubilicity
>
>

![landscape](https://www.haldir66.ga/static/imgs/34a7d57ccabb18c69d085247cf009b22.jpg)

<!--more-->

## 1. getting the concreate class from generic types
    ```java
        /**
     * Make a GET request and return a parsed object from JSON.
     *
     * @param url     URL of the request to make
     * @param clazz   Relevant class object, for Gson's reflection
     * @param headers Map of request headers
     */
    public GenericMoshiRequest(String url, @Nullable Class<T> clazz, Map<String, String> headers,
                               Response.Listener<T> listener, Response.ErrorListener errorListener) {
        super(Method.GET, url, errorListener);
//        this.clazz = clazz;
        Class<T> entityClass = (Class<T>) ((ParameterizedType) getClass().getGenericSuperclass()).getActualTypeArguments()[0];//使用反射获得泛型对应class
        this.clazz = entityClass;
        this.headers = headers;
        this.listener = listener;
    }
    ```

## 2. OkHttp 默认会自动重试失败的请求
[okhttp-is-quietly-retrying-requests-is-your-api-ready](https://medium.com/inloop/okhttp-is-quietly-retrying-requests-is-your-api-ready-19489ef35ace)
OkHttp默认会对请求进行重试，具体是在RetryAndFollowUpInterceptor中进行的。
 ```java
   RetryAndFollowUpInterceptor.java

  @Override public Response intercept(Chain chain) throws IOException {
    Request request = chain.request();

    streamAllocation = new StreamAllocation(
        client.connectionPool(), createAddress(request.url()), callStackTrace);

    int followUpCount = 0;
    Response priorResponse = null;
    while (true) { # 不停的尝试
      if (canceled) {
        streamAllocation.release();
        throw new IOException("Canceled");
      }

      Response response = null;
      boolean releaseConnection = true;
      try {
        response = ((RealInterceptorChain) chain).proceed(request, streamAllocation, null, null);
        releaseConnection = false; //默认不认可response成功
      } catch (RouteException e) {
        // The attempt to connect via a route failed. The request will not have been sent.
        if (!recover(e.getLastConnectException(), false, request)) {
          throw e.getLastConnectException();
        }
        releaseConnection = false;
        continue;  //继续尝试
      } catch (IOException e) {
        // An attempt to communicate with a server failed. The request may have been sent.
        boolean requestSendStarted = !(e instanceof ConnectionShutdownException);
        if (!recover(e, requestSendStarted, request)) throw e;
        releaseConnection = false;
        continue; //继续尝试
      } finally {
        // We're throwing an unchecked exception. Release any resources.
        if (releaseConnection) { //出现不可预料的错误，释放硬件资源，端口什么的
          streamAllocation.streamFailed(null);
          streamAllocation.release();
        }
      }
    }
  }
    ```
客户端当然可以使用retryOnConnectionFailure禁止这种自动重试策略，但不建议这么做。另外，为避免减少不必要的重试请求，
OkHttp 3.3.0 [issue](https://github.com/square/okhttp/issues/2394)

> Don’t recover if we encounter a read timeout after sending the request, but do recover if we encounter a timeout building a connection
建立连接超时可以重试(客户端到服务器的通道不可靠，当然可以重试)，连接上之后读取超时则不去重试(服务器出了问题，没有必要重试)。

另外，GET方法本身是人畜无害的，Retry请求多次发起不会造成数据错误；但对于POST，涉及到写服务端写操作，最好带上GUID作为单次请求unique标示。（这是server和client之间需要协商好的protocol）

## 3. From Java Code To Java Heap
   A talk from IBM Engineer, talking about optimizing the memery usage for your java application.[youtube](https://www.youtube.com/watch?v=FLcXf9pO27w)
   [ibm](https://www.ibm.com/developerworks/java/library/j-codetoheap/index.html)

## 4. 强行更改String的内容
  String这种东西是放在常量池里面的，所以
  ```java
  String a = "hello"
  String b = "hello"
  String c = new String("Hello")

  显然ab都指向了常量池，c指向了放在堆上的对象，后者也指向常量池
  a==b!=c  

  //更改这个String里面的东西
  Field a_ = String.class.getDeclaredField("value");
        a_.setAccessible(true);
        char[] value=(char[])a_.get(a);
        value[3]='_';   //修改a所指向的值

  这样a,b,c 的值都改掉了      
  ```
```java
  void internSample(){
        String str1 = "Go to hell";
        String str2 = str1.intern();
        System.out.println(str1==str2);
        System.out.println("before modification str1 =  "+str1);
        System.out.println("before modification str2 =  "+str2);
        try {
            Field f = String.class.getDeclaredField("value");
            f.setAccessible(true);
            f.set(str2,"Dump ass".toCharArray());
        } catch (NoSuchFieldException e) {
            e.printStackTrace();
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        }
        System.out.println("after modification str1 = "+ str1);
        System.out.println("after modification str2 = "+ str2);
    }
```
输出：
> true
before modification str1 =  Go to hell
before modification str2 =  Go to hell
after modification str1 = Dump ass
after modification str2 = Dump ass

Process finished with exit code 0


## 5. 注解
```java
 Builder(Retrofit retrofit, Method method) {
      this.retrofit = retrofit;
      this.method = method;
      this.methodAnnotations = method.getAnnotations();// 返回的是一个Annotation[]数组
      this.parameterTypes = method.getGenericParameterTypes();// 比如HashMap的put方法，这个方法返回一个Type[2]，分别是'K','V'
      this.parameterAnnotationsArray = method.getParameterAnnotations();
    }
```

如果不是看到Retrofit的源码，一般还真没机会了解到这几个方法。。


## 6. java如何把char类型数据转成int类型数据
String a = "123"
Stirng本质上就是一个char[]的包装类，1对应Asicii码的49,2对应50,3对应51.所以实质上就类似于char[] = new char{49,50,51} ;

想把1,2,3分别拿出来得这么写：
```java
char[] array = a.tocharArray();
for(i=0;i<=array.length();i++){
  int a = Integer.parseInt(String.valueof(array.charAt(i)));//这样就能分别把1,2,3拿出来了。
}
```


根据stackoverFlow的[解释](https://stackoverflow.com/questions/14342988/why-are-we-allowed-to-assign-char-to-a-int-in-java), char只是16bit的数字，也就是int（4个字节,32位）的子集。

```java
char word = 'A' +1234 ;//编译通过

char word2 = 'A';
word2 = word2 +1 ;//编译失败
```

[char的转换问题](https://stackoverflow.com/questions/21317631/java-char-int-conversions)

## 7. Guava就是个Util

## 8. 从ArrayList的ConcurrentModificationException说起
ArrayList的ConcurrentModificationException一般在使用Iterator的时候会抛出，普通的get，set不会。

```java
private class Itr implements Iterator<E> {
       int cursor;       // index of next element to return
       int lastRet = -1; // index of last element returned; -1 if no such
       int expectedModCount = modCount;
      //简单的三个成员变量，cursor会在外部调用next方法时自增1，在
      // lastRet 会在调用next时候设置为next方法返回的Value的index，在remove时设置为-1
     }

     //Itr的next 方法只是返回了array[cursor],cursor是从0开始的。
     // Itr的remove方法调用了ArrayList的remove方法（modeCount++），expectedModCount设置为modCount
     // 之所以调用Iterator一边迭代一边删除，一方法是hasNext方法检测了当前index不会超出数组大小。另外在remove的时候会将当前Iterator的预期下一个操作位置cursor设置为上一次操作的位置（remove里面还有一个arrayCopy）。

     final void checkForComodification() {
               if (modCount != expectedModCount)
                   throw new ConcurrentModificationException();
           }
```
假定开了十条线程，每条线程都调用ArrayList的ListIterator，各自得到一个new Itr的实例。而这些Itr的modecount都是从这一个ArrayList拿的，expectedModCount则是各自保存的。一个原则就是，对于这个集合结构性的更改，同时只能有一条线程来做。每条线程的expectedModCount都会在调用ArrayList的remove方法之后被赋值为ArrayList的modCount。next和remove方法开头都调用了这个checkForComodification。就在于next会因为其他线程的结构性更改抛出IndexOutOfBoundsException，但实际上问题并不出在next方法取错了index。同理，remove方法调用的是可能抛出IndexOutOfBoundsException的ArrayList的remove方法，但实际问题并不出在remove传错了对象。Itr本身保存的index是正确的，只是外部环境的变更使得这些index存在多线程条件下的不可靠性。
即迭代器对象实例保持了一些对于外界环境的预期，而并发条件下对于集合的结构性更改使得这些必要的预测信息变得不可靠。

ListIterator和Iterator(next,hasNext以及remove)和两个接口，前者在后者的基础上加了一些方法(add,set,remove等方法).

改成CopyOnWriteArrayList为什么就不会崩了：

```java
static final class COWIterator<E> implements ListIterator<E> {
     /** Snapshot of the array */
     private final Object[] snapshot;
     /** Index of element to be returned by subsequent call to next.  */
     private int cursor;  

   }
```
没有了expectedModCount，成员变量就这俩。
CopyOnWriteArrayList直接实现List，写操作都用ReentrantLock锁上了，即同时只能有一条线程进行写操作，get没有加锁。
private transient volatile Object[] array;
注意保存数据的array是volatile的，任何一条线程写的操作都会被所有的读取线程看到(skip了cpu缓存)，set的时候，以set为例：
```java
public E set(int index, E element) {
      final ReentrantLock lock = this.lock;
      lock.lock();
      try {
          Object[] elements = getArray();
          E oldValue = get(elements, index);

          if (oldValue != element) {
              int len = elements.length;
              Object[] newElements = Arrays.copyOf(elements, len); //即CopyOnWrite
              newElements[index] = element;
              setArray(newElements);
          } else {
              // Not quite a no-op; ensures volatile write semantics
              setArray(elements);
          }
          return oldValue;
      } finally {
          lock.unlock();
      }
  }
```

CopyOnWriteArrayList内部ListIterator直接保存了一份final的之前Array的snapShot，由于是volatile，任何读操作都能读取到实时的array数据。所谓读取是安全的是指读的时候始终读到的是最实时的信息，这个通过volatile 就能保证。写入由于加锁了，所以也是线程安全的。




## 9.float和long这些相互除法，会出现精确度损失
6.8040496E7*100/68040488f 会出现1.000001这种东西

## 10. int居然还可以这么写
- int a = 5_372_4323; 下划线只是为了具有更好的可读性，added in java 7

## 11.java nio是java1.4引入的
适合连接数高的并发处理
1.nio做了内存映射，少了一次用户空间和系统空间之间的拷贝
2.nio是异步，触发式的响应，非阻塞式的响应，充分利用了系统资源，主要是cpu

## 12.微观(macro)层面的性能要点
```java
   List<String> list = new ArrayList<>();
  for (int i = 0; i < list.size(); i++) {
      //do stuff
  }

//下面这种才是正确的方法
 List<String> list = new ArrayList<>();
  for (int i = 0,size = list.size(); i<size; i++) {
      //do stuff
  }
```
在字节码层面，list.size是通过invokeInterface实现的，这个过程实际上需要根据"size（）"这个方法名称计算出对应的hash值，然后去方法区缓存里面查找这个方法的对应实现。hash计算一次无所谓，计算多次总归比计算一次要浪费时间。

## 13. inline Function
编译器层面做的优化[inline](https://www.quora.com/How-can-you-perform-an-inline-function-in-Java)。主要是省去不必要的一次函数调用

## 14.json解析器推荐报出的错误稍微看下还是能懂的
例如：[gson-throwing-expected-begin-object-but-was-begin-array](https://stackoverflow.com/questions/9598707/gson-throwing-expected-begin-object-but-was-begin-array) 问题就在于，String形式的json没问题，自己这边写的对应映射class结构写错了，一个变量其实是object，自己在class里面写成了array(list).
一般的解析器会allocate一大堆String然后丢掉，moshi会根据binary data做好cache，每一个key只会创建一次。所以速度很快。这一点jake Wharton和Jesse Wilson在一次[会议](https://www.youtube.com/watch?v=6uroXz5l7Gk)上提到过.
另外，jsonArray的String长这样"[{},{}]",jsonObject的String长这样"{key1:value1,key2:value2}". 经常会不确定。

## 15. Collections.unmodifiableList的出现是有道理的
还记得Arrays.asList返回的并不是java.util.ArrayList。并不支持add,remove(丢unSupportedOperationException).**但支持set,get**。为了把List变成彻底只读的，就得用Collections的这个方法。原理上就是在get和set里面也丢异常出来。


### 16. 单例模式，双重锁检查
单例模式怎么写，一般的答案就是双重检查
```
class Foo {
    private Helper helper;
    public Helper getHelper() {
        if (helper == null) {
            synchronized(this) {
                if (helper == null) { //可能指针不为空，但指向的对象还未实例化完成
                    helper = new Helper();
                }
            }
        }
        return helper;
    }
}
```
除非在单例前面加上volatile，否则上述单例模式并不安全。
infoQ也有[解释](http://www.infoq.com/cn/articles/double-checked-locking-with-delay-initialization)
正确答案参考知乎答案:
[知乎用户](https://www.zhihu.com/question/35268028/answer/62016374)

- 是因为**指令重排**造成的。直接原因也就是 初始化一个对象并使一个引用指向他 这个过程不是原子的。导致了可能会出现引用指向了对象并未初始化好的那块堆内存，使用volatile修饰对象引用，防止重排序即可解决。推荐使用**内部静态类**做延时初始化，更合适，更可靠。这个同步过程由JVM实现了。

### 17.函数的执行顺序，由此带来的性能影响
```java
Log.Debug("list is "+list) //传一个list进去，list的长度未知
其实应该改为
Log.debug(() -> "list is"+list) //这个方法接受一个Supplier<String>
```
区别在于，前者无论是否DEBUG都会去创建一个String，后者只是提供了如何创建String的思路，并没有真的创建。

### 18.inline的解释
这种说辞更多见于C或者C++,java里面，例如
```
String s = "someThing";
System.out.println(s.length())

//可以改成
System.out.println("something".length()) // 这就叫inline，没必要多创建一根指针出来
```
一种说法是，一个method只被用了一次，完全没必要声明这个method，vm调用method需要invokestatic或者invokeInterface,提取出来省掉这部分消耗。据说有些vm可以自动做好这部分优化。

### 19. for loop的写法
```java
int i = 0;
for (; i < 10; i++) {
  // do stuff here
}
```
这么写也是可以的，其实很像
```java
for (;;) {}
```
[解释](https://stackoverflow.com/questions/5676992/what-do-two-semicolons-mean-in-java-for-loop),这跟while(true)是一样的。

java7的enhanced for loop[只是一个syntax sugar](https://stackoverflow.com/questions/85190/how-does-the-java-for-each-loop-work):
```java
List<String> somelist = new ArrayList<>();//右边只有两个<>是jdk7出现的diamond operator。
for (Iterator<String> i = someList.iterator(); i.hasNext();) {
    String item = i.next();
    System.out.println(item);
}
//由于实在是一样的东西，intellij idea里面会变黄色，提醒 replace with for each
// debug 一下确实发现 hasNext和next方法在每一个循环都被调用了
```

### 20. 关于泛型
一般泛型要这么写：
> class A <T> 或者class B<V extends List>

实际上IDE不在乎选择了什么字母，所以可以这么写：
> class A <CALLBACK extends Binder>
这样写完全没问题

### 21.子类和父类的关系
子类里面写一个和父类一样名字的变量，会把父类protected变量的值冲刷掉；
```java
public class FatherClass {
    protected int mId;

}


public class ChildClass extends FatherClass {
   private int mId;

    public static void main(String[] args) {
        FatherClass fatherClass = new ChildClass();
        fatherClass.mId = 10;
        System.out.println(fatherClass.mId); //10

        ChildClass childClass = (ChildClass) fatherClass;
        childClass.mId = 20;
        System.out.println(fatherClass.mId); //10
        System.out.println(childClass.mId); //20
    }
}
输出
10
10
20
换成
public class ChildClass extends FatherClass {
   private int mId;

    public static void main(String[] args) {
        ChildClass fatherClass = new ChildClass();
        fatherClass.mId = 10;
        System.out.println(fatherClass.mId);

        ChildClass childClass = (ChildClass) fatherClass;
        childClass.mId = 20;
        System.out.println(fatherClass.mId);
        System.out.println(childClass.mId);
    }
}
输出
10
20
20
```
所基本上就是，把一个对象当成什么class来用，操作的范围就在这个层面造成影响；
debug会看见两个变量
mId和FatherClass.mId，所以完全是两个int。

调用父类被override的方法，目测只能用super.someMethod()

### 22.打印出一个方法执行到这里的方法栈
> Thread.dumpStack();
还有，e.printStakTrace是非常昂贵的

### 23. try with resource(since jdk 7)
Joshua Bloch设计了jdk7中的try with resource特性。
在程序开发中，代表资源的对象，一般用完了需要及时释放掉。
例如，jdk7之前
```java
static String readFirstLineFromFileWithFinallyBlock(String path) throws IOException {
      BufferedReader br = new BufferedReader(new FileReader(path));
      try {
        return br.readLine();
      } finally {
        if (br != null) br.close();
      }
    }
```
放在finally里面就是确保资源能够被释放掉
jdk7之后
```
static String readFirstLineFromFile(String path) throws IOException {
      try (BufferedReader br = new BufferedReader(new FileReader(path)) {
        return br.readLine();
      }
  }
```
jdk7添加了AutoCloseable接口，当try语句块运行结束时，BufferReader会被自动关闭。即会自动调用close方法，假如这个close方法抛出异常，异常可以通过Exception.getSuppressed获得，所以这里面的Exception是try语句块里面抛出来的。[oracle给出的解释](http://www.oracle.com/technetwork/cn/articles/java/trywithresources-401775-zhs.html)
其实跟python很像:
```python
with open('','wb+') as f:
     f.read()
with urllib.request.urlopen(url) as u:
    page = u.read()
    print(len(page))     
```
会自动完成文件的关闭或者socket的关闭


### 24. java提供了文件zip功能的接口
jdk7开始添加了java.util.zip包。

### 25. String为什么要设计成final的
[解释](https://www.programcreek.com/2013/04/why-string-is-immutable-in-java/)非常多
有人猜测Java想用这种方式让String在形式上成为一种基本数据类型，而不是一个普通的类。确实String基本在所有的类中都用到了。

### 26.从Exploring java's hidden cost得到的
在intellij中，Setting -> Editor -> Inspection -> Synthetic accessor call
The docs explains as these:
>
This inspection is intended for J2ME and other highly resource constrained environments. Applying the results of this inspection without consideration might have negative effects on code clarity and design.
Reports references to non-constant private members of a different class, for which javac will generate a package-private synthetic accessor method.
An inner class and its containing class are compiled to separate class files. The Java virtual machine normally prohibits access from a class to private fields and methods of another class. To enable access from an inner class to private members of a containing class or the other way around javac creates a package-private synthetic accessor method. Less use of memory and greater performance may be achieved by making the member package-private, thus allowing direct access without the creation of a synthetic accessor method.

There 's no actual inner class'

### 27. abstract class可以没有抽象方法
[Why use an abstract class without abstract methods?](https://stackoverflow.com/questions/6856133/why-use-an-abstract-class-without-abstract-methods)

### 28. 一般说map迭代读取的顺序和存进去的顺序是不一样的（有例外）
[文档](https://stackoverflow.com/questions/2973751/how-to-maintain-order-of-insertion-using-collections)是这样说的：
LinkedHashMap: "with predictable iteration order [...] which is normally the order in which keys were inserted into the map (insertion-order)."
HashMap: "makes no guarantees as to the order of the map"
TreeMap: "is sorted according to the natural ordering of its keys, or by a Comparator"
实际开发中想要有序就用LinkedHashMap。
但是
```java
HashMap<String, Integer> map = new HashMap<>(10);
map.put("A", 1);
map.put("B", 2);
map.put("C", 3);
map.put("D", 4);
map.forEach((s, integer) -> System.out.println("key = "+s+" value is "+integer));
```
实际是有序的，文档是说[no guarantees]。看下源码，其实是在Hashmap算hashcode的时候，String的hashCode比较耿。。。
[Stuart Mark提到了这一点](https://www.youtube.com/watch?v=ogRVWXuuAU4)，并希望开发者不要寄希望于这种edge case。

### 29. 自动装箱使用不小心会造成NullPointerException
[参考](http://mazhuang.org/2017/08/20/java-auto-boxing-unboxing/)
```java
public class Test {
    public static long test(long value) {
        return value;
    }

    public static void main(String[] args) {
        Long value = null; //因为null不能被Boxing，所以崩了
        // ...
        test(value);
    }
}
```
其实重点在于看javap -c 生成的字节码

[ternary operator也会造成npe]三目运算符会隐式转型(https://stackoverflow.com/questions/25996591/java-ternary-operator-npe-autoboxing-string)
> This is happening because the type return by a ternary operator is the type of the first returned value. In this case, that's the primitive value false. So Java is trying to take the primitive boolean returned by the ternary operator, then use autoboxing to convert it to a wrapper Boolean. But then you return a null from the ternary operator. And then when Java tries to autobox it, it throws an NPE because null can't be autoboxed. You should either use wrapper Booleans as the values in the ternary operator, or restructure this using if statements.

简单来讲，ternary operator返回值的类型是第一个return值的类型(在这里就是boolean)，但返回一个Null的话，null并不能被autoBoxing，所以崩了。

### 30. 假如没有override hashCode方法，那么deug里面看到的是什么？
```java
@HotSpotIntrinsicCandidate
   public native int hashCode();//是一个native方法
```
[默认返回内存中的地址](https://stackoverflow.com/questions/2237720/what-is-an-objects-hash-code-if-hashcode-is-not-overridden)
[其实也不能真当做是内存地址](https://stackoverflow.com/questions/1961146/memory-address-of-variables-in-java)
> System.identityHashCode()方法返回的内容是vm 的implementation detail（亦即不同vm之间的实现方式可能不同），虽然多数时候这个值是object的initial memory address。但vm随时可能把这个object挪走，所以Getting the memory addresses of variables is meaningless within Java。

System.identityHashCode返回的形式是1360875712这样的十进制的int，需要转成2进制Integer.toBinaryString




### 31. 接口里面放一个接口这种事情也不是没干过
android.content.DialogInterface.java
```java
public interface DialogInterface {    

    public static final int BUTTON_POSITIVE = -1;

    public static final int BUTTON_NEGATIVE = -2;

    public static final int BUTTON_NEUTRAL = -3;

    public void cancel();

    public void dismiss();

    interface OnCancelListener {
        public void onCancel(DialogInterface dialog);
    }

    interface OnDismissListener {
        public void onDismiss(DialogInterface dialog);
    }

    interface OnShowListener {
        public void onShow(DialogInterface dialog);
    }
    interface OnClickListener {
        public void onClick(DialogInterface dialog, int which);
    }

    interface OnMultiChoiceClickListener {
        public void onClick(DialogInterface dialog, int which, boolean isChecked);
    }

    interface OnKeyListener {
        public boolean onKey(DialogInterface dialog, int keyCode, KeyEvent event);
    }
}
```
接口里面放常量也行啊

### 32.Stuart Marks又提到了写comparatr时可能出现的错误
[Comparison Method Violates Its General Contract! (Part 1) by Stuart Marks](https://www.youtube.com/watch?v=Enwbh6wpnYs)

### 33. java也是有二维数组的

### 34. 在运行时得这么拿注解
代码出自[深入理解Java：注解（Annotation）--注解处理器](http://www.cnblogs.com/peida/archive/2013/04/26/3038503.html)
```java
/**
 * 水果名称注解
 * @author peida
 *
 */
@Target(ElementType.FIELD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface FruitName {
    String value() default "";
}

/**
 * 水果颜色注解
 * @author peida
 *
 */
@Target(ElementType.FIELD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface FruitColor {
    /**
     * 颜色枚举
     * @author peida
     *
     */
    public enum Color{ BULE,RED,GREEN};

    /**
     * 颜色属性
     * @return
     */
    Color fruitColor() default Color.GREEN;

}

/**
 * 水果供应者注解
 * @author peida
 *
 */
@Target(ElementType.FIELD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface FruitProvider {
    /**
     * 供应商编号
     * @return
     */
    public int id() default -1;

    /**
     * 供应商名称
     * @return
     */
    public String name() default "";

    /**
     * 供应商地址
     * @return
     */
    public String address() default "";
}

/***********注解使用***************/

public class Apple {

    @FruitName("Apple")
    private String appleName;

    @FruitColor(fruitColor=Color.RED)
    private String appleColor;

    @FruitProvider(id=1,name="陕西红富士集团",address="陕西省西安市延安路89号红富士大厦")
    private String appleProvider;

    public void setAppleColor(String appleColor) {
        this.appleColor = appleColor;
    }
    public String getAppleColor() {
        return appleColor;
    }

    public void setAppleName(String appleName) {
        this.appleName = appleName;
    }
    public String getAppleName() {
        return appleName;
    }

    public void setAppleProvider(String appleProvider) {
        this.appleProvider = appleProvider;
    }
    public String getAppleProvider() {
        return appleProvider;
    }

    public void displayName(){
        System.out.println("水果的名字是：苹果");
    }
}

/***********注解处理器***************/

public class FruitInfoUtil {
    public static void getFruitInfo(Class<?> clazz){

        String strFruitName=" 水果名称：";
        String strFruitColor=" 水果颜色：";
        String strFruitProvicer="供应商信息：";

        Field[] fields = clazz.getDeclaredFields();

        for(Field field :fields){
            if(field.isAnnotationPresent(FruitName.class)){
                FruitName fruitName = (FruitName) field.getAnnotation(FruitName.class);
                strFruitName=strFruitName+fruitName.value();
                System.out.println(strFruitName);
            }
            else if(field.isAnnotationPresent(FruitColor.class)){
                FruitColor fruitColor= (FruitColor) field.getAnnotation(FruitColor.class);
                strFruitColor=strFruitColor+fruitColor.fruitColor().toString();
                System.out.println(strFruitColor);
            }
            else if(field.isAnnotationPresent(FruitProvider.class)){
                FruitProvider fruitProvider= (FruitProvider) field.getAnnotation(FruitProvider.class);
                strFruitProvicer=" 供应商编号："+fruitProvider.id()+" 供应商名称："+fruitProvider.name()+" 供应商地址："+fruitProvider.address();
                System.out.println(strFruitProvicer);
            }
        }
    }
}

/***********输出结果***************/
public class FruitRun {

    /**
     * @param args
     */
    public static void main(String[] args) {

        FruitInfoUtil.getFruitInfo(Apple.class);

    }

}

====================================
 水果名称：Apple
 水果颜色：RED
 供应商编号：1 供应商名称：陕西红富士集团 供应商地址：陕西省西安市延安路89号红富士大厦
```

### 35 .四舍五入问题，BigDecimal,BigInteger这些
基本数据类型中float和double只能用于处理科学运算或者工程计算，商业应用中，需要使用BigDecimal来处理。
```java
System.out.println(0.06 + 0.01);
System.out.println(1.0 - 0.42);
System.out.println(4.015 * 100);
System.out.println(303.1 / 1000);

//下面是实际输出，显然是不对的
// 0.06999999999999999
// 0.5800000000000001
// 401.49999999999994
// 0.30310000000000004

double a = 4887233385.5;
double b = 0.85;
BigDecimal a1 = new BigDecimal(a);
BigDecimal b1 = new BigDecimal(b);
System.out.println("==============================================================");
System.out.println(a*b);
System.out.println("result2-->"+a1.multiply(b1));//result2-->4154148377.674999891481619374022926649558939971029758453369140625无限不循环,其实后面还有
System.out.println("result2-->"+a1.multiply(b1).setScale(1, RoundingMode.HALF_UP));
System.out.println("result2-->"+a1.multiply(b1).setScale(5, RoundingMode.HALF_UP));
System.out.println("result2-->"+a1.multiply(b1).setScale(9, RoundingMode.HALF_UP));
System.out.println("result2-->"+a1.multiply(b1).setScale(11, RoundingMode.HALF_UP));
System.out.println("==============================================================");
```
以下为实际输出
> ==============================================================
4.1541483776749997E9  //科学计数法在这种场景下几乎没法用（注意默认给出了16位，下面有解释）
result2-->4154148377.674999891481619374022926649558939971029758453369140625 //这个是实际值
result2-->4154148377.7
result2-->4154148377.67500
result2-->4154148377.674999891
result2-->4154148377.67499989148
==============================================================
实在靠谱的四舍五入

> RoundingMode.HALF_EVEN就是把这个小数化为离它最近的偶数
RoundingMode.HALF_UP 就是碰到五就往上进一位
RoundingMode.HALF_DOWN 就是碰到五就视为0
RoundingMode.FLOOR 和Math.floor差不多
RoundingMode.CEILING 和Math.ceiling差不多
core Library的命名都很易懂

由此引申出：
```java
System.out.println( 0.9999999f==1f ); // 7个9
System.out.println( 0.99999999f==1f ); //8个9
System.out.println( 0.999999999f==1f ); // 9个9
// false
// true
// true
```

[Java 浮点数 float和double类型的表示范围和精度](http://blog.csdn.net/zq602316498/article/details/41148063)
和整数型是signed的不一样,float和double是unsigned。
这32位是怎么分的：
1bit（符号位） 8bits（指数位） 23bits（尾数位）（内存中就长这样）
double占据64bit。
1bit（符号位） 11bits（指数位） 52bits（尾数位）（内存中就长这样）

所以float的指数范围是-128~127 。(2的8次方)
double的指数范围为-1024~+1023。
再具体点：
<br>float的范围为-2^128 ~ +2^127，也即-3.40E+38 ~ +3.40E+38；</br>

update : From 3.402,823,5 E+38 to 1.4 E-45(由于是unsigned，这只是正数部分)

the correct way: [-3.40E+38,-1.4 E-45 ] && [1.4 E-45, +3.40E+38] ## 站在十进制的角度来看，是相对于0对称的两个区间。整个实数轴并未完全覆盖。

很多人都说这些最大值最小值不用记，对应的包装类都有常量MIN_VALUE和MAX_VALUE。然而，这个还是有些需要注意的。
Float.MIN_VALUE 并不是负数，而是一个0.00000XXX 的小数。[一般认为这个常量应该起一个更合适的名字](https://stackoverflow.com/questions/3884793/why-is-double-min-value-in-not-negative)，另外不要把Float.MIN_VALUE和Float.MIN_NORMAL搞混淆；
```java
  // Float
  public static final float MIN_NORMAL = 0x1.0p-126f; // 1.17549435E-38f
                                //          这个是2^-126=1.175494350822..(注意小数点后的值就没有了，实在表示不了)
  public static final float MIN_VALUE = 0x0.000002P-126f; // 1.4e-45f 真正的MIN_VALUE应该是MAX_VALUE的负值
  public static final float MAX_VALUE = 0x1.fffffeP+127f; // 3.4028235e+38f //这个max倒是起名起的很好
                           // 怎么算的 拿个计算器算下：2^128 = 3.402823669209...。是不是小数点后第七位就不对了，这个就看上面的23bit了

  // Double
  public static final double MAX_VALUE = 0x1.fffffffffffffP+1023; // 1.7976931348623157e+308 //这个确实是最大值
  public static final double MIN_NORMAL = 0x1.0p-1022; // 2.2250738585072014E-308
  public static final double MIN_VALUE = 0x0.0000000000001P-1022; // 4.9e-324  -Double.MAX_VALUE才是你能用double表示的最小值

  Float.MAX_VALUE + 1 == Float.MAX_VALUE  // true


```
MIN_VALUE和NIN_NORMAL的[区别](https://stackoverflow.com/questions/3728309/difference-between-double-min-normal-and-double-min-value)
float和double最终在内存中都是以a^n次方来表示为十进制数值的。
以float为例来解释下：float一共32bit，就是32个槽子，第一个拿来表示符号(unsigned)，那还剩下31个，最终要用剩下的31个bit表示出一个科学计数法的Decimal.
上面说了，8个用来表示指数，也就是2^8 = 128，也就是指数方面最小是-127，最大是128。也就是说上面那个a^n的n的范围是[-127,128]。
根据stackoverFlow的解释，MIN_NORMAL就是二进制小数点前有一个1开头的，MIN_VALUE就是可以用0开头的
所以就是23个槽子前22个都放了0，最后一个放了1，也就是十进制的2，算上指数层的-127，也就是2乘以2^-127 = 2^-126，论MIN_NORMAL是怎么来的。
还剩下32-1-8 = 23个，用来表示确切的值， 2^23 = 8388608(7个数字，所以7个数字保不准，但6个是有把握的，让7位给指数位吧，把10的-38次方变成10的-45次方)。也就是说上面个a^n的a的范围是[1,8388608]，论MIN_VALUE是怎么来的。



double和float都属于The IEEE 754 format has one bit reserved for the sign and the remaining bits representing the magnitude.

double的范围为-2^1024 ~ +2^1023，也即-1.79E+308 ~ +1.79E+308。就这么算出来的。
至于float里面那剩下的23位和double里面剩下的52位，是用来表示精度的。

>float：2^23 = 8388608，一共七位，由于最左为1的一位省略了，这意味着最多能表示8位数： 2*8388608 = 16777216 。有8位有效数字，但绝对能保证的为7位，也即float的精度为7~8位有效数字；
double：2^52 = 4503599627370496，一共16位，同理，double的精度为16~17位。

所以上面出现了小数点后最多16位的double。
所以上面的java代码还可以想到：
```java
System.out.println( 0.9999999f==1f ); // 7个9
System.out.println( 0.99999999f==1f ); //8个9
System.out.println( 0.9999999996666666f==1f ); // 9个9
```
<del>当一个float小数的小数点后位数超出了8个之后，java就无法用float表示这后面的数字了。</del>
应该说一个float数据类型能够保证不损失精度的限制就是有效数字6-7位（6个是准的，7个不好说）。
所以上面的第8个9之后写什么都是true的。
随手写一个
```java
float aa = 1123456789123456f;
float bb = 1123456789123456.1f;
System.out.println(aa==bb); // ide自动飚黄，显示always 为true
```
不要以为自己真的想要多少就有多少，float后面最多使用8位有效数字，double最多能表示16位有效数字。为什么，数学这么说的。
这么说吧，从整个数轴来看，整个数轴最左边和最右边都是接触不到的。
另外，0左右各有一小块宽度为0.0000000xxx的小范围是表示不了的。
就算是已经覆盖到的位置，计算机这种二进制表达的方式只是**零零散散**的占据了很少的一部分。

```java
float f = 2.2f;  
double d = (double) f;  
System.out.println(d);   
f = 2.25f;  
d = (double) f;  
System.out.println(d);
```
输出：
> 2.200000047683716
2.25

这样的问题也能够理解了，给你32个bit，第一位表示正负，第2-9位表示指数，剩下23位表示实际的数字。
对于2.2f，首先第一位表示正负，然后个位数2可以表示在第二位，剩下的0.2设法用22位表示。

来看十进制小数转换二进制的问题，例如：
22.8125转二进制
> 整数和小数分别转换。
整数除以2，商继续除以2，得到0为止，将余数逆序排列。
22 / 2  11 余0
11/2     5  余 1
5 /2      2  余 1
2 /2      1  余 0
1 /2      0  余 1
所以22的二进制是10110
小数乘以2，取整，小数部分继续乘以2，取整，得到小数部分0为止，将整数顺序排列。
0.8125x2=1.625 取整1,小数部分是0.625
0.625x2=1.25 取整1,小数部分是0.25
0.25x2=0.5 取整0,小数部分是0.5
0.5x2=1.0 取整1,小数部分是0，结束
所以0.8125的二进制是0.1101
十进制22.8125等于二进制10110.1101

对于0.2来说，得到的是一个无线循环的00110011001100110011....区区23位怎么够用。
所以23位之后的数字被无视了，然后打印的时候尝试将这仅有的23位0101表示成10进制的时候，无论如何是得不到跟数学意义上的数字相等的数。但对于机器来说，就是一样的，Intelij里面float超过小数点后8位自动飚黄，说什么is always true。。。就这么23个槽子，确实没法满足实际需要的位数要求。
所以实际上是2.2f需要无限个小槽子表示，2.25f正好停在：0 100 0000 0001 0010 0000 0000 0000 0000 就够用了。
有时候float或者double的位数不够了，就用String吧。BigDecimal提供了String为参数的初始化方法。
```java
double currentLat2 = 2.455675;
BigDecimal b = new BigDecimal(currentLat2);
currentLat2 = b.setScale(5, BigDecimal.ROUND_HALF_UP).doubleValue();
System.out.println(currentLat2);
// 输出的是2.45567而不是2.45568

String currentLat2 = "2.455675";
BigDecimal b = new BigDecimal(currentLat2);   
System.out.println(b.setScale(5,BigDecimal.ROUND_HALF_UP).doubleValue());
```
所以建议用String初始化BigDecimal.

[Floating point precision error](https://www.quora.com/In-Python-why-does-8-5-8-4-give-0-099999999999999964)这种事几乎所有语言都有

type -casting java中从double强转float，从long强转int是怎么实现的


### 36.调jvm参数
先看怎么get:
在Intelij里面，写一个helloworld程序，看下console的输出，然后复制出来。中间加上这么一行：
> -XX:+PrintFlagsFinal and -XX:+PrintFlagsInitial

打印出来的东西很长，在console中不好找，最好拿管道复制出来:  XXXXX | clip 。然后在文本编辑器中粘贴，自己找想要的参数
挑几个好玩的：

> InitialHeapSize                          = 132120576
  MaxJavaStackTraceDepth                   = 1024

具体教程搜索打印jvm参数即可。

再看怎么set:
Intelij里面，Setting-Build-maven-runner，有个VM Options。把网上找到的“jvm 参数粘贴进去”。比如这些
> -Xmx3550m:设置JVM最大可用内存为3550M.
   -Xms3550m:设置JVM促使内存为3550m.此值可以设置与-Xmx相同,以避免每次垃圾回收完成后JVM重新分配内存.
   -Xmn2g:设置年轻代大小为2G.


### 37. Serializable的原理
刚学java的时候没人会跟你讲Serializable为什么是一个没有抽象方法的接口，那时甚至不知道serialize和deserialize是怎么回事。
关于Serializable主要的点有几个：
- 为什么一个没有抽象方法的接口也能算接口
- 为什么总是说序列化一定要实现serializable接口
- 那个serialVersionUID干什么用的
- 为什么写了transient就不会被序列化了。

现在回答下这些问题，serialize（序列化，就是把一个对象写进磁盘），deserialize（反序列化，就是把写在磁盘上的0110这些东西重新组装成一个对象）。
```java
public interface Serializable {
}

private static final long serialVersionUID = 2906642554793891381L;

// 网上随便找到的序列化和反序列化的demo如下
// Serializable：把对象序列化
public static void writeSerializableObject() {
    try {
        Man man = new Man("lat", "123456");
        Person person = new Person(man, "王尼玛", 21);
        ObjectOutputStream objectOutputStream = new ObjectOutputStream(new FileOutputStream("output.txt"));
        objectOutputStream.writeObject("string");
        objectOutputStream.writeObject(person);
        objectOutputStream.close();
    } catch (FileNotFoundException e) {
        e.printStackTrace();
    } catch (IOException e) {
        e.printStackTrace();
    }
}

// Serializable：反序列化对象
public static void readSerializableObject() {
    try {
        ObjectInputStream objectInputStream = new ObjectInputStream(new FileInputStream("output.txt"));
        String string = (String) objectInputStream.readObject();
        Person person = (Person) objectInputStream.readObject();
        objectInputStream.close();
        System.out.println(string + ", age: " + person.getAge() + ", man username: " + person.getMan().getUsername());
    } catch (FileNotFoundException e) {
        e.printStackTrace();
    } catch (Exception e) {
        e.printStackTrace();
    }
}
```

为什么说序列化一定要实现serializable接口。上面的objectOutputStream.writeObject方法走进去。
ObjectOutputStream.java
```java
public final void writeObject(Object obj) throws IOException {
    if (enableOverride) {
        writeObjectOverride(obj);
        return;
    }
    try {
        writeObject0(obj, false);
    } catch (IOException ex) {
        if (depth == 0) {
            writeFatalException(ex);
        }
        throw ex;
    }
}

private void writeObject0(Object obj, boolean unshared)
        throws IOException{
          // 省略省略
          // remaining cases
            if (obj instanceof String) {
                writeString((String) obj, unshared);
            } else if (cl.isArray()) {
                writeArray(obj, desc, unshared);
            } else if (obj instanceof Enum) {
                writeEnum((Enum<?>) obj, desc, unshared);
            } else if (obj instanceof Serializable) {
                writeOrdinaryObject(obj, desc, unshared);
            } else {
                if (extendedDebugInfo) {
                    throw new NotSerializableException(
                        cl.getName() + "\n" + debugInfoStack.toString());
                } else {
                    throw new NotSerializableException(cl.getName());
                }
            }
            // 省略省略
}
```
果然还是用了**instanceof**这个关键词啊。这是写进磁盘(serialize的情况)，从磁盘里取出来的话
ObjecInputStream.java
```java
 public final Object readObject(){
   // 省略
     Object obj = readObject0(false);
     // 省略
 }

 /**
     * Underlying readObject implementation.
     */
    private Object readObject0(boolean unshared) throws IOException {
      // 省略
      case TC_OBJECT:
                  return checkResolve(readOrdinaryObject(unshared));
                  // 省略
    }

      private Object readOrdinaryObject(boolean unshared){
        //省略
        try {
           obj = desc.isInstantiable() ? desc.newInstance() : null;
       } catch (Exception ex) {
           throw (IOException) new InvalidClassException(
               desc.forClass().getName(),
               "unable to create instance").initCause(ex);
       }
       //省略
}
```
就是反射调用无参的构造函数。


以前我问过那个serialVersionUID是干什么的，怎么写，老手告诉我说，瞎写就行了。后来的项目中就一直瞎写了，倒也没出过什么问题。现在来回答这个serialVersionUID是干什么的：
序列化和反序列化就是存进去和取出来，为了保证存进磁盘的A在取出来的时候不会去拿B的二进制数据，所以需要这个。这个值就相当于每一个存进去的class的身份证号，保证存进去和取出来的是一个东西。
ObjectStreamClass.java
```java
private static Long getDeclaredSUID(Class<?> cl) {
      try {
          Field f = cl.getDeclaredField("serialVersionUID");
          int mask = Modifier.STATIC | Modifier.FINAL;
          if ((f.getModifiers() & mask) == mask) {
              f.setAccessible(true);
              return Long.valueOf(f.getLong(null));
          }
      } catch (Exception ex) {
      }
      return null;
  }
```
假如忘记写的话，呵呵
```java
throw new InvalidClassException(osc.name,
                       "local class incompatible: " +
                               "stream classdesc serialVersionUID = " + suid +
                               ", local class serialVersionUID = " +
                               osc.getSerialVersionUID());
```

<quote>
没有指定serialVersionUID的，那么java编译器会自动给这个class进行一个摘要算法，类似于指纹算法，只要这个文件多一个空格，得到的UID就会截然不同的，可以保证在这么多类中，这个编号是唯一的。所以，我们添加了一个字段后，由于没有显指定serialVersionUID，编译器又为我们生成了一个UID，当然和前面保存在文件中的那个不会一样了，于是就出现了2个号码不一致的错误。因此，只要我们自己指定了serialVersionUID，就可以在序列化后，去添加一个字段，或者方法，而不会影响到后期的还原，还原后的对象照样可以使用，而且还多了方法可以用
</quote>

所以还是得老老实实写，而且一次写了之后就不用**也不要**改了
现在可以不用瞎写了，在Intelij里面有小工具：
```
"File->Setting->Editor->Inspections->Serialization issues->Serializable class without ’serialVersionUID’ ->勾选操作"
```

### 38. java中Process的Api
关键词：ProcessBuilder , java9提供了新的Api。另外还有Runtime.exec这个方法
亲测，下面的命令可以在mac上执行uname -a 命令
```java
//用ProcessBuilder是一种做法
 try {
            Runtime r = Runtime.getRuntime();
            Process p = r.exec("uname -a");
            p.waitFor();
            BufferedReader b = new BufferedReader(new InputStreamReader(p.getInputStream()));
            String line = "";

            while ((line = b.readLine()) != null) {
                System.out.println(line);
            }

            b.close();
        }catch (IOException | InterruptedException e){
            
        }

//  下面这个也行
String s = null;

        try {

            // run the Unix "ps -ef" command
            // using the Runtime exec method:
            Process p = Runtime.getRuntime().exec("ps -ef");

            BufferedReader stdInput = new BufferedReader(new
                    InputStreamReader(p.getInputStream()));

            BufferedReader stdError = new BufferedReader(new
                    InputStreamReader(p.getErrorStream()));

            // read the output from the command
            System.out.println("Here is the standard output of the command:\n");
            while ((s = stdInput.readLine()) != null) {
                System.out.println(s);
            }

            // read any errors from the attempted command
            System.out.println("Here is the standard error of the command (if any):\n");
            while ((s = stdError.readLine()) != null) {
                System.out.println(s);
            }

            System.exit(0);
        }
        catch (IOException e) {
            System.out.println("exception happened - here's what I know: ");
            e.printStackTrace();
            System.exit(-1);
        }

```
只不过很少见过用java去调用系统接口的



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

### 40. 关于动态代理(InvocationHandler这一套)
[动态代理](http://www.wanandroid.com/blog/show/2038)。
> System.getProperties().put("sun.misc.ProxyGenerator.saveGeneratedFiles", "true");  

### 41. java io主要是装饰模式，另外，调用操作系统api实现读写文件的功能在FileInputStream和FilePutputStream里面，主要的native方法都在这里面，FileDescriptor的使用也在这里面
```java
  // FileInputStream.java
 private native int read0() throws IOException;
 private native int readBytes(byte b[], int off, int len) throws IOException;
 private native void close0() throws IOException;

//FileOutputStream.java
private native void write(int b, boolean append) throws IOException;
private native void writeBytes(byte b[], int off, int len, boolean append)
       throws IOException;
private native void close0() throws IOException;
```

### 42. Using java from command line interface
平时都被IDE宠坏了，习惯了用Intelij Idea跑java 程序，如果用命令行呢？

java -h 会告诉我们可以通过java command传递的参数。
看了下Intelij Idea点击run的时候做了什么:

首先是一闪而过的compiling.....(其实就是跑javac了)，然后在console里面开始输出："java.exe的绝对路径" "-javaagent:xxx.jar" -Dfile.encoding=UTF-8 -classpath "/jre/lib/A.jar;/jre/lib/B.jar;.....;/target/classes(这个是ide在当前项目目录下创建的一个文件夹，里面按照包名结构放了对应的class文件);C:/users/administrator/.m2/repository/com.xxx.xxx.jar;......" com.example.sample

java - h说
>    -D<名称>=<值> 设置系统属性
-javaagent:<jarpath>[=<选项>] 加载 Java 编程语言代理, 请参阅 java.lang.instrument
-classpath <目录和 zip/jar 文件的类搜索路径>用 ; 分隔的目录, JAR 档案和 ZIP 档案列表, 用于搜索类文件。

记住,javac只是一个utlity that comes with JDK

错误: 找不到或无法加载主类
两种正确的方案是：
1. java文件中不写packagename!不写packagename!不写packagename!
```java
public class Demo {
    public static void main(String[] args) {
        System.out.println("Hello there");
    }
}
```
然后命令行
javac Demo.java -> java Demo -> Hello there

2. java文件写上packageName

```java
package com.me.example;

public class Demo2 {
    public static void main(String[] args) {
        System.out.println("Hello there");
    }
}
```

<del>然后javac Demo2.java -> java Demo2 -> 错误: 找不到或无法加载主类 com.me.example.Demo2</del>
应该javac Demo2.java -> 把生成的Demo2.class粘贴到当前目录下新建的一个com/me/example文件夹下 -> java/com/me/example/Demo2 -> Hello there

3. 非要把带packagename的java文件写在src/com/me/example文件夹下？好啊
```java
package com.me.example;

public class Demo3 {
    public static void main(String[] args) {
        System.out.println("Hello there");
    }
}
```
在src/com/me.example文件夹下敲命令：
javac Demo3 -> 把生成的Demo3.class粘贴到src/com/me/example/com/me/example文件夹下 -> java com/me/example/Demo3

4. java文件还放在src/com/me/example文件夹下，不加packageName总能行了吧
```java
public class Demo4 {
    public static void main(String[] args) {
        System.out.println("Hello there");
    }
}
```
javac Demo4.java   -> java Demo4.class -> "Hello there"
最终的结构是每一个A.java文件旁边都跟着一个A.class文件


[命令行里写java代码](http://www.sergiy.ca/how-to-compile-and-launch-java-code-from-command-line/)这篇文章告诉我们，没有IDE也能写java代码。亲测，用vs code写代码也不算差。文章的大致内容如下:
假定当前项目目录结构如下:
> /bin ##用于存储安装生成的.class文件
 /lib ## 用于放第三方jar文件
  /Okio.jar
 /src ## 用于存放开发写的java文件
    /com
      /example
        /Application.java

```java
package com.example;

import java.io.*;
import okio.BufferedSource;
import okio.Okio;

public class Application {
    public static void main(String[] args) {
        print("Hello there");
        File info = new File("info.txt");
        FileReader reader = null;
        BufferedReader bufferedReader = null;
        try {
            BufferedSource source = null;
            source = Okio.buffer(Okio.source(info));
            // bufferedReader = new BufferedReader(new InputStreamReader(new FileInputStream(info), "UTF-8"));
            String line = "";
            while ((line = source.readUtf8Line()) != null) {
                // print(new String(line.getBytes("GBK"), "UTF-8"));
                print(line);
            }
        } catch (Exception e) {
            //TODO: handle exception
            e.printStackTrace();
        }
    }

    static void print(String out) {
        System.out.println(out);
    }
}
```
注意上面的java文件第一行是有package name声明的。
首先cd到根目录下
> javac -d bin -sourcepath src -cp lib/Okio.jar;lib/gson.jar src/com/example/Application.java

-d的意思是destination, sourcepath就是源码路径 ， -cp其实和-classpath一样

bin目录下就会生成com/example/Application.class文件，这中间的文件层级也生成好了。
还是在根目录下
> java -cp bin;lib/Okio.jar com.example.Application

运行的时候要带上classpath,不然会出现classnotFound
需要注意的是代码中引用的文件路径指的是你当前所在的路径，所以，想要避免FileNotFound的话，需要在当前项目的根目录下放一个"info.txt"文件。其实站在一个command的角度来看，这也正常，外部并未特意声明工作路径，所以jvm运行class文件时就是在当前的目录下进行的。

Some Notes About Classpath，关于classpath的说明。
很多网上的教程都说去自己电脑的环境变量改CLASSPATH这个值，想看下当前是什么样的话 echo %CLASSPATH%
javac编译器在编Application.java这个文件的时候，遇到了com.example.Util这个class，这个文件在哪？根据java命名规则，这个class应该在../com/example/这个文件夹下面。那么这个路径从哪里开始，就是让javac把哪个绝对路径当做根路径？
三种方式:
>If no --classpath parameter is passed, CLASSPATH environment variable is used
If CLASSPATH environment variable is not found, current folder (".") is used by default
If --classpath is explicitly set as a command line parameter, it overrides all other values

> java -cp bin;lib/Okio.jar com.example.Application

运行的时候需要带上bin这个classpath的原因是设定了classpath就会覆盖掉其他设定，所以要把我们自己的java文件打出来的class文件也加到classpath。还有要注意的是，unix系统上classpath之间是用:分割的，windows上是用;分割的


### 43 . java读文件也要注意编码问题(FileReader读取文件里文乱码问题)
```java
import java.io.*;

public class Sample {
    public static void main(String[] args) {
        print("Hello there");
        File info = new File("info.txt");
        FileReader reader = null;
        BufferedReader bufferedReader = null;
        try {
            reader = new FileReader(info);
            bufferedReader = new BufferedReader(reader);
            // bufferedReader = new BufferedReader(new InputStreamReader(new FileInputStream(info), "UTF-8"));
            String line = "";
            while ((line = bufferedReader.readLine()) != null) {
                print(new String(line.getBytes("GBK"), "UTF-8")); //这样输出大部分正确，但是带了一些乱码，显示成问号
                // print(line); 改用utf-8构造函数的InputStreamReader之后，直接print出来就丝毫不差了
            }
        } catch (Exception e) {
            //TODO: handle exception
            e.printStackTrace();
        }
    }

    static void print(String out) {
        System.out.println(out);
    }
}
```
原理的话，文件读入时是按OS的默认字符集即GBK解码的，windows上默认是GBK(中文的win10)，String.getBytes("GBK")就是把按照GBK编码的内容还原成二进制数据，再用UTF-8去new String，照说没问题，结果大部分汉字显示出来，但是部分汉字后面跟着问号。
原因的话，FileReader继承了InputStreamReader，没有实现InputStreamReader的带charset的构造函数。
FileReader属于字符流，是读取字符文件的便捷类。其继承自InputStreamReader，后者是将字节流转换为字符流的的桥梁，即将字节信息转换为字符信息。实际上， FileReader在类内部实现过程中也是利用了InputStreamReader完成字节流到字符流的转化，只不过转化时采用的字符集为系统默认的字符集。
如果文件保存时的编码设定为UTF-8， 那么在中文操作系统使用 FileReader时就会发生乱码，因为中文操作系统平台的默认字符集为GBK。
解决该问题的办法是，放弃使用FileReader，改用InputStreamReader，在获取InputStreamReader对象时，显示指定合适的字符集。
从源码来看，FileReader的read方法直接调用了InputStreamReader的read方法，在没有传编码进来的情况下，FileReader(InputStreamReader)直接用操作系统默认编码(GBK)去解码一个UTF-8的文件，当然会有损失。
[The constructors of FileReader always use the platform default encoding which is generally a bad idea.](https://stackoverflow.com/questions/696626/java-filereader-encoding-issue)。

或者，在notpadPLus中新建一个txt文件，编码字符集->中文->GB2312(simplified)。这样这个文件本身就是GB2312编码的，那个FileReader用GBK去解码，自然不会存在损失，拿着解码后的二进制流给System.out去打印肯定没问题。所以，照说一个文本文件(编码是针对字符来说的，二进制文件是解码之后的东西)，想看编码格式的话，用Notepad++就好了。windows下建议使用utf-8不带BOM格式。很有意思的是我在vs code里面查看这个GB2312的文本文件，全是乱码，给当成utf-8处理了。。。。


### 44 . 主函数的参数
顺便提一下，主函数里面的args是可以用的
```java
public static void main(String[] args){
                          System.out.println("args[0] is"+args[0]);
                          System.out.println("args[1] is"+args[1]);
                          System.out.println("args[2] is"+args[2]);
                }
```
### 45. 打jar包(命令行还是ide)
> jar -cvf HelloWorld.jar HelloWorld.class   #将HelloWorld.class文件打入jar包
> jar cvf xxx.jar ./ 打当前所有的class
> jar cvfm xxx.jar ./META-INF/MANIFEST.MF ./ ##修改jar包，使用原有的manifest文件

[创建一个jar包可以使用命令行，也可以使用maven](https://dzone.com/articles/java-8-how-to-create-executable-fatjar-without-ide)
如果想要让这个jar文件变成可执行的，需要添加一个Manifest.txt文件,在里面包含Main-Class内容
[stackoverflow的解释]](https://stackoverflow.com/questions/4597866/java-creating-jar-file)

[创建一个可执行的jar包](https://www.javatpoint.com/how-to-make-an-executable-jar-file-in-java)
First.java
```java
import javax.swing.*;    
public class First{    
First(){    
JFrame f=new JFrame();    
                    
JButton b=new JButton("click");    
b.setBounds(130,100,100, 40);    
        
f.add(b);    
            
f.setSize(300,400);    
f.setLayout(null);    
f.setVisible(true);    
            
f.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);    
}    
public static void main(String[] args) {    
    new First();    
}    
}    
```

myfile.mf
> Main-Class: First

注意在className后面必须有一个换行（In mf file, new line is must after the class name.）

>javac First.java
jar -cvmf myfile.mf myjar.jar First.class
java -jar myjar.jar ## 即可运行





[intelij idea打jar包更简单](http://blog.csdn.net/xuemengrui12/article/details/74984731)


### 46. DateFormats are not thread-safe，多线程下不安全
[stackoverFlow上有人说DateFormat本身不是线程安全的](https://stackoverflow.com/questions/2409657/call-to-method-of-static-java-text-dateformat-not-advisable)，简单来说就是多条线程调用DateFormat的format方法，得到的String结果 **有可能** 是错的。
```java
public class Test{
    private SimpleDateFormat dateFormat ;
    public static void main(String[] args) {
        SimpleDateFormat dateFormat= new SimpleDateFormat("yyyy-MM-dd");
        Date today = new Date();
        Date tomorrow = new Date(today.getTime()+1000*60*60*24);
        System.out.println(today); // 今天是2010-01-11
        System.out.println(tomorrow); // 明天是2010-01-11
        Thread thread1 = new Thread(new Thread1(dateFormat,today));
        thread1.start();
        Thread thread2 = new Thread(new Thread2(dateFormat,tomorrow));
        thread2.start();
    }

}
class Thread1 implements Runnable{
    private SimpleDateFormat dateFormat;
    private Date date;
    public Thread1(SimpleDateFormat dateFormat,Date date){
        this.dateFormat = dateFormat;
        this.date = date;
    }
    public void run() {
        for(;;){// 一直循环到出问题为止吧。
            String strDate = dateFormat.format(date);
            // 如果不等于2018-03-19，证明出现线程安全问题了！！！！
            if(!"2018-03-19".equals(strDate)){
                System.err.println("format 出来的 today="+strDate);
                System.exit(-1);
            }
        }
    }
}
class Thread2 implements Runnable{
    private SimpleDateFormat dateFormat;
    private Date date;
    public Thread2(SimpleDateFormat dateFormat,Date date){
        this.dateFormat = dateFormat;
        this.date = date;
    }
    public void run() {
        for(;;){
            String strDate = dateFormat.format(date);
            if(!"2018-03-20".equals(strDate)){
                System.err.println("format 出来的 tomorrow="+strDate);
                System.exit(-1);
            }
        }
    }
}
```
一般来说的解决方案是用ThreadLocal，每条线程都保留一份备份，就不会出问题了


### 47. equals()方法被override时，hashCode()也要被override
现象就是如果两个业务上应该相同的object
```java
public class EqualsTest {
    public static void main(String[] args) {
        Employee e1 = new Employee();
        Employee e2 = new Employee();

        e1.setId(100);
        e2.setId(100);
        //Prints false in console
        System.out.println(e1.equals(e2)); //如果业务上要求具有相同id的用户视为同一个用户，需要复写equals

        Set<Employee> employees = new HashSet<Employee>();
       employees.add(e1);
       employees.add(e2);
       //Prints two objects
       System.out.println(employees); //但此时只应该打印出一个object，因为二者在业务上应该视为同一个对象处理，也就违反了HashSet不能存储重复元素的原则。
    }
}

//在HashMap的getNode方法

do {
    if (e.hash == hash &&
        ((k = e.key) == key || (key != null && key.equals(k))))
        return e;
    } while ((e = e.next) != null);
//优先根据hashCode去获取    
```
HashMap 底层采用一个 Entry[] 数组来保存所有的 key-value 对，当需要存储一个 Entry 对象时，会根据hash算法来决定其在数组中的存储位置，在根据equals方法决定其在该数组位置上的链表中的存储位置；当需要取出一个Entry时，也会根据hash算法找到其在数组中的存储位置，再根据equals方法从该位置上的链表中取出该Entry。

**那么复写了hashCode之后，一定要复写equals方法吗。**

### 48. maven的一些东西
maven官网提供的通过命令行创建一个maven项目的方法
```
mvn -B archetype:generate -DarchetypeGroupId=org.apache.maven.archetypes -DgroupId=com.mycompany.app -DartifactId=my-app

mvn compile ##开始编译
```
[maven getting started是很友好的教程](https://maven.apache.org/guides/getting-started/index.html#How_do_I_make_my_first_Maven_project)


### 49. WeakHashmap还是LeakHashmap
```html
An entry in a <tt>WeakHashMap</tt> will automatically be removed when
* its key is no longer in ordinary use.  More precisely, the presence of a
* mapping for a given key will not prevent the key from being discarded by the
* garbage collector, that is, made finalizable, finalized, and then reclaimed.
* When a key has been discarded its entry is effectively removed from the map,
* so this class behaves somewhat differently from other <tt>Map</tt>
* implementations.
```
weakHashmap中的Entry长这样：
```java
 private static class Entry<K,V> extends WeakReference<Object> implements Map.Entry<K,V> {
        V value;
        final int hash;
        Entry<K,V> next;

        /**
         * Creates new entry.
         */
        Entry(Object key, V value,
              ReferenceQueue<Object> queue,
              int hash, Entry<K,V> next) {
            super(key, queue); //就是把key作为weakReference包装起来了
            this.value = value;
            this.hash  = hash;
            this.next  = next;
        }

        }
```
多数的说法都是weakHashMap持有key的弱引用，value的强引用
[关于string作为key和常量池的问题](https://dzone.com/articles/the-interesting-leak)
这里面还谈到了
```java
String a = "a"+"b";
//反编译后发现这样的代码会直接被编译器优化成
String a = "ab";

String b = new String("Something");//new String()方法搞出来的String是不会放到常量池的

String c = b.intern(); //这么干就把Something这个String丢到常量池去了，永远不会被GC

```

[Brian Goetz写过一篇关于WeakHashmap的文章](https://www.ibm.com/developerworks/library/j-jtp11225/index.html)


### 50. 使用ByteBuffer进行文件io操作
这个其实要看使用场景，比方说文件大小
```java
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
 
 // 小文件直接读完
public class ReadFileWithFileSizeBuffer
{
    public static void main(String args[])
    {
        try
        {
            RandomAccessFile aFile = new RandomAccessFile(
                            "test.txt","r");
            FileChannel inChannel = aFile.getChannel();
            long fileSize = inChannel.size();
            ByteBuffer buffer = ByteBuffer.allocate((int) fileSize);
            inChannel.read(buffer);
            //buffer.rewind();
            buffer.flip();
            for (int i = 0; i < fileSize; i++)
            {
                System.out.print((char) buffer.get());
            }
            inChannel.close();
            aFile.close();
        }
        catch (IOException exc)
        {
            System.out.println(exc);
            System.exit(1);
        }
    }
}


import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
 
 // 读取大文件
public class ReadFileWithFixedSizeBuffer
{
    public static void main(String[] args) throws IOException
    {
        RandomAccessFile aFile = new RandomAccessFile
                ("test.txt", "r");
        FileChannel inChannel = aFile.getChannel();
        ByteBuffer buffer = ByteBuffer.allocate(1024);
        while(inChannel.read(buffer) > 0)
        {
            buffer.flip();
            for (int i = 0; i < buffer.limit(); i++)
            {
                System.out.print((char) buffer.get());
            }
            buffer.clear(); // do something with the data and clear/compact it.
        }
        inChannel.close();
        aFile.close();
    }
}

//更快的复制文件
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
 
public class ReadFileWithMappedByteBuffer
{
    public static void main(String[] args) throws IOException
    {
        RandomAccessFile aFile = new RandomAccessFile
                ("test.txt", "r");
        FileChannel inChannel = aFile.getChannel();
        MappedByteBuffer buffer = inChannel.map(FileChannel.MapMode.READ_ONLY, 0, inChannel.size());
        buffer.load(); 
        for (int i = 0; i < buffer.limit(); i++)
        {
            System.out.print((char) buffer.get());
        }
        buffer.clear(); // do something with the data and clear/compact it.
        inChannel.close();
        aFile.close();
    }
}
```

### 51. Class.forName...
在App启动的时候在另外一个线程里面提前去加载这个class，能够加快速度吗？

todo a pratical cheetsheet on java reflection

=========================================
[反射为什么慢，慢成什么样了](https://github.com/hehonghui/android-tech-frontier/blob/master/issue-45/%E4%BD%BF%E7%94%A8%E5%8F%8D%E5%B0%84%E5%88%B0%E5%BA%95%E4%BC%9A%E5%AF%B9%E6%80%A7%E8%83%BD%E9%80%A0%E6%88%90%E5%A4%9A%E5%A4%A7%E5%BD%B1%E5%93%8D%EF%BC%9F.md)
class的生命周期



## 参考
- [Jake Wharton and Jesse Wilson - Death, Taxes, and HTTP](https://www.youtube.com/watch?v=6uroXz5l7Gk)
- [Android Tech Talk: HTTP In A Hostile World](https://www.youtube.com/watch?v=tfD2uYjzXFo)
- [netty里面使用jvm inline提升运行效率的一个issue](http://normanmaurer.me/blog/2014/05/15/Inline-all-the-Things/) 博客内容非常深入

