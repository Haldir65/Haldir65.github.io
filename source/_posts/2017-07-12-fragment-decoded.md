---
title: Fragment源码解析记录(supportLibrary 25.3.0)
date: 2017-07-12 08:37:23
tags: [android]
---

We been told Fragment itself should only trust official docs, the implementation detail are prone to any change any time, don't count on it!
![](http://odzl05jxx.bkt.clouddn.com/2009528111321773591934.jpg?imageView2/2/w/600)
<!--more-->

Fragment源码解析（support Library 25.3.0），不要以为看了源码就可以不鸟官方文档了，源码的内容经常变，只有官方的文档才是可靠的，谷歌保证会实现的效果。

## 1. 概述
Fragment的核心类有这几个:

> FragmentManager, FragmentTransaction, Fragment。而事实上前两个都是抽象类，
>FragmentManager的实现类是FragmentManagerImpl，FragmentTransaction的实现类是BackStackRecord

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


       // FragmentManagerImpl
      /**这里就是被推送到主线程的runnable，注意，这里是异步的
     * Only call from main thread!
     */
    public boolean execPendingActions() {
        ensureExecReady(true);

        boolean didSomething = false;
        //这里就是不断的从mPendingAction中查找待执行的操作
        while (generateOpsForPendingActions(mTmpRecords, mTmpIsPop)) {
            mExecutingActions = true;
            try {
                optimizeAndExecuteOps(mTmpRecords, mTmpIsPop); //从方法名大致能猜到这里是执行操作的地方,两个参数，第一个是待执行的操作的List，一个是对应每项操作是pop还push(出栈还是入栈)
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
        for (int opNum = mOps.size() - 1; opNum >= 0; opNum--) { //倒序执行,每一个ops包含了对一个Fragment的指令，遍历所有的ops
            final Op op = mOps.get(opNum);
            Fragment f = op.fragment;
            f.setNextTransition(FragmentManagerImpl.reverseTransit(mTransition), mTransitionStyle);
            switch (op.cmd) {
                //这些操作全部只是设置一些变量的值，暂时还没到UI更改，具体的UI操作在moveToState里面
                case OP_ADD:
                    f.setNextAnim(op.popExitAnim);
                    mManager.removeFragment(f);  //从FragmentManager的mAdded中移除该fragment，fragment的mAdded = false,mRemoving = true;
                    break;
                case OP_REMOVE:
                    f.setNextAnim(op.popEnterAnim);
                    mManager.addFragment(f, false);
                    /** addFragment里面有这么一段  
       if (mAdded.contains(fragment)) {
                throw new IllegalStateException("Fragment already added: " + fragment); //就是简单的判断下List中是否存在，如果在一个Fragment已经added的情况下再去add，就会出现这种错误
            }**/
                    break;
                case OP_HIDE:
                    f.setNextAnim(op.popEnterAnim);
                    mManager.showFragment(f);
                    // 只是将fragment的mHidden设置为false了
                    break;
                case OP_SHOW:
                    f.setNextAnim(op.popExitAnim);
                    mManager.hideFragment(f);
                    // 只是将fragment的mHidden设置为true了
                    break;
                case OP_DETACH:
                    f.setNextAnim(op.popEnterAnim);
                    mManager.attachFragment(f);
                    //和attach差不多，也是设定了一些标志位
                    break;
                case OP_ATTACH:
                    f.setNextAnim(op.popExitAnim);
                    mManager.detachFragment(f);
                    // mFragment.mDetached = false,这里判断了manager.mAdded.contains(mFragment)，会抛出异常Fragment already added!如果正常的话把mFragment添加到mAdded里面
                    break;
                default:
                    throw new IllegalArgumentException("Unknown cmd: " + op.cmd);
            }
           if (!mAllowOptimization && op.cmd != OP_ADD) {
                mManager.moveFragmentToExpectedState(f);
            }
        }
         if (!mAllowOptimization) {
            // Added fragments are added at the end to comply with prior behavior.
            mManager.moveToState(mManager.mCurState, true);
        }
    }        

```
通常我们都是在主线程往Manager添加Transaction，不过从这里看来，添加Transaction只是添加了一份BackStackRecord，最终执行还是在主线程上做的。
很直观的看到这里 调用了manager的removeFragment、showFragment等方法.随便挑两个
```java
// FragmentManagerImpl.java
 public void addFragment(Fragment fragment, boolean moveToStateNow) {
        if (mAdded == null) {
            mAdded = new ArrayList<Fragment>();
        }
        makeActive(fragment);
        if (!fragment.mDetached) {
            if (mAdded.contains(fragment)) {
                throw new IllegalStateException("Fragment already added: " + fragment);
            }
            mAdded.add(fragment);
            fragment.mAdded = true; // 记得fragment.isAdded()方法吗，在这里被设置的
            fragment.mRemoving = false;
            if (fragment.mView == null) {
                fragment.mHiddenChanged = false;
            }
            if (fragment.mHasMenu && fragment.mMenuVisible) {
                mNeedMenuInvalidate = true;
            }
            if (moveToStateNow) {
                moveToState(fragment);
            }
        }
    }

        // show的方法异常简单
       /**
     * Marks a fragment as shown to be later animated in with
     * {@link #completeShowHideFragment(Fragment)}.
     *
     * @param fragment The fragment to be shown.
     */
    public void showFragment(Fragment fragment) {
        if (fragment.mHidden) {
            fragment.mHidden = false; //这里只是设置一下标志位
            // Toggle hidden changed so that if a fragment goes through show/hide/show
            // it doesn't go through the animation.
            fragment.mHiddenChanged = !fragment.mHiddenChanged;
        }
    }

```

接下里就是FragmentManager的MoveToState方法了，非常长
先记住Fragment的几个状态，这些都是Adam powell说过的，这是线性的，moveToState方法也是这样走的，不会跳过中间某个state
>   static final int INITIALIZING = 0;     // Not yet created.
    static final int CREATED = 1;          // Created.
    static final int ACTIVITY_CREATED = 2; // The activity has finished its creation.
    static final int STOPPED = 3;          // Fully created, not started.
    static final int STARTED = 4;          // Created and started, not resumed.
    static final int RESUMED = 5;          // Created started and resumed.

moveToState的方法比较长，删掉一些不必要的，重点关注Fragment的那些生命周期回调是什么时候被调用的。建议看源码，我这里删除了很多还有一大坨。
```java
// FragmentImpl.java
    void moveToState(Fragment f, int newState, int transit, int transitionStyle,
            boolean keepActive) {
//Fragment的state将提高，例如从ACTIVITY_CREATED到ACTIVITYCREATED
        if (f.mState < newState) {
            switch (f.mState) {
                case Fragment.INITIALIZING://尚未初始化
                    if (f.mSavedFragmentState != null) {
                      //从SavedState中获取各个View的状态，尝试恢复View的状态
                    }
                    f.mHost = mHost; //从这一刻开始,getActivity，getContext，isAdded等和Activity相关的方法都有正确的返回

                    f.mCalled = false; //这个mCalled是为了避免子类忘记调用super方法的
                    f.onAttach(mHost.getContext()); // onAttach就是在这里调用的
                    if (f.mParentFragment == null) {
                        mHost.onAttachFragment(f);//mHost其实就是Activity
                    } else {
                        f.mParentFragment.onAttachFragment(f); //这个是ChildFragment的情况
                    }
                    dispatchOnFragmentAttached(f, mHost.getContext(), false);

                    if (!f.mRetaining) {
                        f.performCreate(f.mSavedFragmentState); //这里面调用了onCreate回调，同时STATE变成CREATED
                        dispatchOnFragmentCreated(f, f.mSavedFragmentState, false);
                    } else {
                        f.restoreChildFragmentState(f.mSavedFragmentState);
                        f.mState = Fragment.CREATED;
                    }
                    f.mRetaining = false;
                    if (f.mFromLayout) {//写在XML里面的，直接在从INITIALIZING到CREATED的过程中把performCreateView和onViewCreated走一遍
                    }
                case Fragment.CREATED:
                    if (newState > Fragment.CREATED) {
                        if (!f.mFromLayout) { //不是写在xml标签中的Fragment
                            ViewGroup container = null;
                            if (f.mContainerId != 0) {
                                container = (ViewGroup) mContainer.onFindViewById(f.mContainerId);
                            }
                            f.mContainer = container;
                            f.mView = f.performCreateView(f.getLayoutInflater(
                                    f.mSavedFragmentState), container, f.mSavedFragmentState);// onCreateView回调
                            if (f.mView != null) {
                                f.mInnerView = f.mView;
                                if (container != null) {
                                    container.addView(f.mView);//所以Fragment本质上只是addView到Container里
                                }
                                if (f.mHidden) { //hide就只是设置Visibility这么简单，这mHdidden是在上面的showFragment里面设置的
                                    f.mView.setVisibility(View.GONE);
                                }
                                f.onViewCreated(f.mView, f.mSavedFragmentState);// 又是回调,onViewCreated确实是在onCreatedView之后立马添加的
                                dispatchOnFragmentViewCreated(f, f.mView, f.mSavedFragmentState,
                                        false);
                                // Only animate the view if it is visible. This is done after
                                // dispatchOnFragmentViewCreated in case visibility is changed
                                f.mIsNewlyAdded = (f.mView.getVisibility() == View.VISIBLE)
                                        && f.mContainer != null;
                            } else {
                                f.mInnerView = null;
                            }
                        }
                        //随后马上就调用到了onActivityCreated了，同一个Message中
                        f.performActivityCreated(f.mSavedFragmentState);
                        dispatchOnFragmentActivityCreated(f, f.mSavedFragmentState, false);
                        if (f.mView != null) {
                            f.restoreViewState(f.mSavedFragmentState);
                        }
                        f.mSavedFragmentState = null;
                    }
                case Fragment.ACTIVITY_CREATED:
                    if (newState > Fragment.ACTIVITY_CREATED) {
                        f.mState = Fragment.STOPPED;
                    }
                case Fragment.STOPPED:
                    if (newState > Fragment.STOPPED) {
                        if (DEBUG) Log.v(TAG, "moveto STARTED: " + f);
                        f.performStart(); //随后开始onStart
                        dispatchOnFragmentStarted(f, false);
                    }
                case Fragment.STARTED:
                    if (newState > Fragment.STARTED) {
                        if (DEBUG) Log.v(TAG, "moveto RESUMED: " + f);
                        f.performResume(); //onResume
                        dispatchOnFragmentResumed(f, false);
                        f.mSavedFragmentState = null;
                        f.mSavedViewState = null;
                    }
            }
        } else if (f.mState > newState) { //Fragment的STATE降低
            switch (f.mState) {
                case Fragment.RESUMED:
                    if (newState < Fragment.RESUMED) {
                        f.performPause(); //onPause
                        dispatchOnFragmentPaused(f, false);
                    }
                case Fragment.STARTED:
                    if (newState < Fragment.STARTED) {
                        f.performStop();//调用onStop,state变成STOPPED
                        dispatchOnFragmentStopped(f, false);
                    }
                case Fragment.STOPPED:
                    if (newState < Fragment.STOPPED) {
                        f.performReallyStop();//不调用回调，状态变成ACTIVITY_CREATED
                    }
                case Fragment.ACTIVITY_CREATED:
                    if (newState < Fragment.ACTIVITY_CREATED) {
                        f.performDestroyView(); //状态变成CREATED，调用onDestoryView。最后收尾调用                            f.mContainer.removeView(f.mView);//引用置空
                        dispatchOnFragmentViewDestroyed(f, false);
                        if (f.mView != null && f.mContainer != null) {
                            f.mContainer.removeView(f.mView);
                        }
                        f.mContainer = null;
                        f.mView = null;
                        f.mInnerView = null;
                    }
                case Fragment.CREATED:
                    if (newState < Fragment.CREATED) {
                            if (DEBUG) Log.v(TAG, "movefrom CREATED: " + f);
                            if (!f.mRetaining) {
                                f.performDestroy();
                                dispatchOnFragmentDestroyed(f, false);
                            } else {
                                f.mState = Fragment.INITIALIZING;
                            }

                            f.performDetach();
                            dispatchOnFragmentDetached(f, false);
                            if (!keepActive) {
                                if (!f.mRetaining) {
                                    makeInactive(f);
                                } else {
                                    f.mHost = null; //Fragment可以在Activity挂了之后接着存在，这里只是避免内存泄漏，那个方法叫做setRetainState好像
                                    f.mParentFragment = null;
                                    f.mFragmentManager = null;
                                }
                            }

                    }
            }
        }
    }

```
moveToState的方法很长，基本上可以分为state升高和state降低来看：
1. state升高的过程中：
  -  onAttach是第一个回调，这里面给Fragment的mHost赋值；(响应Fragment.CREATED信号)
  -  onCreateView,onViewCreated是在一个方法里进行的，本质上调用的是mContainer.addView方法。随后立即调用onActivityCreated方法(响应Fragment.ACTIVITY_CREATED方法)
  - onStart是第三个回调，onStart文档明确表示该方法调用时Fragment已经对用户可见。文档同时说明该方法和Activity的onStart方法挂钩，原理是FragmentActivity的onStart中调用了mFragments.dispatchStart()方法。
2. Fragment和Activity生命周期挂钩
  - FragmentActivity的onCreate中调用了FragmentManager的dispatchCreate方法，发出Fragment.CREATED信号
  - FragmentActivity的onStart中先调用了dispatchActivityCreated方法（发出ACTIVITY_CREATED信号），随后调用dispatchStart（发出Fragment.STARTED信号）
  - FragmentActivity的onResume中用Handler发送了一个Message，对应mFragments.dispatchResume(Fragment.RESUMED信号);FragmentActivity的onPostResume中也调用了dispatchResume方法，不过moveToState方法最后已经判断了newState> currentState。
  - onPause和onStop和onDestoryView也差不多。注意，DestoryView实质只是将Fragment的mView从container中移除，设置mView为null，mContainer为null;onDestory先于onDetach调用
3. FragmentActivity中的dispatchActivityCreated和dispatchFragmentStarted写在一个方法里，区别是onActivityCreated先于onStart调用且只会被调用一次。所以onActivityCreated存在的意义不过是为了帮助区分是初次start还是后面多次的start（Activity的onStart会被多次调用）
4. state降低的过程其实也差不多，我也懒得分析了。之前以为detach和attch方法很特殊，其实只是从FragmentManager的mAdded中移除该Fragment，并设置fragment.mAdded = false.
5. 从一个state到另一个state基本的步骤就是fragment.performXXX，然后dispatchXXX，这里面顺手把state设置一下


FragmentManager的核心方法应该就是这个moveToState方法了。到此，commit分析结束。说一下几个不建议使用的方法
**executePendingTransactions** 看了下，这个方法里面没有异步方法，别的就不清楚了。据说是将所有的Transaction全部执行掉，首先这里面有一大堆操作，会堵住主线程，其次，这个方法里面涉及到各个状态的判断，很混乱。

**commitAllowingStateLoss** 这个方法和commit的唯一区别是调用一个可能会抛出异常的方法，后面还是post了一个pendingAction,还是异步的。所以很多人纷纷调用commitAllowingStateLoss方法。然而，这个方法存在是有其意义的。安卓本身就是个异步的系统。Activity的onSaveInstanceState随时可能会被调用，调用之后所有有id的View的onSaveInstanceState都被调用了。这个时候再去尝试做任何操作都可能会重新对已经保存了状态的View造成影响。Activity重新恢复的时候会把saveState中的的UI快照恢复，这一次的操作就会造成恢复的时候不是保存时的效果.allowStateLoss的字面意思很清楚了，就是系统不保证此后View的状态能够正确被恢复。

```java
private void checkStateLoss() {
       if (mStateSaved) {
           throw new IllegalStateException(
                   "Can not perform this action after onSaveInstanceState");
       }
       if (mNoTransactionsBecause != null) {
           throw new IllegalStateException(
                   "Can not perform this action inside of " + mNoTransactionsBecause);
       }
   }
```

**commitNow** 注意24.2 之后Google添加了一个单独的commitNow方法，这一点Adam Powell在2016年的IO上特别提到过。
内部执行了mTmpRecords(临时操作)，由于只是一项操作，外加里面还对这一次操作进行了优化，所以直接同步执行了。该方法不允许addToBackStack，因为这实质上等同于在所有pendingAction中插队。由于是同步执行，该方法保证方法返回之后，所有的Fragment都能处于所预期的state。

```java
 @Override
    public void commitNow() {
        disallowAddToBackStack();
        mManager.execSingleAction(this, false);
    }

  @Override
  public void commitNowAllowingStateLoss() {
      disallowAddToBackStack();
      mManager.execSingleAction(this, true);
  }
```

**commitNowAllowingStateLoss** 和commitAllowingStateLoss一样的道理，开发者可能不经意在Activity保存了状态之后调用该方法，这违背了状态保存和恢复的原则。但还是开了个后门，前提是不保证UI恢复的时候出现非预期的表现。allowStateLoss的方法照说不应该调用，如果不调用这个方法的话，使用commitNow，而不是commit + executePendingTransactions。 同时，commitNow之前检查下mStateSaved是否是true,具体来说Activity的onStop和onSaveInstanceState调用之后这个值都会为true。

关于Activity的onSaveInstanceState什么时候会调用，找到比较好的[解释](http://www.cnblogs.com/heiguy/archive/2010/10/30/1865239.html)。 记住，旋转屏幕的时候一定会调用的。



## 4. 现在再来看FragmentPagerAdapter和FragmentStatePagerAdapter
这两个类行数都不超过300行，非常简单，只是通过调用FragmentManager的相应方法实现展示View的功能。

## 5. Fragment的一些不常用的API
attach,detach,FragmentLifecycleCallbacks,commitNow，setAllowOptimization(26.0.0又被deprecated了)
onCreateView这个名字是怎么来的，其实是在dispatchFragmentsOnCreateView里面调用的。Activity实现了onCreateView(LayoutInflater定义的，会在getSytemService返回LayoutInflater时调用，获取系统服务毕竟是一个异步过程)。


## 6. 关于Glide是如何实现生命周期绑定的
Fragment本身提供了生命周期监听回调
```java
registerFragmentLifecycleCallbacks 25.1.0
unregisterFragmentLifecycleCallbacks 25.1.0

addOnBackStackChangedListener 22.2.0
removeOnBackStackChangedListener 22.2.0
```
Glide的做法是写了一个**SupportRequestManagerFragment** 在这个Fragment的构造函数里放了一个ActivityFragmentLifecycle
 [参考](http://blog.leanote.com/post/qq-tank/Glide%E4%B8%AD)
 在这个Fragment的onStart，OnStop等方法里面调用该lifeCycle的onStart,onStop等回调(lifeCycle是接口，由RequestManager实现)
 关键代码
 ```java
 if (current == null) {
                current = new RequestManagerFragment();
                pendingRequestManagerFragments.put(fm, current);
                fm.beginTransaction().add(current, FRAGMENT_TAG).commitAllowingStateLoss();
                handler.obtainMessage(ID_REMOVE_FRAGMENT_MANAGER, fm).sendToTarget();
            }
 ```
 所以经常会在Debug的时候看到FragmentManager里面有个"com.bumptech.glide.manager"的Fragment。这个Fragment没有实现onCreateView，所以直接返回null。Fragment本身是可以不带View的。



## 7. 总结
Fragment的一些生命周期还是需要跟Activity的生命周期一起看，大部分是异步操作。FragmentManager类似一个管理者，也是一个容器，在Activity的生命周期中顺手实现了容器中元素所要求的UI状态。Fragment本质上是一个View的Controllers，通过FragmentManger和FragmentActivity的生命周期挂钩，并自动做好View的状态保存和恢复。具体的UI展示无非是addView，setVisibility等常规的方法，也正因为这样，support包里的Fragment才能做到3.0以下的适配。日常开发中，Fragment能够将原本堆在Activity中的逻辑承载过来,以异步的方式减轻主线程的压力，对外提供了获取(onViewCreated)，操作(Transaction)，销毁(onDestoryView)这些业务对象的回调方法。由于Android本身就是异步的系统，系统随时(asynchronous)可能会对Fragment的资源进行更改，开发者的代码也随时(asynchronous)会对这些资源进行操作。由于存在这种无法改变的'并发'现状，Fragment不得不为保证资源的一致性而主动抛出一些错误。本文有意忽略掉了一些transition动画(使用了hardwareLayer)和Loader加载的细节，希望能够对日常开发有点帮助。


## 更新，拿来主义
1. [一份2013年的文档](http://www.androiddesignpatterns.com/2013/08/fragment-transaction-commit-state-loss.html),不要在FragmentActivity#onResume中beginTransaction，需要的话，在onPostResume或者onPostResume中做。也不要在onActivityResult里面去做，onActivityResult会触发onPostResume，推迟到onPostResume去做。

## Reference
1. [Fragment的onAttach和onDetach什么时候会调用](http://stackoverflow.com/questions/9156406/whats-the-difference-between-detaching-a-fragment-and-removing-it)
2. [Glide是怎么跟生命周期挂钩的](http://blog.leanote.com/post/qq-tank/Glide%E4%B8%AD)
3. [Activity的onSaveInstanceState什么时候会调用](http://www.cnblogs.com/heiguy/archive/2010/10/30/1865239.html)
4. [Activity-LifeCycle](https://developer.android.com/guide/components/activities/activity-lifecycle.html)
5. [Fragments文档](https://developer.android.com/guide/components/fragments.html)不要依赖Implementation Detail,源码随时会变，官方的文档才是值得依赖的。
