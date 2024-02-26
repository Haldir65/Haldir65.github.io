---
title: django学习记录
date: 2018-06-12 22:40:01
tags: [python,django]
---


![](https://api1.reindeer36.shop/static/imgs/djangopony-slide.png)



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

[在ununtu上使用uwsgi和nginx运行django application](https://www.digitalocean.com/community/tutorials/how-to-deploy-python-wsgi-applications-using-uwsgi-web-server-with-nginx)

uwsgi.conf文件里面需要注意的有这么一条
[uwsgi]
module = somefile:app ## 当前目录下有一个somefile.py文件，里面有一个app = Flask(__name__)



requirements.txt的生成和使用
当然都要在virtualenv中了
> (venv) $ pip freeze > requirements.txt # 创建
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

[在ubuntu服务器上搭配nginx部署django应用](https://www.digitalocean.com/community/tutorials/how-to-deploy-python-wsgi-applications-using-uwsgi-web-server-with-nginx)
创建一个myconf.ini文件
> uwsgi --ini myconf.ini


![](https://api1.reindeer36.shop/static/imgs/food-salad-instagram-hunger-city-life.jpg)

还有，多数时候会热更新，但比如我更改了PaginationClass，还是得重新runserver才能获得理想的结果

[目前DRF不支持通过一个Post请求创建一个list of nested objects](https://stackoverflow.com/questions/23153040/django-rest-framework-create-objects-passed-as-a-list-attribute-of-nested-obje)

自定义接口返回格式
ListCreateAPIView中override create方法
```python
def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid(raise_exception=False):
            return Response({"Fail": "blablal", status=status.HTTP_400_BAD_REQUEST)

        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response({"Success": "msb blablabla"}, status=status.HTTP_201_CREATED, headers=headers)
```

post和get请求都变得非常轻松
```python
class CountryView(APIView):

    def get(self, request, format=None):
        snippets = County.objects.all()
        serializer = CountySimpleSerilizer(snippets, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        serializer = CountySimpleSerilizer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return responses.JsonResponse(serializer.data, status=status.HTTP_201_CREATED)
        return responses.JsonResponse(data={"name","bad post request"}, status=status.HTTP_400_BAD_REQUEST)
```


> python manage.py dbshell ##用于在命令行中直接查看数据库
> .help 查看在这个shell中可以用的一些操作
> .tables  查看当前创建的所有的表 这个不要加分号
> DROP TABLE appname_model; 删表 这个要加分号

注意，删了表之后，还得把对应的migrations中的文件删掉，否则migrate无效


pk其实就是primary_key的意思
```python
Object.objects.get(id=1)
Object.objects.get(pk=1)

## 看清楚了，是两个下划线
User.objects.filter(pk__in=[1,2,3])
User.objects.filter(pk__gt=10)  
User.objects.filter(pk__lt=10)  
```

[nested relations](http://www.django-rest-framework.org/api-guide/relations/)

```
{
    "detail": "Method \"GET\" not allowed."
}
```
随便继承一个APIView，只写了post方法，使用GET方法就会得到这个response

urlPatterns的一些东西
[如果url中有空格的话就直接换成%20](https://stackoverflow.com/questions/3675368/django-url-pattern-for-20)
urls.py里面写的主要是一堆正则表达式
```python
urlpatterns = [
    url(r'^profiles/(?P<username>[\w\ ]+)/?$', ProfileRetrieveAPIView.as_view()),
    url(r'^profiles/(?P<username>\w+)/follow/?$', 
        ProfileFollowAPIView.as_view()),
]
```
第一行的意思是访问 /profiles/你想要查找的userName 这个链接就会交给后面这个View

lookup_field和lookup_url_kwarg都是定义在GenericApiView这个Class上的
```python
class GenericAPIView(views.APIView):
    """
    Base class for all other generic views.
    """
    queryset = None
    serializer_class = None

    # If you want to use object lookups other than pk, set 'lookup_field'.
    # For more complex lookup requirements override `get_object()`.
    lookup_field = 'pk'
    lookup_url_kwarg = None

    # The filter backend classes to use for queryset filtering
    filter_backends = api_settings.DEFAULT_FILTER_BACKENDS

    # The style to use for queryset pagination.
    pagination_class = api_settings.DEFAULT_PAGINATION_CLASS
```

rest-framework的文档是这么说的
> lookup_field - The model field that should be used to for performing object lookup of individual model instances. Defaults to 'pk'. Note that when using hyperlinked APIs you'll need to ensure that both the API views and the serializer classes set the lookup fields if you need to use a custom value.
lookup_url_kwarg - The URL keyword argument that should be used for object lookup. The URL conf should include a keyword argument corresponding to this value. If unset this defaults to using the same value as lookup_field

简言之，就是lookup_field就是把url里面传进来的参数当做model的什么field来查，比如model是Customer，primarykey是customername，默认的lookup_field就是这个主键。客户端的url需要传上来一个customername，然后就会根据这个customername去Customer.objects.filter(customername="xxx")去找。如果定义lookup_field为customer_age，就会把客户端传上来的参数当做一个customer_age去查找,Customer.objects.filter(customer_age="xxx")


关于这个继承关系，CreateAPIView，ListAPIView，RetrieveAPIView，DestroyAPIView这些全都是继承了GenericAPIView，并各自继承了mixin，扩展出post,get,post,delete等方法。

mixins.ListModelMixin，定义了一个list方法，返回一个queryset列表，对应GET方法
mixins.CreateModelMixin，定义了一个create方法，创建一个实例，对应POST请求
mixins.RetrieveModelMixin，定义了一个retrieve方法，对应GET请求
mixins.UpdateModelMixin，定义一个update方法，对应PUT/PATCH请求


```python
##在models的Filed中定义一个
createdAt = serializers.SerializerMethodField(method_name='get_created_at') ##意味着这个field要调用一个自定义的方法去获取
updatedAt = serializers.SerializerMethodField(method_name='get_updated_at')


##filed还有一个source的概念: The name of the attribute that will be used to populate the field.  默认是这个field的name，比如可以定义为model的一个方法，也可以定义为一个model的field


##serializer里面可以自定义model中不存在的field
customField = RelatedField(many=True, required=False, source='tags') ## 这个tags是存在的，customField是不存在这个model中的
##这样做就很有意思了，因为从数据库里查出来的object可能就那么点信息，客户端希望后台在response中添加一些原本不存在于数据库model中的信息。就可以在某个已有变量的基础上扩展新的response 数据


## 这里的insatnce是Serializer的model的实例
def get_created_at(self, instance):
    return instance.created_at.isoformat()

```

[在serializer层面为model添加field](https://stackoverflow.com/questions/13471083/how-to-extend-model-on-serializer-level-with-django-rest-framework)。这里面要注意field还有read-only和write-only等区别   
关于slugFiled
>from django.utils.text import 
Well, if we give a string like ‘The new article title’ to slugify(), it returns ‘the-new-article-title’. Simple.

slugField主要是为了让url好看点
>Slugs are created mostly for the purpose of creating a nice, clean URL.
Say for example, you have a site of user-generated posts, such as stackoverflow or quora.
A user starts a post that has a title.
Each post creates a separate web page based on the title.
Now if a user asks the question, "How do you slugify text in Python"
If a URL is created for this question, as is, with the spaces in them, the browser will insert %20 in place of each space. Therefore, the URL will be, How%20do%20you%20slugify%20text%20in%20Python
This will work, but it looks extremely ugly and isn't very human readable.
So instead of having spaces in a URL, a slugified text is created that contains no spaces. Instead of spaces there are "-" instead. Therefore, the URL will be, How-do-you-slugify-text-in-Python
This looks much cleaner and is much more human readable.


drf 的authorization默认需要是这样的:
>Authorization: Token 9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b
Note: If you want to use a different keyword in the header, such as Bearer, simply subclass TokenAuthentication and set the keyword class variable.
If successfully authenticated, TokenAuthentication provides the following credentials.
request.user will be a Django User instance.
request.auth will be a rest_framework.authtoken.models.Token instance.



### jwt的logout或者踢人怎么做
[首先Token是放在内存里而不是db里的，另外要踢人的话，手动给这个user生成一个新的token](https://stackoverflow.com/questions/40604877/how-to-delete-a-django-jwt-token)
搞清楚，踢人是服务器这边做(创建个新的Token或者让原有Token无效)，logout是客户端那边做(删除客户端本地存储的Token)。
在html里面删掉Token可以这么干
```html
<script>
document.cookie = "token=; expires=Thu, 01 Jan 1970 00:00:01 GMT; path=/";
location.href="/accounts/auth/";
</script>
```
对，就是简单的把token置空就行了

代码里认证的地方取的Header是WWW-Authenticate XXX，但客户端传的是Authorization。估计这是wsgi协议[文档在这里](http://wsgi.readthedocs.io/en/latest/specifications/simple_authentication.html)相关的，记得Nginx好像也有这样的设定。
WWW-Authenticate: Token


从[django urlconf中抄来这些代码](https://docs.djangoproject.com/en/2.0/topics/http/urls/)
```python
from django.urls import path, re_path

from . import views
from django.urls import path

from . import views

urlpatterns = [
    path('articles/2003/', views.special_case_2003),
    path('articles/<int:year>/', views.year_archive),
    path('articles/<int:year>/<int:month>/', views.month_archive),
    path('articles/<int:year>/<int:month>/<slug:slug>/', views.article_detail),
]

##底下这个和上面的差不多，底下用的是re_path，使用正则，年份只能四位，传给view的参数类型始终是str。还是有点小区别

urlpatterns = [
    path('articles/2003/', views.special_case_2003),
    re_path(r'^articles/(?P<year>[0-9]{4})/$', views.year_archive),
    re_path(r'^articles/(?P<year>[0-9]{4})/(?P<month>[0-9]{2})/$', views.month_archive),
    re_path(r'^articles/(?P<year>[0-9]{4})/(?P<month>[0-9]{2})/(?P<slug>[\w-]+)/$', views.article_detail),
]
```

关于performance的issue，参考[这里](http://ses4j.github.io/2015/11/23/optimizing-slow-django-rest-framework-performance/)
```python
class CustomerSerializer(serializers.ModelSerializer):
    # This can kill performance!
    order_descriptions = serializers.StringRelatedField(many=True) 
    # So can this, same exact problem...
    orders = OrderSerializer(many=True, read_only=True) # This can kill performance!
```

>The code inside DRF that populates either CustomerSerializer does this:
Fetch all customers. (Requires a round-trip to the database.)
For the first returned customer, fetch their orders. (Requires another round-trip to the database.)
For the second returned customer, fetch its orders. (Requires another round-trip to the database.)
For the third returned customer, fetch its orders. (Requires another round-trip to the database.)
For the fourth returned customer, fetch its orders. (Requires another round-trip to the database.)
For the fifth returned customer, fetch its orders. (Requires another round-trip to the database.)
For the sixth returned customer, fetch its orders. (Requires another round-trip to the database.)
... you get the idea. Lets hope you don't have too many customers!

所以要是有50个customer，就要执行50次查询，加上第一次获取所有Customer的数据库query。

优化后的代码只需要走2次数据库
```python
queryset = queryset.prefetch_related('orders') ##干两件事，一个是获取所有user，一个是获取这些user的orer集合，一共就两次sql执行
```
其实这些东西在[Django official document](https://docs.djangoproject.com/en/dev/ref/models/querysets/#django.db.models.query.QuerySet.select_related)里面都提到过。

另外的优化就是用redis了,比如说[Caching in Django With Redis](https://realpython.com/caching-in-django-with-redis/)

>pip install django-redis 

```python
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': '127.0.0.1:6379',
        "OPTIONS": {
            "CLIENT_CLASS": "django_redis.client.DefaultClient",
        },
    },
}

## python manage.py shell 开一个shell，记得先把redis的server跑起来
from django.core.cache import cache #引入缓存模块
cache.set('k', '12314', 30*60)      #写入key为k，值为12314的缓存，有效期30分钟
cache.has_key('k') #判断key为k是否存在
cache.get('k')     #获取key为k的缓存
```
一切OK的话说明可以用了

view.py
```python
from rest_framework.views import APIView
from rest_framework import status
from rest_framework.response import Response
from .serializers import CourseSerializer
from .models import Course
from django.core.cache import cache
import time

def get_data_from_db(criteria_name):
    course = Course.objects.get(criteria=criteria_name)
    return course


def get_readed_cache(criteria_name):
    #判断键是否存在
    key = '_key_course_query_criteria_'+criteria_name
    if cache.has_key(key):
        data = cache.get(key)
        print('cache hit')
    else:
        #不存在，则获取数据，并写入缓存
        data = get_data_from_db(criteria_name)
 
        #写入缓存
        cache.set(key, data, 3600-int(time.time() % 3600))
        print('sorry , no cache')
    return data

# Create your views here.

class CourseApiView(APIView):

    def post(self,request,format=None):
        serializer = CourseSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data,status=status.HTTP_201_CREATED)
        return Response(data={"msg":"invalid data"},status=status.HTTP_400_BAD_REQUEST)

    def get(self, request, *args, **kwargs):
        critia = request.query_params.get('criteria',None)
        if critia:
            cached_data = get_readed_cache(critia)
            course = cached_data
            if course:
                serializer = CourseSerializer(course)
                return Response(serializer.data,status=status.HTTP_200_OK)    
        return Response("not found",status=status.HTTP_404_NOT_FOUND)          
```


[drf默认的admin pannel可以自定义样式和功能](https://books.agiliq.com/projects/django-admin-cookbook/en/latest/change_text.html)
[这人的博客不错](https://simpleisbetterthancomplex.com/tutorial/2016/08/01/how-to-upload-files-with-django.html)

[querySet里面有一个_set](https://stackoverflow.com/questions/42080864/set-in-django-for-a-queryset)
在moderl中没有声明related_name的情况下，需要通过_set来反向查找model
>For example, if Product had a many-to-many relationship with User, named purchase, you might want to write a view like this:

```python
class PurchasedProductsList(generics.ListAPIView):
    """
    Return a list of all the products that the authenticated
    user has ever purchased, with optional filtering.
    """
    model = Product
    serializer_class = ProductSerializer
    filter_class = ProductFilter

    def get_queryset(self):
        user = self.request.user
        return user.purchase_set.all()
```


filter_backend是定义在GenericAPIView中的，所以要使用这个属性得用GenericAPIView


[nested relations](http://www.django-rest-framework.org/api-guide/relations/)

json web token authentication
> pip install djangorestframework-jwt


```python
##settings.py
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework.authentication.BasicAuthentication',
        'rest_framework.authentication.SessionAuthentication',
        # 'rest_framework.authentication.TokenAuthentication',
        'rest_framework_jwt.authentication.JSONWebTokenAuthentication',  # 加入此行
    ),
}

## urls.py
urlpatterns = [
	...
    # url(r'api-auth-token/', authtoken_views.obtain_auth_token),  # drf自带的token认证
    url(r'login/', jwt_authtoken_views.obtain_jwt_token),       # 加此行，jwt认证
]
```

然后通过post请求127.0.0.1/login/,body中添加username和password
得到这样的response 
```json
{
  "token": "someweirdwords---------"
}
```
下次请求的时候带上这个Header就好了
```json
"Authorization": "JWT someweirdwords---------"
```

通过manage.py创建user的方式：
```
user@host> manage.py shell
>>> from django.contrib.auth.models import User
>>> user=User.objects.create_user('John', password='password123')
>>> user.is_superuser=False
>>> user.is_staff=False
>>> user.save()
```

用jwt去请求需要authentication的接口时，header里面得带上一个
```
Authorization: Token 登录.接口.返回的token
```


注意Token这个单词后面有一个空格

[caching django with redis](https://realpython.com/caching-in-django-with-redis/)
[redirect in django](https://realpython.com/django-redirects/#redirects-that-just-wont-redirect)
