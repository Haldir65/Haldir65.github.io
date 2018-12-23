---
title: Vim常用命令指南
date: 2018-08-26 22:49:00
tags: [linux]
---

![](https://www.haldir66.ga/static/imgs/food_truck_hotdog_night_city.jpg)
<!--more-->


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
挪到文件开头: H 挪到文件头部是gg
挪到文件最后: L 挪到文件底部是G

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

走到当前行的末尾: $
走到当前行的开头: 0



visual mode
进入visual mode之后就可以大段的复制粘贴了


还可以全文搜索
按一个/（斜杠就可以了），好像按n时往下查找下一个匹配结果


VIM格式化代码：
格式化全文指令 gg=G //这其实是三个命令,gg是到达文档开始,=是要求缩进，G是到达文档最后一行
自动缩进当前行指令　　==
格式化当前光标接下来的8行　　8=
格式化选定的行　　v 选中需要格式化的代码段 =


很多人都会有一个vimrc文件备份在github上，那么vimrc其实就是对于vim这个编辑器的配置文件
全局的vimrc文件在/etc/vim/vimrc 这个位置，针对单个用户还是在~/.vimrc这个文件里面改

```
set number "显示行号，这个注释只要左边的冒号就行了
syntax on “自动语法高亮 
set shiftwidth=4 “默认缩进4个空格 
set softtabstop=4 “使用tab时 tab空格数 
set tabstop=4 “tab 代表4个空格 
set expandtab “使用空格替换tab
```


比较出名的vimrc是[the ultimate vimrc](https://github.com/amix/vimrc)，自带一些比较好的插件
首先在任意目录,输入vim。
任何时候想要退出vim的话 :q 就可以了


## 一些好用的插件：
[NERDTree是一个类似于file browser的插件](https://github.com/scrooloose/nerdtree)
ctrl + w + h    光标 focus 左侧树形目录
ctrl + w + l    光标 focus 右侧文件显示窗口
ctrl + w + w    光标自动在左右侧窗口切换
ctrl + w + r    移动当前窗口的布局位置
o       在已有窗口中打开文件、目录或书签，并跳到该窗口
go      在已有窗口 中打开文件、目录或书签，但不跳到该窗口
t       在新 Tab 中打开选中文件/书签，并跳到新 Tab
T       在新 Tab 中打开选中文件/书签，但不跳到新 Tab
i       split 一个新窗口打开选中文件，并跳到该窗口
gi      split 一个新窗口打开选中文件，但不跳到该窗口
s       vsplit 一个新窗口打开选中文件，并跳到该窗口
gs      vsplit 一个新 窗口打开选中文件，但不跳到该窗口
:tabnew [++opt选项] ［＋cmd］ 文件      建立对指定文件新的tab
:tabc   关闭当前的 tab
:tabo   关闭所有其他的 tab
:tabs   查看所有打开的 tab
:tabp   前一个 tab
:tabn   后一个 tab


[vim-fugitive](https://github.com/tpope/vim-fugitive) fugitive.vim: A Git wrapper so awesome, it should be illegal 


[ctrl +f 就是激活ctrlp](https://github.com/ctrlpvim/ctrlp.vim)这个插件，类似于文件搜索

[内置了vim-markdown](https://github.com/tpope/vim-markdown)。默认已经可以实现markdown语法高亮。默认是自动把段落收起来的，光标一直挪到右边就自动展开了

## 参考
[vim cheat sheet](https://vim.rtorr.com/)
[youtube上一个比较好的关于vim的视频](https://www.youtube.com/watch?v=Nim4_f5QUxA)
[练上一年再来总结的vim使用技巧](http://www.pchou.info/linux/2016/11/10/vim-skill.html)



