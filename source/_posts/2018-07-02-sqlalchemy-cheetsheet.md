---
title: sqlalchemy速查手册
date: 2018-07-02 21:12:31
tags: [python,sql]
---

> pip install SQLAlchemy

![](https://www.haldir66.ga/static/imgs/side_walk_tree.jpg)

<!--more-->


```python
from sqlalchemy import create_engine
## 想用sqlite?
engine = create_engine('sqlite:///foo.db', echo=True) ## 会在当前目录下生成一个foo.db文件，这个True表示程序运行的时候会打印出生成的sql语句。

## 想用mysql?
engine = create_engine('mysql+mysqlconnector://%s:%s@localhost:3306/%s?charset=utf8' % (config.DB_USER_NAME,config.DB_PASS_WORD,config.DB_NAME)) ## mysql也是支持的
这里有一个坑：
## mysql://username:password@server/db  python3下面不能这么写，虽然flask-sqlalchemy教程上是这么教人的
## mysql+pymysql://username:password@server/db  应该这么写，还有pip install PyMySQL



## postgresql也是可以的
engine = create_engine("postgresql://scott:tiger@localhost/test") 
```
创建db的时候注意,sqlite因为是直接写文件，所以要把db的路径写清楚了。如果贸然写一个'sqlite:///db.sqlite3'，可能会出现no such table
config.py文件里面
```python
import os

project_dir = os.path.dirname(os.path.abspath(__file__))
SQLALCHEMY_DATABASE_URI = "sqlite:///{}".format(os.path.join(project_dir, "backend.db"))
```


数据库创建了，开始<del>建表</del>设计表
其实一般没必要这么搞，直接db.create_all()得了
```python

## create table if not exists
engine = create_engine("sqlite:///myexample.db")  # Access the DB Engine
if not engine.dialect.has_table(engine, Variable_tableName):  # If table don't exist, Create.
    metadata = MetaData(engine)
    # Create a table with the appropriate Columns
    ##主键，auto_increment是这么设置的
    Table(Variable_tableName, metadata,
          Column('Id', Integer, primary_key=True, nullable=False,autoincrement = True),
          Column('Date', Date), Column('Country', String),
          Column('Brand', String), Column('Price', Float),
    # Implement the creation
    metadata.create_all()
```


Flask比较好的地方是可以和SQLAlechemy紧密结合
Flask一起用[代码出处](https://www.thatyou.cn/flask%E4%BD%BF%E7%94%A8flask-sqlalchemy%E6%93%8D%E4%BD%9Cmysql%E6%95%B0%E6%8D%AE%E5%BA%93%EF%BC%88%E4%BA%8C%EF%BC%89-%E5%8D%95%E8%A1%A8%E6%9F%A5%E8%AF%A2/)
```python
from flask_sqlalchemy import SQLAlchemy
from flask import Flask, jsonify, request
import configparser

app = Flask(__name__)

my_config = configparser.ConfigParser()
my_config.read('db.conf')

app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql://' + my_config.get('DB', 'DB_USER') + ':' + my_config.get('DB', 'DB_PASSWORD') + '@' + my_config.get('DB', 'DB_HOST') + '/' + my_config.get('DB', 'DB_DB')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = True

mydb = SQLAlchemy()
mydb.init_app(app)

# 用户模型
class User(mydb.Model):
    user_id = mydb.Column(mydb.Integer, primary_key=True)
    user_name = mydb.Column(mydb.String(60), nullable=False)
    user_password = mydb.Column(mydb.String(30), nullable=False)
    user_nickname = mydb.Column(mydb.String(50))
    user_email = mydb.Column(mydb.String(30), nullable=False)
    def __repr__(self):
        return '<User %r>' % self.user_name

# 获取用户列表
@app.route('/users', methods=['GET'])
def getUsers():
    data = User.query.all()
    datas = []
    for user in data:
        datas.append({'user_id': user.user_id, 'user_name': user.user_name, 'user_nickname': user.user_nickname, 'user_email': user.user_email})
    return jsonify(data=datas)

# 添加用户数据
@app.route('/user', methods=['POST'])
def addUser():
    user_name = request.form.get('user_name')
    user_password = request.form.get('user_password')
    user_nickname = request.form.get('user_nickname')
    user_email = request.form.get('user_email')
    user = User(user_name=user_name, user_password=user_password, user_nickname=user_nickname, user_email=user_email)
    try:
        mydb.session.add(user)
        mydb.session.commit()
    except:
        mydb.session.rollback()
        mydb.session.flush()
    userId = user.user_id
    if (user.user_id is None):
        result = {'msg': '添加失败'}
        return jsonify(data=result)

    data = User.query.filter_by(user_id=userId).first()
    result = {'user_id': user.user_id, 'user_name': user.user_name, 'user_nickname': user.user_nickname, 'user_email': user.user_email}
    return jsonify(data=result)

# 获取单条数据
@app.route('/user/<int:userId>', methods=['GET'])
def getUser(userId):
    user = User.query.filter_by(user_id=userId).first()
    if (user is None):
        result = {'msg': '找不到数据'}
    else:
        result = {'user_id': user.user_id, 'user_name': user.user_name, 'user_nickname': user.user_nickname, 'user_email': user.user_email}
    return jsonify(data=result)

# 修改用户数据
@app.route('/user/<int:userId>', methods=['PATCH'])
def updateUser(userId):
    user_name = request.form.get('user_name')
    user_password = request.form.get('user_password')
    user_nickname = request.form.get('user_nickname')
    user_email = request.form.get('user_email')
    try:
        user = User.query.filter_by(user_id=userId).first()
        if (user is None):
            result = {'msg': '找不到要修改的记录'}
            return jsonify(data=result)
        else:
            user.user_name = user_name
            user.user_password = user_password
            user.user_nickname = user_nickname
            user.user_email = user_email
            mydb.session.commit()
    except:
        mydb.session.rollback()
        mydb.session.flush()
    userId = user.user_id
    data = User.query.filter_by(user_id=userId).first()
    result = {'user_id': user.user_id, 'user_name': user.user_name, 'user_password': user.user_password, 'user_nickname': user.user_nickname, 'user_email': user.user_email}
    return jsonify(data=result)

# 删除用户数据
@app.route('/user/<int:userId>', methods=['DELETE'])
def deleteUser(userId):
    User.query.filter_by(user_id=userId).delete()
    mydb.session.commit()
    return getUsers()


if __name__ == '__main__':
    app.run(debug=True)
```


sclalchemy的model的tablename默认是会根据model的name生成小写的tablename:
> For instance the table name is automatically set for you unless overridden. It’s derived from the class name converted to lowercase and with “CamelCase” converted to “camel_case”. To override the table name, set the __tablename__ class attribute.


来看看curd的一些常用的地方,[query Api](http://docs.sqlalchemy.org/en/latest/orm/query.html#the-query-object)
[Flask SQLAlchemy query api](http://flask-sqlalchemy.pocoo.org/2.3/queries/)

```
>>> peter = User.query.filter_by(username='peter').first()
>>> peter.id
2
>>> peter.email
u'peter@example.org'
```


sqlalchemy这种orm也是需要加锁的


```
sqlalchemy.exc.InvalidRequestError: When initializing mapper Mapper|Newscate|newscate, expression 'News' failed to locate a name ("name 'News' is not defined"). If this is a class name, consider adding this relationship() to the <class 'category.models.Newscate'> class after both dependent classes have been defined.
```

[flask-sqlalchemy关于一对多，多对多关系的解释](http://flask-sqlalchemy.pocoo.org/2.3/models/)
抄来的model,一对多关系，一个User可以有多个News，一个Newscategory可以有多个News
```python
from sqlalchemy import Table, MetaData, Column, Integer, String, ForeignKey
from database import db as mydb

class User(mydb.Model):
    __tablename__="t_user"
    user_id = mydb.Column(mydb.Integer, primary_key=True)
    user_name = mydb.Column(mydb.String(60), nullable=False)
    user_password = mydb.Column(mydb.String(30), nullable=False)
    user_nickname = mydb.Column(mydb.String(50), nullable=False)
    user_email = mydb.Column(mydb.String(100), nullable=False)
    newses = mydb.relationship('News', backref='user', lazy=True)
    def __repr__(self):
        return '<User %r>' % self.user_nickname

class Newscate(mydb.Model):
    __tablename__="t_newscat"
    cate_id = mydb.Column(mydb.Integer, primary_key=True)
    cate_name = mydb.Column(mydb.String(50), nullable=False)
    cate_title = mydb.Column(mydb.String(50), nullable=False)
    newses = mydb.relationship('News', backref='newscate', lazy=True)
    def __repr__(self):
        return '<Newscate %r>' % self.cate_name

class News(mydb.Model):
    __tablename__="t_news"
    news_id = mydb.Column(mydb.Integer, primary_key=True)
    news_date = mydb.Column(mydb.DateTime, nullable=False)
    news_content = mydb.Column(mydb.Text, nullable=False)
    news_title = mydb.Column(mydb.String(100), nullable=False)
    news_excerpt = mydb.Column(mydb.Text, nullable=False)
    news_status = mydb.Column(mydb.String(20), nullable=False)
    news_modified = mydb.Column(mydb.DateTime, nullable=False)
    news_category = mydb.Column(mydb.Integer, mydb.ForeignKey('t_newscat.cate_id'), nullable=False)
    news_author = mydb.Column(mydb.Integer, mydb.ForeignKey('t_user.user_id'), nullable=False)
    def __repr__(self):
        return '<News %r>' % self.news_title            
```

开始建表吧，直接在shell里面搞要快很多
```
>>> python 
from app import app ## 这个app是一个Flask实例
from database import db
from models import News,User,Newscate
app.app_context().push() ## 这句话是必须的[context](http://flask-sqlalchemy.pocoo.org/2.3/contexts/)
db.create_all() 
```
如果只要创建一张表的话可以这么干
Model.__table__.create(session.bind)

来看看生成的sql语句
```sql
CREATE TABLE t_user (
        user_id INTEGER NOT NULL AUTO_INCREMENT,
        user_name VARCHAR(60) NOT NULL,
        user_password VARCHAR(30) NOT NULL,
        user_nickname VARCHAR(50) NOT NULL,
        user_email VARCHAR(100) NOT NULL,
        PRIMARY KEY (user_id)
)
CREATE TABLE t_newscat (
        cate_id INTEGER NOT NULL AUTO_INCREMENT,
        cate_name VARCHAR(50) NOT NULL,
        cate_title VARCHAR(50) NOT NULL,
        PRIMARY KEY (cate_id)
)

CREATE TABLE t_news (
        news_id INTEGER NOT NULL AUTO_INCREMENT,
        news_date DATETIME NOT NULL,
        news_content TEXT NOT NULL,
        news_title VARCHAR(100) NOT NULL,
        news_excerpt TEXT NOT NULL,
        news_status VARCHAR(20) NOT NULL,
        news_modified DATETIME NOT NULL,
        news_category INTEGER NOT NULL,
        news_author INTEGER NOT NULL,
        PRIMARY KEY (news_id),
        FOREIGN KEY(news_category) REFERENCES t_newscat (cate_id),
        FOREIGN KEY(news_author) REFERENCES t_user (user_id)
)
```
生成表之后，开始插入数据，还是在shell里面，快一点

```
>>  User.query.all() 
[] ##数据为空
>>> robin = User(user_name="Tim",user_password="secret",user_nickname="tim_nick",user_email="lenon@gmail.com")
>>> robin.user_email
'lenon@gmail.com'
>>> robin.newses ## 注意，db中user并没有newses这个column
[]
>>> robin.user_id
>>>   ##什么都没有，因为还没有commit到数据库，那么commit一下
>>> robin.user_id
>>> db.session.add(robin)
>>> db.session.commit()
再查找一下
>>> robin.user_id
2018-07-15 10:26:58,358 INFO sqlalchemy.engine.base.Engine BEGIN (implicit)
2018-07-15 10:26:58,358 INFO sqlalchemy.engine.base.Engine SELECT t_user.user_id AS t_user_user_id, t_user.user_name AS t_user_user_name, t_user.user_password AS t_user_user_password, t_user.user_nickname AS t_user_user_nickname, t_user.user_email AS t_user_user_email
FROM t_user
WHERE t_user.user_id = %(param_1)s
2018-07-15 10:26:58,359 INFO sqlalchemy.engine.base.Engine {'param_1': 1}
>>> 1 ##这回就有了
```


因为news依赖两个Foreign key，user和newcate，且都不为空，所以在创建News之前得先创建Newscate
````
>>> breaking_news = Newscate(cate_name="beaking_news",cate_title="breaking News")
>>> breaking_news
<Newscate 'beaking_news'>
>>> breaking_news.cate_title
'breaking News'
>>>db.session.add(breaking_news)
>>>db.session.commit()
>>>breaking_news.cate_id
1 ## 查下数据库，User和Newscate里面都有数据了

 newsitem = News(news_date=datetime.utcnow(),news_content="content of news item one",news_title="title of news item one",news_excerpt="excerpt of news item one",news_status="normal",news_modified=datetime.now(),news_category=2,news_author=1)
>>> newsitem
<News 'title of news item one'>
>>> db.session.add(newsitem)
>>> db.session.commit()
2018-07-15 10:42:11,134 INFO sqlalchemy.engine.base.Engine BEGIN (implicit)
2018-07-15 10:42:11,135 INFO sqlalchemy.engine.base.Engine INSERT INTO t_news (news_date, news_content, news_title, news_excerpt, news_status, news_modified, news_category, news_author) VALUES (%(news_date)s, %(news_content)s, %(news_title)s, %(news_excerpt)s, %(news_status)s, %(news_modified)s, %(news_category)s, %(news_author)s)
2018-07-15 10:42:11,136 INFO sqlalchemy.engine.base.Engine {'news_date': datetime.datetime(2018, 7, 15, 2, 41, 50, 454505), 'news_content': 'content of news item one', 'news_title': 'title of news item one', 'news_excerpt': 'excerpt of news item one', 'news_status': 'normal', 'news_modified': datetime.datetime(2018, 7, 15, 10, 41, 50, 454505), 'news_category': 2, 'news_author': 1}
2018-07-15 10:42:11,141 INFO sqlalchemy.engine.base.Engine COMMIT
```
查下数据库，News也插入成功

后面开始在gui界面中往数据库里面插入一些数据，准备好假数据之后要db.session.commit()一下才会在sqlalchemy这边同步一下。(session好像也没有什么类似于sync的api)

开始查询：
### 根据一个Newsid去查找这篇news的user

```
>>> News.query.all()[0].news_author 
1 ##正常啊，这里存储的就是user的id,但是我们想要User，还记得上面建表的时候那个"backref"嘛，写的是backref='user'
>>> News.query.all()[0].user
<User 'tim_nick'>
```

## 查询所有发表过News的User（就是user.newses不为空List）
```
>>> User.query.filter(func.length(User.newses) > 0).all()
[<User 'tim_nick'>, <User 'bounty hounter'>, <User 'sally williams'>, <User 'john doe'>]显然不正确

这种情况的一般sql语句应该是这么写的
>>>SELECT t_user.user_id AS t_user_user_id, t_user.user_name AS t_user_user_name, t_user.user_password AS t_user_user_password, t_user.user_nickname AS t_user_user_nickname, t_user.user_email AS t_user_user_email FROM t_user, t_news WHERE t_user.user_id = t_news.news_author GROUP BY t_user_user_name;

所以最终凑合得到这样的查询
>>> User.query.filter(User.newses).all()
2018-07-15 11:09:17,584 INFO sqlalchemy.engine.base.Engine SELECT t_user.user_id AS t_user_user_id, t_user.user_name AS t_user_user_name, t_user.user_password AS t_user_user_password, t_user.user_nickname AS t_user_user_nickname, t_user.user_email AS t_user_user_email
FROM t_user, t_news
WHERE t_user.user_id = t_news.news_author
2018-07-15 11:09:17,585 INFO sqlalchemy.engine.base.Engine {}
[<User 'tim_nick'>]
```

## 查询一个user发布过的所有news
```
>>> News.query.filter(News.news_author==1).all()
2018-07-15 11:29:42,306 INFO sqlalchemy.engine.base.Engine SELECT t_news.news_id AS t_news_news_id, t_news.news_date AS t_news_news_date, t_news.news_content AS t_news_news_content, t_news.news_title AS t_news_news_title, t_news.news_excerpt AS t_news_news_excerpt, t_news.news_status AS t_news_news_status, t_news.news_modified AS t_news_news_modified, t_news.news_category AS t_news_news_category, t_news.news_author AS t_news_news_author
FROM t_news
WHERE t_news.news_author = %(news_author_1)s
2018-07-15 11:29:42,306 INFO sqlalchemy.engine.base.Engine {'news_author_1': 1}
[<News 'title of news item one'>, <News 'title of news item two'>]
```



### 到这里一共有三张表，那么join这种联表查询也是ok的
```
>>> result = db.session.query(News.news_id, News.news_author, News.news_date, News.news_title, News.news_content, News.news_excerpt, News.news_status, News.news_modified, Newscate.cate_name, Newscate.cate_title, User.user_name, User.user_nickname).filter_by(news_id=1).join(Newscate, News.news_category == Newscate.cate_id).join(User, News.news_author == User.user_id).first()
2018-07-15 14:08:27,487 INFO sqlalchemy.engine.base.Engine SELECT t_news.news_id AS t_news_news_id, t_news.news_author AS t_news_news_author, t_news.news_date AS t_news_news_date, t_news.news_title AS t_news_news_title, t_news.news_content AS t_news_news_content, t_news.news_excerpt AS t_news_news_excerpt, t_news.news_status AS t_news_news_status, t_news.news_modified AS t_news_news_modified, t_newscat.cate_name AS t_newscat_cate_name, t_newscat.cate_title AS t_newscat_cate_title, t_user.user_name AS t_user_user_name, t_user.user_nickname AS t_user_user_nickname
FROM t_news INNER JOIN t_newscat ON t_news.news_category = t_newscat.cate_id INNER JOIN t_user ON t_news.news_author = t_user.user_id
WHERE t_news.news_id = %(news_id_1)s
 LIMIT %(param_1)s
2018-07-15 14:08:27,487 INFO sqlalchemy.engine.base.Engine {'news_id_1': 1, 'param_1': 1}
(1, 1, datetime.datetime(2018, 7, 15, 2, 41, 50), 'title of news item one', 'content of news item one', 'excerpt of news item one', 'normal', datetime.datetime(2018, 7, 15, 10, 41, 50), 'economy', 'economy title', 'Tim', 'tim_nick')
这里得到的是一个<class 'sqlalchemy.util._collections.result'>对象
>>> result.cate_name ## 可以这么访问数据
'economy'
```

###查找所有用gmail注册的用户
```
>>>>>> db.session.query(User.user_name).filter(User.user_email.like("gmail")).all()
2018-07-15 13:50:56,237 INFO sqlalchemy.engine.base.Engine SELECT t_user.user_name AS t_user_user_name
FROM t_user
WHERE t_user.user_email LIKE %(user_email_1)s
2018-07-15 13:50:56,239 INFO sqlalchemy.engine.base.Engine {'user_email_1': 'gmail'}
[] ##显然有问题

数据库里执行这句sql就能正确的找出gmail邮箱的user
>>> SELECT t_user.user_name AS t_user_user_name FROM t_user WHERE t_user.user_email LIKE '%gmail%'
于是改成
>>> db.session.query(User.user_name).filter(User.user_email.like("%gmail%")).all()
2018-07-15 13:54:08,541 INFO sqlalchemy.engine.base.Engine SELECT t_user.user_name AS t_user_user_name
FROM t_user
WHERE t_user.user_email LIKE %(user_email_1)s
2018-07-15 13:54:08,542 INFO sqlalchemy.engine.base.Engine {'user_email_1': '%gmail%'}
[('Tim',), ('Django',), ('Sally',), ('john',)]

### 分页接口，limit,count这种怎么写？
用标准的limit,count似乎并不困难
>>> db.session.query(User.user_name).filter(User.user_email.like("%gmail%")).limit(1).all()
[('Tim',)]
>>> db.session.query(User.user_name).filter(User.user_email.like("%gmail%")).limit(1).offset(2).all()
[('Sally',)]
offset超出了实际数据的总量如何？
>>> db.session.query(User.user_name).filter(User.user_email.like("%gmail%")).limit(1).offset(10).all()
[]

除了标准的limit方法以外，下面这个paginate方法返回了一个pagination object
>>> db.session.query(User.user_name).filter(User.user_email.like("%gmail%")).paginate(2,1,False).items
```

[MYSQL分页limit速度太慢优化方法](https://www.jianshu.com/p/7d1b6db64a8f)


## Many to many relationship
添加新的model的时候，旧的model import会报错
```python
class Node(Base):
    __tablename__ = "nodes"
    __table_args__ = {"useexisting": True} ## 关键是这个
```

这样db.create_all()的时候也不会去动现有的表里面的数据

[many-to-many-relationship依赖于第三张表](https://stackoverflow.com/questions/25668092/flask-sqlalchemy-many-to-many-insert-data)
```python
association_table = db.Table('association', db.Model.metadata,
    db.Column('left_id', db.Integer, db.ForeignKey('left.id')),
    db.Column('right_id', db.Integer, db.ForeignKey('right.id'))
)

class Parent(db.Model):
    __tablename__ = 'left'
    id = db.Column(db.Integer, primary_key=True)
    children = db.relationship("Child",
                    secondary=association_table)

class Child(db.Model):
    __tablename__ = 'right'
    id = db.Column(db.Integer, primary_key=True)

## 添加数据
p = Parent()
c = Child()
p.children.append(c)
db.session.add(p)
db.session.commit()


student_identifier = db.Table('student_identifier',
    db.Column('class_id', db.Integer, db.ForeignKey('classes.class_id')),
    db.Column('user_id', db.Integer, db.ForeignKey('students.user_id'))
)

class Student(db.Model):
    __tablename__ = 'students'
    user_id = db.Column(db.Integer, primary_key=True)
    user_fistName = db.Column(db.String(64))
    user_lastName = db.Column(db.String(64))
    user_email = db.Column(db.String(128), unique=True)


class Class(db.Model):
    __tablename__ = 'classes'
    class_id = db.Column(db.Integer, primary_key=True)
    class_name = db.Column(db.String(128), unique=True)
    children = db.relationship("Student",
                    secondary=student_identifier)

s = Student()
c = Class()
c.children.append(s)
db.session.add(c)
db.session.commit()

## 查询数据
db.session.query(Class).all()[0].children ##得到一个Student的list
Class.query.with_parent(user_id) ## 获得一个student上的所有课程
```



有时候用db.session.query去查，有时候用Model.query去查




## 参考
[tutorials](http://docs.sqlalchemy.org/en/latest/orm/tutorial.html)
[queryapi](http://docs.sqlalchemy.org/en/latest/orm/query.html)
