#!/bin/bash
set -ev
export TZ='Asia/Shanghai'

echo "begin of clone static repo"

## this is for string concatenation
##foo="Hello"
##foo="$foo World"
##echo $foo

## this is for how to send outputs of a program into a variable
##OUTPUT="$(ls -1)"
###echo "${OUTPUT}"

### so we want to grab the latest commit msg
msg="$(git log -1 --pretty=%B)"
echo "${msg}"


# 先 clone 再 commit，避免直接 force commit
git clone --depth=50 --branch=master git@github.com:Haldir65/Haldir65.github.io.git ~/Haldir65/Haldir65.github.io

ls -al ./public

cd ./public

# rm -rf * ~/Haldir65/Haldir65.github.io
# mv  * -f  ~/Haldir65/Haldir65.github.io

cp -TRv ./ ~/Haldir65/Haldir65.github.io

# echo "may be cache issue"
# cat ../themes/yilia/_config.yml
#
# echo "start of archive"
# cat ./archives/index.html
#
#
# cat ./archives/index.html > ~/Haldir65/Haldir65.github.io/index.html


# ls -al ~/Haldir65/Haldir65.github.io
#
# echo "start of parent dir"
# cat ~/Haldir65/Haldir65.github.io/index.html

cd ~/Haldir65/Haldir65.github.io

git status
git add .
git commit -m "Site updated on: `date +"%Y-%m-%d %H:%M:%S"`"
# git commit -m ${msg}
git status
echo "end of commit"

git push origin master

echo "end of push"

# # 同时 push 一份到自己的服务器上
# git remote add vps git@prinzeugen.net:hexo.git
#
# git push vps master:master --force --quiet
# git push origin master:master --force --quiet
