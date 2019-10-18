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

server这边普遍用的是netty，正好netty的官网上也有相关的教程.
[netty的example非常多，http2,cors,upload等等都有](https://netty.io/4.1/xref/overview-summary.html)


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

[自己用selector实现了一个toy server](https://github.com/Haldir65/Jimmy/blob/rm/src/_045_realpython_socket_article/dumbHttpServer.py)，使用curl可以像请求一个本地服务一样去获得response

> sudo python3 src/_045_realpython_socket_article/dumbHttpServer.py 127.0.0.1 80

完成的地方包括:
1. server注册socket non-blocking监听。有新的client连接上就把client socket加入selector监听。
2. 在出现EventRead之后使用socket.recv()读取请求（GET /index.html http/1.1 ....），把"index.html"这样的path加入data
3. 在出现EventWrite之后，从data中获取之前的path（实际中可以根据这个path去找服务或者文件资源），返回utf-8 encoded内容，外加http response header (socket.sendall).

主要的缺陷包括:
1. client这边ctrl+c之后，server这边会接收到一个13的信号，默认对这个信号的处理是杀进程
2. 在send或者read的时候有可能出现BrokenPipeError或者ConnectionResetError。暂时只好到处try except.
3. 自己用socket伪造http协议的content-length字段是能够被wget认可的，只是这个content-length = len(正文.encode('utf-8'))。就是这部分长度是字节数组的长度，否则会短一些。
4. http response协议头字段之间加(\r\n header最后跟两个换行符) 这些都是必要的
5. curl不知道为什么在读完response之后还卡在那里（除非server主动close掉socket）
6. wrk跑分看不出来这个toy server的吞吐量。



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


一个使用libevent的版本的客户端可以这样写
```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <assert.h>
#include <unistd.h>
#include <evhttp.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <event2/event.h>
#include <event2/util.h>
#include <event2/http.h>
#include <event2/bufferevent.h>

void http_request_done(struct evhttp_request *req, void *arg){
    char buf[8196]; //这里没处理了
    int s = evbuffer_remove(req->input_buffer, &buf, sizeof(buf) - 1);
    buf[s] = '\0';
    printf("%s", buf);
    // terminate event_base_dispatch()
    event_base_loopbreak((struct event_base *)arg);
}

char *
get_tcp_socket_for_host(const char *hostname, ev_uint16_t port)
{
    char port_buf[6];
    struct evutil_addrinfo hints;
    struct evutil_addrinfo *answer = NULL;
    int err;
    evutil_socket_t sock;

    /* Convert the port to decimal. */
    evutil_snprintf(port_buf, sizeof(port_buf), "%d", (int)port);

    /* Build the hints to tell getaddrinfo how to act. */
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC; /* v4 or v6 is fine. */
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP; /* We want a TCP socket */
    /* Only return addresses we can use. */
    hints.ai_flags = EVUTIL_AI_ADDRCONFIG;

    /* Look up the hostname. */
    err = evutil_getaddrinfo(hostname, port_buf, &hints, &answer);
    if (err != 0) {
          fprintf(stderr, "Error while resolving '%s': %s",
                  hostname, evutil_gai_strerror(err));
          return NULL;
    }

    /* If there was no error, we should have at least one answer. */
    assert(answer);
    /* Just use the first answer. */
    sock = socket(answer->ai_family,
                  answer->ai_socktype,
                  answer->ai_protocol);
    if (sock < 0)
        return NULL;
    if (connect(sock, answer->ai_addr, answer->ai_addrlen)) {
        /* Note that we're doing a blocking connect in this function.
         * If this were nonblocking, we'd need to treat some errors
         * (like EINTR and EAGAIN) specially. */
        EVUTIL_CLOSESOCKET(sock);
        return NULL;
    }

    const char *s = NULL;
    char buf[128];

    if ( answer->ai_family == AF_INET){
        struct sockaddr_in *sin = (struct sockaddr_in *)answer->ai_addr;
        s = evutil_inet_ntop(AF_INET, &sin->sin_addr, buf, 128);
    } else if ( answer->ai_family == AF_INET6){
        struct sockaddr_in6 *sin6 = (struct sockaddr_in6 *)answer->ai_addr;
        s = evutil_inet_ntop(AF_INET6, &sin6->sin6_addr, buf, 128);
    }
    if (s){
        printf("  ->%s\n" , s);
    }
    char *res = (char *)malloc(sizeof(char)*strlen(s)+1);
    strcpy(res,s);
    return res;
}

int main(int argc, char **argv){

    char *ip_addresss = get_tcp_socket_for_host("www.taobao.com",80);
    printf("the ip address of taobao is  %s \n",ip_addresss);

    struct event_base *base;
    struct evhttp_connection *conn;
    struct evhttp_request *req;


    base = event_base_new();
 
    conn = evhttp_connection_base_new(base, NULL, ip_addresss, 80);
    req = evhttp_request_new(http_request_done, base);

    // 这里就是写request 的 header
    evhttp_add_header(req->output_headers, "Host", "www.taobao.com");
    evhttp_add_header(req->output_headers, "Connection", "keep-alive");
    evhttp_add_header(req->output_headers, "Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8");
    evhttp_add_header(req->output_headers, "User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36");

    evhttp_make_request(conn, req, EVHTTP_REQ_GET, "/index.html");
    evhttp_connection_set_timeout(req->evcon, 600);
    event_base_dispatch(base);

    return 0;
}
```


网络通信显然还要注意一个字节序的问题，简单来讲,java是大端的,c++是跟着平台走的且多数为小端
[c++的服务器和java的客户端之间的通信](https://blog.csdn.net/windshg/article/details/12956107)

> C/C++语言编写的程序里数据存储顺序是跟编译平台所在的CPU相关的，而现在比较普遍的 x86 处理器是 Little Endian
JAVA编写的程序则唯一采用 Big Endian 方式来存储数据

htons();//将short类型的值从主机字节序转换为网络字节序(上面就是把端口号转化一下)
inet_addr();//将IP地址字符串转换为long类型的网络字节序（接受一个字符串，返回一个long）
gethostbyname();//获得与该域名对应的IP地址
inet_ntoa();//将long类型的网络字节序转换成IP地址字符串
//这些转换字节序的函数是必须的，因为ip地址，端口这些东西不是应用层处理，而是由路由器这些东西去处理的，后者遵照网络标准使用的是big-endian，所以必须转换字节序。

读函数read
ssize_t read(int fd,void *buf,size_t nbyte)
read函数是负责从fd中读取内容.当读成功 时,read返回实际所读的字节数,如果返回的值是0 表示已经读到文件的结束了,小于0表示出现了错误.如果错误为EINTR说明读是由中断引起的, 如果是ECONNREST表示网络连接出了问题. 

写函数write
```c
#include <unistd.h>
ssize_t write(int fd, const void *buf, size_t count);
```
write函数将buf中的nbytes字节内容写入文件描述符fd.成功时返回写的字节数.失败时返回-1. 并设置errno变量. 在网络程序中,当我们向套接字文件描述符写时有两可能.
1)write的返回值大于0,表示写了部分或者是全部的数据. 这样我们用一个while循环来不停的写入，但是循环过程中的buf参数和nbyte参数得由我们来更新。也就是说，网络写函数是不负责将全部数据写完之后在返回的。
2)返回的值小于0,此时出现了错误.我们要根据错误类型来处理.
如果错误为EINTR表示在写的时候出现了中断错误.
如果为EPIPE表示网络连接出现了问题(对方已经关闭了连接).

[recv和send都是跟buffer打交道的](https://www.cnblogs.com/jianqiang2010/archive/2010/08/20/1804598.html)
Socket send函数和recv函数详解
1.send 函数
int send( SOCKET s, const char FAR *buf, int len, int flags );  
不论是客户还是服务器应用程序都用send函数来向TCP连接的另一端发送数据。客户程序一般用send函数向服务器发送请求，而服务器则通常用send函数来向客户程序发送应答。

该函数的第一个参数指定发送端套接字描述符；

第二个参数指明一个存放应用程序要发送数据的缓冲区；

第三个参数指明实际要发送的数据的字节数；

第四个参数一般置0。 

这里只描述同步Socket的send函数的执行流程。当调用该函数时，

（1）send先比较待发送数据的长度len和套接字s的发送缓冲的长度， 如果len大于s的发送缓冲区的长度，该函数返回SOCKET_ERROR；

（2）如果len小于或者等于s的发送缓冲区的长度，那么send先检查协议是否正在发送s的发送缓冲中的数据，如果是就等待协议把数据发送完，如果协议还没有开始发送s的发送缓冲中的数据或者s的发送缓冲中没有数据，那么send就比较s的发送缓冲区的剩余空间和len

（3）如果len大于剩余空间大小，send就一直等待协议把s的发送缓冲中的数据发送完

（4）如果len小于剩余 空间大小，send就仅仅把buf中的数据copy到剩余空间里（注意并不是send把s的发送缓冲中的数据传到连接的另一端的，而是协议传的，send仅仅是把buf中的数据copy到s的发送缓冲区的剩余空间里）。

如果send函数copy数据成功，就返回实际copy的字节数，如果send在copy数据时出现错误，那么send就返回SOCKET_ERROR；如果send在等待协议传送数据时网络断开的话，那么send函数也返回SOCKET_ERROR。

要注意send函数把buf中的数据成功copy到s的发送缓冲的剩余空间里后它就返回了，但是此时这些数据并不一定马上被传到连接的另一端。如果协议在后续的传送过程中出现网络错误的话，那么下一个Socket函数就会返回SOCKET_ERROR。（每一个除send外的Socket函数在执 行的最开始总要先等待套接字的发送缓冲中的数据被协议传送完毕才能继续，如果在等待时出现网络错误，那么该Socket函数就返回 SOCKET_ERROR）

注意：在Unix系统下，如果send在等待协议传送数据时网络断开的话，调用send的进程会接收到一个SIGPIPE信号，进程对该信号的默认处理是进程终止。

通过测试发现，异步socket的send函数在网络刚刚断开时还能发送返回相应的字节数，同时使用select检测也是可写的，但是过几秒钟之后，再send就会出错了，返回-1。select也不能检测出可写了。

 

2. recv函数

int recv( SOCKET s, char FAR *buf, int len, int flags);   

不论是客户还是服务器应用程序都用recv函数从TCP连接的另一端接收数据。该函数的第一个参数指定接收端套接字描述符；

第二个参数指明一个缓冲区，该缓冲区用来存放recv函数接收到的数据；

第三个参数指明buf的长度；

第四个参数一般置0。

这里只描述同步Socket的recv函数的执行流程。当应用程序调用recv函数时，

（1）recv先等待s的发送缓冲中的数据被协议传送完毕，如果协议在传送s的发送缓冲中的数据时出现网络错误，那么recv函数返回SOCKET_ERROR，

（2）如果s的发送缓冲中没有数据或者数据被协议成功发送完毕后，recv先检查套接字s的接收缓冲区，如果s接收缓冲区中没有数据或者协议正在接收数据，那么recv就一直等待，直到协议把数据接收完毕。当协议把数据接收完毕，recv函数就把s的接收缓冲中的数据copy到buf中（注意协议接收到的数据可能大于buf的长度，所以 在这种情况下要调用几次recv函数才能把s的接收缓冲中的数据copy完。recv函数仅仅是copy数据，真正的接收数据是协议来完成的），

recv函数返回其实际copy的字节数。如果recv在copy时出错，那么它返回SOCKET_ERROR；如果recv函数在等待协议接收数据时网络中断了，那么它返回0。

注意：在Unix系统下，如果recv函数在等待协议接收数据时网络断开了，那么调用recv的进程会接收到一个SIGPIPE信号，进程对该信号的默认处理是进程终止。

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

需要记住的是，read是从系统的缓冲区读取的,write是写到tcp buffer里面的



**还有实现websocket协议的，实现sock5协议的**

见过的一个websocket的请求长这样
GET wss://nexus-websocket-b.xxx.io/pubsub/xxx?X-Nexus-New-Client=true&X-Nexus-Version=0.4.53 HTTP/1.1
Host: nexus-websocket-b.xxx.io
Connection: Upgrade
Pragma: no-cache
Cache-Control: no-cache
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3538.77 Safari/537.36
Upgrade: websocket
Origin: https://app.xxx.io
Sec-WebSocket-Version: 13
Accept-Encoding: gzip, deflate, br
Accept-Language: zh-CN,zh;q=0.9
Sec-WebSocket-Key: xaxsasdasdas==
Sec-WebSocket-Extensions: permessage-deflate; client_max_window_bits

Response长这样
HTTP/1.1 101 Switching Protocols
Date: Thu, 25 Oct 2018 06:07:10 GMT
Connection: upgrade
Upgrade: websocket
Sec-WebSocket-Accept: sasasasaD/tA=

这样也就完成了protocol upgrade的过程,webSocket是建立在http协议上的


- <del>js并不支持对操作系统socket的直接控制</del>，可能是安全因素(websocket倒是有，不过那是另外一回事了)。
node js是有[socket支持](https://www.runoob.com/nodejs/nodejs-net-module.html)的
```js
var net = require('net');       // 这个是tcp             
var client = new net.Socket();                         
client.connect(6000, "127.0.0.1");                     

client.on('data', function (data) {                   
    console.log('!!!!!!!!:' + data);
});

client.on('error', function (exception) {            
    console.log('socket error:' + exception);
//    client.end();
});
```

想要用udp的话有require('dgram');


```c
#include <unistd.h>
ssize_t read(int fd, void *buf, size_t count);
```
read这个函数返回的是读取的byte数，(On success, the number of bytes read is returned (zero indicates end of file), and the file position is advanced by this number;On error, -1 is returned, and errno is set appropriately.  In this case, it is left unspecified whether the file position (if any) changes.)

如果read的时候一直统计当前总的read到的bytes数，应该是要比content-length长不少的。
[那么一个字符到底多少个byte呢](https://stackoverflow.com/questions/4850241/how-many-bits-in-a-character)
首先要明白，read出来的东西是byte(是被utf-8编码过的)。几乎所有的语言在接收到之后都要重新解码一下，所以在这里decode一下，用c语言decode怎么弄？

- It depends what is the character and what encoding it is in:

- An ASCII character in 8-bit ASCII encoding is 8 bits (1 byte), though it can fit in 7 bits.

- An ISO-8895-1 character in ISO-8859-1 encoding is 8 bits (1 byte).

- A Unicode character in UTF-8 encoding is between 8 bits (1 byte) and 32 bits (4 bytes).

- A Unicode character in UTF-16 encoding is between 16 (2 bytes) and 32 bits (4 bytes), though most of the common characters take 16 bits. This is the encoding used by Windows internally.

- A Unicode character in UTF-32 encoding is always 32 bits (4 bytes).

- An ASCII character in UTF-8 is 8 bits (1 byte), and in UTF-16 - 16 bits.

- The additional (non-ASCII) characters in ISO-8895-1 (0xA0-0xFF) would take 16 bits in UTF-8 and UTF-16.


[what-is-the-default-encoding-for-c-strings](https://stackoverflow.com/questions/3996026/what-is-the-default-encoding-for-c-strings) 结论就是c语言的标准并没有规定用什么encoding    
> A c string is pretty much just a sequence of bytes. That means, that it does not have a well-defined encoding, it could be ASCII, UTF8 or anything else, for that matter. Because most operating systems understand ASCII by default, and source code is mostly written with ASCII encoding, so the data you will find in a simple (char*) will very often be ASCII as well. Nonetheless, there is no guarantee that what you get out of a (char*) will be UTF8 or even KOI8.

[java用utf-8,c用了ascii](https://stackoverflow.com/questions/45893641/output-difference-in-c-implementation-of-java-code)

 用上面的c语言的server发出这样一个字符串
 "你好啊\r\n"

 python的client每次读取一个字节,然后打印出0101这样的形式
 ```python
 while True:
    # 每次最多接收1个字节:
    d = s.recv(1)
    t = ''
    for x in d:
        t+= format(ord(x),'b')
        print(t)
    if d:
        buffer.append(d)
    else:
        break
data = b''.join(buffer)
print(data);
```

//在python的socket client这边接收到了
11100100
10111101
10100000
11100101
10100101
10111101
11100101
10010101
10001010


 b'\xe4'
 b'\xbd'
 b'\xa0'
 b'\xe5'
 b'\xa5'
 b'\xbd'
 b'\xe5'
 b'\x95'
 b'\x8a'
 '\r'
 '\n'
 因为tcp是有序的，所以发送端的字节以什么顺序排列的，接受端就是受到完全一样顺序排列的字节。这里因为网络传输是以字节为单位的。而sizeof(char) = 1 ，但是sizeof(int) = 4, 以上都还只是text-based content，字节序这回事只跟多字节类型的数据有关的比如int,short,long这类数字类型有关，所以基于文本传输的协议当然不存在字节序问题(当然content-length这种数字还是要注意一下的)。



 //在console里面还能够正常的打印出“你好啊”这三个字（包括换行也做了）

ut-8是变长的
Unicode符号范围        | UTF-8编码方式
(十六进制)             | （二进制）
----------------------+---------------------------------------------
      0 <--> 0x7f     | 0xxxxxxx
   0x80 <--> 0x7FF    | 110xxxxx 10xxxxxx
  0x800 <--> 0xFFFF   | 1110xxxx 10xxxxxx 10xxxxxx
0x10000 <--> 0x10FFFF | 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx


//来看这三个字的unicode码
你 -> u4f60 -----> 转换成二进制就是 0100 1111 0110 0000(位于上表的第三行，也就是三个字节) 把0100 1111 0110 0000塞进1110xxxx 10xxxxxx 10xxxxxx的xxx里面
得到11100100 10111101 10100000（E4 BD A0）
好 -> u597d -----> 同上，不再赘述
啊 -> u554a -----> 同上，不再赘述

在浏览器console里面输入
encodeURI('你好啊')
"%E4%BD%A0%E5%A5%BD%E5%95%8A" //是不是和python那边收到的东西很像

所以，c语言这边关键函数
send(sock_client,"你好啊",len,0);
看上去是发送了6个字节(每个汉字unicode两个字节)，实际上send调用下层在发送出去的时候回把这个6个字节的数据分散在9个字节长度的utf-8 byte array上。
可以认为发送6个字节，耗费9个字节的流量(如果发送的全部是ascii字符就不会这么浪费了，但其实utf-8已经很节省了)


**结论就是utf-8 encode的工作是底层根据locale做的，跟application无关。**


[libc只是当作以0结尾的字符串原封不动地write给内核，识别汉字的工作是由终端的驱动程序做的。](http://docs.linuxtone.org/ebooks/C&CPP/c/apas03.html)也就是基于当前的locale
```c
#include <stdio.h>

int main(void)
{
    printf("你好\n");
    return 0;
}
```
上述程序源文件是以UTF-8编码存储的：
```
$ od -tc nihao.c 
0000000   #   i   n   c   l   u   d   e       <   s   t   d   i   o   .
0000020   h   >  \n  \n   i   n   t       m   a   i   n   (   v   o   i
0000040   d   )  \n   {  \n  \t   p   r   i   n   t   f   (   " 344 275
0000060 240 345 245 275   \   n   "   )   ;  \n  \t   r   e   t   u   r
0000100   n       0   ;  \n   }  \n
0000107
```
> 其中八进制的344 375 240（十六进制e4 bd a0）就是“你”的UTF-8编码，八进制的345 245 275（十六进制e5 a5 bd）就是“好”。把它编译成目标文件，"你好\n"这个字符串就成了这样一串字节：e4 bd a0 e5 a5 bd 0a 00，汉字在其中仍然是UTF-8编码的，一个汉字占3个字节，这种字符在C语言中称为多字节字符（Multibyte Character）。运行这个程序相当于把这一串字节write到当前终端的设备文件。如果当前终端的驱动程序能够识别UTF-8编码就能打印出汉字，如果当前终端的驱动程序不能识别UTF-8编码（比如一般的字符终端）就打印不出汉字。也就是说，像这种程序，识别汉字的工作既不是由C编译器做的也不是由libc做的，C编译器原封不动地把源文件中的UTF-8编码复制到目标文件中，libc只是当作以0结尾的字符串原封不动地write给内核，识别汉字的工作是由终端的驱动程序做的。

[Unicode in C and C++: What You Can Do About It Today](https://www.cprogramming.com/tutorial/unicode.html)


## 不知道为什么,百度首页的response中没有content-length字段
read from socket , and write it to local file ,how about that?
[这篇文章提到](https://www.cnblogs.com/skynet/archive/2010/12/11/1903347.html)，由于http keep-alive的存在，读取server的response已经读不到EOF了，所以也就不能以EOF作为读取完毕的标志。分两种情况：有Content-length的，Transfer-Encoding：chunked（复杂一点点）这两种。
chunked简单说就是把一个大文件切分成N个小包，每个包(chunk)里面包括header和body。这个header里面也是有body的长度的。




## todo
** [sock5协议的解释](https://github.com/gwuhaolin/lightsocks)
c语言libevent实现简单的webserver
python selector实现高阶的httpserver
