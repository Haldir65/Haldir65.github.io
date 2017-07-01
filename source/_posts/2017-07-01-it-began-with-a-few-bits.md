---
title: 2017-07-01-it-began-with-a-few-bits
date: 2017-07-01 23:03:00
tags:
   - linux
   - java
---

###This is gonna be nasty......

1. Retrofit

```java
ServiceMethod serviceMethod = loadServiceMethod(method);
OkHttpCall okHttpCall = new OkHttpCall<>(serviceMethod, args);
return serviceMethod.callAdapter.adapt(okHttpCall);
```

2. OkHttp
3. a few 'ok' libraries
why moshi ? why Retrofit call can be clone cheap？
why SinkedSource?
why protolBuffer cost less ?
<!--more-->


### ref
1. [Paisy](https://blog.piasy.com/2016/06/25/Understand-Retrofit/)
2. [open-sourse-projetc](https://github.com/android-cn/android-open-project-analysis/tree/master/tool-lib/network/retrofit)
3. [making retrofit work for you]
