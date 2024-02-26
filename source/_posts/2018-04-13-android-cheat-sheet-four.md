---
title: Android知识集合[四]
date: 2018-04-13 13:53:52
tags: [android]
---


![](https://api1.reindeer36.shop/static/imgs/street%20lights%20dark%20night%20car%20city%20bw.jpg)

<!--more-->

## 1. 在子线程中显示一个Toast是亲测可行的
不是那种post到主线程的方案
[其实知乎上已经有了讨论](https://www.zhihu.com/question/51099935)
```java
static class ToastThread extends Thread {

     Context mContext;

     public ToastThread(Context mContext) {
         this.mContext = mContext;
     }

     @Override

     public void run() {
         Looper.prepare();
         String threadId = String.valueOf(Thread.currentThread().getId());
         Toast.makeText(mContext,threadId,Toast.LENGTH_SHORT).show();
         Looper.loop();
     }
 }
```
![](https://api1.reindeer36.shop/static/imgs/toast_transact.jpg)
其实Toast的原理就是通过IPC向NotificationManager请求加入队列，后者会检测权限xxxx。然后通过上面的ipc回调到客户端的onTransact中，这里也就是走到了Toast.TN这个static inner class的handler中，发送一个Message，handlerMessage中完成了WindowManager.addView的操作
需要注意的是，这里还是子线程，所以确实可能存在多条线程同时操作UI的现象。从形式上看，主线程和子线程中的Toast对象各自通过自己的Looper维护了一个消息循环队列，这其中的消息类型包括show,hide和cancel。所以可能存在多条线程同时调用WindowManager的方法，View也是每条线程各自独有的，最坏的场景莫过于两条线程同时各自添加了一个View到window上。另外，子线程中引入looper的形式也造成了子线程实质上的阻塞，当然可以直接当成一个handlerThread来用。
所以不是很推荐这么干，只是说可以做。
**Toast.TN.handleShow**
```java
try {
      mWM.addView(mView, mParams);
      trySendAccessibilityEvent();
  } catch (WindowManager.BadTokenException e) {
      /* ignore */
  }
```

## 2.ContentProvider的onCreate要早于Application的onCreate发生
比如ArchitectureComponent中的lifeCycle就是这么干的，写了个dummpy的contentProvider，在provider的onCreate中去loadLibrary.

## 3. 看到一个关于apk反编译和重新打包的帖子，非常好用
[Android apk反编译及重新打包流程](https://www.jianshu.com/p/792a08d5452c)，关键词apktool。
但是，360加固之后的apk是不能用dex2jar查看java代码的。


### 4.从base.apk谈到apk安装的过程
[APK安装过程](https://www.jianshu.com/p/ae45af3c3098)。
之前无意间在FileExplorer中看到了base.apk这个文件，由此展开apk安装过程的研究。

## 5.关于模块化和项目重构
很多关于Android甚至java项目的重构的文章都会最终提到两条：
面向接口编程 -> 依赖注入(IOC)
然后跟上一大堆专业分析和没什么用的废话。
这俩在java的领域翻译过来就是：
在A模块中用Dagger2生成B模块中定义的interface的impl实例。
<del>其实不用Dagger2也行，就是每次在B模块的生命周期开始时准备一个HashMap<interfaceClass,ImplClass>这样的一大堆键值对，然后在A模块中根据想要的interface class去找impl class，用反射去创建，生产环境肯定不能这么干。</del>
在Dagger2中大致是这么干的：

先声明好B模块对外提供的接口，以下这俩都在另一个module中，A module通过gradle引用了B模块
```java
public interface Store {
    String sell();
}

public class StoreImpl implements Store {
    @Override
    public String sell() {
        return "Dummy products";
    }
}
```
B模块中再提供Component和provide的module
```java
@Component(modules = StoreModule.class)
public interface StoreComponent {
    Store eject();
}

@Module
public class StoreModule {
    @Provides
    Store provideStore() {
        return new StoreImpl();
    }
}
```

A模块中最终使用的方式应该是
```java
 Store store = DaggerStoreComponent.builder().build().eject();
```

## 6.写sqlite语句的时候总是容易出小错误
```sql
//错误写法
CREATE TABLE IF NOT EXISTS table_one ( _id INTEGER PRIMARY KEY AUTOINCREMENT, studentName TEXT,studentNick TEXT)
INSERT OR IGNORE INTO table_one (studentName,studentNick) VALUES ( name1,nick1)
//  SQLiteException: no such column: name1 (code 1) 报错

//正确写法
CREATE TABLE IF NOT EXISTS table_one ( _id INTEGER PRIMARY KEY AUTOINCREMENT, studentName TEXT,studentNick TEXT)
INSERT OR IGNORE INTO table_one (studentName,studentNick) VALUES ( 'name1','nick1')
```
唯一的区别就在于name1和nick1这俩用 **单引号单引号单引号** 包起来了。

## 7. Webview的坑的总结
[WebView的那些坑](http://iluhcm.com/2017/12/10/design-an-elegant-and-powerful-android-webview-part-one/)


## 8.BitmapRegionDecoder不要随便用，到处是坑，主要问题和jpg图片的colorSpace有关，动不动就爆出IOException

>The Skia library on which BitmapRegionDecoder is based had some bugs that will not be fixed in versions of Android prior to Nougat or Oreo. It will still display the vast majority of images properly, but you may see problems displaying CMYK JPGs, and grayscale PNGs, especially on older devices. To reduce the frequency of these problems, the view automatically falls back to BitmapFactory when the image does not need to be subsampled.
[subsampling-scale-image-view这个库](https://github.com/davemorrissey/subsampling-scale-image-view/wiki/02.-Displaying-images)

## 9.Bitmap对象的recycle问题还是要调用
Bitmap类有一个方法recycle()，从方法名可以看出意思是回收。这里就有疑问了，Android系统有自己的垃圾回收机制，可以不定期的回收掉不使用的内存空间，当然也包括Bitmap的空间。那为什么还需要这个方法呢？
Bitmap类的构造方法都是私有的，所以开发者不能直接new出一个Bitmap对象，只能通过BitmapFactory类的各种静态方法来实例化一个Bitmap。仔细查看BitmapFactory的源代码可以看到，生成Bitmap对象最终都是通过JNI调用方式实现的。所以，加载Bitmap到内存里以后，是包含两部分内存区域的。简单的说，一部分是Java部分的，一部分是C部分的。这个Bitmap对象是由Java部分分配的，不用的时候系统就会自动回收了，但是那个对应的C可用的内存区域，虚拟机是不能直接回收的，这个只能调用底层的功能释放。所以需要调用recycle()方法来释放C部分的内存。从Bitmap类的源代码也可以看到，recycle()方法里也的确是调用了JNI方法了的。
那如果不调用recycle()，是否就一定存在内存泄露呢？也不是的。Android的每个应用都运行在独立的进程里，有着独立的内存，如果整个进程被应用本身或者系统杀死了，内存也就都被释放掉了，当然也包括C部分的内存。
Android对于进程的管理是非常复杂的。简单的说，Android系统的进程分为几个级别，系统会在内存不足的情况下杀死一些低优先级的进程，以提供给其它进程充足的内存空间。在实际项目开发过程中，有的开发者会在退出程序的时候使用Process.killProcess(Process.myPid())的方式将自己的进程杀死，但是有的应用仅仅会使用调用Activity.finish()方法的方式关闭掉所有的Activity。


## 10. 原来layer_list还可以这么用啊
给一个View加边框，只在左边，上面和下面三条边上加边框，用layer_list就可以了
```xml
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- 连框颜色值 -->
    <item>
        <shape>
            <solid android:color="@color/md_blue_700" />
        </shape>
    </item>
    <!-- 主体背景颜色值 -->
    <!-- 此处定义只有上下两边有边框 高度为1像素-->
    <item
    android:bottom="10dp"
    android:left="10dp"
    android:top="10dp">
    <!--边框里面背景颜色 白色-->
    <shape>
        <solid android:color="#ffffff" />
    </shape>
    </item>
</layer-list>
```

### 11.proguard可以把log干掉
```config
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}
```

### 12.国产Rom的权限问题是在是头疼
以5.1的rom为例
```java
if(ContextCompat.checkSelfPermission(activity,Manifest.permission.Camera)== PackageManager.PERMISSION_GRANTED):
    Camera c = Camera.open();// 还是null
```
类似的问题衍生出了[国产手机5.0,6.0权限适配框架](https://github.com/jokermonn/permissions4m)
找到了启动魅族权限管理的Activity的代码
```java
final String N_MANAGER_OUT_CLS = "com.meizu.safe.permission.PermissionMainActivity"; 
final String L_MANAGER_OUT_CLS = "com.meizu.safe.SecurityMainActivity"; // 5.1上叫做这个名字
final String PKG = "com.meizu.safe";
Activity activity = (Activity) context;
Intent intent = new Intent();
intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
intent.putExtra("package", activity.getPackageName());
ComponentName comp = new ComponentName(PKG, L_MANAGER_OUT_CLS);
intent.setComponent(comp);
activity.startActivity(intent);
```

### 13. Canvas.clipPath会出现锯齿的问题以及可能的解决方案
a Naive implementation of CircleImageView would look something like this:
xml里面宽高都写成200dp，方便一点。
```java
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Path;
import android.graphics.RectF;
import android.support.v7.widget.AppCompatImageView;
import android.util.AttributeSet;

public class RoundCornerImageView1 extends AppCompatImageView {
    float[] radiusArray = new float[8];

    public RoundCornerImageView1(Context context) {
        super(context);
        init();
    }

    public RoundCornerImageView1(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    public RoundCornerImageView1(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }

    private void init() {
        setScaleType(ScaleType.CENTER_CROP);
    }

    public void setRadius(float leftTop, float rightTop, float rightBottom, float leftBottom) {
        radiusArray[0] = leftTop;
        radiusArray[1] = leftTop;
        radiusArray[2] = rightTop;
        radiusArray[3] = rightTop;
        radiusArray[4] = rightBottom;
        radiusArray[5] = rightBottom;
        radiusArray[6] = leftBottom;
        radiusArray[7] = leftBottom;
        invalidate();
    }

    @Override
    protected void onDraw(Canvas canvas) {
        Path path = new Path();
        int width = getWidth();
        int height = getHeight();
        setRadius(width/2,width/2,height/2,height/2);
        path.addRoundRect(new RectF(0, 0, width,height), radiusArray, Path.Direction.CW);
        canvas.clipPath(path);
        super.onDraw(canvas);
    }
}
```
不出意外的话，在真机上运行会出现圆形边角有锯齿的问题。google一下clipPath锯齿就会发现类似的[issue](https://www.cnblogs.com/everhad/p/6161083.html)，framework只是对skia library的一层很薄的包装。

[早先版本的系统画圆弧似乎不是特别准](https://github.com/hehonghui/android-tech-frontier/blob/aa6f125b1a3801820e697f5ac6246b4827acd5a5/issue-45/Android%E5%9C%86%E5%BC%A7%E6%95%B4%E5%AE%B9%E4%B9%8B%E8%B0%9C.md)

多数时候对这种问题的解决方式是使用PorterDuff.SRCIN的方式，用canvas saveLayer(貌似layer是一种栈的结构)的方式在其他的layer中去画bitmap。最后顶层的layer全部pop掉之后会合并到initial的layer上，类似于在顶层的layer中合成这张bitmap。
canvas.saveLayer(0, 0, w, h, null, Canvas.ALL_SAVE_FLAG); // 大致就在这里,layer似乎可以理解成photoShop里面的图层的概念
```java
public class RoundCornerImageView2 extends AppCompatImageView {
    // 四个角的x,y半径
    private float[] radiusArray = { 0f, 0f, 0f, 0f, 0f, 0f, 0f, 0f };
    private Paint bitmapPaint = new Paint(Paint.ANTI_ALIAS_FLAG);

    private Bitmap makeRoundRectFrame(int w, int h) {
        Bitmap bm = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888);
        Canvas c = new Canvas(bm);
        Path path = new Path();
        setRadius(w/2,w/2,h/2,h/2);
        path.addRoundRect(new RectF(0, 0, w, h), radiusArray, Path.Direction.CW);
        Paint bitmapPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        bitmapPaint.setColor(Color.GREEN); // 颜色随意，不要有透明度。
        c.drawPath(path, bitmapPaint);
        return bm;
    }
    public RoundCornerImageView2(Context context) {
        super(context);
        init();
    }
    public RoundCornerImageView2(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }
    public RoundCornerImageView2(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }
    private void init() {
//        setLayerType(LAYER_TYPE_SOFTWARE, null); // Xfermode 需要禁用硬件加速
        setScaleType(ScaleType.CENTER_CROP);
    }

    public void setRadius(float leftTop, float rightTop, float rightBottom, float leftBottom) {
        radiusArray[0] = leftTop;
        radiusArray[1] = leftTop;
        radiusArray[2] = rightTop;
        radiusArray[3] = rightTop;
        radiusArray[4] = rightBottom;
        radiusArray[5] = rightBottom;
        radiusArray[6] = leftBottom;
        radiusArray[7] = leftBottom;
    }

    @Override
    protected void onDraw(Canvas canvas) {

        final int w = getWidth();
        final int h = getHeight();
        Bitmap bitmapOriginal = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888);
        Canvas c = new Canvas(bitmapOriginal);
        super.onDraw(c);

        Bitmap bitmapFrame = makeRoundRectFrame(w, h);

        int sc = canvas.saveLayer(0, 0, w, h, null);

        canvas.drawBitmap(bitmapFrame, 0, 0, bitmapPaint); //先画一个圆形的框框条条出来
// 利用Xfermode取交集（利用bitmapFrame作为画框来裁剪bitmapOriginal）
        bitmapPaint.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.SRC_IN)); //后续的画图操作，只有交集的部分才会显示在最终的canvas上
        canvas.drawBitmap(bitmapOriginal, 0, 0, bitmapPaint);

        bitmapPaint.setXfermode(null);
        canvas.restoreToCount(sc);
    }
}
```
这种方式一般称为离屏缓冲


### 14. jni使用
[一般使用javah生成header文件](https://blog.csdn.net/baidu_34045013/article/details/78994516)


多数教程都是写一个
gradle.properties添加一句android.useDeprecatedNdk=true
随着studio版本升级，还是不得不升级到使用cmake的方式。

Android Studio中集成c或者cpp代码照着这个官方的[教程](https://developer.android.com/studio/projects/add-native-code)抄就行了。其实也就是写一个CMakeLists.txt，然后在studio里面右键app模块, Link C++ Project with Gradle。照着来就是了。

先写好java的native方法，然后cd到src/main/java路径
javah -classpath .:/Users/harris/Library/Android/sdk/platforms/android-28/android.jar  -d jni com.me.harris.ndk_graphics.JNIHelper

加上classpath的原因是JNIHelper这个java文件里面引用到了Android的class

把生成的header文件剪切到和main/Java文件夹平级的jni文件夹中，再去写c的实现。

移植mp3lame到Android平台照着[这里](https://www.jianshu.com/p/065bfe6d3ec2)操作就行了。
这篇博客使用的是lame-3.99.5，注意下载对应的版本。
[cmake的一些知识点](http://cfanr.cn/2017/08/26/Android-NDK-dev-CMake-s-usage/)
cmake生成的.so文件在"\app\build\intermediates\cmake\debug\obj\arm64-v8a"这个路径下。另外，CMakeLists.txt文件中比如说指定了生成的.so文件名字为xxx,那么在这个路径下找到的将会是libxxx.so

java调用c语言性能还好,c语言调用java的性能就比较差了
[两头调来调去的例子](https://blog.csdn.net/honjane/article/details/53958166 )
下面是c层面调用java代码的例子，分别是调用java instance method 和java static method
```c
private String sex = "female";//需要赋初始值或定义成static，不然在没有调用accessPublicMethod方法前，调用getSex方法会抛异常

    public void setSex(String sex){
        this.sex = sex;
    }

    public String getSex(){
        return sex;
    }

    public native void accessPublicMethod();
```

```c++
//访问java中public方法
extern "C"
void Java_com_honjane_ndkdemo_JNIUtils_accessPublicMethod( JNIEnv* env, jobject jobj){
    //1.获得实例对应的class类
    jclass jcls = env->GetObjectClass(jobj);

    //2.通过class类找到对应的method id
    //name 为java类中变量名，Ljava/lang/String; 为变量的类型String
    jmethodID jmid = env->GetMethodID(jcls,"setSex","(Ljava/lang/String;)V");
    //定义一个性别赋值给java中的方法
    char c[10] = "male";
    jstring jsex = env->NewStringUTF(c);
    //3.通过obj获得对应的method
    env->CallVoidMethod(jobj,jmid,jsex);
}
```

```java
 private static int height = 160;

    public static int getHeight(){
        return height;
    }

    public native int accessStaticMethod();

```
```c++

//访问java中static方法
extern "C"
jint Java_com_honjane_ndkdemo_JNIUtils_accessStaticMethod( JNIEnv* env, jobject jobj){
    //1.获得实例对应的class类
    jclass jcls = env->GetObjectClass(jobj);

    //2.通过class类找到对应的method id
    jmethodID jmid = env->GetStaticMethodID(jcls,"getHeight","()I");

    //3.静态方法通过class获得对应的method
    return env->CallStaticIntMethod(jcls,jmid);
}
```


//访问field用的是GetObjectClass和getXXXField(这里无论是public还是private field都能拿到)
```java
public class JNIUtils {

    public int num = 10;

    public native int addNum();

    static {
        System.loadLibrary("native-lib");
    }
}
```
```c++
#include <jni.h>
#include <string.h>
#include <stdio.h>

//访问java对象中num属性，并对其作加法运算
extern "C"
jint Java_com_honjane_ndkdemo_JNIUtils_addNum( JNIEnv* env, jobject jobj){
    //1.获得实例对应的class类
    jclass jcls = env->GetObjectClass(jobj);

    //2.通过class类找到对应的field id
    //num 为java类中变量名，I 为变量的类型int
    jfieldID fid = env->GetFieldID(jcls,"num","I");

    //3.通过实例object获得对应的field
    jint jnum = env->GetIntField(jobj,fid);
    //add
    jnum += 10;

    return jnum;
}
```
从jni层抛出一个java Exception也是可以的，其实就是new 一个java object(Exception)
> 1、当调用一个JNI函数后，必须先检查、处理、清除异常后再做其它 JNI 函数调用，否则会产生不可预知的结果。 
2、一旦发生异常，立即返回，让调用者处理这个异常。或 调用 ExceptionClear 清除异常，然后执行自己的异常处理代码。 
3、异常处理的相关JNI函数总结： 
1> ExceptionCheck：检查是否发生了异常，若有异常返回JNI_TRUE，否则返回JNI_FALSE 
2> ExceptionOccurred：检查是否发生了异常，若用异常返回该异常的引用，否则返回NULL 
3> ExceptionDescribe：打印异常的堆栈信息 
4> ExceptionClear：清除异常堆栈信息 
5> ThrowNew：在当前线程触发一个异常，并自定义输出异常信息 
jint (JNICALL *ThrowNew) (JNIEnv *env, jclass clazz, const char *msg); 
6> Throw：丢弃一个现有的异常对象，在当前线程触发一个新的异常 
jint (JNICALL *Throw) (JNIEnv *env, jthrowable obj); 
7> FatalError：致命异常，用于输出一个异常信息，并终止当前VM实例（即退出程序） 
void (JNICALL *FatalError) (JNIEnv *env, const char *msg);

jni是一套规范,oracle有一个[文档](https://docs.oracle.com/javase/7/docs/technotes/guides/jni/spec/functions.html)，不同的vm照着这个规范实现就是了




15. 关于Spannable String的问题
Medium上有关于使用span的文章 [Spantastic text styling with Spans](https://medium.com/google-developers/spantastic-text-styling-with-spans-17b0c16b4568) 其实有SpannableString(mutable),SpannableStringBuilder还有SpannedString(immutable)。
Just reading and not setting the text nor the spans? -> SpannedString(文字和style都改不了)
Setting the text and the spans? -> SpannableStringBuilder(文字和Style都能改)
Setting a small number of spans (<~10)? -> SpannableString(文字不能改，Style能改)
Setting a larger number of spans (>~10) -> SpannableStringBuilder

[stackoverflow上甚至有Glide作者的讨论](https://stackoverflow.com/questions/17546955/android-spanned-spannedstring-spannable-spannablestring-and-charsequence)
从源码来看,SpannedString和SpannableString几乎是一样的，后者继承了一个Spannable的接口，由此对外暴露了父类(SpannableStringInternal)的setSpan和removeSpan方法。
> Use a SpannedString when your text has style but you don't need to change either the text or the style after it is created. (似乎平时也应该这样使用，但从源码来看，两者几乎没有性能上的区别。真正的性能差异要取决于实际的use case)
> Use a SpannableString when your text doesn't need to be changed but the styling does.
> Use a SpannableStringBuilder when you will need to update the text and its style.

SPAN_EXCLUSIVE_EXCLUSIVE，SPAN_EXCLUSIVE_INCLUSIVE这些东西的意思是针对新的文字插入之后的行为来说的。
SPAN_EXCLUSIVE_INCLUSIVE就是说新的文字插入之后，之前设置的span将自动扩增并应用到这段新的文字上。
```java
spannable.setSpan(
     ForegroundColorSpan(Color.RED), 
     /* start index */ 8, /* end index */ 12, 
     Spannable.SPAN_EXCLUSIVE_INCLUSIVE)
spannable.insert(12, “(& fon)”) //注意SpannableStringBuilder的这个insert方法是可以指定insert的位置的


val spannable = SpannableString(“Text is spantastic!”)
spannable.setSpan(
     ForegroundColorSpan(Color.RED), 
     8, 12, 
     Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
spannable.setSpan(
     StyleSpan(BOLD), 
     8, spannable.length, 
     Spannable.SPAN_EXCLUSIVE_EXCLUSIVE) //一段文字可以同时应用多个Spannable样式
```

Framework自带的spans可以分为两类：一种是改变文字外观的（Appearance affecting span），另一种是改变文字大小的(Metric affecting span)。

文章里还提到了可以使用TextView.setText(Spannable, BufferType.SPANNABLE)方法，如果后续需要修改文字的span样式的话，可以getText，获得的是之前设置的span，这时候再去对这个span进行操作（不要再setText回去了），这对提升性能有帮助（text的measure和layout都是耗性能的操作）。但注意，如果是使用了RelativeSizeSpan的话，因为更改了TextView的大小，这必然会触发重新measure和layout，上述的优化似乎也就没有必要了。

自定义Span的话：
Affecting text at the character level -> CharacterStyle
Affecting text at the paragraph level -> ParagraphStyle
Affecting text appearance -> UpdateAppearance
Affecting text metrics -> UpdateLayout


asset文件夹里面的东西是无法用File的形式去获取的
android.os.FileUriExposedException: file://assets/dist/index.js exposed beyond app through Intent.getData()
at android.os.StrictMode.onFileUriExposed(StrictMode.java:1816)


### 15. setClipToOutline(v21)
[圆角矩形的实现多了一种选择](https://stackoverflow.com/questions/16161448/how-to-make-layout-with-rounded-corners)

[gradle build scan](https://gradle.com/build-scans)
[把一些本地libiary打包成aar能够显著加快编译]


[AAPT2会生成一堆.flat文件](https://fucknmb.com/2017/10/31/aapt2%E8%B5%84%E6%BA%90compile%E8%BF%87%E7%A8%8B/)

**全角半角对汉字没有影响**
TextView有时候会出现提前换行的问题,这事据说跟全角半角有关（全角状态下字母、数字符号等都会占两个字节的位置，也就是一个汉字那么宽，半角状态下，字母数字符号一般会占一个字节，也就是半个汉字的位置，全角半角对汉字没有影响。）
一个直观的表现是全角的情况下你发现冒号，分号这些东西都变得比较宽。（;；MＭ）也就是所谓的中文标点符号 .对了，全角的情况下字母，数字也会变宽一点（本质上是占用两个字符）

[Instagram是如何提升TextView渲染性能的(http://codethink.me/2015/04/23/improving-comment-rendering-on-android/),关键字TextLayoutCache
[compile ffmpeg for android](https://zhuanlan.zhihu.com/p/40921043)
需要修改B0 -> b0 ，linux平台或者mac平台可用
[compile ffmpeg for android](https://yesimroy.gitbooks.io/android-note/content/compile_ffmpeg_for_android.html)

Andorid平台上默认的isLoggable的允许的LogLevel是info，也就是说，log.d和log.v是不会显示的。[wht are log-d and log-v not printing](https://stackoverflow.com/questions/28434901/why-are-log-d-and-log-v-not-printing)
当然这也要看手机厂商设置，魅族手机就是设置为info级别及以上了。这话2016年有人提醒过我。

### 16.lamemp3 移植到android平台
[lame版本3.99.5](https://www.jianshu.com/p/534741f5151c)
```c
#include <stdio.h>
#include <stdlib.h>
#include <jni.h>
#include <android/log.h> 
#include "libmp3lame/lame.h"

#define LOG_TAG "LAME ENCODER"
#define LOGD(format, args...)  __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, format, ##args);
#define BUFFER_SIZE 8192
#define be_short(s) ((short) ((unsigned short) (s) << 8) | ((unsigned short) (s) >> 8))

lame_t lame;

int read_samples(FILE *input_file, short *input) {
    int nb_read;
    nb_read = fread(input, 1, sizeof(short), input_file) / sizeof(short);

    int i = 0;
    while (i < nb_read) {
    input[i] = be_short(input[i]);
    i++;
}

    return nb_read;
}

void Java_com_example_core_audio_NativeRecorder_initEncoder(JNIEnv *env,
jobject jobj, jint in_num_channels, jint in_samplerate, jint in_brate,
jint in_mode, jint in_quality) {
    lame = lame_init();

    //	LOGD("Init parameters:");
    lame_set_num_channels(lame, in_num_channels);
    //	LOGD("Number of channels: %d", in_num_channels);
    lame_set_in_samplerate(lame, in_samplerate);
    //	LOGD("Sample rate: %d", in_samplerate);
    lame_set_brate(lame, in_brate);
    //	LOGD("Bitrate: %d", in_brate);
    lame_set_mode(lame, in_mode);
    //	LOGD("Mode: %d", in_mode);
    lame_set_quality(lame, in_quality);
    //	LOGD("Quality: %d", in_quality);

    int res = lame_init_params(lame);
    //	LOGD("Init returned: %d", res);
}

void Java_com_example_core_audio_NativeRecorder_destroyEncoder(
JNIEnv *env, jobject jobj) {
    int res = lame_close(lame);
    //	LOGD("Deinit returned: %d", res);
}

void Java_com_example_core_audio_NativeRecorder_encodeFile(JNIEnv *env,
jobject jobj, jstring in_source_path, jstring in_target_path) {
const char *source_path, *target_path;
source_path = (*env)->GetStringUTFChars(env, in_source_path, NULL);
target_path = (*env)->GetStringUTFChars(env, in_target_path, NULL);

FILE *input_file, *output_file;
input_file = fopen(source_path, "rb");
output_file = fopen(target_path, "wb");

short input[BUFFER_SIZE];
char output[BUFFER_SIZE];
int nb_read = 0;
int nb_write = 0;
int nb_total = 0;

//	LOGD("Encoding started");
while (nb_read = read_samples(input_file, input)) {
nb_write = lame_encode_buffer(lame, input, input, nb_read, output,
BUFFER_SIZE);
fwrite(output, nb_write, 1, output_file);
nb_total += nb_write;
}
//	LOGD("Encoded %d bytes", nb_total);

nb_write = lame_encode_flush(lame, output, BUFFER_SIZE);
fwrite(output, nb_write, 1, output_file);
//	LOGD("Flushed %d bytes", nb_write);

fclose(input_file);
fclose(output_file);
}
```

### 17. Android平台上native的crash其实是可以catch的
Chromium 的Breakpad是目前 Native 崩溃捕获中最成熟的方案

### 18. bitmap 4096
Bitmap too large to be uploaded into a texture (9425x1920, max=8192x8192)
4096还是8192这个数值不确定,[stackoverflow上的回答](https://stackoverflow.com/questions/15313807/android-maximum-allowed-width-height-of-bitmap)教会如何查
```java
int[] maxSize = new int[1];
gl.glGetIntegerv(GL10.GL_MAX_TEXTURE_SIZE, maxSize, 0);
Log.e("GL", "CURRENT MAX IS "+String.valueOf(maxSize[0]));
// maxSize[0] now contains max size(in both dimensions)
```

### 19. RenderScript的使用方式
[高斯模糊](https://www.jianshu.com/p/f2352c95d391)
```java
//首先从一个view中获取Bitmap,在父viewgroup中addView(ImageView),setImageBItmap(blurredBitmap)
public static Bitmap getViewBitmap(View v) {
    if(v.getWidth() == 0 || v.getHeight() == 0)
        return null;
    Bitmap b = Bitmap.createBitmap( v.getWidth(), v.getHeight(), Bitmap.Config.ARGB_8888);
    Canvas c = new Canvas(b);
    v.draw(c);
    return b;
}

public Bitmap blurBitmap(Bitmap bitmap){
		
	//Let's create an empty bitmap with the same size of the bitmap we want to blur
	Bitmap outBitmap = Bitmap.createBitmap(bitmap.getWidth(), bitmap.getHeight(), Config.ARGB_8888);
		
	//Instantiate a new Renderscript
	RenderScript rs = RenderScript.create(getApplicationContext());
		
	//Create an Intrinsic Blur Script using the Renderscript
	ScriptIntrinsicBlur blurScript = ScriptIntrinsicBlur.create(rs, Element.U8_4(rs));
		
	//Create the Allocations (in/out) with the Renderscript and the in/out bitmaps
	Allocation allIn = Allocation.createFromBitmap(rs, bitmap);
	Allocation allOut = Allocation.createFromBitmap(rs, outBitmap);
		
	//Set the radius of the blur: 0 < radius <= 25
	blurScript.setRadius(25.0f);
		
	//Perform the Renderscript
	blurScript.setInput(allIn);
	blurScript.forEach(allOut);
		
	//Copy the final bitmap created by the out Allocation to the outBitmap
	allOut.copyTo(outBitmap);
		
	//recycle the original bitmap
	bitmap.recycle();
		
	//After finishing everything, we destroy the Renderscript.
	rs.destroy();
		
	return outBitmap;	
		
}
```

## 20. webView是可以设置代理的
在Android中webView是可以通过反射的方式为webView设置代理的
[参考](https://www.jianshu.com/p/d02e8818a72e)。
[蘑菇街在处理系统 WebView 请求的时候，为系统的 WebView 设置代理，将请求发送至本地端口。同时在网络库中实现了一个 Http Proxy Server，能转发所监听端口的 http，https 请求，所有接收到的 http，https 请求，可以经过自己的网络库转发出去，这样所有自有网络库的修改，优化都可以生效。](https://www.infoq.cn/article/mogujie-app-chromium-network-layer)


## 21.Android上敏感信息存储本地应该存在哪里
在shadowsocks-android中看到这样一段源码,外加这样一段注释说config文件属于敏感信息，要么加密保存，要么存在设备存储中
```js
  /**
     * Sensitive shadowsocks configuration file requires extra protection. It may be stored in encrypted storage or
     * device storage, depending on which is currently available.
     */
 val configRoot = (if (Build.VERSION.SDK_INT < 24 || app.getSystemService<UserManager>()
                            ?.isUserUnlocked != false) app else Core.deviceStorage).noBackupFilesDir
 val configFile =  File(configRoot, "shadowsocks.conf")                            
```

**isUserUnlocked（added in api 24）**
>
Return whether the calling user is running in an "unlocked" state.
On devices with direct boot, a user is unlocked only after they've entered their credentials (such as a lock pattern or PIN). On devices without direct boot, a user is unlocked as soon as it starts.
When a user is locked, only device-protected data storage is available. When a user is unlocked, both device-protected and credential-protected private app data storage is available.

所以上面的文件路径在api 24或者userUnlocked（已经解锁）的情况下，用的是Application.noBackupFilesDir,否则用的是context.createDeviceProtectedStorageContext()创建出来的一个context(也就是在24以上)。noBackupFilesDir的意思只是不会被自动同步，这种敏感信息当然不应该被同步。

至于安全性，getFilesDir()这种返回的属于internal Storage。根据[Commonsware的解释](https://stackoverflow.com/questions/43710317/is-storing-data-using-file-input-output-stream-method-secure)的解释，这个位置的文件只有当前app（或者有root权限的app）能够读或者写，其他的app一律deny。所以如果不考虑root的情况下，这个位置其实是很安全的。

android:sharedUserId这个属性可以让两个app共享getFilesDir()下面的文件（前提是signing key相同），事实上这些文件的owner都是同一个linux user。
最后提一下这个目录的位置
```java
File f=new File("/data/data/their.app.package.name/files/foo.txt");
File f=new File(getFilesDir(), "foo.txt");
```
their.app.package.name这个文件夹下面有几个目录cache,shared_prefs...

## 22. 在Android上使用mmap等linux通信手段
> 在数据访问中，内存的访问速度肯定是最快的，所以对于有些文件需要频繁高效访问的时候就可以考虑使用内存映射进行直接读写操作，代替IO读写，达到更高的效率。

[Android简单内存映射与访问](http://www.wxtlife.com/2016/01/17/Android-memory-map/) Linux提供了内存映射函数mmap, 它把文件内容映射到一段内存上(准确说是虚拟内存上), 通过对这段内存的读取和修改, 实现对文件的读取和修改,mmap()系统调用使得进程之间可以通过映射一个普通的文件实现共享内存。普通文件映射到进程地址空间后，进程可以向访问内存的方式对文件进行访问，不需要其他系统调用(read,write)去操作。


[进程崩溃时，mmap的内存内核是会帮你写回到磁盘的](https://github.com/wangxuemin/myblog/blob/master/md_bk/linux中mmap文件到内存中，该进程发生错误被挂掉后mmap映射的内存能否写回到文件中的问题.md)

当然可以自己写jni打成so文件，只是jdk已经提供了写好的jni（其实MappedByteBuffer就是简单的一层c语言mmap包裹），没必要自己写
```java
private MappedByteBuffer memoryMap = null;
private void initMemoryMap() {
		if (memoryMap == null) {
			RandomAccessFile raf = null;
			try {
				// 和前面c++映射的文件名一致。
				raf = new RandomAccessFile("/tmp/memory_map", "rw");
				FileChannel fc = raf.getChannel();
				memoryMap = fc.map(FileChannel.MapMode.READ_WRITE, 0, 16);
			} catch (FileNotFoundException e) {
				e.printStackTrace();
			} catch (IOException e) {
				e.printStackTrace();
			} finally {
				if (raf != null) {
					try {
						raf.close();
					} catch (IOException e) {
						e.printStackTrace();
					}
				}
			}
		}
	}
```
通过FileChannel的map(),可以将指定区域范围的文件直接读到内存中，返回MappedByteBuffer类型,这里称之为内存映射.然后通过MappedByteBuffer取或写对应标记位数据。
如何取呢？通过memoryMap.get(index) 来取指定位置的字节数据，index根据标记位的位置来确认，比如前面mFlag的标记位为是在文件头向后偏移了一个4个字节，所以这里要取相同的值则是要使用memoryMap.get(4)即可，如果要设置标记位的值可以使用put(index,value)函数，例如：memoryMap.put(4,(byte)1);
其实在Android上层也很简单，相当于读文件，**把文件描述符映射到内存中，这种方式比每次进行文件IO操作肯定快很多。** 想到什么？ log4j使用mmmap将写日志变成对内存的操作 [早就有人这样做了](https://github.com/pqpo/Log4a) 注意的是，快是快，但多线程操作还是要加锁，多进程操作还是要用信号量同步

类似的使用mmap的库还有很多: mmkv (腾讯的KV存储),Tokyo Cabinet (比较早的一个kv存储系统)

## 23. Android图片质量会比iPhone的差是有原因的
[替换libjpeg库](https://www.jianshu.com/p/9b47fc25f526)
大致是，Android编码保存图片就是通过Java层函数——Native层函数——Skia库函数——对应第三方库函数（例如libjpeg），这一层层调用做到的。 libjpeg在压缩图像时，有一个参数叫optimize_coding，如果设置optimize_coding为TRUE，将会使得压缩图像过程中基于图像数据计算哈弗曼表，由于这个计算会显著消耗空间和时间，默认值被设置为FALSE。对于当时的计算设备来说，空间和时间的消耗可能是显著的，但到今天，这似乎不应再是问题。但谷歌的Skia项目工程师们对optimize_coding在Skia中默认的等于了FALSE，这就意味着更差的图片质量和更大的图片文件。还有其他和iOS的比较可以看下。
也讲到了Android可以替换libjpeg库达到设置为TRUE的目的。
[Android图片编码机制深度解析（Bitmap，Skia，libJpeg）](http://www.cnblogs.com/hrlnw/p/4403334.html)

## 24.TransactionTooLargeException的原因及规避方案
[使用AndroidSharedMemory](https://github.com/mc2012/Android-AshMemory) 其实也就是MemoryFile这个class了
[Android 通过匿名共享内存传输Parcelable对象列表](https://www.jianshu.com/p/73714d399eb7)
> TransactionTooLargeException这个异常，这个java异常是在jni层抛出的，可见android_util_binder.cpp中关于这个异常的解释，大概意思是“传输太大是最常见的原应，但是不是唯一原应，也有可能是FD，应该就是描述binder驱动的文件描是符关闭了，以及可能其他原因”，这里暂且只关注常见的。我们在组件间通信时会使用intent传输一些参数，一步小心会带上一些大对象，组件启动到底层都会通过ActivityManagerService这个守护神，属于进程间通信，最终都需要使用Parcel将数据写入内核中由Binder开辟的一块区域，Binder驱动open的区域一般为4M，而进程间传输的数据大小会限制在1M，而且这1M是被这个进程所有正在进行的binder通信所共同使用的，所以一般情况下也就达不到1M，可想而知，我们要是传个Bitmap啥的，离奔溃也就不远了。

原理就是在主进程里面使用MemoryFile("test",bytearray.length), 往这个memoryFile里面写bytes，搞定之后通过反射拿到MemoryFile.getFileDescriptor方法,invoke这个方法。（获得底层SharedMemory在本进程中的fd,注意，这只是个Int值，并且在另一个进程中这个int值是不一样的。但是我们可以通过binder把这个fd包装成ParcelFileDescriptor，传到remote process中。）remote process在读取bytes的时候，读到的fd 的int值不一样，但是可以直接根据new FileInputStream(fd)，从中读取指定长度的bytes array， marshall一下，也就能够在remote process中创建刚才那份object的备份了。(api 27之后提供了sharedMemory的public api，而MemoryFile则是MemoryFile的一层Wrapper)
亲测，这种方式可以写50MB以上的byte array，只是bytes[]太大的话，写的进程会看到很多GC日志，所以会比较慢。读数据的一端也是一样的道理，会慢一点。
看上去就像是A进程往一个系统共享的内存写了50MB数据，然后走Binder告诉B进程这个内存的地址，后者自己去那里读数据
共享内存只要读一次，写一次，效率最高
采用共享内存通信的一个显而易见的好处是效率高，因为进程可以直接读写内存，而不需要任何数据的拷贝。
对于像管道和消息队列等通信方式，则需要在内核和用户空间进行四次的数据拷贝，
而共享内存则只拷贝两次数据[1]： 
1.一次从输入文件到共享内存区，
2.另一次从共享内存区到输出文件。

至少在[6.0的Bitmap.cpp](https://android.googlesource.com/platform/frameworks/base/+/refs/heads/marshmallow-release/core/jni/android/graphics/Bitmap.cpp)代码中还看到parcel写bitmap会尝试使用匿名共享内存的影子。如果不行才走writeBlob方法(1MB限制，TransactionTooLargeException是jni丢出来的方法).
```c++
static jboolean Bitmap_writeToParcel(JNIEnv* env, jobject,
                                     jlong bitmapHandle,
                                     jboolean isMutable, jint density,
                                     jobject parcel) {
                                         ...
    // Transfer the underlying ashmem region if we have one and it's immutable.
    android::status_t status;
    int fd = androidBitmap->getAshmemFd(); //这里获得共享内存
    if (fd >= 0 && !isMutable && p->allowFds()) { //allowFds默认是true的
#if DEBUG_PARCEL
        ALOGD("Bitmap.writeToParcel: transferring immutable bitmap's ashmem fd as "
                "immutable blob (fds %s)",
                p->allowFds() ? "allowed" : "forbidden");
#endif
        status = p->writeDupImmutableBlobFileDescriptor(fd);
        if (status) {
            doThrowRE(env, "Could not write bitmap blob file descriptor.");
            return JNI_FALSE;
        }
        return JNI_TRUE;
    }
    // Copy the bitmap to a new blob.
    bool mutableCopy = isMutable;
#if DEBUG_PARCEL
    ALOGD("Bitmap.writeToParcel: copying %s bitmap into new %s blob (fds %s)",
            isMutable ? "mutable" : "immutable",
            mutableCopy ? "mutable" : "immutable",
            p->allowFds() ? "allowed" : "forbidden");
#endif
    size_t size = bitmap.getSize();
    android::Parcel::WritableBlob blob;
    status = p->writeBlob(size, mutableCopy, &blob); //退而求其次，使用writeBlob
    ....
    }
```
不过后来的release好像又删掉了走共享内存这段

### 25. activity的启动流程是怎样的
```java
Activity.startActivity
Activity.startActivityForResult
Instrumentation.execStartActivity
ActivityManagerProxy.startActivity
---
ActivityManagerService.startActivity
ActivityStack.startActivityMayWait
ActivityStack.startActivityLocked
ActivityStack.startActivityUncheckedLocked
ActivityStack.resumeTopActivityLocked
ActivityStack.startPausingLocked
ApplicationThreadProxy.schedulePauseActivity
---
ApplicationThread.schedulePauseActivity
ActivityThread.queueOrSendMessage
H.handleMessage
ActivityThread.handlePauseActivity
ActivityManagerProxy.activityPaused
---
ActivityManagerService.activityPaused
ActivityStack.activityPaused
ActivityStack.completePauseLocked
ActivityStack.resumeTopActivityLokced
ActivityStack.startSpecificActivityLocked
ActivityStack.realStartActivityLocked
---
ApplicationThreadProxy.scheduleLaunchActivity
ApplicationThread.scheduleLaunchActivity
ActivityThread.queueOrSendMessage
H.handleMessage
ActivityThread.handleLaunchActivity
ActivityThread.performLaunchActivity
*AcitiviyB.onCreate
```


### 26. SharedPreference的apply用多了有一个比较需要注意的anr隐患
(Android中SharedPreferenceImpl中写磁盘操作有一个writtenToDiskLatch(CountDownLatch)，这个也是SharedPreference在activity onStop或者onPause中可能导致anr的原因)
给看一下堆栈就清楚了
```
"main" prio=5 tid=1 WAIT
  | group="main" sCount=1 dsCount=0 obj=0x4155cc90 self=0x41496408
  | sysTid=13523 nice=0 sched=0/0 cgrp=apps handle=1074110804
  | state=S schedstat=( 2098661082 1582204811 6433 ) utm=165 stm=44 core=0
  at java.lang.Object.wait(Native Method)
  - waiting on <0x4155cd60> (a java.lang.VMThread) held by tid=1 (main)
  at java.lang.Thread.parkFor(Thread.java:1205)
  at sun.misc.Unsafe.park(Unsafe.java:325)
  at java.util.concurrent.locks.LockSupport.park(LockSupport.java:157)
  at java.util.concurrent.locks.AbstractQueuedSynchronizer.parkAndCheckInterrupt(AbstractQueuedSynchronizer.java:813)
  at java.util.concurrent.locks.AbstractQueuedSynchronizer.doAcquireSharedInterruptibly(AbstractQueuedSynchronizer.java:973)
  at java.util.concurrent.locks.AbstractQueuedSynchronizer.acquireSharedInterruptibly(AbstractQueuedSynchronizer.java:1281)
  at java.util.concurrent.CountDownLatch.await(CountDownLatch.java:202)
  at android.app.SharedPreferencesImpl$EditorImpl$1.run(SharedPreferencesImpl.java:364)
  at android.app.QueuedWork.waitToFinish(QueuedWork.java:88)
  at android.app.ActivityThread.handleServiceArgs(ActivityThread.java:2689)
  at android.app.ActivityThread.access$2000(ActivityThread.java:135)
  at android.app.ActivityThread$H.handleMessage(ActivityThread.java:1494)
  at android.os.Handler.dispatchMessage(Handler.java:102)
  at android.os.Looper.loop(Looper.java:137)
  at android.app.ActivityThread.main(ActivityThread.java:4998)
  at java.lang.reflect.Method.invokeNative(Native Method)
  at java.lang.reflect.Method.invoke(Method.java:515)
  at com.android.internal.os.ZygoteInit$MethodAndArgsCaller.run(ZygoteInit.java:777)
  at com.android.internal.os.ZygoteInit.main(ZygoteInit.java:593)
  at dalvik.system.NativeStart.main(Native Method)
```

看上去像是SharedPreferencesImpl$EditorImpl$1这个class堵住了主线程
这个匿名内部类就干了这么件事，堵住了主线程。此时HandlerThread正在忙着写磁盘呢。
```java
 final Runnable awaitCommit = new Runnable() {
                    @Override
                    public void run() {
                        try {
                            mcr.writtenToDiskLatch.await();}}}
```
这种情况重现的方式是，在任意线程apply 1000次，然后按返回键。。。应该会把主线程给堵住


countDownLatch的javaDoc是这么说的：
If the current count is zero then this method returns immediately.
If the current count is greater than zero then the current thread becomes disabled for thread scheduling purposes and lies dormant until one of two things happen:
The count reaches zero due to invocations of the countDown method; or
Some other thread interrupts the current thread.
If the current thread:
has its interrupted status set on entry to this method; or
is interrupted while waiting,
then InterruptedException is thrown and the current thread's interrupted status is cleared.

当前数量是0的话，立刻返回；大于0 的话，就等别人调用coutDown()方法或者其他线程interrupts这条线程


另外,The SharedPreferences implementation in Android is thread-safe but not process-safe.(线程安全)
原因是，apply的时候有这么一段
```java
synchronized (SharedPreferencesImpl.this.mLock) {
    // mMap ，顺便说一下,getXXX的时候也要  synchronized (mLock) {}，所以极端情况下，A线程写完之后去apply后马上又去put（此时获得了mLock，read这一端就看不到最新的数据了）
//所谓线程安全就是读和写都用了一把锁。可以保证的是apply或者commit对内存中map进行写时，任何试图读的线程都会因为拿不到锁而等待
}
```

关于sharedPreference的工作流程嘛，getXXX的时候从一个mMap里面getXXX(用一个mLock包起来了),putxxx的时候就是拿着这把锁(mLock)，往一个mModified的map里丢数据，apply的时候先去commitToMemory(就是抢到这把锁mLock，一个个去往mMap里面比较containsKey，然后clear这个mModified)。另外,mMap是创建的时候就起了一个线程，loadFromDisk之后生成这个map。
写磁盘分为apply和commit，apply是先commitToMemory，然后enqueueDiskWrite()。commit在特定情况下直接在调用commit的线程中写磁盘，这个特定情况是指（c，mDiskWritesInFlight在每次调用commitToMemory中加一，写完磁盘后减一，所以这种特殊情况一般出现在刚调用一次commit之后，就是说等待同步到磁盘上的写次数只有一次的时候就直接写磁盘了。）否则立刻给handler发送一个消息去处理写磁盘任务队列 。

在commit里面，enqueueDiskWrite之后调用了writtenToDiskLatch.await();（如果是同步写，写的里面就通过countDown把count变成0，所以这里直接返回）。如果是跑到那个handlerThread里面去写。enqueueDiskWrite还指定了一个postWriteRunnable(就是countDown，所以这里会堵住)

这样看来，commit的堵塞有两种堵法，一种是直接在当前线程做io堵住(mDiskWritesInFlight == 1)v，另一种是CountDownLatch.await(等其他线程写完了之后countDown，这里的线程才能唤醒)。



```java
HandlerThread handlerThread = new HandlerThread("queued-work-looper",
                    Process.THREAD_PRIORITY_FOREGROUND); //这个是apply里面写磁盘的后台线程
```

往这条HandlerThread上推任务时有延时(延时100ms再post)和立刻执行(立刻post，理论上应该会唤醒等待的looper，算是立刻执行吧)两种方式

### 27. 半夜看到一篇关于miui的开发者文档，顿时感觉不是所有的问题都能通过技术来解决
[miui](https://dev.mi.com/docs/appsmarket/technical_docs/adaptation_FAQ/#1manifestandroidpermissioninternet)。这里面描述了muui上开发的一些问题：例如
Q:如何获取某项权限是否开启？
A:暂时没有这个查询接口

Q:为什么不能在锁屏显示Activity(这个我自己看到的是网易云音乐这种也不能在miui上锁屏)
A:MIUI引入了锁屏显示窗口权限控制，默认不能在锁屏上显示Activity

早一些看到这样的文档，也不至于浪费太多时间和国产rom进行调试吧，没意思的。当然还是要看价值。

## 28. 关于android中如何收集native crash的问题
[libcorkscrew](https://www.jianshu.com/p/5f8f6d95b79c) 一种基于linux信号量的收集crash的方式
生产环境见过用[爱奇艺的一个库](https://github.com/iqiyi/xCrash)

[安卓打包流程](https://api1.reindeer36.shop/static/imgs/android_build_detail.png)


### 29. MiuiResources不能随便替换
Resource.getClass().getName().equals("android.content.res.MiuiResources")的时候，ContextImpl的resource不能换。
