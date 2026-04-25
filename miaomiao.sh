#!/bin/bash

INSTALL_PATH="/opt/miaomiaowu"
mkdir -p $INSTALL_PATH/mmw-data $INSTALL_PATH/subscribes $INSTALL_PATH/rule_templates
cd $INSTALL_PATH

# 1. 强制清理旧容器（解决端口占用问题）
docker stop miaomiaowu &>/dev/null
docker rm miaomiaowu &>/dev/null

# 2. 运行官方镜像 (明确绑定 IPv4 0.0.0.0)
docker run -d \
  --user root \
  --name miaomiaowu \
  --restart always \
  -p 0.0.0.0:8080:8080 \
  -v $INSTALL_PATH/mmw-data:/app/data \
  -v $INSTALL_PATH/subscribes:/app/subscribes \
  -v $INSTALL_PATH/rule_templates:/app/rule_templates \
  -e JWT_SECRET=$(date +%s%N | md5sum | head -c 16) \
  ghcr.io/iluobei/miaomiaowu:latest

# 3. 结果展示
if [ $? -eq 0 ]; then
    IPV4=$(curl -4 -s ifconfig.me)
    echo -e "\n\033[1;32m======================================\033[0m"
    echo -e "\033[1;32m       喵喵屋 (IPv4纯净版) 部署成功！ \033[0m"
    echo -e "\033[1;32m======================================\033[0m"
    echo -e "访问地址: \033[1;34mhttp://${IPV4}:8080\033[0m"
    echo -e "数据路径: $INSTALL_PATH"
    echo -e "\033[1;32m======================================\033[0m"
else
    echo -e "\033[31m启动失败，请检查 8080 端口是否被其他非 Docker 程序占用\033[0m"
fi
