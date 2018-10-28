---
title: 正则表达式手册
date: 2017-09-10 23:10:05
tags: [tools]
---

关于正则的一些收集


<!--more-->


javaScript中的正则
比如说webpack.config.js中，loader模块有:
```js
{
  ...
  test: /\.css$/,
  ...
}
```

nginx的config文件中也要写正则




第一个正斜杠和最后一个正斜杠表示正则的开始和结束，反斜杠表示后面那个点就当做一个文字的点来处理，$代表以css结束
***We need more Pictures***

> ^表示开头，$表示结尾 ## django的url中是这样的

一般情况下不要乱用正则
![](https://www.haldir66.ga/static/imgs/bee-getting-the-pollen-wallpaper-538358eb5d5a3.jpg)


### 从digitalOcean的 grep教程中抄来一些
[using-grep-regular-expressions-to-search-for-text-patterns-in-linux](https://www.digitalocean.com/community/tutorials/using-grep-regular-expressions-to-search-for-text-patterns-in-linux)
grep(global regular expression print)
在文件中查找字符串，不区分大小写
- grep -i "sometext" filenname
在一个文件夹里面的所有文件中递归查找含有特定字符串的文件
- grep -r "sometext" *
- grep -v "the" BSD //在BSD这个文件中查找不包含"the"这个单词的的行（对，一行一行的找） v 的意思是“--invert-match”
- grep -vn "the" BSD //n的意思是显示行号  "--line-number" 

## 这俩和django里面的url.py很像
// grep "^GNU" GPL-3 // only mach "GNU" if it occurs at the very beginning of a line.(只会匹配上以GNU开头的)
// grep "and$" GPL-3 // match every line ending with the word "and" in the following regular expression: （只会匹配上以and结束的）

// grep "..cept" GPL-3 // "."的意思是一个字符，anything that has two characters and then the string "cept", （两个字符加上cept的）

// grep "t[wo]o" GPL-3 //  find the lines that contain "too" or "two"，中间的单词可以是w也可以是o

// grep "[^c]ode" GPL-3 // 除了'c'以外什么字母都可以，大写的'C'也会匹配上

// grep "^[A-Z]" GPL-3 //任何以一个大写字母开头的
// grep "^[[:upper:]]" GPL-3 //这个也是找大写字母开头的，:upper叫做POSIX character classes，比上面更加准确一些

// one of the most commonly used meta-characters is the "*", which means "repeat the previous character or expression zero or more times"."*"是重复前面的expression的意思，而不是任意字符的意思，任意字符应该用"."

// grep "([A-Za-z ]*)" GPL-3 //找到所有小括号包起来的，小括号里面只有小写或者大写字母或者空格的行

// grep "^[A-Z].*\.$" GPL-3 // any line that begins with a capital letter and ends with a period（大写字母开头，中间那个点表示任意字符，反斜杠表示转义字符）

// egrep 和grep -E 是一个意思
e的意思是extended regular expressions（Extended regular expressions include all of the basic meta-characters, along with additional meta-characters to express more complex matches.翻译下就是能够使用更多的正则）

// grep -E "(GPL|General Public License)" GPL-3 //包含GPL或者General Public License的行

// grep -E "(copy)?right" GPL-3 //*号的意思是重复之前的pattern无数次，?是重复0或者1次，所以这个匹配上的是copyright或者right

//grep -E "free[^[:space:]]+" GPL-3 //+号表示一次或者多次，和*差不多，但是+号至少得有一次。所以这个匹配上free加上一个或者多个非空格

//grep -E "[AEIOUaeiou]{3}" GPL-3  //前面的*号表示重复多次，.号表示任意字符,+号表示重复至少一次，那么指定重复n次就要用花括号包起来。这句话的意思是AEIOUaeiou里面任意字符连在一起出现正好三次

//grep -E "[[:alpha:]]{16,20}" GPL-3 //If we want to match any words that have between 16 and 20 characters.任何包含16-20个字母的单词


[fgrep不支持正则表达式，只能实现全部关键字匹配，用处不大](http://www.178linux.com/7040)


[Linux 中 grep 命令的 12 个实践例子](http://blog.jobbole.com/112580/)


![](https://haldir66.ga/static/imgs/ship_docking_along_side_bay.jpg)
![](https://www.haldir66.ga/static/imgs/scenery151110067848.jpg)
![](https://www.haldir66.ga/static/imgs/scenery1511100718415.jpg)
![](https://www.haldir66.ga/static/imgs/fresh-sparkle-dew-drops-on-red-flower-wallpaper-53861cf580909.jpg)
![](https://www.haldir66.ga/static/imgs/1513521515888.jpg)
![](https://www.haldir66.ga/static/imgs/1513521557303.jpg)
![](https://www.haldir66.ga/static/imgs/black-mountains.jpg)
![](https://www.haldir66.ga/static/imgs/scenery151110074347.jpg)

![](https://www.haldir66.ga/static/imgs/scenery1511100746620.jpg)
![](https://www.haldir66.ga/static/imgs/sceneryd15ddf2ba4fb7b5f4e51dfa6cb74cb70.jpg)

![](https://www.haldir66.ga/static/imgs/strawberry-festival.jpg)
![](https://www.haldir66.ga/static/imgs/scenery1511100729187.jpg)
![](https://www.haldir66.ga/static/imgs/1102533137-5.jpg)
![](https://www.haldir66.ga/static/imgs/1102533911-1.jpg)
![](https://haldir66.ga/static/imgs/20120103214255_nTsVt.jpg)
![](https://www.haldir66.ga/static/imgs/apic5964_sc115.jpg)
![](https://www.haldir66.ga/static/imgs/apic6283_sc115.jpg)
![](https://haldir66.ga/static/imgs/849c18412f8e7a0b18df09f6f87e6516.jpg)

![](https://www.haldir66.ga/static/imgs/timg.jpg)

![](https://www.haldir66.ga/static/imgs/beautiful-dandelion-wallpaper-5384b7d0e8b09.jpg)
![](https://www.haldir66.ga/static/imgs/cotton-grass-whip-wallpaper-5383509d2bd13.jpg)

![](https://www.haldir66.ga/static/imgs/bullet-shots-over-the-flower-wallpaper-56ee6081c7f2b.jpg)
![](https://www.haldir66.ga/static/imgs/macro-of-yellow-narcisa-flower-wallpaper-53834d45b40a1.jpg)
![](https://www.haldir66.ga/static/imgs/nature-grass-wet-plants-high-resolution-wallpaper-573f2c6413708.jpg)

![](https://www.haldir66.ga/static/imgs/yellow-autumn-leaves-wallpaper-537f1e4672a31.jpg)

![](https://www.haldir66.ga/static/imgs/green_forset_alongside_river_2.jpg)

![](https://haldir66.ga/static/imgs/starry-night-van-gogh.jpg)
### 参考
- [DFA和NFA](http://www.importnew.com/26560.html)
