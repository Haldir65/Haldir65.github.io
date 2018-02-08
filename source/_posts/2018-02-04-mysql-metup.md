---
title: mysql填坑记录
date: 2018-02-04 21:37:37
tags:
---

![](http://odzl05jxx.bkt.clouddn.com/image/jpg/fuchsia-973x547.jpg?imageView2/2/w/600)
<!--more-->
读音：
MySQL is pronounced as "my ess-que-ell," in contrast with SQL, pronounced "sequel."

RDBMS(关系型数据库)
RDBMS stands for Relational Database Management System. RDBMS is the basis for SQL, and for all modern database systems like MS SQL Server, IBM DB2, Oracle, MySQL, and Microsoft Access.
 mySql相关
## 安装
[How to Install MySQL on Ubuntu](https://www.digitalocean.com/community/tutorials/a-basic-mysql-tutorial)
[how-to-create-a-new-user-and-grant-permissions-in-mysql](https://www.digitalocean.com/community/tutorials/how-to-create-a-new-user-and-grant-permissions-in-mysql)
[a-basic-mysql-tutorial](https://www.digitalocean.com/community/tutorials/a-basic-mysql-tutorial)

> mysql -u root -p ## 以root身份登录

[Too many connections](https://stackoverflow.com/questions/4932503/how-to-kill-mysql-connections)
mysql连接多了容易爆内存，关掉的[方法](https://stackoverflow.com/questions/11091414/how-to-stop-mysqld)

> mysqladmin -u root -p shutdown ## 关闭
> sudo /etc/init.d/mysql restart ## 重启

[host-xxx-xx-xxx-xxx-is-not-allowed-to-connect-to-this-mysql-server](https://stackoverflow.com/questions/1559955/host-xxx-xx-xxx-xxx-is-not-allowed-to-connect-to-this-mysql-server)
> 1。 改表法。
可能是你的帐号不允许从远程登陆，只能在localhost。这个时候只要在localhost的那台电脑，登入mysql后，更改 "mysql" 数据库里的 "user" 表里的 "host" 项，从"localhost"改称"%"



配置文件的位置:
> nano /etc/mysql/mysql.conf.d/mysqld.conf

```sql
mysql -u root -p
use mysql;
update user set host = '%' where user = 'root';
select host, user from user;
```

2. 授权法。

例如，你想myuser使用mypassword从任何主机连接到mysql服务器的话。
```sql
GRANT ALL PRIVILEGES ON *.* TO 'myuser'@'%' IDENTIFIED BY 'mypassword' WITH GRANT OPTION;
FLUSH   PRIVILEGES;
```
如果你想允许用户myuser从ip为192.168.1.6的主机连接到mysql服务器，并使用mypassword作为密码
```sql
GRANT ALL PRIVILEGES ON *.* TO 'myuser'@'192.168.1.3' IDENTIFIED BY 'mypassword' WITH GRANT OPTION;

FLUSH   PRIVILEGES;
```
如果你想允许用户myuser从ip为192.168.1.6的主机连接到mysql服务器的dk数据库，并使用mypassword作为密码
```sql
GRANT ALL PRIVILEGES ON dk.* TO 'myuser'@'192.168.1.3' IDENTIFIED BY 'mypassword' WITH GRANT OPTION;

FLUSH   PRIVILEGES;
```


## HeidiSQL 中创建database记得选择character set 'utf-8'
Collation: 'utf_8_general_cli';

[sql tutorials](https://www.tutorialspoint.com/sql/sql-select-query.htm)
## CURD COMMANDS
首先要注意的是所有sql语句最后面都要跟一个分号
```sql
SHOW DATABASES;
CREATE DATABASE dbname;
USE dbname;

## show how many tables are there in this table
SHOW TABLES;

## create table
CREATE TABLE potluck (id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,name VARCHAR(20),food VARCHAR(30),confirmed CHAR(1),signup_date DATE);

## show everyting
SELECT * FROM potluck;

## how does potluck look like?
DESCRIBE potluck;

## ADD STUFF
INSERT INTO `potluck` (`id`,`name`,`food`,`confirmed`,`signup_date`) VALUES (NULL, "John", "Casserole","Y", '2012-04-11');

## update stuff
UPDATE `potluck` SET `confirmed` = 'Y' WHERE `potluck`.`name` ='Sandy';

## we want to add a column to table
ALTER TABLE potluck ADD email VARCHAR(40);

## this way we add to a specific position
ALTER TABLE potluck ADD email VARCHAR(40) AFTER name;

## drop this column
ALTER TABLE potluck DROP email;

## how about delete this row
DELETE from potluck  where name='Sandy';

```

### 支持的数据类型
signed or unsigned.(有符号或者无符号的)
- Numeric
INT (signed : -2147483648 to 2147483647  or unsigned: 0 to 4294967295.)，2的32次方(4 byte)
TINYINT(signed : -128 to 127, or unsigned: from 0 to 255)，2的八次方(1 byte)
BIGINT( signed :-32768 to 32767, or unsigned: from 0 to 65535.)，2的四次方(2 byte)
FLOAT(只能是signed)，
DOUBLE，
DECIMAL
- Date and Time
DATE (1973-12-30), DATETIME (1973-12-30 15:30:00),TIMESTAMP (19731230153000),TIME (HH:MM:SS),
- String Types.
CHAR(fixed-length，长度固定，不强制要求设置长度，默认1) ,
VARCHAR(ariable-length string between 1 and 255，长度可变， ),
BLOB or TEXT(BLOBs case sensitive，TEXT not case sensitive,这俩不需要设定长度，最大长度65535 )
ENUM (置顶的枚举类型中之一，可以为NULL)





## language support
[using mysql in node js](https://github.com/mysqljs/mysql)



### Another choice

[mariadb](https://mariadb.org/)
