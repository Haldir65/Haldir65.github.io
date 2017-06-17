---
title: For those tiny details in Java 
date: 2017-06-17 21:24:48
tags: [java]
---
> interesting stuff in java that don't seem to get enough pubilicity
> 
>

![landscape](http://odzl05jxx.bkt.clouddn.com/34a7d57ccabb18c69d085247cf009b22.jpg?imageView2/2/w/600)

<!--more-->

1. getting the concreate class from generic types
    ```java
        /**
     * Make a GET request and return a parsed object from JSON.
     *
     * @param url     URL of the request to make
     * @param clazz   Relevant class object, for Gson's reflection
     * @param headers Map of request headers
     */
    public GenericMoshiRequest(String url, @Nullable Class<T> clazz, Map<String, String> headers,
                               Response.Listener<T> listener, Response.ErrorListener errorListener) {
        super(Method.GET, url, errorListener);
//        this.clazz = clazz;
        Class<T> entityClass = (Class<T>) ((ParameterizedType) getClass().getGenericSuperclass()).getActualTypeArguments()[0];//使用反射获得泛型对应class
        this.clazz = entityClass;
        this.headers = headers;
        this.listener = listener;
    }
    ```

