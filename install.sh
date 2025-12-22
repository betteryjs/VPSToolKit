#!/usr/bin/env bash

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: VPSToolKit 一键安装脚本
#	Version: 2.0.0
#	Author: VPSToolKit Contributors
#=================================================

SCRIPT_VERSION="2.0.0"
INSTALL_DIR="/usr/local/bin"
SCRIPTS_DIR="/usr/local/vpstoolkit/scripts"
CONFIG_DIR="/etc/vpstoolkit"
MODULES_DIR="${CONFIG_DIR}/modules.d"
MAIN_SCRIPT="m.sh"
VTK_SCRIPT="vtk.sh"
COMMAND_NAME="m"
VTK_COMMAND="vtk"
GITHUB_RAW=""
DOWNLOAD_SOURCE=""

Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Yellow_font_prefix="\033[0;33m"
Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Success="${Green_font_prefix}[成功]${Font_color_suffix}"

check_root(){
	if [[ $EUID != 0 ]]; then
		echo -e "${Error} 当前账号非ROOT(或没有ROOT权限)，无法继续操作，请使用 sudo su 来获取临时ROOT权限。"
		exit 1
	fi
}

check_system(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	fi
}

select_download_source(){
	clear
	echo -e "
========================================
    选择下载源
========================================

${Green_font_prefix}1.${Font_color_suffix} GitHub Raw (国外推荐)
   https://raw.githubusercontent.com

${Green_font_prefix}2.${Font_color_suffix} OSS CDN (国内推荐)
   https://oss.naloong.de/VPSToolKit

========================================
"
	read -e -p " 请选择下载源 [1-2]：" source_choice
	
	case "$source_choice" in
		1)
			GITHUB_RAW="https://raw.githubusercontent.com/betteryjs/VPSToolKit/master"
			DOWNLOAD_SOURCE="github"
			echo -e "${Info} 已选择 GitHub Raw 下载源"
			;;
		2)
			GITHUB_RAW="https://oss.naloong.de/VPSToolKit"
			DOWNLOAD_SOURCE="oss"
			echo -e "${Info} 已选择 OSS CDN 下载源"
			;;
		*)
			echo -e "${Info} 输入错误，默认使用 GitHub Raw"
			GITHUB_RAW="https://raw.githubusercontent.com/betteryjs/VPSToolKit/master"
			DOWNLOAD_SOURCE="github"
			;;
	esac
	
	sleep 1
}

install_dependencies(){
	echo -e "${Info} 正在安装依赖..."
	if [[ ${release} == "centos" ]]; then
		yum install wget curl -y
	else
		apt-get update
		apt-get install wget curl -y
	fi
}

create_directories(){
	echo -e "${Info} 创建目录结构..."
	
	# 创建脚本目录
	mkdir -p "${SCRIPTS_DIR}"/{proxy,system,tools}
	
	# 创建配置目录
	mkdir -p "${MODULES_DIR}"/{default,extend}
	
	echo -e "${Success} 目录结构创建完成！"
}

download_config_files(){
	echo -e "${Info} 正在下载配置文件..."
	
	local config_base_url
	if [[ "${DOWNLOAD_SOURCE}" == "github" ]]; then
		config_base_url="https://raw.githubusercontent.com/betteryjs/VPSToolKit/master"
	else
		config_base_url="https://oss.naloong.de/VPSToolKit"
	fi
	
	# 下载主配置文件
	wget --no-check-certificate -O "${CONFIG_DIR}/config.toml" "${config_base_url}/config.toml"
	
	# 下载模块配置文件
	wget --no-check-certificate -O "${MODULES_DIR}/default/000-menu.toml" "${config_base_url}/modules.d/default/000-menu.toml"
	wget --no-check-certificate -O "${MODULES_DIR}/default/010-proxy.toml" "${config_base_url}/modules.d/default/010-proxy.toml"
	wget --no-check-certificate -O "${MODULES_DIR}/default/020-system.toml" "${config_base_url}/modules.d/default/020-system.toml"
	wget --no-check-certificate -O "${MODULES_DIR}/default/030-tools.toml" "${config_base_url}/modules.d/default/030-tools.toml"
	
	# 写入版本信息
	echo "${SCRIPT_VERSION}" > "${CONFIG_DIR}/version"
	
	echo -e "${Success} 配置文件下载完成！"
}

