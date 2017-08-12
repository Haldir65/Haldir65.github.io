---
title: 位运算总结
date: 2017-07-23 19:06:46
tags: [java,tools]
---



位运算的好处至少有两点，由于是直接操作bit,没有任何包装类，速度快。另外一个就是节省内存了。

![](http://odzl05jxx.bkt.clouddn.com/8af185ed137a586be732d63425d8bcb8.jpg?imageView2/2/w/600)
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
-5 就是
1111 1111 1111 1111 1111 1111 1111 1011

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
结果n变号并且绝对值减1，再减去-1就是绝对值 */

// 11. 取两个数的最大值（某些机器上，效率比a>b ? a:b高）
System.out.println(b&((a-b)>>31) | a&(~(a-b)>>31));

// 12. 取两个数的最小值（某些机器上，效率比a>b ? b:a高）
System.out.println(a&((a-b)>>31) | b&(~(a-b)>>31));

// 13. 判断符号是否相同(true 表示 x和y有相同的符号， false表示x，y有相反的符号。)
System.out.println((a ^ b) > 0);

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



## 结束
1. 记得Chet Haase和Romain Guy曾经在2013年的一次[演讲](https://www.youtube.com/watch?v=Ho-anLsWvJo)中提到,Android中View内部使用了3个int来表示70多个Flags。如果换做boolean(4byte大小)的话，就需要接近300bytes。由于View在Application中被广泛（成百上千）使用，framework这样做事实上为开发者节约了相当多的内存。
android.view.View.java
```
int mPrivateFlags;
int mPrivateFlags2;
int mPrivateFlags3;
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


2. 不要迷信位运算，对于一些简单的操作，现代编译器还是能够帮助开发者自动做好优化的。

3. 从java7开始，可以在java代码里[直接写二进制，八进制，十六进制的数字了](https://www.bbsmax.com/A/xl569bA1Jr/)
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

## 参考
- [Java位运算操作全面总结](https://my.oschina.net/xianggao/blog/412967)
- [Java 位运算(移位、位与、或、异或、非）](http://blog.csdn.net/xiaochunyong/article/details/7748713)

