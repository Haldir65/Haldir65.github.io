---
title: 2018-02-03-gradle-command-explained
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
