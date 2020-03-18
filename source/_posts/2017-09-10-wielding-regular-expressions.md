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
![](https://api1.foster66.xyz/static/imgs/bee-getting-the-pollen-wallpaper-538358eb5d5a3.jpg)


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



## C语言版本的正则
[regex.h](https://www.zfl9.com/c-regex-pcre.html)

![](https://api1.foster66.xyz/static/imgs/scenery151110067848.jpg)
![](https://api1.foster66.xyz/static/imgs/1513521515888.jpg)
![](https://api1.foster66.xyz/static/imgs/1513521557303.jpg)


![](https://api1.foster66.xyz/static/imgs/1102533911-1.jpg)
![](https://api1.foster66.xyz/static/imgs/20120103214255_nTsVt.jpg)
![](https://api1.foster66.xyz/static/imgs/apic5964_sc115.jpg)

![](https://api1.foster66.xyz/static/imgs/strawberry-festival.jpg)



![](https://api1.foster66.xyz/static/imgs/macro-of-yellow-narcisa-flower-wallpaper-53834d45b40a1.jpg)

![](https://api1.foster66.xyz/static/imgs/yellow-autumn-leaves-wallpaper-537f1e4672a31.jpg)



![](https://api1.foster66.xyz/static/imgs/rice_on_trunk.jpg)

![](https://api1.foster66.xyz/static/imgs/EibseeHerbst_EN-AU10470771604_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/FoxMolt_ZH-CN7917304192_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/FremontPeak_EN-AU8617183007_1920x1080.jpg)

![](https://api1.foster66.xyz/static/imgs/HuaynaPicchu_EN-AU9938663347_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/HubbleSaturn_EN-AU12572317531_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/JeanLafitte_EN-AU11428973003_1920x1080.jpg)



![](https://api1.foster66.xyz/static/imgs/OtterChillin_EN-AU10154811440_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/ParkRangerIsmael_EN-AU8783805449_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/PortAntonio_EN-AU9246692740_1920x1080.jpg)

![](https://api1.foster66.xyz/static/imgs/RedAntarctica_EN-AU12197122155_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/SaltApple_EN-AU13056568956_1920x1080.jpg)

![](https://api1.foster66.xyz/static/imgs/SuperBlueBloodMoon_JA-JP11881086623_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/TDPflamingos_EN-AU9923017546_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/WavePoppy_EN-AU9071800685_1920x1080.jpg)

![](https://api1.foster66.xyz/static/imgs/BlueMushroom_EN-AU9252668987_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/DCCB_EN-AU11982634575_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/DogWork_EN-AU10032511594_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/ElkValleyVideo_EN-AU7645555683_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/Forest_ZH-CN16430313748_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/HeronIslandShark_EN-AU12565902939_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/Mapleleaf_ZH-CN9491310356_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/MaryLouWilliams_EN-AU11937645356_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/Mooncake_ZH-CN10274798301_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/MooseLakeGrass_EN-AU11940305772_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/PlutoNorthPole_ZH-CN12213356975_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/Rapadalen_EN-AU11885358150_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/SweetChestnut_ZH-CN10220364928_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/TadamiTrain_ZH-CN13495442975_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/TahquamenonFalls_EN-AU8966938934_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/VallesMarineris_ZH-CN10598461085_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/WorldRefugeeDay_EN-AU5421237644_1920x1080.jpg)



![](https://api1.foster66.xyz/static/imgs/LakePowellStorm_ZH-CN6822865622_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/OceanCurrents_ZH-CN13704695457_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/Aldabra_EN-AU10067035056_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/EborFallsVideo_EN-AU8428374700_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/OsoyoosExpressway_EN-AU12955968650_1920x1080.jpg)


![](https://api1.foster66.xyz/static/imgs/BailysBeads_ZH-CN5728297739_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/ElkFallsBridge_ZH-CN3921681387_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/HawksbillCrag_ZH-CN4429681235_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/HKreuni_ZH-CN5683726370_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/ManausBasin_ZH-CN4303809335_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/RootBridge_ZH-CN5173953292_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/SalcombeDevon_ZH-CN5806331292_1920x1080.jpg)




![](https://api1.foster66.xyz/static/imgs/RainierMilkyWay_ZH-CN9404321904_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/PeruvianRainforest_ZH-CN4066508593_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/Ghyakar_ZH-CN4631836915_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/LuciolaCruciata_ZH-CN9063767400_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/HallstattAustria_PT-BR9407016733_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/PingganVillage_ZH-CN10035092925_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/RainforestMoss_ZH-CN2878951870_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/BlumenwieseNRW_ZH-CN4774429225_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/HopeValley_ZH-CN2208363231_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/NFLDfog_ZH-CN4846953507_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/dragonboat_ZH-CN0697680986_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/Manhattanhenge_ZH-CN4659585143_1920x1080.jpg)
![](https://api1.foster66.xyz/static/imgs/QingMingHuangShan_ZH-CN12993895964_1920x1080.jpg)




![](https://api1.foster66.xyz/static/imgs/starry-night-van-gogh.jpg)
### 参考
- [DFA和NFA](http://www.importnew.com/26560.html)
- [Learn regex the easy way](https://github.com/ziishaned/learn-regex)
- [大部分图片来自必应壁纸](https://bing.ioliu.cn/)
