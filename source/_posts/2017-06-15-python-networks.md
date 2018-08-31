---
title: 使用Python搭建本地服务器
date: 2017-06-15 23:56:26
categories: blog
tags: [python]
---

![Kitty](https://www.haldir66.ga/static/imgs/c6dd030bf8cc75628fce3aec8216ba52.jpg)
关于如何使用Python搭建后台的方法很多，这里列举出一些实例。<!--more-->

## 1. The Flask Way
PyCharm最好装Professional的，方便很多，可以ssh到linux远程服务器,直接[远程开发](http://blog.csdn.net/zhaihaifei/article/details/53691873)，调试。除了连接有点慢，别的都好。windows环境下很多库都跑不起来。
还是用mac或者直接linux desktop

### 1.1 Basics
> Flask is a very simple, but extremely flexible framework Flask使用Decorator对请求进行处理


```Python
#!/usr/bin/python3
# -*- coding:utf8 -*-

from flask import Flask
from flask import request
from flask import jsonify
from flask import send_file

### create the flask object
app = Flask(__name__)


### 对于GET请求，获得query参数的方式
> http://127.0.0.1:12345/_search_user?user=111&date=190

@app.route('/_search_user', methods=['GET'])
def query_user_profile():
    try:
        user = request.args.get('user','')
        date = request.args.get('date','')
        print(user) ## 111
        print(date) ## 190
        return 'every Thing Ok'
    except KeyError as e:
        return "missing required key"

### 处理POST请求，从request中拿东西，返回response
@app.route('/', methods=['POST'])
def handle_post():
    uid = request.form['uid'] # requets.form是一个list，从里面获取想表单的参数
    name = request.form['name']
    print('uid is %s ,name is %s ' % (uid, name))
    return '200 Ok, or whatever you like'

从request中获得json数据
@app.route('/api/add_message/<uuid>', methods=['GET', 'POST'])
def add_message(uuid):
    content = request.get_json(silent=True) 
##前提是客户端发来的request中包含'Content-Type' == 'application/json'的header    
    print content
    return uuid   

if __name__ == '__main__':
    app.run(port=12345, debug=True) #设置为True后，会自动检测到服务端代码更改并reload，出错了也会给client返回实际的错误堆栈， 生产环境不要打开Debug 。


from flask import request
##读取cookie
@app.route('/')
def index():
    username = request.cookies.get('username')
    # use cookies.get(key) instead of cookies[key] to not get a
    # KeyError if the cookie is missing.

from flask import make_response
##设置cookie
@app.route('/')
def index():
    resp = make_response(render_template(...))
    resp.set_cookie('username', 'the username')
    return resp

### 设置header
@app.errorhandler(404)
def not_found(error):
    resp = make_response(render_template('error.html'), 404)
    resp.headers['X-Something'] = 'A value'
    return resp

# hosting static file，image,css,etc
# 提供图片什么的

@app.route('/_get_image', methods=['GET'])
def get_image():
    filename = 'static/image/b1.jpg'
    fullpath = os.path.join(os.path.curdir, filename)
    return send_file(fullpath, mimetype='image/jpeg')
```

我觉得Flask的官方Doc对初学者的友好度几乎是满分
- [accessing-request-data](http://flask.pocoo.org/docs/0.12/quickstart/#accessing-request-data)
- [cookies](http://flask.pocoo.org/docs/0.12/quickstart/#cookies)
- [sessions](http://flask.pocoo.org/docs/0.12/quickstart/#sessions)
- [static files](http://flask.pocoo.org/docs/0.12/quickstart/#static-files)
所有的静态文件必须放在当前目录下的static目录中，里面可以再创建image，css,404.html等文件
另外，如果要调试接口的话，用Postman吧，比Fiddler简单点
返回response的时候一定要指明mime-type，或者content-type
text/html、text/css、application/json什么的，

### 1.2 Flask BluePrints
正常的工程都会希望将业务处理逻辑写在不同的module里面，在flask里面这种思想的实现方式是[BluePrint](http://flask.pocoo.org/docs/1.0/blueprints/#blueprints)。

[how-to-divide-flask-app-into-multiple-py-files](https://stackoverflow.com/questions/11994325/how-to-divide-flask-app-into-multiple-py-files)

### 1.3 Flask + gevent 提高web 框架的性能
[docs](http://flask.pocoo.org/docs/0.12/deploying/wsgi-standalone/)

### 1.4 Flask Session management
这段示例代码展示了如何为请求设置session
```python
from flask import Flask ,session
import os

app = Flask(__name__)
app.secret_key = os.urname(24)

@app.route('/')
def index():
    session('user') = 'Anthony'
    return 'Index'

@app.route('/getsession')
def getsession():
    if 'user' in session:
        return session['user']
    return 'not logged in!'

@app.router('/dropsession')
def dropsession():
    session.pop('user',None)
    return 'Dropped'

if  __name__ == '__main__':
    app.run(debug=True)
```

[Flask和FlaskSqlAlCheMy的curd教程很简单](https://www.codementor.io/garethdwyer/building-a-crud-application-with-flask-and-sqlalchemy-dm3wv7yu2)

以sqlite为例，db.sqlite文件的位置要注意(最好需要指定db文件的路径)
```python
import os
project_dir = os.path.dirname(os.path.abspath(__file__))
database_file = "sqlite:///{}".format(os.path.join(project_dir, "bookdatabase.db"))
```

flask从request post中提取data:
```python
##It is simply as follows
##For URL Query parameter, use request.args
search = request.args.get("search")
page = request.args.get("page")
##For Form input, use request.form
email = request.form.get('email')
password = request.form.get('password')
##For data type application/json, use request.data
# data in string format and you have to parse into dictionary
data = request.data
dataDict = json.loads(data)
```

flask的jsonify会将中文变成unicode返回，解决方式
> app.config['JSON_AS_ASCII'] = False

flask的config对象继承于字典，并且可以像修改字典一样修改它:

### 2. The Django Way
Django是**web framework**，不是**WebServer**


## 3. Using Tornado

## 4. 其他的点
### 4.1 Web架构
网络库上手比较快，很重要的一点是理解其在通讯中的层级，Nigix属于代理转发，Flask处理业务逻辑，Tornado处理Http底层实现，Django负责用于高效网络应用开发
 - [Django和Flask这两个框架在设计上各方面有什么优缺点？
](https://www.zhihu.com/question/41564604)


UrlLib，Socket这些属于Python底层的基础性的network库，属于基础的东西。

### 4.2不服跑个分
引用一篇[测评](http://www.vimer.cn/archives/2926.html)
>可见纯框架自身的性能为:

    bottle > flask > tornado > django

结合实际使用:

    tornado 使用了异步驱动，所以在写业务代码时如果稍有同步耗时性能就会急剧下降；
    bottle需要自己实现的东西太多，加上之后不知道性能会怎样；
    flask性能稍微差点，但周边的支持已经很丰富了；
    django就不说了，性能已经没法看了，唯一的好处就是开发的架子都已经搭好，开发速度快很多
当然这些框架不是纯粹一个功能层面上的东西，可能有所偏差。



## Update
[请教flask ,laravel , rails对初学者那个更友好？](https://segmentfault.com/q/1010000003799544)
这三个分别是python,php,ruby。懂python的话，flask上手很快。没必要学会每一种，就好像会用15种语言写hello world并没有卵用，一个意思。

[flask全局统一定义error返回格式，似乎统一定义response格式也是可以的](http://chuangyiji.com/archives/1271)
[talk from flask author](https://speakerdeck.com/mitsuhiko/advanced-flask-patterns-1)

### Reference
1. xxxx
2. xxxx
