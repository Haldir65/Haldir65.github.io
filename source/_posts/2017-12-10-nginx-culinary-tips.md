---
title: Nginx使用记录
date: 2017-12-10 16:12:43
tags: [nginx,tools]
---

Nginx参考手册
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/scenery151110073841.jpg?imageView2/2/w/600)
<!--more-->


### 1.安装
[Installing nginx on windows](http://nginx.org/en/docs/windows.html)
安装教程，google 'installing nginx on ubuntu'
基本上就是把DigitalOcean写的这些复制粘贴过来


```shell
sudo apt-get update
sudo apt-get install nginx
## We can list the applications configurations that ufw knows how to work with by typing:
sudo ufw app list
sudo ufw allow 'Nginx HTTP'
sudo ufw status
```
### 1.1 安装失败的解决方案
>Job for nginx.service failed because the control process exited with error code.                 
 See "systemctl status nginx.service" and "journalctl -xe" for details.
invoke-rc.d: initscript nginx, action "start" failed.
● nginx.service - A high performance web server and a reverse proxy server
   Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)

根据[Nginx installation error in Ubuntu 16.04](https://askubuntu.com/questions/764222/nginx-installation-error-in-ubuntu-16-04)
解决方案:
> Check your nginx error log:
sudo cat /var/log/nginx/error.log|less
Then try again:
sudo apt-get update;sudo apt-get upgrade

我看到的是:
>2017/12/10 22:21:46 [emerg] 2485#2485: bind() to 0.0.0.0:80 failed (98: Address already in use)
2017/12/10 22:21:46 [emerg] 2485#2485: bind() to 0.0.0.0:80 failed (98: Address already in use)
2017/12/10 22:21:46 [emerg] 2485#2485: bind() to 0.0.0.0:80 failed (98: Address already in use)
2017/12/10 22:21:46 [emerg] 2485#2485: bind() to 0.0.0.0:80 failed (98: Address already in use)
2017/12/10 22:21:46 [emerg] 2485#2485: bind() to 0.0.0.0:80 failed (98: Address already in use)

就是80端口被占用了，看下谁在用:
> lsof -i:80

## 2. 常用command
```shell
## 查看当前status
systemctl status nginx
## stop
sudo systemctl stop nginx
## start
sudo systemctl start nginx
##重启
sudo systemctl restart nginx
##  改了配置文件之后可以直接reload，而不会失去连接
sudo systemctl reload nginx
## nginx默认开机启动的,取消开机启动
sudo systemctl disable nginx
##  加入开机启动
sudo systemctl enable nginx
```
## 3. 常用目录和文件(直接从DigitalOcean复制过来了)

- /var/www/html ## 就是放默认首页的地方（原因是 /etc/nginx/sites-enabled/default这里面设置的）
>
/etc/nginx: The Nginx configuration directory. All of the Nginx configuration files reside here.
/etc/nginx/nginx.conf: The main Nginx configuration file. This can be modified to make changes to the Nginx global configuration.
/etc/nginx/sites-available/: The directory where per-site "server blocks" can be stored. Nginx will not use the configuration files found in this directory unless they are linked to the sites-enabled directory (see below). Typically, all server block configuration is done in this directory, and then enabled by linking to the other directory.
/etc/nginx/sites-enabled/: The directory where enabled per-site "server blocks" are stored. Typically, these are created by linking to configuration files found in the sites-available directory.
/etc/nginx/snippets: This directory contains configuration fragments that can be included elsewhere in the Nginx configuration. Potentially repeatable configuration segments are good candidates for refactoring into snippets.

访问日志都在这里
>
/var/log/nginx/access.log: Every request to your web server is recorded in this log file unless Nginx is configured to do otherwise.
/var/log/nginx/error.log: Any Nginx errors will be recorded in this log.


## 4.配置文件
### 4.1 不想用80端口怎么办(比如跟apache冲突了)
修改 /etc/nginx/nginx.conf文件
config文件的大致结构就是这样,来自[stackoverflow](https://stackoverflow.com/questions/10829402/how-to-start-nginx-via-different-portother-than-80)
```bash
user www-data;
worker_processes  1;

error_log  /var/log/nginx/error.log;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
    # multi_accept on;
}

http {
    include       /etc/nginx/mime.types;

    access_log  /var/log/nginx/access.log;

    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;
    tcp_nodelay        on;

    gzip  on;
    gzip_disable "MSIE [1-6]\.(?!.*SV1)";

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;

   server {

        listen       81;

        location / {
         proxy_pass  http://94.143.9.34:9500;
         proxy_set_header   Host             $host:81;
         proxy_set_header   X-Real-IP        $remote_addr;
         proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
         proxy_set_header Via    "nginx";
        }


    }
}

 mail {
      See sample authentication script at:
      http://wiki.nginx.org/NginxImapAuthenticateWithApachePhpScript

      auth_http localhost/auth.php;
      pop3_capabilities "TOP" "USER";
      imap_capabilities "IMAP4rev1" "UIDPLUS";

     server {
         listen     localhost:110;
         protocol   pop3;
         proxy      on;
     }

     server {
         listen     localhost:143;
         protocol   imap;
         proxy      on;
     }
 }
```

比如想要通过81端口访问，加上这么一行
server {
    listen       81;
    server_name  example.org  www.example.org;
    root         /var/www/html/
}

Checking nginx config file syntax
> nginx -t -c conf/nginx.conf
nginx -s quit  //gracefully stop  on windows
nginx -s stop // force stop on windows

### 4.2 限制日志文件的大小
根据上面的config文件，默认的访问日志是在/var/log/nginx/access.log这个文件里面。限制这个文件的大小的方法：
[serverfault](https://serverfault.com/questions/427144/how-to-limit-nginx-access-log-file-size-and-compress)
```
/etc/logrotate.d/nginx
/var/log/nginx/access_log {
    rotate 7
    size 5k
    dateext
    dateformat -%Y-%m-%d
    missingok
    compress
    sharedscripts
    postrotate
        test -r /var/run/nginx.pid && kill -USR1 `cat /var/run/nginx.pid`
    endscript
}
```

需要注意的是，当网站访问量大后，日志数据就会很多，如果全部写到一个日志文件中去，文件会变得越来越大。文件大速度就会慢下来，比如一个文件几百兆。写入日志的时候，会影响操作速度。另外，如果我想看看访问日志，一个几百兆的文件，下载下来打开也很慢。为了方便对日志进行分析计算，需要对日志进行定时切割。定时切割的方式有按照月切割、按天切割，按小时切割等。最常用的是按天切割。[脚本](http://www.codeceo.com/article/nginx-log.html)

### 4.3 分享特定目录(serve static files)
[How to serve a directory of static files at a certain location path with nginx?](https://stackoverflow.com/questions/33989060/how-to-serve-a-directory-of-static-files-at-a-certain-location-path-with-nginx)
```
server {
  listen 80;
  server_name   something.nateeagle.com;

  location /something {
    alias /home/neagle/something;
    index index.html index.htm;
  }
}
```

有的时候会看到两种写法
```
location /static/ {
        root /var/www/app/static/;
        autoindex off;
}
## 结果是/var/www/app/static/static目录

location /static/ {
        alias /var/www/app/static/;
        autoindex off;
}
##这才是/var/www/app/static目录
```
[location里面写root还是alias](https://stackoverflow.com/questions/10631933/nginx-static-file-serving-confusion-with-root-alias)

[那alias标签和root标签到底有哪些区别呢？](http://blog.51cto.com/nolinux/1317109)
1、alias后跟的指定目录是准确的,并且末尾必须加“/”，否则找不到文件

location /c/ {
      alias /a/
}
如果访问站点http://location/c访问的就是/a/目录下的站点信息。
2、root后跟的指定目录是上级目录，并且该上级目录下要含有和location后指定名称的同名目录才行，末尾“/”加不加无所谓。

location /c/ {
      root /a/
}
如果访问站点http://location/c访问的就是/a/c目录下的站点信息。
3、一般情况下，在location /中配置root，在location /other中配置alias是一个好习惯。

在windows平台下这么写
```
location / {
           root D:/VDownload;
           index index.html index.htm;
       }
```
> nginx -s reload 然后重启nginx


### 4.4 Nginx软链接
目测不能用软链接


###4.5 Nginx通过CORS实现跨域
在nginx.conf里找到server项,并在里面添加如下配置
```
location / {
add_header 'Access-Control-Allow-Origin' 'http://example.com';
add_header 'Access-Control-Allow-Credentials' 'true';
add_header 'Access-Control-Allow-Headers' 'Authorization,Content-Type,Accept,Origin,User-Agent,DNT,Cache-Control,X-Mx-ReqToken,X-Requested-With';
add_header 'Access-Control-Allow-Methods' 'GET,POST,OPTIONS';
...
}
```

但上述配置只能实现允许一个domain或者*实现跨域，Nginx允许多个域名跨域访问
在location context的上层添加
```config
map $http_origin $corsHost {
    default 0;
    "~http://www.example.com" http://www.example.com;
    "~http://m.example.com" http://m.example.com;
    "~http://wap.example.com" http://wap.example.com;
}

server
{
    listen 80;
    server_name www.example2.com;
    root /usr/share/nginx/html;
    location /
    {
        add_header Access-Control-Allow-Origin $corsHost;
    }
}
```

## 5. proxy_pass
根据[how-to-set-up-a-node-js-application-for-production-on-ubuntu-14-04](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-node-js-application-for-production-on-ubuntu-14-04)
> /etc/nginx/sites-available/default
``` config
server {
    listen 80;

    server_name example.com;

    location / {
        proxy_pass http://APP_PRIVATE_IP_ADDRESS:8080; // A应用跑在8080端口，外部访问http://example.com/即可访问应用服务
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location /app2 {
       proxy_pass http://APP_PRIVATE_IP_ADDRESS:8081; // B应用跑在8081端口，外部访问http://example.com/app2即可访问应用服务
       proxy_http_version 1.1;
       proxy_set_header Upgrade $http_upgrade;
       proxy_set_header Connection 'upgrade';
       proxy_set_header Host $host;
       proxy_cache_bypass $http_upgrade;
   }
}
```

### 5.1 pratical take aways
[nginx配置location总结及rewrite规则写法](http://seanlook.com/2015/05/17/nginx-location-rewrite/)


### ddos防御
from [mitigating-ddos-attacks-with-nginx-and-nginx-plus/](https://www.nginx.com/blog/mitigating-ddos-attacks-with-nginx-and-nginx-plus/)

**allow a single client IP address to attempt to login only every 2 seconds (equivalent to 30 requests per minute):**


1. Limiting the Rate of Requests
eg: 单ip访问login接口频率不能超过2秒每次。
```config
limit_req_zone $binary_remote_addr zone=one:10m rate=30r/m;

server {
    # ...
    location /login.html {
        limit_req zone=one;
    # ...
    }
}
```
2. Limiting the Number of Connections
eg: 单ip访问/store/不能创建超过10条connections
```config
limit_conn_zone $binary_remote_addr zone=addr:10m;

server {
    # ...
    location /store/ {
        limit_conn addr 10;
        # ...
    }
}
```

3. Closing Slow Connections
eg: 限定nginx一条connection写client header和写client body的时间间隔为5s，默认为60s
```config
server {
    client_body_timeout 5s;
    client_header_timeout 5s;
    # ...
}
```

4. 黑名单
```config
// 123.123.123.1 through 123.123.123.16 拉黑
location / {
    deny 123.123.123.0/28;
    # ...
}

location / {
    deny 123.123.123.3;
    deny 123.123.123.5;
    deny 123.123.123.7;
    # ...
}

//只允许特定白名单
location / {
    allow 192.168.1.0/24;
    deny all;
    # ...
}
```

5.  ngx_http_proxy_module的configuration
proxy_cache_use_stale
当客户端请求一项过期的资源时，只发送一次请求，在backend server返回新的资源之前，不再发送新的请求，并只向客户端返回已有的过期资源。这有助于缓解backend server的压力。
proxy_cache_key:包含内置三个key$scheme$proxy_host$request_uri。但不要添加$query_string，这会造成过多的caching.

6. 几种情况是应该直接拉黑的
>Requests to a specific URL that seems to be targeted  
Requests in which the User-Agent header is set to a value that does not correspond to normal client traffic
Requests in which the Referer header is set to a value that can be associated with an attack
Requests in which other headers have values that can be associated with an attack

```config
location /foo.php {
    deny all; //直接让这个接口不响应
}

location / {
    if ($http_user_agent ~* foo|bar) {
        return 403;  //User-Agent中有foo或者bar的时候直接forbidden
    }
    # ...
}

// NGINX Plus提供的
// An NGINX or NGINX Plus instance can usually handle many more simultaneous connections than the backend servers it is load balancing.
//作为代理，nginx能够接受的连接数要远超其代理的后台服务
upstream website {
    server 192.168.100.1:80 max_conns=200;
    server 192.168.100.2:80 max_conns=200;
    queue 10 timeout=30s;
}
```

### 5.2 Nginx模块
http_image_filter_module（图片裁剪模块）
首先查看是否已安装http_image_filter_module模块
> nginx -V
/etc/nginx/nginx.conf文件添加
```config
location /image {
		   alias "/imgdirectory/";  ## 这样直接输入 yourip/image/imgname.jpeg就能返回原始图片
}
location ~* (.*\.(jpg|jpeg|gif|png))!(.*)!(.*)$ {  ## 这个是匹配全站图片资源
        		set $width      $3;  
        		set $height     $4;  
        		rewrite "(.*\.(jpg|jpeg|gif|png))(.*)$" $1;  ## 这样输入 yourip/image/imgname.jpeg!200!200就能返回200*200的图片
}  

location ~* /imgs/.*\.(jpg|jpeg|gif|png|jpeg)$ {  
			root "/var/www/";
  		image_filter resize $width $height;  
}
```
亲测上述可行，python也有类似库[thumbor](https://github.com/thumbor/thumbor)

关于正则匹配：
```config
## 比如匹配全站所有的结尾图片
location ~* \.(jpg|gif|png)$ {

               image_filter resize 500 500;

       }

### 匹配某个目录所有图片       
location ~* /image/.*\.(jpg|gif|png)$ {

            image_filter resize 500 500;

    }
```
更多直接google吧。


### 添加黑名单
```shell
##获取各个IP访问次数

awk '{print $1}' nginx.access.log |sort |uniq -c|sort -n

## 新建一个黑名单文件 blacklist.conf ,放在 nginx/conf下面。

  ##添加一个IP ，deny 192.168.59.1;

### 在http或者server模块引入

  include blacklist.conf ;

##需要重启服务器, nginx -s reload; 即可生效
```
防御DDOS是一个系统工程，这里只是一小点。


### 5.3 return rewrite and try_files
```config
server {
    listen 80;
    listen 443 ssl;
    server_name www.old-name.com;
    return 301 $scheme://www.new-name.com$request_uri;
}
301 (Moved Permanently)
//上面的scheme是http或者https，request_url就是请求的url。
```

rewrite就更加复杂一点，比如可以manipulate url
Here’s a sample NGINX rewrite rule that uses the rewrite directive. It matches URLs that begin with the string /download and then include the /media/ or /audio/ directory somewhere later in the path. It replaces those elements with /mp3/ and adds the appropriate file extension, .mp3 or .ra. The $1 and $2 variables capture the path elements that aren't changing. As an example, /download/cdn-west/media/file1 becomes /download/cdn-west/mp3/file1.mp3. If there is an extension on the filename (such as .flv), the expression strips it off and replaces it with .mp3.
```config
server {
    # ...
    rewrite ^(/download/.*)/media/(\w+)\.?.*$ $1/mp3/$2.mp3 last;
    rewrite ^(/download/.*)/audio/(\w+)\.?.*$ $1/mp3/$2.ra  last;
    return  403;
    # ...
}
```


In the following example, NGINX serves a default GIF file if the file requested by the client doesn’t exist. When the client requests (for example) http://www.domain.com/images/image1.gif, NGINX first looks for image1.gif in the local directory specified by the root or alias directive that applies to the location (not shown in the snippet). If image1.gif doesn’t exist, NGINX looks for image1.gif/, and if that doesn’t exist, it redirects to /images/default.gif. That value exactly matches the second location directive, so processing stops and NGINX serves that file and marks it to be cached for 30 seconds.
```config
location /images/ {
    try_files $uri $uri/ /images/default.gif;
}

location = /images/default.gif {
    expires 30s;
}
```

### 6. 问题速查
- nginx.service - A high performance web server and a reverse proxy server
   Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
   Active: failed (Result: exit-code) since Fri 2017-12-29 20:12:50 EST; 3min 21s ago

启动失败，检查/var/log/nginx/error.log 或者/var/log/syslog。
windows下应该在nginx/logs/error.log文件里面
windows平台下查找当前正在跑的nginx进程：
> tasklist /fi "imagename eq nginx.exe"

==============================================================================================================================


### 参考
- [nginx Configurations](https://wizardforcel.gitbooks.io/nginx-doc/content/Text/6.1_nginx_windows.html)
- [How To Install Nginx on Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-16-04)
- [understanding-the-nginx-configuration-file](https://www.digitalocean.com/community/tutorials/understanding-the-nginx-configuration-file-structure-and-configuration-contexts)
- [if is evil, 可以,但不要在config文件里面写if](https://www.nginx.com/resources/wiki/start/topics/depth/ifisevil/)
- [nginx的一些优化策略](https://www.digitalocean.com/community/tutorials/how-to-optimize-nginx-configuration)
- [rewrite rules怎么写](https://www.nginx.com/blog/creating-nginx-rewrite-rules/)
