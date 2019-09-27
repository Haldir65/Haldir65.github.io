---
title: Theme和Style的区别
date: 2016-10-10 19:35:32
categories: blog
tags: [android]
---



认识Theme和Styles

重新看一遍Using Themes and styles without going crazy，大部分属于直接翻译

## 1. Styles

### 1.1 首先，在layout文件中，Style可以将一些重复的，具有共性的属性提取出来

```xml
<View android:background= "#ff0000" />
```

变成

```xml
<View style= "@Style/MyStyle" />

<Style name = "MyStyle">
	<item name = "android:background">#ff0000</item>
</Style>
```

这种形式，对于大量的具有相同属性的且具有*共性*的View，可以直接使用对应的Style，这能够让layout文件更加整洁。前提是确信layout文件中使用的View具有相同的属性。

<!--more-->

### 1.2 Style Inheritance

Style可以继承，两种方式：

假设有parent style ，一种在name中使用前缀的方式指明parent，另一种在后面显式的声明parent

```xml
<style name = "Parent"/>
```

Explicit child

```xml
<style name = "Child" parent = "Parent">
```

  Implicit Child

```xml
<style name = "Parent.Child"/>
```

同时使用两种方式时，默认使用Explicit Parent  

为避免混淆，推荐使用Explicit Child且Child name不带前缀  

View不能拥有两个Style,除了TextView及其子类，例如

```xml
<TextView>
  android:textColor = "#ffffff"
	style="@style/SomeStyle"
  android:textAppearance = "@style/MyText"
</TextView>
```

如上所示，TextView中可以定义TextAppearance，后者包含了常见的textColor，textSize等attributes，而在一个View中可以同时定义两个Style。如果出现冲突，styles之间相同attributes的应用优先级为：

> android:textColor >> SomeStyle中的android:textColor>>MyText中的android:textColor

> 使用TextAppearance 时一定要有一个parent

```xml
<style name = "MyText" parent="TextAppearance.Appcompat">
	<item name = "android:TextColor">#F08</item>
</style>
```

因为使用style时，系统将把style中定义的attribute和当前View的默认attribute融合起来，而TextView默认attribute 中什么也没有，造成textSize = 0的情况，所以务必选择parent，在parent style已经定义好大多数属性的情况下再去修改小部分属性将简单得多。TextAppearance可以在Theme中定义，也可以写在单一的TextView上。

## 2. Themes
  在Android中，Theme名字以"Theme."开头，查看源码会发现只是定义了一大堆color attributes 和Window attributes。Themes比Styles的作用范围更广，themes可以在Application,Activity层面管理Widget外观，Theme还可以实现夜间模式切换

  来看如何定义一个Theme

  ```xml
  <style name = "Theme">
  	<item name = android:statusBarColor>#ff0000</item>
  </style>
  ```

  回头看一下Style

  ```xml
  <Style name = "Style">
  	<item name = "android:background">#ff0000</item>
  </Style>
  ```

  语法看起来完全一样。

  区别：styles中的属性被直接送到View的构造函数中，记得在自定义View时写的那些attrs吗，其实就是两个参数的构造函数中的AttributeSets

  Theme应用范围更广，定义的属性和Style也不尽相同。

  两者之间有一些联系：例如Theme中可以定义default widget style，Style可以引用Theme中定义的属性(?attr:selectableItemBackground还记得吗)
  上面提到了Theme中可以定义default widget style，具体做法无非就是这样:

  ```xml
  <style name= "MyTheme" parent="Theme.AppCompat.Light">
    <item name="android:editTextStyle">@style/MyEditTextStyle</item>
  </style>
  ```
  所以，只要在AppTheme中点进去，找一下这个键对应的值就可以了


### 2.1 使用Theme

  两种方式:

  1.在Manifest中，例如

```xml
  <application
    android:theme="@style/Theme.AppCompat" />

  或者
  <activity
    android:theme="@style/Theme.AppCompat.Light"        />
```

  activty中Theme override Application的Theme

  2. 应用于View

  Lollipop开始引入View Theming的概念

```xml
  <Toolbar
     android:theme="@style/ThemeOverlay.AppCompat.Dark.ActionBar"
     app:popupTheme="@style/ThemeOverlay.AppCompa.Light"/>      
```

  应用在View上的Theme将能够作用在该View及其所有的Children，这样做的好处在于没有必要专门为了一个View而去选择其他的Theme。

  例如在Holo中有Holo.Light.DarkActionBar，为了专门适配ActionBar需要一个专门的Theme。目前看来主要应用在Toolbar上。

## 3 .墙裂推荐使用AppCompat

  好处:

- Material on all devices ,记得以前听说AppCompat在21以上继承自Theme.Material。
- Baseline themes/styles AppCompat 预设了一系列样式标准，只需要继承AppCompat，改动一小部分样式就能完成设计
    - Enable View theming pre-Lollipop
    - 使用ColorPrimary , ColorAccent等attributes(backPorted by AppCompat)设置Widget样式
    - 在Theme中可以定义默认的Widget样式，例如

```xml
<style name="AppTheme" parent = "Theme.AppCompat">
<item name="android:spinnerItemStyle">@sytle/MySpinnerStyle</item>
</style>
```

还可以更改默认样式：

```xml
<style name = "AttrTheme" parent ="Theme.AppCompat">
<item name ="selectableItemBackground">@drawable/bg</item>
</style>
<Button android:background=?attr/selectableItemBackground"/>
```
这样就可以自定义点击时的Drawable了。

- 支持android:theme: API 7+(只应用于该View)，API 11+(View及其子View)

