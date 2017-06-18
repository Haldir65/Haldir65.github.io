---
title: 使用Python搭建本地服务器
date: 2017-06-15 23:56:26
categories: blog
tags: [python]
---

![Kitty](http://odzl05jxx.bkt.clouddn.com/c6dd030bf8cc75628fce3aec8216ba52.jpg?imageView2/2/w/600)
关于如何使用Python搭建后台的方法很多，这里列举出一些实例。<!--more-->

### 1. The Flask Way
Flask官方的快速入门很详细，做一个接口也很简单。Flask的方式是使用Decorator对请求进行处理
```python
#!/usr/bin/python3
# -*- coding:utf8 -*-

from flask import Flask
from flask import request
from flask import jsonify
from flask import send_file

# create the flask object
app = Flask(__name__)

# 处理GET请求像这样就可以了

@app.route('/', methods=['GET'])
def handle_get():
    return 'haha ,this is http status code 200'

#处理POST请求，从request中拿东西，返回response
@app.route('/', methods=['POST'])
def handle_post():
    uid = request.form['uid']
    name = request.form['name']
    print('uid is %s ,name is %s ' % (uid, name))
    return '200 Ok, or whatever you like'  


 #返回json，作为API
@app.route('/_get_current_user', methods=['GET'])
def get_current_user():
    return jsonify(
        username='Admin',
        email='Bob@gmail.com',
        age=18
    )    

{
    username: 'Admin';
    email: 'Bob@gamil.com';
    age: 18
}

#返回复杂一点的json，或者json数组 
@app.route('/_get_user_list', methods=['GET'])
def get_user_list():
    user_list = create_user_list()
    return Response(json.dumps(user_list), mimetype='application/json')


#生成数据
def create_user_list():
    alice = {'name': 'alice', 'age': 16, 'sex': 'female'}
    tom = {'name': 'tom', 'age': 23, 'sex': 'male'}
    josh = {'name': 'josh', 'age': 20, 'sex': 'male'}
    bill = {'name': 'bill', 'age': 19, 'sex': 'male'}
    li = [alice, tom, josh, bill]
    return li


# 在Postman中就能获得这样的result
[
    {
        "name": "alice",
        "age": 16,
        "sex": "female"
    },
    {
        "name": "tom",
        "age": 23,
        "sex": "male"
    },
    {
        "name": "josh",
        "age": 20,
        "sex": "male"
    },
    {
        "name": "bill",
        "age": 19,
        "sex": "male"
    }
]

# hosting static file，image,css,etc
# 提供图片什么的

@app.route('/_get_image', methods=['GET'])
def get_image():
    filename = 'static/image/b1.jpg'
    fullpath = os.path.join(os.path.curdir, filename)
    print(filename, fullpath)
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
text/html、text/css、application/json什么的，[详细的http-content-type表格](http://www.runoob.com/http/http-content-type.html)
关于content-type,找到一篇[介绍](http://homeway.me/2015/07/19/understand-http-about-content-type/)


>下面是几个常见的Content-Type:
1.text/html
2.text/plain
3.text/css
4.text/javascript
5.application/x-www-form-urlencoded
6.multipart/form-data
7.application/json
8.application/xml
…
前面几个都很好理解，都是html，css，javascript的文件类型，后面四个是POST的发包方式。



### 2. The Django Way 


### 3. Using Tornado

### 4. 其他的点
UrlLib，Socket




### Reference
1. xxxx
2. xxxx