---
title: 在ubuntu服务器上部署web app
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



## 3. Deploying node app on ubuntu(backgroud)
三种方法

> 1.  nohup node /home/zhoujie/ops/app.js & ## nohup就是不挂起的意思( no hang up)。 ignoring input and appending output to nohup.out // 输出被写入当前目录下的nohup.out文件中
> 2. screen ## 新开一个screen
> 3. pm2
npm install -g pm2
pm2 start app.js

[Configure Nginx as a web server and reverse proxy for Nodejs application on AWS Ubuntu 16.04 server](https://medium.com/@utkarsh_verma/configure-nginx-as-a-web-server-and-reverse-proxy-for-nodejs-application-on-aws-ubuntu-16-04-server-872922e21d38)



### Reference
1. [how-to-deploy-a-flask-application-on-an-ubuntu-vps](https://www.digitalocean.com/community/tutorials/how-to-deploy-a-flask-application-on-an-ubuntu-vps)
