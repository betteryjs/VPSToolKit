#!/bin/bash

# 一键DD脚本 - Debian 12
# 默认配置
DEFAULT_PORT=22
DEFAULT_OS="debian"
DEFAULT_VERSION=12

# 显示菜单
echo "=========================================="
echo "      一键DD系统安装脚本 - Debian 12"
echo "=========================================="
echo "请选择安装源："
echo "1. GitHub脚本 - 默认源"
echo "2. CloudFlare脚本 - 清华源"
echo "3. CloudFlare脚本 - 阿里源"
echo "=========================================="
read -p "请输入选项 [1-3]: " choice

# 验证输入
if [[ ! "$choice" =~ ^[1-3]$ ]]; then
    echo "错误：无效的选项，请输入1、2或3"
    exit 1
fi

# 配置SSH端口和密码
echo ""
echo "=========================================="
echo "配置系统参数"
echo "=========================================="

# 输入SSH端口（可选，默认22）
read -p "请输入SSH端口 (默认: $DEFAULT_PORT): " input_port
PORT=${input_port:-$DEFAULT_PORT}

# 输入root密码（必填）
while true; do
    read -sp "请输入root密码: " PASSWORD
    echo ""
    if [[ -z "$PASSWORD" ]]; then
        echo "错误：密码不能为空，请重新输入"
        continue
    fi
    read -sp "请再次确认密码: " PASSWORD_CONFIRM
    echo ""
    if [[ "$PASSWORD" == "$PASSWORD_CONFIRM" ]]; then
        break
    else
        echo "错误：两次密码不一致，请重新输入"
    fi
done

echo ""
echo "=========================================="
echo "配置确认："
echo "端口: $PORT"
echo "密码: ********"
echo "系统: Debian $DEFAULT_VERSION"
echo "=========================================="

# 根据选择执行相应的命令
echo ""
echo "=========================================="
echo "开始执行安装..."
echo "=========================================="

case $choice in
    1)
        echo "使用GitHub脚本 - 默认源"
        bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh') -debian $DEFAULT_VERSION -pwd "$PASSWORD" -port $PORT
        ;;
    2)
        echo "使用CloudFlare脚本 - 清华源"
        bash <(wget --no-check-certificate -qO- 'https://oss.naloong.de/sh/InstallNET.sh') -debian $DEFAULT_VERSION -pwd "$PASSWORD" -port $PORT -mirror "https://mirrors.ustc.edu.cn/debian/"
        ;;
    3)
        echo "使用CloudFlare脚本 - 阿里源"
        bash <(wget --no-check-certificate -qO- 'https://oss.naloong.de/sh/InstallNET.sh') -debian $DEFAULT_VERSION -pwd "$PASSWORD" -port $PORT -mirror "https://mirrors.cloud.aliyuncs.com/debian/"
        ;;
esac

echo ""
echo "=========================================="
echo "安装命令已执行！"
echo "系统将在准备完成后自动重启并开始安装"
echo "=========================================="
