---
title: nagel-algorithm-and-delay-ack
date: 2018-11-06 13:25:55
tags:
---

傳送 TCP 封包的時候， TCP header 占 20 bytes， IPv4 header 占 20 bytes，若傳送的資料太小， TCP/IPv4 headers 造成的 overhead (40bytes) 並不划算。想像傳送資料只有 1 byte，卻要另外傳 40 bytes header，這是很大的浪費。若網路上有大量小封包，會占去網路頻寬，可能會造成網路擁塞 。
![](https://www.haldir66.ga/static/imgs/nature-grass-wet-plants-high-resolution-wallpaper-573f2c6413708.jpg)

<!--more-->

tcpdump和wireshark实战


## 参考
[Nagle和Delayed ACK优化算法合用导致的死锁问题](http://taozj.net/201808/nagle-and-delayed-ack.html)
[Nagle’s Algorithm 和 Delayed ACK 以及 Minshall 的加強版](https://medium.com/fcamels-notes/nagles-algorithm-%E5%92%8C-delayed-ack-%E4%BB%A5%E5%8F%8A-minshall-%E7%9A%84%E5%8A%A0%E5%BC%B7%E7%89%88-8fadcb84d96f)