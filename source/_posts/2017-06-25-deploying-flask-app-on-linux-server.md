---
title: 在ubuntu服务器上部署web app
date: 2017-06-25 22:46:23
categories: blog
tags: [python]
---

![](http://odzl05jxx.bkt.clouddn.com/ChMkJ1fAMmKIIFpWAA_5Us41gQkAAUv1QE2Pp8AD_lq599.jpg?imageView2/2/w/600)
<!--more-->

## 1. virtualenv install

```bash
sudo pip install virtualenv
sudo virtualenv venv
source venv/bin/activate
sudo pip install Flask


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

```


## 2. install apache2 , mysql-server... on ubuntu
    重启apache2服务 service apache2 restart



## 3. Deploying node app on ubuntu(backgroud)
三种方法

> 1.  nohup node /home/zhoujie/ops/app.js & ## nohup就是不挂起的意思( no hang up)。 ignoring input and appending output to nohup.out // 输出被写入当前目录下的nohup.out文件中
> 2. screen ## 新开一个screen
> 3. pm2
npm install -g pm2
pm2 start app.js

[Configure Nginx as a web server and reverse proxy for Nodejs application on AWS Ubuntu 16.04 server](https://medium.com/@utkarsh_verma/configure-nginx-as-a-web-server-and-reverse-proxy-for-nodejs-application-on-aws-ubuntu-16-04-server-872922e21d38)

首先是json.dumps()这个函数，对于自定义的class类型，需要提供一个default参数
```python
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True,autoincrement = True)
    username = db.Column(db.String(80), unique=False, nullable=False)
    email = db.Column(db.String(120), unique=False, nullable=False)

    def __repr__(self):
        return '<User %r>' % self.username

## 这个方法是给json.dumps使用的，classmethod在被调用的时候默认会在前面添加一个class对象(不是class实例)
   @classmethod
    def serialize(cls,_usr):
        return {
            "id": _usr.id,
            "username": _usr.username,
            "email": _usr.email
        }  


@app.route('/users/all')
def all_users():
    # user = User.query.filter_by(username=username).first_or_404()
    # return render_template('show_user.html', user=user)
    user_ = {'name':user.username,'email':user.email}
    ## peter = User.query.filter_by(username='peter').first()
    ##missing = User.query.filter_by(username='missing').first()
    all_users = User.query.filter(User.email.endswith('@example.com')).all()
    ## all_user的类型是list
    # User.query.order_by(User.username).all()
    # User.query.limit(1).all()
    # User.query.get(1)
    result = None
    try:
        ## 对于自定义的class类型，需要告诉json如何去序列化
        result = json.dumps(all_users,default=User.serialize)
    except (AttributeError,TypeError) as e:
        logging.error("formating json obj error! \n   root cause %s" % e)
        result = json.dumps({"status_code":403,"error_msg":"json serialize error!"})
    return result    
```

这个对于多数class有效
> print(json.dumps(s, default=lambda obj: obj.__dict__))


### Reference
1. [how-to-deploy-a-flask-application-on-an-ubuntu-vps](https://www.digitalocean.com/community/tutorials/how-to-deploy-a-flask-application-on-an-ubuntu-vps)
