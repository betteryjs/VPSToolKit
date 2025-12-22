#!/usr/bin/env bash

# Speedtest 管理脚本

# 显示菜单
echo "=========================================="
echo "      Speedtest 一键管理脚本"
echo "=========================================="
echo "请选择操作："
echo "1. 安装 Speedtest"
echo "2. 卸载 Speedtest"
echo "=========================================="
read -p "请输入选项 [1-2]: " choice

# 验证输入
if [[ ! "$choice" =~ ^[1-2]$ ]]; then
    echo "错误：无效的选项，请输入1或2"
    exit 1
fi

# 根据选择执行相应的操作
echo ""
echo "=========================================="

case $choice in
    1)
        echo "开始安装 Speedtest..."
        echo "=========================================="
        apt-get install curl -y
        curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash
        apt-get install speedtest -y
        echo ""
        echo "=========================================="
        echo "Speedtest 安装完成！"
        echo "使用命令 'speedtest' 进行测速"
        echo "=========================================="
        ;;
    2)
        echo "开始卸载 Speedtest..."
        echo "=========================================="
        rm -rf /etc/apt/sources.list.d/speedtest.list
        apt-get update
        apt-get remove speedtest -y
        apt-get remove speedtest-cli -y
        apt-get autoremove -y
        echo ""
        echo "=========================================="
        echo "Speedtest 卸载完成！"
        echo "=========================================="
        ;;
esac
