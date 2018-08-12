---
title: 在ubuntu服务器上部署wsgi application
date: 2017-06-25 22:46:23
categories: blog
tags: [python]
---

![](http://www.haldir66.ga/static/imgs/ChMkJ1fAMmKIIFpWAA_5Us41gQkAAUv1QE2Pp8AD_lq599.jpg)
<!--more-->

## 1. virtualenv 好习惯

```shell
sudo pip install virtualenv
sudo virtualenv venv
source venv/bin/activate
sudo pip install Flask

## virtualenv指定python版本
virtualenv env --python=python2.7
virtualenv -p"$(which python3.6)" TEST ##linux这个也行
mkvirtualenv --python=`which python3` <env_name> ## 这个居然也行

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

mac和linux平台下
source ./env/bin/activate
```


## 2. flask+nginx+wsgi
[Digital Ocean总有很多实用的教程](https://www.digitalocean.com/community/tutorials/how-to-serve-flask-applications-with-uwsgi-and-nginx-on-ubuntu-16-04),跟这个这里面的教程去部署flask app多半会碰到nginx 502。原因是生成的.sock文件的权限不对，所以在ini文件里面加上

> chmod-socket = 666

在venv里面不要用pip3，用pip

wsgi协议的app跑起来之后是没有办法直接通过http去请求的，要让nginx转发一下。生成的.sock文件就是用来和nginx通信的。
这时候的在浏览器里面访问的port就是nginx决定的了。
[wsgi的文档应该在pep-333里面](https://www.python.org/dev/peps/pep-3333/)

另外，通过uwsgi跑起来的托管在Ngixn上的app如果server端报错的话，可以sudo systemctl status yourservicefilename 去查看具体的报错原因，比起本地开发还是麻烦了一点点


## 3. flask的一大堆extensions
官方列举出的[Extensions](http://flask.pocoo.org/extensions/)有很多

### flask-jwt(似乎已经很久没人维护了))
```python
from flask import Flask
from flask_jwt import JWT, jwt_required, current_identity
from werkzeug.security import safe_str_cmp

class User(object):
    def __init__(self, id, username, password):
        self.id = id
        self.username = username
        self.password = password

    def __str__(self):
        return "User(id='%s')" % self.id

users = [
    User(1, 'user1', 'abcxyz'),
    User(2, 'user2', 'abcxyz'),
]

username_table = {u.username: u for u in users}
userid_table = {u.id: u for u in users}

def authenticate(username, password):
    user = username_table.get(username, None)
    if user and safe_str_cmp(user.password.encode('utf-8'), password.encode('utf-8')):
        return user

def identity(payload):
    user_id = payload['identity']
    return userid_table.get(user_id, None)

app = Flask(__name__)
app.debug = True
app.config['SECRET_KEY'] = 'super-secret'
app.config['JWT_AUTH_HEADER_PREFIX'] = 'awesome' ##设置header中的Authorization: JWT xxxxx中的JWT三个字
jwt = JWT(app, authenticate, identity)


@app.route('/protected')
@jwt_required()
def protected():
    return '%s' % current_identity

if __name__ == '__main__':
    app.run()

## 认证接口 curl -X POST http://127.0.0.1:5000/auth --header "Content-Type:application/json" --data '{"username":"user1","password":"abcxyz"}'    
## {
 ## "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE1MzEyMTg0NTUsImlhdCI6MTUzMTIxODE1NSwibmJmIjoxNTMxMjE4MTU1LCJpZGVudGl0eSI6MX0.TPfb5Xwthbwnnf5P1LNB0o-CKiSis8VH0Db6JEotc9A"
##}

##访问需要认证的接口
## curl -X GET http://127.0.0.1:5000/protected --header "Content-Type:application/json" --header "Authorization: JWT eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE1MzEyMTg0NTUsImlhdCI6MTUzMTIxODE1NSwibmJmIjoxNTMxMjE4MTU1LCJpZGVudGl0eSI6MX0.TPfb5Xwthbwnnf5P1LNB0o-CKiSis8VH0Db6JEotc9A"
## User(id='1')

```

Flask设置cookie:
```python
from flask import Flask,make_response,request
app = Flask(__name__)

@app.router('/setcookie')
def setcookie():
    resp = make_response('Setting cookies')
    resp.set_cookie('framework','flask')
    return resp

@app.route('/getcookie')
def getcookie():
    framework = request.cookies.get('framework')
    return 'The frame work stored in cookie is '+framework

if __name__ == "__main__":
    app.run(debug=True)
```

设置header比如cors这种也可以
```python 
@app.route("/")
def home():
    resp = flask.Response("Foo bar baz")
    resp.headers['Access-Control-Allow-Origin'] = '*'
    return resp
```
> curl -i http://127.0.0.1:5000/your/endpoint 即可(i表示include)

## flask操作数据库
[mysql](https://www.thatyou.cn/flask%E4%BD%BF%E7%94%A8flask-sqlalchemy%E6%93%8D%E4%BD%9Cmysql%E6%95%B0%E6%8D%AE%E5%BA%93%EF%BC%88%E5%9B%9B%EF%BC%89-%E8%81%94%E8%A1%A8%E5%A4%9A%E5%AF%B9%E5%A4%9A%E6%9F%A5%E8%AF%A2/)



在windows下设置环境变量要用set:
> (env) λ set FLASK_APP=C:\code\realworld\flask-realworld-example-app\autoapp.py




### Reference
1. [how-to-deploy-a-flask-application-on-an-ubuntu-vps](https://www.digitalocean.com/community/tutorials/how-to-deploy-a-flask-application-on-an-ubuntu-vps)
