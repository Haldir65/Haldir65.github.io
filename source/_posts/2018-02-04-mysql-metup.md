---
title: mysql填坑记录
date: 2018-02-04 21:37:37
tags:
---

![](http://odzl05jxx.bkt.clouddn.com/image/jpg/fuchsia-973x547.jpg?imageView2/2/w/600)
<!--more-->


 mySql相关
## 安装
[How to Install MySQL on Ubuntu](https://www.digitalocean.com/community/tutorials/a-basic-mysql-tutorial)
[how-to-create-a-new-user-and-grant-permissions-in-mysql](https://www.digitalocean.com/community/tutorials/how-to-create-a-new-user-and-grant-permissions-in-mysql)
[a-basic-mysql-tutorial](https://www.digitalocean.com/community/tutorials/a-basic-mysql-tutorial)

> mysql -u root -p ## 以root身份登录

[Too many connections](https://stackoverflow.com/questions/4932503/how-to-kill-mysql-connections)
mysql连接多了容易爆内存，关掉的[方法](https://stackoverflow.com/questions/11091414/how-to-stop-mysqld)

> mysqladmin -u root -p shutdown

[host-xxx-xx-xxx-xxx-is-not-allowed-to-connect-to-this-mysql-server](https://stackoverflow.com/questions/1559955/host-xxx-xx-xxx-xxx-is-not-allowed-to-connect-to-this-mysql-server)


## CURD COMMANDS
首先要注意的是所有sql语句最后面都要跟一个分号
> SELECT * FROM potluck;







## language support
[using mysql in node js](https://github.com/mysqljs/mysql)



### Another choice

[mariadb](https://mariadb.org/)
