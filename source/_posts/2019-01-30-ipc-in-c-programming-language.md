---
title: C语言中多进程之间通信的方式
date: 2019-01-30 07:57:28
tags: [c, linux]
---

***进程是资源分配的最小单位，线程是CPU调度的最小单位***
![](https://api1.foster66.xyz/static/imgs/Prayercard_ZH-CN13472871640_1920x1080.jpg)

本文多数来自[c语言多进程编程](https://zfl9.github.io/c-multi-proc.html)

当Linux启动的时候，init是系统创建的第一个进程，这一进程会一直存在，直到我们关闭计算机；虽然后面systemd取代了init进程。后面的所有进程都是init进程fork出来的,linux下使用pstree可以看到所有的进程都是以systemd为根节点的
当进程调用fork的时候，Linux在内存中开辟出一片新的内存空间给新的进程，并将老的进程空间中的内容复制到新的空间中，此后两个进程同时运行；老进程成为新进程的父进程(parent process)，而相应的，新进程就是老进程的子进程(child process)；

<!--more-->

## fork的最简单实例
fork是系统调用，会有两次返回，分别是父进程和子进程。


```C
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

void print_process_message(){
    __pid_t myprocess_id = getpid();
    __uid_t uid = getuid();
    __gid_t ugid = getgid();
    printf("getpid = %d getuid= %d  getgid= %d \n",myprocess_id,uid, ugid);
}

int main(int argc, char const *argv[])
{
    int n =0;
    printf("before fork: n = %d\n",n);

    __pid_t fpid =fork();

    if(fpid <0 )
    {
        perror("fork error");
        exit(EXIT_FAILURE);
    }else if (fpid == 0)
    {
        n++;
        printf("child_proc(%d, ppid=%d): n= %d\n",getpid(),getppid(),n);
    } else
    {
        n--;
        printf("parent_proc(%d): n= %d\n",getpid(),n);
    }
    print_process_message();
    printf("quit_proc(%d) ...\n",getpid());
    return 0;
}
```

### fork和vfrok
fork创建子进程，把父进程数据空间、堆和栈复制一份；
vfork创建子进程，与父进程内存数据共享；
但是后来的fork也学聪明了，不是一开始调用fork就复制数据，而是只有在子进程要修改数据的时候，才进行复制，即copy-on-write；
所以我们现在也很少去用vfork，因为vfork的优势已经不复存在了；


## 孤儿进程和僵尸进程以及wait
正常的操作流程：子进程终结时会通知父进程，并通过return code告诉内核自己的退出信息，父进程知道后，有责任对该子进程使用***wait***系统调用，这个wait函数能够从内核中取出子进程的退出信息，并清空该信息在内核中所占据的空间；

***不正常的流程：***
父进程早于子进程挂掉，那么子进程就成了孤儿进程

如果程序写的糟糕，父进程忘记对子进程调用wait，子进程就成为僵尸(zombie)进程。（在htop里面看到state是Z）
当进程退出，释放大多数资源和它的父进程收集它的返回值、释放剩余资源这两段时间之间，子进程处于一个特殊状态，被称为僵尸进程；
每个进程都会经过一个短暂的僵尸状态，僵尸进程的最大危害就是会占用宝贵的PID资源，如果不及时清理，会导致无法再创建新的进程；

***解决僵尸进程的方法是干掉僵尸进程的父进程***，僵尸进程也就变成了孤儿进程，最终被init进程接管，init进程会负责wait这些孤儿进程，释放占用的资源。

## wait和waitpid函数
pid_t wait(int *status);：等待任意子进程退出，并捕获退出状态
pid_t waitpid(pid_t pid, int *status, int options);：等待子进程退出，并捕获退出状态
这两个函数返回的都是退出的子进程的id

```C
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <wait.h>

int main(int argc, char const *argv[],char *envp[])
{
    pid_t fpid = fork(), pid;
    if(fpid < 0)
    {
        perror("fork error");
        exit(EXIT_FAILURE);
    }
    else if(fpid ==0 )
    {
        sleep(5);
        exit(5);
    } else {
        int stat;
        for(;;){
            pid = waitpid(fpid,&stat,WNOHANG); //stat用于记录子进程的返回结果
            if(pid>0) {
                break;
            }else {
                printf("wait child proc ... \n");
                sleep(1);
            }
        }
        if(WIFEXITED(stat))//这个函数如果子进程正常退出的话就返回真
        {
            printf("child_proc(%d): exit_code :%d\n",pid,WEXITSTATUS(stat));
        }
    }
    return 0;
}
```

**处理子进程的退出有以下两种方式：**
第一种：通过信号处理函数signal()，如可以忽略子进程的SIGCHLD信号来防止僵尸进程的产生：signal(SIGCHLD, SIG_IGN);
第二种：通过调用wait()、waitpid()函数，来回收子进程，防止产生僵尸进程，占用**PID等宝贵的系统资源**；

经常在parent process中看到wait(NULL)的操作，意思就是让父进程等child process 返回exit status。
[wait(NULL)是什么意思](https://stackoverflow.com/questions/42426816/how-does-waitnull-exactly-work?rq=1)
```
wait(NULL) will block parent process until any of its children has finished. If child terminates before parent process reaches wait(NULL) then the child process turns to a zombie process until its parent waits on it and its released from memory.

If parent process doesn't wait for its child, and parent finishes first, then the child process becomes orphan and is assigned to init as its child. And init will wait and release the process entry in the process table.

In other words: parent process will be blocked until child process returns an exit status to the operating system which is then returned to parent process. If child finishes before parent reaches wait(NULL) then it will read the exit status, release the process entry in the process table and continue execution until it finishes as well.
```

### exec系列函数
**fork出来一个新的进程当然是要干活的**，就要用到exec系统调用
exec系统调用是以新的进程空间替换现在的进程空间，但是pid不变，还是原来的pid，相当于换了个身体，但是名字不变；
调用exec后，系统会申请一块新的进程空间来存放被调用的程序，然后当前进程会携带pid跳转到新的进程空间，并从main函数开始执行，旧的进程空间被回收；
exec用被执行的程序完全替换调用它的程序的影像。fork创建一个新的进程就产生了一个新的PID，
exec启动一个新程序，替换原有的进程，因此这个新的被exec执行的进程的PID不会改变，

```C
#include <stdio.h>
#include <unistd.h>

int main(int arg,char **args)
{
    char *argv[]={"ls","-al","/usr/include/linux",NULL};//传递给执行文件的参数数组，这里包含执行文件的参数 
    char *envp[]={0,NULL};//传递给执行文件新的环境变量数组
    execve("/bin/ls",argv,envp);
}
```
这个函数的参数
```
int   execve( char *pathname,char *argv[],char *envp[])
```

### exit(可以注册进程退出的时候的回调函数)
exit是系统调用级别的，用于进程运行的过程中，随时结束进程；
return是语言级别的，用于调用堆栈的返回，返回上一层调用；
在main函数中调用exit(0)等价于return 0；
_exit()函数的作用最为简单：直接使进程停止运行，清除其使用的内存空间，并销毁其在内核中的各种数据结构；
exit()函数则在这些基础上作了一些包装，在执行退出之前加了若干道工序；
exit()函数与_exit()函数最大的区别就在于exit()要检查文件的打开情况，把文件缓冲区中的内容写回文件，就是”清理I/O缓冲”；

按照ANSI C的规定，一个进程可以登记至多32个函数，这些函数将由exit自动调用；（也就是说在调用exit的时候会调用这些回调函数）
分为atexit和on_exit
```C
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <signal.h>

void func1(void){
    printf("<atexit> func1 getpid = %d \n",getpid());
}

void func2(void){
    printf("<atexit> func2 getpid = %d \n",getpid());
}

void func3(void){
    printf("<atexit> func3 getpid = %d \n",getpid());
}

void func(int status, void *str){
    printf("<on_exit> exit_code: %d, arg: %s getpid = %d \n", status, (char *)str,getpid());
}

int main(void){
    signal(SIGCHLD, SIG_IGN);

    on_exit(func, "on_exit3");
    on_exit(func, "on_exit2");
    on_exit(func, "on_exit1");

    atexit(func3);
    atexit(func2);
    atexit(func1);

    pid_t pid;
    pid = fork();
    if(pid < 0){
        perror("fork error");
        exit(EXIT_FAILURE);
    }else if(pid == 0){
        exit(0);
    }else{
        sleep(3);
    }

    return 0;
}
```

***输出：***
```
<atexit> func1 getpid = 13508
<atexit> func2 getpid = 13508
<atexit> func3 getpid = 13508
<on_exit> exit_code: 0, arg: on_exit1 getpid = 13508
<on_exit> exit_code: 0, arg: on_exit2 getpid = 13508
<on_exit> exit_code: 0, arg: on_exit3 getpid = 13508
<atexit> func1 getpid = 13507
<atexit> func2 getpid = 13507
<atexit> func3 getpid = 13507
<on_exit> exit_code: 0, arg: on_exit1 getpid = 13507
<on_exit> exit_code: 0, arg: on_exit2 getpid = 13507
```
也就是说fork出来的子进程会继承父进程的终止处理函数、信号处理设置；


## Daemon守护进程
Linux Daemon进程是运行在后台的一种特殊进程。
一个守护进程的父进程是init进程，因为它真正的父进程在fork出子进程后就先于子进程exit退出了，***所以它是一个由init继承的孤儿进程；***
守护进程是非交互式程序，没有控制终端，所以任何输出，无论是向标准输出设备stdout还是标准出错设备stderr的输出都需要特殊处理；
守护进程的名称通常以d结尾，比如sshd、xinetd、crond等；

头文件：unistd.h
***int daemon(int nochdir, int noclose);***

## system和popen
***system是去执行一个shell命令***
system()函数调用/bin/sh来执行参数指定的命令，/bin/sh一般是一个软连接，指向某个具体的shell，比如bash；
```C
system("cat /etc/sysctl.conf");；
```
实际上system()函数执行了三步操作：
fork一个子进程；
在子进程中调用exec函数去执行command；
在父进程中调用wait去等待子进程结束；
一个不好的地方是system()，并不能获取命令执行的输出结果，只能得到执行的返回值；

**popen**
标准I/O函数库提供了popen函数，它启动另外一个进程去执行一个shell命令行；
这里我们称调用popen的进程为父进程，由popen启动的进程称为子进程；

popen函数还创建一个管道用于父子进程间通信；父进程要么从管道读信息，要么向管道写信息，至于是读还是写取决于父进程调用popen时传递的参数；
```C
#include <stdio.h>

FILE *popen(const char *command, const char *type);
/*
函数功能：popen()会调用fork()产生子进程，然后从子进程中调用/bin/sh -c来执行参数command的指令;
          参数type可使用"r"代表读取，"w"代表写入;
          依照此type值，popen()会建立管道连到子进程的标准输出设备或标准输入设备，然后返回一个文件指针;
          随后进程便可利用此文件指针来读取子进程的输出设备或是写入到子进程的标准输入设备中;
返回值：若成功则返回文件指针，否则返回NULL，错误原因存于errno中
*/

int pclose(FILE *stream);
/*
函数功能：pclose()用来关闭由popen所建立的管道及文件指针；参数stream为先前由popen()所返回的文件指针;
返回值：若成功则返回shell的终止状态(也即子进程的终止状态)，若出错返回-1，错误原因存于errno中;
*/
```

**这里正式使用到了进程之间的管道通信**
```C
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>


int main(int argc, char *argv[]){
    if(argc < 2){
        fprintf(stderr, "usage: %s <cmd>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    char output[1024+1];

    FILE *pp = popen(argv[1], "r");
    if(pp == NULL){
        perror("popen error");
        exit(EXIT_FAILURE);
    }

    int nread = fread(output, 1, 1024, pp); //父进程通过文件指针读取子进程的输出设备。
    int status = pclose(pp);
    if(status < 0){
        perror("pclose error");
        exit(EXIT_FAILURE);
    }

    output[nread] = '\0';
    if(WIFEXITED(status)){
        printf("status: %d\n%s", WEXITSTATUS(status), output);
    }
    return 0;
}
```

## signal信号
信号(signal)是一种软中断，信号机制是进程间通信的一种方式，采用**异步通信方式**
用kill -l　可以查看可以发出的信号
```
$ kill -l           
HUP INT QUIT ILL TRAP ABRT BUS FPE KILL USR1 SEGV USR2 PIPE ALRM TERM 16 CHLD CONT STOP TSTP TTIN TTOU URG XCPU XFSZ VTALRM PROF WINCH POLL 30 SYS
```
挑几个重要的:
SIGINT(2) 中断　（CTRL + C）
SIGKILL(9) kill信号（强杀，进程不能阻止）
SIGPIPE(13) 管道破损，没有读端的管道写数据,就是那个brokenpipe。**默认是杀进程的，所以网络编程中要处理这个信号。**（当服务器close一个连接时，若client端接着发数据。根据TCP协议的规定，会收到一个RST响应，client再往这个服务器发送数据时，系统会发出一个SIGPIPE信号给进程，告诉进程这个连接已经断开了，不要再写了。）
SIGTERM（１５）　终止信号，这个不是强制的，它可以被捕获和解释（或忽略）的过程。类似于和这个进程商量一下，让它退出。不听话的话可以用９杀掉。
SIGCHLD(１７) 子进程退出。　默认忽略
SIGSTOP（１９）　进程停止　不能被忽略、处理和阻塞
SIGPWR(30) 关机　默认忽略
进程可以注册收到信号时的处理函数
```C
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <unistd.h>

void handle_signal(int signum){
    printf("received signal: %d\n", signum);
    exit(0);
}

int main(void){
    signal(SIGINT, handle_signal);

    for(;;){
        printf("running ... \n");
        sleep(1);
    }
    return 0;
}
```
这里添一句，cpython因为是用Ｃ语言写的，在处理信号这方面几乎是一模一样。
[注册signal_handler](https://stackabuse.com/handling-unix-signals-in-python/)

> ＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝介绍进程的基础知识到此结束


## 进程之间的通信

### 使用管道
管道是FIFO的
下面是创建一个匿名管道的代码
```C
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>

int main(int argc, char *argv[]){
    if(argc < 3){
        fprintf(stderr, "usage: %s parent_sendmsg child_sendmsg\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    int pipes[2];
    if(pipe(pipes) < 0){
        perror("pipe");
        exit(EXIT_FAILURE);
    }

    pid_t pid = fork();
    if(pid < 0){
        perror("fork");
        exit(EXIT_FAILURE);
    }else if(pid > 0){
        char buf[BUFSIZ + 1];
        int nbuf;
        strcpy(buf, argv[1]);
        write(pipes[1], buf, strlen(buf));

        sleep(1); //这里sleep是为了让子进程有时间把管道中的数据读走，不然数据就会被底下的父进程的read读走.
        //因为实质上内核中只有一个管道缓冲区，是父进程创建的，只不过子进程同时拥有了它的引用

        nbuf = read(pipes[0], buf, BUFSIZ);
        buf[nbuf] = 0;
        printf("parent_proc(%d) recv_from_child: %s\n", getpid(), buf);

        close(pipes[0]);
        close(pipes[1]);
    }else if(pid == 0){
        char buf[BUFSIZ + 1];
        int nbuf = read(pipes[0], buf, BUFSIZ);
        buf[nbuf] = 0;
        printf("child_proc(%d) recv_from_parent: %s\n", getpid(), buf);

        strcpy(buf, argv[2]);
        write(pipes[1], buf, strlen(buf));

        close(pipes[0]);
        close(pipes[1]);
    }

    return 0;
}
```
> ./a.out parent_say_tochild child_say_to_parent

实际中为了实现双向通信，应该准备两根管道，一根负责从父进程往子进程写数据（同时子进程从这里读取数据），一根负责从子进程往父进程写数据（父进程也从这里读数据）

管道默认是阻塞模式的，fcntl(fd, F_SETFL, flags | O_NONBLOCK);可以设置非阻塞的管道，这个跟socket很像。

### 命名管道
上面说的匿名管道要求这些进程都是由同一个祖先创建的。所以在不相干的进程之间交换数据就不方便了，为此，我们需要命名管道
命名管道也被称为FIFO文件
我们可以使用以下两个函数之一来创建一个命名管道，原型如下：
```C
头文件：sys/types.h、sys/stat.h
int mkfifo(const char *filename, mode_t mode);
int mknod(const char *filename, mode_t mode | S_IFIFO, (dev_t)0);
返回值：执行成功返回0，失败返回-1，并设置errno
```
注意这样的方式是在文件系统中创建了一个真实的文件, 可以对其进行读写操作(注意不能同时读写)
sender.c
```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

int main(int argc, char *argv[]){
    if(argc < 3){
        fprintf(stderr, "usage: %s fifo_file filename\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    int fifo = open(argv[1], O_WRONLY);
    if(fifo < 0){
        perror("open");
        exit(EXIT_FAILURE);
    }

    FILE *fp = fopen(argv[2], "rb");
    if(fp == NULL){
        perror("fopen");
        exit(EXIT_FAILURE);
    }

    char buf[BUFSIZ];
    int nbuf;
    while((nbuf = fread(buf, 1, BUFSIZ, fp)) > 0){
        write(fifo, buf, nbuf);
    }

    fclose(fp);
    close(fifo);
    return 0;
}

```
receiver.c
```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
int main(int argc, char *argv[]){
    if(argc < 3){
        fprintf(stderr, "usage: %s fifo_file filename\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    int fifo = open(argv[1], O_RDONLY);
    if(fifo < 0){
        perror("fifo");
        exit(EXIT_FAILURE);
    }

    FILE *fp = fopen(argv[2], "wb");
    if(fp == NULL){
        perror("fopen");
        exit(EXIT_FAILURE);
    }

    char buf[BUFSIZ];
    int nbuf;
    while((nbuf = read(fifo, buf, BUFSIZ)) > 0){
        printf("i got something %s\n", buf);
        fwrite(buf, nbuf, 1, fp);
    }

    close(fifo);
    fclose(fp);
    return 0;
}
```
```
mkfifo fifo ##使用mkfifo这个命令创建一个管道文件
./bin/sender fifo /var/log/syslog ###把/var/log/syslog这个文件里面的内容读出来，通过fifo这个文件传到另一个进程。注意到这里卡在这里了
./bin/receiver fifo syslog.copy ##从管道文件中读取输出，写到syslog.copy文件中.注意到这里读完了之后前面卡住的进程成功退出了
```

这里还要提到命名管道的安全问题，有可能存在多个进程同时往一个FIFO文件写数据，这样会存在数据顺序错乱的问题。解决方案就是每次写入的数据的大小保持在PIPE_BUF大小以内，要么全部写入，要么一个字节也不写入。


## 共享内存
***概念:***
>什么是共享内存
顾名思义，共享内存就是允许两个不相关的进程访问同一个逻辑内存；共享内存是在两个正在运行的进程之间共享和传递数据的一种非常有效的方式；
不同进程之间共享的内存通常安排为同一段物理内存，进程可以将同一段共享内存连接到它们自己的地址空间中，所有进程都可以访问共享内存中的地址；
而如果某个进程向共享内存写入数据，所做的改动将立即影响到可以访问同一段共享内存的任何其他进程；
特别提醒：共享内存并未提供同步机制，也就是说，在第一个进程结束对共享内存的写操作之前，并无自动机制可以阻止第二个进程开始对它进行读取；所以我们通常需要用其他的机制来同步对共享内存的访问，例如信号量、互斥锁；

***共享内存的函数接口***
**
头文件：sys/types.h、sys/ipc.h、sys/shm.h
int shmget(key_t shm_key, size_t shm_size, int shm_flg);：创建共享内存
shm_key用来标识一块共享内存：
shm_size：输入参数，共享内存的大小（单位：byte）：注意内存分配的单位是页（一般为4kb，可通过getpagesize()获取）；也就是说如果shm_size为1，那么也会分配4096字节的内存；只获取共享内存时，shm_size可指定为0；**



## Unix domain socket
socket原本是为了网络通讯设计的，但是后来在socket的框架上发展出一种IPC机制，就是UNIX Domain Socket；
虽然网络socket也可用于同一台主机的进程间通讯（通过loopback地址127.0.0.1），但是UNIX Domain Socket用于IPC更有效率：
1. 不需要经过网络协议栈；
2. 不需要打包拆包；
3. 不需要计算校验和；
4. 不需要维护序号和应答；

这是因为IPC机制本质上是可靠的通讯，而网络协议是为不可靠的通讯设计的；
UNIX Domain Socket也提供面向流和面向数据报两种API接口，类似TCP和UDP，但是面向数据报的UNIX Domain Socket也是可靠的，消息既不会丢失也不会顺序错乱；
使用UNIX Domain Socket的过程和网络socket十分相似，也要先调用socket()创建一个socket文件描述符，address family指定为AF_UNIX，type可以选择SOCK_STREAM或SOCK_DGRAM，protocol参数仍然指定为0即可；
UNIX Domain Socket与网络socket编程最明显的不同在于地址格式不同，用结构体<code>sockaddr_un</code>表示；
网络编程的socket地址是IP地址加端口号，而UNIX Domain Socket的地址是一个socket类型的文件在文件系统中的路径，这个socket文件由bind()调用创建，如果调用bind()时该文件已经存在，则bind()错误返回；

unix_domain_server.c
```C
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <ctype.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <netdb.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <signal.h>
#include <sys/wait.h>

#define SOCK_PATH "/run/echo.sock"
#define BUF_SIZE 1024

int listenfd;
void handle_signal(int signo);

int main(void){
    signal(SIGINT, handle_signal);
    signal(SIGHUP, handle_signal);
    signal(SIGTERM, handle_signal);

    if((listenfd = socket(AF_UNIX, SOCK_STREAM, 0)) < 0){
        perror("socket");
        exit(EXIT_FAILURE);
    }

    struct sockaddr_un servaddr;
    memset(&servaddr, 0, sizeof(servaddr));
    servaddr.sun_family = AF_UNIX;
    strcpy(servaddr.sun_path, SOCK_PATH);

    unlink(SOCK_PATH);
    if(bind(listenfd, (struct sockaddr *)&servaddr, sizeof(servaddr)) < 0){ //因为这里要在/var/目录下创建一个临时文件，这个程序需要sudo运行
        perror("bind");
        exit(EXIT_FAILURE);
    }
    chmod(SOCK_PATH, 00640);

    if(listen(listenfd, SOMAXCONN) < 0){
        perror("listen");
        exit(EXIT_FAILURE);
    }

    int connfd, nbuf;
    char buf[BUF_SIZE + 1];
    for(;;){
        if((connfd = accept(listenfd, NULL, NULL)) < 0){
            perror("accept");
            continue;
        }

        nbuf = recv(connfd, buf, BUF_SIZE, 0);
        buf[nbuf] = 0;
        printf("new msg: \"%s\"\n", buf);
        send(connfd, buf, nbuf, 0);

        close(connfd);
    }

    return 0;
}

void handle_signal(int signo){
    if(signo == SIGINT){
        fprintf(stderr, "received signal: SIGINT(%d)\n", signo);
    }else if(signo == SIGHUP){
        fprintf(stderr, "received signal: SIGHUP(%d)\n", signo);
    }else if(signo == SIGTERM){
        fprintf(stderr, "received signal: SIGTERM(%d)\n", signo);
    }

    close(listenfd);
    unlink(SOCK_PATH);
    exit(EXIT_SUCCESS);
}
```
unix_domain_client.c
```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <ctype.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <netdb.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <signal.h>
#include <sys/wait.h>

#define SOCK_PATH "/run/echo.sock"
#define BUF_SIZE 1024

int main(int argc, char *argv[]){
    if(argc < 2){
        fprintf(stderr, "usage: %s msg\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    int sockfd;
    if((sockfd = socket(AF_UNIX, SOCK_STREAM, 0)) < 0){
        perror("socket");
        exit(EXIT_FAILURE);
    }

    struct sockaddr_un servaddr;
    memset(&servaddr, 0, sizeof(servaddr));
    servaddr.sun_family = AF_UNIX;
    strcpy(servaddr.sun_path, SOCK_PATH);

    if(connect(sockfd, (struct sockaddr *)&servaddr, sizeof(servaddr)) < 0){
        perror("connect");
        exit(EXIT_FAILURE);
    }

    char buf[BUF_SIZE + 1];
    int nbuf;

    nbuf = strlen(argv[1]);
    send(sockfd, argv[1], nbuf, 0);
    nbuf = recv(sockfd, buf, BUF_SIZE, 0);
    buf[nbuf] = 0;
    printf("echo msg: \"%s\"\n", buf);

    close(sockfd);
    return 0;
}
```

上述程序实现了通过uninx domain socket的client-server 数据传输，就像是通过/var/echo.sock这个文件传输数据。印象中uwsi也是这样实现nginx和django进程的通信。


### 信号量
信号量是用来调协进程对共享资源的访问的，程序对信号量的操作都是<code>原子操作</code>，并且只能对它进行等待和发送操作。
当请求一个使用信号量来表示的资源时，进程需要先读取信号量的值来判断资源是否可用。大于0，资源可以请求，等于0，无资源可用，进程会进入睡眠状态直至资源可用。
当进程不再使用一个信号量控制的共享资源时，信号量的值+1，对信号量的值进行的增减
操作均为原子操作，这是由于信号量主要的作用是维护资源的互斥或多进程的同步访问。而在信号量的创建及初始化上，不能保证操作均为原子性。


## 总结
**现在把进程之间传递信息的各种途径（包括各种IPC机制）总结如下：
父进程通过fork可以将打开文件的描述符传递给子进程
子进程结束时，父进程调用wait可以得到子进程的终止信息
几个进程可以在文件系统中读写某个共享文件，也可以通过给文件加锁来实现进程间同步
进程之间互发信号，一般使用SIGUSR1和SIGUSR2实现用户自定义功能
管道
FIFO
mmap函数，几个进程可以映射同一内存区
SYS V IPC，以前的SYS V UNIX系统实现的IPC机制，包括消息队列、信号量和共享内存，现在已经基本废弃
Linux内核继承和兼容了丰富的Unix系统进程间通信（IPC）机制。有传统的管道（Pipe）、信号（Signal）和跟踪（Trace），这三项通信手段只能用于父进程与子进程之间，或者兄弟进程之间；后来又增加了命令管道（Named Pipe），使得进程间通信不再局限于父子进程或者兄弟进程之间；为了更好地支持商业应用中的事务处理，在AT&T的Unix系统V中，又增加了三种称为“System V IPC”的进程间通信机制，分别是报文队列（Message）、共享内存（Share Memory）和信号量（Semaphore）；后来BSD Unix对“System V IPC”机制进行了重要的扩充，提供了一种称为插口（Socket）的进程间通信机制。
UNIX Domain Socket是目前最广泛使用的IPC机制**

[Linux现有的所有进程间IPC方式](https://www.zhihu.com/question/39440766/answer/89210950)
1. 管道：在创建时分配一个page大小的内存，缓存区大小比较有限；
2. 消息队列：信息复制两次，额外的CPU消耗；不合适频繁或信息量大的通信；
3. 共享内存：无须复制，共享缓冲区直接付附加到进程虚拟地址空间，速度快；但进程间的同步问题操作系统无法实现，必须各进程利用同步工具解决；
4. 套接字：作为更通用的接口，传输效率低，主要用于不通机器或跨网络的通信；
5. 信号量：常作为一种锁机制，防止某进程正在访问共享资源时，其他进程也访问该资源。因此，主要作为进程间以及同一进程内不同线程之间的同步手段。
6. 信号: 不适用于信息交换，更适用于进程中断控制，比如非法内存访问，杀死某个进程等；

## 参考
[c语言多进程编程](https://zfl9.github.io/c-multi-proc.html)
