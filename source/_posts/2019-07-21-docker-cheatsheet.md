---
title: docker学习笔记
date: 2019-07-21 20:18:17
tags:
---

docker相关的知识点
![](https://haldir66.ga/static/imgs/ship_docking_along_side_bay.jpg)
<!--more-->

> sudo apt install docker-compose

首先的首先，docker命令用sudo权限运行，会少很多麻烦
docker image 是snapshot, 而container是docker image的运行实例

youtube 上有人在 Digital Ocean 的 vps 上安装 docker，主要作用就是将一个复杂的操作系统打包成一个下载即用的容器。进入容器中，可以像在实际的操作系统中一样运行指令。所以虚拟化的机器随时可以使用其他操作系统。[how-to-install-and-use-docker-on-ubuntu-16-04](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-16-04)


docker常用的命令有那么几条
>docker run hello-world
docker search ubuntu
docker pull ubuntu 
docker run ubuntu ## 进入ubuntu这个container
docker images
docker run -it ubuntu
exit


## docker-compose 
使用docker-compose.yml的方式要比输入docker命令来的简单的多。就是将参数写入docker-compose.yml这个文件，然后运行docker-compose up -d命令的方式。

docker run -p 3000:3000 -ti dummy-app ## 每次都需要输入一大段命令行参数很烦人的，所以把配置写在一个docker-compose.yml文件里面，每次只需要docker-compose up就可以了。

## 这两条命令用于自己在本地打一个docker image
docker build -t <your username>/node-web-app .
docker build -t packsdkandroiddocker.image -f ./scripts/PackSdkDockerfile .
## 注意你修改了Dockerfile之后要重新跑一遍docker build -t <your username>/node-web-app .
[每次修改之后重新打image](https://stackoverflow.com/questions/18804124/docker-updating-image-along-when-dockerfile-changes)


docker会在/var/lib/docker文件夹里吃掉大量空间，释放空间的话
> docker system prune -a




[用docker host一个node js app](https://nodejs.org/en/docs/guides/nodejs-docker-webapp/)。实测下来image大小在600MB左右，内存占用200MB左右。

[用docker运行一个node mongodb应用](https://medium.com/@kahana.hagai/docker-compose-with-node-js-and-mongodb-dbdadab5ce0a) 亲测有效
[node的官方image太大了，alpine-node占用的磁盘空间更小](https://hub.docker.com/r/mhart/alpine-node/)




## 参考
[how-to-launch-containers-with-docker-compose](https://linuxconfig.org/how-to-launch-containers-with-docker-compose)

