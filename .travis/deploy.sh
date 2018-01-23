#!/bin/bash
set -ev
export TZ='Asia/Shanghai'

echo "begin of clone static repo"
# 先 clone 再 commit，避免直接 force commit
git clone --depth=50 --branch=master git@github.com:Haldir65/Haldir65.github.io.git ~/Haldir65/Haldir65.github.io

ls -al ./public

cd ./public

# rm -rf * ~/Haldir65/Haldir65.github.io
# mv  * -f  ~/Haldir65/Haldir65.github.io

cp -TRv ./ ~/Haldir65/Haldir65.github.io

touch ~/Haldir65/Haldir65.github.io/index.html
cat ./public/archives/index.html > ~/Haldir65/Haldir65.github.io/index.html


ls -al ~/Haldir65/Haldir65.github.io

cat ~/Haldir65/Haldir65.github.io/index.html

cd ~/Haldir65/Haldir65.github.io

git status
git add .
git commit -m "Site auto updated: `date +"%Y-%m-%d %H:%M:%S"`"
git status
echo "end of commit"

git push origin master

echo "end of push"

# # 同时 push 一份到自己的服务器上
# git remote add vps git@prinzeugen.net:hexo.git
#
# git push vps master:master --force --quiet
# git push origin master:master --force --quiet
