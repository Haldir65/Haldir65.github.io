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

TEMP_DIR="$(mktemp -d)/Haldir65.github.io"
# 先 clone 再 commit，避免直接 force commit
git clone --depth=50 --branch=master git@github.com:Haldir65/Haldir65.github.io.git ${TEMP_DIR}

ls -al ./public

cd ./public

# rm -rf * ~/Haldir65/Haldir65.github.io
# mv  * -f  ~/Haldir65/Haldir65.github.io

cp -TRv ./ ${TEMP_DIR}

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

cd ${TEMP_DIR}

## removing irrelevant js and css file , this should be done in webpack

ALL_JS_FILES=$(ls ${TEMP_DIR}/*.js | xargs -n 1 basename)
for f in ${ALL_JS_FILES}; do
    echo "${f}"
    if [ ! "$(grep -w ${f} "${TEMP_DIR}/index.html" )" ]; then
        rm ${TEMP_DIR}/${f}
        echo "js file ${f} not relevant, removing it\n\n"
    fi
done

ALL_CSS_FILE=$(ls ${TEMP_DIR}/*.css | xargs -n 1 basename)
for f in ${ALL_CSS_FILE}; do
    echo "${f}"
    if [ ! "$(grep -w ${f} "${TEMP_DIR}/index.html" )" ]; then
        rm ${TEMP_DIR}/${f}
        echo "css file ${f} not relevant , delete it\n\n"
    fi
done



##git status

if [ -z "$(git status --porcelain)" ]; then 
  # Working directory clean
    echo "Working directory clean"
else 
    echo "something has changed"
    git add .
    # git commit -m "Site updated on: `date +"%Y-%m-%d %H:%M:%S"`"
    git commit -m "${msg}"
    git status
    git push origin master
    echo "end of push"
fi

rm -rf ${TEMP_DIR}



# # 同时 push 一份到自己的服务器上
# git remote add vps git@prinzeugen.net:hexo.git
#
# git push vps master:master --force --quiet
# git push origin master:master --force --quiet
