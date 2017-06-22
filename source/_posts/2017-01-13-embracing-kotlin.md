---
title: 使用Kotlin进行java开发
date: 2017-01-13 23:06:13
categories: blog 
tags: [kotlin]
---

Kotlin是Jetbrain公司推出的面向jvm的语言，编译后的bytecode和java编写的代码并没有什么区别。

<!--more-->

### 1. 基本语法

 没有new关键字
 ```
 主函数
 fun main(args : Array<String>) {
    for (i in args.indices) {
       print(args[i])
    }
}


自定义函数

 ```
 fun getStringLength(obj: Any) :Int?{ //问号代表有可能返回空值
    if (obj is String) {
        return obj.length
    }
    return 0
}

 ```

 支持lambda
 fun maps(list: List<String>) {
    list.filter { it.startsWith("a") }
            .sortedBy { it }
            .map(String::toUpperCase)
            .forEach(::print)
}
 ```


 

### 2. 集合迭代

 ```
//带index的方式
  val quoteParts = " YOU JUST TALKED TO MUCH !".split(" ")
            for ((index, value) in quoteParts.withIndex()) {
                print("reading index $index: $value ")
            }
 ```




### ref

1. [Kotlin in production](https://www.youtube.com/watch?v=mDpnc45WwlI&index=10&list=PLnVy79PaFHMXJha06t6pWfkYcATV4oPvC)
2. [10 Kotlin Tricks in 10 ish minutes by Jake Wharton](https://www.youtube.com/watch?v=YKzUbeUtTak)​
3. [Try Kotlin](https://try.kotlinlang.org/#/Examples/Basic%20syntax%20walk-through/Null-checks/Null-checks.kt)

