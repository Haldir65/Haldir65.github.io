---
title: Tomcat部分源码解析
date: 2019-07-28 21:50:29
tags: [java,tbd]
---

[Tomcat](https://github.com/apache/tomcat)源码解析

![](https://www.haldir66.ga/static/imgs/LetchworthSP_EN-AU14482052774_1920x1080.jpg)
<!--more-->

tomcat的使用很简单，windows下双击那个startup.bat或者cd 到bin目录，运行catlina run就可以了。配置的话，用xml文件就可以了，静态文件放在webapp/目录下。。


从Spring-boot支持的embedded servlet container就能看出来，tomcat的替代品有不少
spring-boot-starter-undertow,
spring-boot-starter-jetty,
spring-boot-starter-tomcat 

**<font color="red">源码版本tomcat 9.0.21</font>**

##  从main函数开始吧
tomcat的主函数在org.apache.catalina.startup.Bootstrap这个文件中
```java
public final class Bootstrap {

    public static void main(String args[]) {
        Bootstrap bootstrap = new Bootstrap();
        try {
            bootstrap.init();
        } catch (Throwable t) {
            t.printStackTrace();
            return;
        }
        //接下来就是根据不同的command执行对应的start,stop等命令
          try {
            String command = "start";
            if (args.length > 0) {
                command = args[args.length - 1];
            }

            if (command.equals("startd")) {
                args[args.length - 1] = "start";
                daemon.load(args);
                daemon.start();
            } else if (command.equals("stopd")) {
                args[args.length - 1] = "stop";
                daemon.stop();
            } else if (command.equals("start")) {
                daemon.setAwait(true);
                daemon.load(args);
                daemon.start();
                if (null == daemon.getServer()) {
                    System.exit(1);
                }
            } else if (command.equals("stop")) {
                daemon.stopServer(args);
            } else if (command.equals("configtest")) {
                daemon.load(args);
                if (null == daemon.getServer()) {
                    System.exit(1);
                }
                System.exit(0);
            } else {
                log.warn("Bootstrap: command \"" + command + "\" does not exist.");
            }
        }
    }
}
```

## init的调用栈
Tomcat能够处理ajp(不常用，无视)和http协议。
默认情况下，Server只有一个Service组件，Service组件先后对Engine、Connector进行初始化。而Engine组件并不会在初始化阶段对子容器进行初始化，Host、Context、Wrapper容器的初始化是在start阶段完成的。tomcat默认会启用HTTP1.1和AJP的Connector连接器，这两种协议默认使用Http11NioProtocol、AJPNioProtocol进行处理

> Connector的主要功能，是接收连接请求，创建Request和Response对象用于和请求端交换数据；然后分配线程让Engine（也就是Servlet容器）来处理这个请求，并把产生的Request和Response对象传给Engine。当Engine处理完请求后，也会通过Connector将响应返回给客户端。


ProtocolHandler是处理HTTP1.1协议的类(实际上是一个接口)，实现的子类有两个，AbstractProtocol和Http11NioProtocol（继承于AbstractProtocol）
AbstractProtocol是基本的实现，可以认为这个类把主要的活都干了，而NIO默认使用的是Http11NioProtocol。

在AbstractProtocol的init方法中，调用了endpoint.init();endPoint是抽象类，实现类包括NioEndpoint和Nio2Endpoint。Endpoint的主要工作是完成端口和地址的绑定监听。
```java
// NioEndPoint.java
private volatile ServerSocketChannel serverSock = null;
// ServerSocketChannel是nio的一个类，用于监听外来请求的

protected void initServerSocket() throws Exception {

serverSock = ServerSocketChannel.open();
        socketProperties.setProperties(serverSock.socket()); // 这里面设了是否要setReuseAddress，设置setSoTimeout为多少
        InetSocketAddress addr = new InetSocketAddress(getAddress(), getPortWithOffset());
        serverSock.socket().bind(addr,getAcceptCount()); //这里就是socket.bind的地方了
}

// Nio2Endpoint.java
@Override
public void bind() throws Exception {
    serverSock = AsynchronousServerSocketChannel.open(threadGroup);
    socketProperties.setProperties(serverSock);
    InetSocketAddress addr = new InetSocketAddress(getAddress(), getPortWithOffset());
    serverSock.bind(addr, getAcceptCount());
}
```
可以看出来NioEndPoint和Nio2EndPoint在绑定socket的时候的区别是后者用的是jdk1.7的AsynchronousServerSocketChannel，而ServerSocketChannel是jdk1.4就有的。java的io操作分为bio,nio,nio2，tomcat8.5开始去掉了bio（就是那种阻塞式io）的支持。


在 socketProperties.setProperties里面，设置了socket的超时时间，很好奇到底是多少
在Constants.java中
```java
public static final int DEFAULT_CONNECTION_TIMEOUT = 60000; 
```
**所以是1分钟?**

接着NioEndPoint.java的Bind方法来看，走到了selectorPool.open(getName());
这里面就是启动了一条线程,NioBlockingSelector.BlockPoller继承自Thread。对应的run方法中使用的是selector那一套(selector.selectedKeys()获得一个Iterator<SelectionKey> ，根据是read,write还是connect的形式去判断)。注意，此刻已经开始select了。select自身是阻塞的，但是一旦有io事件到来，就会将事件交给线程池去处理，所以并发性能是可以的。

[参考](https://www.cnblogs.com/kismetv/p/7806063.html)

<font color="red">Tomcat处理请求的过程：在accept队列中接收连接（当客户端向服务器发送请求时，如果客户端与OS完成三次握手建立了连接，则OS将该连接放入accept队列）；在连接中获取请求的数据，生成request；调用servlet容器处理请求；返回response。</font>

线程池的配置是可以通过server.xml配置的
```xml
<Executor name="tomcatThreadPool" namePrefix ="catalina-exec-" maxThreads="150" minSpareThreads="4" />
<Connector executor="tomcatThreadPool" port="8080" protocol="HTTP/1.1" connectionTimeout="20000" redirectPort="8443" acceptCount="1000" />
```

<font color="red">Connector中的几个参数功能如下：</font>
- acceptCount
accept队列的长度；当accept队列中连接的个数达到acceptCount时，队列满，进来的请求一律被拒绝。默认值是100。
关于这个100，我记得2017年的时候，公司后端老大在一次内部技术分享的点评环节提问一帮后端这个参数是多少，其当时还提到这个Executor“就是接客”的(原话如此)。两年后回过头来再来看这段，挺有趣的。

- maxConnections
Tomcat在任意时刻接收和处理的最大连接数。当Tomcat接收的连接数达到maxConnections时，Acceptor线程不会读取accept队列中的连接；这时accept队列中的线程会一直阻塞着，直到Tomcat接收的连接数小于maxConnections。如果设置为-1，则连接数不受限制。

- maxThreads
请求处理线程的最大数量。默认值是200（Tomcat7和8都是的）。如果该Connector绑定了Executor，这个值会被忽略，因为该Connector将使用绑定的Executor，而不是内置的线程池来执行任务。
maxThreads规定的是最大的线程数目，并不是实际running的CPU数量；实际上，maxThreads的大小比CPU核心数量要大得多。这是因为，处理请求的线程真正用于计算的时间可能很少，大多数时间可能在阻塞，如等待数据库返回数据、等待硬盘读写数据等。因此，在某一时刻，只有少数的线程真正的在使用物理CPU，大多数线程都在等待；因此线程数远大于物理核心数才是合理的。
换句话说，Tomcat通过使用比CPU核心数量多得多的线程数，可以使CPU忙碌起来，大大提高CPU的利用率。
默认值与连接器使用的协议有关：NIO的默认值是10000，APR/native的默认值是8192，而BIO的默认值为maxThreads（如果配置了Executor，则默认值是Executor的maxThreads）。
在windows下，APR/native的maxConnections值会自动调整为设置值以下最大的1024的整数倍；如设置为2000，则最大值实际是1024。

---
<font color="red">Executor的主要属性包括：</font>
- name：该线程池的标记
- maxThreads：线程池中最大活跃线程数，默认值200（Tomcat7和8都是）
- minSpareThreads：线程池中保持的最小线程数，最小值是25
- maxIdleTime：线程空闲的最大时间，当空闲超过该值时关闭线程（除非线程数小于minSpareThreads），单位是ms，默认值60000（1分钟）
- daemon：是否后台线程，默认值true
- threadPriority：线程优先级，默认值5
- namePrefix：线程名字的前缀，线程池中线程名字为：namePrefix+线程编号

---
这些参数的调优有一些经验:
（1）maxThreads的设置既与应用的特点有关，也与服务器的CPU核心数量有关。通过前面介绍可以知道，maxThreads数量应该远大于CPU核心数量；而且CPU核心数越大，maxThreads应该越大；应用中CPU越不密集（IO越密集），maxThreads应该越大，以便能够充分利用CPU。当然，maxThreads的值并不是越大越好，如果maxThreads过大，那么CPU会花费大量的时间用于线程的切换，整体效率会降低。
（2）maxConnections的设置与Tomcat的运行模式有关。<del/>如果tomcat使用的是BIO，那么maxConnections的值应该与maxThreads一致</del>；如果tomcat使用的是NIO，maxConnections值应该远大于maxThreads。
（3）通过前面的介绍可以知道，虽然tomcat同时可以处理的连接数目是maxConnections，但服务器中可以同时接收的连接数为maxConnections+acceptCount 。acceptCount的设置，与应用在连接过高情况下希望做出什么反应有关系。如果设置过大，后面进入的请求等待时间会很长；如果设置过小，后面进入的请求立马返回connection refused。


走到这里，是从BootStrap.init -> Catalina.init-> ...总之中间封了很多层组件... -> 方法的调用栈


## start方法的调用栈
和init一样,bootStrap的start方法被代理给了catalina的start方法
Catalina.java
```java
public void start() {
    try {
        getServer().start();
    } catch (LifecycleException e) {
        //....
        return;
    }

    if (shutdownHook == null) {
        shutdownHook = new CatalinaShutdownHook();
    }
    //用于安全的关闭服务
    Runtime.getRuntime().addShutdownHook(shutdownHook);

     if (await) { //这个是true
            await(); //其目的在于让tomcat在shutdown端口阻塞监听关闭命令
            stop();
    }
}
```

上面的getServer返回的是server的默认实现StandardServer，后者的startInternal中又会走到StandardService，的startInternal，这里面会
1. 调用Engine.start
2. 启动线程池
3. 启动Connector

一个个来看
Engine
StandardEngine、StandardHost、StandardContext、StandardWrapper各个容器存在父子关系，一个父容器包含多个子容器，并且一个子容器对应一个父容器。Engine是顶层父容器，它不存在父容器。默认情况下，StandardEngine只有一个子容器StandardHost，一个StandardContext对应一个webapp应用，而一个StandardWrapper对应一个webapp里面的一个 Servlet。
[参考](https://blog.csdn.net/Dwade_mia/article/details/79244157)
StandardEngine的startInternal调用到父类ContainerBase的startInternal方法。具体实现就是给一个线程池去跑所有child的启动任务。当前线程通过Future.get方法阻塞等待所有child初始化完毕。
一个child(StandardHost)就是一个webapp，可以添加多个，初始化的时候，有一个线程池，并发去初始化各个webapp
**server.xml**
```xml
<Host name="localhost"  appBase="webapps"
            unpackWARs="true" autoDeploy="true" startStopThreads="4">
  <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
         prefix="localhost_access_log" suffix=".txt"
         pattern="%h %l %u %t &quot;%r&quot; %s %b" />
</Host>
```

然后启动PipeLine（Pipeline是管道组件，用于封装了一组有序的Valve，便于Valve顺序地传递或者处理请求，就是处理请求的前后拦截器）。
Valve包括
- AccessLogValve(默认开启，用于记录请求日志)，
- RemoteAddrValve，可以做访问控制，比如限制IP黑白名单 
- RemoteIpValve，主要用于处理 X-Forwarded-For 请求头，用来识别通过HTTP代理或负载均衡方式连接到Web服务器的客户端最原始的IP地址的HTTP请求头字段

加载子容器的方法是在HostConfig(实现了LifecycleListener，在start中启动Context容器)处理的。
HostConfig.java
```java
    protected void deployApps() {

        File appBase = host.getAppBaseFile();
        File configBase = host.getConfigBaseFile();
        String[] filteredAppPaths = filterAppPaths(appBase.list());
        // Deploy XML descriptors from configBase
        deployDescriptors(configBase, configBase.list());
        // Deploy WARs
        deployWARs(appBase, filteredAppPaths);
        // Deploy expanded folders
        deployDirectories(appBase, filteredAppPaths);
    }
```
deployWARs也是丢(submit)N个任务到线程池中，然后调用future.get使得当前线程阻塞直到拿到结果。这个任务其实就是解压war文件(war就是zip文件改了个后缀),这个任务包括，调用java处理压缩文件的API(JarEntry)去获取文件内容，还有一些其他的
deployDirectories方法的注释是（Deploy exploded webapps.），就是说解压完成之后做的事情。这里面又是executor.submit，然后future.get那一套东西(tomcat里似乎很多用这种方式等待多个任务完成)。
deployWars和deployDirectories中都出现了

> context = (Context) digester.parse(xml); //所以Context是对xml文件的描述？


tbd

## tomcat类加载器(重点)



[apache支持zero-copy](https://httpd.apache.org/docs/2.4/mod/core.html#enablesendfile)

## 参考
[tomcat源码解析](https://blog.csdn.net/Dwade_mia/column/info/18882)
