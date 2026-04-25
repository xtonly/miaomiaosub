#!/bin/bash

# 检查 root 权限
[[ $EUID -ne 0 ]] && echo -e "\033[31m请使用 root 用户运行此脚本\033[0m" && exit 1

echo -e "\033[32m正在开始安装 喵喵屋 (MiaoMiaoWu) Docker 环境...\033[0m"

# 1. 安装 Docker 和 Docker-compose (如果尚未安装)
if ! command -v docker &> /dev/null; then
    echo "正在安装 Docker..."
    curl -fsSL https://get.docker.com | bash -s docker
    systemctl start docker
    systemctl enable docker
fi

# 2. 创建工作目录
mkdir -p /opt/miaomiaowu && cd /opt/miaomiaowu

# 3. 创建 docker-compose.yml
# 参考原项目结构，配置前端、后端和 Redis/MySQL（视具体镜像版本而定）
cat <<EOF > docker-compose.yml
version: '3'
services:
  miaomiaowu:
    image: iluobei/miaomiaowu:latest
    container_name: miaomiaowu
    restart: always
    ports:
      - "8080:80"
    volumes:
      - ./data:/app/data
    environment:
      - NODE_ENV=production
EOF

# 4. 启动容器
docker compose up -d

# 5. 完成提示
IP_ADDR=$(curl -s ifconfig.me)
echo -e "\n\033[32m======================================\033[0m"
echo -e "\033[32m        喵喵屋 安装成功！             \033[0m"
echo -e "\033[32m======================================\033[0m"
echo -e "管理面板地址: \033[1;34mhttp://${IP_ADDR}:8080\033[0m"
echo -e "默认初始账号/密码请参考项目文档 (通常为 admin/123456)"
echo -e "配置文件存放路径: /opt/miaomiaowu"
echo -e "\033[32m======================================\033[0m"
