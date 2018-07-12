---
title: sqlalchemy速查手册
date: 2018-07-02 21:12:31
tags: [python]
---

> pip install SQLAlchemy

![](http://odzl05jxx.bkt.clouddn.com/image/jpg/side_walk_tree.jpg?imageView2/2/w/600)

<!--more-->


```python
from sqlalchemy import create_engine
## 想用sqlite?
engine = create_engine('sqlite:///foo.db', echo=True) ## 会在当前目录下生成一个foo.db文件，这个True表示程序运行的时候会打印出生成的sql语句。

## 想用mysql?
engine = create_engine('mysql+mysqlconnector://%s:%s@localhost:3306/%s?charset=utf8' % (config.DB_USER_NAME,config.DB_PASS_WORD,config.DB_NAME)) ## mysql也是支持的

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


sqlalchemy这种orm也是需要加锁的



## 参考
[tutorials](http://docs.sqlalchemy.org/en/latest/orm/tutorial.html)