View theming原本只是API 21才引入的概念，AppCompat实现了向前兼容


## 4 .  ?attr的问题

> ?android:attr/selectableItemBackground

一个个来解释：

?  :  we're doing a theme lookup

android:  we’re looking up something within the android namespace

attr/  : we're looking for an attribute(可省略)

selectableItemBackground: The name of the atribute we're looking up

把attr/省略掉后变成

> ?android:selectableItemBackground

效果完全一样

```xml
<style name="MyTheme">
	<item name = "android:colorPrimary">@color/red</item>
</style>
```

问题在于android:ColorPromary是Lollipop才引入的，解决方案

```xml
<syle name = "MyTheme" parent="Theme.AppCompat">
	<item name = "colorPrimary">@color/red</item>
</syle>
```

注意这里没有android: 前缀，AppCompat针对API21之前的版本定义了自己的一套资源。

再举个例子

```xml
在values/attrs.xml中
<attr name:"myAttribute" format="dimension"/>

在values/themes.xml中
<style name = "MyTheme" parent = "Theme.AppCompat">
	<item name="myAttribute">4dp</item>  这就是实际使用的Theme
</style>

在values/styles.xml中
<style name="MyStyle">
	<item name="android:padding">?attr/myAttribute</item>
</style>

实际操作中
在layout文件中，通过将一个长度，颜色定义为?attr的方式，就会去当前的Theme中寻找相对应的attribute，这就是黑夜模式切换的原理
```

要注意的是，所有非android nameSpace的attribute Name都是global的，所以如果两个library定义了相同的attribute Name，将无法编译通过。

Style可以通过?attr的方式引用Theme中的资源



## 5 .获取Theme

```java
context.getTheme().resolveAttribute(R.attr.dialogTheme,outValue,true)

在View中
  TypedArray a = context.obtainStyledAttributes(attrs,com.android.internal.R.styleable.ImageView,defStyleAttr,defStyleRes)

int alpha = a.getInt(
  com.android.internal.R.styleable.ImageView_drawableAlpha,255)   
```

Activity有一个setTheme(int themeResId)方法，注意，这个方法并不是取代原先的Theme,只是在原有的Theme上apply了。所以这个命名不算太好。Activity内部会在onCreate()前调用setTheme(你写在manifest里面的Theme)



## 6. v21的问题

```xml
在values/styles.xml中
<style name="BaseToolbar"/>

在values-v21/styles.xml中
<style name= "BaseToolbar">
	<item name = "android:elevation">4dp</item>
</style>
elevation是21以上api才有的属性，lint会提示问题
这样，在values/styles.xml中
<style name = "Toolbar" parent = "BaseToolbar"/>
lint就不会飙黄了，直接引用Toolbar即可
```

通过这种继承的方式能够在自己的Theme中使用统一的theme，针对不同的运行时版本确定最终运行的Theme。

## 7 . ThemeOverlay

```JAVA
ThemeOverlay.Material.Light
ThemeOverlay.Material.Dark
//etc ...   
```

用于添加到现有的Theme上，例如Theme.Material.Light只包含color relevant to a light Theme，不会改变原有Theme的window Attributes。查看源码，只是完整的Theme中的一小部分attribute。

## 8. 常见错误

1. 作为Theme中引用的style必须要有一个parent

例如
```xml
在AppTheme中
<item name = "android:editTextStyle">@style/MyEditTextStyle</item>

<style name= "MyEditTextStyle">
	<item name= "android:fontFamily">
  sans-serif-medium
  </item>
</style>
```
这样做的结果将是所有的EditText都会失去基本的属性

2. defStyleAttr vs defStyleRes

常见于

```java
ObtainStyledAttributes(AttributeSet set,int []attrs,
 int defStyleAttr,int defStyleRes)
```

直接解释：

>  defStyleAttr: The attr in your theme which points to the default style
>
>  eg: R.attr.editTextStyle
>
>  defStyleRes: The resource ID of the default style
>
>  eg:R.style.Widget_Material_EditText

ObtainStyledAttributes查找Value时读取的顺序如下

```java
1. Value in the AttributeSet
2. Value in the explicit style
3. Default style specified in defStyleRes
4. Default style specified in defStyleAttr
5. Base value in this theme     
```
注意最后一条，万一在manifests文件中出现这种东西

```xml
<Style name = "AppTheme" parent = "Theme.AppCompat">
	<item name = "android:background">...</item>
</Style>
```

这意味着

> Any View which doesn't have a background set ,will use the theme's value ,  SHIT!




## 9. 容易遇到的错误
编译不通过的情况
```java
Error retrieving parent for item: No resource found that matches the given name
 '@android:style/TextAppearance.Holo.Widget.ActionBar.Title'
```



## 10. 最后，一点好玩的

```java
Context themedContext =
  new ContextThemeWrapper(baseContext,R.style.MyTheme);

View view = LayoutInflator.form(themedContext)
  		.inflate(R.layout.some_layout,null);
//或者
View view = new View(themedContext);
//生成的View就会带有MyTheme中的属性，动态设置。
```

而这也是AppComPat对于API 21以下版本进行兼容的原理
翻了一下文档：
ContextThemeWrapper : Added in API level 1

这一点AppCompat的作者也在2014年的一篇 [博客](https://chris.banes.me/2014/11/12/theme-vs-style/)中提到了。

## reference

- [Daniel Lew](https://www.youtube.com/watch?v=Jr8hJdVGHAk)
- [View Constructor](http://blog.danlew.net/2016/07/19/a-deep-dive-into-android-view-constructors/)
- [IO 2016](https://www.youtube.com/watch?v=TIHXGwRTMWI)
