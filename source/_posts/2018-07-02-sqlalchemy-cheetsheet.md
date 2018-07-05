---
title: sqlalchemy速查手册
date: 2018-07-02 21:12:31
tags: [python]
---

> pip install SQLAlchemy
<!--more-->

```python
from sqlalchemy import create_engine
engine = create_engine('sqlite:///foo.db', echo=True) ## 会在当前目录下生成一个foo.db文件，这个True表示程序运行的时候会打印出生成的sql语句。

engine = create_engine('mysql+mysqlconnector://%s:%s@localhost:3306/%s?charset=utf8' % (config.DB_USER_NAME,config.DB_PASS_WORD,config.DB_NAME)) ## mysql也是支持的

engine = create_engine("postgresql://scott:tiger@localhost/test") ## postgresql也是可以的
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





## 参考
[tutorials](http://docs.sqlalchemy.org/en/latest/orm/tutorial.html)
