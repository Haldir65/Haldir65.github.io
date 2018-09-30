---
title: Android知识集合[三]
date: 2017-12-08 22:33:26
tags: [android,tools]
---

之前的文章快装不下了，所以另外开一篇文章专门放Android相关的杂乱的知识点。
![](https://www.haldir66.ga/static/imgs/scenery1511100734648.jpg)
<!--more-->


[Android Source code](https://android-review.googlesource.com)，能够实时看到提交信息
[androidxref，一个比较好的查看源码的网站](http://androidxref.com/7.1.2_r36/xref/frameworks/base/core/java/android/widget/)
[From View to Pixel](https://www.youtube.com/watch?v=CMzCccqE_R0)讲了ViewRootImpl,SurfaceFlinger这些东西
[一个很长的关于显示原理的文章](https://juejin.im/post/5a1e8d5ef265da431280ae19)，基本上什么都讲了



### 1.基本上所有的Android System Event都是从ActivityThread中发起的
onDetachedFromWindow是从ActivityThread的handleDestoryActivity传下来的，走到windowManager.removeViewImediate,然后ViewRootImpl.doDie,然后ViewRootImpl.dispatchDetachedFromWindow，然后DecoreView.dispatchDetachedFromWindow，然后一个个child传下去。所有的View走完了之后，DecorView在onDetachedFromWindow中以Window.Callback的方式顺手通知了Activity的onDetachedFromWindow。其实打个断点看的话就快一点。

### 2. onSaveInstance对于有id的View，系统会自动帮忙存一点东西
当然onSaveInstance也是从ActivityThread里面传递下来的。还有就是onCreate(Bundle)和onRestroreSaveInstanceState(Bundle)里面的bundle是同一个object。romain Guy说最初onSaveInstance和onRestroreSaveInstanceState本来叫onIcy(冻结)和onThaw（解冻），确实很形象。
其实这个到现在还有一些痕迹:
ViewGroup.java
```java
protected void dispatchFreezeSelfOnly(SparseArray<Parcelable> container) {
     super.dispatchSaveInstanceState(container);
 }

 protected void dispatchThawSelfOnly(SparseArray<Parcelable> container) {
     super.dispatchRestoreInstanceState(container);
 }
```

### 3.android asset atlas
就是为了节省asset耗费的内存，将一些系统公用的资源作为一个服务先跑起来，所有app的process共用这部分资源。

### 4. ZygoteInit
[这篇文章](http://www.10tiao.com/html/599/201703/2651434963/1.html)讲到了从Launcher点击icon到起一个app的过程，Launcher所在进程通过IPC走startActivity请求位于system_server进程的ActivityManagerService,后者通过socket(Zygote进程跑起来之后就一直在循环等待请求)请求Zygote fork出一个app的进程，接着通知system_server去走Binder IPC去scheduleStartActivity(后面就都是App所在进程了)。


### 5. Michael Bailey每年的演讲都很精彩
[Droidcon NYC 2015 - How the Main Thread works](https://www.youtube.com/watch?v=eAtMon8ndfk)
[Droidcon NYC 2016 - How LayoutInflater works](https://www.youtube.com/watch?v=Y06wmVIFlsw)
[droidcon NYC 2017 - How Espresso Works](https://www.youtube.com/watch?v=7lCsp84wVPM)

2016年的演讲中提到了LayoutInflater中的好玩的注释
LayoutInflater.java
```java
if (name.equals(TAG_1995)) {
            // Let's party like it's 1995!
            return new BlinkLayout(context, attrs);
        }
```

### 6. Chris Banes在2017年给出了关于状态栏的解释
[droidcon NYC 2017 - Becoming a master window fitter](https://www.youtube.com/watch?v=_mGDMVRO3iE)

### 7. Android默认的launcher的repo在
[Launcher3](https://android.googlesource.com/platform/packages/apps/Launcher3/),应该是属于System UI Team在维护。
todo 那个点击了icon进应用的点击事件在哪里。大致是在Launcher.java这个文件的startActivitySafely里面

### 8. 在string.xml里面放一些format的字符

```java
public static void main(String[] args) {
   String s1 = "这里面可以放多个字符串%1$s,%2$s前面加上一个百分号和数字，代表顺序";
   String s2 = "百分号的d和百分号的s可以混着%1$s用的，比如这个%2$d数字什么的，第三个是带百分号的数字%3$d%%这个由于需要显示百分号，所以加上两个百分号";

   System.out.println(String.format(s1,"XXXX","XXX"));
   System.out.println(String.format(s2,"XXX", 100, 100));
}
```
实际输出
> 这里面可以放多个字符串XXXX,XXX前面加上一个百分号和数字，代表顺序
百分号的d和百分号的s可以混着XXX用的，比如这个100数字什么的，第三个是带百分号的数字100%这个由于需要显示百分号，所以加上两个百分号

[%d represents an integer; you want to use %f for a double.  ](https://stackoverflow.com/questions/3693079/problem-with-system-out-printf-command-in-java)
据猜测d代表decimal而不是double

### 9.我记得Chet Haase说过Lollipop及以上的Button默认是有一个elevation的
记得Chet在一次演讲中说到Appcompat在5.0以上默认使用material Theme, Button的默认elevation好像是3dp。日常开发中也经常会看见button和设置elevation=0的button相比确实有些阴影。在Button的构造函数里面打了断点，在setElevation也打了断点，最后发现是在View创建之后Choregrapher在doFrame的时候run了一个Animation，在这个animation中设置了一个6px的elevation(2dp，原来Chet记错了)。
至于这个2dp是那来的呢：
```xml
<Button
    ...

    android:stateListAnimator="@null" />

    <Button
    ...

    android:stateListAnimator="@anim/my_animator" />
```
最终在网上[找到了](http://www.itmmd.com/201412/240.html)
core/res/res/anim/button_state_list_anim_material.xml
```xml
<?xml version="1.0" encoding="utf-8"?>
<selector xmlns:android="http://schemas.android.com/apk/res/android">
  <item android:state_pressed="true" android:state_enabled="true">
      <set>
          <objectAnimator android:propertyName="translationZ"
                          android:duration="@integer/button_pressed_animation_duration" 100ms
                          android:valueTo="@dimen/button_pressed_z_material" ## 4dp 其实稍微注意下，手指按住一个Button的时候，Button底部的阴影会扩大，就是这个4dp的属性动画在跑
                          android:valueType="floatType"/>
          <objectAnimator android:propertyName="elevation"
                          android:duration="0"
                          android:valueTo="@dimen/button_elevation_material" ## 2dp
                          android:valueType="floatType"/>
      </set>
  </item>
  <!-- base state -->
  <item android:state_enabled="true">
      <set>
          <objectAnimator android:propertyName="translationZ"
                          android:duration="@integer/button_pressed_animation_duration"  ##100ms
                          android:valueTo="0"
                          android:startDelay="@integer/button_pressed_animation_delay" ## 100ms
                          android:valueType="floatType"/>
          <objectAnimator android:propertyName="elevation"
                          android:duration="0"
                          android:valueTo="@dimen/button_elevation_material" ## 2dp
                          android:valueType="floatType" />
      </set>
  </item>
  <item>
      <set>
          <objectAnimator android:propertyName="translationZ"
                          android:duration="0"
                          android:valueTo="0"
                          android:valueType="floatType"/>
          <objectAnimator android:propertyName="elevation"
                          android:duration="0"
                          android:valueTo="0"
                          android:valueType="floatType"/>
      </set>
  </item>
</selector>
```
注意那个button_elevation_material：
在[aosp](https://android.googlesource.com/platform/frameworks/base/+/master/core/res/res/values/dimens_material.xml)中
```xml
<!-- Elevation when button is pressed -->
    <dimen name="button_elevation_material">2dp</dimen>
    <!-- Z translation to apply when button is pressed -->
    <dimen name="button_pressed_z_material">4dp</dimen>
```
***所以Lollipop上使用Appcompat主题，什么都不改，button默认是会有2dp的elevation的***
至于这个elevation为什么不是在初始化的时候就设置的（打断点的时候走完构造函数,getElevation还是0），就在于这上面这个AnimationDelay(其实是100ms之后再去运行这个动画)，从堆栈来看，最终导致调用setElevation的地方是在drawableStateChange这个方法里面。

### 10. 内网传输功能的原理
有些App提供局域网内无限传输文件的能力：本质上是用了TCP或者UDP。在java层的话，TCP用的是java.net.Socket，UDP用的是java.net.DatagramSocket。由于数据传输是双向的，客户端和Server端都需要创建这样的Object Instance。
[一个比较好的Demo](https://github.com/xanarry/LanTrans-android)
Unix的输入输出(IO)系统遵循Open-Read-Write-Close这样的操作范本。


### 11.v7包里面的Toolbar只是一个自定义View
随便举一个例子，右上角的optionMenu点击跳出的弹窗里面其实是一个ListView，具体的class是android.support.v7.view.menu.ListMenuItemView。都是很常规的自定义View的做法，这个ListView的Adapter叫做MenuAdapter，这个Adapter的itemLayout布局文件叫做abc_popup_menu_item_layout.xml
abc_popup_menu_item_layout.xml
```xml
<android.support.v7.internal.view.menu.ListMenuItemView
        xmlns:android="http://schemas.android.com/apk/res/android"
        android:layout_width="fill_parent"
        android:layout_height="?attr/dropdownListPreferredItemHeight"
        android:minWidth="196dip"
        android:paddingRight="16dip">

    <!-- Icon will be inserted here. -->

    <!-- The title and summary have some gap between them, and this 'group' should be centered vertically. -->
    <RelativeLayout
            android:layout_width="0dip"
            android:layout_weight="1"
            android:layout_height="wrap_content"
            android:layout_gravity="center_vertical"
            android:layout_marginLeft="16dip"
            android:duplicateParentState="true">

        <TextView
                android:id="@+id/title"
                android:layout_width="fill_parent"
                android:layout_height="wrap_content"
                android:layout_alignParentTop="true"
                android:layout_alignParentLeft="true"
                android:textAppearance="?attr/textAppearanceLargePopupMenu"
                android:singleLine="true"
                android:duplicateParentState="true"
                android:ellipsize="marquee"
                android:fadingEdge="horizontal"/>

        <TextView
                android:id="@+id/shortcut"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:layout_below="@id/title"
                android:layout_alignParentLeft="true"
                android:textAppearance="?attr/textAppearanceSmallPopupMenu"
                android:singleLine="true"
                android:duplicateParentState="true"/>

    </RelativeLayout>

    <!-- Checkbox, and/or radio button will be inserted here. -->

</android.support.v7.internal.view.menu.ListMenuItemView>
```
一般来讲，MenuItem的字体大小，颜色都是需要在theme中写的。所以照说硬要用findViewById(ViewGroup的findViewTraversal)其实是能找到的。

### 12. Message.ontain以及相似的场景
MotionEvent.ontain()，TouchTarget.ontain(),HoverTarget.ontain()....
MotionEvent最多缓存10个，TouchTarget和HoverTarget这些都是在看ViewGroup源码的时候瞅到的，简单点。
稍微看下就知道这种obtain,recycle写法的套路。
```java
private static final class TouchTarget {
      private static final int MAX_RECYCLED = 32;
      private static final Object sRecycleLock = new Object[0];
      private static TouchTarget sRecycleBin;
      private static int sRecycledCount;

      public static final int ALL_POINTER_IDS = -1; // all ones

      // The touched child view.
      public View child;

      // The combined bit mask of pointer ids for all pointers captured by the target.
      public int pointerIdBits;

      // The next target in the target list.
      public TouchTarget next;

      private TouchTarget() {
      }

      public static TouchTarget obtain(@NonNull View child, int pointerIdBits) {
          if (child == null) {
              throw new IllegalArgumentException("child must be non-null");
          }

          final TouchTarget target;
          synchronized (sRecycleLock) {
              if (sRecycleBin == null) {
                  target = new TouchTarget();
              } else {
                  target = sRecycleBin;
                  sRecycleBin = target.next;
                   sRecycledCount--;
                  target.next = null;
              }
          }
          target.child = child;
          target.pointerIdBits = pointerIdBits;
          return target;
      }

      public void recycle() {
          if (child == null) {
              throw new IllegalStateException("already recycled once");
          }

          synchronized (sRecycleLock) {
              if (sRecycledCount < MAX_RECYCLED) {
                  next = sRecycleBin;
                  sRecycleBin = this;
                  sRecycledCount += 1;
              } else {
                  next = null;
              }
              child = null;
          }
      }
  }
```


### 13. 从点击Launcher到应用启动的过程
> 借助binder驱动
ActivityManagerService.startActivity-> (AMS)  
...
//一系类AMS的调用链和一些与Launcher通过Binder的互相调用过程，此时仍然未创建应用程序的进程。
...
 AMS创建一个新的进程，用来启动一个ActivityThread实例，
 即将要启动的Activity就是在这个ActivityThread实例中运行
Process.start("android.app.ActivityThread",...)->    
// 通过zygote机制创建一个新的进程    
Process.startViaZygote->调用新进程的main()
ActivityThread.main->

[Android 应用点击图标到Activity界面显示的过程分析](https://juejin.im/entry/5a0d02086fb9a045263b2387)

### 14. Context是什么
ActivityThread.java  
```java
createBaseContextForActivity{
  ContextImpl appContext = ContextImpl.createActivityContext(
                 this, r.packageInfo, r.activityInfo, r.token, displayId, r.overrideConfig);
}
```
ContextImpl包含资源信息、对Context的一些函数的实现等。每次创建Activity都会新建一个ContextImpl


### 15. Dex file explained
[The Dex File Format](https://blog.bugsnag.com/dex-and-d8/)


### 16 .PackageParser和Android.manifest文件有关
[Android APK应用安装原理(1)-解析AndroidManifest原理-](http://blog.csdn.net/zhbinary/article/details/7353739).

### 17. 在Dialog中getContext获取的是ContextThemeWrapper
ContextThemeWrapper是API 1就有了的，主要是包装一下context，将Context的外部调用添加一些包装。

### 18. 低版本的xml属性怎么写
mylayout.xml
```xml
<Button
       android:layout_width="wrap_content"
       android:layout_height="wrap_content"
       android:elevation="10dp"
       />
```
这样写的话，Lint肯定会报warning。
解决办法，alt+enter，Android studio自动生成一个/layout-v21/maylayout.xml。现在想起来很多项目里v-xx文件夹，其实是这个意思。
还有一种写法
> style="?android:attr/borderlessButtonStyle"
自己写style也是行的

### 19. LocalBroadCastManager<del>好像</del>确实是基于handler实现的
App内部全局拥有一个LocalBroadCastManager实例，内部持有一个handler，对外暴露功能sendBroadcast。就是往handler里丢一个message MSG_EXEC_PENDING_BROADCASTS，处理这个message就是executePendingBroadcasts。所以默认是在下一个message中处理的。如果想在当前message中就处理掉，还有一个sendBroadcastSync方法，但这会把当前持有的所有待处理消息全部flush掉。sendBroadcast，unregisterReceiver，registerReceiver内部用了synchronize，所以是线程安全的。
[stackoverflow上也有人指出LocalBrodcatManager不支持ipc](https://stackoverflow.com/questions/38751320/android-unable-to-receive-local-broadcast-in-my-activity-from-service).BroadcastReceiver倒是可以的，ContentProvider也是官方支持ipc的组件

### 20. ViewPager为什么没有那些attrs的可以写在xml里面的属性
 Adam Powell在15年的Android Dev summit上说过：this is pre aar gradle age, if we were to do it today , we definitely would add。
 看了下aosp的git日志，ViewPager是2011年就有了的。而[aar](https://developer.android.com/studio/projects/android-library.html#CreateLibrary)是随着android studio的发布推出的。
 jar和aar的区别:
 jar : JAR 文件就是 Java Archive File，顾名思意，它的应用是与 Java 息息相关的，是 Java 的一种文档格式。只包含了class文件与清单文件 ，不包含资源文件，如图片等所有res中的文件。
 aar: aar，AAR（Android Archive）包是一个Android库项目的二进制归档文件,包含一些自己写的控件布局文件以及字体等资源文件(resources或者manifest文件)那么就只能使用*.aar文件。

### 21. 都知道RelativeLayout会measure两次child，LinearLayout在加weight的时候也会measure两次
LinearLayout.java
measureVertical()
```java
// We have no limit, so make all weighted views as tall as the largest child.
        // Children will have already been measured once.
        if (useLargestChild && heightMode != MeasureSpec.EXACTLY) {
            for (int i = 0; i < count; i++) {
                final View child = getVirtualChildAt(i);
                  // ......
            }
        }
```

### 22. gradle wrapper文件的作用
[understanding-the-gradle-wrapper](https://medium.com/@bherbst/understanding-the-gradle-wrapper-a62f35662ab7)
进一个新目录
> gradle wrapper 命令会生成如下目录
├─.gradle
│  ├─4.4.1
│  │  ├─fileChanges
│  │  ├─fileHashes
│  │  └─taskHistory
│  └─buildOutputCleanup
└─gradle
    └─wrapper
这里提到了一些点：gradlew.bat是给windows平台用的，gradlew是给unix平台用的。
gradle/wrapper/gradle-wrapper.jar 里面装的是Gradle Wrapper的代码
gradlew就是一个调用gradle命令的脚本，内部会根据gradle-wrapper.properties里面的distributionUrl下载对应版本的gradle distribution zip文件并解压缩，并只会使用该版本的gradle进行编译

[gradlew就是帮忙安装好gradle然后调用gradle](https://stackoverflow.com/questions/39627231/difference-between-using-gradlew-and-gradle)
其实看一下gradlew文件里面的注释:
> Gradle start up script for UN*X 
其实就是一个bash脚本


### 23. java平台下扫描本地samba服务器用的的一个library叫做import jcifs.smb.SmbFile
[找到一个实例代码](https://github.com/eriklupander/microgramcaster/blob/master/src/com/squeed/microgramcaster/smb/SambaExplorer.java)

### 24.Android平台上js交互的速度
也是从别处看到的，说是java调js的效率不高，大概200ms，js调java好一点，大概50ms左右，所以尽量用js调java。

### 25.在Android平台发起上传图片请求的重点在于掌握http协议（关键词Boundary）
自己用express写了一个上传文件的后台，前端请求/post接口即可上传图片
看了下chrome里面的network
```text
POST /upload/ HTTP/1.1
Host: localhost:3000
Connection: keep-alive
Content-Length: 9860
Accept: */*
Origin: http://localhost:3000
X-Requested-With: XMLHttpRequest
User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 10_3 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) CriOS/56.0.2924.75 Mobile/14E5239e Safari/602.1
Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryw0ZREBdOiJbbwuAg // 注意这句
DNT: 1
Referer: http://localhost:3000/
Accept-Encoding: gzip, deflate, br
Accept-Language: zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7
```

```text
------WebKitFormBoundaryw0ZREBdOiJbbwuAg
Content-Disposition: form-data; name="uploads[]"; filename="278a516893f31a16feee.jpg"
Content-Type: image/jpeg


------WebKitFormBoundaryw0ZREBdOiJbbwuAg--
```
那个WebKitFormBoundary是浏览器自动加的，Content-Disposition也是浏览器加的

这里借用[鸿洋的代码](http://blog.csdn.net/lmj623565791/article/details/23781773)
```java
private static final String BOUNDARY = "----WebKitFormBoundaryT1HoybnYeFOGFlBR";  

public void uploadForm(Map<String, String> params, String fileFormName,  
            File uploadFile, String newFileName, String urlStr)  
            throws IOException {  
        if (newFileName == null || newFileName.trim().equals("")) {  
            newFileName = uploadFile.getName();  
        }  

        StringBuilder sb = new StringBuilder();  
        /**
         * 普通的表单数据
         */  
        for (String key : params.keySet()) {  
            sb.append("--" + BOUNDARY + "\r\n");  
            sb.append("Content-Disposition: form-data; name=\"" + key + "\""  
                    + "\r\n");  
            sb.append("\r\n");  
            sb.append(params.get(key) + "\r\n");  
        }  
        /**
         * 上传文件的头
         */  
        sb.append("--" + BOUNDARY + "\r\n");  
        sb.append("Content-Disposition: form-data; name=\"" + fileFormName  
                + "\"; filename=\"" + newFileName + "\"" + "\r\n");  
        sb.append("Content-Type: image/jpeg" + "\r\n");// 如果服务器端有文件类型的校验，必须明确指定ContentType  
        sb.append("\r\n");  

        byte[] headerInfo = sb.toString().getBytes("UTF-8");  
        byte[] endInfo = ("\r\n--" + BOUNDARY + "--\r\n").getBytes("UTF-8");  
        System.out.println(sb.toString());  
        URL url = new URL(urlStr);  
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();  
        conn.setRequestMethod("POST");  
        conn.setRequestProperty("Content-Type",  
                "multipart/form-data; boundary=" + BOUNDARY);  
        conn.setRequestProperty("Content-Length", String  
                .valueOf(headerInfo.length + uploadFile.length()  
                        + endInfo.length));  
        conn.setDoOutput(true);  

        OutputStream out = conn.getOutputStream();  
        InputStream in = new FileInputStream(uploadFile);  
        out.write(headerInfo);  

        byte[] buf = new byte[1024];  
        int len;  
        while ((len = in.read(buf)) != -1)  
            out.write(buf, 0, len);  

        out.write(endInfo);  
        in.close();  
        out.close();  
        if (conn.getResponseCode() == 200) {  
            System.out.println("上传成功");  
        }  

    }  
```


### 26.ScrollView，RecyclerView的截屏实现
主要是用lru包装下，[参考](https://gist.github.com/PrashamTrivedi/809d2541776c8c141d9a)
```java
public static Bitmap shotRecyclerView(RecyclerView view) {
    RecyclerView.Adapter adapter = view.getAdapter();
    Bitmap bigBitmap = null;
    if (adapter != null) {
      int size = adapter.getItemCount();
      int height = 0;
      Paint paint = new Paint();
      int iHeight = 0;
      final int maxMemory = (int) (Runtime.getRuntime().maxMemory() / 1024);

      // Use 1/8th of the available memory for this memory cache.
      final int cacheSize = maxMemory / 8;
      LruCache<String, Bitmap> bitmaCache = new LruCache<>(cacheSize);
      for (int i = 0; i < size; i++) {
        RecyclerView.ViewHolder holder = adapter.createViewHolder(view, adapter.getItemViewType(i));
        adapter.onBindViewHolder(holder, i);
        holder.itemView.measure(
            View.MeasureSpec.makeMeasureSpec(view.getWidth(), View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED));
        holder.itemView.layout(0, 0, holder.itemView.getMeasuredWidth(),
            holder.itemView.getMeasuredHeight());
        holder.itemView.setDrawingCacheEnabled(true);
        holder.itemView.buildDrawingCache();
        Bitmap drawingCache = holder.itemView.getDrawingCache();
        if (drawingCache != null) {

          bitmaCache.put(String.valueOf(i), drawingCache);
        }
        height += holder.itemView.getMeasuredHeight();
      }

      bigBitmap = Bitmap.createBitmap(view.getMeasuredWidth(), height, Bitmap.Config.ARGB_8888);
      Canvas bigCanvas = new Canvas(bigBitmap);
      Drawable lBackground = view.getBackground();
      if (lBackground instanceof ColorDrawable) {
        ColorDrawable lColorDrawable = (ColorDrawable) lBackground;
        int lColor = lColorDrawable.getColor();
        bigCanvas.drawColor(lColor);
      }

      for (int i = 0; i < size; i++) {
        Bitmap bitmap = bitmaCache.get(String.valueOf(i));
        bigCanvas.drawBitmap(bitmap, 0f, iHeight, paint);
        iHeight += bitmap.getHeight();
        bitmap.recycle();
      }
    }
    return bigBitmap;
  }

// 截取listView也是差不多，主要是一个makeMeasureSpec View.MeasureSpec.UNSPECIFIED
  public static Bitmap shotListView(ListView listview) {

     ListAdapter adapter = listview.getAdapter();
     int itemscount = adapter.getCount();
     int allitemsheight = 0;
     List<Bitmap> bmps = new ArrayList<Bitmap>();

     for (int i = 0; i < itemscount; i++) {

       View childView = adapter.getView(i, null, listview);
       childView.measure(
           View.MeasureSpec.makeMeasureSpec(listview.getWidth(), View.MeasureSpec.EXACTLY),
           View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED));

       childView.layout(0, 0, childView.getMeasuredWidth(), childView.getMeasuredHeight());
       childView.setDrawingCacheEnabled(true);
       childView.buildDrawingCache();
       bmps.add(childView.getDrawingCache());
       allitemsheight += childView.getMeasuredHeight();
     }

     Bitmap bigbitmap =
         Bitmap.createBitmap(listview.getMeasuredWidth(), allitemsheight, Bitmap.Config.ARGB_8888);
     Canvas bigcanvas = new Canvas(bigbitmap);

     Paint paint = new Paint();
     int iHeight = 0;

     for (int i = 0; i < bmps.size(); i++) {
       Bitmap bmp = bmps.get(i);
       bigcanvas.drawBitmap(bmp, 0, iHeight, paint);
       iHeight += bmp.getHeight();

       bmp.recycle();
       bmp = null;
     }

     return bigbitmap;
   }
```
[都在这里了](http://www.cnblogs.com/onelikeone/p/7091246.html)

### 27.正常使用Android WebView的方法大概这样
```java
mWebView = findViewById(R.id.my_webview)
mWebView.getSettings().setJavaScriptEnabled(true) //这只是enable js
mWebView.setWebViewClient(WebViewClient()) //没有这句LayoutInflater调用newInstance的时候就崩了
mWebView.loadUrl("https://www.baidu.com")
```

对于Android调用JS代码的方法有2种：
[Android：你要的WebView与 JS 交互方式 都在这里了(https://blog.csdn.net/carson_ho/article/details/64904691)
1. 通过WebView的loadUrl（）
2. 通过WebView的evaluateJavascript（） // 4.4以上可用，效率高一点

对于JS调用Android代码的方法有3种：
1. 通过WebView的addJavascriptInterface（）进行对象映射
2. 通过 WebViewClient 的shouldOverrideUrlLoading ()方法回调拦截 url
3. 通过 WebChromeClient 的onJsAlert()、onJsConfirm()、onJsPrompt（）方法回调拦截JS对话框alert()、confirm()、prompt（） 消息

然后是WebView的截屏
```java
private fun screenShot() {
  //这种方式只能截出来当前屏幕上显示的内容，状态栏以下，手机屏幕底部以上的内容，仅此而已
    val screenWidth :Float = Utils.getScreenWidth(this).toFloat()
    val screenHeight = Utils.getScreenHeight(this).toFloat()
    val shortImage = Bitmap.createBitmap(screenWidth.toInt(), screenHeight.toInt(), Bitmap.Config.RGB_565)
    val canvas = Canvas(shortImage)   // 画布的宽高和屏幕的宽高保持一致
    val paint = Paint()
    canvas.drawBitmap(shortImage, screenWidth, screenHeight, paint)
    mWebView.draw(canvas)
    savebitmap("1_awesome",shortImage)
}

// 然而下面这种方式截出来的长度是对了，但底部是空的，得到的是一张很长的，但除了顶部有当前屏幕显示内容以外底部空白的图片
//就是只能截下来可视区域
private fun screenShotLong(){
     mWebView.measure(View.MeasureSpec.makeMeasureSpec(View.MeasureSpec.UNSPECIFIED, View.MeasureSpec.UNSPECIFIED),
             View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED))
     mWebView.layout(0,0,mWebView.measuredWidth,mWebView.measuredHeight)
     mWebView.isDrawingCacheEnabled = true
     mWebView.buildDrawingCache() //图片大的话，这段也卡很长时间
     val longBitmap = Bitmap.createBitmap(mWebView.measuredWidth,mWebView.measuredHeight,Bitmap.Config.ARGB_8888)
     val canvas = Canvas(longBitmap)
     val  paint =  Paint()
     canvas.drawBitmap(longBitmap,0f,mWebView.measuredHeight.toFloat(),paint)
     mWebView.draw(canvas)
     savebitmap("longbitmap",longBitmap)
     ToastUtil.showTextLong(this,"All done!")
 }

//然后找了下，只要在setContentView前，调用这个方法就ok了。但这个方法得在App中所有WebView创建前调用
 if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
       WebView.enableSlowWholeDocumentDraw();
 }
 setContentView(R.layout.activity_webview);
 // 然而看到了这样的日志
// View: WebView not displayed because it is too large to fit into a software layer (or drawing cache), needs 20710080 bytes, only 8294400 available
//保存下来的png大小正好普遍在MB量级，另外，保存图片期间完全卡顿（把createBitmap和saveBitmap这段挪到子线程好点了，cpu占用25%以上持续10s，内存占用从32MB飙到400MB，一直不下来了）
```
还有,js调java的时候，走的是java的一个叫做JavaBridge的线程，操作UI的话post就好了。

### 28. 分析一点ViewPager的源码

首先是快速滑动的时候为了性能只是挪了bitmap，这比调用layout要快得多。
ViewPager.java
```java
private void setScrollingCacheEnabled(boolean enabled) {
       if (mScrollingCacheEnabled != enabled) {
           mScrollingCacheEnabled = enabled;
           if (USE_CACHE) { //这个一直是false
               final int size = getChildCount();
               for (int i = 0; i < size; ++i) {
                   final View child = getChildAt(i);
                   if (child.getVisibility() != GONE) {
                       child.setDrawingCacheEnabled(enabled);
                   }
               }
           }
       }
   }

// 这里要说的是，PagerAdapter中可以复写的方法很多，比如一些状态的保存就可以写在adapter中
   @Override
     public Parcelable onSaveInstanceState() {
         Parcelable superState = super.onSaveInstanceState();
         SavedState ss = new SavedState(superState);
         ss.position = mCurItem;
         if (mAdapter != null) {
             ss.adapterState = mAdapter.saveState();
         }
         return ss;
     }   
```
ViewPager的 onMeasure中有这么一段话,这也就解释了为什么viewPager宽高不能设置为wrap_content。[](https://stackoverflow.com/questions/8394681/android-i-am-unable-to-have-viewpager-wrap-content)
```java
 @Override
   protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
       // For simple implementation, our internal size is always 0.
       // We depend on the container to specify the layout size of
       // our view.  We can't really know what it is since we will be
       // adding and removing different arbitrary views and do not
       // want the layout to change as this happens.
       setMeasuredDimension(getDefaultSize(0, widthMeasureSpec),
               getDefaultSize(0, heightMeasureSpec));
                // ................................

             }     
```
ViewPager横向挪动child的方法是
ViewPager.java
```java

@Override
   public boolean onInterceptTouchEvent(MotionEvent ev) {
       /*
        * This method JUST determines whether we want to intercept the motion.
        * If we return true, onMotionEvent will be called and we do the actual
        * scrolling there.
      */
      // 这里只是做一个拦截，真正去挪动child的方法在onTouchEvent里面
    }

// Not else! Note that mIsBeingDragged can be set above.
 if (mIsBeingDragged) {
     // Scroll to follow the motion event
     final int activePointerIndex = ev.findPointerIndex(mActivePointerId);
     final float x = ev.getX(activePointerIndex);
     needsInvalidate |= performDrag(x);
 }

 private boolean performDrag(float x) {
       boolean needsInvalidate = false;
       scrollTo((int) scrollX, getScrollY()); //其实是ViewPager自己在滑动
       pageScrolled((int) scrollX);  //pageScrollView中并未涉及child的挪动

       return needsInvalidate;
   }

// 因为在onLayout中是这么写的，所以后面的child其实已经被layout到屏幕右边排队了，手指往左滑动的时候带着ViewPager，相当于直接把右边的children拽出来了。
child.layout(childLeft, childTop,
                         childLeft + child.getMeasuredWidth(),
                         childTop + child.getMeasuredHeight());   



// offsetLeftAndRight底层的实现是修改displayList的数据，native方法
mLeft += offset;
mRight += offset;
mRenderNode.offsetLeftAndRight(offset);
```


在smoothScrollTo中这个方法被调用，传了一个true。其实类似的[scrollCache](https://stackoverflow.com/questions/15570041/scrollingcache)的讨论还很多。原理就是调用所有child的setDrawingCacheEnabled方法（不过目前看来这个因为USE_CACHE一直是false所以没用）
看ViewPager的时候又想到一件事，最早的时候以为这种跟adapter打交道的View不应该用setData，应该用addData，并天真的以为内部实现就是直接从外部的list中取数据。
在ViewPager源码中，有一个mItems的ArrayList,这么看来实际上外部的数据也只是被拿来填充到内部的一个新的List中。
```java
ItemInfo addNewItem(int position, int index) {
      ItemInfo ii = new ItemInfo();
      ii.position = position;
      ii.object = mAdapter.instantiateItem(this, position);
      ii.widthFactor = mAdapter.getPageWidth(position);
      if (index < 0 || index >= mItems.size()) {
          mItems.add(ii);
      } else {
          mItems.add(index, ii);
      }
      return ii;
  }


// notifyDataSetChange的不过是调用了这个方法
  void dataSetChanged() {
         // This method only gets called if our observer is attached, so mAdapter is non-null.

         final int adapterCount = mAdapter.getCount();
         mExpectedAdapterCount = adapterCount;
         boolean needPopulate = mItems.size() < mOffscreenPageLimit * 2 + 1
                 && mItems.size() < adapterCount; // mOffscreenPageLimit默认是1
        // 比如原来的数量只有2，或者添加了新的数据，都需要重走一遍layout

         boolean isUpdating = false;
         for (int i = 0; i < mItems.size(); i++) {
             if (ii.position != newPos) {
                 needPopulate = true; //多数不会走到这里
             }
         }
         if (needPopulate) {
             requestLayout();
         }
     }
```

最后是关于ViewPager的预加载问题
```java
 void populate(int newCurrentItem) {
      if (curItem == null && N > 0) {
           curItem = addNewItem(mCurItem, curIndex); //首先是加载当前的item
       }

       // Fill 3x the available width or up to the number of offscreen
          // pages requested to either side, whichever is larger.
          // If we have no current item we have no work to do.
          // 左右两侧都放至少offscreenLimit*screenwidth的宽度，所以左右至少都加载一个
          //实际加载的方法是在addNewItem里面，

          // Fill 3x the available width or up to the number of offscreen
          // pages requested to either side, whichever is larger.
          // If we have no current item we have no work to do.

      if (curItem != null) {
          float extraWidthLeft = 0.f;
          if(....){
            addNewItem()
          }
          // .... 先填充左边

          float extraWidthRight = curItem.widthFactor;
          // ...然后是右边
          if(....){
            addNewItem()
          }
          calculatePageOffsets(curItem, curIndex, oldCurInfo);
      }
 }
```

viewPager的layoutParams是不认margin的，所以加左右margin得这样
>viewPager.pageMargin =  gap
viewPager.clipToPadding = false
viewPager.setPadding(gap,0,gap,0)

还有PagerAdapter的getItemPosition这个方法，返回值限于POSITION_UNCHANGED，POSITION_NONE或者object的newPosition(很多时候都忘记写)
[fragment-state-pager-adapter](https://billynyh.github.io/blog/2014/03/02/fragment-state-pager-adapter/)
[ViewPager 与 PagerAdapter 刷新那点事](https://www.zybuluo.com/zhuhf/note/783633)


在AbsListView中，setScrollingCacheEnabled这个方法也存在，同样是调用的child的drawingCacheEnabled
[Romain Guy的博客提到了ListView默认开启，但他忘记了GridView默认开启](http://www.curious-creature.com/2008/12/22/why-is-my-list-black-an-android-optimization/)

### 29.关于65536问题
[Too many classes in --main-dex-list, main dex capacity exceeded | 主Dex引用太多怎么办？](http://www.jackywang.tech/2017/06/14/Too-many-classes-in-main-dex-list-main-dex-capacity-exceeded-%E4%B8%BBDex%E5%BC%95%E7%94%A8%E5%A4%AA%E5%A4%9A%E6%80%8E%E4%B9%88%E5%8A%9E%EF%BC%9F/)
MultiDex对于minSdk> =21 不会生效，如果最低版本是21上面所有的任务都不会执行，也不会有主Dex列表的计算。这是因为在应用安装期间所有的dex文件都会被ART转换为一个.oat文件。所以minSdk高的也不用开multiDex了。
在使用ART虚拟机的设备上(部分4.4设备，5.0+以上都默认ART环境)，已经[原生支持](https://developer.android.com/studio/build/multidex.html)多Dex，因此就不需要手动支持了
>Android 5.0 (API level 21) and higher uses a runtime called ART which natively supports loading multiple DEX files from APK files. ART performs pre-compilation at app install time which scans for classesN.dex files and compiles them into a single .oat file for execution by the Android device. Therefore, if your minSdkVersion is 21 or higher, you do not need the multidex support library.

看下MultiDex的源码，secondaryDex文件的路径是/date/date/<package_name>/code_cache/secondary-dexes/ 这是一个文件夹
MultiDex的原理基本上在[简书](https://www.jianshu.com/p/33f22b21ef1e)
```java
private static final class V14
    {
        private static void install(final ClassLoader loader, final List<File> additionalClassPathEntries, final File optimizedDirectory) throws IllegalArgumentException, IllegalAccessException, NoSuchFieldException, InvocationTargetException, NoSuchMethodException {
            //通过反射获取loader的pathList字段，loader是由Application.getClassLoader()获取的，实际获取到的是PathClassLoader对象的pathList字段
            final Field pathListField = findField(loader, "pathList");
            final Object dexPathList = pathListField.get(loader);
            //dexPathList是PathClassLoader的私有字段，里面保存的是Main Dex中的class
            //dexElements是一个数组，里面的每一个item就是一个Dex文件
            //makeDexElements()返回的是其他Dex文件中获取到的Elements[]对象，内部通过反射makeDexElements()获取
            //expandFieldArray是为了把makeDexElements()返回的Elements[]对象添加到dexPathList字段的成员变量dexElements中
            expandFieldArray(dexPathList, "dexElements", makeDexElements(dexPathList, new ArrayList<File>(additionalClassPathEntries), optimizedDirectory));
        }

        private static Object[] makeDexElements(final Object dexPathList, final ArrayList<File> files, final File optimizedDirectory) throws IllegalAccessException, InvocationTargetException, NoSuchMethodException {
            final Method makeDexElements = findMethod(dexPathList, "makeDexElements", (Class<?>[])new Class[] { ArrayList.class, File.class });
            return (Object[])makeDexElements.invoke(dexPathList, files, optimizedDirectory);
        }
    }
```
这里面注意makeDexElements方法，是通过反射调用了Dalvik的DexPathList class的这个方法[makeDexElements](https://android.googlesource.com/platform/libcore-snapshot/+/ics-mr1/dalvik/src/main/java/dalvik/system/DexPathList.java)。说白了，整个过程就是在/data/data/(packagename)/code_cache/这个目录下面复制粘贴文件(class.dex文件也是文件)，复制粘贴文件带来的影响就是classLoader(Android上是BaseDexClassLoader)在findClass的时候调用的是DexPathList的findClass方法:
```java
public Class findClass(String name) {
      for (Element element : dexElements) {
          DexFile dex = element.dexFile;
          if (dex != null) {
              Class clazz = dex.loadClassBinaryName(name, definingContext);
              if (clazz != null) {
                  return clazz;
              }
          }
      }
      return null;
  }
```
当然，Tinker也是采用的极其相似的方法，完成了dex替换(谁在这个数组前面谁就先得到加载)
[凯子哥提到由于在App冷启动的时候由于反射外加io操作，可能会比较卡甚至ANR](https://www.jianshu.com/p/33f22b21ef1e),把这部分操作弄到子线程也是行的，一种可能的方案是从Instrumentation下手。

### 30 . 从已安装的app中提取apk
[鸿洋的博客中提到过如何使用bsdiff比较旧的apk和新的apk的差异](http://blog.csdn.net/lmj623565791/article/details/52761658)
```java
context = context.getApplicationContext();
ApplicationInfo applicationInfo = context.getApplicationInfo();
String apkPath = applicationInfo.sourceDir;
return apkPath;
```
在Android Studio 3.0后，直接在Device Explorer中查看data/app/com.example.appname，发现里面有个base.apk文件。几乎就是把原有的apk文件复制了一份。


### 31. 老版本的WebView是存在内存泄露的
[参考](https://www.jianshu.com/p/eada9b652d99)
大致上就是主动调用了WebView.destory方法，原本在onDetachedFromWindow中系统的一些资源释放就没有走到，
作者给出了这样的解决方案
```java
ViewParent parent = mWebView.getParent();
    if (parent != null) {
        ((ViewGroup) parent).removeView(mWebView);// 这里面会调用到 view.dispatchDetachedFromWindow();
    }
    mWebView.destroy();    
```
[webView的sourceCode](https://android.googlesource.com/platform/external/chromium_org/+/lollipop-release/android_webview/java/src/org/chromium/android_webview/AwContents.java)

### 32. App升级或者安装之前是要做一些检查的
[这篇文章详尽描述了需要做的一些方案](http://blog.csdn.net/sk719887916/article/details/52233112)
可能被劫持的地方有三处： 升级api(就是返回下载链接的接口)，下载api(就是那个cdn), 安装过程(调用packageManager之前)

- 升级接口必须https，避免返回恶意地址
- 检查file的md5和服务器response中的md5是否一致
- 还要对下载的文件进行包名和签名验证，防止Apk被恶意植入木马

```java
// 升级接口返回下载地址之后
UpgradeModel  aResult = xxxx;//解析服务器返回的后数据

if (aResult != null && aResult.getData() != null ) {
      String url = aResult.getData().getDownUrl();
      if (url == null || !TextUtils.equals(url, "the_domain_that_i_own")) {
        // 如果不是自己掌握的域名，不下载
      }
}

// 判断下载下来的文件的md5和升级接口描述的md5是否一致
File file = DownUtils.getFile(url);
        // 监测是否要重新下载
 if (file.exists() &&   TextUtils.equals(aResult.getData().getHashCode(), EncryptUtils.Md5File(file))) {
  && TextUtils.equals(aResult.getData().getKey(), DownLoadModel.getData()..getKey())
  // 如果符合，就去安装 不符合重新下载 删除恶意文件
}


// 下面这些代码来自上述文章
public static void installApK(Context context, final String path, final String name ) {

    if (!SafetyUtils.checkFile(path + name, context)) {
        return;
    }

    if (!SafetyUtils.checkPagakgeName(context, path + name)) {
        Toast.makeText(context, "升级包被恶意软件篡改 请重新升级下载安装", Toast.LENGTH_SHORT ).show();
        DLUtils.deleteFile(path + name);
        ((Activity)context).finish();
        return;
    }

    switch (SafetyUtils.checkPagakgeSign(context, path + name)) {

        case SafetyUtils.SUCCESS:
            DLUtils.openFile(path + name, context);
            break;

        case SafetyUtils.SIGNATURES_INVALIDATE:

            Toast.makeText(context, "升级包安全校验失败 请重新升级", Toast.LENGTH_SHORT ).show();
            ((Activity)context).finish();

            break;

        case SafetyUtils.VERIFY_SIGNATURES_FAIL:

            Toast.makeText(context, "升级包为盗版应用 请重新升级", Toast.LENGTH_SHORT ).show();
            ((Activity)context).finish();
            break;

        default:
            break;
    }

}


/**
* 安全校验
* Created by LIUYONGKUI on 2016-04-21.
*/
public class SafetyUtils {

    /** install sucess */
    protected static final int SUCCESS = 0;
    /** SIGNATURES_INVALIDATE */
    protected static final int SIGNATURES_INVALIDATE = 3;
    /** SIGNATURES_NOT_SAME */
    protected static final int VERIFY_SIGNATURES_FAIL = 4;
    /** is needcheck */
    private static final boolean NEED_VERIFY_CERT = true;

/**
 * checkPagakgeSigns.
 */
public static int checkPagakgeSign(Context context, String srcPluginFile) {

    PackageInfo PackageInfo = context.getPackageManager().getPackageArchiveInfo(srcPluginFile, 0);
    //Signature[] pluginSignatures = PackageInfo.signatures;
    Signature[] pluginSignatures = PackageParser.collectCertificates(srcPluginFile, false);
    boolean isDebugable = (0 != (context.getApplicationInfo().flags & ApplicationInfo.FLAG_DEBUGGABLE));
    if (pluginSignatures == null) {
        PaLog.e("签名验证失败", srcPluginFile);
        new File(srcPluginFile).delete();
        return SIGNATURES_INVALIDATE;
    } else if (NEED_VERIFY_CERT && !isDebugable) {
        //可选步骤，验证APK证书是否和现在程序证书相同。
        Signature[] mainSignatures = null;
        try {
            PackageInfo pkgInfo = context.getPackageManager().getPackageInfo(
                    context.getPackageName(), PackageManager.GET_SIGNATURES);
            mainSignatures = pkgInfo.signatures;
        } catch (PackageManager.NameNotFoundException e) {
            e.printStackTrace();
        }
        if (!PackageParser.isSignaturesSame(mainSignatures, pluginSignatures)) {
            PaLog.e("升级包证书和旧版本证书不一致", srcPluginFile);
            new File(srcPluginFile).delete();
            return VERIFY_SIGNATURES_FAIL;
        }
    }
    return SUCCESS;
}

/**
 * checkPagakgeName
 * @param context
 * @param srcNewFile
 * @return
 */
public static boolean checkPagakgeName (Context context, String srcNewFile) {
    PackageInfo packageInfo = context.getPackageManager().getPackageArchiveInfo(srcNewFile, PackageManager.GET_ACTIVITIES);

    if (packageInfo != null) {

       return TextUtils.equals(context.getPackageName(), packageInfo.packageName);
    }

    return false;
}

/**
 * checkFile
 *
 * @param aPath
 *            文件路径
 * @param context
 *            context
 */
public static boolean checkFile(String aPath, Context context) {
    File aFile = new File(aPath);
    if (aFile == null || !aFile.exists()) {
        Toast.makeText(context, "安装包已被恶意软件删除", Toast.LENGTH_SHORT).show();
        return false;
    }
    if  (context == null)  {
         Toast.makeText(context, "安装包异常", Toast.LENGTH_SHORT).show();
        return false;
     }

     return true;
 }
}
```

## 33. TextView原生支持一些比较好玩的属性
[Advanced Android TextView](https://www.youtube.com/watch?v=q2GtM1_RmMw)
比方说
```java
Bitmap bitmap = BitmapFactory.
            decodeResource(getResource(),R.drawable_cheetah_title);
Shader shader = new BitmapShader(
  bitmap,
  Shader.TileMode.REPEAT,
  Shader.TileMode.REPEAT);
textView.getPaint().setShader(shader);
)            
```
TextView渲染html文档的时候可以自定义一个tagHandler
显示数学上的带有分子和分母的分数，可以使用<afrc>标签
TextView里面有一个Layout.Alignment的属性，然后创建一个AlignMentSpan，可以用来实现类似于聊天的文字左对齐，右对齐，只用一个TextView

## 34. ContentProvider的一些点
可以自定义权限，在manifest里面写
URI有固定格式：

分析URI：content://com.ljq.provider.personprovider/person/10/name，其中content://是Scheme，com.ljq.provider.personprovider表示主机名或者authorities，person/10/name表示路径，此URI要操作person表中id为10的name字段。

自定义权限
```xml
<permission android:name="me.pengtao.READ" android:protectionLevel="normal"/>

<provider
    android:authorities="me.pengtao.contentprovidertest"
    android:name=".provider.TestProvider"
    android:readPermission="me.pengtao.READ"
    android:exported="true">
</provider>

<!-- 在第三方app中就可以声明： -->
<uses-permission android:name="me.pengtao.READ"/>
```
另外说一句，ContentProvider是在App启动的时候就创建的，比Application的onCreate还要早

## 35. android:multiprocess="true"
Activity可以在Manifest中声明这个属性，provider也可以声明这个属性。这个意思就是说，这个activity或者provider在A进程被拉起，那就创建一个A进程的Activity实例。在B进程被拉起，就创建一个B进程的Activity实例。在那个进程被打开就创建一个跑在哪个进程的实例
>If the app runs in multiple processes, this attribute determines whether multiple instances of the content provder are created. If true, each of the app's processes has its own content provider object. If false, the app's processes share only one content provider object. The default value is false.
Setting this flag to true may improve performance by reducing the overhead of interprocess communication, but it also increases the memory footprint of each process.

## 36. 两个App之间共享数据
 两个应用的ShareUserId相同，则共享对方的data目录下的文件，包括SharePreference, file, lib等文件。例如，在ShareUserId相同的情况下，读取另一个应用的SharePreference文件。

 ```xml
 //第一个应用程序为的menifest文件代码如下：  
<manifest xmlns:android="http://schemas.android.com/apk/res/android"  
package="com.mythou.serviceID"  
android:sharedUserId="com.mythou.share"  
>  
//第二个应用程序的menifest文件代码如下：  
<manifest xmlns:android="http://schemas.android.com/apk/res/android"  
package="com.mythou.clientID"  
android:sharedUserId="com.mythou.share"  
>  
```
读取的时候这么读
```java
try {  
     Context ct=this.createPackageContext ("com.mythou.serviceID", Context.CONTEXT_IGNORE_SECURITY);  
     SharedPreferences sp = ct.getSharedPreferences("appInfo", MODE_PRIVATE);  
     String str2 = sp.getString("appname", "service");  
     Log.d("test", "share preference-->" + str2);  
} catch (NameNotFoundException e) {  
     // TODO Auto-generated catch block  
     e.printStackTrace();  
}   
```

## 37. ActivityAlias就跟Alias一样
```xml
<activity android:name="com.mytest.StartupActivity"  
    android:exported="true">  
</activity>  

<!-- Solution for upgrading issue -->  
<activity-alias android:name="com.mytest.HomeActivity"  
    android:targetActivity="com.mytest.StartupActivity"  
    android:exported="true"  
    android:enabled="true">  
    <intent-filter>  
        <action android:name="android.intent.action.MAIN" />  
        <category android:name="android.intent.category.LAUNCHER" />  
    </intent-filter>  
</activity-alias>  
```

## 38. 自定义一个scheme也很简单
比如说App打电话就是:
```java
//电话号码  
String phoneNum = phoneNumEdit.getText().toString().trim();  
//打电话  
Intent callIntent = new Intent(Intent.ACTION_CALL);  
callIntent.setData(Uri.parse("tel:"+phoneNum));  
startActivity(callIntent);  


Intent takePhotoIntent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);  
startActivityForResult(takePhotoIntent, REQUEST_TAKE_PHOTO);  

// 系统相机进程的数据还能通过onActivityResult返回，跨进程了
@Override  
protected void onActivityResult(int requestCode, int resultCode, Intent data) {  

    //如果去拍照请求返回  
    if (requestCode == REQUEST_TAKE_PHOTO) {  

        //如果结果返回成功  
        if (resultCode == RESULT_OK) {  

            Bitmap bmp = (Bitmap) data.getExtras().get("data");  
            takeResultImg.setImageBitmap(bmp);  
        }  
    }  
    super.onActivityResult(requestCode, resultCode, data);  
}  
```

```xml
<activity android:name="com.sarnasea.interprocess.ShareActivity">  
    <intent-filter>  
        <action android:name="com.sarnasea.interprocess.MYACTION"/>  
        <data android:scheme="message"/>  
        <category android:name="android.intent.category.DEFAULT"/>  
    </intent-filter>  
</activity>  
```


```java
//  在ShareActivity获得其他应用程序传递过来的数据  （完全可以多进程）
Uri data = getIntent().getData();  
if (data != null) {  

    //获得Host,也就是message://后面的主体内容  
    String host = data.getHost();  
    Toast.makeText(this, host, Toast.LENGTH_SHORT).show();  
}  

Bundle bundle = getIntent().getExtras();  
if(bundle != null){  

    //获得其他应用程序调用该Activity时传递过来的Extras数据  
    String value = bundle.getString("value");  
    Toast.makeText(this, value, Toast.LENGTH_SHORT).show();  
}



// 外部启动这个Activity的方法
Intent intent = new Intent();  
intent.setAction("com.sarnasea.interprocess.MYACTION");   
intent.setData(Uri.parse("message://Hello World!"));  
intent.putExtra("value", "yanglu");  
startActivity(intent);  


//这个Activty还可以从另一个进程返回数据
Intent data = new Intent();  
// 设置要返回的数据  
data.putExtra("result", "关闭Activity时返回的数据");  
// 设置返回码和Intent对象  
setResult(Activity.RESULT_OK, data);  
// 关闭Activity  
finish();    
```

## 39. Intent的底层实现是共享内存
两个Activity之间Intent传递数据的时候，Intent中的数据已经经历了两轮序列化和反序列化，当然是不同的对象
熟悉AIDL的同学都很清楚，AIDL跨进程通信支持的数据类型是：

>Java 的原生类型，如int,boolean,long,float…
String 和CharSequence
List 和 Map ,List和Map 对象的元素必须是AIDL支持的数据类型
AIDL 自动生成的接口 需要导入(import)
实现android.os.Parcelable 接口的类. 需要导入(import)。
这里并不包括Serializable类型。
于是去看了源码，发现是Parcel自己对Serializable类型的对象做了兼容，可以直接写入其中。
public class Intent implements Parcelable, Cloneable

[Intent传递数据底层分析](https://blog.csdn.net/javine/article/details/56836454)

Parcelable是Android为我们提供的序列化的接口,Parcelable相对于Serializable的使用相对复杂一些,但Parcelable的效率相对Serializable也高很多,这一直是Google工程师引以为傲的,有时间的可以看一下Parcelable和Serializable的效率对比 Parcelable vs Serializable 号称快10倍的效率

Parcelable的底层使用了 **Parcel** 机制， Parcel机制会将序列化的数据写入到一个共享内存中，其他进程通过Parcel从共享内存中读出字节流，然后反序列化后使用。这就是Intent或Bundle能够在activity或者在binder中跨进程通信的原理。

## 40. BlockCanary的原理就是在每一个Message执行前计时，结束后停止计时，看下时间有没有超过阈值。
[BlockCanary](https://github.com/markzhai/AndroidPerformanceMonitor)值得一提的是，这里面考虑到了系统给当前进程分配的CPU时间段
具体就是
> cat /proc/pid/stat ## 如果系统分配的cpu时间不够，那么卡顿也是难免的



=============================================================================

有些地方会对Apk进行二次打包，加固就是防着这个的。

![](https://www.haldir66.ga/static/imgs/scenery1511100809920.jpg)


### 9. Facebook出品的BUCK能够用于编译Android 项目，速度比较快。

[一个具有网络传输的FileExplorer](https://github.com/1hakr/AnExplorer)
[MultiDex原理](http://mouxuejie.com/blog/2016-06-11/multidex-source-analysis/)
[偏向native层面的内存占用分析](http://wetest.qq.com/lab/view/359.html)
[Android进程框架：进程的启动创建、启动与调度流程](https://juejin.im/post/5a646211f265da3e3f4cc997)
[Android进程框架：进程的启动创建、启动与调度流程](https://juejin.im/post/59fafa3351882529642107d2)
