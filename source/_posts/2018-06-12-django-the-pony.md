---
title: django学习记录
date: 2018-06-12 22:40:01
tags: [python]
---

django is a pony
<!--more-->
首先是几个常用命令
```python
virtualenv --no-site-packages venv ## virtualenv好习惯
source venv/bin/activate ## windows下应该不用source
deactivate ## 退出

django-admin startproject  mysite ## 创建项目
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
