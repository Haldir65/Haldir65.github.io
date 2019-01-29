---
title: Scrappy框架学习笔记
date: 2017-07-12 08:37:55
tags: [python]
---

## Scrappy框架学习
首先建议安装virtualenv，在env中进行操作。

![](https://www.haldir66.ga/static/imgs/green_forest_alogside_river.jpg)

<!--more-->
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


scrapy似乎是提供了一个Request类，传入一个url和callback，另外，项目结构包括scrapy.cfg和setting.py文件，把网络请求的细节隐藏了。最后生成的文件是items.csv(Comma-Separated Values)。应该可以结合其他库去作图。

## 2. MongoDB存储
[pymongo](http://api.mongodb.com/python/current/tutorial.html)，就像node环境下有mongoose可以调用mongodb api一样，python环境下也有对于的driver


### requests的timeout并不是说整个请求的时间限定在10s内完成，而是底层的socket过了10s还没有收到一个Byte.
> timeout is not a time limit on the entire response download; rather, an exception is raised if the server has not issued a response for timeout seconds (more precisely, if no bytes have been received on the underlying socket for timeout seconds). If no timeout is specified explicitly, requests do not time out.


### content-encoding的一些点
在request中添加了'accept-encoding':'gzip, deflate, br'的header之后，返回的response可能是gzip或者是br压缩的.这时候就需要根据response中的content-encoding来决定采用什么样的解压缩方式了。
比如是gzip的话要import gzip，其他的还要另外import。这是python，当然早就有现成的工具了
```python
import brotli
bytecontent = brotli.decompress(response.content) ## byte，还需要decode('utf-8') 然后如果是json的话 , 
strcontent = bytecontent.decode('utf-8')
jobj = json.loads(strcontent)
```

