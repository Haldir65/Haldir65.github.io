---
title: page-size and block size
date: 2018-12-02 21:42:24
tags: [linux,tools,tbd]
---

page size（内存相关）和block size(文件系统相关)的一些点
![](https://www.haldir66.ga/static/imgs/scenery1511100718415.jpg)
<!--more-->
wiki上说
Page size常由processor的架构决定的，操作系统管理内存的最小单位是一个Page size(应用程序申请分配内存时，操作系统实际分配的内存是page-size的整数倍)


[Block size vs. page size](http://forums.justlinux.com/showthread.php?3261-Block-size-vs-page-size)
>  block size concerns storage space on a filesystem.
Page size is, I believe, architecture-dependent, 4k being the size for IA-32 (x86) machines. For IA-64 architecture, I'm pretty sure you can set the page size at compile time, with 8k or 16k considered optimal. Again, I'm not positive, but I think Linux supports 4,8,16, and 64k pages.
Block size is a function of the filesystem in use. Many, if not all filesystems allow you to choose the block size when you format, although for some filesystems the block size is tied to/dependent upon the page size.
Minimun block size is usually 512 bytes, the allowed values being determined by the filesystem in question.


unix系统中查看系统的page size
> getconf PAGESIZE ## X86架构的cpu上一般是4096byte


一个很有意思的现象是，java BufferedInputStream的默认buffer数组大小是8192，okio 的segment的默认size也是8192，这些都是以byte为单位的。找到一个合理的[解释](https://stackoverflow.com/questions/37404068/why-is-the-default-char-buffer-size-of-bufferedreader-8192)。大致意思是8192 = 2^13, windows和linux上这个大小正好占用两个分页文件(8kB)。


## block size(硬盘块)
摘抄一段来自[深入浅出腾讯云CDN：缓存篇](https://zhuanlan.zhihu.com/p/26077257)的话：
> 不管SSD盘或者SATA盘都有最小的操作单位，可能是512B，4KB，8KB。如果读写过程中不进行对齐，底层的硬件或者驱动就需要替应用层来做对齐操作，并将一次读写操作分裂为多次读写操作。


[什么是内存对齐，为什么要对齐？](https://www.zfl9.com/c-struct.html)

现代计算机中内存空间都是按照 byte 划分的，从理论上讲似乎对任何类型的变量的访问可以从任何地址开始，但实际情况是在访问特定变量的时候经常在特定的内存地址访问，这就需要各类型数据按照一定的规则在空间上排列，而不是顺序的一个接一个的排放，这就是对齐。
对齐的作用和原因：各个硬件平台对存储空间的处理上有很大的不同。一些平台对某些特定类型的数据只能从某些特定地址开始存取。其他平台可能没有这种情况，但是最常见的是如果不按照适合其平台的要求对数据存放进行对齐，会在存取效率上带来损失。
比如有些平台每次读都是从偶地址开始，如果一个 int 型（假设为32位）如果存放在偶地址开始的地方，那么一个读周期就可以读出，而如果存放在奇地址开始的地方，就可能会需要 2 个读周期，并对两次读出的结果的高低字节进行拼凑才能得到该 int 数据。显然在读取效率上下降很多，这也是空间和时间的博弈。
“内存对齐”应该是编译器的“管辖范围”。
编译器为程序中的每个“数据单元”安排在适当的位置上。
**但是C语言的一个特点就是太灵活，太强大，它允许你干预“内存对齐”**

对齐规则(内存相关)
每个特定平台上的编译器都有自己默认的“对齐系数”，我们可以通过预处理指令#pragma pack(n), n=1, 2, 4, 8, 16...来改变这一系数，这个 n 就是对齐系数

数据成员对齐规则：结构(struct)或联合(union)的数据成员，第一个数据成员放在 offset 为 0 的地方，以后的每个数据成员的对齐按照#pragma pack(n)指定的 n 值和该数据成员本身的长度 len = sizeof(type) 中，较小的那个进行，如果没有显示指定n值，则以len为准，进行对齐
结构/联合整体对齐规则：在数据成员对齐完成之后，结构/联合本身也要对齐，对齐按照#pragma pack(n)指定的n值和该结构/联合最大数据成员长度max_len_of_members中，较小的那个进行，如果没有显示指定n值，则以max_len_of_members为准，进行对齐
结合1、2可推断：当n值均超过(或等于)所有数据成员的长度时，这个n值的大小将不产生任何效果


### 从fsize看block
```c
#include <stdio.h>
#include <stdlib.h>
#define N 1024
long fsize(FILE *fp){
    fseek(fp, 0, SEEK_END);
    return ftell(fp);
}

int main(){
    printf("enter the file absolute path: \n ");
    char str[N];
    scanf("%s",str);
    printf("\n the file name you choose is: %s\n ",str);
    FILE *fp = fopen(str, "rb");
    if(fp == NULL ){
        printf("error opening file \n");
        exit(-1);
    }
    printf("len: %ld bytes\n", fsize(fp));
    fclose(fp);
    return 0;
}
```
简单的一个用fsize函数获取文件的bytes数的函数

./a.out sample.txt ## len: 2527 bytes
du sample.txt 
4 sample.txt
du -b sample.txt
2527 sample.txt

简单的来说，fsize获取的大小和du的结果不一致。但du -b 就一样了。这事主要是因为block size的缘故,文件系统分配磁盘存储的时候是以block为单位的。所以经常看到windows里面显示一个文件的大小和“占用的磁盘空间”。就是因为block的原因。[更详细的解释在这里](https://unix.stackexchange.com/questions/120311/why-are-there-so-many-different-ways-to-measure-disk-usage)

> For files, ls -l file shows (among other things) the size of file in bytes, while du -k file shows the space occupied by file on disk (in units of 1 kB = 1204 bytes). Since disk space is allocated in blocks, the size indicated by du -k is always slightly larger than the space indicated by  ls -kl (which is the same as ls -l, but in 1 kB units).

> For directories, ls -ld dir shows (among other things) the size of the list of filenames (together with a number of attributes) of the files and subdirectories in dir. This is just the list of filenames, not the files' or subdirectories' contents. So this size increases when you add files to dir (even when files are empty), but it stays unchanged when one of the files in dir grows.

> However, when you delete files from dir the space from the list is not reclaimed immediately, but rather the entries for deleted files are marked as unused, and are later recycled (this is actually implementation-dependent, but what I described is pretty much the universal behavior these days). That's why you may not see any changes in ls -ld output when you delete files until much later, if ever.

> Finally, du -ks dir shows (an estimate of) the space occupied on disk by all files in dir, together with all files in all of dir's subdirectories, in 1 kB = 1024 bytes units. Taking into account the description above, this has no relation whatsoever with the output of ls -kld dir.


linux上是ext4文件系统
应用程序调用read()方法，系统会通过中断从用户空间进入内核处理流程，然后经过VFS(Virtual File System，虚拟文件系统)、具体文件系统、页缓存Page Cache。VFS主要是用于实现屏蔽具体的文件系统，为应用程序的操作提供一个统一的接口。
Page Cache(页缓存)，读文件的时候，会先看一下它是不是已经在Page Cache里面，如果命中了的话，就不会去读取磁盘。通过/proc/meminfo文件可以查看缓存的内存占用情况，当系统内存不足的时候，系统会回收这部分内存，I/O的性能就会降低。


这本应该是一篇关于操作系统原理，内核简介的文章,to be complemented



## 参考
- [ ] [Paging Technique : Memory management in Operating System](https://www.youtube.com/watch?v=0Rf5Jc61ArM)
- [深入理解 ext4 等 Linux 文件系统](https://zhuanlan.zhihu.com/p/44267768)
- [Linux 的 EXT4 文件系统的历史、特性以及最佳实践](https://zhuanlan.zhihu.com/p/27875337)


https://zhuanlan.zhihu.com/p/52054044
https://zhuanlan.zhihu.com/p/35879028

[what a c programmer should know about memory](https://marek.vavrusa.com/memory/)
