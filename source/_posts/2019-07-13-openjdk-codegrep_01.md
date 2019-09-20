---
title: openjdk源码解析[一]
date: 2019-07-13 21:06:23
tags: [java]
---


[openjdk](https://github.com/AdoptOpenJDK/openjdk-jdk8u/blob/master/jdk/src/windows/native/java/net/SocketOutputStream.c)部分源码解析(文件IO),java层以及c语言层的分析
![](https://www.haldir66.ga/static/imgs/BlueShark_EN-AU12265881842_1920x1080.jpg)

<!--more-->

## File IO

IOUtils 
FileChannel


## 回顾一下C语言提供的操作文件的api

1 .读写(创建)文件
```c
#include <stdio.h> 
FILE *fopen( const char * filename, const char * mode ); //定义在标准中的，所以是跨平台的

int fclose( FILE *fp ); //关闭文件
```

| 模式 | 描述 |
| ------ | ------ |
| r | 打开一个已有的文本文件，允许读取文件。 | 
| w | 打开一个文本文件，允许写入文件。如果文件不存在，则会创建一个新文件。在这里，您的程序会从文件的开头写入内容。如果文件存在，则该会被截断为零长度，重新写入。 |
| a | 打开一个文本文件，以追加模式写入文件。如果文件不存在，则会创建一个新文件。在这里，您的程序会在已有的文件内容中追加内容。 | 
| r+ | 打开一个文本文件，允许读写文件。 | 
| w+ | 打开一个文本文件，允许读写文件。如果文件已存在，则文件会被截断为零长度，如果文件不存在，则会创建一个新文件。 | 
| a+ | 打开一个文本文件，允许读写文件。如果文件不存在，则会创建一个新文件。读取会从文件的开头开始，写入则只能是追加模式。 | 


```c
int fputs( const char *s, FILE *fp ); //将字符串s写入文件中

char *fgets( char *buf, int n, FILE *fp ); //从fp指向的输入流中读取n-1个字符，并且自动追加一个 null 字符来终止字符串
```

回到java这一端，创建一个文件File file = new File("c:\somefile.txt") 只是创建了一个java object。
File的一些方法代理给了FileSystem这个抽象类，在unix平台上的实现是UnixFileSystem.java。


例如File.exists方法，最终进入FileSystem.getBooleanAttributes0。这是一个native方法,对应的实现在[UnixFileSystem_md.c](https://github.com/openjdk-mirror/jdk7u-jdk/blob/master/src/solaris/native/java/io/UnixFileSystem_md.c)中
```c
static jboolean
statMode(const char *path, int *mode)
{
    struct stat64 sb;
    if (stat64(path, &sb) == 0) {
        *mode = sb.st_mode;
        return JNI_TRUE;
    }
    return JNI_FALSE;
}

JNIEXPORT jint JNICALL
Java_java_io_UnixFileSystem_getBooleanAttributes0(JNIEnv *env, jobject this,
                                                  jobject file)
{
    jint rv = 0;

    WITH_FIELD_PLATFORM_STRING(env, file, ids.path, path) {
        int mode;
        if (statMode(path, &mode)) {
            int fmt = mode & S_IFMT;
            rv = (jint) (java_io_FileSystem_BA_EXISTS
                  | ((fmt == S_IFREG) ? java_io_FileSystem_BA_REGULAR : 0)
                  | ((fmt == S_IFDIR) ? java_io_FileSystem_BA_DIRECTORY : 0));
        }
    } END_PLATFORM_STRING(env, path);
    return rv;
}

// S_IFMT是一个掩码， S_IFREG表示是一个普通文件， S_IFDIR表示是一个目录。返回值是一个int（其中4位被分别用于存储BA_HIDDEN，BA_DIRECTORY，BA_REGULAR，BA_EXISTS），足以表达文件的这几种常用属性。java层获取对应的属性后，进行位运算就能知道这个文件的属性了。
```

文件读写以及FileDescriptor
文件描述符在unix系统上是非负的int，用于代表一个文件。java层的FileDescriptor中包裹了一个int fd。
读写文件都需要通过FileInputStream进行，构造函数中有一个open方法，对应c语言的方法在
[FileInputStream.c](https://github.com/openjdk-mirror/jdk7u-jdk/blob/master/src/share/native/java/io/FileInputStream.c)中
```c
JNIEXPORT void JNICALL
Java_java_io_FileInputStream_open(JNIEnv *env, jobject this, jstring path) {
    fileOpen(env, this, path, fis_fd, O_RDONLY);
}
```
fileOpen的实现在[io_util_md.c](https://github.com/openjdk-mirror/jdk7u-jdk/blob/master/src/solaris/native/java/io/io_util_md.c)中
```c
void
fileOpen(JNIEnv *env, jobject this, jstring path, jfieldID fid, int flags)
{
    WITH_PLATFORM_STRING(env, path, ps) {
        FD fd;

#if defined(__linux__) || defined(_ALLBSD_SOURCE)
        /* Remove trailing slashes, since the kernel won't */
        char *p = (char *)ps + strlen(ps) - 1;
        while ((p > ps) && (*p == '/'))
            *p-- = '\0';
#endif
        fd = JVM_Open(ps, flags, 0666); 
        if (fd >= 0) {
            SET_FD(this, fd, fid);
        } else {
            throwFileNotFoundException(env, path);
        }
    } END_PLATFORM_STRING(env, ps);
}
```
JVM_OPEN是jvm的方法，不属于jdk了，要去hotSpot里面查看对应的实现：
//  在/hotspot/src/share/vm/prims/jvm.cpp （cpp我不熟，据说这里面最终走的是 open64方法）

**这里要提一句，jvm不止oracle一家**，还包括OpenJDK，SUN JVM，IBM JVM，都是对java specification的implementation。


### 文件读写
java这边读取文件用的是FileInputStream，下面方法表示读取一个Byte
```java
private native int read0() throws IOException; 
```

对应openjdk的实现在[FileInputStream.c](https://github.com/AdoptOpenJDK/openjdk-jdk8u/blob/master/jdk/src/share/native/java/io/FileInputStream.c)文件中
```c
JNIEXPORT jint JNICALL
Java_java_io_FileInputStream_read0(JNIEnv *env, jobject this) {
    return readSingle(env, this, fis_fd);
}
```

[readSingle在io_util.c中](https://github.com/AdoptOpenJDK/openjdk-jdk8u/blob/master/jdk/src/share/native/java/io/io_util.c)

```c
jint
readSingle(JNIEnv *env, jobject this, jfieldID fid) {
    jint nread;
    char ret;
    FD fd = GET_FD(this, fid);
    if (fd == -1) {
        JNU_ThrowIOException(env, "Stream Closed");
        return -1;
    }
    nread = IO_Read(fd, &ret, 1);
    if (nread == 0) { /* EOF */
        return -1;
    } else if (nread == -1) { /* error */
        JNU_ThrowIOExceptionWithLastError(env, "Read error");
    }
    return ret & 0xFF;
}

// IO_Read指向io_util_md.c中的handleRead方法
ssize_t
handleRead(FD fd, void *buf, jint len)
{
    ssize_t result;
    RESTARTABLE(read(fd, buf, len), result);
    return result;
}
```

> c语言的read方法:
```
头文件：#include <unistd.h>
定义函数：ssize_t read(int fd, void * buf, size_t count);
函数说明：read()会把参数fd 所指的文件传送count 个字节到buf 指针所指的内存中. 若参数count 为0, 则read()不会有作用并返回0. 返回值为实际读取到的字节数, 如果返回0, 表示已到达文件尾或是无可读取的数据,此外文件读写位置会随读取到的字节移动.
```

[super.clone方法在openjdk中的实现](https://stackoverflow.com/questions/12032292/is-it-possible-to-find-the-source-for-a-java-native-method)

## 参考
[openjdk是如何读取.class文件的](https://fansunion.blog.csdn.net/article/details/13252309)
[openjdk源码分析](https://hunterzhao.io/)
[hotspot源码](https://github.com/openjdk-mirror/jdk7u-hotspot)