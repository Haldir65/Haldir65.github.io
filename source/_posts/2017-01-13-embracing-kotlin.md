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


### 3. implementing an interface not like in java
如果接口只有一个方法
简单用lambda
```
button.setOnClickListener( { v-> System.out.print(v.id)})
```
如果有多个方法，语法就显得[啰嗦的多](https://stackoverflow.com/questions/37672023/how-to-create-an-instance-of-anonymous-interface-in-kotlin)
```
val handler = object : DisposableObserver<Bitmap>() {
        override fun onError(e: Throwable) {
           LogUtil.d("e")
        }

        override fun onNext(t: Bitmap) {
            image_two!!.setImageBitmap(t)
        }

        override fun onComplete() {
            LogUtil.d("completed")
        }
    }
```
### 4. 没有new关键字了
```
class somClass{
  fun printMsg(msg : String){
    println(msg)
  }
}

fun main(args: Array<String>){
  val instance  = somClass() // 直接把new给删了
  instance.printMsg("Hey there")
}

```

### 5. java Bean不需要写废话了
```
data class SomeThing(val id: Int)

//用的时候

val instance = SomeThing(10)
```

### 6. 具有更好语义的typealis
```
typealias CustomerName = String

data class Customer(val name: CustomerName,val email: String)
```
跟linux上的alias差不多，CustomerName其实就是String，但使用typealias使得传数据时更不容易错误。

### 7. switch case用when来写
```
fun returnSomeThing(input :Any) : String{
    val actual = when(input){

        1 -> {
            println("1")
        }

        2 -> {
            println("2")
        }

        is Int -> {
            println("is Int")
        }

        else ->{
            println("don't know which one")
        }
    }

    return actual.toString()

}
```

### 8. 能够接受一个函数作为参数
在调用一些资源的时候，经常需要用完了关闭掉
```
fun using(resource: Closeable, body: () -> Unit) {
    try {
        body()
    }finally {
        resource.close()
    }
}

val inputstram = FileInputStream("/") as FileInputStream

   using(inputstram){
    //  do stuff with this resource
    // it will close for you
   }
```




### ref

1. [Kotlin in production](https://www.youtube.com/watch?v=mDpnc45WwlI&index=10&list=PLnVy79PaFHMXJha06t6pWfkYcATV4oPvC)
2. [10 Kotlin Tricks in 10 ish minutes by Jake Wharton](https://www.youtube.com/watch?v=YKzUbeUtTak)​
3. [Try Kotlin](https://try.kotlinlang.org/#/Examples/Basic%20syntax%20walk-through/Null-checks/Null-checks.kt)
4. [What can Kotlin do for me? (GDD Europe '17)](https://www.youtube.com/watch?v=YbF8Q8LxAJs)
