---
title: service和activity的通信方式
date: 2016-09-30 15:25:28
categories: blog
tags: [service,android]
---

![](http://www.haldir66.ga/static/imgs/service_lifecycle.png)

一年以前写过一篇关于service和Activity相互通信的很详细的博客，当时真的是费了很大心思在上面。现在回过头来看，还是有些不完善的地方，比如aidl没有给，demo不够全面。现在补上。

<!--more-->

## 1. 关于Android的Service，[官方文档](https://developer.android.com/guide/components/services.html)是这样描述的

> `Service` 是一个可以在后台执行长时间运行操作而不使用用户界面的应用组件。服务可由其他应用组件启动，而且即使用户切换到其他应用，服务仍将在后台继续运行。 此外，组件可以绑定到服务，以与之进行交互，甚至是执行进程间通信 (IPC)。 例如，服务可以处理网络事务、播放音乐，执行文件 I/O 或与内容提供程序交互，而所有这一切均可在后台进行。

这其中也能看出Android对于Service角色的定位，后台工作，不涉及UI。

Service本身包含started Service和Binded Service

对于Binded Service 使用

![](http://www.haldir66.ga/static/imgs/service_binding_tree_lifecycle.png)



## 2. AIDL写法
以下代码来自[简书](https://www.jianshu.com/p/ce1e35c84134)
```java
interface IMyAidlInterface {
    /**
     * Demonstrates some basic types that you can use as parameters
     * and return values in AIDL.
     */
    void basicTypes(int anInt, long aLong, boolean aBoolean, float aFloat,
            double aDouble, String aString);

    String getName(String nickName);
}


public class AIDLService extends Service {

    IMyAidlInterface.Stub mStub = new IMyAidlInterface.Stub() { //这个class是编译后生成的
        @Override
        public void basicTypes(int anInt, long aLong, boolean aBoolean, float aFloat, double aDouble, String aString) throws RemoteException {

        }

        @Override
        public String getName(String nickName) throws RemoteException {
            return "aidl " + nickName;
        }
    };

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return mStub;
    }
}

public class MainActivity extends AppCompatActivity {

    private Button mBtnAidl;
    private IMyAidlInterface mIMyAidlInterface;

    ServiceConnection mServiceConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            mIMyAidlInterface = IMyAidlInterface.Stub.asInterface(service); //在这里获得远程服务的proxy引用
        }

        @Override
        public void onServiceDisconnected(ComponentName name) {

        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        mBtnAidl = (Button) findViewById(R.id.btn_aidl);

        bindService(new Intent(MainActivity.this, AIDLService.class), mServiceConnection, BIND_AUTO_CREATE);

        mBtnAidl.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if(mIMyAidlInterface != null){
                    try {
                        String name = mIMyAidlInterface.getName("I'm nick");
                        Toast.makeText(MainActivity.this, "name = " + name, Toast.LENGTH_SHORT).show();
                    } catch (RemoteException e) {
                        e.printStackTrace();
                    }
                }
            }
        });
    }
}
```
需要注意的是，aidl不一定非得多进程才能用，同一进程之间的不同组件之间也能用aidl，而且，framework会判断如果是当前进程，直接返回在当前进程的引用。


### reference
[Android开发高级进阶——多进程间通信](https://www.jianshu.com/p/ce1e35c84134)
[csdn](http://blog.csdn.net/javazejian/article/details/52709857)
