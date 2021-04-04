---
title: react-native-cookbook
date: 2018-01-19 22:28:34
tags: [前端]
---

![](https://api1.foster57.tk/static/imgs/iu%20kpop%20star%20music%20sony.jpg)

<!--more-->

更新
[2020年不再推荐使用react native cli](https://github.com/react-native-community/cli#using-npx-recommended)
在mac上使用这种命令可以直接创建一个新的react native app，自动拉起一个simulator，运行这个app。
```
npx react-native init AwesomeProject
cd AwesomeProject
npx react-native run-ios
```


### tips
在android手机上打开显示布局边界，发现react-native app并不是一个webview，而是一个个实在的buttom,text。

目前暂不支持java 9
Double tap R on your keyboard to reload其实并不是按电脑键盘上的R，而是模拟器上的，所以需要鼠标上去，ctrl+m即可
如果是一台真实手机的话，需要摇一摇手机，就能显示菜单。但是每次都要摇一摇实在是太麻烦，所以点一下那个Enable LiveReload就能在每次保存文件后Reload。

npm run start是用来起dev server的。
react-native run-android是用来向client端推更新的。

could not connect to development server...的原因就是没有运行npm start。

所以，正常的流程应该是npm start && react-native run-android

debug:
react-native run-android是把这个App安装到手机上，然后terminal就返回了，需要查看后续日志输出的话
react-native log-android // 这个是帮助在console中输出log



## route
**react-navigation** 似乎是官方推荐的解决方案，下面给出的是1.x版本的写法，目前(2020年)已经出到5.X版本了。🤮
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

类似于LinearLayout horizontal ,1：3等分两个View的方式可以这么写
```js
<View style={{flexDirection:'row'}}>
  <Text style={{flex:1}}>
    occupy 25% width
  </Text>
  <Text style={{flex:3}}>
    occupy 75% width
  </Text>
</View>
```


Image支持圆角，例如 borderTopRightRadius
[image，这个是Image控件的文档](https://facebook.github.io/react-native/docs/image.html)
下面这个是圆形的Image
```js
<Image
  style={{
    alignSelf: 'center',
    height: 150,
    width: 150,
    borderWidth: 1,
    borderRadius: 75
  }}
  source={{uri:'https://facebook.github.io/react/img/logo_og.png'}}
  resizeMode="cover"
/>
```


[images，这个是Image数据源的文档](https://facebook.github.io/react-native/docs/images.html)</br>
大致意思是网络图片需要手动设置宽高，assets文件则不需要。因为require(./avatar.png)的返回值将会自动带上图片的尺寸信息
```
 It is more work for the developer to know the dimensions (or aspect ratio) of the remote image in advance, but we believe that it leads to a better user experience. Static images loaded from the app bundle via the require('./my-icon.png') syntax can be automatically sized because their dimensions are available immediately at the time of mounting.
```



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

## Components
Android平台一个ScrollView只能有一个ChildView(Node)，在react-native上似乎没有这样的限制

Button是一个没什么大用处的控件，一般用TouchableOpacity包一层text去实现
[Button组件的styling仅限于几个属性，可以用TouchableXXX来代替](https://stackoverflow.com/questions/43585297/react-native-button-style-not-work)

```
The React Native Button is very limited in what you can do, see; Button

It does not have a style prop, and you don't set text the "web-way" like <Button>txt</Button> but via the title property <Button title="txt" />

If you want to have more control over the appearance you should use one of the TouchableXXXX' components like TouchableOpacity They are really easy to use :-)
```


在jsx里面写三元表达式也是可以的
```xml
<View style={{paddingTop: Platform.OS === 'android' ? 0 : 20}}>
</View>
```


### 状态栏问题
尤其是在iphone X上，如何设置notch那一块位置的颜色
[iOS doesn't have a concept of a status bar bg](https://stackoverflow.com/a/39300715)

### 触控事件处理
[如何处理touch event](https://facebook.github.io/react-native/docs/gesture-responder-system) react native把这个称之为gesture

## PropTypes用于定义一个Component的props
> import PropTypes from 'prop-types'; // 主要是为了类型检查吧

例如PropTypes.oneOfType


### 直接操作某个element也不是没有
[refs](https://reactjs.org/docs/refs-and-the-dom.html)
可以用来获取某个element，直接操作，例如measure

```js
cloneElement()
isValidElement()
React.Children
```


### [下拉刷新可以使用refreshControl](https://facebook.github.io/react-native/docs/refreshcontrol)
## 待填坑

async storage

camera Roll

React.FunctionComponent

## react hooks的出现是为了替代一些嵌套得过深的高阶组件。
hooks里面也有一个store，推荐去看一下react-redux的源码。应该有兼容class component和functional component的写法。



[ReactNative之js与native通信流程（Android篇）](http://yangguang1029.github.io/2018/02/26/rn-android-communicate/)
[ReactNative之VirtualDomTree的diff原理](http://yangguang1029.github.io/2018/02/25/rn-reconciliation/)
[基于React Native构建的仿京东客户端](https://github.com/yuanguozheng/JdApp)


