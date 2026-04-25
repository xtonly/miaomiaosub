#!/bin/bash

# 定义安装路径
INSTALL_PATH="/opt/miaomiaowu"
mkdir -p $INSTALL_PATH/mmw-data $INSTALL_PATH/subscribes $INSTALL_PATH/rule_templates
cd $INSTALL_PATH

echo -e "\033[32m正在从 GHCR 拉取官方最新镜像...\033[0m"

# 1. 停止并删除旧容器（如果存在）
docker stop miaomiaowu &>/dev/null
docker rm miaomiaowu &>/dev/null

# 2. 运行官方镜像
# 增加了 --restart always 保证开机自启
docker run -d \
  --user root \
  --name miaomiaowu \
  --restart always \
  -p 8080:8080 \
  -v $INSTALL_PATH/mmw-data:/app/data \
  -v $INSTALL_PATH/subscribes:/app/subscribes \
  -v $INSTALL_PATH/rule_templates:/app/rule_templates \
  -e JWT_SECRET=$(date +%s%N | md5sum | head -c 16) \
  ghcr.io/iluobei/miaomiaowu:latest

# 3. 检查结果
if [ $? -eq 0 ]; then
    IP_ADDR=$(curl -s ifconfig.me)
    echo -e "\n\033[1;32m======================================\033[0m"
    echo -e "\033[1;32m        喵喵屋 (GHCR版) 安装成功！    \033[0m"
    echo -e "\033[1;32m======================================\033[0m"
    echo -e "管理面板地址: \033[1;34mhttp://${IP_ADDR}:8080\033[0m"
    echo -e "数据目录: $INSTALL_PATH"
    echo -e "提示: 如果打不开，请检查防火墙是否放行 8080 端口"
    echo -e "\033[1;32m======================================\033[0m"
else
    echo -e "\033[31m安装失败，请检查是否能连接 ghcr.io\033[0m"
fi
