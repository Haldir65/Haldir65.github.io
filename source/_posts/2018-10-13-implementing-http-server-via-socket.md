---
title: 从Socket入手实现http协议
date: 2018-10-13 21:30:36
tags: [tools]
---

![](https://www.haldir66.ga/static/imgs/sun_rise_dim_grass.jpg)

收集几种语言中使用socket实现httpServer和httpClient的主要步骤
<!--more-->

OSI七层网络体系结构 ： 物理层(IEEE 802.2)、数据链路层(ARP,RARP)、网络层(ip,icmp)、传输层(tcp,udp)、表示层、会话层(SSL,TLS)、应用层(HTTP,FTP,SMTP,POP3).
这里面Socket比较特殊，Socket是一组编程接口（API）。介于传输层和应用层，向应用层提供统一的编程接口。应用层不必了解TCP/IP协议细节,直接通过对Socket接口函数的调用完成数据在IP网络的传输。SOCKET 算不上是个协议，应该是应用层与传输层间的一个抽象层，是个编程接口。

tcp包结构是不包含ip地址的，只有source port(2个byte)和destination port(65536这么来的)的. ip address是ip层的工作。

[HTTP 1.1的RFC非常长](https://tools.ietf.org/html/rfc7230)

> 在 OSI 的七层协议中，第二层（数据链路层）的数据叫「Frame」，第三层（网络层）上的数据叫「Packet」，第四层（传输层）的数据叫「Segment」。(在wireShark的抓包结果就是这么展示的)

[tcp包结构，udp的也有](https://jerryc8080.gitbooks.io/understand-tcp-and-udp/chapter1.html)


## java
用java实现一个httpclient怎么样?
```java
public class HttpSocketClient {

    private Socket mSocket;

    public static void main(String[] args) {
        HttpSocketClient client = new HttpSocketClient();
        try {
            client.sendGet("www.baidu.com",80,"/");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }


    public HttpSocketClient() {
        this.mSocket = new Socket();

    }

    /** 在百度服务器面前，这就是一个正常的浏览器
     * @param host
     * @param port
     * @param path
     * @throws IOException
     */
    void sendGet(String host, int port, String path) throws IOException {
        SocketAddress dest = new InetSocketAddress(host, port);
        mSocket.connect(dest);
        OutputStreamWriter streamWriter = new OutputStreamWriter(mSocket.getOutputStream());
        BufferedWriter bufferedWriter = new BufferedWriter(streamWriter);

        bufferedWriter.write("GET " + path + " HTTP/1.1\r\n");
        bufferedWriter.write("Host: " + host + "\r\n");
        bufferedWriter.write("Connection: " + "keep-alive" + "\r\n");
        bufferedWriter.write("User-Agent: " + "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.140 Safari/537.36" + "\r\n");
        bufferedWriter.write("Accept: " + "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" + "\r\n");
        bufferedWriter.write("Accept-Language: " + "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7" + "\r\n");
        bufferedWriter.write("\r\n");
        bufferedWriter.flush(); //flush一下很重要，等于说已经写完了


        BufferedInputStream stream = new BufferedInputStream(mSocket.getInputStream());
        BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(stream));
        String line = null;
        while ((line = bufferedReader.readLine())!=null) {
            System.out.println(line);
        }
        bufferedReader.close();
        bufferedWriter.close();
        mSocket.close();
    }
}
```
输出
```
HTTP/1.1 302 Moved Temporarily
Date: Sat, 24 Mar 2018 06:44:20 GMT
Content-Type: text/html
Content-Length: 225
Connection: Keep-Alive
Set-Cookie: BAIDUID=259D5F393E329E8E44651C589037C093:FG=1; expires=Thu, 31-Dec-37 23:55:55 GMT; max-age=2147483647; path=/; domain=.baidu.com
Set-Cookie: BIDUPSID=259D5F393E329E8E44651C589037C093; expires=Thu, 31-Dec-37 23:55:55 GMT; max-age=2147483647; path=/; domain=.baidu.com
Set-Cookie: PSTM=1521873860; expires=Thu, 31-Dec-37 23:55:55 GMT; max-age=2147483647; path=/; domain=.baidu.com
Set-Cookie: BD_LAST_QID=10107339987852007720; path=/; Max-Age=1
P3P: CP=" OTI DSP COR IVA OUR IND COM "
Location: https://www.baidu.com/
Server: BWS/1.1
X-UA-Compatible: IE=Edge,chrome=1

<html>
<head><title>302 Found</title></head>
<body bgcolor="white">
<center><h1>302 Found</h1></center>
<hr><center>65d90fa34a5e777be72b3e20c859c335f9198cc2
Time : Thu Mar 15 16:20:59 CST 2018</center>
</body>
</html>
```
当然因为访问的是http，302是临时重定向（另外，几乎没见过谁返回301的，301的结果会被浏览器缓存），注意上面返回了Location字段，所以是符合规范的

server这边普遍用的是netty，正好netty的官网上也有相关的教程，后面再补上


## Python
[我自己抄来的简易版](https://github.com/Haldir65/Jimmy/blob/rm/basics/simpleHttpServer/httpServer.py)
```python
## server 
import socket
import re
import os
import codecs,logging

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.bind((HOST, 18004))
sock.listen(100)


# infinite loop
while True:
    # maximum number of requests waiting
    conn, addr = sock.accept()
    request = conn.recv(1024)
    if isinstance(request,bytes):
        request = str(request)
        logging.error(request)

    splited = request.split(' ')    
    if(len(splited)<2):
        continue
    method = request.split(' ')[0]
    src = request.split(' ')[1]

    print('Connect by: ', addr)
    print('Request is:\n', request)

    # deal wiht GET method
    if method == 'GET' or method.__contains__('GET'):
        if src == '/index.html':
            content = index_content
        elif src == '/image/image_12.jpg':
            content = pic_content
        elif src == '/reg.html':
            content = reg_content
        elif re.match('^/\?.*$', src):
            entry = src.split('?')[1]  # main content of the request
            content = 'HTTP/1.x 200 ok\r\nContent-Type: text/html\r\n\r\n'
            content += entry
            content += '<br /><font color="green" size="7">register successs!</p>'
        else:
            continue

    # deal with POST method
    elif method == 'POST':
        form = request.split('\r\n')
        entry = form[-1]  # main content of the request
        content = 'HTTP/1.x 200 ok\r\nContent-Type: text/html\r\n\r\n'
        content += entry
        content += '<br /><font color="green" size="7">register successs!</p>'

    ######
    # More operations, such as put the form into database
    # ...
    ######

    else:
        continue
    if(type(content) is str):
        content = content.encode('utf-8')
    conn.sendall(content)
    # close connection
    conn.close()
```

本地浏览器访问localhost:10086应该就能看到结果了，值得一提的是自己在chrome里面访问"http://localhost:18004/index.html"这个地址的时候，事实上浏览器发送的数据是这样的
> b'GET /index.html HTTP/1.1\r\nHost: localhost:18004\r\nConnection: keep-alive\r\nCache-Control: max-age=0\r\nUpgrade-Insecure-Requests: 1\r\nUser-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Safari/537.36\r\nDNT: 1\r\nAccept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8\r\nAccept-Encoding: gzip, deflate, br\r\nAccept-Language: zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7\r\nCookie: _ga=GA1.1.dsadsa.dsadas; _gid=GA1.1.dsadsa.dsadasda\r\n\r\n'

对了，浏览器默认会请求favicon，所以在服务器这边看到了另一个请求
> b'GET /favicon.ico HTTP/1.1\r\nHost: localhost:18004\r\nConnection: keep-alive\r\nPragma: no-cache\r\nCache-Control: no-cache\r\nUser-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Safari/537.36\r\nDNT: 1\r\nAccept: image/webp,image/apng,image/*,*/*;q=0.8\r\nReferer: http://localhost:18004/index.html\r\nAccept-Encoding: gzip, deflate, br\r\nAccept-Language: zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7\r\nCookie: _ga=GA1.1.dsadsa.dsadas; _gid=GA1.1.dsadsa.dsadasda\r\n\r\n'

平时用的都是[requests](https://github.com/requests/requests/)这个库,不过自己写也还是很简单
```python
#!/usr/bin/python
# -*- coding: UTF-8 -*-
# 导入socket库:
import socket

# 创建一个socket:
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
# 建立连接:
s.connect(('www.sina.com.cn', 80))
s.send(b'GET / HTTP/1.1\r\nHost: www.sina.com.cn\r\nConnection: close\r\n\r\n')
# 接收数据:
buffer = []
while True:
    # 每次最多接收1k字节:
    d = s.recv(1024)
    if d:
        buffer.append(d)
    else:
        break
data = b''.join(buffer)

s.close()
header, html = data.split(b'\r\n\r\n', 1)
print(header.decode('utf-8'))
# 把接收的数据写入文件:
with open('sina.html', 'wb') as f:
    f.write(html)
```

上述代码，server和client都不能很好的处理并发或者利用多进程

[高阶版](https://realpython.com/python-sockets/)


## C语言版本
C语言的应该最接近底层,C语言实现HTTP的GET和POST请求
[似乎有很多现成的例子可以直接拿来抄](http://pminkov.github.io/blog/socket-programming-in-linux.html)




一个简单的httpServer.c(unix环境下运行)
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

#define PORT 8888
#define SERV "0.0.0.0"
#define QUEUE 20
#define BUFF_SIZE 1024


typedef struct doc_type{
        char *key;
        char *value;
}HTTP_CONTENT_TYPE;

HTTP_CONTENT_TYPE http_content_type[] = {
        { "html","text/html" },
        { "gif" ,"image/gif" },
        { "jpeg","image/jpeg" }
};

int sockfd;
char *http_res_tmpl = "HTTP/1.1 200 OK\r\n"
        "Server: Cleey's Server V1.0\r\n"
    "Accept-Ranges: bytes\r\n"
        "Content-Length: %d\r\n"
        "Connection: close\r\n"
        "Content-Type: %s\r\n\r\n";

void handle_signal(int sign); // 退出信号处理
void http_send(int sock,char *content); // http 发送相应报文
char* joinString(char *s1, char *s2);//字符串拼接

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
                memset(buff,0,sizeof(buff));
                int len = recv(sock_client,buff,sizeof(buff),0);
                fputs(buff,stdout);
                //send(sock_client,buff,len,0);
                char *re = joinString("<h2>the client said</h2> <br>  ",buff);
                http_send(sock_client,re);
                close(sock_client);
        }
        fputs("Bye Cleey",stdout);
        close(sockfd);
        return 0;
}

void http_send(int sock_client,char *content){
        char HTTP_HEADER[BUFF_SIZE],HTTP_INFO[BUFF_SIZE];
        int len = strlen(content);
        sprintf(HTTP_HEADER,http_res_tmpl,len,"text/html");
        len = sprintf(HTTP_INFO,"%s%s",HTTP_HEADER,content);

        send(sock_client,HTTP_INFO,len,0);
}

void handle_signal(int sign){
        fputs("\nSIGNAL INTERRUPT \nBye Cleey! \nSAFE EXIT\n",stdout);
        close(sockfd);
        exit(0);
}

char* joinString(char *s1, char *s2)
{
    char *result = malloc(strlen(s1)+strlen(s2)+1);//+1 for the zero-terminator
    //in real code you would check for errors in malloc here
	if (result == NULL) exit (1);
 
    strcpy(result, s1);
    strcat(result, s2);
 
    return result;
}
```

使用方式:
>curl -X GET -d  --header "Content-Type:application/json" --header "Authorization:JWT somerandomjwtstringandstuffs" "http://127.0.0.1:8888/user"


一个类似于简易的curl的c语言httpClient可能长这样
```C
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h> 
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <netinet/in.h>
#include <unistd.h>

int get_ip_by_domain(const char *domain, char *ip); // 根据域名获取ip

int main(int argc, char *argv[]){
if(argc!=2){
    printf("please input host name %s ipn",argv[0]); 
    return 1;
}
char * host = argv[1];
int sockfd;
int len; 
struct sockaddr_in address; 
int result; 
char httpstring[1000]; 

char * server_ip[100];
get_ip_by_domain(host,server_ip);
strcat(httpstring,"GET / HTTP/1.1\r\n");
strcat(httpstring,"Host: ");
strcat(httpstring,host);
strcat(httpstring,"\r\n");
strcat(httpstring,
"Connection: keep-alive\r\n"
"Cache-Control: max-age=0\r\n"
"Upgrade-Insecure-Requests: 1\r\n"
"User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.67 Safari/537.36\r\n"
"DNT: 1\r\n"
"Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8\r\n"
"Accept-Encoding: gzip, deflate, br\r\n"
"Accept-Language: zh-CN,zh;q=0.9\r\n\r\n"); 
char ch;
sockfd = socket(AF_INET, SOCK_STREAM, 0); 
address.sin_family = AF_INET; 
printf("the server host is %s and the ip is %s\n",argv[1],server_ip);
address.sin_addr.s_addr = inet_addr(server_ip); 
address.sin_port = htons(80); 
len = sizeof(address);
result = connect(sockfd,(struct sockaddr *)&address,len); 
if(result == -1){ 
    perror("oops: client connect error"); 
    return 1; 
}
printf("befor connect!!");
write(sockfd,httpstring,strlen(httpstring)); 
printf("after write!!\n");
while(read(sockfd,&ch,1)){ 
    printf("%c", ch); 
} 
close(sockfd); 
printf("n"); 
return 0;
} 

#define IP_SIZE		16

// 根据域名获取ip
int get_ip_by_domain(const char *domain, char *ip)
{
    char **pptr;
    struct hostent *hptr;
    hptr = gethostbyname(domain);
    if(NULL == hptr)
    {
        printf("gethostbyname error for host:%s/n", domain);
        return -1;
    }
    for(pptr = hptr->h_addr_list ; *pptr != NULL; pptr++)
    {
        if (NULL != inet_ntop(hptr->h_addrtype, *pptr, ip, IP_SIZE) )
        {
            return 0; // 只获取第一个 ip
        }
    }
    return -1;
}
```
使用方式:
> ./bin/client www.baidu.com ##这时候，在百度服务器看来，这个程序和普通的浏览器没有区别。试了下主流的网站，都没有什么问题。优酷返回了一大串奇怪的字符串，看了下，应该是content-encoding: gzip了，所以在终端里面看上去乱七八糟的。

上面这段会卡在read里面，因为读到最后一个字节的时候，客户端并不知道是没有更多数据还是网络不好堵住了。需要在每一次读完之后去找那个"\r\n\r\n"的结束标志。


网络通信显然还要注意一个字节序的问题，简单来讲,java是大端的,c++是跟着平台走的且多数为小端
[c++的服务器和java的客户端之间的通信](https://blog.csdn.net/windshg/article/details/12956107)

> C/C++语言编写的程序里数据存储顺序是跟编译平台所在的CPU相关的，而现在比较普遍的 x86 处理器是 Little Endian
JAVA编写的程序则唯一采用 Big Endian 方式来存储数据

htons();//将short类型的值从主机字节序转换为网络字节序(上面就是把端口号转化一下)
inet_addr();//将IP地址字符串转换为long类型的网络字节序（接受一个字符串，返回一个long）
gethostbyname();//获得与该域名对应的IP地址
inet_ntoa();//将long类型的网络字节序转换成IP地址字符串


读函数read
ssize_t read(int fd,void *buf,size_t nbyte)
read函数是负责从fd中读取内容.当读成功 时,read返回实际所读的字节数,如果返回的值是0 表示已经读到文件的结束了,小于0表示出现了错误.如果错误为EINTR说明读是由中断引起 的, 如果是ECONNREST表示网络连接出了问题. 

写函数write
ssize_t write(int fd, const void*buf,size_t nbytes);
write函数将buf中的nbytes字节内容写入文件描述符fd.成功时返回写的字节数.失败时返回-1. 并设置errno变量. 在网络程序中,当我们向套接字文件描述符写时有两可能.
1)write的返回值大于0,表示写了部分或者是全部的数据. 这样我们用一个while循环来不停的写入，但是循环过程中的buf参数和nbyte参数得由我们来更新。也就是说，网络写函数是不负责将全部数据写完之后在返回的。
2)返回的值小于0,此时出现了错误.我们要根据错误类型来处理.
如果错误为EINTR表示在写的时候出现了中断错误.
如果为EPIPE表示网络连接出现了问题(对方已经关闭了连接).

除了read和write之外
还有
int recv(int sockfd,void *buf,int len,int flags)
int send(int sockfd,void *buf,int len,int flags)
这两个函数，功能差不多，只是多了第四个参数

- 简单版本的参考
[使用Linux c语言编写简单的web服务器](http://www.cleey.com/blog/single/id/789.html)
[socket http文件下载器c语言实现](http://www.voidcn.com/article/p-xieequox-bat.html)

- 高阶版本的参考
[高阶一点，处理并发的](https://www.geeksforgeeks.org/socket-programming-in-cc-handling-multiple-clients-on-server-without-multi-threading/)
[多线程的server和client源码](https://github.com/pminkov/webserver)


## todo
**socket还有阻塞，超时，tcp缓冲等问题值得研究，Linux下TCP延迟确认机制**

**还有实现websocket协议的，实现sock5协议的**

- js并不支持对操作系统socket的直接控制，可能是安全因素(websocket倒是有，不过那是另外一回事了)。


