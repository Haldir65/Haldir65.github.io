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



## 参考
[tutorials](http://docs.sqlalchemy.org/en/latest/orm/tutorial.html)
