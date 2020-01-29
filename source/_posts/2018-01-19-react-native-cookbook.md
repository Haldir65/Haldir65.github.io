---
title: react-native-cookbook
date: 2018-01-19 22:28:34
tags: [前端]
---

![](https://www.haldir66.ga/static/imgs/iu%20kpop%20star%20music%20sony.jpg)

<!--more-->

更新
[2020年不再推荐使用react native cli](https://github.com/react-native-community/cli#using-npx-recommended)
在mac上使用这种命令可以直接创建一个新的react native app，自动拉起一个simulator，运行这个app。
```
npx react-native init AwesomeProject
cd AwesomeProject
npx react-native run-ios
```


<del>install cli</del>

>npm install -g react-native-cli
react-native init myproject ## 最好全部小写字母
cd myproject
react-native run-android
注意，可能会报错



```
FAILURE: Build failed with an exception.
* What went wrong:
A problem occurred configuring project ':app'.
> SDK location not found. Define location with sdk.dir in the local.properties file or with an ANDROID_HOME environment variable.
```

新建一个local.properities文件，放到android 文件夹下面就好了

[unable-to-load-script-from-assets-index-android-bundle-on-windows](https://stackoverflow.com/questions/44446523/unable-to-load-script-from-assets-index-android-bundle-on-windows)

在android手机上打开显示布局边界，发现react-native app并不是一个webview，而是一个个实在的buttom,text。

### tips
目前暂不支持java 9
Double tap R on your keyboard to reload其实并不是按电脑键盘上的R，而是模拟器上的，所以需要鼠标上去，ctrl+m即可
如果是一台真实手机的话，需要摇一摇手机，就能显示菜单。但是每次都要摇一摇实在是太麻烦，所以点一下那个Enable LiveReload就能在每次保存文件后Reload。
注意，如果更改了state，那么hotReload没用，需要手动Reload

npm run start是用来起dev server的。
react-native run-android是用来向client端推更新的。

could not connect to development server...的原因就是没有运行npm start。

所以，正常的流程应该是npm start && react-native run-android

debug:
react-native run-android是把这个App安装到手机上，然后terminal就返回了，需要查看后续日志输出的话
react-native log-android // 这个是帮助在console中输出log

jsx文件开头的import要注意
```js
// 这是错误的
import React, { AppRegistry,  Component,StyleSheet,Text,View} from 'react-native';
//这才是正确的
import React from "react";
import { AppRegistry,  Component,StyleSheet,Text,View} from 'react-native';
```

## route
Navigator is deprecated,use [stack navigator](https://reactnavigation.org/)
```js
import React from 'react';
import { View, Text } from 'react-native';
import { StackNavigator } from 'react-navigation'; // 1.0.0-beta.27

class HomeScreen extends React.Component {
  render() {
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
        <Text>Home Screen</Text>
      </View>
    );
  }
}

class DetailsScreen extends React.Component {
  render() {
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
        <Text>Details Screen</Text>
      </View>
    );
  }
}

const RootStack = StackNavigator(
  {
    Home: {
      screen: HomeScreen,
    },
    Details: {
      screen: DetailsScreen,
    },
  },
  {
    initialRouteName: 'Home',
  }
);

export default class App extends React.Component {
  render() {
    return <RootStack />;
  }
}
```

## 既然有路由就不免谈到各个组件之间的写法
显然，你可以将LogoTitle写到另一个文件中去，然后export default，再import出来。
下面这种只是为了说明你能这样写，一个很简单的小功能可以放在内部作为一个class自己使用。
```js
class LogoTitle extends React.Component {
  render() {
    return (
      <Image
        source={require('./spiro.png')}
        style={{ width: 30, height: 30 }}
      />
    );
  }
}

class HomeScreen extends React.Component {
  static navigationOptions = {
    // headerTitle instead of title
    headerTitle: <LogoTitle />,
  };

  /* render function, etc */
}
```


## styling
```js
<View style={{
              height:30,
              backgroundColor:'purple',
              justifyContent:'center',
              alignItems:'center',
              flexDirection:'row',
              alignContent:'flex-start'
          }}>
      <Text style={{
          color: 'white',
          backgroundColor: 'red',
      }}>
          This Text will be centered both horizontally and vertically
      </Text>
</View>
```
view的props中,true要这么写

<!-- > autoFocus={true} -->

Text文字居中的方式是设置alignSelf:center

[SectionList](https://facebook.github.io/react-native/docs/sectionlist)自带stickyHeader，并且其数据结构是这样的
```js
const DATA = [
  {
    title: 'Main dishes',
    data: ['Pizza', 'Burger', 'Risotto'],
  },
  {
    title: 'Sides',
    data: ['French Fries', 'Onion Rings', 'Fried Shrimps'],
  },
  {
    title: 'Drinks',
    data: ['Water', 'Coke', 'Beer'],
  },
  {
    title: 'Desserts',
    data: ['Cheese Cake', 'Ice Cream'],
  },
];
```


[Button组件的styling仅限于几个属性，可以用TouchableXXX来代替](https://stackoverflow.com/questions/43585297/react-native-button-style-not-work)



## Components

Button是一个没什么大用处的控件，一般用TouchableOpacity包一层text去实现


### ScrollView
Android平台一个ScrollView只能有一个ChildView(Node)，在react-native上似乎没有这样的限制

```
The React Native Button is very limited in what you can do, see; Button

It does not have a style prop, and you don't set text the "web-way" like <Button>txt</Button> but via the title property <Button title="txt" />

If you want to have more control over the appearance you should use one of the TouchableXXXX' components like TouchableOpacity They are really easy to use :-)
```

// Adding alignItems to a component's style determines the alignment of children along the secondary axis 


```
As of react v16.3.2 these methods are not "safe" to use:

componentWillMount
componentWillReceiveProps
componentWillUpdate
```


在jsx里面写三元表达式也是可以的
```xml
<View style={{paddingTop: Platform.OS === 'android' ? 0 : 20}}>
</View>
```





尤其是在iphone X上，如何设置notch那一块位置的颜色
[iOS doesn't have a concept of a status bar bg](https://stackoverflow.com/a/39300715)

## 参考
[基于React Native构建的仿京东客户端](https://github.com/yuanguozheng/JdApp)


async storage

camera Roll

React.FunctionComponent

## 待填坑
[ReactNative之js与native通信流程（Android篇）](http://yangguang1029.github.io/2018/02/26/rn-android-communicate/)
[ReactNative之VirtualDomTree的diff原理](http://yangguang1029.github.io/2018/02/25/rn-reconciliation/)


<!-- <audio src="http://m10.music.126.net/20180121230941/8d878803b3b0542d9c5482ccf613a86b/ymusic/d95e/bab6/a7f5/864661168da79b309c3d2fac971d1698.mp3" autoplay="autoplay">
您的浏览器不支持 audio 标签。
</audio> -->
