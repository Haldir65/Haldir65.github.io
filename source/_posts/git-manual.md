---
title: git常用操作手册
date: 2016-09-27 17:24:51
categories: blog
tags: [git,tools]
---

记录一下常用git的命令，作为日常使用的参考手册

![](http://www.haldir66.ga/static/imgs/f787b2e8d757dc83b782bcd6d4c9f523.jpg)

<!--more-->

## 1. 在本地创建一个项目并同步到github的过程

```git
$ mkdir ~/hello-world    //创建一个项目hello-world
$ cd ~/hello-world       //打开这个项目
$ git init             //初始化
$ touch README   		//创建文件
$ git add README        //更新README文件
$ git commit -m 'first commit'     //提交更新，并注释信息“first commit”
$ git remote add origin git@github.test/hellotest.git     //连接远程github项目  
$ git push -u origin master     //将本地项目更新到github项目上去
```

## 2.  将本地git branch和远程github repository同步

可行的方式
```git
git branch --set-upstream local_branch origin/remote_branch
```
这样做可行，但出现下面的错误提示，照着操作就行了。

```git
$ git branch --set-upstream master origin/master
The --set-upstream flag is deprecated and will be removed. Consider using --track or --set-upstream-to
Branch master set up to track remote branch master from origin.
```

直接拿下面这段就行了
**如果已经clone下来，想要在本地创建一个和远程分支对应的local分支。**
> git branch --track dev origin/dev && git chekout dev


## 3. git处理大小写字母的问题

> git默认对大小写不敏感，所以，新建一个文件adapter.java，上传到github之后说不定就给变成了Adapter.java。在windows下面将已经push到远端的文件，改变其文件名的大小写时，git默认会认为文件没有发生任何改动，从而拒绝提交和推送，原因是其默认配置为大小写不敏感，故须在bash下修改配置：

```git
git config core.ignorecase false
```

## 4. git设置用户名

```git
$ git config --global user.name "name"
$ git config --global user.email xxx@163.com
```
这样可以为git所有的仓库设置用户名，如果想为指定仓库设置用户名或email:

```git
$ git config user.name "name"
$ git config user.email "myEmail.awesome.com"
```
查看当前用户名或email
```git
$ git config user.name
$ git config user.email
```

## 5. 设置代理

只针对当前项目设置代理
```git
git config  http.proxy socks5://127.0.0.1:1080
git config  https.proxy socks5://127.0.0.1:1080
```

设置全局代理
```git
git config --global http.proxy socks5://127.0.0.1:1080
git config --global https.proxy socks5://127.0.0.1:1080
```

取消设置
```shell
git config --global --unset http.proxy

git config --global --unset https.proxy
```

### 对指定url设置代理
git config --global http.<要设置代理的URL>.proxy socks5://127.0.0.1:1080

git config --global http.https://github.com.proxy socks5://127.0.0.1:1080


## 6. 对上一次commit进行修改(在不添加新的commit的基础上)
```git
git commit --amend
```

## 7. git revert和reset的区别
> reset 是在正常的commit历史中,删除了指定的commit,这时 HEAD 是向后移动了,而 revert 是在正常的commit历史中再commit一次,只不过是反向提交,他的 HEAD 是一直向前的. 即reset是通过一次反向的commit操作撤销之前的commit，而reset则会直接从提交历史里删除commit。如果还没有push，用reset可以在本地解决问题，之后重新commit再push。如果已经push，可以考虑通过一次revert来实现“撤销”的效果。


语法：
### reset
```git
git reset --hard HEAD //本地仓库文件修改也会消失
git reset --soft HEAD //本地文件修改不会消失，类似于回到git add 之前的状态(把绿色的改成红色)
git reset --hard HEAD~3 //最近的三次提交全部撤销
git reset --soft HEAD~ //把最近一次本地提交撤销，上次提交的文件修改还在，等于变成红色的状态
```

[如何撤销最近一次本地提交](https://stackoverflow.com/questions/927358/how-to-undo-the-most-recent-commits-in-git)
```
$ git commit -m "Something terribly misguided"             # (1)
$ git reset HEAD~                                          # (2)
<< edit files as necessary >>                              # (3)
$ git add ...                                              # (4)
$ git commit -c ORIG_HEAD                                  # (5)
```
ORIG_HEAD意思是把上一次的commit message带上，同时提供一个editor供修改

### revert
```git
git revert c011eb3c20ba6fb38cc94fe //之后在分支图上就能看到一个新的反向的commit，push即可。
```

## 8. 切分支, 删除分支
本地新建分支
```git
git checkout -b <branchName>
```
将这条分支与远程同步的方式
```git
git branch --set-upstream <laocalBranchName> origin/<RemoteBranchName>
// 或者
git branch -u origin/dev
```
直接从远程仓库切一个分支出来并保持同步的方式
```git
git checkout -b <branchName> origin/<branchName>

git checkout --track origin/dev
```


删除远程分支:
```git
git push origin --delete <branchName>
```
删除远程tag
```git
git push origin --delete tag <tagName>
```
顺便说一下[打tag](http://blog.csdn.net/wangjia55/article/details/8793577)，这个实在太简单
```git
git tag //看下当前仓库有哪些tags
git tag myTag // 在当前head打一个myTag的标签
git push origin myTag //刚才那个tag还只是在本地，需要提交到远程
git checkout myTag //打tag的好处就在于埋下一个里程碑，你随时可以回到当时的状态
git tag -d myTag //删除这个tag也很简单
git tag -a myTag adjksdas31231//假如当前head不在想打的位置，找到想打的位置的log，照着打就好
git push origin -tags //将本地所有标签一次性提交到git服务器
git ls-remote --tags origin //查看远程仓库所有的tags
```

## 9. pull和rebase的区别
pull = fetch +merge ，会生成新的提交

> Merge好在它是一个安全的操作。现有的分支不会被更改，避免了rebase潜在的缺点

## 10. rebase和cherry-pick
rebase不会生成新的提交，而且会使得项目提交历史呈现出完美的线性。但注意[不要在公共的分支上使用](https://github.com/geeeeeeeeek/git-recipes/wiki/5.1-%E4%BB%A3%E7%A0%81%E5%90%88%E5%B9%B6%EF%BC%9AMerge%E3%80%81Rebase%E7%9A%84%E9%80%89%E6%8B%A9)



## 11. gitignore文件写法
参考[repo](https://github.com/suzeyu1992/repo/tree/master/project/git)
```git
# 忽略所有以 .c结尾的文件
*.c

# 但是 stream.c 会被git追踪
!stream.c

# 只忽略当前文件夹下的TODO文件, 不包括其他文件夹下的TODO例如: subdir/TODO
/TODO

# 忽略所有在build文件夹下的文件
build/

# 忽略 doc/notes.txt, 但不包括多层下.txt例如: doc/server/arch.txt
doc/*.txt

# 忽略所有在doc目录下的.pdf文件
doc/**/*.pdf

# 让ignore文件立即生效的方法（如果不该上传到服务器的东西已经上传了，本次提交会把这些不该上传的东西从服务器删掉）
git rm -r --cached .
git add .
git commit -m ".gitignore is now working"
```

## 12. git stash
常用命令
```git
git stash  //保存下来，压进一个栈，基本上就是先进后出了
git stash pop //推出一个栈

git stash save -a "message to add" // 添加一次stash，打上标记

git stash list  //展示当前仓库所有的被stash的变更以及对应的id，记得这个不是跟着branch走的
git stash drop stah@{id} // 从stash的List中删除指定的某一次stash
git stash apply <stash@{id}> //应用某一次的stash

git stash clear// 一次性删除stash List中所有的item

```

## 13. 强推
谨慎使用
```git
# Be very careful with this command!
git push --force
```

## 14.既然是shell环境，那当然可以写bash 脚本
> git add . && git commit -m "stuff" && git push
### 一部搞定，前提是每一步都得成功，原理就是bash脚本的&&和||操作符。

## 15. git-error-please-make-sure-you-have-the-correct-access-rights-and-the-reposito
总会有不小心的时候把本地的sshkey干掉了，解决方法就是本地生成sshkey，然后粘贴到你的github或者gitlab网站上
> ssh-keygen ## 这个基本上在网上都能找到，可以传参数，生成的文件名，密码什么的
> cat ~/.ssh/id_rsa.pub | clip ## 中间的管道是把内容搞到剪切板上，clip是windows上的命令
> 去粘贴吧

[一台电脑上存储两个github账号的ssh的方式]()
> $ cd ~/.ssh
$ ssh-keygen -t rsa -C "your_email@associated_with_githubPersonal.com"
### save it as id_rsa_personal when prompted
> $ ssh-keygen -t rsa -C "your_email@associated_with_githubWork.com"
### save it as id_rsa_work when prompted

由此创建四个文件：
id_rsa_personal
id_rsa_personal.pub ## 这里面的内容是要粘到github账户setting里面的
id_rsa_work
id_rsa_work.pub

touch config，添加如下内容
```config
#githubPersonal
Host personal
   HostName github.com
   User git
   IdentityFile ~/.ssh/id_rsa_personal

# githubWork
Host work
   HostName github.com
   User git
   IdentityFile ~/.ssh/id_rsa_work
```
另外,确保只有owner有读写权限chmod 600 ~/.ssh/config

error:Could not open a connection to your authentication agent.
> ssh-agent bash

ssh-add -D
一台电脑上同时要添加github和gitlab的权限，或者一台电脑上要同时添加两个github账户的权限
> ssh-keygen -t rsa -C "your_email@youremail.com"
$ ssh-add id_rsa_personal
$ ssh-add id_rsa_work
ssh-add -l
ssh -Tv personal
ssh -Tv work
似乎这样就行了，就可以用git@xxxx去clone并且push了（记得在github账户的setting里面把.pub文件里面的内容粘贴进去）

[如何避免每次都得输入ssh-add id_rsaxxx的现象](https://stackoverflow.com/questions/3466626/add-private-key-permanently-with-ssh-add-on-ubuntu) 
手动将clone下来的Git仓库的origin改成下面这种是可以的

然后每次clone的时候，不能用
> git clone git@github.com:gothinkster/node-express-realworld-example-app.git
> git clone git@personal:gothinkster/node-express-realworld-example-app.git ### 改成这样就好啦

[Error: Permission denied (publickey)的解决方案](https://help.github.com/articles/error-permission-denied-publickey/)
ssh -vT git@github.com ## 会输出详细的信息
[multiple github account](https://stackoverflow.com/questions/3225862/multiple-github-accounts-ssh-config)
[Digital ocean关于.ssh/config文件的解释非常好](https://www.digitalocean.com/community/tutorials/how-to-configure-custom-connection-options-for-your-ssh-client)

[详细的关于如何用ssh管理多个github账户的教程](http://mherman.org/blog/2013/09/16/managing-multiple-github-accounts/)

## 16. 空目录推送到远端
常常在node项目中看到一个static文件夹，里面只有一个.gitkeep文件，这个文件的意思是，就算这个目录是空的，也得推送到远端。

## 17. stale和prune的概念
prune(stale的概念 - 一个原本分支叫做dev，远程叫origin/dev，如果删除了dev，合到master，提交到origin/master之后，远程的origin/dev就成了stale的了)
man prune是这么说的：
> Deletes all stale tracking branches under <name>.
These stale branches have already been removed from the remote repository
referenced by <name>, but are still locally available in "remotes/<name>".

prune的[解释](https://stackoverflow.com/questions/4040717/git-remote-prune-didnt-show-as-many-pruned-branches-as-i-expected)

### 一些看上去很神奇的操作
git clone --depth=50 --branch=branchName https://github.com/XXX/XXX.git myFolder/theNameIwantItToBe

git -c core.quotepath=false push --progress --porcelain origin refs/heads/master:master // idea内置git push操作实际执行了这一行指令

git fetch -v

git submodule update --init ## 比如说shadowsocks工程

我也是才发现，windows下的git bash集成了openssh，curl，好用的不行

git branch -r 有时候不显示所有的remote branch，亲测，remove掉origin，重新添加然后fetch就好了

git 统计commiter人数
> git log --pretty='%aN' | sort -u | wc -l
git log --oneline | wc -l ### 提交总数统计
git log --pretty='%aN' | sort | uniq -c | sort -k1 -n -r | head -n 5 ###查看仓库提交者排名前 5

查看最近一次commit都改了什么
> git diff HEAD~1 HEAD

git log
[](https://www.atlassian.com/git/tutorials/git-logAdvanced git log)
> git log --pretty=format:"%cn committed %h on %cd"
git log --oneline
git log --stat ## 显示出每一次commit的，以及每一次commit都改了哪些文件
git log -v ##这个更啰嗦 ## 比stat多出了每次更改之后修改的文件内容
git log --graph --oneline --decorate
git log --pretty=format:"%cn committed %h on %cd" | awk '{ print $8}' | sort -n ##结合awk可以看到最晚几点commit，比如凌晨1点还在commit的.[format里面的参数在man git log page可以找到](https://mirrors.edge.kernel.org/pub/software/scm/git/docs/git-log.html#_pretty_formats)
git log --after="2014-7-1" --before="2014-7-4" ## 还可以查看某个日期之间提交的东西
git log --author="John"
git log --author="John\|Mary" ## John或者Mary的
git log --grep="JRA-224:" ## 从commit message里面查找
git log -- foo.py bar.py ## 查看跟这几个文件相关的操作记录
git log -S"Hello, World!" ##这个等于查找git log -p里面哪一次提交添加了“Hello, World！”这句话
git log --no-merges
git log --merges
git log --pretty=format:"%h%x09%an%x09%ad%x09%s" //非常简明的一行显示

## Reference
-[git reset和revert](http://yijiebuyi.com/blog/8f985d539566d0bf3b804df6be4e0c90.html)
-[git recipes](https://github.com/geeeeeeeeek/git-recipes)
