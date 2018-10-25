---
title: Vim常用命令指南
date: 2018-08-26 22:49:00
tags: [linux]
---

![](https://www.haldir66.ga/static/imgs/food_truck_hotdog_night_city.jpg)
<!--more-->

很多人都会有一个vimrc文件备份在github上，应该是挺高频的操作

首先是一些加快terminal 中操作的命令，跟vim没什么关系

在bash中，几个比较方便的快捷键(zsh可能不一样)
sudo !! - re-run previous command with 'sudo' prepended ##敲命令忘记加sudo了，直接sudo!!，把上一个命令加上sudo执行一遍

ctrl-k（剪切掉光标之后的文字）
ctrl-y(把ctrl k剪切的文字粘贴上来) 
ctrl-u(清空当前行)
ctrl-w(remove word by word)

use 'less +F' to view logfiles, instead of 'tail' (ctrl-c, shift-f, q to quit)
ctrl-x-e - continue editing your current shell line in a text editor (uses $EDITOR)
alt-. - paste previous command's argument (useful for running multiple commands on the same resource)

在当前目录下查找"python"这几个字符
>grep -ni "python" * //如果要递归，就是碰到子文件夹就往下找

这个命令好在能够显示在哪个文件的哪一行找到的



接下来是vim常用的一些
### 首先是command mode下的
```
    k
h       l
    j
```
挪到屏幕头部: H 挪到文件头部是gg
挪动光标到屏幕底部: L 挪到文件底部是G

走到第5行： 5G


复制当前行: yy
复制2行： 2yy
刚才复制的东西要粘贴: p(光标后粘贴)，P(光标前粘贴)
复制当前单词: yw

剪切当前行: dd
剪切2行: 2dd
剪切当前单词: dw

从光标位置到行末尾全部剪切：D(D$也行)

撤销刚才的操作(undo): u










visual mode
进入visual mode之后就可以大段的复制粘贴了


还可以全文搜索
按一个/（斜杠就可以了），好像按n时往下查找下一个匹配结果




格式化整个文件
gg=G //这其实是三个命令,gg是到达文档开始,=是要求缩进，G是到达文档最后一行


[vim cheat sheet](https://vim.rtorr.com/)
[youtube上一个比较好的关于vim的视频](https://www.youtube.com/watch?v=Nim4_f5QUxA)
[练上一年再来总结的vim使用技巧](http://www.pchou.info/linux/2016/11/10/vim-skill.html)

