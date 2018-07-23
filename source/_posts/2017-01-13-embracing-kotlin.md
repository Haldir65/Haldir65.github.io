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
```

自定义函数

 ```
 fun getStringLength(obj: Any) :Int?{ //问号代表有可能返回空值
    if (obj is String) {
        return obj.length
    }
    return 0
}



 支持lambda
 fun maps(list: List<String>) {
    list.filter { it.startsWith("a") }
            .sortedBy { it }
            .map(String::toUpperCase)
            .forEach(::print)
}

对于函数有新的认识了

public fun isOdd(number: Int) = number % 2 != 0 // 函数也可以用一个等式来表达了
public fun isOdd2(number: Int) :Boolean { //这种就啰嗦点
    return number % 2 != 0
}
 ```


### 2. 集合相关
常用的迭代一个range的方式
```
for (i in 1..3) {
    println(i) //这个打印出来是1，2，3
}

for (i in 6 downTo 0 step 2) {
    println(i)
} //这个打印出来是6 4 2 0
```

```
//带index的迭代一个集合的方式
val quoteParts = " YOU JUST TALKED TO MUCH !".split(" ")
for ((index, value) in quoteParts.withIndex()) {
    print("reading index $index: $value ")
}

//和java定义的List interface不一样，Kotlin定义的interface默认是没有add,remove这些修改性质的方法的。
// 比如说有一个int，想凑到String + int中，不需要String.format了，kotlin给String加上了一个format的ententsion Function，更简单的方式是直接加上美元符号引用即可。感觉和es6很像。


// List<out T>这种集合默认只提供了只读的方法，比如get ,size。想要更改内容需要使用MutableList接口提供的方法
// 直接看代码的话，一个提供了readOnlyMethod，修改(add ,remove ,set ...)的方法是通过MutableList提供的
val numbers: MutableList<Int> = mutableListOf(1, 2, 3)
val readOnlyView: List<Int> = numbers //将原先一个可修改的List包装成一个“只读”的List
println(numbers)        // prints "[1, 2, 3]"
numbers.add(4)
println(readOnlyView)   // prints "[1, 2, 3, 4]" 但是不完全只读，通过修改底层list还是能只读
readOnlyView.clear()    // -> does not compile

val items = listOf(1, 2, 3) //彻底的只读

public interface MutableList<E> : List<E>, MutableCollection<E> {
   override fun clear(): Unit
   public fun add(index: Int, element: E): Unit
}


读取一个List的元素推荐使用数组下标
items.get(0) //ide会提示推荐使用下面这种方式
items[0] //

map也是，推荐通过类似于数组下标的方式去获取value
```


### 3. implementing an interface not like in java
如果接口只有一个方法
简单用lambda

```
button.setOnClickListener( { v-> System.out.print(v.id)})
```
如果有多个方法，语法就显得[啰嗦的多](https://stackoverflow.com/questions/37672023/how-to-create-an-instance-of-anonymous-interface-in-kotlin)

```java
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

提到lambda，可以认为就是一个要执行的规则
```
fun logExecution1(func: () -> String){
        Log.d("tag","before method call")
        func()
        Log.d("tag","after method call")
    }

logExecution1({
           val result = "name"
           result
       })
```     
在high order function的领域里，这就算传入了一个返回值为String的函数，用lambda的话，返回值就不用写return了。好像使用高阶函数，只能这么写lambda.lambda的函数的写法相当邪乎，用两个分号包起来，里面一行行的写，最后也不用写返回值


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

//这种data class会主动对外提供非private属性(都不能叫Field了)的访问权（类似get set）。有些get方法会刻意复写getter
private val foo = calcValue("foo") //这个只会在第一次访问属性的时候调用这个方法
private val bar get() = calcValue("bar") //主动添加的get方法，意味着每次调用属性都会调用这个方法

private fun calcValue(name: String): Int {
    println("Calculating $name")
    return 3
}

// 自定义getter和setter
var stringRepresentation: String
    get() = this.toString()
    set(value) {
        setDataFromString(value) // parses the string and assigns values to other properties
    }

```

对于不希望生成getter和setter的filed，使用@jvmFiled的注解标识即可

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

// when ... is ...是根据传入的object的class类型来进行判断的
when (x) {
    is Foo -> ...
    is Bar -> ...
    else   -> ...
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
### 9. 获取this
使用this@MyActivity即可

### 10. findViewById怎么写
> change
val listView = findViewById(R.id.list) as ListView to
val listView = findViewById<ListView>(R.id.list)

[参考](https://www.jianshu.com/p/e2cb4c65d4ff)
```
封装：
fun <V : View> Activity.bindView(id: Int): Lazy<V> = lazy {
    viewFinder(id) as V
}

private val Activity.viewFinder: Activity.(Int) -> View?
    get() = { findViewById(it) }


之后我们就可以在 Activity 中这样注入 View 了
val mTextView by bindView<TextView>(R.id.text_view)
```


### 11.extends需要把parentClass设置为open
```java
open class MySuperClass(parameter:String)

class MyClass2 {
    object AnonymousSubClass:MySuperClass("something"),MyInterface1,MyInterface2 {

    }
}
```

### 12.没有static 关键字了，静态方法的写法
```
class Controller {
    private val _items = mutableListOf<String>("1","2","4")
     val items: List<String> get() = _items.toList()

