---
title: Nginx使用记录
date: 2017-12-10 16:12:43
tags: [nginx,tools]
---

[installing nginx on windows](http://nginx.org/en/docs/windows.html)
![](http://odzl05jxx.bkt.clouddn.com/image/jpg/scenery151110073841.jpg?imageView2/2/w/600)
<!--more-->


### 1.安装
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

### 4.3 分享特定目录
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

### 4.4 Nginx软链接
目测不能用软链接

## 5. 问题速查
- nginx.service - A high performance web server and a reverse proxy server
   Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
   Active: failed (Result: exit-code) since Fri 2017-12-29 20:12:50 EST; 3min 21s ago

启动失败，检查/var/log/nginx/error.log 或者/var/log/syslog。





### 参考
- [nginx Configurations](https://wizardforcel.gitbooks.io/nginx-doc/content/Text/6.1_nginx_windows.html)
- [How To Install Nginx on Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-16-04)
