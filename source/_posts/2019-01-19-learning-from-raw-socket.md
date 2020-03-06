---
title: 原始套接字学习指南
date: 2019-01-19 22:20:35
tags: [c]
---

![](https://api1.foster66.xyz/static/imgs/SunFlowersStorm_EN-AU8863925685_1920x1080.jpg)
从原始套接字 SOCK_RAW学习到的知识
<!--more-->

以下图片盗自[chinaunix一篇讲解raw socket的文章](http://abcdxyzk.github.io/blog/2015/04/14/kernel-net-sock-raw/)，感谢原作者的辛勤工作。复习一下ip包的结构。


- ### 这是IP packet
![](https://api1.foster66.xyz/static/imgs/2019-01-19-1.jpg)

- ### 这是TCP header
![](https://api1.foster66.xyz/static/imgs/2019-01-19-2.jpg)

- ### 这是IP header
![](https://api1.foster66.xyz/static/imgs/2019-01-19-3.jpg)

- ### 这是mac header
![](https://api1.foster66.xyz/static/imgs/2019-01-19-4.jpg)

从内核代码来看，这些分别对应ethhdr、iphdr、tcphdr、udphdr等结构体。

一般来讲，应用层程序的数据都是在tcp或者udp的data中的，实际发送过程中，内核会帮忙添加上tcp header，ip header以及mac header等数据，开发者无需关心也无从干涉。raw socket为我们提供了直接读写这块数据的方法。

C语言中raw socket的创建方式为:
> socket(AF_INET, SOCK_RAW, protocol); //需要root权限

raw socket一般用于网络监测程序中比较多，比如ping , nmap这种。这类协议是没有端口的。

另一种场景是伪造tcp header应对运营商udp屏蔽和流量qos，这种类似的实现在2017年出来的比较多。(就是用一个raw socket把一个udp包伪装成一个tcp包)。


接下来这个例子是使用raw socket监听server端收到的ip packet包内容
server.c
```c
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <linux/if_ether.h>
#include <stdlib.h>
#include <arpa/inet.h>
 
int main()
{     
printf("main is running\n");

int iSock, nRead, iProtocol;        
char buffer[4096] = {0};
char  *ethhead, *iphead, *tcphead, *udphead, *icmphead, *p;
    
if((iSock = socket(PF_PACKET, SOCK_RAW, htons(ETH_P_IP))) < 0)
{
    printf("create iSocket error, check root\n");  // 需要root权限， 最后运行的时候， 可以用sudo ./server
    return 1;
}
        
while(1) 
{
    nRead = recvfrom(iSock, buffer, 2048, 0, NULL, NULL);  
    /*
        以太网帧头 14
        ip头       20
        udp头      8
        总共42字节(最少)
    */
    if(nRead < 42) 
    {
        printf("packet error\n");
        continue;
    }
            
    int n = 0XFF;
    char szVisBuf[1024] = {0};
    for(unsigned int i = 0; i < nRead; ++i)
    {
        char szTmp[3] = {0};
        sprintf(szTmp, "%02x", buffer[i]&n);
        strcat(szVisBuf, szTmp);
    }
        
    
    ethhead = buffer;
    p = ethhead;
    
    iphead = ethhead + 14;  
    p = iphead + 12;

    char szIps[128] = {0};
    snprintf(szIps, sizeof(szIps), "IP: %d.%d.%d.%d => %d.%d.%d.%d",
        p[0]&n, p[1]&n, p[2]&n, p[3]&n,
        p[4]&n, p[5]&n, p[6]&n, p[7]&n);
    iProtocol = (iphead + 9)[0];
    p = iphead + 20;
    
    
    unsigned int iDstPort = (p[2]<<8)&0xff00 | p[3]&n;
    switch(iProtocol)
    {
        case IPPROTO_UDP : 
            if(iDstPort == 8888)
            {
                printf("source port: %u,",(p[0]<<8)&0xff00 |  p[1]&n);
                printf("dest port: %u\n", iDstPort);
                
                printf("%s\n", szIps);	
                printf("%s\n", szVisBuf);
                printf("nRead is %d\n", nRead);	
                
            }
            break;
        case IPPROTO_RAW : 
            printf("raw\n");
            break;
        default:
            break;
    }
}
}
```

client.c
```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
 
int main()
{
    struct sockaddr_in srvAddr;
    bzero(&srvAddr, sizeof(srvAddr));
    srvAddr.sin_family = AF_INET;
    srvAddr.sin_addr.s_addr = inet_addr("127.0.0.1");
    srvAddr.sin_port = htons(8888);
 
    int iSock = socket(AF_INET, SOCK_DGRAM, 0); // udp
	int i = 0;
    while(1)
    {
		printf("press enter to send data\n");
        while (( i = getchar()) != '\n'){
            char szBuf[32] = {0};
            snprintf(szBuf, sizeof(szBuf), "hello %d", ++i);
            sendto(iSock, szBuf, strlen(szBuf) + 1, 0, (struct sockaddr *)&srvAddr, sizeof(srvAddr));
        }
    }
 
	close(iSock);
    return 0;
}
```

从raw socket 接受过来的buffer 的地址是数据链路层的地址，具体我们获取的东西就是通过偏移量来，这个偏移量我们需要查看网络书或者抓个包分析下链路层的数据格式等等。 
client很简单，就是一个udp发包到localhost，关键在于server这边：
> iSock = socket(PF_PACKET, SOCK_RAW, htons(ETH_P_IP)

这个socket能够监听本机接收到的所有ip packet，接收到的数据帧的头6个字节是目的地的MAC地址，紧接着6个字节是源MAC地址 , 如果是udp或者tcp的话，还能读取到port。也就是一些常用抓包工具的实现原理。

所以可以写一个简单的抓包工具，将那些发给本机的IPV4报文全部打印出来。
```c
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <netinet/if_ether.h>

int main(int argc, char **argv)
{
int sock, n;
char buffer[2048];
struct ethhdr *eth;
struct iphdr *iph;

if (0 > (sock = socket(PF_PACKET, SOCK_RAW, htons(ETH_P_IP)))) {
    perror("socket");
    exit(1);
}

while (1) {
    printf("=====================================\n");
    //注意：在这之前我没有调用bind函数，raw socket这一层已经不存在port的概念了
    n = recvfrom(sock, buffer, 2048, 0, NULL, NULL);
    printf("%d bytes read\n", n);

    //接收到的数据帧头6字节是目的MAC地址，紧接着6字节是源MAC地址。
    eth = (struct ethhdr*)buffer;
    printf("Dest MAC addr:%02x:%02x:%02x:%02x:%02x:%02x\n",eth->h_dest[0],eth->h_dest[1],eth->h_dest[2],eth->h_dest[3],eth->h_dest[4],eth->h_dest[5]);
    printf("Source MAC addr:%02x:%02x:%02x:%02x:%02x:%02x\n",eth->h_source[0],eth->h_source[1],eth->h_source[2],eth->h_source[3],eth->h_source[4],eth->h_source[5]);

    iph = (struct iphdr*)(buffer + sizeof(struct ethhdr));
    //我们只对IPV4且没有选项字段的IPv4报文感兴趣
    if(iph->version == 4 && iph->ihl == 5){
    unsigned char *sd, *dd;
    sd = (unsigned char*)&iph->saddr;
    dd = (unsigned char*)&iph->daddr;
    printf("Source Host: %d.%d.%d.%d Dest host: %d.%d.%d.%d\n", sd[0], sd[1], sd[2], sd[3], dd[0], dd[1], dd[2], dd[3]);
    //    printf("Source host:%s\n", inet_ntoa(iph->saddr));
    //    printf("Dest host:%s\n", inet_ntoa(iph->daddr));
    }
}
return 0;
}
```



顺便提一下，一般我们在Linux机器上是可以查看到当前系统对应的内核的头文件的
>  root][~]# grep -n 'ethhdr' /usr/include/linux/if_ether.h
107:struct ethhdr {
[root][~]#
[root][~]# grep -n 'iphdr' /usr/include/linux/*
/usr/include/linux/if_tunnel.h:32:      struct iphdr            iph;
/usr/include/linux/ip.h:85:struct iphdr {

[从raw socket介绍中学到的东西](http://abcdxyzk.github.io/blog/2015/04/14/kernel-net-sock-raw/)
> 接下来我们简单介绍一下网卡是怎么收报的，如果你对这部分已经很了解可以跳过这部分内容。网卡从线路上收到信号流，网卡的驱动程序会去检查数据帧开始的前6个字节，即目的主机的MAC地址，如果和自己的网卡地址一致它才会接收这个帧，不符合的一般都是直接无视。然后该数据帧会被网络驱动程序分解，IP报文将通过网络协议栈，最后传送到应用程序那里。往上层传递的过程就是一个校验和“剥头”的过程，由协议栈各层去实现。


setsockopt (packet_send_sd, IPPROTO_IP, IP_HDRINCL, val, sizeof (one)) // IP_HDRINCL to tell the kernel that headers are included in the packet
这样设置告诉内核，ip packet的header将由我们自己添加，所以最终发送出去的内容需要完全由自己决定。

为了将一个udp包伪装成tcp包，需要一个SOCK_RAW的socket
> socket(AF_INET , SOCK_RAW , IPPROTO_TCP)

接下来就是自己组装tcp包结构，tbd(这个不同的网卡的值是不一样的，最简单的就是抓包就可以了)


## python也提供了对应rawsocket的api 
>  socket.socket(socket.AF_INET, socket.SOCK_RAW, socket.IPPROTO_TCP)


## 参考
[kcptun-raw：应对UDP QoS，重新实现kcptun的一次尝试](https://blog.chionlab.moe/2017/04/06/kcptun-with-fake-tcp/)
[some_kcptun_tools](https://github.com/linhua55/some_kcptun_tools)
[kcptun-raw](https://github.com/Chion82/kcptun-raw)
[tcp那些事](https://coolshell.cn/articles/11609.html) tcp协议为了对外实现可靠交付，内部实现有很多非常复杂的算法。
[java并不支持raw socket，最多用jni包装一下](https://stackoverflow.com/questions/14873243/raw-socket-in-java)