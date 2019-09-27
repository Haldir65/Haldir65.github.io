---
title: replace butterKnife with databinding
date: 2016-09-22 15:17:39
categories: blog
tags: [databinding, Butterknife,android]
---


Yigit Boyar 在2015年的android Dev summit上介绍了Databinding，当时好像提到一句:
"no binding libraries will be created from now on "，大意如此。
本文介绍使用Databinding替代ButterKnife的用法
## 本文大部分代码来自网络，我只是觉得简单的代码直接复制粘贴可能会比较好。
<!--more-->

# 1.在Activity中使用
*before*
```java
class ExampleActivity extends Activity {
  @Bind(R.id.title) TextView title;
  @Bind(R.id.subtitle) TextView subtitle;
  @Bind(R.id.footer) TextView footer;

  @Override
  public void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.simple_activity);
    ButterKnife.bind(this);
  }
}
```
*after*
首先需要将xml文件添加 **Layout** tag
`R.layout.smple_activity`
```xml
<layout>
  <LinearLayout>
    <TextView android:id="@+id/title">
    <TextView android:id="@+id/subtitle">
    <TextView android:id="@+id/footer">
  </LinearLayout>
</layout>
```
```java
class ExampleActivity extends Activity {
  private ActivitySampleBinding binding;

  @Override
  public void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    binding = DataBindingUtils.setContentView(this, R.layout.simple_activity);
    binding.title.setText("I am Title");
    //no more findViewById!!!
  }
}
```

# 2.在Fragment中使用
*before*
```java
public class FancyFragment extends Fragment {
  @Bind(R.id.button1) Button button1;
  @Bind(R.id.button2) Button button2;
  @Override
  public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
    View view = inflater.inflate(R.layout.fancy_fragment, container, false);
    ButterKnife.bind(this, view);
    // TODO Use fields...
    return view;
  }
}
```

*after*
```java
public class FancyFragment extends Fragment {
  private FragmentFancyBinding binding;

  @Override
  public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
    binding = DataBindingUtil.inflate(inflater,R.layout.fragment_fancy, container, false);
	  return binding.getRoot();
  }

}
```

# 3.在ViewHolder中使用

*before*
```java
public class MyAdapter extends BaseAdapter {
  @Override
  public View getView(int position, View view, ViewGroup parent) {
    ViewHolder holder;
    if (view != null) {
      holder = (ViewHolder) view.getTag();
    } else {
      view = inflater.inflate(R.layout.list_item_sample, parent, false);
      holder = new ViewHolder(view);
      view.setTag(holder);
    }

    holder.name.setText("John Doe");
    // etc...

    return view;
  }

  static class ViewHolder {
    @Bind(R.id.title) TextView name;
    @Bind(R.id.job_title) TextView jobTitle;
    public ViewHolder(View view) {
      ButterKnife.bind(this, view);
    }
  }
}
```

*after*
### ListView
```java
public class MyAdapter extends BaseAdapter {
  @Override
  public View getView(int position, View convertView, ViewGroup parent) {
      ListItemSampleBinding binding;
      if (convertView == null) {
          binding = DataBindingUtil.inflate(inflater, R.layout.list_item_sample, parent, false);
          convertView = binding.getRoot();
          convertView.setTag(binding);
      } else {
          binding = (ListItemSampleBinding) convertView.getTag();
      }
      binding.setUser(getItem(position));
      // binding.name.setText("John Doe");

      return convertView;
  }
}
```

### recyclerView
```java
public class SampleRecyclerAdapter extends RecyclerView.Adapter<SampleRecyclerAdapter.BindingHolder> {

    @Override
    public RegisterableDeviceListAdapter.ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
      final View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.list_item_sample, parent, false);
      return new BindingHolder(v);
    }

  @Override
  public void onBindViewHolder(BindingHolder holder, int position) {
    holder.getBinding().setVariable(BR.user, getItem(position));
  }

  static class BindingHolder extends RecyclerView.ViewHolder {
    private final ViewDataBinding binding;

    public BindingHolder(View itemView) {
      super(itemView);
      binding = DataBindingUtil.bind(itemView)
    }

    public ViewDataBinding getBinding() {
      return binding;
    }
  }
}
```

# 4.在CustomView中使用
在自定义View(ViewGroup)的时候，可以用ButterKnife减少自定义ViewGroup中的findViewById,使用Databinding之后是这样的。
```java
public class Pagination extends RelativeLayout {
  private ViewPaginationBinding binding;

  public Pagination(Context context) {
    this(context, null);
  }

  public Pagination(Context context, AttributeSet attrs) {
    super(context, attrs);
    binding = DataBindingUtil.inflate(LayoutInflater.from(context), R.layout.view_pagination, this, true);
  }

  public static void setListener(Pagination paginate, View target, OnPaginationClickListener listener) {
    if (listener != null) {
      target.setOnClickListener(_v -> listener.onClick(paginate));
    }
  }

  @BindingAdapter({"android:onPrevButtonClicked"})
  public static void setPrevClickListener(Pagination view, OnPaginationClickListener listener) {
    setListener(view, view.binding.btnPrevPage, listener);
  }

  @BindingAdapter({"android:onNextButtonClicked"})
  public static void setNextClickListener(Pagination view, OnPaginationClickListener listener) {
    setListener(view, view.binding.btnNextPage, listener);
  }

  public interface OnPaginationClickListener {
    void onClick(Pagination pagination);
  }
}
```

# 5.EventHandler, setDefaultComponent...</br>
Databinding还有很多高级用法，目前给我带来的好处就是明显减少了boilerplate code </br>
So ,感谢ButterKnife给我们带来的便利，Googbye ButterKnife，Hello DataBinding!

＊todo＊
###　how did ButterKnife work?
[ButterKnife](https://github.com/JakeWharton/butterknife)
[原理基本上从ButterKnifeAnnotationProcess.process开始](https://medium.com/@lgvalle/how-butterknife-actually-works-85be0afbc5ab)



# Reference

 1. [Data Binding Library](https://developer.android.com/topic/libraries/data-binding/index.html)
 2. [data-binding-android-boyar-mount](https://realm.io/cn/news/data-binding-android-boyar-mount/)
 3. [Advanced Data Bindinding](https://www.youtube.com/watch?v=DAmMN7m3wLU) Two-Way Data Binding at google io 2016
 4. [Android Dev Summit 2015](https://www.youtube.com/watch?v=NBbeQMOcnZ0)
 5. [Goodbye Butter Knife](http://qiita.com/izumin5210/items/2784576d86ce6b9b51e6)
 6. [Google Sample](https://github.com/google/android-ui-toolkit-demos)
