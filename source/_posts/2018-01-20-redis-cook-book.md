---
title: redis-cook-book
date: 2018-01-20 08:19:20
tags:
---

![](http://odzl05jxx.bkt.clouddn.com/image/jpg/apple logo dark bw life night.jpg?imageView2/2/w/600)
<!--more-->

redis速度相当快
[The Redis project does not officially support Windows. However, the Microsoft Open Tech group develops and maintains this Windows port targeting Win64. ](https://github.com/MicrosoftArchive/redis)
直接从release page下载msi文件，安装下去很方便的

### start server and client
 > redis-server  redis.windows.conf  
 > 双击打开 redis-cli.exe ## start client

 和数据库类似，不同业务的数据需要存贮在不同的数据库中，redis提供了client端的切换数据库的语法
 > select 1 ## 每个数据库之间的key不冲突

### Configurations

> sudo find / -name "redis.conf" ##  linux下应该是装到了/etc/redis/这个目录下，不确定的话find一下

常见的配置包括：

> port 6379 ## redis-server监听端口（默认6379）
requirepass ## 指定客户端操作需要的密码
databases 16 ## 这里面对于可供选择的数据库总数


### 错误处理
当内存达到最大值的时候Redis会选择删除哪些数据？有五种方式可供选择
>volatile-lru -> 利用LRU算法移除设置过过期时间的key (LRU:最近使用 Least Recently Used )
allkeys-lru -> 利用LRU算法移除任何key
volatile-random -> 移除设置过过期时间的随机key
allkeys->random -> remove a random key, any key
volatile-ttl -> 移除即将过期的key(minor TTL)
noeviction -> 不移除任何可以，只是返回一个写错误

### 支持的存储类型
- Strings
- Hashes
- Lists
- Sets
- Sorted Sets


## 针对各种数据进行CURD操作

**String**
```shell
set(key, value)：给数据库中名称为key的string赋予值value
get(key)：返回数据库中名称为key的string的value
getset(key, value)：给名称为key的string赋予上一次的value
mget(key1, key2,…, key N)：返回库中多个string的value
setnx(key, value)：添加string，名称为key，值为value
setex(key, time, value)：向库中添加string，设定过期时间time
mset(key N, value N)：批量设置多个string的值
msetnx(key N, value N)：如果所有名称为key i的string都不存在
incr(key)：名称为key的string增1操作
incrby(key, integer)：名称为key的string增加integer
decr(key)：名称为key的string减1操作
decrby(key, integer)：名称为key的string减少integer
append(key, value)：名称为key的string的值附加value
substr(key, start, end)：返回名称为key的string的value的子串
```


**Hashes**
A Redis hash is a collection of key value pairs. Redis Hashes are maps between string fields and string values. Hence, they are used to represent objects.

Hashes用于代表object

```shell
## 添加操作
## set
redis> HMSET myhash field1 "Hello" field2 "World"
"OK"

## 只在field不存在的时候添加，可以理解为putIfAbsent
HSETNX myhash field "Hello"
##返回1表明设置成功，返回0说明不成功

## 查询操作
## get
redis> HGET myhash field1
"Hello"
redis> HGET myhash field2
"World"

### delete a specified field from an object
## 删除操作
redis> HSET myhash field1 "foo"
redis> HDEL myhash field1
## 返回0表示不存在该key，返回1表示删除成功

##检查是否存在某个field
HEXISTS myhash field1
(integer) 1  
##1表示存在，0表示不存在

## 把某个变量的值增加
HINCRBY myhash field 1
## 返回操作成功后field 的当前value

##查看当前object有哪些field,类似于javaScript的iterating  protoType
HKEYS myhash


```

**Lists**
Redis Lists are simply lists of strings, sorted by insertion order. You can add elements to a Redis List on the head or on the tail.


```shell
redis 127.0.0.1:6379> lpush tutoriallist redis
(integer) 1
redis 127.0.0.1:6379> lpush tutoriallist mongodb
(integer) 2
redis 127.0.0.1:6379> lpush tutoriallist rabitmq
(integer) 3
redis 127.0.0.1:6379> lrange tutoriallist 0 10  

1) "rabitmq"
2) "mongodb"
3) "redis"



rpush(key, value)：在名称为key的list尾添加一个值为value的元素
lpush(key, value)：在名称为key的list头添加一个值为value的 元素
llen(key)：返回名称为key的list的长度
lrange(key, start, end)：返回名称为key的list中start至end之间的元素
ltrim(key, start, end)：截取名称为key的list
lindex(key, index)：返回名称为key的list中index位置的元素
lset(key, index, value)：给名称为key的list中index位置的元素赋值
lrem(key, count, value)：删除count个key的list中值为value的元素
lpop(key)：返回并删除名称为key的list中的首元素
rpop(key)：返回并删除名称为key的list中的尾元素
blpop(key1, key2,… key N, timeout)：lpop命令的block版本。
brpop(key1, key2,… key N, timeout)：rpop的block版本。
rpoplpush(srckey, dstkey)：返回并删除名称为srckey的list的尾元素，并将该元素添加到名称为dstkey的list的头部
```


**SET**

```shell
sadd(key, member)：向名称为key的set中添加元素member
srem(key, member) ：删除名称为key的set中的元素member
spop(key) ：随机返回并删除名称为key的set中一个元素
smove(srckey, dstkey, member) ：移到集合元素
scard(key) ：返回名称为key的set的基数
sismember(key, member) ：member是否是名称为key的set的元素
sinter(key1, key2,…key N) ：求交集
sinterstore(dstkey, (keys)) ：求交集并将交集保存到dstkey的集合
sunion(key1, (keys)) ：求并集
sunionstore(dstkey, (keys)) ：求并集并将并集保存到dstkey的集合
sdiff(key1, (keys)) ：求差集
sdiffstore(dstkey, (keys)) ：求差集并将差集保存到dstkey的集合
smembers(key) ：返回名称为key的set的所有元素
srandmember(key) ：随机返回名称为key的set的一个元素
```



## 一些特性的指令

### 持久化
```shell
save：将数据同步保存到磁盘
bgsave：将数据异步保存到磁盘
lastsave：返回上次成功将数据保存到磁盘的Unix时戳
shundown：将数据同步保存到磁盘，然后关闭服务
```

### 设定有效时间
expireat

### 对Value的操作
```shell
exists(key)：确认一个key是否存在
del(key)：删除一个key
type(key)：返回值的类型
keys(pattern)：返回满足给定pattern的所有key
randomkey：随机返回key空间的一个
keyrename(oldname, newname)：重命名key
dbsize：返回当前数据库中key的数目
expire：设定一个key的活动时间（s）
ttl：获得一个key的活动时间
select(index)：按索引查询
move(key, dbindex)：移动当前数据库中的key到dbindex数据库
flushdb：删除当前选择数据库中的所有key
flushall：删除所有数据库中的所有key
```

### SubScribe和Publish
```shell
redis 127.0.0.1:6379> SUBSCRIBE redisChat  
Reading messages... (press Ctrl-C to quit)
1) "subscribe"
2) "redisChat"
3) (integer) 1

## 另起一个screen
PUBLISH redisChat "Redis is a great caching technique"  
## 回到刚才的screen : ctrl +a +d screen -r
```

两个client同时subscribe了redisChat这个话题，表现上就和局域网聊天一样。也就有了很多用js+webSocket写的简易聊天室


### pipelining
一次请求/响应服务器能实现处理新的请求即使旧的请求还未被响应。这样就可以将多个命令发送到服务器，而不用等待回复，最后在一个步骤中读取该答复。
省去了RTT(Round Trip deplay time)的时间。
```
非pipleline模式：

Request---->执行

---->Response

Request---->执行

---->Response
Pipeline模式下：

Request---->执行，Server将响应结果队列化

Request---->执行，Server将响应结果队列化

---->Response

---->Response
```

### 和其他语言的整合
[支持的lanaguage client](https://redis.io/clients)


[jedis](https://github.com/xetorthio/jedis)
**java**
```java
public void pipeline(){  
        String key = "pipeline-test";  
        String old = jedis.get(key);  
        if(old != null){  
            System.out.println("Key:" + key + ",old value:" + old);  
        }  
        //代码模式1,这种模式是最常见的方式  
        Pipeline p1 = jedis.pipelined();  
        p1.incr(key);  
        System.out.println("Request incr");  
        p1.incr(key);  
        System.out.println("Request incr");  
        //结束pipeline，并开始从相应中获得数据  
        List<Object> responses = p1.syncAndReturnAll();  
        if(responses == null || responses.isEmpty()){  
            throw new RuntimeException("Pipeline error: no response...");  
        }  
        for(Object resp : responses){  
            System.out.println("Response:" + resp.toString());//注意，此处resp的类型为Long  
        }  
        //代码模式2  
        Pipeline p2 = jedis.pipelined();  
        Response<Long> r1 = p2.incr(key);  
        try{  
            r1.get();  
        }catch(Exception e){  
            System.out.println("Error,you cant get() before sync,because IO of response hasn't begin..");  
        }  
        Response<Long> r2 = p2.incr(key);  
        p2.sync();  
        System.out.println("Pipeline,mode 2,--->" + r1.get());  
        System.out.println("Pipeline,mode 2,--->" + r2.get());  

    }  
```


**python**
[redis-py](https://github.com/andymccurdy/redis-py)
[使用Python操作Redis](http://debugo.com/python-redis/)

### 应用场景

>
《Redis Cookbook》对这个经典场景进行详细描述。假定我们对一系列页面需要记录点击次数。例如论坛的每个帖子都要记录点击次数，而点击次数比回帖的次数的多得多。如果使用关系数据库来存储点击，可能存在大量的行级锁争用。所以，点击数的增加使用redis的INCR命令最好不过了。

### 存储多层次级别的object
[Redis strings vs Redis hashes to represent JSON: efficiency?
](https://stackoverflow.com/questions/16375188/redis-strings-vs-redis-hashes-to-represent-json-efficiency)
由于redis各种commands本质上只能存储key-value形式的object，对于多层级的object，需要将key扁平化
```javaScript
var house = {
  roof: {
    color: 'black'
  },
  street: 'Market',
  buildYear: '1996'
};
```
> HMSET house:1 roof "house:1:roof" street "Market" buildYear "1996"

[在redis中存储关系型数据](https://alexandergugel.svbtle.com/storing-relational-data-in-redis)

=================================================================================

### Redis Cluster(集群)





## 参考
[redis official docs](https://redis.io/commands/hlen)
[Redis supports 5 types of data types] (https://www.tutorialspoint.com/redis/redis_data_types.htm)
[Redis 高级特性与性能调优](http://www.ttlsa.com/redis/redis-advanced-features-and-performance-tuning/)
[大部分语句转载自](http://www.dnsdizhi.com/post-219.html)
[关于pipelining的解释](http://shift-alt-ctrl.iteye.com/blog/1863790)
