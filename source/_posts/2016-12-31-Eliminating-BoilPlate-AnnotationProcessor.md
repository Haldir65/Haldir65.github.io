---
title: 使用AnnotationProcessor自动生成代码
date: 2016-12-31 22:42:15
categories: blog
tags: [android,annotation]
---


![](http://odzl05jxx.bkt.clouddn.com/apt_01.JPG?imageView2/2/w/500)
记得Romain Guy在一次DroidCon上曾说过:

> As I understand, modern java development are all about wrting annaotation Processors and not wrting code anymore...

全场观众大笑。。。

这之后经常看到Jack Wharton在演讲中提到"My Hypothetical Annotation Processor..." ，后来才意识到像Retrofit，ButterKnife这些都是使用了注解的方式。
 <!--more-->



### 1. 原理介绍
Annotation Processoring Tool是javac的一部分，它会在编译期生成新的.java文件（不是class文件）
定义一个Annotation的语法如下：
```java
@Documented
@Target(ElementType.TYPE)  //这说明生成的注解能够放在class,interface,enum等类型上。不能放在method上
@Retention(RetentionPolicy.SOURCE)  //指明在编译器有效
public @interface Builder {  //@interface就像class,interface,enum一样
}
```

### 2.Annotation Processor是生成新代码的实现类
大致的实现例如：
```java
public class PojoStringProcessor extends AbstractProcessor {
    private static final String ANNOTATION = "@" + PojoString.class.getSimpleName();
    private static final String CLASS_NAME = "StringUtil";
    private Messager messager; //有点像Logger,用于输出信息
    private Filer filer //可以获得Build Path，用于生成文件

    //public构造函数不写也会自动加上

    // init做一些初始化操作
    @Override
    public synchronized void init(ProcessingEnvironment processingEnv) {
        super.init(processingEnv);
        messager = processingEnv.getMessager();
        this.filer = processingEnv.getFiler();
    }

    //apt在检查被注解的class时，会返回你需要的注解类型
    @Override
    public Set<String> getSupportedAnnotationTypes() {
        return immutableSet.of(Builder.class.getCanonicalName());
    }

	 //java7,java8 有点像android的targetSdk Version
    @Override
    public SourceVersion getSupportedSourceVersion() {
        return SourceVersion.latestSupported();
    }



    //重点
    @Override
    public boolean process(Set<? extends TypeElement> annotations, RoundEnvironment roundEnv) {
        ArrayList<AnnotatedClass> annotatedClasses = new ArrayList<>();
        for (Element element : roundEnv.getElementsAnnotatedWith(PojoString.class)) {
            TypeElement typeElement = (TypeElement) element;
            if (!isValidClass(typeElement)) {
                return true; //apt找到的所有被注解的class
            }

            try {
                annotatedClasses.add(buildAnnotatedClass(typeElement));
            } catch (IOException e) {
                String message = String.format("Couldn't process class %s: %s", typeElement,
                        e.getMessage());
                messager.printMessage(Diagnostic.Kind.ERROR, message, element);
                e.printStackTrace();
            }


        }
        try {
            generate(annotatedClasses);
        } catch (IOException e) {
            messager.printMessage(Diagnostic.Kind.ERROR, "Couldn't generate class");
        }

        return true;
    }


}

```
几个重要的方法解释下：
1. roundEnv: apt分两步：1. apt发现被注解的代码，提供给我们写的processor，后者生成新的java代码(apt还未处理这部分新代码)。
2. apt发现新代码，提供给我们的Processor，不生成新代码。完成processing。（后面提供给编译）


ServiceLoader Discovery File（这货在jar中）
//META-INFO/services/javax.annotations.processing.Processor文件中写入
com.example.annotation.BuilderProcessor// class包名
//这里声明所有的processor，这里可以include别的processor

语法：
```java
app/build.gradle

dependencies {
  compile project(': annotation')

  apt project (':processor')
}
//apt 表示processor中的方法不会带到distributed apk中,方法数不用担心了
//https://bitbucket.org/hvisser/android-apt
//https://github.com/tbroyer/gradle-apt-plugin
```



继承AbstractProcessor，必须要有一个无参public构造函数


### 3. 生成新的java方法
首先添加依赖，square的javaPoet

假设想生成的代码是这样的
```java
public final class UserBuilder{

private String userName;

public UserBuilder username(String username){
    this.username = username;
    returen this;
  }

}
```
- 生成变量
![](http://odzl05jxx.bkt.clouddn.com/apt_field.JPG)

- 生成方法
![](http://odzl05jxx.bkt.clouddn.com/apt_methods.JPG)

- 生成class:
![](http://odzl05jxx.bkt.clouddn.com/apt_class.JPG)

直接截图了
- 主要步骤
![](http://odzl05jxx.bkt.clouddn.com/apt_process_steps.JPG)

meta_data
![](http://odzl05jxx.bkt.clouddn.com/apt_process_meta_data.JPG)

- 生成private field和public setter:
> FiledSpec username = FiledSpec.builder(String.class,"username",Modifier.PRIVATE).build();
![](http://odzl05jxx.bkt.clouddn.com/apt_process_fields.JPG)


- 生成build method
![](http://odzl05jxx.bkt.clouddn.com/apt_process_build_method.JPG)

- 生成builder
![](http://odzl05jxx.bkt.clouddn.com/apt_process_create_builder.JPG)

- 写java文件：
![](http://odzl05jxx.bkt.clouddn.com/apt_process_write_java_file.JPG)




### 4. 注意的地方
dnot't put annotation processors in a compile configuration, use the Android Apt plugin。

if you using jack, jack has support for annotation processors.

if it's only a java, could use the Gradle Apt Plugin

我们写的processor不会带到生成的apk中，但生成的代码会。这也正是想要的目的。

## updates
[Instagram的json parser也是使用了annotationProcessor在编译期生成代码](https://github.com/Instagram/ig-json-parser) 很多gson这样的解析器都使用了大量的反射，所以相比手写的构造函数要慢很多。


### ref
 - [android gradle plugin 2.3的兼容问题](https://code.google.com/p/android/issues/detail?id=227612)
 - [Android沉思录](http://yeungeek.com/2016/04/27/Android%E5%85%AC%E5%85%B1%E6%8A%80%E6%9C%AF%E7%82%B9%E4%B9%8B%E4%BA%8C-Annotation-Processing-Tool)
 - [Droidcon NYC 2016 - @Eliminate("Boilerplate")](https://www.youtube.com/watch?v=NBkl_SIHUr8)
 - [Gradle Apt Plugin](https://github.com/tbroyer/gradle-apt-plugin)
 - [Andorid Apt Plugin](https://bitbucket.org/hvisser/android-apt)
