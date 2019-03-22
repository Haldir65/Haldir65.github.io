---
title: ndk入门笔记
date: 2019-02-13 18:25:01
tags: [android]
---

android中ndk及jni编写注意事项（本文主要讲CMake）
![](https://www.haldir66.ga/static/imgs/ShanwangpingKarst_EN-AU5360258756_1920x1080.jpg)
<!--more-->
一些小窍门
> cmake最终执行的命令在这个文件里面.externalNativeBuild/cmake/debug/{abi}/cmake_build_command.txt
cmake生成的.so文件在"\app\build\intermediates\cmake\debug\obj\arm64-v8a"这个路径下。
CMake 一共有2种编译工具链 - clang 和 gcc，gcc 已经废弃，clang 是默认的。

[ndk官方入门指南](https://developer.android.com/ndk/guides/)

cpu架构
```
armeabi
armeabi­v7a
arm64­v8a
x86
x86_64
mips
mips64
```


cmake交叉编译
### abi(application binary interface)
[abis](https://developer.android.com/ndk/guides/abis)
ndk支持的abi包括
armeabi，armeabi-v7a，arm64-v8a，x86，x86_64，mips，mips64

***NDK 17 不再支持 ABI: armeabi、mips、mips64***


x86设备上，libs/x86目录中如果存在.so文件的话，会被安装，如果不存在，则会选择armeabi-v7a中的.so文件，如果也不存在，则选择armeabi目录中的.so文件。

x86设备能够很好的运行ARM类型函数库，但并不保证100%不发生crash，特别是对旧设备。

64位设备（arm64-v8a, x86_64, mips64）能够运行32位的函数库，但是以32位模式运行，在64位平台上运行32位版本的ART和Android组件，将丢失专为64位优化过的性能（ART，webview，media等等）。
所有的x86/x86_64/armeabi-v7a/arm64-v8a设备都支持armeabi架构的.so文件，因此似乎移除其他ABIs的.so文件是一个减少APK大小的好技巧。

### abiFilter
[只想让cmake打arm64-v8a一种arch的包怎么办](https://developer.android.com/studio/projects/gradle-external-native-builds)
>In most cases, you only need to specify abiFilters in the ndk block, as shown above, because it tells Gradle to both build and package those versions of your native libraries. However, if you want to control what Gradle should build, independently of what you want it to package into your APK, configure another abiFilters flag in the defaultConfig.externalNativeBuild.cmake block (or defaultConfig.externalNativeBuild.ndkBuild block). Gradle builds those ABI configurations but only packages the ones you specify in the defaultConfig.ndk block.

翻译过来就是
```
android {
  ...
  defaultConfig {
    ...
    externalNativeBuild {
      cmake {
          abiFilters "arm64-v8a" //只帮我打这个架构的就好了
      }
      // or ndkBuild {...}
    }

    // Similar to other properties in the defaultConfig block,
    // you can configure the ndk block for each product flavor
    // in your build configuration.
    ndk {
      // Specifies the ABI configurations of your native
      // libraries Gradle should build and package with your APK.
      abiFilters 'x86', 'x86_64', 'armeabi', 'armeabi-v7a',
                   'arm64-v8a' //这些架构的包我全部都要打进apk里面
    //当然，如果 externalNativeBuild里面只打了arm64-v8a的so文件，这种写法导致最终生成的apk里面装了x86，x86_64..的so文件夹，但其实里面放的都是arm64-v8a的so，当然是不行的。
    //默认情况下，不写abiFilter的话，所有支持的abi对应的so文件都会打出来，大小略有差异
    }
  }
  buildTypes {...}
  // Use this block to link Gradle to your CMake or ndk-build script.似乎只是用来告诉gradle CMakeList.txt的位置在哪里
  externalNativeBuild {
       cmake {
            path 'CMakeLists.txt' //这个是说明CMakeLists.txt这个文件在哪里的，studio 里面link project with c++ program就是干这个的
        }
  }
}
```

[所以现在看来这种手动调用cmake的方式也没有太大必要了](https://rangaofei.github.io/2018/02/22/shell脚本生成安卓全abi动态库与静态库)

### abi支持缺失导致的crash
android第三方 sdk是以aar形式提供的,甚至是远程aar，如果这个sdk对abi的支持比较全，可能会包含armeabi, armeabi-v7a,x86, arm64-v8a,x86_64五种abi,而你应用的其它so只支持armeabi,armeabi-v7a，x86三种，直接引用sdk的aar,会自动编译出支持5种abi的包。但是应用的其它so缺少对其它两种abi的支持，那么如果应用运行于arm64-v8a,x86_64为首选abi的设备上时，就会CRASH。
所以解决方法就分两种
第一种：
```
productFlavors {  
    necess {  
        ndk {  
            abiFilters "armeabi-v7a"  
            abiFilters "x86"  
            abiFilters "armeabi"  
        }  
    }  
    abiall {  
        ndk {  
            abiFilters "armeabi-v7a"  
            abiFilters "x86"  
            abiFilters "armeabi"  
            abiFilters "arm64-v8a"  
            abiFilters "x86_64"  
        }  
    }  
}  
```

第二种：
app/build.gradle中这句话的意思是指让生成的apk中包含下面三种abi的so文件
```gradle
defaultConfig {
    ndk {
        abiFilters "armeabi", "armeabi-v7a", "arm64-v8a"
    }
}
```
在apk文件中，so文件放在lib/armeabi-v7a lib/x86_64 lib/x86 lib/arm64-v8a这些文件夹下面

### 添加prebuilt library
Add other prebuilt libraries
在CMakeLists.txt中添加
add_library( imported-lib
             SHARED
             IMPORTED )
关键词IMPORTED ，就拿ffmepg来说，首先在linux上编译出不同abi的so文件，ffmpeg有好几个so文件，比方说libavcodec.so这个文件。

```
Some libraries provide separate packages for specific CPU architectures, or Application Binary Interfaces (ABI), and organize them into separate directories. This approach helps libraries take advantage of certain CPU architectures while allowing you to use only the versions of the library you want. To add multiple ABI versions of a library to your CMake build script, without having to write multiple commands for each version of the library, you can use the ANDROID_ABI path variable. This variable uses a list of the default ABIs that the NDK supports, or a filtered list of ABIs you manually configure Gradle to use. 
```
有些第三方库针对不同的cpu架构提供了不同的so文件


```
# 添加库——外部引入的库
# 库名称：avcodec（不需要包含前缀lib）
# 库类型：SHARED，表示动态库，后缀为.so（如果是STATIC，则表示静态库，后缀为.a）
# IMPORTED表明是外部引入的库
set(distribution_DIR ../../../../libs) //这个libs文件夹名字随便取，下面要包含armeabi-v7a,x86,x86_64等你想要支持的架构对应的so文件（在Linux上编出来的）

add_library( avcodec
        SHARED
        IMPORTED)

set_target_properties( avcodec
        PROPERTIES IMPORTED_LOCATION
        ${distribution_DIR}/${ANDROID_ABI}/libavcodec.so) //最终gradle编译的时候会把abiFilter中指定的cpu架构一个个去对应的文件夹去找so文件，找不到就会报错

include_directories( avcodec/include/ )
//告诉cmake，把这个目录下面的文件当做头文件拿进来，不用自己一个个去copy了，注意这个不是recursive的，也就是照顾不到子文件夹

//这一步就是Link了
target_link_libraries( native-lib //这个是我们自己的lib的名字
        avcodec
        avfilter
        avformat
        avutil
        swresample
        swscale
        -landroid
        ${log-lib} )        
```         


### 预先编译好的so文件放置的目录要告诉gradle
>f you want Gradle to package prebuilt native libraries with your APK, modify the default source set configuration to include the directory of your prebuilt .so files, as shown below. Keep in mind, you don't need to do this to include artifacts of CMake build scripts that you link to Gradle.

```
android {
    ...
    sourceSets {
        main {
            jniLibs.srcDirs 'imported-lib/src/', 'more-imported-libs/src/'
        }
    }
}
```

### 调用ndk的api
比方说这种头文件
```c
#include <android/native_window_jni.h>
#include <android/cpu-features.h>
#include <android/multinetwork.h>
```
native_window_jni 在ndk 的libandroid.so库中，需要在CMakeLists.txt中引入android库，像这样
```
target_link_libraries( my-lib
        ...
        -landroid
        ${log-lib} )
```
从[fmpeg+native_window实现万能视频播放器播放本地视频](https://www.jianshu.com/p/7a165b9f9fad)抄来一段cpp代码
```cpp
 extern "C" {
    //编码
    #include "libavcodec/avcodec.h"
    //封装格式处理
    #include "libavformat/avformat.h"
    //像素处理
    #include "libswscale/swscale.h"
    //native_window_jni 在ndk 的libandroid.so库中，需要在CMakeLists.txt中引入android库
    #include <android/native_window_jni.h>
    #include <unistd.h>//sleep用的头文件
    }
    /**
        *将任意格式的视频在手机上进行播放，使用native进行绘制
        * env:虚拟机指针
        * inputStr：视频文件路径
        * surface: 从java层传递过来的SurfaceView的surface对象 
        */
    void ffmpegVideoPlayer(JNIEnv *env, char *inputStr, jobject surface) {
        // 1.注册各大组件，执行ffmgpe都必须调用此函数
        av_register_all();
        //2.得到一个ffmpeg的上下文（上下文里面封装了视频的比特率，分辨率等等信息...非常重要）
        AVFormatContext *pContext = avformat_alloc_context();
        //3.打开一个视频
        if (avformat_open_input(&pContext, inputStr, NULL, NULL) < 0) {
            LOGE("打开失败");
            return;
        }
        //4.获取视频信息（将视频信息封装到上下文中）
        if (avformat_find_stream_info(pContext, NULL) < 0) {
            LOGE("获取信息失败");
            return;
        }
        //5.用来记住视频流的索引
        int video_stream_idx = -1;
        //从上下文中寻找找到视频流
        for (int i = 0; i < pContext->nb_streams; ++i) {
            LOGE("循环  %d", i);
            //codec：每一个流 对应的解码上下文
            //codec_type：流的类型
            if (pContext->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
                //如果找到的流类型 == AVMEDIA_TYPE_VIDEO 即视频流，就将其索引保存下来
                video_stream_idx = i;
            }
        }
    
        //获取到解码器上下文
        AVCodecContext *pCodecCtx = pContext->streams[video_stream_idx]->codec;
        //获取解码器（加密视频就是在此处无法获取）
        AVCodec *pCodex = avcodec_find_decoder(pCodecCtx->codec_id);
        LOGE("获取视频编码 %p", pCodex);
    
        //6.打开解码器。 （ffempg版本升级名字叫做avcodec_open2）
        if (avcodec_open2(pCodecCtx, pCodex, NULL) < 0) {
            LOGE("解码失败");
            return;
        }
        //----------------------解码前准备--------------------------------------
        //准备开始解码时需要一个AVPacket存储数据（通过av_malloc分配内存）
        AVPacket *packet = (AVPacket *) av_malloc(sizeof(AVPacket));
        av_init_packet(packet);//初始化结构体
    
        //解封装需要AVFrame
        AVFrame *frame = av_frame_alloc();
        //声明一个rgb_Frame的缓冲区
        AVFrame *rgb_Frame = av_frame_alloc();
        //rgb_Frame  的缓冲区 初始化
        uint8_t *out_buffer = (uint8_t *) av_malloc(
                avpicture_get_size(AV_PIX_FMT_RGBA, pCodecCtx->width, pCodecCtx->height));
        //给缓冲区进行替换
        int re = avpicture_fill((AVPicture *) rgb_Frame, out_buffer, AV_PIX_FMT_RGBA, pCodecCtx->width,
                                pCodecCtx->height);
        LOGE("宽 %d  高 %d", pCodecCtx->width, pCodecCtx->height);
    
    
        //格式转码需要的转换上下文（根据封装格式的宽高和编码格式，以及需要得到的格式的宽高）
        //pCodecCtx->pix_fmt 封装格式文件的上下文
        //AV_PIX_FMT_RGBA ： 目标格式 需要跟SurfaceView设定的格式相同
        //SWS_BICUBIC ：清晰度稍微低一点的算法（转换算法，前面的算法清晰度高效率低，下面的算法清晰度低效率高） 
        //NULL,NULL,NULL ： 过滤器等
        SwsContext *swsContext = sws_getContext(pCodecCtx->width, pCodecCtx->height, pCodecCtx->pix_fmt,
                                                pCodecCtx->width, pCodecCtx->height, AV_PIX_FMT_RGBA,
                                                SWS_BICUBIC, NULL, NULL, NULL
        );
        int frameCount = 0;
    
        //获取nativeWindow对象,准备进行绘制
        ANativeWindow *nativeWindow = ANativeWindow_fromSurface(env, surface);
        ANativeWindow_Buffer outBuffer;//申明一块缓冲区 用于绘制
    
        //------------------------一桢一帧开始解码--------------------
        int length = 0;
        int got_frame;
        while (av_read_frame(pContext, packet) >= 0) {//开始读每一帧的数据
            if (packet->stream_index == video_stream_idx) {//如果这是一个视频流
                //7.解封装（将packet解压给frame，即：拿到了视频数据frame）
                length = avcodec_decode_video2(pCodecCtx, frame, &got_frame, packet);//解封装函数
                LOGE(" 获得长度   %d 解码%d  ", length, frameCount++);
                if (got_frame > 0) {
    
                    //8.准备绘制
                    //配置绘制信息 宽高 格式(这个绘制的宽高直接决定了视频在屏幕上显示的情况，这样会平铺整个屏幕，可以根据特定的屏幕分辨率和视频宽高进行匹配)
                    ANativeWindow_setBuffersGeometry(nativeWindow, pCodecCtx->width, pCodecCtx->height,
                                                     WINDOW_FORMAT_RGBA_8888);
                    ANativeWindow_lock(nativeWindow, &outBuffer, NULL);//锁定画布(outBuffer中将会得到数据)
                    //9.转码（转码上下文，原数据，一行数据，开始位置，yuv的缓冲数组，yuv一行的数据）
                    sws_scale(swsContext, (const uint8_t *const *) frame->data, frame->linesize, 0,
                              frame->height, rgb_Frame->data,
                              rgb_Frame->linesize
                    );
                    //10.绘制
                    uint8_t *dst = (uint8_t *) outBuffer.bits; //实际的位数
                    int destStride = outBuffer.stride * 4; //拿到一行有多少个字节 RGBA
                    uint8_t *src = (uint8_t *) rgb_Frame->data[0];//像素数据的首地址
                    int srcStride = rgb_Frame->linesize[0]; //实际内存一行的数量
                    for (int i = 0; i < pCodecCtx->height; ++i) {
                        //将rgb_Frame缓冲区里面的数据一行一行copy到window的缓冲区里面
                        //copy到window缓冲区的时候进行一些偏移设置可以将视频播放居中
                        memcpy(dst + i * destStride, src + i * srcStride, srcStride);
                    }
    
                    ANativeWindow_unlockAndPost(nativeWindow);//解锁画布
                    usleep(1000 * 16);//可以根据帧率休眠16ms
    
                }
            }
            av_free_packet(packet);//释放
        }
        ANativeWindow_release(nativeWindow);//释放window
        av_frame_free(&frame);
        av_frame_free(&rgb_Frame);
        avcodec_close(pCodecCtx);
        avformat_free_context(pContext);
    
        free(inputStr);
    }
```

### ffmpeg移植到Android上（多个abi）
[首先是编译不同架构的ffmpeg library](https://github.com/ejoker88/FFmpeg-3.4-Android)
这个库使用了FFmpeg 3.4 和 NDK r16b stable. 版本搭配真的很重要，这个脚本还要调用python创建不同abi的toolchain。
使用ndk编译ffmpeg满满的都是坑
```
In file included from libavfilter/aeval.c:26:0:
./libavutil/avassert.h:30:20: fatal error: stdlib.h: No such file or directory
 #include <stdlib.h>
                    ^
出现这个错误是因为使用最新版的NDK造成的，最新版的NDk将头文件和库文件进行了分离，我们指定的sysroot文件夹下只有库文件，而头文件放在了NDK目录下的sysroot内，只需在--extra-cflags中添加 "-isysroot $NDK/sysroot" 即可，还有有关汇编的头文件也进行了分离，需要根据目标平台进行指定 "-I$NDK/sysroot/usr/include/arm-linux-androideabi"，将 "arm-linux-androideabi" 改为需要的平台就可以，终于可以顺利的进行编译了
```

```
nasm/yasm not found or too old. use --disable-x86asm for a crippled build
```
这是汇编工具没有安装导致的
sudo apt install yasm

[找到一个编译不同abi的so文件的脚本](https://github.com/coopsrc/FFPlayerDemo)
armeabi-v7a arm64-v8a x86 x86_64这么几个host每个都要花上10分钟，所以这个脚本跑起来之后可以去喝杯茶了

```bash
#!/bin/sh

PREFIX=android-build
HOST_PLATFORM=linux-x86_64

COMMON_OPTIONS="\
    --target-os=android \
    --disable-static \
    --enable-shared \
    --enable-small \
    --disable-programs \
    --disable-ffmpeg \
    --disable-ffplay \
    --disable-ffprobe \
    --disable-doc \
    --disable-symver \
    --disable-asm \
    --enable-decoder=vorbis \
    --enable-decoder=opus \
    --enable-decoder=flac 
    "

build_all(){
    for version in armeabi-v7a arm64-v8a x86 x86_64; do
        echo "======== > Start build $version"
        case ${version} in
        armeabi-v7a )
            ARCH="arm"
            CPU="armv7-a"
            CROSS_PREFIX="$NDK_HOME/toolchains/arm-linux-androideabi-4.9/prebuilt/$HOST_PLATFORM/bin/arm-linux-androideabi-"
            SYSROOT="$NDK_HOME/platforms/android-21/arch-arm/"
            EXTRA_CFLAGS="-march=armv7-a -mfpu=neon -mfloat-abi=softfp -mvectorize-with-neon-quad"
            EXTRA_LDFLAGS="-Wl,--fix-cortex-a8"
        ;;
        arm64-v8a )
            ARCH="aarch64"
            CPU="armv8-a"
            CROSS_PREFIX="$NDK_HOME/toolchains/aarch64-linux-android-4.9/prebuilt/$HOST_PLATFORM/bin/aarch64-linux-android-"
            SYSROOT="$NDK_HOME/platforms/android-21/arch-arm64/"
            EXTRA_CFLAGS=""
            EXTRA_LDFLAGS=""
        ;;
        x86 )
            ARCH="x86"
            CPU="i686"
            CROSS_PREFIX="$NDK_HOME/toolchains/x86-4.9/prebuilt/$HOST_PLATFORM/bin/i686-linux-android-"
            SYSROOT="$NDK_HOME/platforms/android-21/arch-x86/"
            EXTRA_CFLAGS=""
            EXTRA_LDFLAGS=""
        ;;
        x86_64 )
            ARCH="x86_64"
            CPU="x86_64"
            CROSS_PREFIX="$NDK_HOME/toolchains/x86_64-4.9/prebuilt/$HOST_PLATFORM/bin/x86_64-linux-android-"
            SYSROOT="$NDK_HOME/platforms/android-21/arch-x86_64/"
            EXTRA_CFLAGS=""
            EXTRA_LDFLAGS=""
        ;;
        esac

        echo "-------- > Start clean workspace"
        make clean

        echo "-------- > Start config makefile"
        configuration="\
            --prefix=${PREFIX} \
            --libdir=${PREFIX}/libs/${version}
            --incdir=${PREFIX}/includes/${version} \
            --pkgconfigdir=${PREFIX}/pkgconfig/${version} \
            --arch=${ARCH} \
            --cpu=${CPU} \
            --cross-prefix=${CROSS_PREFIX} \
            --sysroot=${SYSROOT} \
            --extra-ldexeflags=-pie \
            ${COMMON_OPTIONS}
            "

        echo "-------- > Start config makefile with ${configuration}"
        ./configure ${configuration}

        echo "-------- > Start make ${version} with -j8"
        make j8

        echo "-------- > Start install ${version}"
        make install
        echo "++++++++ > make and install ${version} complete."

    done
}

echo "-------- Start --------"
build_all
echo "-------- End --------"
```

[如何把ffmpeg生成的so文件压缩大小](https://blog.csdn.net/u011485531/article/details/55804380)

然后才是交叉编译



## 参考
[configure-cmake](https://developer.android.com/studio/projects/configure-cmake)
[googlesamples/android-ndk](https://github.com/googlesamples/android-ndk)
[Android NDK开发扫盲及最新CMake的编译使用](https://www.jianshu.com/p/6332418b12b1)