    companion object {
        fun checkType(args:Any?){
            when(args){
                is String -> println("This is an String Type")
                is Int -> println("This is Some Integer Number ")
                else -> println("i don't recognize this format doom.....")
            }
        }
    }
}

//外部调用
Controller.checkType(10) // -> This is Some Integer Number
//在另一个class中调用Controller.Companion.checkType(18) //和static方法一样，如果方法是private的话，外部也访问不了
```

所以比如说像Constants这样的东西，也要丢到companion object中了

### 13. class cast
```
val modifiableMap :MutableMap<String,String> = unmodifiableMap as MutableMap<String, String> //使用as关键字
```

### 14. by lazy和lateinit的区别
[参考](http://ebnbin.com/2017/06/16/kotlin_variable_to_be_lazy_or_to_be_late/)
```
val myUtil by lazy {
     MyUtil(parameter1, parameter2)
}
// 第一次调用myUtil的时候会调用

val instance :HashMap<String,String> by lazy {
        HashMap<String,String>()
}
//所以看上去就特别适合作为instance

//官方推荐的实现singleton的方式
object Resource {
    val name = "Name"
}

lateinit var myUtil: MyUtil
// 使用的时候
myUtil = MyUtil(parameter1, parameter2)
// 这明显是把变量的初始化与定义分离开了。
```
显然的区别是一个是val 一个是var。

>如果是值可修改的变量（即在之后的使用中可能被重新赋值），使用 lateInit 模式
如果变量的初始化取决于外部对象（例如需要一些外部变量参与初始化），使用 lateInit 模式。这种情况下，lazy 模式也可行但并不直接适用。
如果变量仅仅初始化一次并且全局共享，且更多的是内部使用（依赖于类内部的变量），请使用 lazy 模式。从实现的角度来看，lateinit 模式仍然可用，但 lazy 模式更有利于封装你的初始化代码。

### 15. NPE还是会有的
```
val files = File("").listFiles()
println(files.size) // crash

val files = File("").listFiles()
println(files?.size) // 输出 null ?的意思类似于优先判空

```

### 16. let ,apply ,with,run方法
```
/**
 * Calls the specified function [block] with `this` value as its argument and returns its result.
 */
// let，其实就是一个实例化的对象上添加一个extension method
val result ="Hello World".let {
        println(it) //这个it是一个关键字
        520
    }

println(result)
输出
"Hello World"
520 //这个时候的result就已经是520了

// 如果不为Null的话，执行下面这一段代码块
val value = ...

value?.let {
    ... // execute this block if not null
}
```

apply的用法
val name =  "myName".apply {
      toUpperCase()
   }
print(name) //出来的还是myName，也就是说apply里面的东西不会对值产生影响





### 17. with关键字用于同时调用一个Instance 的多个method
```
class Turtle {
    fun penDown()
    fun penUp()
    fun turn(degrees: Double)
    fun forward(pixels: Double)
}

val myTurtle = Turtle()
with(myTurtle) { //draw a 100 pix square
    penDown()
    for(i in 1..4) {
        forward(100.0)
        turn(90.0)
    }
    penUp()
}  

// java7 的try with resources
val stream = Files.newInputStream(Paths.get("/some/file.txt"))
stream.buffered().reader().use { reader ->
    println(reader.readText())
}
```

### 18. class还是File
新建一个class和新建一个File有什么区别，File里面可以写多个class，每个class都是类似于java中static inner class，互相之间是不能引用到的。
内部类不是像Java那样写在里面就能引用到外部类了，kotlin写在里面的class默认是引用不到外面class的field和方法的，需要给内部class加上inner关键词。

java里面写习惯了.class对象，在kotlin中得这么写:
```java
retrofit.create(ApiStores.class) //java写法

retrofit.create(ApiStores::class.java) // kotlin写法
```

init函数和constructor是有区别的
[What are the Kotlin class initialisation semantics?
](https://stackoverflow.com/questions/33688821/what-are-the-kotlin-class-initialisation-semantics).简单来说，init函数


## 19. ? extends T怎么写
var lst = ArrayList<Class<out Number>>()
lst.add(Noun_Class::class.java)



[stackoverflow](https://stackoverflow.com/questions/45267041/not-enough-information-to-infer-parameter-t-with-kotlin-and-android)
init代码块不是构造函数，同时，init的执行效果要看写在哪一行了，如果在Init中引用了一个propertity，这个属性要是在Init之前就初始化了那倒还好，要是在后面,那么在init调用的时候看到的就是null.

### ref

1. [Kotlin in production](https://www.youtube.com/watch?v=mDpnc45WwlI&index=10&list=PLnVy79PaFHMXJha06t6pWfkYcATV4oPvC)
2. [10 Kotlin Tricks in 10 ish minutes by Jake Wharton](https://www.youtube.com/watch?v=YKzUbeUtTak)​
3. [Try Kotlin](https://try.kotlinlang.org/#/Examples/Basic%20syntax%20walk-through/Null-checks/Null-checks.kt)
4. [What can Kotlin do for me? (GDD Europe '17)](https://www.youtube.com/watch?v=YbF8Q8LxAJs)
