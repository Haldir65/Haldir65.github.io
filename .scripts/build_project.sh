#!/bin/bash
set -ev

echo "show current info"

node --version
npm --version


rm -rf node_modules && npm install --force
npm install -g hexo-cli@3.1.0

hexo version
hexo clean
hexo generate

tree -L 4
