---
title: 集成Tinker的一些记录
date: 2017-11-18 17:25:29
tags: [android,热修复]
---

关于Android Application集成Tinker的一次记录。
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/single-yellow-beauty-flower-on-the-fence-wallpaper-56801fde208df.jpg?imageView2/2/w/600)
<!--more-->

## 1. 首先从官方Demo项目开始
[Tinker](https://github.com/Tencent/tinker)是2016年开源的，先直接clone下来。
我的环境：
> Android Studio 3.0 稳定版
gradle版本：distributionUrl=https\://services.gradle.org/distributions/gradle-4.1-all.zip
gradle插件版本:  classpath 'com.android.tools.build:gradle:3.0.0'
TINKER_VERSION=1.9.1
compileSdkVersion 26
buildToolsVersion '26.0.2'

Android Studio 3.0 因为刚出来，所以遇到了一些问题，不过好在Google一下或者在issue里面查一下，都能找到合适的解答

[官方Demo](https://github.com/Tencent/tinker/tree/master/tinker-sample-android)
先把官方Demo按照普通App的流程安装上来。
这时候在app/build/bakApk/目录下就会出现“app-debug-1118-15-50-07.apk”这样的文件，其实是复制了一份当前的apk

然后，在MainActivity代码中，把原本注释掉的一行Log取消注释，运行如下命令
> gradlew tinkerPatchDebug
或者在Andriod Studio的Gradle tab里面找到这个task，运行一下

打releasePatch其实也差不多
> gradlew tinkerRelease

一切顺利的话，在
app/build/outputs/apk/tinkerPatch/debug文件夹下就会看到一些新生成的文件，例如
“app/build/outputs/apk/tinkerPatch/debug/patch_signed.apk”，
“app/build/outputs/apk/tinkerPatch/debug/patch_signed_7zip.apk”
等等，具体每个文件是干嘛的文档上都说了。
这时候通过adb push命令把这个7zip文件上传到手机根目录下
> adb push ./app/build/outputs/tinkerPatch/debug/patch_signed_7zip.apk /storage/sdcard0/patch_signed_7zip.apk
或者在Android Studio 3.0右下角有一个Device File Explorer,把这个文件上传到手机里

上面那个路径不一定准，总之需要和这里面的路径一样，所以我在模拟器里面是sdcard/emulated/0这个目录下
```java
TinkerInstaller.onReceiveUpgradePatch(getApplicationContext(), Environment.getExternalStorageDirectory().getAbsolutePath() + "/patch_signed_7zip.apk");
```

上传完毕之后，在当前页面点击Button，点击事件调用到上面这一行代码.
一切Ok的话（运气好的话），会出现Toast,其实这个Toast是在SampleResultService（一个IntentService）里面写的，也就是说Patch打上的话，开发者可以自定义一些UI事件。

这时候再Kill Porcess,据说锁屏也行？
重新启动后，刚才取消注释的那一行代码就在logcat里面出现了。

到此，在没有重新打包的情况下，热修复完成。


## 2. 已有的项目改造
照着改成这样
在Gradle.properties里面添加
> TINKER_VERSION = 1.9.1 //只是为了集中管理
> TINKER_ID = 1.0 //这个不添加会报错


project的build.gradle中添加
>  classpath "com.tencent.tinker:tinker-patch-gradle-plugin:${TINKER_VERSION}"

app的build.gradle中需要新增很多东西，建议直接[复制](https://github.com/Tencent/tinker/blob/master/tinker-sample-android/app/build.gradle)过来。
需要改的地方就是
```
ext {
    tinkerOldApkPath = "${bakPath}/app-debug-1118-15-50-07.apk"
    // 找到当前app/build/bakApk/目录下的apk文件，把名字改成自己和当前的文件一样的
}

ignoreWarning = true //默认是false，不改经常编译报错

implementation("com.tencent.tinker:tinker-android-lib:${TINKER_VERSION}") { changing = true }
provided("com.tencent.tinker:tinker-android-anno:${TINKER_VERSION}")
annotationProcessor("com.tencent.tinker:tinker-android-anno:${TINKER_VERSION}")
```

接下来是Application，如果自己继承了android.app.Application的话，得改一下
```java
//原来
public MyApplication extends Application{

}

//现在
@SuppressWarnings("unused")
@DefaultLifeCycle(application = "com.包名.SomeName",
        flags = ShareConstants.TINKER_ENABLE_ALL,
        loadVerifyFlag = false)
public class AppLike extends DefaultApplicationLike {
     static Context context;

    public AppLike(Application application, int tinkerFlags, boolean tinkerLoadVerifyFlag,
                   long applicationStartElapsedTime, long applicationStartMillisTime, Intent tinkerResultIntent) {
        super(application, tinkerFlags, tinkerLoadVerifyFlag, applicationStartElapsedTime, applicationStartMillisTime, tinkerResultIntent);
    }

    /**
     * install multiDex before install tinker
     * so we don't need to put the tinker lib classes in the main dex
     *
     * @param base
     */
    @TargetApi(Build.VERSION_CODES.ICE_CREAM_SANDWICH)
    @Override
    public void onBaseContextAttached(Context base) {
        super.onBaseContextAttached(base);
        //you must install multiDex whatever tinker is installed!
        MultiDex.install(base);
        AppLike.context = getApplication();
        //初始化Tinker
        TinkerInstaller.install(this);

    }

    @TargetApi(Build.VERSION_CODES.ICE_CREAM_SANDWICH)
    public void registerActivityLifecycleCallbacks(Application.ActivityLifecycleCallbacks callback) {
        getApplication().registerActivityLifecycleCallbacks(callback);
    }
    public static Context getContext() {
        return context;
    }
}

Mainfest里面要改成上面那个“com.包名.SomeName”
```
接下来按照之前的步骤就Ok了。

## 3. Configuration
以上只是简单的把Demo跑通，接下里需要看下Tinker提供的定制项

=======================================================================


## 4. 常见问题
Q: 我只不过改了一个Toast的文案，为毛生成的patch_signed_7zip.apk文件这么大()？
A: 看下tinkerPatch文件夹下面的log.txt文件（建议用Notepad打开），里面一大堆“Found add resource: res/drawable-hdpi-v4/abc_list_pressed_holo_light.9.png”这样的类似的出现，具体原因跟aapt有关，好像可以设置detect resource change （大概就这意思）为false，这样就不会那么大了。

Q: Tinker-Patch把补丁文件放在什么位置
A: 因为接收补丁的代码就在TinkerInstaller.onReceiveUpgradePatch这一段了。在UpgradePatchRetry.java中，有这么一段：tempPatchFile = new File(SharePatchFileUtil.getPatchTempDirectory(context), TEMP_PATCH_NAME); （/data/data/com.example.myApp/data/tinker_temp/temp.apk）。当然还有其他的，总之就是放在当前应用data文件夹下面的tinker或者tinker_temp文件夹下。

Q: TinkerPatch和Tinker什么关系
A：TinkerPatch的SDK里面包含了Tinker必要的功能，开发者只需要添加TinkerPatch这一条依赖，也不需要去继承ApplicationLike这些东西了，开发者不用自己开一个下载服务去下发patch_signed_7zip.apk这个文件了，onReceiveUpgradePatch这些事也做好了。确实是接入成本最低的方案，搭建后台假如交由自己公司的API团队处理，起码得好几天，还得耽误产品正常的开发节奏。而TinkerPatch给出的报价是399元/月。短期来看，显然前者的成本要高出不少，还得顾虑自家团队维护的代价。算一笔经济账的话，显然企业倾向于花钱买稳定服务。对于个人来讲，目前有免费版可以使用，估计也是为了给测试Demo使用的，想玩简单版的话可以试试。

Q: 如何更换Dex的
A: 引用[Android热补丁之Tinker原理解析](http://w4lle.com/2016/12/16/tinker/index.html)中的话：“由于Tinker的方案是基于Multidex实现的修改dexElements的顺序实现的，所以最终还是要修改classLoder中dexPathList中dexElements的顺序。Android中有两种ClassLoader用于加载dex文件，BootClassLoader、PathClassLoader和DexClassLoader都是继承自BaseDexClassLoader。最终在DexPathList的findClass中遍历dexElements，谁在前面用谁。”。所以其实就是根据下发的补丁文件，把dex文件给修改了，这一点跟MultiDex很像。

Q: Dex文件格式
A： [The Dex File Format](https://blog.bugsnag.com/dex-and-d8/)。值得一提的是，这篇文章提到了文件头，dex的头是
>6465780A 30333800
dex
038

这个是hexoDecimal，十六进制2个数字（字母）代表一个byte(2*8bits = 2 bytes)，按照二进制0101的方式来看的话就是： 6465（0110 0100 0110 0101） 780A(0111 1000 0000 1010)。
[关于dex format的更多的分析](http://blog.csdn.net/sbsujjbcy/article/details/52869361)

Q: broken.apk + patch_signed_7zip = fixed apk的过程
A: 在UpgradePatch.tryPath -> DexDiffPatchInternal.tryRecoverDexFiles -> dexOptimizeDexFiles -> TinkerDexOptimizer.optimizeAll ->OptimizeWorker.run -> DexFile.loadDex(DexFile是dalvik.system包下的)。

Q： 把Tinker导入Intelij中
A： Intelij中open project -> 选择 tinker-build/tinker-build.iml 即可。顺带着其他的mudule都能查看了。最好在tinker-sample-android/app/build.gradle文件中注释掉这两句话
> // annotationProcessor("com.tencent.tinker:tinker-android-anno:${TINKER_VERSION}") { changing = true }
//  compileOnly("com.tencent.tinker:tinker-android-anno:${TINKER_VERSION}") { changing = true }

Q: 关于BSDiff
A：windows下可以直接下载对应的exe ,cmd中执行
> bsdiff old.apk new.apk old-to-new.patch
bspatch old.apk new2.apk old-to-new.patch

Q: patch进程是如何和业务进程交互的
A： tinker-android/tinker-android-lib/src/main/AndroidManifest.xml中明确指明了打补丁是在一个youpackagename:patch的进程中去操作的。这样做也是为了减少对于主业务的影响。跨进程交互并没有写aidl，其实只是起了一个IntentService通知主业务进程。



=======================================================================
好的学习资料
[Tinker学习计划(2)-Tinker的原理一](https://www.jianshu.com/p/7034c3fec6c8)
[Android 基于gradle插件实现多渠道打包](https://www.jianshu.com/p/23ea8e332dcd)
[加快apk的构建速度，如何把编译时间从130秒降到17秒](https://www.jianshu.com/p/53923d8f241c)
[fastdex](https://github.com/typ0520/fastdex)
[multiple-apk-generator](https://github.com/typ0520/multiple-apk-generator)

## 5. 源码解析
至少我现在看到7个包：
> com.tencent.tinker:aosp-dexutils:1.91.@jar
> com.tencent.tinker:bsdiff-util:1.91.@jar
> com.tencent.tinker:tinker-android-anno:1.91.@jar
> com.tencent.tinker:tinker-android-lib:1.91.@jar
> com.tencent.tinker:tinker-android-loader:1.91.@jar
> com.tencent.tinker:tinker-commons:1.91.@jar
> com.tencent.tinker:tinker-ziputils:1.91.@jar

分的这么散估计也是希望能够好扩展吧。
=======================================================================

换dex文件的关键方法在[DexPathList.findClass这个方法里面](http://androidxref.com/5.0.0_r2/xref/libcore/dalvik/src/main/java/dalvik/system/DexPathList.java#316)。[参考](https://juejin.im/post/5a42f29ef265da43333eaba0)

网上关于源码解析的文章已经很多，有时间看看，应该不难。

看一下官方Tinker项目中的文件夹，有一个tinker-build，里面有两个python文件，这就很有意思了。再看看tinker-patch-gradle-plugin，里面一大堆groovy文件，所以看懂这个对于gradle插件开发是有好处的。
目前在1.9.1版本里面好像看到了一个*tinkerFastCrashProtect*，看来也是跟风天猫快速修复启动保护那一套。
=======================================================================

关于Tinker-Patch这个外包给第三方的服务，纯属好奇就去看了下url到底长什么样。在[TinkerClientAPI](https://github.com/TinkerPatch/tinkerpatch-sdk/blob/master/tinkerpatch-sdk/src/main/java/com/tencent/tinker/server/client/TinkerClientAPI.java)里面有这么一段，其实跟Tinker本身庞大的架构比起来，已经算不上什么了。
```java
Uri.Builder urlBuilder = Uri.parse(this.host).buildUpon(); // "http://q.tinkerpatch.com"
        if (clientAPI.debug) {
            urlBuilder.appendPath("dev");
        }
        final String url = urlBuilder.appendPath(this.appKey)
            .appendPath(this.appVersion)
            .appendQueryParameter("d", versionUtils.id())
            .appendQueryParameter("v", String.valueOf(System.currentTimeMillis()))
            .build().toString();
```
除此之外，为了能够在测试环境验证补丁，还提供了一个[小工具](https://github.com/TinkerPatch/tinkerpatch-debug-tool)

很感谢鹅厂能够将Tinker这样的工具开源出来造福广大开发者，抛开技术上的实力不说，能够一直积极维护也是一件了不起的事情。

## 参考
1. [微信热修复tinker及tinker-server快速接入](http://jp1017.top/2016/11/25/%E5%BE%AE%E4%BF%A1%E7%83%AD%E4%BF%AE%E5%A4%8Dtinker%E5%8F%8Atinker-server%E5%BF%AB%E9%80%9F%E6%8E%A5%E5%85%A5/)
2. [TinkerPatch](https://github.com/TinkerPatch/tinkerpatch-sdk)，其实就是帮你把下发“patch_signed_7zip.apk”这个文件的活干了，还给了非常直观的报表，收费也是合情合理。
3. [Android热补丁之Tinker原理解析](http://w4lle.com/2016/12/16/tinker/index.html)，这篇文章基本将整个流程都讲清楚了
4. [热更新Tinker研究（三）：加载补丁](http://blog.csdn.net/huweigoodboy/article/details/62428170)
5. [微信Tinker的一切都在这里，包括源码](https://mp.weixin.qq.com/s?__biz=MzAwNDY1ODY2OQ==&mid=2649286384&idx=1&sn=f1aff31d6a567674759be476bcd12549&scene=4#wechat_redirect)
6. [Enabling Android Teams: Dex Ed by Jesse Wilson](https://www.youtube.com/watch?v=v4Ewjq6r9XI)Jesse Wilson谈Dex文件的结构，可惜视频清晰度垃圾
