---
title: "android内部类导致leak模板"
date: 2016-09-18 10:23:42
categories: blog
tags: [android]
---


----------

通常我们在一个class里面写内部类时，不是一定要用static声明为静态类，但是推荐作为内部静态类，因为内部类会隐式持有外部类的引用，有些时候如果代码处理不对容易造成内存泄漏
下面就是个内存泄漏的例子
<!--more-->
```java
public class MainActivity extends Activity {

	public class MyHandler extends Handler{
	@Override
	public void handleMessage(Message msg) {
		if(msg.what==1){
			new Thread(){
				@Override
				public void run() {
					while(true){
						//do something
					}
				}
			}.start();
		}
	}
	}
	public MyHandler handler;
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main);
		
		//...
		handler.sendEmptyMessage(1);
		finish();
	    }
}
```


如上面代码所示，在onCreate方法里发送了一条消息给handler处理然后finish方法关闭activity，但是代码并不能如愿，因为在handler收到消息启动了一个线程并且是**死循环**，
这时候Thread持有handler的引用，而handler又持有activity的引用，这就导致了handler不能回收和activty也不能回收，所以推荐使用静态内部类，因为静态内部类不持有外部类的引用，可以避免这些不必要的麻烦。

除此之外，在Activity里面创建一个AsyncTask的子类也容易导致leak
例如 [stackoverFlow上的这个问题](http://stackoverflow.com/questions/24679383/memory-leak-using-asynctask-as-a-inner-class)

对于这类问题的比较常用的方式:
WeakReference
例如,写这样一个的静态内部类
    
```java
private static class IncomingHandler extends Handler {
    private final WeakReference<MessagingService> mReference;

    IncomingHandler(MessagingService service) {
        mReference = new WeakReference<>(service);
    }

    @Override
    public void handleMessage(Message msg) {
        MessagingService service = mReference.get();
        switch (msg.what) {
            case MSG_SEND_NOTIFICATION:
                int howManyConversations = msg.arg1 <= 0 ? 1 : msg.arg1;
                int messagesPerConversation = msg.arg2 <= 0 ? 1 : msg.arg2;
                if (service != null) {
                    service.sendNotification(howManyConversations,
                    messagesPerConversation);
                }
                break;
            default:
                super.handleMessage(msg);
        }
    }
}
```    
//handler通过弱引用持有service对象，外加static内部类不持有外部类引用，应该不会leak了






