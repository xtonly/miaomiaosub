#!/bin/bash

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 定义路径
INSTALL_PATH="/opt/miaomiaowu"

# 检查 root 权限
[[ $EUID -ne 0 ]] && echo -e "${RED}错误：请使用 root 用户运行此脚本！${NC}" && exit 1

show_menu() {
    clear
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${BLUE}    妙妙屋 (MiaoMiaoWu) 管理脚本  3.1     ${NC}"
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${GREEN} 1.${NC} 安装/更新 妙妙屋"
    echo -e "${RED} 2.${NC} 彻底卸载 妙妙屋"
    echo -e "${YELLOW} 3.${NC} 重启服务"
    echo -e "${BLUE} 4.${NC} 查看实时运行日志"
    echo -e "${GREEN} 0.${NC} 退出脚本"
    echo -e "${BLUE}=========================================${NC}"
    read -p "请输入数字选择 [0-4]: " choice
    case $choice in
        1) install_mmw ;;
        2) uninstall_mmw ;;
        3) restart_mmw ;;
        4) view_logs ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选择，请重新输入！${NC}"; sleep 1; show_menu ;;
    esac
}

install_mmw() {
    echo -e "${YELLOW}第一步：正在自动补齐系统工具 (lsof/psmisc)...${NC}"
    # 针对 Debian/Ubuntu 的自动安装
    apt-get update &>/dev/null
    apt-get install -y lsof psmisc &>/dev/null

    echo -e "${YELLOW}第二步：正在强力清空 8080 端口...${NC}"
    # 1. 停止重名容器
    docker stop miaomiaowu &>/dev/null
    docker rm miaomiaowu &>/dev/null

    # 2. 停止任何占用 8080 的 Docker 容器
    CONFLICT_ID=$(docker ps -q --filter "publish=8080")
    if [ ! -z "$CONFLICT_ID" ]; then
        docker stop $CONFLICT_ID &>/dev/null
        docker rm $CONFLICT_ID &>/dev/null
    fi

    # 3. 强制杀死系统级占用进程 (使用刚才装好的 lsof)
    if command -v lsof &> /dev/null; then
        lsof -t -i:8080 | xargs kill -9 &>/dev/null
    fi

    echo -e "${YELLOW}第三步：正在创建目录并启动容器...${NC}"
    mkdir -p $INSTALL_PATH/mmw-data $INSTALL_PATH/subscribes $INSTALL_PATH/rule_templates
    
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

    if [ $? -eq 0 ]; then
        IPV4=$(curl -s4 ifconfig.me)
        echo -e "\n${GREEN}========================================${NC}"
        echo -e "${GREEN} 妙妙屋 3.1 部署成功！        ${NC}"
        echo -e " 访问地址: ${BLUE}http://${IPV4}:8080${NC} "
        echo -e "${GREEN}========================================${NC}"
    else
        echo -e "${RED}部署失败！请检查 Docker 是否正常工作。${NC}"
    fi
    read -n 1 -s -r -p "按任意键返回菜单..."
    show_menu
}

uninstall_mmw() {
    echo -e "${RED}警告：此操作将彻底删除所有数据！${NC}"
    read -p "确定卸载吗？(y/n): " confirm
    if [[ $confirm == [yY] ]]; then
        docker stop miaomiaowu &>/dev/null
        docker rm miaomiaowu &>/dev/null
        docker rmi ghcr.io/iluobei/miaomiaowu:latest &>/dev/null
        rm -rf $INSTALL_PATH
        echo -e "${GREEN}卸载成功，数据已清空。${NC}"
    fi
    read -n 1 -s -r -p "按任意键返回菜单..."
    show_menu
}

restart_mmw() {
    docker restart miaomiaowu &>/dev/null
    echo -e "${GREEN}重启成功！${NC}"
    sleep 2
    show_menu
}

view_logs() {
    echo -e "${YELLOW}正在查看日志 (Ctrl+C 退出)...${NC}"
    docker logs -f miaomiaowu
}

show_menu
