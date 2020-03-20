---
title: adb常用命令手册
date: 2016-12-10 21:14:14
tags:
 - android
 - adb
---

## ADB 常用命令手册

平时在android studio中用command的时候还有点不熟悉，找到一篇博客，记录下来，作为日常参考。希望后期能够有时间把Google IO上添加的一些命令加上来
<!--more-->

获取序列号：
 > adb get-serialno

查看连接计算机的设备：
 > adb devices

重启机器：

 > adb reboot

重启到bootloader，即刷机模式：

> adb reboot bootloader

重启到recovery，即恢复模式：

> adb reboot recovery

查看log：

 > adb logcat

终止adb服务进程：

> adb kill-server

重启adb服务进程：

> adb start-server

获取机器MAC地址：

> adb shell  cat /sys/class/net/wlan0/address

获取CPU序列号：

> adb shell cat /proc/cpuinfo

安装APK：

> adb install <apkfile> //比如：adb install baidu.apk

保留数据和缓存文件，重新安装apk：

> adb install -r <apkfile> //比如：adb install -r baidu.apk

安装apk到sd卡：

> adb install -s <apkfile> // 比如：adb install -s baidu.apk

卸载APK：

> adb uninstall <package> //比如：adb uninstall com.baidu.search

卸载app但保留数据和缓存文件：

> adb uninstall -k <package> //比如：adb uninstall -k com.baidu.search

启动应用：

> adb shell am start -n <package_name>/.<activity_class_name>

查看设备cpu和内存占用情况：

> adb shell top

查看占用内存前6的app：

> adb shell top -m 6

刷新一次内存信息，然后返回：

> adb shell top -n 1

查询各进程内存使用情况：

> adb shell procrank

杀死一个进程：

> adb shell kill [pid]

查看进程列表：

> adb shell ps

查看指定进程状态：

> adb shell ps -x [PID]

查看后台services信息：

> adb shell service list

查看当前内存占用：

> adb shell cat /proc/meminfo

查看IO内存分区：

> adb shell cat /proc/iomem

将system分区重新挂载为可读写分区：

> adb remount

从本地复制文件到设备：

> adb push <local> <remote>

从设备复制文件到本地：

> adb pull <remote>  <local>

列出目录下的文件和文件夹，等同于dos中的dir命令：

> adb shell ls

进入文件夹，等同于dos中的cd 命令：

> adb shell cd <folder>

重命名文件：

> adb shell rename path/oldfilename path/newfilename

删除system/avi.apk：

> adb shell rm /system/avi.apk

删除文件夹及其下面所有文件：

> adb shell rm -r <folder>

移动文件：

> adb shell mv path/file newpath/file

设置文件权限：

> adb shell chmod 777 /system/fonts/DroidSansFallback.ttf

新建文件夹：

> adb shell mkdir path/foldelname

查看文件内容：

> adb shell cat <file>

查看wifi密码：

```
adb shell cat /data/misc/wifi/*.conf
```
清除log缓存：

> adb logcat -c

查看bug报告：

> adb bugreport

获取设备名称：

> adb shell cat /system/build.prop

查看ADB帮助：

> adb help

跑monkey：

> adb shell monkey -v -p your.package.name 500

录制视频

> adb shell screenrecord /sdcard/demo.mp4  生成的Demo.mp4文件在根目录下面，默认录制时长180s
按下ctrl+c 停止录制
注意，最好在开发者选项里面，把显示触摸操作打开，这样视频中能显示用户点击操作位置


ADB无线调试
> $adb tcpip 5555
>$ adb connect <\device-ip-address>
> $ adb devices
done

ANR的日志放在/data/anr/traces.txt里面
./adb pull path_to_file location_to_save就能搞出来了


> $ adb shell ps | grep bbk ## 在一台步步高手机上
u0_a24    11843 730   1808812 61012 SyS_epoll_ 0000000000 S com.bbk.appstore
system    13140 730   1773144 51608 SyS_epoll_ 0000000000 S com.bbk.facewake
u0_a80    13464 730   1772072 46280 SyS_epoll_ 0000000000 S com.bbk.calendar

> $ adb shell cat /proc/11843/oom_adj
/system/bin/sh: cat: /proc/11843/oom_adj: Permission denied

[LowMemory Killer实现](http://www.jcodecraeer.com/a/anzhuokaifa/androidkaifa/2013/0724/1482.html)
搜索关键字(oom_adj)


adb su进terminal
找一台root了的手机
adb shell 
su
//好了，现在可以进root模式了
pm list packages
pm clear PACKAGE //删掉/data/data/package里面的东西
//启用/禁用app或者组件,需要su执行
pm enable [--user USER_ID] PACKAGE_OR_COMPONENT
pm disable [--user USER_ID] PACKAGE_OR_COMPONENT
pm reset //重置所有应用的权限

这里面就有很多可以做的了

am stack list
am start -n com.huxiu/com.huxiu.ui.activity.SplashActivity //命令行启动某应用
am start -n com.android.browser/com.android.browser.BrowserActivity //命令行开浏览器


adb devices -l查看设备信息；
通过adb shell getprop | grep product查看设备信息：
更详细的信息可以使用adb shell getprop查看全部信息。

导入和导出文件
导入：adb push xxx/xxx /sdcard/xxx
导出：adb pull /sdcard/xxx /xxx/xxx

获取当前运行的Activity
adb shell dumpsys activity | grep "Run #"

查看cpu
低版本Android(Android N及之前)：adb shell top -n 1 | sed -n '4,17p'
高版本ANdroid(Android O及之后)：adb shell top -n 1 | sed -n '5,15p'

查看内存信息
adb shell dumpsys meminfo com.package

查看某个应用的耗电状况
从android 5.0开始，可以通过adb shell dumpsys batterystats com.package获取电量的相关信息。

清除应用的数据和缓存
adb shell pm clear com.package

模拟input事件
adb shell input keyevent key_code
例如：
adb shell input keyevnet 3 # 点击home键操作

adb shell input keyevent 4 # 点击返回键操作

adb shell input keyevent 8 # for key '1'

adb shell input keyevent 29 # for key 'A'

adb shell input text “hello” # 发送文本“hello”

## react native shake emulator , will start debug menu
adb shell input keyevent 82

查看系统版本：adb shell getprop ro.build.version.release

查看系统api版本：adb shell getprop ro.build.version.sdk

查看手机IP地址：adb shell ifconfig | grep 'inet addr:' | sed -n '2p' | awk '{print $2}' | cut -d ':' -f 2


### 参考:
- [张明云的博客](http://zmywly8866.github.io/2015/01/24/all-adb-command.html)
- [adb无线调试](http://blog.csdn.net/ykttt1/article/details/52058717)
