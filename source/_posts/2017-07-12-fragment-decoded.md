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
先记住Fragment的几个状态，这些都是Adam powell说过的，这是线性的
>     static final int INITIALIZING = 0;     // Not yet created.
    static final int CREATED = 1;          // Created.
    static final int ACTIVITY_CREATED = 2; // The activity has finished its creation.
    static final int STOPPED = 3;          // Fully created, not started.
    static final int STARTED = 4;          // Created and started, not resumed.
    static final int RESUMED = 5;          // Created started and resumed.


```java
// FragmentImpl.java
    void moveToState(Fragment f, int newState, int transit, int transitionStyle,
            boolean keepActive) {
        // Fragments that are not currently added will sit in the onCreate() state.
        if ((!f.mAdded || f.mDetached) && newState > Fragment.CREATED) {
            newState = Fragment.CREATED;
        }
        if (f.mRemoving && newState > f.mState) {
            // While removing a fragment, we can't change it to a higher state.
            newState = f.mState;
        }
        // Defer start if requested; don't allow it to move to STARTED or higher
        // if it's not already started.
        if (f.mDeferStart && f.mState < Fragment.STARTED && newState > Fragment.STOPPED) {
            newState = Fragment.STOPPED;
        }
        if (f.mState < newState) { //Fragment的state将提高，例如从ACTIVITY_CREATED到ACTIVITYCREATED
            // For fragments that are created from a layout, when restoring from
            // state we don't want to allow them to be created until they are
            // being reloaded from the layout.
            if (f.mFromLayout && !f.mInLayout) {
                return;
            }
            if (f.getAnimatingAway() != null) {
                // The fragment is currently being animated...  but!  Now we
                // want to move our state back up.  Give up on waiting for the
                // animation, move to whatever the final state should be once
                // the animation is done, and then we can proceed from there.
                f.setAnimatingAway(null);
                moveToState(f, f.getStateAfterAnimating(), 0, 0, true); //注意这里递归调用了
            }
            switch (f.mState) {
                case Fragment.INITIALIZING:
                    if (DEBUG) Log.v(TAG, "moveto CREATED: " + f);
                    if (f.mSavedFragmentState != null) {
                        f.mSavedFragmentState.setClassLoader(mHost.getContext().getClassLoader());
                        f.mSavedViewState = f.mSavedFragmentState.getSparseParcelableArray(
                                FragmentManagerImpl.VIEW_STATE_TAG);
                        f.mTarget = getFragment(f.mSavedFragmentState,
                                FragmentManagerImpl.TARGET_STATE_TAG);
                        if (f.mTarget != null) {
                            f.mTargetRequestCode = f.mSavedFragmentState.getInt(
                                    FragmentManagerImpl.TARGET_REQUEST_CODE_STATE_TAG, 0);
                        }
                        f.mUserVisibleHint = f.mSavedFragmentState.getBoolean(
                                FragmentManagerImpl.USER_VISIBLE_HINT_TAG, true);
                        if (!f.mUserVisibleHint) {
                            f.mDeferStart = true;
                            if (newState > Fragment.STOPPED) {
                                newState = Fragment.STOPPED;
                            }
                        }
                    }
                    f.mHost = mHost;
                    f.mParentFragment = mParent;
                    f.mFragmentManager = mParent != null
                            ? mParent.mChildFragmentManager : mHost.getFragmentManagerImpl();
                    dispatchOnFragmentPreAttached(f, mHost.getContext(), false);
                    f.mCalled = false;
                    f.onAttach(mHost.getContext());
                    if (!f.mCalled) {
                        throw new SuperNotCalledException("Fragment " + f
                                + " did not call through to super.onAttach()");
                    }
                    if (f.mParentFragment == null) {
                        mHost.onAttachFragment(f);//mHost其实就是Activity
                    } else {
                        f.mParentFragment.onAttachFragment(f); //这个是ChildFragment的情况
                    }
                    dispatchOnFragmentAttached(f, mHost.getContext(), false);

                    if (!f.mRetaining) {
                        f.performCreate(f.mSavedFragmentState); //onCreate回调
                        dispatchOnFragmentCreated(f, f.mSavedFragmentState, false);
                    } else {
                        f.restoreChildFragmentState(f.mSavedFragmentState);
                        f.mState = Fragment.CREATED;
                    }
                    f.mRetaining = false;
                    if (f.mFromLayout) {//写在XML里面的，直接在从INITIALIZING到CREATED的过程中把performCreateView和onViewCreated走一遍
                        // For fragments that are part of the content view
                        // layout, we need to instantiate the view immediately
                        // and the inflater will take care of adding it.
                        f.mView = f.performCreateView(f.getLayoutInflater(
                                f.mSavedFragmentState), null, f.mSavedFragmentState);
                        if (f.mView != null) {
                            f.mInnerView = f.mView;
                            if (Build.VERSION.SDK_INT >= 11) {
                                ViewCompat.setSaveFromParentEnabled(f.mView, false);
                            } else {
                                f.mView = NoSaveStateFrameLayout.wrap(f.mView);
                            }
                            if (f.mHidden) f.mView.setVisibility(View.GONE);
                            f.onViewCreated(f.mView, f.mSavedFragmentState);
                            dispatchOnFragmentViewCreated(f, f.mView, f.mSavedFragmentState, false);
                        } else {
                            f.mInnerView = null;
                        }
                    }
                case Fragment.CREATED:
                    if (newState > Fragment.CREATED) {
                        if (DEBUG) Log.v(TAG, "moveto ACTIVITY_CREATED: " + f);
                        if (!f.mFromLayout) {
                            ViewGroup container = null;
                            if (f.mContainerId != 0) {
                                if (f.mContainerId == View.NO_ID) {
                                    throwException(new IllegalArgumentException(
                                            "Cannot create fragment "
                                                    + f
                                                    + " for a container view with no id"));
                                }
                                container = (ViewGroup) mContainer.onFindViewById(f.mContainerId);
                                if (container == null && !f.mRestored) {
                                    String resName;
                                    try {
                                        resName = f.getResources().getResourceName(f.mContainerId);
                                    } catch (NotFoundException e) {
                                        resName = "unknown";
                                    }
                                    throwException(new IllegalArgumentException(
                                            "No view found for id 0x"
                                            + Integer.toHexString(f.mContainerId) + " ("
                                            + resName
                                            + ") for fragment " + f));
                                }
                            }
                            f.mContainer = container;
                            f.mView = f.performCreateView(f.getLayoutInflater(
                                    f.mSavedFragmentState), container, f.mSavedFragmentState);// onCreateView回调
                            if (f.mView != null) {
                                f.mInnerView = f.mView;
                                if (Build.VERSION.SDK_INT >= 11) {
                                    ViewCompat.setSaveFromParentEnabled(f.mView, false);
                                } else {
                                    f.mView = NoSaveStateFrameLayout.wrap(f.mView);
                                }
                                if (container != null) {
                                    container.addView(f.mView);
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
                        if (DEBUG) Log.v(TAG, "movefrom RESUMED: " + f);
                        f.performPause(); //onPause
                        dispatchOnFragmentPaused(f, false);
                    }
                case Fragment.STARTED:
                    if (newState < Fragment.STARTED) {
                        if (DEBUG) Log.v(TAG, "movefrom STARTED: " + f);
                        f.performStop();//调用onStop,state变成STOPPED
                        dispatchOnFragmentStopped(f, false);
                    }
                case Fragment.STOPPED:
                    if (newState < Fragment.STOPPED) {
                        if (DEBUG) Log.v(TAG, "movefrom STOPPED: " + f);
                        f.performReallyStop();//不调用回调，状态变成ACTIVITY_CREATED
                    }
                case Fragment.ACTIVITY_CREATED:
                    if (newState < Fragment.ACTIVITY_CREATED) {
                        if (DEBUG) Log.v(TAG, "movefrom ACTIVITY_CREATED: " + f);
                        if (f.mView != null) {
                            // Need to save the current view state if not
                            // done already.
                            if (mHost.onShouldSaveFragmentState(f) && f.mSavedViewState == null) {
                                saveFragmentViewState(f);
                            }
                        }
                        f.performDestroyView(); //状态变成CREATED，调用onDestoryView。最后收尾调用                            f.mContainer.removeView(f.mView);//引用置空
                        dispatchOnFragmentViewDestroyed(f, false);
                        if (f.mView != null && f.mContainer != null) {
                            Animation anim = null;
                            if (mCurState > Fragment.INITIALIZING && !mDestroyed
                                    && f.mView.getVisibility() == View.VISIBLE
                                    && f.mPostponedAlpha >= 0) {
                                anim = loadAnimation(f, transit, false,
                                        transitionStyle);
                            }
                            f.mPostponedAlpha = 0;
                            if (anim != null) {
                                final Fragment fragment = f;
                                f.setAnimatingAway(f.mView);
                                f.setStateAfterAnimating(newState);
                                final View viewToAnimate = f.mView;
                                anim.setAnimationListener(new AnimateOnHWLayerIfNeededListener(
                                        viewToAnimate, anim) {
                                    @Override
                                    public void onAnimationEnd(Animation animation) {
                                        super.onAnimationEnd(animation);
                                        if (fragment.getAnimatingAway() != null) {
                                            fragment.setAnimatingAway(null);
                                            moveToState(fragment, fragment.getStateAfterAnimating(),
                                                    0, 0, false);
                                        }
                                    }
                                });
                                f.mView.startAnimation(anim);
                            }
                            f.mContainer.removeView(f.mView);
                        }
                        f.mContainer = null;
                        f.mView = null;
                        f.mInnerView = null;
                    }
                case Fragment.CREATED:
                    if (newState < Fragment.CREATED) {
                        if (mDestroyed) {
                            if (f.getAnimatingAway() != null) {
                                // The fragment's containing activity is
                                // being destroyed, but this fragment is
                                // currently animating away.  Stop the
                                // animation right now -- it is not needed,
                                // and we can't wait any more on destroying
                                // the fragment.
                                View v = f.getAnimatingAway();
                                f.setAnimatingAway(null);
                                v.clearAnimation();
                            }
                        }
                        if (f.getAnimatingAway() != null) {
                            // We are waiting for the fragment's view to finish
                            // animating away.  Just make a note of the state
                            // the fragment now should move to once the animation
                            // is done.
                            f.setStateAfterAnimating(newState);
                            newState = Fragment.CREATED;
                        } else {
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
                                    f.mHost = null;
                                    f.mParentFragment = null;
                                    f.mFragmentManager = null;
                                }
                            }
                        }
                    }
            }
        }

        if (f.mState != newState) {
            Log.w(TAG, "moveToState: Fragment state for " + f + " not updated inline; "
                    + "expected state " + newState + " found " + f.mState);
            f.mState = newState;
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


## 4. 现在再来看FragmentPagerAdapter和FragmentStatePagerAdapter
这两个类行数都不超过300行，非常简单，只是通过调用FragmentManager的相应方法实现展示View的功能。

## 5. Fragment的一些不常用的API
attach,detach,FragmentLifecycleCallbacks,commitNow，setAllowOptimization(26.0.0又被deprecated了)



## Reference
1. [Fragment的onAttach和onDetach什么时候会调用](http://stackoverflow.com/questions/9156406/whats-the-difference-between-detaching-a-fragment-and-removing-it) 