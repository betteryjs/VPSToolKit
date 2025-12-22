#!/usr/bin/env bash

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: VPSToolKit 一键安装脚本
#	Version: 2.0.0
#	Author: VPSToolKit Contributors
#=================================================

set -e

# 配置变量
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/vpstoolkit"
MODULES_DIR="${CONFIG_DIR}/modules.d"
MAIN_SCRIPT="vtk"
DOWNLOAD_SOURCE=""

# 颜色定义
Green="\033[32m"
Red="\033[31m"
Yellow="\033[0;33m"
Reset="\033[0m"
Info="${Green}[信息]${Reset}"
Error="${Red}[错误]${Reset}"
Success="${Green}[成功]${Reset}"

# 检查 Root 权限
check_root() {
	if [[ $EUID != 0 ]]; then
		echo -e "${Error} 当前账号非 ROOT，无法继续操作，请使用 sudo su 获取临时 ROOT 权限。"
		exit 1
	fi
}

# 检测系统类型
check_system() {
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif grep -q -E -i "debian" /etc/issue; then
		release="debian"
	elif grep -q -E -i "ubuntu" /etc/issue; then
		release="ubuntu"
	elif grep -q -E -i "centos|red hat|redhat" /etc/issue; then
		release="centos"
	elif grep -q -E -i "debian" /proc/version; then
		release="debian"
	elif grep -q -E -i "ubuntu" /proc/version; then
		release="ubuntu"
	elif grep -q -E -i "centos|red hat|redhat" /proc/version; then
		release="centos"
	fi
}

# 选择下载源
select_download_source() {
	clear
	echo -e "
========================================
    选择下载源
========================================

${Green}1.${Reset} OSS CDN (国内推荐)
   https://oss.naloong.de/VPSToolKit

${Green}2.${Reset} GitHub Raw (国外推荐)
   https://raw.githubusercontent.com

========================================
"
	read -e -p " 请选择下载源 [1-2]：" source_choice
	
	case "$source_choice" in
		1)
			DOWNLOAD_SOURCE="oss"
			BASE_URL="https://oss.naloong.de/VPSToolKit"
			echo -e "${Info} 已选择 OSS CDN 下载源"
			;;
		2)
			DOWNLOAD_SOURCE="github"
			BASE_URL="https://raw.githubusercontent.com/betteryjs/VPSToolKit/master"
			echo -e "${Info} 已选择 GitHub Raw 下载源"
			;;
		*)
			echo -e "${Info} 输入错误，默认使用 OSS CDN"
			DOWNLOAD_SOURCE="oss"
			BASE_URL="https://oss.naloong.de/VPSToolKit"
			;;
	esac
	
	sleep 1
}

# 安装依赖
install_dependencies() {
	echo -e "${Info} 正在安装依赖..."
	if [[ ${release} == "centos" ]]; then
		yum install -y wget curl
	else
		apt-get update
		apt-get install -y wget curl
	fi
}

# 创建目录结构
create_directories() {
	echo -e "${Info} 创建目录结构..."
	mkdir -p "${CONFIG_DIR}"
	mkdir -p "${MODULES_DIR}"
	echo -e "${Success} 目录结构创建完成！"
}

# 下载配置文件
download_config_files() {
	echo -e "${Info} 正在下载配置文件..."
	
	# 下载模块配置文件
	wget --no-check-certificate -q -O "${MODULES_DIR}/menu.toml" "${BASE_URL}/modules.d/menu.toml"
	wget --no-check-certificate -q -O "${MODULES_DIR}/proxy.toml" "${BASE_URL}/modules.d/proxy.toml"
	wget --no-check-certificate -q -O "${MODULES_DIR}/system.toml" "${BASE_URL}/modules.d/system.toml"
	wget --no-check-certificate -q -O "${MODULES_DIR}/tools.toml" "${BASE_URL}/modules.d/tools.toml"
	
	# 保存下载源配置
	echo "export VTK_DOWNLOAD_SOURCE=${DOWNLOAD_SOURCE}" > "${CONFIG_DIR}/env"
	
	# 保存版本号
	echo "2.0.0" > "${CONFIG_DIR}/version"
	
	echo -e "${Success} 配置文件下载完成！"
}

# 下载主脚本
download_main_script() {
	echo -e "${Info} 正在下载主脚本..."
	
	# 下载 vtk 主脚本
	wget --no-check-certificate -q -O "${INSTALL_DIR}/${MAIN_SCRIPT}" "${BASE_URL}/vtk"
	chmod +x "${INSTALL_DIR}/${MAIN_SCRIPT}"
	
	# 下载 menu.sh 菜单脚本
	wget --no-check-certificate -q -O "${CONFIG_DIR}/menu.sh" "${BASE_URL}/menu.sh"
	chmod +x "${CONFIG_DIR}/menu.sh"
	
	# 创建软链接
	ln -sf "${INSTALL_DIR}/${MAIN_SCRIPT}" "${INSTALL_DIR}/m"
	
	echo -e "${Success} 主脚本下载完成！"
}

# 显示使用说明
show_usage() {
	clear
	echo -e "
========================================
    VPSToolKit 安装完成！
========================================

${Green}使用方法：${Reset}

1. 运行主菜单：
   ${Yellow}vtk${Reset} 或 ${Yellow}m${Reset}

${Green}功能列表：${Reset}

代理服务管理：
  - AnyTLS
  - Shadowsocks
  - Trojan-Go
  - Snell v4/v5

系统工具：
  - BBR 加速
  - DD 重装系统

实用工具：
  - Speedtest 测速

${Green}配置文件位置：${Reset}
  ${CONFIG_DIR}/modules.d/*.toml

${Green}项目地址：${Reset}
  https://github.com/betteryjs/VPSToolKit

========================================
感谢使用 VPSToolKit！
========================================
"
}

# 主函数
main() {
	clear
	echo -e "
========================================
    VPSToolKit 安装脚本
    版本: 2.0.0
========================================
"
	
	check_root
	check_system
	select_download_source
	install_dependencies
	create_directories
	download_config_files
	download_main_script
	show_usage
}

main
