---
title: 在ubuntu服务器上部署flask web app
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

## 3. Scrappy框架学习
首先建议安装virtualenv，在env中进行操作。
pip install Scrappy 报错
# error: Microsoft Visual C++ 14.0 is required. Get it with "Microsoft Visual C++ Build Tools": http://landinghub.visualstudio.com/visual-cpp-build-tools
解决办法是安装vs,4个GB左右。。。。

以下开始在命令行中操作：
安装完毕后，首先创建scrapy 项目
>scrapy startproject tutorial #创建一个project。会生成一个tutorial的文件夹，在tutorial/spiders文件夹中新建一个quotes_spider.py

参考[Scrapy教程](http://cuiqingcai.com/3952.html/2)
```python
import scrapy
class QuotesSpider(scrapy.Spider):
    name = "quotes"

    def start_requests(self):
        urls = [
            'http://quotes.toscrape.com/page/1/',
            'http://quotes.toscrape.com/page/2/',
        ]
        for url in urls:
            yield scrapy.Request(url=url, callback=self.parse) 
     #这个callback就是response拉下来之后的解析过程 
     #下面的这个做法只是把response写到一个文件中，通常还可以使用css或者xpath解析获得相应值。

    def parse(self, response):
        page = response.url.split("/")[-2]
        filename = 'quotes-%s.html' % page
        with open(filename, 'wb') as f:
            f.write(response.body)
        self.log('Saved file %s' % filename)
```

> scrapy crawl quotes #开始爬quotes.toscrape.com的内容,需要切换到tutorial文件夹下

>scrapy shell 'http://quotes.toscrape.com/page/1/' #从Response中提取所需的值  

输入就能得到大致这样的交互
```
>>> response.css('title::text').extract()
['Quotes to Scrape']
```
由于没有安装vc2014，只能在virtualenv中运行,pycharm中也是显示scrapy没有安装。只能用命令行运行。想要看具体的值需要这样
```python
>>> response.css('title::text').extract_first()
'Quotes to Scrape'

>>> response.css('title::text').re(r'Quotes.*') #这里是正则了
['Quotes to Scrape']

#或者使用xpath
>>> response.xpath('//title/text()').extract_first()
'Quotes to Scrape'
```

处理登录请求，afterLogin
网站登录多数需要提交一个表单（Dict）
> formadata = {'userName':  'Bob','pwd'：123456}
中间件(MiddleWare)的作用
Cookie，UserAgent处理 setting.py中设置需要的参数，Cookie默认是接受的
PipeLine是用来持久化的，中间件用于处理Cookie,Ajax等，rules用于筛选需要跟进的url



4. MongoDB存储



### Reference
1. [how-to-deploy-a-flask-application-on-an-ubuntu-vps](https://www.digitalocean.com/community/tutorials/how-to-deploy-a-flask-application-on-an-ubuntu-vps)