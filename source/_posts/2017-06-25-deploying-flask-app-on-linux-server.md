---
title: 在ubuntu服务器上部署wsgi application
date: 2017-06-25 22:46:23
categories: blog
tags: [python]
---

![](http://odzl05jxx.bkt.clouddn.com/ChMkJ1fAMmKIIFpWAA_5Us41gQkAAUv1QE2Pp8AD_lq599.jpg?imageView2/2/w/600)
<!--more-->

## 1. virtualenv install

```shell
sudo pip install virtualenv
sudo virtualenv venv
source venv/bin/activate
sudo pip install Flask

## virtualenv指定python版本
virtualenv TEST --python=python2.7
virtualenv -p"$(which python3.6)" TEST ##linux这个也行
mkvirtualenv --python=`which python3` <env_name> ## 这个居然也行


# sudo python __init__.py
sudo /var/www/FlaskApp/FlaskApp/venv/bin/python2 __init__.py

deactivate # exit

Windows环境下安装virtualenv类似
在pycharm的cmd窗口中，
执行pip install virtualenv
virtualenv env #会生成一个新的ENV文件夹
cd env /Scripts
activate.bat # 此时光标变成(env) >.
退出很简单deactivate.bat即可

mac和linux平台下
source ./env/bin/activate
```


## 2. flask+nginx+wsgi
[Digital Ocean总有很多实用的教程](https://www.digitalocean.com/community/tutorials/how-to-serve-flask-applications-with-uwsgi-and-nginx-on-ubuntu-16-04),跟这个这里面的教程去部署flask app多半会碰到nginx 502。原因是生成的.sock文件的权限不对，所以在ini文件里面加上

> chmod-socket = 666

在venv里面不要用pip3，用pip

uwsgi协议的app跑起来之后是没有办法直接通过http去请求的，要让nginx转发一下。生成的.sock文件就是用来和nginx通信的。
这时候的在浏览器里面访问的port就是nginx决定的了。



## 3. Deploying node app on linux server





### Reference
1. [how-to-deploy-a-flask-application-on-an-ubuntu-vps](https://www.digitalocean.com/community/tutorials/how-to-deploy-a-flask-application-on-an-ubuntu-vps)
