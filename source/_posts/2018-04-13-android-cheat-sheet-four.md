---
title: Android知识集合[四]
date: 2018-04-13 13:53:52
tags: [android]
---


![](https://www.haldir66.ga/static/imgs/street%20lights%20dark%20night%20car%20city%20bw.jpg)

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
![](https://www.haldir66.ga/static/imgs/toast_transact.jpg)
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
a Navive implementation of CircleImageView would look something like this:
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
javah -d jni com.your.package.name.classyoujustWroteWithnativeMethod

把生成的header文件剪切到和main/Java文件夹平级的jni文件夹中，再去写c的实现。

移植mp3lame到Android平台照着[这里](https://www.jianshu.com/p/065bfe6d3ec2)操作就行了。
这篇博客使用的是lame-3.99.5，注意下载对应的版本。
[cmake的一些知识点](http://cfanr.cn/2017/08/26/Android-NDK-dev-CMake-s-usage/)
cmake生成的.so文件在"\app\build\intermediates\cmake\debug\obj\arm64-v8a"这个路径下

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

