#!/bin/bash
# set -ev
export TZ='Asia/Shanghai'

echo "begin of prebuild ,ensure we have those js files in source dir"

THEMES_DIR="themes/yilia"

if [ -d $THEMES_DIR ];then
    cd $THEMES_DIR
    if ls source/*.js 1> /dev/null 2>&1; then
        ls source/*.js
        echo "skip because js files do exist"
    else
        echo "js files do not exist,try to build"
        npm dist
        ls -al source
    fi
else
    echo $THEMES_DIR" doest not exists"    
fi


echo "end of prebuild"

