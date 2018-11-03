---
title: linux常用命令(三)
date: 2018-11-04 08:44:22
categories: blog
tags: [linux,tools]
---

![](https://www.haldir66.ga/static/imgs/green_forset_alongside_river_2.jpg)

<!--more-->

### linux sed命令
[basic sed](https://www.digitalocean.com/community/tutorials/the-basics-of-using-the-sed-stream-editor-to-manipulate-text-in-linux)
>  sed operates on a stream of text that it reads from either standard input or from a file.

基本命令格式
sed [options] commands [file-to-edit]

## 默认情况下,sed会把结果输出到standoutput里面
sed '' BSD ##等同于cat
cat BSD | sed '' ##操作cat的输出流
sed 'p' BSD ##p是命令，明确告诉它要去print，这会导致每一行都被打印两遍
sed -n 'p' BSD ##我不希望你自动打印，每行只被打印一遍
sed -n '1p' BSD ##只打印第一行
sed -n '1,5p' BSD ##打印前5行
sed -n '1,+4p' BSD ##这个也是打印前五行
sed -n '1~2p' BSD ##every other line，打印一行跳过一行，从第一行开始算
sed '1~2d' BSD ##也是隔一行进行操作，只不过这里的d表示删除，结果就是1，3，5...行被从cat的结果中删掉

默认情况下,sed不会修改源文件，加上-i就能改了
sed -i '1~2d' everyother.txt ##第1，3，5，...行被删掉
sed -i.bak '1~2d' everyother.txt ##在编辑文件之前保存一份.bak文件作为备份

sed最为常用的命令就是substituting text了
echo "http://www.example.com/index.html" | sed 's_com/index_org/home_'
http://www.example.org/home.html

命令是这么用的,首先s表示substitute
's/old_word/new_word/'

准备好这么一份text文件
echo "this is the song that never ends
yes, it goes on and on, my friend
some people started singing it
not knowing what it was
and they'll continue singing it forever
just because..." > annoying.txt

sed 's/on/forward/' annoying.txt ##把所有的on换成forward，同时打印出结果。但如果当前行已经替换过一次了，就跳到下一行。所以可能没有替换干净

sed 's/on/forward/g' annoying.txt ## 加上g就好了
sed 's/on/forward/2' annoying.txt ##每一行只替换第二个匹配上的
sed -n 's/on/forward/2p' annoying.text ## n是supress自动print，只打印出哪些被换了的
sed 's/SINGING/saying/i' annoying.txt ##希望大小写不敏感
sed 's/^.*at/REPLACED/' annoying.txt ##从每一行的开头到"at"
sed 's/^.*at/(&)/' annoying.txt ## 把那些会匹配上的文字用括号包起来

[intermediate traning](https://www.digitalocean.com/community/tutorials/intermediate-sed-manipulating-streams-of-text-in-a-linux-environment)






