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

# 主菜单函数
show_menu() {
    clear
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}      喵喵屋 (MiaoMiaoWu) 管理脚本     ${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo -e "${GREEN} 1.${NC} 安装/更新 喵喵屋 (纯净 IPv4 版)"
    echo -e "${RED} 2.${NC} 彻底卸载 喵喵屋 (清理所有数据)"
    echo -e "${YELLOW} 3.${NC} 重启服务"
    echo -e "${BLUE} 4.${NC} 查看实时运行日志"
    echo -e "${GREEN} 0.${NC} 退出脚本"
    echo -e "${BLUE}======================================${NC}"
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

# 1. 安装函数
install_mmw() {
    echo -e "${GREEN}开始安装/更新...${NC}"
    mkdir -p $INSTALL_PATH/mmw-data $INSTALL_PATH/subscribes $INSTALL_PATH/rule_templates
    
    docker stop miaomiaowu &>/dev/null
    docker rm miaomiaowu &>/dev/null
    
    # 绑定 0.0.0.0 强制 IPv4
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
        IPV4=$(curl -4 -s ifconfig.me)
        echo -e "\n${GREEN}部署成功！${NC}"
        echo -e "访问地址: ${BLUE}http://${IPV4}:8080${NC}"
    else
        echo -e "${RED}部署失败，请检查 Docker 是否正常运行或端口是否被占用。${NC}"
    fi
    read -n 1 -s -r -p "按任意键返回菜单..."
    show_menu
}

# 2. 卸载函数 (二级确认)
uninstall_mmw() {
    echo -e "${RED}警告：此操作将删除所有配置、数据库和镜像！${NC}"
    read -p "确定要彻底卸载吗？(y/n): " confirm
    if [[ $confirm == [yY] ]]; then
        echo "正在清理容器..."
        docker stop miaomiaowu &>/dev/null
        docker rm miaomiaowu &>/dev/null
        echo "正在清理镜像..."
        docker rmi ghcr.io/iluobei/miaomiaowu:latest &>/dev/null
        echo "正在清理本地数据..."
        rm -rf $INSTALL_PATH
        echo -e "${GREEN}卸载完成！${NC}"
    else
        echo "已取消卸载。"
    fi
    read -n 1 -s -r -p "按任意键返回菜单..."
    show_menu
}

# 3. 重启函数
restart_mmw() {
    echo "正在重启喵喵屋..."
    docker restart miaomiaowu &>/dev/null
    echo -e "${GREEN}重启成功！${NC}"
    sleep 2
    show_menu
}

# 4. 日志函数
view_logs() {
    echo -e "${YELLOW}正在查看日志 (按 Ctrl+C 退出)...${NC}"
    docker logs -f miaomiaowu
}

# 启动脚本
show_menu
