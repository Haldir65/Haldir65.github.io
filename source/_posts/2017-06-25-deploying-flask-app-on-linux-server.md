---
title: 在ubuntu服务器上部署flask web app
date: 2017-06-25 22:46:23
categories: blog
tags: [python]
---

![](http://odzl05jxx.bkt.clouddn.com/ChMkJ1fAMmKIIFpWAA_5Us41gQkAAUv1QE2Pp8AD_lq599.jpg?imageView2/2/w/600)
<!--more-->

## 1. virtualenv install

```bash
sudo pip install virtualenv 
sudo virtualenv venv
source venv/bin/activate 
sudo pip install Flask 


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

```


## 2. install apache2 , mysql-server... on ubuntu
    重启apache2服务 service apache2 restart

## 3. Scrappy框架学习
首先建议安装virtualenv，在env中进行操作。
pip install Scrappy 报错
# error: Microsoft Visual C++ 14.0 is required. Get it with "Microsoft Visual C++ Build Tools": http://landinghub.visualstudio.com/visual-cpp-build-tools
解决办法是安装vs,4个GB左右。。。。


4.



### Reference
1. [how-to-deploy-a-flask-application-on-an-ubuntu-vps](https://www.digitalocean.com/community/tutorials/how-to-deploy-a-flask-application-on-an-ubuntu-vps)