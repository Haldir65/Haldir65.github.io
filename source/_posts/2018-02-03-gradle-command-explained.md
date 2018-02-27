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


[关于Android Gradle你需要知道这些（4）](https://juejin.im/post/5a756f11f265da4e7c185bc5)
[Gradle插件学习笔记（四)](https://juejin.im/post/5a767c7cf265da4e9c6300a1#heading-5)
