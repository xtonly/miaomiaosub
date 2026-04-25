#!/bin/bash

# 定义安装路径
INSTALL_PATH="/opt/miaomiaowu"
mkdir -p $INSTALL_PATH/mmw-data $INSTALL_PATH/subscribes $INSTALL_PATH/rule_templates
cd $INSTALL_PATH

echo -e "\033[32m正在检查并启动 喵喵屋 官方容器...\033[0m"

# 1. 停止并删除旧容器（为了应用最新的网络配置输出）
docker stop miaomiaowu &>/dev/null
docker rm miaomiaowu &>/dev/null

# 2. 运行官方镜像
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

# 3. 获取双栈 IP 地址
IPV4_ADDR=$(curl -4 -s ifconfig.me || echo "未检测到公网IPv4")
IPV6_ADDR=$(curl -6 -s ifconfig.me || echo "未检测到公网IPv6")

# 4. 结果展示
echo -e "\n\033[1;32m================================================\033[0m"
echo -e "\033[1;32m         喵喵屋 (双栈支持) 部署完成！           \033[0m"
echo -e "\033[1;32m================================================\033[0m"
echo -e "IPv4 访问地址: \033[1;34mhttp://${IPV4_ADDR}:8080\033[0m"
if [[ "$IPV6_ADDR" != *"未检测到"* ]]; then
    echo -e "IPv6 访问地址: \033[1;34mhttp://[${IPV6_ADDR}]:8080\033[0m"
fi
echo -e "------------------------------------------------"
echo -e "数据路径: $INSTALL_PATH"
echo -e "\033[1;33m提示：IPv6 访问需在浏览器地址栏带上中括号 [ ]\033[0m"
echo -e "\033[1;32m================================================\033[0m"
