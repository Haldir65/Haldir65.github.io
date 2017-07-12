---
title: 2017-07-12-fragment-decoded
date: 2017-07-12 08:37:23
tags: [android]
---

We been told Fragment itself should only trust official docs, the implementation detail are prone to any change any time. 
![](http://odzl05jxx.bkt.clouddn.com/2009528111321773591934.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/Cg-4zFVJ0xGITwm_AA688WRj8n8AAXZ9wGMpd0ADr0J195.jpg?imageView2/2/w/600)
![](http://odzl05jxx.bkt.clouddn.com/u=3180342558,2746910171&fm=214&gp=0.jpg?imageView2/2/w/600)

<!--more-->

Fragment源码解析（support Library 25.3.0）

## 1. 概述
Fragment的核心类有这几个:

> FragmentManager, FragmentTransaction, Fragment。而事实上前两个都是抽象类，
>FragemntManager的实现类是FragmentManagerImpl，FragmentTransaction的实现类是BackStackRecord

从日常使用Fragment的方式开始:
```java
((FragmentActivity) mActivity).getSupportFragmentManager()
                    .beginTransaction().add(R.id.containerViewId,fragment).commit();
```



### 2.FragmentTransaction只是将动作添加到一个队列中了
beginTransaction获取了一个FragmentTransaction实例，来看add方法的实现:
```java
    @Override
    public FragmentTransaction add(Fragment fragment, String tag) {
        doAddOp(0, fragment, tag, OP_ADD);
        return this;
    }

    @Override
    public FragmentTransaction add(int containerViewId, Fragment fragment) {
        doAddOp(containerViewId, fragment, null, OP_ADD);
        return this;
    }

    @Override
    public FragmentTransaction add(int containerViewId, Fragment fragment, String tag) {
        doAddOp(containerViewId, fragment, tag, OP_ADD);
        return this;
    }
```

不管是通过id还是Tag添加，都是调用同一个方法，传参不同而已
```java
    private void doAddOp(int containerViewId, Fragment fragment, String tag, int opcmd) {
    //省略部分代码
        fragment.mFragmentManager = mManager;
        if (tag != null) {
            fragment.mTag = tag;
        }
        //注意，进入这个方法的时候fragment已经实例化了，只是其中的回调方法还没有开始调用
        if (containerViewId != 0) {
            fragment.mContainerId = fragment.mFragmentId = containerViewId;
        }

        Op op = new Op();
        op.cmd = opcmd; //这个cmd很重要，代表了是show、hide、add、remove等这些东西
        op.fragment = fragment;
        addOp(op);
    }

    //所有可能的操作细节都包含在这里面了。注意，这是线性的！
    static final int OP_NULL = 0;
    static final int OP_ADD = 1;
    static final int OP_REPLACE = 2;
    static final int OP_REMOVE = 3;
    static final int OP_HIDE = 4;
    static final int OP_SHOW = 5;
    static final int OP_DETACH = 6;
    static final int OP_ATTACH = 7;

    //这个OP包装了了每一次操作的具体细节。
    static final class Op {
        int cmd;
        Fragment fragment;
        int enterAnim;
        int exitAnim;
        int popEnterAnim;
        int popExitAnim;
    }

      void addOp(Op op) {
        mOps.add(op); //往一个普通的ArrayList中添加一个op
        op.enterAnim = mEnterAnim;
        op.exitAnim = mExitAnim;
        op.popEnterAnim = mPopEnterAnim;
        op.popExitAnim = mPopExitAnim;
    }

```


## 3.通过FragmentTransaction.commit执行操作
FragmentFransaction只是将所有操作保留到一次Transaction的一个任务队列(ArrayList)中了。真正的执行需要提交事务，这和数据库的事务很像。
```java
    @Override
    public int commit() {
        return commitInternal(false);
    }

    @Override
    public int commitAllowingStateLoss() {
        return commitInternal(true);
    }

//上面两个函数的返回值 Returns the identifier of this transaction's back stack entry, if addToBackStack(String)} had been called.  Otherwise, returns a negative number. 如果调用过addToBackStack的话，返回这次操作在操作栈上的标识符。否则返回负数。

 int commitInternal(boolean allowStateLoss) {
        if (mCommitted) throw new IllegalStateException("commit already called");
        if (FragmentManagerImpl.DEBUG) {
            Log.v(TAG, "Commit: " + this);
            LogWriter logw = new LogWriter(TAG);
            PrintWriter pw = new PrintWriter(logw);
            dump("  ", null, pw, null);
            pw.close();
        }
        mCommitted = true;
        if (mAddToBackStack) {//如果调用过addToBackStack，这个值就为true，否则为false
            mIndex = mManager.allocBackStackIndex(this);// 将BackStackRecord添加到一个ArrayList的尾部，List不存在则创建
        } else {
            mIndex = -1;
        }
        mManager.enqueueAction(this, allowStateLoss); // 这里就是调用FragmnetManager的方法，添加到FragmentManager的mPendingActions中，并scheduleCommit（通过FragmnetHostCallBack往主线程post一条runnable）
        return mIndex; //返回的就是本次事务的mIndex
    }


      /**这里就是被推送到主线程的runnable，注意，这里是异步的
     * Only call from main thread!
     */
    public boolean execPendingActions() {
        ensureExecReady(true);

        boolean didSomething = false;
        while (generateOpsForPendingActions(mTmpRecords, mTmpIsPop)) {
            mExecutingActions = true;
            try {
                optimizeAndExecuteOps(mTmpRecords, mTmpIsPop); //从方法名大致能猜到这里是执行操作的地方
            } finally {
                cleanupExec();
            }
            didSomething = true;
        }

        doPendingDeferredStart();

        return didSomething;
    }

 private void optimizeAndExecuteOps(ArrayList<BackStackRecord> records,
            ArrayList<Boolean> isRecordPop) {
    }
随后调用了executeOpsTogether方法，接着调用
        executeOps(records, isRecordPop, startIndex, endIndex);
最终又走到了BackStackRecord的方法里面
   /**
     * Reverses the execution of the operations within this transaction. The Fragment states will
     * only be modified if optimizations are not allowed.
     *
     * @param moveToState {@code true} if added fragments should be moved to their final state
     *                    in unoptimized transactions
     */
    void executePopOps(boolean moveToState) {
        for (int opNum = mOps.size() - 1; opNum >= 0; opNum--) {
            final Op op = mOps.get(opNum);
            Fragment f = op.fragment;
            f.setNextTransition(FragmentManagerImpl.reverseTransit(mTransition), mTransitionStyle);
            switch (op.cmd) {
                case OP_ADD:
                    f.setNextAnim(op.popExitAnim);
                    mManager.removeFragment(f);
                    break;
                case OP_REMOVE:
                    f.setNextAnim(op.popEnterAnim);
                    mManager.addFragment(f, false);
                    break;
                case OP_HIDE:
                    f.setNextAnim(op.popEnterAnim);
                    mManager.showFragment(f);
                    break;
                case OP_SHOW:
                    f.setNextAnim(op.popExitAnim);
                    mManager.hideFragment(f);
                    break;
                case OP_DETACH:
                    f.setNextAnim(op.popEnterAnim);
                    mManager.attachFragment(f);
                    break;
                case OP_ATTACH:
                    f.setNextAnim(op.popExitAnim);
                    mManager.detachFragment(f);
                    break;
                default:
                    throw new IllegalArgumentException("Unknown cmd: " + op.cmd);
            }
            if (!mAllowOptimization && op.cmd != OP_REMOVE) {
                mManager.moveFragmentToExpectedState(f);
            }
        }
        if (!mAllowOptimization && moveToState) {
            mManager.moveToState(mManager.mCurState, true);
        }
    }        

```


```java
注意24.2之后Google添加了一个单独的commitNow方法，这一点Adam Powell在2016年的IO上特别提到过。
 @Override
    public void commitNow() {
        disallowAddToBackStack();
        mManager.execSingleAction(this, false);
    }
```


## Reference
1. [Fragment的onAttach和onDetach什么时候会调用](http://stackoverflow.com/questions/9156406/whats-the-difference-between-detaching-a-fragment-and-removing-it) 