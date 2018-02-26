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


[关于Android Gradle你需要知道这些（4）](https://juejin.im/post/5a756f11f265da4e7c185bc5)
[Gradle插件学习笔记（四)](https://juejin.im/post/5a767c7cf265da4e9c6300a1#heading-5)
