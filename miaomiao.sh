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
    echo -e "${BLUE}    妙妙屋 (MiaoMiaoWu) 管理脚本  3.4     ${NC}"
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
    echo -e "${YELLOW}第一步：正在安装必要工具 (lsof/psmisc)...${NC}"
    apt-get update &>/dev/null && apt-get install -y lsof psmisc &>/dev/null

    echo -e "${YELLOW}第二步：深度清理 18080 端口...${NC}"
    
    # 1. 尝试停止 Docker 冲突容器
    docker stop miaomiaowu &>/dev/null && docker rm miaomiaowu &>/dev/null
    
    # 2. 暴力解决：直接通过端口号杀死所有进程
    # 获取占用 18080 的进程 PID 并强制杀掉
    PIDS=$(lsof -t -i:18080)
    if [ ! -z "$PIDS" ]; then
        echo -e "${RED}检测到端口 18080 被进程 $PIDS 占用，正在强制粉碎...${NC}"
        kill -9 $PIDS &>/dev/null
        sleep 1
    fi

    # 3. 二次检查确保端口空闲
    if lsof -i:18080 > /dev/null; then
        echo -e "${RED}错误：端口 18080 无法释放！请检查是否为系统核心服务。${NC}"
        read -n 1 -s -r -p "按任意键返回菜单..."
        return
    fi

    echo -e "${YELLOW}第三步：启动喵喵屋容器...${NC}"
    mkdir -p $INSTALL_PATH/mmw-data $INSTALL_PATH/subscribes $INSTALL_PATH/rule_templates
    
    docker run -d \
      --user root \
      --name miaomiaowu \
      --restart always \
      -p 0.0.0.0:18080:8080 \
      -v $INSTALL_PATH/mmw-data:/app/data \
      -v $INSTALL_PATH/subscribes:/app/subscribes \
      -v $INSTALL_PATH/rule_templates:/app/rule_templates \
      -e JWT_SECRET=$(date +%s%N | md5sum | head -c 16) \
      ghcr.io/iluobei/miaomiaowu:latest

    if [ $? -eq 0 ]; then
        IPV4=$(curl -s4 ifconfig.me)
        echo -e "\n${GREEN}========================================${NC}"
        echo -e "${GREEN} 妙妙屋 3.4 部署成功！        ${NC}"
        echo -e " 访问地址: ${BLUE}http://${IPV4}:18080${NC} "
        echo -e "${GREEN}========================================${NC}"
    else
        echo -e "${RED}启动失败，可能是 Docker 守护进程异常。${NC}"
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
