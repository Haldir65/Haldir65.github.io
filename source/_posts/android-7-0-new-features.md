---
title: android 7.0一些新特性介绍及适配方案
date: 2016-10-08 03:02:26
tags: android 7
---

Google I/O 2016上的[What's new in Android](https://www.youtube.com/watch?v=B08iLAtS3AQ)介绍的比较全面，MultiWindow、Notification、ConstraintLayout等都比较简单。这里拎出来开发者不得不注意的几点来介绍。
<!--more-->

### 1. BackGround Optimization

~~CONNECTIVITY_CHANGE~~(很多应用喜欢在Manifest里注册这个BroadcastReceiver，导致网络变化时，一大堆应用都被唤醒，而ram中无法同时存在这么多process，系统不得不kill old process，由此导致memory thrashing)

同时被移除的还有~~NEW_PICTURE~~,~~NEW_VIDEO~~.

具体来说: 对于**targeting N**的应用，在manifest文件中声明 static broadcastReceiver，监听~~CONNECTIVITY_CHANGE~~将不会唤醒应用。如果应用正在运行，使用context.registerReceiver，将仍能够接受到broadcast。但不会被唤醒。

解决方案: 使用JobScheduler或firebase jobDispatcher。
举个例子:
```java
  public static final int MY_BACKGROUND_JOB = 0;
    public static void scheduleJob(Context context){
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            JobScheduler js =
                    (JobScheduler) context.getSystemService(Context.JOB_SCHEDULER_SERVICE);
            JobInfo job = new JobInfo.Builder(
                    MY_BACKGROUND_JOB,
                    new ComponentName(context,MyJobService.class)).
                    setRequiredNetworkType(JobInfo.NETWORK_TYPE_UNMETERED).
                    setRequiresCharging(true).
                    build();
            js.schedule(job);
        }
      
    }
```


对于~~NEW_PICTURE~~,~~NEW_VIDEO~~.

所有在7.0 Nuget以上设备运行的应用(无论是否 target N) 都不会收到这些broadcast。简单来说，fully deprecated  !!!

解决方案：使用JobScheduler(可以监听contentProvider change)
~~NEW_PICTURE~~的处理(这段代码只在API24以上存在，所以加了版本判断)
```java
    public static void scheduleJob(Context context){
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            JobScheduler js =
                    context.getSystemService(JobScheduler.class);
            JobInfo.Builder builder = new JobInfo.Builder(
                    R.id.schedule_photo_jobs,
                    new ComponentName(context,PhotoContentJob.class));

            builder.addTriggerContentUri(
                    new JobInfo.TriggerContentUri(MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                            JobInfo.TriggerContentUri.FLAG_NOTIFY_FOR_DESCENDANTS)
            );
            js.schedule(builder.build());
        }
    }
```
参考[youtube上谷歌员工的演讲](https://www.youtube.com/watch?v=3ZX0CfVfVP8)

### 2. 文件系统的权限更改(FileProvider)

 File storage permission change 
 简单来说就是Uri.fromFile(file://URI)不能再用了，需要使用FileProvider，这主要是为了6.0开始引进的permission model 考虑的，storage permission例如WRITE_EXTERNAL_STORAGE这种都已经属于Dangerous permission了。
 一个常见的场景就是调用系统相机拍照，给Intent设置一个uri，在7.0上直接用Uri.FromFile会崩
 需要通过FileProvider提供Uri,写了一个[Demo](https://github.com/Haldir65/FileProviderDmo)，使用FileProvider传递文件给另一个App。
 另一个需要注意的就是DownloadManager访问COLUMN_LOCAL_FILENAME会报错，这个不常见。





## Reference

1. [Docs](https://developer.android.com/topic/performance/background-optimization.html?utm_campaign=adp_series__100616&utm_source=anddev&utm_medium=yt-desc)
2. [youtube](https://www.youtube.com/watch?v=vBjTXKpaFj8)
3. [Andrioid 7.0适配心得](http://gold.xitu.io/entry/57ff7e14a0bb9f005860c805)
4. [Android 7.0 Behavior Changes](https://developer.android.com/about/versions/nougat/android-7.0-changes.html)