copy_scripts(){
	echo -e "${Info} 复制脚本文件..."
	
	# 如果是从源码安装，复制 scripts 目录
	if [[ -d "./scripts" ]]; then
		cp -r ./scripts/* "${SCRIPTS_DIR}/"
		chmod +x "${SCRIPTS_DIR}"/*/*.sh
		echo -e "${Success} 脚本文件复制完成！"
	else
		echo -e "${Info} 脚本文件将在首次使用时自动下载"
	fi
}

download_main_script(){
	echo -e "${Info} 正在下载主脚本..."
	
	# 根据下载源构建完整下载地址
	local download_url
	if [[ "${DOWNLOAD_SOURCE}" == "github" ]]; then
		download_url="https://raw.githubusercontent.com/betteryjs/VPSToolKit/master"
	else
		download_url="https://oss.naloong.de/VPSToolKit"
	fi
	
	# 下载交互式菜单脚本
	wget --no-check-certificate -O "${SCRIPTS_DIR}/vtk-interactive.sh" "${download_url}/vtk-interactive.sh"
	if [[ -e "${SCRIPTS_DIR}/vtk-interactive.sh" ]]; then
		chmod +x "${SCRIPTS_DIR}/vtk-interactive.sh"
		echo -e "${Success} 交互式菜单脚本下载成功！"
	else
		echo -e "${Info} 交互式菜单脚本下载失败，将使用传统模式"
	fi
	
	# 下载 m.sh（兼容旧版本）
	wget --no-check-certificate -O "${INSTALL_DIR}/${MAIN_SCRIPT}" "${download_url}/m.sh"
	
	if [[ ! -e "${INSTALL_DIR}/${MAIN_SCRIPT}" ]]; then
		echo -e "${Error} 主脚本下载失败！"
		exit 1
	fi
	
	# 设置执行权限
	chmod +x "${INSTALL_DIR}/${MAIN_SCRIPT}"
	
	# 创建软链接 m
	if [[ -e "${INSTALL_DIR}/${COMMAND_NAME}" ]]; then
		rm -f "${INSTALL_DIR}/${COMMAND_NAME}"
	fi
	ln -s "${INSTALL_DIR}/${MAIN_SCRIPT}" "${INSTALL_DIR}/${COMMAND_NAME}"
	
	# 设置环境变量
	echo "export VTK_DOWNLOAD_SOURCE=${DOWNLOAD_SOURCE}" >> "${CONFIG_DIR}/env"
	
	echo -e "${Success} 主脚本下载完成！"
}

install_vtk_core(){
	echo -e "${Info} 检查 vtkCore..."
	
	# 检查是否已安装 vtkCore
	if command -v vtkCore &> /dev/null; then
		echo -e "${Success} vtkCore 已安装"
		return 0
	fi
	
	echo -e "${Info} vtkCore 未安装，VPSToolKit 将以兼容模式运行"
	echo -e "${Info} 你可以稍后通过以下方式安装 vtkCore："
	echo -e "      ${Yellow_font_prefix}1. 从源码编译安装${Font_color_suffix}"
	echo -e "      ${Yellow_font_prefix}2. 下载预编译二进制文件${Font_color_suffix}"
	echo ""
}

show_usage(){
	clear
	echo -e "
========================================
    VPSToolKit 安装完成！
========================================

${Green_font_prefix}使用方法：${Font_color_suffix}

1. 运行主菜单（兼容模式）：
   ${Yellow_font_prefix}m${Font_color_suffix}
   
2. 或使用完整路径：
   ${Yellow_font_prefix}bash ${INSTALL_DIR}/${MAIN_SCRIPT}${Font_color_suffix}

${Green_font_prefix}功能列表：${Font_color_suffix}

代理服务：
  - Shadowsocks Rust
  - Trojan-Go
  - Snell v4/v5
  - AnyTLS

系统工具：
  - BBR 加速
  - DD 重装系统
  - Speedtest 测速

${Green_font_prefix}配置文件位置：${Font_color_suffix}
  主配置：${CONFIG_DIR}/config.toml
  模块配置：${MODULES_DIR}/

${Green_font_prefix}项目地址：${Font_color_suffix}
  https://github.com/betteryjs/VPSToolKit

${Green_font_prefix}文档地址：${Font_color_suffix}
  https://github.com/betteryjs/VPSToolKit#readme

========================================
感谢使用 VPSToolKit！
========================================
"
}

main(){
	clear
	echo -e "
========================================
    VPSToolKit 安装脚本
    版本: ${SCRIPT_VERSION}
========================================
"
	
	check_root
	check_system
	select_download_source
	install_dependencies
	create_directories
	download_config_files
	copy_scripts
	download_main_script
	install_vtk_core
	show_usage
}

main
