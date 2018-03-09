---
title: gradle command记事本
date: 2018-02-03 14:46:09
tags:
---

![](http://odzl05jxx.bkt.clouddn.com/image/jpg/street lights dark night car city.jpg?imageView2/2/w/600)
<!--more-->

> Android dependency 'com.android.support:support-v4' has different version for the compile (21.0.3) and runtime (26.1.0) classpath. You should manually set the same version via DependencyResolution


I forced the version of support-v4 using this block in root build.gradle:
```gradle
subprojects {
    project.configurations.all {
        resolutionStrategy.eachDependency { details ->
            if (details.requested.group == 'com.android.support'
                    && !details.requested.name.contains('multidex') ) {
                details.useVersion "$supportlib_version"
            }
        }
    }
}
```

[All com.android.support libraries must use the exact same version [duplicate]
](https://stackoverflow.com/questions/42374151/all-com-android-support-libraries-must-use-the-exact-same-version-specification)


>./gradlew -v 版本号
./gradlew clean 清除app目录下的build文件夹
./gradlew build 检查依赖并编译打包
./gradlew assembleDebug 编译并打Debug包
./gradlew assembleRelease 编译并打Release的包
或者
./gradlew aR
./gradlew installRelease Release模式打包并安装
或者
./gradlew iR
./gradlew uninstallRelease 卸载Release模式包

Android项目迁移到gradle 3.0需要注意的一些事
- implementation和api的区别：
> When your module configures an implementation dependency, it's letting Gradle know that the module does not want to leak the dependency to other modules at compile time. That is, the dependency is available to other modules only at runtime.
Using this dependency configuration instead of api or compile can result in significant build time improvements because it reduces the amount of projects that the build system needs to recompile. For example, if an implementation dependency changes its API, Gradle recompiles only that dependency and the modules that directly depend on it. Most app and test modules should use this configuration.
// a module 使用implementation引入了某个dependency，这个依赖就不会暴露给依赖于a的mudule。

> When a module includes an api dependency, it's letting Gradle know that the module wants to transitively export that dependency to other modules, so that it's available to them at both runtime and compile time. This configuration behaves just like compile (which is now deprecated), and you should typically use this only in library modules. That's because, if an api dependency changes its external API, Gradle recompiles all modules that have access to that dependency at compile time. So, having a large number of api dependencies can significantly increase build times. Unless you want to expose a dependency's API to a separate test module, app modules should instead use implementation dependencies.
//所以如果想要把自己的某项依赖暴露出去，让依赖自己的mudule也能用到这项依赖，就要用api了
但是api和之前的compile是一样的，所以编译速度比implementation慢很多。


看到一份关于android build tasks解释的[非常好的文章](https://www.diycode.cc/topics/683)
```
mergeDebugResources任务的作用是解压所有的aar包输出到app/build/intermediates/exploded-aar，并且把所有的资源文件合并到app/build/intermediates/res/merged/debug目录里

processDebugManifest任务是把所有aar包里的AndroidManifest.xml中的节点，合并到项目的AndroidManifest.xml中，并根据app/build.gradle中当前buildType的manifestPlaceholders配置内容替换manifest文件中的占位符，最后输出到app/build/intermediates/manifests/full/debug/AndroidManifest.xml

processDebugResources的作用
1、调用aapt生成项目和所有aar依赖的R.java,输出到app/build/generated/source/r/debug目录
3、生成资源索引文件app/build/intermediates/res/resources-debug.ap_
2、把符号表输出到app/build/intermediates/symbols/debug/R.txt

compileDebugJavaWithJavac这个任务是用来把java文件编译成class文件，输出的路径是app/build/intermediates/classes/debug
编译的输入目录有
- 1、项目源码目录，默认路径是app/src/main/java，可以通过sourceSets的dsl配置，允许有多个（打印project.android.sourceSets.main.java.srcDirs可以查看当前所有的源码路径,具体配置可以参考android-doc
- 2、app/build/generated/source/aidl
- 3、app/build/generated/source/buildConfig
- 4、app/build/generated/source/apt(继承javax.annotation.processing.AbstractProcessor做动态代码生成的一些库，输出在这个目录，具体可以参考Butterknife 和 Tinker)的代码

transformClassesWithJarMergingForDebug的作用是把compileDebugJavaWithJavac任务的输出app/build/intermediates/classes/debug，和app/build/intermediates/exploded-aar中所有的classes.jar和libs里的jar包作为输入，合并起来输出到app/build/intermediates/transforms/jarMerging/debug/jars/1/1f/combined.jar，我们在开发中依赖第三方库的时候有时候报duplicate entry:xxx 的错误，就是因为在合并的过程中在不同jar包里发现了相同路径的类

transformClassesWithMultidexlistForDebug这个任务花费的时间也很长将近8秒，它有两个作用
- 1、扫描项目的AndroidManifest.xml文件和分析类之间的依赖关系，计算出那些类必须放在第一个dex里面,最后把分析的结果写到app/build/intermediates/multi-dex/debug/maindexlist.txt文件里面
- 2、生成混淆配置项输出到app/build/intermediates/multi-dex/debug/manifest_keep.txt文件里

项目里的代码入口是manifest中application节点的属性android.name配置的继承自Application的类，在android5.0以前的版本系统只会加载一个dex(classes.dex)，classes2.dex .......classesN.dex 一般是使用android.support.multidex.MultiDex加载的，所以如果入口的Application类不在classes.dex里5.0以下肯定会挂掉，另外当入口Application依赖的类不在classes.dex时初始化的时候也会因为类找不到而挂掉，还有如果混淆的时候类名变掉了也会因为对应不了而挂掉,综上所述就是这个任务的作用

transformClassesWithDexForDebug这个任务的作用是把包含所有class文件的jar包转换为dex，class文件越多转换的越慢
输入的jar包路径是app/build/intermediates/transforms/jarMerging/debug/jars/1/1f/combined.jar
输出dex的目录是build/intermediates/transforms/dex/debug/folders/1000/1f/main
```

app/build/intermediates/symbols/debug/R.txt这个文件长这样
> int anim abc_fade_in 0x7f010000
int anim abc_fade_out 0x7f010001
int anim abc_grow_fade_in_from_bottom 0x7f010002
int anim abc_popup_enter 0x7f010003
int anim abc_popup_exit 0x7f010004
int anim abc_shrink_fade_out_from_bottom 0x7f010005
int anim abc_slide_in_bottom 0x7f010006
int anim abc_slide_in_top 0x7f010007
int anim abc_slide_out_bottom 0x7f010008
int anim abc_slide_out_top 0x7f010009
int anim design_bottom_sheet_slide_in 0x7f01000a
int anim design_bottom_sheet_slide_out 0x7f01000b
int anim design_snackbar_in 0x7f01000c
int anim design_snackbar_out 0x7f01000d
int anim tooltip_enter 0x7f01000e
int anim tooltip_exit 0x7f01000f
int animator design_appbar_state_list_animator 0x7f020000
int attr actionBarDivider 0x7f030000
int attr actionBarItemBackground 0x7f030001
int attr actionBarPopupTheme 0x7f030002
int attr actionBarSize 0x7f030003
...
按照字母从a-z开始，hex value自增(0x7f开头)

Android Studio中点击run之后，执行了这些tasks
> Task spend time:
      2ms  :app:preBuild
     64ms  :app:preDebugBuild
      9ms  :app:compileDebugAidl
      4ms  :app:compileDebugRenderscript
      1ms  :app:checkDebugManifest
      2ms  :app:generateDebugBuildConfig
      1ms  :app:prepareLintJar
      1ms  :app:generateDebugResValues
      0ms  :app:generateDebugResources
     57ms  :app:mergeDebugResources
      1ms  :app:createDebugCompatibleScreenManifests
      4ms  :app:processDebugManifest
      1ms  :app:splitsDiscoveryTaskDebug
     18ms  :app:processDebugResources
      1ms  :app:generateDebugSources
     11ms  :app:javaPreCompileDebug
     10ms  :app:compileDebugJavaWithJavac
      1ms  :app:compileDebugNdk
      0ms  :app:compileDebugSources
      4ms  :app:mergeDebugShaders
      1ms  :app:compileDebugShaders
      0ms  :app:generateDebugAssets
      8ms  :app:mergeDebugAssets
     19ms  :app:transformClassesWithDexBuilderForDebug
      6ms  :app:transformDexArchiveWithExternalLibsDexMergerForDebug
      7ms  :app:transformDexArchiveWithDexMergerForDebug
      1ms  :app:mergeDebugJniLibFolders
     12ms  :app:transformNativeLibsWithMergeJniLibsForDebug
     10ms  :app:transformNativeLibsWithStripDebugSymbolForDebug
      0ms  :app:processDebugJavaRes
     24ms  :app:transformResourcesWithMergeJavaResForDebug
      2ms  :app:validateSigningDebug
      7ms  :app:packageDebug
      0ms  :app:assembleDebug

[gradle 4.4之后Clock 被Deprecated的方案是自己创建一个groovy文件](https://github.com/HujiangTechnology/gradle_plugin_android_aspectjx/pull/75/files#diff-a5277607f48bf80ac7edd5dbafa307ae)
```java
org.gradle.util.Clock() // 被Deprecated之后的解决方案
```

[building-android-apps](https://guides.gradle.org/building-android-apps/)

> gradlew :app:dependencies --configuration releaseCompileClasspath
gradle tasks --all ## 查看当前project的所有tasks


============================================
How to create gradle Plugin
1. add to your buidl script // 不可复用
2. 创建BuildSrc文件夹 //依旧不可复用
3. 创建一个Standalone Project //可复用


project.extensions.create("makeChannel", MakeChannelParams)
public class GreetingPlugin implements Plugin<Project> {
    @Override
    public void apply(Project project) {
        project.task("hello")
          .doLast(task -> System.out.println("Hello Gradle!"));
    }
}


[official gradle docs 是最好的学习资料](https://guides.gradle.org/creating-new-gradle-builds/)
[custom_plugins](https://docs.gradle.org/current/userguide/custom_plugins.html)
[关于Android Gradle你需要知道这些（4）](https://juejin.im/post/5a756f11f265da4e7c185bc5)
[Gradle插件学习笔记（四)](https://juejin.im/post/5a767c7cf265da4e9c6300a1#heading-5)
