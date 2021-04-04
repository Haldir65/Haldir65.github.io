---
title: 位运算总结
date: 2017-07-23 19:06:46
tags: [java,tools]
---

位运算的好处至少有两点，由于是直接操作bit,没有任何包装类，速度快。另外一个就是节省内存了。

![](https://api1.foster57.tk/static/imgs/8af185ed137a586be732d63425d8bcb8.jpg)
<!--more-->

## 1.左移（<<）
```java
public class Test {  
    public static void main(String[] args) {  
        System.out.println(5<<2);//运行结果是20  
    }  
}
```
原理：
5的二进制表示方式是：
0000 0000 0000 0000 0000 0000 0000 0101
向左挪两位就变成了
0000 0000 0000 0000 0000 0000 0001 0100 //末位补零 ，也就是20

可以认为 5<<n就代表乘以2的n次方
所以10KB可以这么写 ： 10<<10

## 2.右移(>>)
和左移反过来，前面补0。一样的道理，不再赘述。


## 3. 无符号右移(>>>)
在java中一个int占32位，正数的首位是0，负数位-1。
首先说一下负数怎么算出来二进制表示的(原码，补码，反码)在计算机中，负数以其正值的补码形式表达
> 计算机对有符号数（包括浮点数）的表示有三种方法：原码、反码和补码， 补码=反码+1。在 二进制里，是用 0 和 1 来表示正负的，最高位为符号位，最高位为 1 代表负数，最高位为 0 代表正数。

以-5为例
1. 先将-5的绝对值转成二进制： 00000000 00000000 00000000 00000101
2. 然后求该二进制的反码(~)， 也就是0变成1,1变成0，得到11111111 11111111 11111111 11111010
3. 然后把得到的反码加1 ，得到11111111 11111111 11111111 11111010 + 1 = 11111111 11111111 11111111 11111011

因此-5 就是
11111111 11111111 11111111 11111011
0xFFFFFFFB（16进制写法）

正数右移，高位用0补；负数右移，高位用1补；负数无符号右移，用0补高位。

所以-5>>>3 也就变成了
0001 1111 1111 1111 1111 1111 1111 1111 //十进制536870911

注意，正数或者负数左移，低位都是用0补

## 4. 位与(&)
看实例:
```java
public static void main(String[] args) {  
       System.out.println(5 & 3);//结果为1  
   }  
```

原因： 5的二进制是： 0000 0000 0000 0000 0000 0000 0000 0101
      3的二进制是：  0000 0000 0000 0000 0000 0000 0000 0011
同一位上必须都为1，结果才为1，否则为0；于是结果就得到：
      0000 0000 0000 0000 0000 0000 0000 0001 = 1

## 5. 位或（|）
和位与相反
同一位上只要有一个为1，就为1.只有两个都为0，才为0.
二进制下：
      5的二进制是： 0000 0000 0000 0000 0000 0000 0000 0101
      3的二进制是： 0000 0000 0000 0000 0000 0000 0000 0011
所以结果是 7        0000 0000 0000 0000 0000 0000 0000 0111
所以 (5|3) = 7(这让人想到linux文件权限的777)


其实就是 111 111 111 （owner,creater,others）

## 6. 位异或(^)
还是拿5和3一起算
第一个操作数的的第n位于第二个操作数的第n位 相反，那么结果的第n为也为1，否则为0
二进制下：
      5的二进制是： 0000 0000 0000 0000 0000 0000 0000 0101
      3的二进制是： 0000 0000 0000 0000 0000 0000 0000 0011
所以结果是 6        0000 0000 0000 0000 0000 0000 0000 0110
所以a^b可以用来判断两个Flag前后有没有发生变化，有时候如果发现前后flag没有变化，即不操作。


## 7.位非(~)
位非是一元操作符，对一个数进行操作
位非：操作数的第n位为1，那么结果的第n位为0，反之为1，就是所有的1变成0,0变成1。
 5的二进制是： 0000 0000 0000 0000 0000 0000 0000 0101
 倒过来就是：  1111 1111 1111 1111 1111 1111 1111 1010
负整数转二进制的标准方法：先是将对应的正整数转换成二进制后，对二进制取反，然后对结果再加一。

## 8.一些衍生的操作符
从上面的一些基本操作符衍生来的有


```
&= 按位与赋值
|=  按位或赋值
^= 按位非赋值
>>= 右移赋值
>>>= 无符号右移赋值
<<= 赋值左移
```


和+=一个意思。至于那个运算符优先级，算了吧。


## 9.一些常用的小技巧

// 1. 获得int型最大值
System.out.println((1 << 31) - 1);// 2147483647， 由于优先级关系，括号不可省略
System.out.println(~(1 << 31));// 2147483647

// 2. 获得int型最小值
System.out.println(1 << 31);
System.out.println(1 << -1);

// 3. 获得long类型的最大值
System.out.println(((long)1 << 127) - 1);

// 4. 乘以2运算
System.out.println(10<<1);

// 5. 除以2运算(负奇数的运算不可用)
System.out.println(10>>1);

// 6. 乘以2的m次方
System.out.println(10<<2);

// 7. 除以2的m次方
System.out.println(16>>2);

// 8. 判断一个数的奇偶性
System.out.println((10 & 1) == 1);
System.out.println((9 & 1) == 1);

// 9. 不用临时变量交换两个数（面试常考）
a ^= b;
b ^= a;
a ^= b;

// 10. 取绝对值（某些机器上，效率比n>0 ? n:-n 高）
int n = -1;
System.out.println((n ^ (n >> 31)) - (n >> 31));
/* n>>31 取得n的符号，若n为正数，n>>31等于0，若n为负数，n>>31等于-1
若n为正数 n^0-0数不变，若n为负数n^-1 需要计算n和-1的补码，异或后再取补码，
结果n变号并且绝对值减1，再减去-1就是绝对值

// 11. 取两个数的最大值（某些机器上，效率比a>b ? a:b高）
System.out.println(b&((a-b)>>31) | a&(~(a-b)>>31));

// 12. 取两个数的最小值（某些机器上，效率比a>b ? b:a高）
System.out.println(a&((a-b)>>31) | b&(~(a-b)>>31));

// 13. 判断符号是否相同(true 表示 x和y有相同的符号， false表示x，y有相反的符号。)
System.out.println((a ^ b) > 0);
所以在Android的View.java中
```java
void setFlags(int flags, int mask) {
      final boolean accessibilityEnabled =
              AccessibilityManager.getInstance(mContext).isEnabled();
      final boolean oldIncludeForAccessibility = accessibilityEnabled && includeForAccessibility();

      int old = mViewFlags;
      mViewFlags = (mViewFlags & ~mask) | (flags & mask);

      int changed = mViewFlags ^ old; //如果和旧的flag一致，直接return
      if (changed == 0) {
          return;
      }
    // 以下省略、、、、、、、
    }
```


// 14. 计算2的n次方 n > 0
System.out.println(2<<(n-1));

// 15. 判断一个数n是不是2的幂
System.out.println((n & (n - 1)) == 0);
/*如果是2的幂，n一定是100... n-1就是1111....
所以做与运算结果为0*/

// 16. 求两个整数的平均值
System.out.println((a+b) >> 1);

// 17. 从低位到高位,取n的第m位
int m = 2;
System.out.println((n >> (m-1)) & 1);

// 18. 从低位到高位.将n的第m位置为1
System.out.println(n | (1<<(m-1)));
/*将1左移m-1位找到第m位，得到000...1...000
n在和这个数做或运算*/

// 19. 从低位到高位,将n的第m位置为0
System.out.println(n & ~(0<<(m-1)));
/* 将1左移m-1位找到第m位，取反后变成111...0...1111
n再和这个数做与运算*/

//不用加减乘除计算实现一个加法
```java
public class Solution {
    public int Add(int num1,int num2) {
        while (num2!=0) {
            int temp = num1^num2;
            num2 = (num1&num2)<<1;
            num1 = temp;
        }
        return num1;
    }
}
```

[牛客网](https://www.nowcoder.com/questionTerminal/59ac416b4b944300b617d4f7f111b215)
首先看十进制是如何做的： 5+7=12，三步走
第一步：相加各位的值，不算进位，得到2。
第二步：计算进位值，得到10. 如果这一步的进位值为0，那么第一步得到的值就是最终结果。

第三步：重复上述两步，只是相加的值变成上述两步的得到的结果2和10，得到12。

同样我们可以用三步走的方式计算二进制值相加： 5-101，7-111 第一步：相加各位的值，不算进位，得到010，二进制每位相加就相当于各位做异或操作，101^111。

第二步：计算进位值，得到1010，相当于各位做与操作得到101，再向左移一位得到1010，(101&111)<<1。

第三步重复上述两步， 各位相加 010^1010=1000，进位值为100=(010&1010)<<1。
     继续重复上述两步：1000^100 = 1100，进位值为0，跳出循环，1100为最终结果。


## 结束

1. 记得Chet Haase和Romain Guy曾经在2013年的一次[演讲](https://www.youtube.com/watch?v=Ho-anLsWvJo)中提到,Android中View内部使用了3个int来表示70多个Flags。如果换做boolean(4byte大小)的话，就需要接近300bytes。由于View在Application中被广泛（成百上千）使用，framework这样做事实上为开发者节约了相当多的内存。
View.java里面放了好几个flags。
android.view.View.java

```java
/* @hide */
   public int mPrivateFlags;
   int mPrivateFlags2;
   int mPrivateFlags3;

   // The view flags hold various views states.
   int mViewFlags;
```
int中的每一个bit都成为一个boolean，一共只用了12bytes(96bits)的内存.和300bytes相比，节省的内存总量还是相当可观的。
一个onClickListener大概500bytes
所以View.java中到处是这样的奇怪的Flags

```java
  public void setDrawingCacheEnabled(boolean enabled) {
        mCachingFailed = false;
        setFlags(enabled ? 0x00008000 : 0, 0x00008000);
    }

    @ViewDebug.ExportedProperty(category = "drawing")
    public boolean isDrawingCacheEnabled() {
        return (mViewFlags & 0x00008000) == 0x00008000;
    }
```
除了省内存，位运算速度快也有一定的好处。

2. 来看看Android中的ViewGroup是怎么干的

```java
   // Set by default
   static final int FLAG_CLIP_CHILDREN = 0x1;   //二进制的1

   private static final int FLAG_CLIP_TO_PADDING = 0x2; //二进制的10

   static final int FLAG_INVALIDATE_REQUIRED  = 0x4; //二进制 100

   private static final int FLAG_RUN_ANIMATION = 0x8; //二进制1000

   static final int FLAG_ANIMATION_DONE = 0x10; //二进制 10000


   private static final int FLAG_PADDING_NOT_NULL = 0x20;//二进制 100000

   /** @deprecated - functionality removed */
   private static final int FLAG_ANIMATION_CACHE = 0x40;//二进制 1000000

   static final int FLAG_OPTIMIZE_INVALIDATE = 0x80;//二进制 10000000

   static final int FLAG_CLEAR_TRANSFORMATION = 0x100;//二进制 100000000

   private static final int FLAG_NOTIFY_ANIMATION_LISTENER = 0x200;//二进制 1000000000


   protected static final int FLAG_USE_CHILD_DRAWING_ORDER = 0x400;//二进制 10000000000

   //还有更多。

   if ((flags & FLAG_INVALIDATE_REQUIRED) == FLAG_INVALIDATE_REQUIRED) {
     //按为与 两个都为1才为1，所以只有当前flag小于FLAG_INVALIDATE_REQUIRED的时候这个表达式才成立
             invalidate(true);
         }

```

[java-integer-flag-and-bitwise-operations-for-memory-reduction](https://stackoverflow.com/questions/7415590/java-integer-flag-and-bitwise-operations-for-memory-reduction)stackoverflow上有人回答了关于用一个int的flag替代32个boolean的利弊。要点如下:
> 大多数jvm implementation都以一个int的方式存储boolean
> 如果一个class里面滥用一大堆boolean，但这个class的实例不过几百个，那么也不会有什么影响
> 位运算对于cpu来说非常快
> jdk提供了BitSet，属于一种开箱即用的bit操作工具

下面是google 关键词 int flag找到的一段java代码。这是代表各种state之间互斥的。

```java
public static final int UPPERCASE = 1;  // 0001
public static final int REVERSE   = 2;  // 0010
public static final int FULL_STOP = 4;  // 0100
public static final int EMPHASISE = 8;  // 1000
public static final int ALL_OPTS  = 15; // 1111

public static String format(String value, int flags)
{
    if ((flags & UPPERCASE) == UPPERCASE) value = value.toUpperCase();

    if ((flags & REVERSE) == REVERSE) value = new StringBuffer(value).reverse().toString();

    if ((flags & FULL_STOP) == FULL_STOP) value += ".";

    if ((flags & EMPHASISE) == EMPHASISE) value = "~*~ " + value + " ~*~";

    return value;
}
```
可以想象的是，View中一个int，32个小槽子(bit)，每一位都能用来代表isSelected,isFocused,XXX等属性。
检查是否有某个flag只需要
```java
public class BitFlags
{
    public static boolean isFlagSet(byte value, byte flags)
    {
        return (flags & value) == value;//和上面的FLAG_INVALIDATE_REQUIRED一模一样
    }

    public static byte setFlag(byte value, byte flags)
    {
        return (byte) (flags | value);
    }

    public static byte unsetFlag(byte value, byte flags)
    {
        return (byte) (flags & ~value);
    }
}
```


3. 不要迷信位运算，对于一些简单的操作，现代编译器还是能够帮助开发者自动做好优化的。

4. 从java7开始，可以在java代码里[直接写二进制，八进制，十六进制的数字了](https://www.bbsmax.com/A/xl569bA1Jr/)

```java
//16进制
jdk6写法：
public static void main(String[] args) {

         int res = Integer.parseInt("A", 16);
         System.out.println(res);
     }
jdk7写法：
public static void main(String[] args) {

         int res = 0xA;
         System.out.println(res);
     }

// 8进制
jdk6写法:
 public static void main(String[] args) {

         int res = Integer.parseInt("11",8);
         System.out.println(res);
     }
jdk7写法:
public static void main(String[] args) {

         int res = 011;
         System.out.println(res);
     }

//二进制
jdk6写法:
public static void main(String[] args) {

         int res = Integer.parseInt("1100110", 2);
         System.out.println(res);
     }
jdk7写法:
public static void main(String[] args) {

         int res = 0b1100110;
         System.out.println(res);
     }
```
即：
二进制： int res = 0b110; 六（0B也行，0b01_10010_0这种加下划线也行）
八进制： int res = 0110; 七十二
十六进制： int res = 0xA;  十

5. View.MeasureSpec就是32位的int
前2位是mode(能表示四种，够了),后30位是size
文档的定义是：
MeasureSpecs are implemented as ints to reduce object allocation. This class
is provided to pack and unpack the size, mode tuple into the int
就是为了节省内存，才用的位运算

```java
public static class MeasureSpec {
       private static final int MODE_SHIFT = 30;
       private static final int MODE_MASK  = 0x3 << MODE_SHIFT;

       /** @hide */
       @IntDef({UNSPECIFIED, EXACTLY, AT_MOST})
       @Retention(RetentionPolicy.SOURCE)
       public @interface MeasureSpecMode {}

       public static final int UNSPECIFIED = 0 << MODE_SHIFT;//(就是00后面跟30个0)

       public static final int EXACTLY     = 1 << MODE_SHIFT;//（就是01后面跟30个0）

       public static final int AT_MOST     = 2 << MODE_SHIFT;// (就是10后面跟30个0)

       public static int getMode(int measureSpec) {
                  //noinspection ResourceType
                  return (measureSpec & MODE_MASK); //按位与，都是1才能得到1，就是把一个Int的32位中前两位提取出来
              }

        public static int getSize(int measureSpec) {
            return (measureSpec & ~MODE_MASK); //按位与加上位非，二进制取反，结果加一
        }      // ~MODE_MASK就是01后面跟30个0，所以等于直接把measureSpec后三十位拿出来转成int。
     }
```
所以就是一个int存了状态以及大小两部分信息。
多说一句measureSpec是在ViewGroup.getChildMeasureSpec里面算出来的，是parent用来跟child交流的，一般用View.resolveSize就知道到底得多大了。


| 名称 | 含义 | 数值（二进制） |具体表现 |
| ------ | ------ | ------ |------ |
| UNSPECIFIED | 父View不对子View 施加任何约束，子View可以是它想要的任何尺寸 | 00 ...(30个0) |系统内部使用 |
| EXACTLY | 父View已确定子View 的确切大小，子View的大小为父View测量所得的值 | 01 ...(30个0) |具体数值、match_parent |
| AT_MOST | 父View 指定一个子View可用的最大尺寸值，View大小 不能超过该值。 | 10 ...(30个0) |wrap_content |



## 参考
- [Java位运算操作全面总结](https://my.oschina.net/xianggao/blog/412967)
- [Java 位运算(移位、位与、或、异或、非）](http://blog.csdn.net/xiaochunyong/article/details/7748713)
