---
title: service和activity的通信方式
date: 2016-09-30 15:25:28
categories: blog
tags: [service,android]
---

![](https://api1.foster57.tk/static/imgs/service_lifecycle.png)

一年以前写过一篇关于service和Activity相互通信的很详细的博客，当时真的是费了很大心思在上面。现在回过头来看，还是有些不完善的地方，比如aidl没有给，demo不够全面。现在补上。

<!--more-->

## 1. 关于Android的Service，[官方文档](https://developer.android.com/guide/components/services.html)是这样描述的

> `Service` 是一个可以在后台执行长时间运行操作而不使用用户界面的应用组件。服务可由其他应用组件启动，而且即使用户切换到其他应用，服务仍将在后台继续运行。 此外，组件可以绑定到服务，以与之进行交互，甚至是执行进程间通信 (IPC)。 例如，服务可以处理网络事务、播放音乐，执行文件 I/O 或与内容提供程序交互，而所有这一切均可在后台进行。

这其中也能看出Android对于Service角色的定位，后台工作，不涉及UI。

Service本身包含started Service和Binded Service

对于Binded Service 使用

![](https://api1.foster57.tk/static/imgs/service_binding_tree_lifecycle.png)



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

## 客户端调用远程进程的流程： 
服务端跨进程的类都要继承Binder类。我们所持有的Binder引用(即服务端的类引用)并不是实际真实的远程Binder对象，我们的引用在Binder驱动里还要做一次映射。也就是说，设备驱动根据我们的引用对象找到对应的远程进程。客户端要调用远程对象函数时，只需把数据写入到Parcel，在调用所持有的Binder引用的transact()函数，transact函数执行过程中会把参数、标识符（标记远程对象及其函数）等数据放入到Client的共享内存，Binder驱动从Client的共享内存中读取数据，根据这些数据找到对应的远程进程的共享内存，把数据拷贝到远程进程的共享内存中，并通知远程进程执行onTransact()函数，这个函数也是属于Binder类。远程进程Binder对象执行完成后，将得到的写入自己的共享内存中，Binder驱动再将远程进程的共享内存数据拷贝到客户端的共享内存，并唤醒客户端线程。



## 参考
[Binder学习心得](https://blog.csdn.net/bjp000111/article/details/51919595)
