---
title: mysql填坑记录
date: 2018-02-04 21:37:37
tags:
---

![](http://odzl05jxx.bkt.clouddn.com/image/jpg/fuchsia-973x547.jpg?imageView2/2/w/600)
<!--more-->
关系型数据库很多如，MS Access, SQL Server, MySQL
NoSQL(NoSQL = Not Only SQL )，意即"不仅仅是SQL"，NOSQL是基于键值对的，可以想象成表中的主键和值的对应关系，而且不需要经过SQL层的解析，所以性能非常高。典型的代表如MongoDb.

读音：
MySQL is pronounced as "my ess-que-ell," in contrast with SQL, pronounced "sequel."

RDBMS(关系型数据库)
RDBMS stands for Relational Database Management System. RDBMS is the basis for SQL, and for all modern database systems like MS SQL Server, IBM DB2, Oracle, MySQL, and Microsoft Access.

[sql tutorials](https://www.tutorialspoint.com/sql/sql-select-query.htm)

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
> sudo systemctl disable mysql ##禁止开机启动
[host-xxx-xx-xxx-xxx-is-not-allowed-to-connect-to-this-mysql-server](https://stackoverflow.com/questions/1559955/host-xxx-xx-xxx-xxx-is-not-allowed-to-connect-to-this-mysql-server)
> 1。 改表法。
可能是你的帐号不允许从远程登陆，只能在localhost。这个时候只要在localhost的那台电脑，登入mysql后，更改 "mysql" 数据库里的 "user" 表里的 "host" 项，从"localhost"改称"%"

[windows登录出错报10061的解决方式](https://stackoverflow.com/questions/119008/cant-connect-to-mysql-server-on-localhost-10061)
services.msc => 找到MySQL57 => 右键（启动）


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
SELECT user_id FROM potluck;
SELECT  FROM potluck; // 这么写sql 语法有误，必须声明想要选出那些column


## how does potluck look like?
DESCRIBE potluck;

##我想看看当初这表的建表语句长什么样？
show create table potluck;

## ADD STUFF
INSERT INTO `potluck` (`id`,`name`,`food`,`confirmed`,`signup_date`) VALUES (NULL, "John", "Casserole","Y", '2012-04-11');
### 亲测，在heidisql中这么输入也能insert一行,所以这些冒号也不是必须的
INSERT INTO user (user_id,login,password,email,date_added,date_modified) VALUES (1,"firstlogin","dumbpasws","sample@email.com",'2012-03-09','2018-01-09');

## update stuff
UPDATE `potluck` SET `confirmed` = 'Y' WHERE `potluck`.`name` ='Sandy';
UPDATE user SET user_id = 11 WHERE user_id =10;## 亲测这么干也没问题
SELECT user_id FROM user WHERE user_nick = 'john' OR user_id > 10; ## 精确匹配字符串用等号

UPDATE user SET salary= 10000 WHERE salary is NULL;## 更新的时候用=号，判断为空用IS NULL ，对应的也有IS NOT NULL.
UPDATE user SET salary= 22000 WHERE salary < 20000; ## 亲测这么干也行

## 这样的条件语句还有很多，这个应该叫做Operator(操作符)
操作符主要分为四类
Arithmetic operators  （数学加减乘除）
Comparison operators（比较大小的）
Logical operators （逻辑运算符） AND， ANY, BETWEEN,EXISTS,LIKE,OR ,IS NULL ,IS NOT NULL, UNIQUE
Operators used to negate conditions

挑几个不容易理解的，下面这个叫做子查询
SELECT * FROM user WHERE EXISTS (SELECT * FROM todo WHERE user_id = 1) ;



## UNIQUE是用在创建表或者改表结构的:
CREATE TABLE Persons
(
Id_P int NOT NULL,
LastName varchar(255) NOT NULL,
FirstName varchar(255),
Address varchar(255),
City varchar(255),
UNIQUE (Id_P)
)
// unique的意思很明显，不能允许出现同样的row

如果在SELECT的时候想要去重，用DISTINCT
SELECT DISTINCT content FROM todo;
SELECT COUNT(*) FROM  todo; // 看下当前数据库有多少行了
SELECT COUNT(DISTINCT content) FROM  todo; // 去重后看下有多少行

### 模糊查询

SELECT * FROM [user] WHERE u_name LIKE '%三%'; //将会把u_name为“张三”，“张猫三”、“三脚猫”，“唐三藏”等等有“三”的记录全找出来。
SELECT * FROM [user] WHERE u_name LIKE '_三_';  //只找出“唐三藏”这样u_name为三个字且中间一个字是“三”的；_ ： 表示任意单个字符。匹配单个任意字符，它常用来限制表达式的字
符长度语句：
SELECT * FROM [user] WHERE u_name LIKE '[张李王]三' ; 将找出“张三”、“李三”、“王三”（而不是“张李王三”）；
SELECT * FROM [user] WHERE u_name LIKE '[^张李王]三'; 将找出不姓“张”、“李”、“王”的“赵三”、“孙三”等；

## orderBy
SELECT * FROM CUSTOMERS ORDER BY NAME DESC; //就是把查出来的结果排序，按照名称的ASIC顺序倒序排列

## groupBy
GROUP BY的顺序在orderBy前面(groupby要写在orderby前面)，意思就是把相同结果的整合成一行
基本的语法是
SELECT column_one FROM table_name WHERE
  column_two = "" AND ...
  GROUP BY column_one
  ORDER BY column_two;

SELECT NAME, SUM(SALARY) FROM CUSTOMERS
   GROUP BY NAME; // 这里还用了sum函数，计算CUSTOMER表中各个用户的salary总和，name相同的算作一个合并起来。


## we want to add a column to table
ALTER TABLE potluck ADD email VARCHAR(40);

## this way we add to a specific position
ALTER TABLE potluck ADD email VARCHAR(40) AFTER name;

## drop this column
ALTER TABLE potluck DROP email;

## how about delete this row
DELETE from potluck  where name='Sandy';

## 从删库到跑路
TRUNCATE TABLE  table_name; //将这张表的内容全部抹掉
DROP TABLE table_name; //删除这个数据库
```

一些实用的例子：
## 单列数据分组统计
SELECT id,name,SUM(price) AS title,date FROM tb_price GROUP BY pid ORDER BY title DESC;
## 多列数据分组统计
SELECT id,name,SUM(price*num) AS sumprice  FROM tb_price GROUP BY pid ORDER BY sumprice DESC;
## 多表分组统计
SELECT a.name,AVG(a.price),b.name,AVG(b.price) FROM tb_demo058 AS a,tb_demo058_1 AS b WHERE a.id=b.id GROUP BY b.type;

## 跨表查询
现实生活中经常要从多个数据表中读取数据，关键字JOIN
根据ForeignKey去查询：
```sql
## 主表
create table department(
            id int primary key auto_increment,
            name varchar(20) not null,
            description varchar(100)
);

## 从表，外键是在从表中创建，从而找到与主表之间的联系
create table employee(
            id int primary key auto_increment,
            name varchar(10) not null,
            gender varchar(2) not null,
            salary float(10,2),
            age int(2),
            gmr int,
            dept_id int
);

## 外键可以在建表的时候加，也可以在建表完成之后加
ALTER TABLE employee ADD FOREIGN KEY(dept_id) REFERENCES department(id); 


[ON DELETE {RESTRICT | CASCADE | SET NULL | NO ACTION}]

[ON UPDATE {RESTRICT | CASCADE | SET NULL | NO ACTION} 

## 写django的时候就会注意到CASCADE（级联）这个单词，如果主表的记录删掉，则从表中相关联的记录都将被删掉。
RESTRICT(限制)：如果你想删除的那个主表，它的下面有对应从表的记录，此主表将无法删除。（这个好像是默认规则）
SET NULL：将外键设置为空。
NO ACTION：什么都不做。

```
以上，每个员工有一个dep_id的Foreign_key，对应department表中的id.
删除外键
>alter table emp drop foreign key 外键名;

开始联表查询，区分inner join ,left join, right join
```sql
##下面这俩一样的
##inner join，只列出匹配的记录
select e.name,d.name from employee e inner join department d on e.dept_id=d.id; ##inner可以不写，默认是inner
select e.name,d.name from employee e,department d where e.dept_id=d.id; 

## left join 左连接即以左表为基准，显示坐标所有的行，右表与左表关联的数据会显示，不关联的则不显示。
select table a left join table b on a.id = b.ta_id;

## right join 右表列出全部，左表只列出匹配的记录。

## 自连接(据说非常重要)，下面这句查询出员工姓名及其leader的姓名，是的，sql语句里面赋值都是行的。这种带点号的还真像object oriented promramming
select e1.name 员工, e2.name 领导 from employee e1 left join employee e2 on e1.leader=e2.id;
## 等于说根据表名虚拟出两张表
## 查询所有leader的姓名
select e2.name 领导 from employee e1 left join employee e2 on e1.leader=e2.id;
```

以上还只是两张表连在一起查，现实中还有n张表连在一起查，下面这个是三张表一起查
>select table a left join table b(left join table c on b.id = c.tb_id) on a.id = b_ta.id

再加的话就是多张表在一起查，其实就是一层层的sql嵌套，写的时候从外层往里面写，一层层left join。
## 这个子查询是查找月薪最高的员工的名字
SELECT name,salary from employee where salary=(select max(salary) from employee);

## 查询每个部门的平均月薪
select avg(salary),dept_id from employee where dept_id is not null group by depy_id;


## AUTO_INCREMENT
在sqlite3中是[这么](https://stackoverflow.com/questions/26652393/how-to-correctly-set-auto-increment-fo-a-column-in-sqlite-using-python)干的
下面的python sqlalchemy语句是亲测通过的
```python
from sqlalchemy import create_engine

db_uri = "sqlite:///db.sqlite"
engine = create_engine(db_uri)

# DBAPI - PEP249
# create table
engine.execute('CREATE TABLE IF NOT EXISTS "EX1" ('
               'id INTEGER PRIMARY KEY AUTOINCREMENT,'
               'name VARCHAR);')
# insert a raw
engine.execute('INSERT INTO "EX1" '
               '( name) '
               'VALUES ("raw1")')

# select *
result = engine.execute('SELECT * FROM '
                        '"EX1"')
for _r in result:
   print(_r)

# delete *
# engine.execute('DELETE from "EX1" where id=1;')
result = engine.execute('SELECT * FROM "EX1"')
print(result.fetchall())
```
auto increment只要在insert的时候直接忽略掉自增的字段就好了，否则会报unique constraint failed

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
<del>BOOLEAN类型是不存在的</del>用TINYINT就好了，0表示false，1表示true;

### 约束
constraint的一个例子，A表的一个column引用了B表的一个id键作为foreign key.这时候如果想往A表里添加数据，假如尝试添加的这个外键在B表中不存在，会无法执行。
```sql
INSERT INTO todo (todo_id,user_id,content,completed,date_added,date_modified) VALUES (102,11,"random stufffssss",0,"2012-02-09","2016-03-27");
```

##  Joins clause 从多个表中进行查询，对共有的属性进行操作
```sql
SELECT ID, NAME, AGE, AMOUNT FROM CUSTOMERS, ORDERS WHERE  CUSTOMERS.ID = ORDERS.CUSTOMER_ID;

inner join(查的是customer表，但查出来的结果里有来自ORDERS的column)
SQL> SELECT  ID, NAME, AMOUNT, DATE
   FROM CUSTOMERS
   INNER JOIN ORDERS
   ON CUSTOMERS.ID = ORDERS.CUSTOMER_ID;
```

## 时间戳
这一部分应该属于sql的函数了
```sql
SELECT CURDATE();  // YYYY-MM-DD格式 2018-02-10
select now(); // 2018-02-10 15:49:10
想要时间戳的话可以这么干
SELECT  unix_timestamp(); // 1518249025
select unix_timestamp('2008-08-08');  // 1218124800
select unix_timestamp(CURDATE());   //1518192000

// insert一行的时候自动设置插入的时间戳，当然简单了.
Create Table Student
(
  Name varchar(50),
  DateOfAddmission datetime default CURRENT_TIMESTAMP
);

/*下面这个也是行的，CURRENT_TIMESTAMP是一个关键字*/
CREATE TABLE foo (
    creation_time      DATETIME DEFAULT   CURRENT_TIMESTAMP,
    modification_time  DATETIME ON UPDATE CURRENT_TIMESTAMP
)

modification_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
```

### 建索引(Advanced sql)
常常听后台的人说，这个sql查询太慢了，要建索引哈。
但是索引对于提高查询性能也不是万能的，也不是建立越多的索引就越好。索引建少了，用 WHERE 子句找数据效率低，不利于查找数据。索引建多了，不利于新增、修改和删除等操作，因为做这些操作时，SQL SERVER 除了要更新数据表本身，还要连带立即更新所有的相关索引，而且过多的索引也会浪费硬盘空间。

查了下
```sql
CREATE INDEX PersonIndex
ON Person (LastName) ; //名为 "PersonIndex"，在 Person 表的 LastName 列：
```
sql建索引主要是为了查找的时候能够跟翻字典一样快。一般来说，主键，外键应该建索引，频繁更新的列就不要更新索引了
```sql
CREATE INDEX salary_index ON COMPANY(salary); // 创建索引
SELECT * FROM COMPANY INDEXED BY salary_index WHERE salary > 5000; //创建好了之后就要根据index来查了

适合建索引的列是出现在WHERE子句中的列，或者join子句(on语句)中指定的列，就是说那些被当做条件的东西应该作为索引。
索引不要搞得太多，建立索引和维护索引都比较耗时。update,delete,insert都要维护索引
```


### Transaction 事务
- Atomicity − ensures that all operations within the work unit are completed successfully. Otherwise, the transaction is aborted at the point of failure and all the previous operations are rolled back to their former state.

- Consistency − ensures that the database properly changes states upon a successfully committed transaction.

- Isolation − enables transactions to operate independently of and transparent to each other.

- Durability − ensures that the result or effect of a committed transaction persists in case of a system failure.

论ACID是什么
事务的写法
```sql
BEGIN;
DELETE FROM CUSTOMERS
   WHERE AGE = 25;
ROLLBACK; //回滚
COMMIT; //提交更改
SAVEPOINT SAVEPOINT_NAME;
ROLLBACK TO SAVEPOINT_NAME;
```


## language support
### java


java的版本[accessing-data-mysql](https://spring.io/guides/gs/accessing-data-mysql/)
```java
package com.vae.jdbc;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class JDBCtest {
    //数据库连接地址
    public final static String URL = "jdbc:mysql://localhost:3306/JDBCdb";
    //用户名
    public final static String USERNAME = "root";
    //密码
    public final static String PASSWORD = "smyh";
    //驱动类
    public final static String DRIVER = "com.mysql.jdbc.Driver";

    public static void main(String[] args) {
        // TODO Auto-generated method stub
        //insert(p);
        //update(p);
        //delete(3);
        insertAndQuery();
    }

    //方法：使用PreparedStatement插入数据、更新数据
    public static void insertAndQuery(){
        Connection conn = null;
        try {
            Class.forName(DRIVER);
            conn = DriverManager.getConnection(URL, USERNAME, PASSWORD);
            String sql1 = "insert into user(name,pwd)values(?,?)";
            String sql2 = "update user set pwd=? where name=?";
            PreparedStatement ps = conn.prepareStatement(sql1); // 这行其实比较费性能
            ps.setString(1, "smyhvae");
            ps.setString(2, "007");            
            ps.executeUpdate();

            ps = conn.prepareStatement(sql2);
            ps.setString(1, "008");
            ps.setString(2, "smyh");            
            ps.executeUpdate();            

            ps.close();
            conn.close();            

        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

}
```
[Spring里面用的是jpa](https://spring.io/guides/gs/accessing-data-jpa/)


python的版本[python-mysql](http://www.runoob.com/python/python-mysql.html)
> python3不再支持mysqldb 请用pymysql和mysql.connector

```python
import pymysql 
conn = pymysql.connect(host=’127.0.0.1’, port=3306, user=’root’, passwd=’test’, 
db=’mysql’) 
cur = conn.cursor() 
cur.execute(“SELECT * FROM user”) 
for r in cur.fetchall(): 
    print(r) 
#cur.close() 
conn.close()
```
实际开发中都用的orm框架,sqlAlchemy

### nodejs
[using mysql in node js](https://github.com/mysqljs/mysql)


## 更新
SQLite支持事务，这就以外这需要在并发环境下，保持事务的ACID特性。Sqlite的锁实现基于文件锁，对于Linux系统，文件锁主要包含协同锁和强制锁。


[sqlite不支持删除column,确定无疑](https://stackoverflow.com/questions/8442147/how-to-delete-or-add-column-in-sqlite)
SQLite supports a limited subset of ALTER TABLE. The ALTER TABLE command in SQLite allows the user to rename a table or to add a new column to an existing table. It is not possible to rename a column, remove a column, or add or remove constraints from a table.
It is not possible to rename a column, remove a column, or add or remove constraints from a table。//更改约束也不行

alter table record drop column name;  //报错

//一种周转的方法
create table temp as select recordId, customer, place, time from record where 1 = 2;  //复制record的表结构，不包含内容
drop table record;  
alter table temp rename to record;  

// Sqlite的优化手段
1. beginTransaction
2. DB.compileStatement("DELETE FROM users WHERE first_name = ?")//节省了每次parse sql语句的开销
3. [sqlite一次插入多条记录的优化方法](https://www.jianshu.com/p/faa5e852b76b)，使用union


观察到一个现象，在编辑数据库，数据库打开的情况下，test.db所在的文件夹下面同时生成了一个test.db.journal文件，一旦关闭数据库连接，这个文件就没了。


你的数据库用什么存储引擎？区别是？
答案：常见的有MyISAM和InnoDB。
MyISAM：不支持外键约束。不支持事务。对数据大批量导入时，它会边插入数据边建索引，所以为了提高执行效率，应该先禁用索引，在完全导入后再开启索引。
InnoDB：支持外键约束，支持事务。对索引都是单独处理的，无需引用索引。



[联表一对多查询](https://www.thatyou.cn/flask%E4%BD%BF%E7%94%A8flask-sqlalchemy%E6%93%8D%E4%BD%9Cmysql%E6%95%B0%E6%8D%AE%E5%BA%93%EF%BC%88%E4%B8%89%EF%BC%89-%E8%81%94%E8%A1%A8%E4%B8%80%E5%AF%B9%E5%A4%9A%E6%9F%A5%E8%AF%A2/)
[联表多对多查询](https://www.thatyou.cn/flask%E4%BD%BF%E7%94%A8flask-sqlalchemy%E6%93%8D%E4%BD%9Cmysql%E6%95%B0%E6%8D%AE%E5%BA%93%EF%BC%88%E5%9B%9B%EF%BC%89-%E8%81%94%E8%A1%A8%E5%A4%9A%E5%AF%B9%E5%A4%9A%E6%9F%A5%E8%AF%A2/)
### Another choice

[mariadb](https://mariadb.org/) MariaDb是在oracle收购mysql之后，社区fork的一个mysql版本，除了packagename不一样以外，操作都差不多。
PostgreSQL


建表语句:
```sql
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `user_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_name` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `user_password` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `user_nickname` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT '',
  `user_email` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  PRIMARY KEY (`user_id`),
  KEY `user_name` (`user_name`),


CREATE TABLE `news` (`news_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,`news_author` int(6) NOT NULL DEFAULT '0',`news_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,`news_content` longtext COLLATE utf8mb4_unicode_ci NOT NULL,`news_title` text COLLATE utf8mb4_unicode_ci NOT NULL,`news_excerpt` text COLLATE utf8mb4_unicode_ci NOT NULL,`news_status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'publish',`news_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,`news_category` int(4) NOT NULL,PRIMARY KEY (`news_id`), KEY `type_status_date` (`news_status`,`news_date`,`news_id`),KEY `post_author` (`news_author`)) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

mysql> describe user;
+---------------+---------------------+------+-----+---------+----------------+
| Field         | Type                | Null | Key | Default | Extra          |
+---------------+---------------------+------+-----+---------+----------------+
| user_id       | bigint(20) unsigned | NO   | PRI | NULL    | auto_increment |
| user_name     | varchar(60)         | NO   | MUL |         |                |
| user_password | varchar(30)         | NO   |     |         |                |
| user_nickname | varchar(50)         | YES  |     |         |                |
| user_email    | varchar(100)        | NO   | MUL |         |                |
+---------------+---------------------+------+-----+---------+----------------+
5 rows in set (0.00 sec)

mysql> describe news;
+---------------+---------------------+------+-----+-------------------+----------------+
| Field         | Type                | Null | Key | Default           | Extra          |
+---------------+---------------------+------+-----+-------------------+----------------+
| news_id       | bigint(20) unsigned | NO   | PRI | NULL              | auto_increment |
| news_author   | int(6)              | NO   | MUL | 0                 |                |
| news_date     | datetime            | NO   |     | CURRENT_TIMESTAMP |                |
| news_content  | longtext            | NO   |     | NULL              |                |
| news_title    | text                | NO   |     | NULL              |                |
| news_excerpt  | text                | NO   |     | NULL              |                |
| news_status   | varchar(20)         | NO   | MUL | publish           |                |
| news_modified | datetime            | NO   |     | CURRENT_TIMESTAMP |                |
| news_category | int(4)              | NO   |     | NULL              |                |
+---------------+---------------------+------+-----+-------------------+----------------+
9 rows in set (0.00 sec)

[spring官方给的手把手教程很详细](https://spring.io/guides/gs/accessing-data-mysql/)
乐观锁(需要自己实现或者使用orm框架)和悲观锁(数据库自带).
悲观锁包括共享锁和排他锁:
共享锁: 在执行sql语句屁股后面加上lock in share mode
排他锁：在执行sql语句屁股后面加上for update

举个例子：
```sql
begin; ##开启一个实务，不commit
SELECT * from city where id = "1"  lock in share mode;

update  city set name="666" where id ="1"; ##会error的
```

另外还有行锁，表锁
行锁： SELECT * from city where id = "1"  lock in share mode; 
AUTO_INCREMENT有时候不会从1开始

mysql查看连接数
生产环境Mysql吃内存特别厉害的解决途径
[todo 建表，实查](http://www.runoob.com/sql/sql-groupby.html)