---
title: 从DroidPlugin谈插件化开发
date: 2017-11-22 22:33:44
tags: [android,插件化]
---

关于360团队出开源的[DroidPlugin](https://github.com/DroidPluginTeam/DroidPlugin)的一些记录
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/scenery15111006999.jpg?imageView2/2/w/600)

过程中发现了关于插件化，Hook系统方法的操作，摘录下来。
<!--more-->
## 1. 从Context的本质说起
其实也简单，就是ContextImpl，一个各种资源的容器。
```java
Activity extends ContextThemeWrapper
ContextThemeWrapper extends ContextWrapper
ContextWrapper extends Context
```
Activity作为一个天然的交互核心，能够以一个容器的身份（继承而来）轻易获取这些外部资源，也使得基于UI页面的开发变得简单。
如果对于ActivityThread有所了解的话，就知道Activity的生命周期都是在这个类中完成的
简单来说在ContextImpl中createActivityContext方法中使用new的方式创建了一个ContextImpl，整个流程就是ActivityThread在创建一个Activity后，给它不断赋值的过程。ContextImpl只是一个各种资源的容器（比如Resource,Display,PackageInfo,构造函数里面塞了一些，创建出来之后还给一些变量赋了值）。


Hook(使用Invokcation handler，将一个接口的调用原本的实现包揽下来，把原来的结果占为己有，同时添加一些自己要做的事情)[修改getSystemService，添加自定义功能](http://weishu.me/2016/02/16/understand-plugin-framework-binder-hook/)
Hook掉AMS,在startActivity里面添加一些私货。
getSystemService最终会追溯到SystemServiceRegistry.java。这里面用static block的方式初始化了各种service的cache.

### 1.1 ActivityThread做了很多事
onSaveInstance是从ActivityThread的callCallActivityOnSaveInstanceState方法dispatch下来的。


## 2. Hook作为插件化的切入点给了开发者篡改系统api实现的通道
[比如Hook掉剪切板SystemService](http://weishu.me/2016/02/16/understand-plugin-framework-binder-hook/),
[比如在ActivityManagerService调用IPC操作时添加私货](http://weishu.me/2016/03/07/understand-plugin-framework-ams-pms-hook/)


![](http://odzl05jxx.bkt.clouddn.com/image/jpg/scenery2a2241cc5c1278cf7a28f15f91dbbb7f.jpg?imageView2/2/w/600)



## 3. Android多渠道打包的实现
### 3.1 历史上曾经有效的方式，原始方法
关于gradlew
打包release之前，先Build -> Generate Singed apk 创建一个新的keystore , 密码记住，keystore文件保存好。
关于打包: 根据[Android 多渠道打包梳理](https://www.jianshu.com/p/4f2990cf53bf)
Gradle UMeng 多渠道打包

-  Android.manifest文件添加
```xml
<meta-data
    android:name="UMENG_CHANNEL"
    android:value="${UMENG_CHANNEL_VALUE}" />
```

-  app的build.gradle中添加
```gradle
android {  
    ...
    productFlavors {
        xiaomi {
            manifestPlaceholders = [UMENG_CHANNEL_VALUE: "xiaomi"]
        }
        _360 {
            manifestPlaceholders = [UMENG_CHANNEL_VALUE: "_360"]
        }
        baidu {
            manifestPlaceholders = [UMENG_CHANNEL_VALUE: "baidu"]
        }
        wandoujia {
            manifestPlaceholders = [UMENG_CHANNEL_VALUE: "wandoujia"]
        }
        ...
    }  
    ...
}

android {  
    productFlavors {
        xiaomi {}
        _360 {}
        baidu {}
        wandoujia {}
    }  

    productFlavors.all {
        flavor -> flavor.manifestPlaceholders = [UMENG_CHANNEL_VALUE: name]
    }
}

```

-  打包
除此之外 assemble 还能和 Product Flavor 结合创建新的任务（assemble + Build Variants），Build Variants = Build Type + Product Flavor
> ./gradlew assembleDebug # 会打包 Debug apk
./gradlew assembleRelease # 打包 Release apk
./gradlew assembleWandoujiaRelease # 打包 wandoujia Release 版本，大小写不敏感
./gradlew assembleWandoujia  # 此命令会生成wandoujia渠道的Release和Debug版本

但是，20个渠道就要编译20次，耗时冗长。

### 3.2 在META-INF目录内添加空文件，可以不用重新签名应用。<del>已失效</del>
比较出名的有python版本的，就是写了个空文件
```python
for line in channels:
    target_channel = line.strip()
    target_apk = output_dir + apk_names[0] + "-" + target_channel+"-"+apk_names[2] + src_apk_extension
    shutil.copy(src_apk,  target_apk)
    zipped = zipfile.ZipFile(target_apk, 'a', zipfile.ZIP_DEFLATED)
    empty_channel_file = "META-INF/uuchannel_{channel}".format(channel = target_channel) //所以渠道号简单来说就是往META-INF里写了一个"uuchannel_xiaomi"之类的文件
    zipped.write(src_empty_file, empty_channel_file)
    zipped.close()
```

**亲测** 关于多渠道打包，由于新的签名机制的引入，上面的这种方法是会报错的。
> $ adb install app-release_channel_xiaomi.apk
Failed to install app-release_channel_xiaomi.apk: Failure [INSTALL_PARSE_FAILED_NO_CERTIFICATES: Failed to collect certificates from /data/app/vmdl185799136.tmp/base.apk: META-INF/CERT.SF indicates /data/app/vmdl185799136.tmp/base.apk is signed using APK Signature Scheme v2, but no such signature was found. Signature stripped?]


[美团的技术团队给出了科普](https://tech.meituan.com/android-apk-v2-signature-scheme.html)，

> 新的签名方案会在ZIP文件格式的 Central Directory 区块所在文件位置的前面添加一个APK Signing Block区块，下面按照ZIP文件的格式来分析新应用签名方案签名后的APK包。
整个APK（ZIP文件格式）会被分为以下四个区块：
Contents of ZIP entries（from offset 0 until the start of APK Signing Block）
APK Signing Block
ZIP Central Directory
ZIP End of Central Directory
新应用签名方案的签名信息会被保存在区块2（APK Signing Block）中， 而区块1（Contents of ZIP entries）、区块3（ZIP Central Directory）、区块4（ZIP End of Central Directory）是受保护的，在签名后任何对区块1、3、4的修改都逃不过新的应用签名方案的检查。



### 3.3 还有就是往apk(zip)文件尾部添加comment
> End of central directory record	 
Offset	Bytes	Description	译
0	4	End of central directory signature = 0x06054b50	核心目录结束标记（0x06054b50）
4	2	Number of this disk	当前磁盘编号
6	2	Disk where central directory starts	核心目录开始位置的磁盘编号
8	2	Number of central directory records on this disk	该磁盘上所记录的核心目录数量
10	2	Total number of central directory records	该磁盘上所记录的核心目录数量
12	4	Size of central directory (bytes)	核心目录的大小
16	4	Offset of start of central directory, relative to start of archive	核心目录开始位置相对于archive开始的位移
20	2	Comment length (n)	注释长度 (n)
22	n	Comment	注释内容

apk 默认情况下没有comment，所以 comment length的short 两个字节为 0，我们需要把这个值修改为我们的comment的长度，然后把comment追加到后边即可。
Android N 中提到了 APK Signature Scheme v2，这种新引入的签名机制，会对整个文件的每个字节都会做校验，包括 comment 区域。所以到时候如果app使用新版本的签名工具的时候，如果启用 scheme v2，那么这个机制则不能工作。目前看代码，是可以disable v2 的。

虽然目前暂时还是可以disable APK Signature Scheme v2的。
```
signingConfigs {
    release {
        v2SigningEnabled false
    }
}
```

### 3.3 当前比较合适的方案是使用美团的walle
[Signature Scheme v2的出现让目前美团的walle成为公开已知的多渠道打包的最好选择](https://www.jianshu.com/p/e4ed249e4cab)
[还有一个开源的gradle plugin据说也支持V2签名模式](https://github.com/mcxiaoke/packer-ng-plugin)

[美团的walle接入指南](https://www.jianshu.com/p/0ba717f7385f),原理都在[新一代开源Android渠道包生成工具Walle](https://tech.meituan.com/android-apk-v2-signature-scheme.html)


[有人给出了Android多渠道打包的进化史，很有意思](http://www.dss886.com/2017/11/21/01/)


[为什么 Android 要采用 Binder 作为 IPC 机制？](https://www.zhihu.com/question/39440766)


> 传统的进程间通信方式有管道，消息队列，共享内存等，其中管道，消息队列采用存储-转发方式，即数据先从发送方缓存区拷贝到内核开辟的缓存区中，然后再从内核缓存区拷贝到接收方缓存区，至少有两次拷贝过程。共享内存虽然无需拷贝，但控制复杂，难以使用。socket作为一款通用接口，其传输效率低，开销大，主要用在跨网络的进程间通信和本机上进程间的低速通信。Binder通过内存映射的方式，使数据只需要在内存进行一次读写过程。
内存映射，简而言之就是将用户空间的一段内存区域映射到内核空间，映射成功后，用户对这段内存区域的修改可以直接反映到内核空间，相反，内核空间对这段区域的修改也直接反映用户空间。那么对于内核空间<—->用户空间两者之间需要大量数据传输等操作的话效率是非常高的。

## sharedPreference其实是支持跨进程的，只是谷歌不推荐，建议使用ContentProvider这种
> Context.MODE_MULTI_PROCESS
This constant was deprecated in API level 23. MODE_MULTI_PROCESS does not work reliably in some versions of Android, and furthermore does not provide any mechanism for reconciling concurrent modifications across processes. Applications should not attempt to use it. Instead, they should use an explicit cross-process data management approach such as ContentProvider.


[听说你Binder机制学的不错，来面试下这几个问题](https://www.jianshu.com/p/adaa1a39a274)

Client发起IPC请求，是阻塞的吗？
这个要看了，反正startActivity和finish这种都不是

adb getEvent sendEvent
input tap x y
input touchescreen
input text helloworld
input keyevent

Xposed的介绍与入门
Xposed的原理与Multidex及动态加载问题

### 组件化、插件化
组件化、插件化的前提就是解耦

[在Android中执行shell指令](https://github.com/jaredrummler/AndroidShell)
[滴滴的virtualApp](https://github.com/didi/VirtualAPK)。 目前看来就是用android.content.pm.PackageParse去解析一个apk文件，封装成一个LoadedPlugin对象（Cache下来），后续调用apk中描述的功能进行操作。所以应该还是在host的进程中跑的。由此联系到[PackageInstaller 原理简述](http://www.cnblogs.com/myitm/archive/2012/05/17/2506635.html)


-  多渠道的话这样的命令要跑多次
使用walle就好了。
> project 的 build.gradle 添加:
```gradle
dependencies {
    classpath 'com.meituan.android.walle:plugin:1.0.3'
}
app/build.gradle 添加：
apply plugin: 'walle'
dependencies {
    ...
    compile 'com.meituan.android.walle:library:1.0.3'
}
在工程目录下创建 channel 文件：
meituan # 美团
samsungapps #三星
hiapk
anzhi
xiaomi # 小米
91com
gfan
appchina
nduoa
3gcn
mumayi
10086com
wostore
189store
lenovomm
hicloud
meizu
wandou
# Google Play
# googleplay
# 百度
baidu
#
# 360
360cn
#
# 应用宝
myapp
```

编译全部渠道
> gradlew clean assembleReleaseChannels
gradlew clean assembleReleaseChannels -PchannelList=huawei // 只编译华为的
gradlew clean assembleReleaseChannels -PchannelList=huawei,xiaomi // 小米跟华为的

以上亲测通过，原本装的jdk 9，一直报错。在java home里换成jdk 1.8后，就没什么问题了。有问题gradlew的时候后面跟上--stacktrace，出错了粘贴到google里就好了。

在java代码中获取渠道信息
> String channel = WalleChannelReader.getChannel(this.getApplicationContext());

关于美团的热修复方案，亲测可用，生成的patch.jar文件大小5.0kB(改了个方法)
[美团的热修复叫Robust](https://github.com/Meituan-Dianping/Robust)
> 1. 按照官方wiki在build.gradle中添加需要的依赖。还有一个robust.xml文件，把packageName和patchPackageName改成自己的，看下别的配置，注释都很清楚
> 2. 先打release包，记得开progurad。gradlew clean assembleRelease --stacktrace
> 3. 在activity里面放一个button,在onClick的时候loadPatch.记得PatchManipulateImpl里面写的setPatchesImfoImplClassFullName要和roubust.xml里面写的一样
> 4. 在activity里面修改的代码添加@mofidy注解，@Add作为新加的方法的注解
> 5. 开始打补丁包.在gradle中注释掉apply plugin: 'robust'，开启apply plugin: 'auto-patch-plugin'。把app/build/outputs/mappings/mapping.txt文件和app/build/outputs/robust/methodsMap.robust这两个文件粘贴到app/robust文件夹中。重新打release包：gradlew clean assembleRelease --stacktrace。报错是正常的。
> 6. 在app/build/outputs/robust文件夹中找到patch.jar文件。 adb push app/build/outputs/robust/patch.jar /sdcard/robust/patch.jar
> 7. 进Activity，点击那个loadPath的按钮，就是去刚才adb push的路径去加载这个patch（当然生产环境应该是搭建https服务了）。


[插件化开发small解释了动态注册activity的原理](https://github.com/wequick/small/wiki/Android-dynamic-register-activities):
app所在进程startActivity会通过Instrumentation的execStartActivity方法向system_server进程的activityManagerService发起请求，在这里要将插件activity的名称换成之前写在manifest中的名称。system_server完成启动Activity会回调到Instrumentation的newActivity方法，在这里可以将manifest中的名称还原成插件的activity名称。

```java
ActivityThread thread = currentActivityThread();
Instrumentation base = thread.@mInstrumentation;
Instrumentation wrapper = new InstrumentationWrapper(base);
thread.@mInstrumentation = wrapper;

class InstrumentationWrapper extends Instrumentation {
    public ActivityResult execStartActivity(..., Intent intent, ...) {
        fakeToStub(intent); //这里在intent里面放个className就好了
        base.execStartActivity(args);
    }

    @Override
    public Activity newActivity(ClassLoader cl, String className, Intent intent) {
        className = restoreToReal(intent, className); //这里从intent中读取className就好了
        return base.newActivity(cl, className, intent);
    }
}
```

[sharedUid](https://www.jianshu.com/p/107aaf054140)通过Shared User id,拥有同一个User id的多个APK可以配置成运行在同一个进程中.所以默认就是可以互相访问任意数据。





## 参考
[分析DroidPlugin，深入理解插件化框架](https://github.com/tiann/understand-plugin-framework)
[逆向大全](http://www.wjdiankong.cn/)
[Android Hook技术防范漫谈](https://tech.meituan.com/android_anti_hooking.html)
[爱奇艺组件化探索之原理篇](https://zhuanlan.zhihu.com/p/34346219)
[Atlas容器框架](http://atlas.taobao.org/docs/principle-intro/Runtime_principle.html)
