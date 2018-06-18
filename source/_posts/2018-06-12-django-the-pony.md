---
title: django学习记录
date: 2018-06-12 22:40:01
tags: [python,django]
---


![](http://odzl05jxx.bkt.clouddn.com/image/jpg/djangopony-slide.png?imageView2/2/w/600)



<!--more-->
首先是几个常用命令
```python
virtualenv --no-site-packages venv ## virtualenv好习惯
source venv/bin/activate ## windows下应该是Scripts/activate.bat这个文件
deactivate ## 退出

python manage.py mkemigrations app1 app2
python manage.py migrate
python manage.py runserver

django-admin startproject  mysite ## 创建项目
django-admin startapp  app1 ## 创建app

python manage.py runserver ## 本地运行，默认8000端口
python manage.py runserver 8080  ## 端口也可以自己决定

python manage.py migrate ##创建了新的model，数据库需要建表
python manage.py createsuperuser ## 创建admin
```

需要注意的是，runserver命令多数情况下能够实现自动reload，比如修改了一个py文件。但如果是创建了一个新的文件，还是需要重新跑一遍的
> settings.py中的SECRET_KEY不应该对外公布


models简化了建表操作，添加的__str__方法类似于将Object类型的数据展示为String的方法
```python
from django.db import models

class Question(models.Model):
    # ...
    def __str__(self):
        return self.question_text

class Choice(models.Model):
    # ...
    def __str__(self):
        return self.choice_text
```

官方tutorial中的url和view的匹配也很简单
```python
def detail(request, question_id):
    return HttpResponse("You're looking at question %s." % question_id)

def results(request, question_id):
    response = "You're looking at the results of question %s."
    return HttpResponse(response % question_id)

def vote(request, question_id):
    return HttpResponse("You're voting on question %s." % question_id)


from django.urls import path

from . import views

urlpatterns = [
    # ex: /polls/
    path('', views.index, name='index'),
    # ex: /polls/5/
    path('<int:question_id>/', views.detail, name='detail'),
    # ex: /polls/5/results/
    path('<int:question_id>/results/', views.results, name='results'),
    # ex: /polls/5/vote/
    path('<int:question_id>/vote/', views.vote, name='vote'),
]    
```


安装mysql:
首先是virtualenv
pip install mysql-connector-python  mysql-connector-python

在ununtu上使用uwsgi和nginx运行django application

requirements.txt的生成和使用
当然都要在virtualenv中了
> (venv) $ pip freeze >requirements.txt # 创建
> (venv) $ pip install -r requirements.txt ##使用


### 127.0.0.1和0.0.0.0的区别
我尝试在vps(216.216.216.216)上运行django应用
> python manage.py 17289 ##随便挑一个端口
> curl localhost:17289 ## 网页的html response展示出来

于是尝试在本地windows上浏览器中输入
> 216.216.216.216:17289 

没反应，使用postman，没效果。本地curl，curl --trace 依旧没效果。看下防火墙
sudo uwf status  # inactive
最终找到了[running-django-server-on-localhost](https://stackoverflow.com/questions/47675934/running-django-server-on-localhost)

其实只要改用0.0.0.0就可以了
> python manage.py runserver 0.0.0.0:8000
> python manage.py runserver HERE.IS.MY.IP:8000 #或者使用实际的地址

[whats-the-difference-between-ip-address-0-0-0-0-and-127-0-0-1](https://serverfault.com/questions/78048/whats-the-difference-between-ip-address-0-0-0-0-and-127-0-0-1)

>In simple terms: Listening on 0.0.0.0 means listening from anywhere that has network access to this computer, for example, from this very computer, from local network or from the Internet, while listening on 127.0.0.1 means only listen from this very computer


```python
python manage.py shell
python manage.py plus_shell
```

[drf官方文档](http://www.django-rest-framework.org/)

在ubuntu服务器上搭配nginx部署django应用
创建一个myconf.ini文件
> uwsgi --ini myconf.ini


![](http://odzl05jxx.bkt.clouddn.com/image/jpg/food%20salad%20instagram%20hunger%20city%20life.jpg?imageView2/2/w/600)
