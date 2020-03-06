---
title: celery-cheetsheet
date: 2018-07-03 08:43:41
tags: [python]
---

>“There are only two hard things in Computer Science: cache invalidation and naming things.”
— Phil Karlton

![](https://api1.foster66.xyz/static/imgs/Celery_picture.jpg)

<!--more-->

因为需要使用Redis，在ubuntu上安装redis可以用apt-get，也能自己下载源码去make（前提是内存充足，内存不足的话make test会失败）。所以我干脆关掉了几个比较耗内存的进程，最后直接用apt-get装上了。

下面这几步就算最简单的celery入门了
```python
from celery import Celery

app = Celery('tasks', broker='redis://localhost:6379/0')

@app.task
def add(x, y):
    return x + y
```

celery -A tasks worker --loglevel=info
```
>>> from tasks import add
>>> add.delay(4, 4)
```
注意，windows上celery4不完全支持
[celery-raises-valueerror-not-enough-values-to-unpack](https://stackoverflow.com/questions/45744992/celery-raises-valueerror-not-enough-values-to-unpack)


基本的项目结构
```
proj/__init__.py
    /celery.py
    /tasks.py
```

proj/celery.py 
```python
from __future__ import absolute_import, unicode_literals
from celery import Celery

app = Celery('proj',
             broker='amqp://',
             backend='amqp://',
             include=['proj.tasks'])

# Optional configuration, see the application user guide.
app.conf.update(
    result_expires=3600,
)

if __name__ == '__main__':
    app.start()
```

##耗时的任务都丢到这里就好了
proj/tasks.py
```python
from __future__ import absolute_import, unicode_literals
from .celery import app


@app.task
def add(x, y):
    return x + y


@app.task
def mul(x, y):
    return x * y


@app.task
def xsum(numbers):
    return sum(numbers)
```
注意下面的命令要在proj项目上层目录中运行
> celery -A proj worker -l info

> 执行异步方法，这俩都行：
add.delay(2, 2)
add.apply_async((2, 2)) ##这句话并不会阻塞在这里，后面的方法接着执行，也就达到了异步执行的目的



[在django项目中使用celery](http://docs.celeryproject.org/en/latest/django/first-steps-with-django.html)
[django-celery-example](https://simpleisbetterthancomplex.com/tutorial/2017/08/20/how-to-use-celery-with-django.html)

生产环境需要supervisor守护celery
> sudo apt-get install supervisor
/etc/supervisor/conf.d/something.conf
[program:celery]
command=/home/deploy/.virtualenvs/my_env/bin/celery --app=proj_name worker --loglevel=INFO
directory=/home/deploy/webapps/django_project
user=user_name
autostart=true
autorestart=true
redirect_stderr=true

## 刷新一下supervisor任务
sudo supervisorctl reread
sudo supervisorctl update

##启动celery
sudo supervisorctl start celery


```python
## 失败了自动retry
from celery import shared_task
 
@shared_task(bind=True, max_retries=3)  # you can determine the max_retries here
def access_awful_system(self, my_obj_id):
    from core.models import Object
    from requests import ConnectionError
    o = Object.objects.get(pk=my_obj_id)
    # If ConnectionError try again in 180 seconds
    try:
 
        o.access_awful_system()
    except ConnectionError as exc:
        self.retry(exc=exc, countdown=180)  # the task goes back to the queue


##重试时间指数型增长也行 
@celery_app.task(max_retries=10)
def notify_gcm_device(device_token, message, data=None):
  notification_json = build_gcm_json(message, data=data)
 
  try:
    gcm.notify_device(device_token, json=notification_json)
  except ServiceTemporarilyDownError:
    # Find the number of attempts so far
    num_retries = notify_gcm_device.request.retries
    seconds_to_wait = 2.0 ** num_retries
    # First countdown will be 1.0, then 2.0, 4.0, etc.
    raise notify_gcm_device.retry(countdown=seconds_to_wait)

## eta 像crontab一样定期执行任务
from django.utils import timezone
from datetime import timedelta
now = timezone.now() 
 
# later is one hour from now
later = now + timedelta(hours=1)
access_awful_system.apply_async((object_id), eta=later)

```

## 创建多个queue
```
# CELERY ROUTES
CELERY_ROUTES = {
    'core.tasks.too_long_task': {'queue': 'too_long_queue'},
    'core.tasks.quick_task': {'queue': 'quick_queue'},
}

# For too long queue
celery --app=proj_name worker -Q too_long_queue -c 2
# For quick queue
celery --app=proj_name worker -Q quick_queue -c 2
```

可以subclass task，比如自定义缓存什么的
```python
class MyTask(celery.Task):
    ignore_result = False  # in case you set it to True globally — you should!
    def __init__(self):
        # This code is only called once per worker.
        # Here you can define members, which will be accessible when the task runs, later on.
        self.cache = {}
    def run(self, user_id, arg):
        # Now the task is executing.
        # We have the ‘cache’ at our disposal!
        return self.normal_operation(user_id, arg)
    def normal_operation(self, user_id, arg):
        if (user_id, arg) in self.cache:
             return self.cache[(user_id, arg)]
        retval = self.some_value(user_id, arg)
        self.cache[(user_id, arg)] = retval
        return retval

```


### references
[celery有一个监控工具Flower](http://flower.readthedocs.io/en/latest/)
[asynchronous-tasks-with-django-and-celery](https://realpython.com/asynchronous-tasks-with-django-and-celery/)
[my-experiences-with-a-long-running-celery-based-microprocess](https://theblog.workey.co/my-experiences-with-a-long-running-celery-based-microprocess-b2cc30da94f5)


