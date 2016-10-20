---
title: 一些脏代码
date: 2016-10-20 21:35:10
tags:
---

今天在V2EX上看到有人提到Notoification有漏洞，好奇也就查了一下，结果发现有人专门针对这个问题进行了[分析](http://zhoujianghua.com/2015/07/28/black_technology_in_alipay/)。本身的技术分析并不多，写在这里只是为了作为今后的一个参考。

### 1. 问题的由来
Android对后台应用是有一个权重区分的，最直观的就是查看最近使用的应用，这里每一个应用可能有一个或者多个Process，而系统在资源紧张时会干掉一些Process，而决定后台应用生死的是一个Lru List，也就是least recently used 会被干掉。显然大家都不希望自己被干掉，DAU对于很多应用来说是优先于系统资源和用户体验的。
根据[官方文档](https://developer.android.com/guide/components/processes-and-threads.html),Android Process有五种，根据优先级从高到低为:
- 前台进程
- 可见进程
- 服务进程
- 后台进程
- 空进程

越靠前的进程就越不容易被系统干掉，所以大家都希望能够成为前台进程。成为前台进程的条件:
```
用户当前操作所必需的进程。如果一个进程满足以下任一条件，即视为前台进程：
托管用户正在交互的 Activity（已调用 Activity 的 onResume() 方法）
托管某个 Service，后者绑定到用户正在交互的 Activity
托管正在“前台”运行的 Service（服务已调用 startForeground()）
托管正执行一个生命周期回调的 Service（onCreate()、onStart() 或 onDestroy()）
托管正执行其 onReceive() 方法的 BroadcastReceiver
通常，在任意给定时间前台进程都为数不多。只有在内在不足以支持它们同时继续运行这一万不得已的情况下，系统才会终止它们。 此时，设备往往已达到内存分页状态，因此需要终止一些前台进程来确保用户界面正常响应。
```
以上条件只有startForeGround满足条件了，但大家都知道startForeGround会在通知栏常驻一个Notification，且用户取消不了。对于我这种强迫症来说实在是太丑。


### 2. startForeGround一定会在系统状态栏，真的吗?
```java
void startForeground (int id, 
                Notification notification)
```
我找到了G+上的Chris Banes的一篇[post](https://plus.google.com/+AndroidDevelopers/posts/NEPWzPwSruR)，这其中明确指出
```
Unfortunately there are a number of applications on Google Play which are using the startForeground() API without passing a valid notification. While this worked in previous versions of Android, it is a loophole which has been fixed in Android 4.3. The system now displays a notifications for you automatically if you do not provide a valid one.
```
也就是说，API 18以前，只需要提供一个无效的Notification就可以让Notification不显示了。所以，判断下API<18的时候，直接new Notification()就可以得到一个不完整的Notification.
文章也指出了这是一个Loophole（已经是个贬义词了）。
Api 18之后的修复措施，看[ServiceRecord的源码](https://android.googlesource.com/platform/frameworks/base.git/+/android-4.3_r2.1/services/java/com/android/server/am/ServiceRecord.java):
```java
public void postNotification() {
        final int appUid = appInfo.uid;
        final int appPid = app.pid;
        if (foregroundId != 0 && foregroundNoti != null) {
            // Do asynchronous communication with notification manager to
            // avoid deadlocks.
            final String localPackageName = packageName;
            final int localForegroundId = foregroundId;
            final Notification localForegroundNoti = foregroundNoti;
            ams.mHandler.post(new Runnable() {
                public void run() {
                    NotificationManagerService nm =
                            (NotificationManagerService) NotificationManager.getService();
                    if (nm == null) {
                        return;
                    }
                    try {
                        if (localForegroundNoti.icon == 0) {
                            // It is not correct for the caller to supply a notification
                            // icon, but this used to be able to slip through, so for
                            // those dirty apps give it the app's icon.
                            localForegroundNoti.icon = appInfo.icon;
                            // Do not allow apps to present a sneaky invisible content view either.
                            localForegroundNoti.contentView = null;
                            localForegroundNoti.bigContentView = null;
                            CharSequence appName = appInfo.loadLabel(
                                    ams.mContext.getPackageManager());
                            if (appName == null) {
                                appName = appInfo.packageName;
                            }
                            Context ctx = null;
                            try {
                                ctx = ams.mContext.createPackageContext(
                                        appInfo.packageName, 0);
                                Intent runningIntent = new Intent(
                                        Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
                                runningIntent.setData(Uri.fromParts("package",
                                        appInfo.packageName, null));
                                PendingIntent pi = PendingIntent.getActivity(ams.mContext, 0,
                                        runningIntent, PendingIntent.FLAG_UPDATE_CURRENT);
                                localForegroundNoti.setLatestEventInfo(ctx,
                                        ams.mContext.getString(
                                                com.android.internal.R.string
                                                        .app_running_notification_title,
                                                appName),
                                        ams.mContext.getString(
                                                com.android.internal.R.string
                                                        .app_running_notification_text,
                                                appName),
                                        pi);
                            } catch (PackageManager.NameNotFoundException e) {
                                localForegroundNoti.icon = 0;
                            }
                        }
                        if (localForegroundNoti.icon == 0) {
                            // Notifications whose icon is 0 are defined to not show
                            // a notification, silently ignoring it.  We don't want to
                            // just ignore it, we want to prevent the service from
                            // being foreground.
                            throw new RuntimeException("icon must be non-zero");
                        }
                        int[] outId = new int[1];
                        nm.enqueueNotificationInternal(localPackageName, localPackageName,
                                appUid, appPid, null, localForegroundId, localForegroundNoti,
                                outId, userId);
                    } catch (RuntimeException e) {
                        Slog.w(ActivityManagerService.TAG,
                                "Error showing notification for service", e);
                        // If it gave us a garbage notification, it doesn't
                        // get to be foreground.
                        ams.setServiceForeground(name, ServiceRecord.this,
                                0, null, true);
                        ams.crashApplication(appUid, appPid, localPackageName,
                                "Bad notification for startForeground: " + e);
                    }
                }
            });
        }
    }

```
单单是看注释大概能看出来Android团队对于这种做法的不满。所以如果不提供有效Notification，则显示你的App的Icon。所以Api 18以上一定会显示一个Notification。

然而套路还是太深。。。。又有人给出了API 18以上的解决办法:

我在[这里](http://blog.csdn.net/wxx614817/article/details/50669420)找到了新的方法，简单来说就是起两个Service，两个Service都在一个进程里。
先Start A Service ，onCreate里面 bind B Service，
在onServiceConnected的时候A service startForeground(processId,notification)
B service startForeground(processId,notification)
随后立即调用B service stopForeGround(true)
由于两个Notification具有相同的id，所以A service最终成为Foreground Service，Notification也被清除掉了。


### 3.综述
整个过程看下来，API 18以下，给一个不完整的Notification(比如new Notification())，就不会出现在通知栏；API 18以上，起两个Service，B Service负责取消Notification就可以了。
目前看来，国内很多App为了保活，都采取了类似的方式。
而整体技术层面的实现并不难，只是利用了一个又一个小漏洞罢了。所以，从开发者的角度来说，这种应用与系统的博弈并不是什么好事。
![](http://odzl05jxx.bkt.clouddn.com/blamingtheuser-big.png?imageView2/2/w/600)


### Reference
- [支付宝后台不死的黑科技](http://zhoujianghua.com/2015/07/28/black_technology_in_alipay/)
- [Android的startForeground前台Service如何去掉通知显示](http://blog.csdn.net/wxx614817/article/details/50669420)


