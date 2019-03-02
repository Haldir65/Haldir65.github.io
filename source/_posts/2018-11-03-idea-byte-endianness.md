---
title: 网络传输的字节序问题
date: 2018-11-03 10:38:04
tags:
---
字节序（Endianness），在计算机科学领域中，是跨越***多字节***的程序对象的存储规则。 

![](https://haldir66.ga/static/imgs/ship_docking_along_side_bay.jpg)
<!--more-->

## 首先确认下c语言下基本数据类型大小
```c
printf("sizeof(int)= %ld\n",sizeof(int));
printf("sizeof(char)= %ld\n",sizeof(char));
printf("sizeof(long)= %ld\n",sizeof(long));
printf("sizeof(float)= %ld\n",sizeof(float));
printf("sizeof(short)= %ld\n",sizeof(short));
```
>sizeof(int)= 4
sizeof(char)= 1
sizeof(long)= 8
sizeof(float)= 4
sizeof(short)= 2

## 来看一下c语言这边用socket以int，long的形式发送数据，Python这边接收会是怎么样的

c语言的server长这样
```c
#include <stdio.h>
#include <netinet/in.h>
#include <sys/socket.h> // socket
#include <sys/types.h>  // 基本数据类型
#include <unistd.h> // read write
#include <string.h>
#include <stdlib.h>
#include <fcntl.h> // open close
#include <sys/shm.h>

#include <signal.h>

#define PORT 7037
#define SERV "0.0.0.0"
#define QUEUE 20
#define BUFF_SIZE 1024


int sockfd;

int main(int argc,char *argv[ ]){

        signal(SIGINT,handle_signal);
        int count = 0; // 计数
        // 定义 socket
        sockfd = socket(AF_INET,SOCK_STREAM,0);
        // 定义 sockaddr_in
        struct sockaddr_in skaddr;
        skaddr.sin_family = AF_INET; // ipv4
        skaddr.sin_port   = htons(PORT);
        skaddr.sin_addr.s_addr = inet_addr(SERV);
        // bind，绑定 socket 和 sockaddr_in
        if( bind(sockfd,(struct sockaddr *)&skaddr,sizeof(skaddr)) == -1 ){
                perror("bind error");
                exit(1);
        }

        // listen，开始添加端口
        if( listen(sockfd,QUEUE) == -1 ){
                perror("listen error");
                exit(1);
        }

        // 客户端信息
        char buff[BUFF_SIZE];
        struct sockaddr_in claddr;
        socklen_t length = sizeof(claddr);


        while(1){
                int sock_client = accept(sockfd,(struct sockaddr *)&claddr, &length);
                printf("%d\n",++count);
                if( sock_client <0 ){
                        perror("accept error");
                        exit(1);
                }
                int a[3]={1,2,3}; //在这里发送出byte数组
                send(sock_client,(char*)a,sizeof(a),0);
                close(sock_client);
        }
        fputs("have a nice day",stdout);
        close(sockfd);
        return 0;
}

```

python的client长这样：
```python
#!/usr/bin/python
# -*- coding: UTF-8 -*-
import socket
# 创建一个socket:
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
# 建立连接:
s.connect(('192.168.1.45', 7037))
s.send(b'GET / HTTP/1.1\r\nHost: www.sina.com.cn\r\nConnection: close\r\n\r\n')
# 接收数据:
buffer = []
while True:
    d = s.recv(1) ##其实这里应该是有误区的，，recv并不是从socket里直接读数据，recv只是从tcp的buffer中(已经帮我们转成了小端，所以这事应该得抓包才能看懂）
    t = ''
    for x in d:
        print(format(x,'b'))
    if d:
        buffer.append(d)
    else:
        break
data = b''.join(buffer)
print(data)
s.close()
```

在局域网内的两台电脑,server跑在mac上,client跑在win10
client这边打印出了
```
1    
0
0
0
===我是四个byte等于一个int的手动分割线===
10
0
0
0
===我是四个byte等于一个int的手动分割线===
11
0
0
0
```


前四个字节是"1"
1   0   0   0 
0   0   0   1  -> 显然是1

中间四个字节是"2"
10  0   0   0
0   0   0   10 -> 显然是2

最后四个字节是"3"
11  0   0   0
0   0   0   11 -> 显然是3

这个实验其实没有证明什么，c语言端发出的int[3] = {1, 2, 3}在走tcp层的时候其实是[0001, 0002, 0003]这么发的，达到达客户端的时候，客户端的tcp buffer收到了之后手动把每个转成小端[1000, 2000,3000] ，应用层程序读取的时候是从这个buffer里面读取的



这里如果把c语言的server改一下
```c
float a[3]={1,2,3}; //在这里发送出byte数组
send(sock_client,(char*)a,sizeof(a),0);
```
client一字不改，得到的是
```
0
0
10000000
111111
===我是四个byte等于一个float的手动分割线===
0
0
0
1000000
===我是四个byte等于一个float的手动分割线===
0
0
1000000
1000000
```

这个其实跟float是如何表示小数有关了，float有几个bit是专门给小数点后面的数值和指数准备的。
float是4个byte，这32位是这么分的：
1bit（符号位） 8bits（指数位） 23bits（尾数位）（内存中就长这样）

改成long呢，short呢？
改成long
```
1    
0
0
0
0
0
0
0
===我是八个byte等于一个long的手动分割线===
10
0
0
0
0
0
0
0
===我是八个byte等于一个long的手动分割线===
11
0
0
0
0
0
0
0
```

问题已经很清楚了。
上述是把数字当做int,long,float这种数据类型来发送，但如果是把123这三个数字当做"123"这种字符串，数字1其实只用一个byte(utf-8下)就解决了，也就不存在什么字节序的问题了

如C编写的进程和Java编写的进程间通信，(JVM也是大端）。在主机和网络字节序的互相转化主要涉及IP地址和端口。c语言写server要老老实实去转换ip地址和端口的字节序，这也是为了遵守规范
```c
#include <netstat/in.h>
unsigned long int htonl(unsigned long int hostlong);
unsigned short  int htons(unsigned short int hostshort);
unsigned long int ntohl(unsigned long int netlong);
unsigned short int ntohs(unsigned short int netshort);
```
网络字节序是一种规定，它规定了传输的数据应该按照大端，因为通信双方的字节序其实是不确定的，但是按照规定我们都认为接收到的数据都是大端，即遵守规定的顺序，这样老老实实地通过htons系列函数处理格式化的数据（如int）保证了不会出现任何错误。

但是，我们自己写的C/S因为都是小端，所以即使没有遵守规定，依然可以用，但这样并不规范，有潜在的隐患。

而对于IP地址或者端口，因为这些数据的处理全部是在应用层以下，是路由器，网卡进行处理，它们在设计时自然遵守规定全部依照网络字节序对数据进行处理，而你自己不把IP地址转换顺序，交给下层处理时自然会出错。

所以，在应用层，也应该遵守规定，对于int double 这样的数据也应该转换字节序，当然字符串也挺好（这大概也就是Json的优势了，而像protobuf这种传输时就要注意顺序）。

[抓包看ip地址字节序转换](https://blog.csdn.net/XiyouLinux_Kangyijie/article/details/72991235)
utf-8还有一个byte-order-mark(bom)的问题

C语言下可以把一个byte按照binary的方式打印出来(就是把一个byte的每一个bit输出来),int也可以。
```c
#include <stdio.h>
#include <limits.h>

void print_bin(unsigned char byte)
{
    int i = CHAR_BIT; /* however many bits are in a byte on your platform */
    while(i--) {
        putchar('0' + ((byte >> i) & 1)); /* loop through and print the bits */
    }
    printf("\n\n");
}

void print_bin_int(unsigned int integer)
{
    int i = CHAR_BIT * sizeof integer; /* however many bits are in an integer */
    while(i--) {
        putchar('0' + ((integer >> i) & 1));
    }
    printf("\n\n");
}



int checkCPUendian()
{
  union
  {
    unsigned int a;
    unsigned char b;
  }c;
  c.a = 1;
  printf("a = %a , b= %a \n",c.a , c.b);
  printf("a = %X , b= %X \n",c.a , c.b);
  printf("a = %p , b= %p \n",c.a , c.b);
  printf("a = %u , b= %u \n",c.a , c.b);
  print_bin(c.b);
  print_bin_int(c.a);
  return (c.b == 1);
}

int main(int argc, char const *argv[]) {
        if(checkCPUendian()){
                printf("Little endian platform!\n");
        } else {

                printf("Big Endian platform!\n");
        }

        return 0;
}
```

输出，这里是从高地址内存开始往低地址的内存读取
```
a = 0x0.07fcbc8474a98p-1022 , b= 0x0p+0
a = 1 , b= 1
a = 0x1 , b= 0x1
a = 1 , b= 1
00000001

00000000000000000000000000000001

Little endian platform!
```