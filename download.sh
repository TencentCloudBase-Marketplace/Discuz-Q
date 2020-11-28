#!/bin/bash -e

mkdir -p source
cd source
curl https://dl.discuz.chat/discuz_web_latest.zip -o discuz_web_latest.zip
unzip discuz_web_latest.zip
# 下载h5代码
curl https://dl.discuz.chat/uniapp_latest.zip -o uniapp_latest.zip
unzip uniapp_latest.zip

# 下载并解压 DQ 后台程序代码
curl https://dl.discuz.chat/dzq_latest_install.zip -o dzq_latest_install.zip
unzip dzq_latest_install.zip -d dzq_latest_install