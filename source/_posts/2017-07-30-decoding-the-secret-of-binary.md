---
title: 二进制编码总结
date: 2017-07-30 17:45:51
tags: [java,tools]
---

![](http://odzl05jxx.bkt.clouddn.com/01f691dea62d22e138481a353fbb6228.jpg?imageView2/2/w/600)

<!--more-->
## 1.重新学习Java基本数据类型

### 基本数据类型之间的转换
初学java的时候都说没必要记住各种基本数据类型的大小范围。这里补上一些：

```
byte：8位，最大存储数据量是255，存放的数据范围是-128~127之间。

short：16位，最大数据存储量是65536，数据范围是-32768~32767之间。

int：32位，最大数据存储容量是2的32次方减1，数据范围是负的2的31次方到正的2的31次方减1。

long：64位，最大数据存储容量是2的64次方减1，数据范围为负的2的63次方到正的2的63次方减1。

float：32位，数据范围在3.4e-45~1.4e38，直接赋值时必须在数字后加上f或F。

double：64位，数据范围在4.9e-324~1.8e308，赋值时可以加d或D也可以不加。

boolean：只有true和false两个取值。

char：16位，存储Unicode码，用单引号赋值。
```
这个表的顺序是有道理的，byte->short->int->long这类表示的都是整数（不带小数点的）;
float->double这类表示的都是浮点数(计算机里没有小数点，都是用类似科学计数法来表示的);

后面这俩比较特殊：
boolean只有两个值;
char专门用来表示Unicode码，最小值是0，最大值是65535(2^16-1);

- (这个范围是严格限定的，比如byte a = 127都没问题，byte a = 128 立马编译有问题。)
另外，char是为数不多的可以在java IDE里面像python一样写单引号的机会：
char c = '1' // ok
char c = '12'//错误
char c = 12 //正确


当一个较大的数和一个较小的数在一块运算的时候，系统会自动将较小的数转换成较大的数，再进行运算。[这里的大小指的是基本类型范围的大小](http://www.cnblogs.com/doit8791/archive/2012/05/25/2517448.html)
所以(byte、short、char) -> int -> long -> float -> double这么从小往大转是没有问题的。编译器自动转，所以经常不会被察觉。
byte、short、char这三个是平级的，相互转换也行。
试了下,
```java
byte b = 3;
char c = '2';
short s = 23;

s = b; //只有byte往上转short是自动的
b = (byte) s;


s = (short) c;
c = (char) s;

b = (byte) c;
c = (char) b;
```
强转就意味着可能的精度损失。

所以除去boolean以外:
- char
- byte,short,int,long
- float,double
可以分成这三类，从小往大转没问题，同一类从小到大转没问题。

具体到实际操作上：
1. char->byte->short->int->long->float->double
2. 有一个操作数是long，结果是long
3. 有一个操作数是float,结果是float
4. 有一个操作数是double，结果是double
5. long l = 424323L ,后面的L要大写。
6. 这些整数都是没办法表示一个小数的，要用float或者double，后面加上f（F）或者L。
7. char(16位)，能表示的范围大小和short一样，是用单引号括起来的一个字符(可以是中文字符)，两个字符不行。
8. char的原理就是转成int，根据unicode编码找到对应的符号并显示出来。
9. 两个char相加，就是转成int之后两个int相加
10. double类型后面可以不写D
11. float后面写f或者F都一样



## 2. Encoding解析

java编译器将源代码编译位字节码时，会用int来表示boolean(非零表示真)
byte,short,int,long这些都是有符号的整数，八进制数以0开头，十六进制数字以0x开头




## 参考

[Jesse Wilson | Decoding the Secrets of Binary Data ](https://www.youtube.com/watch?v=T_p22jMZSrk)
