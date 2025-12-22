#!/usr/bin/env bash

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: VPSToolKit 一键安装脚本
#	Version: 1.0.0
#	Author: VPSToolKit Contributors
#=================================================

SCRIPT_VERSION="1.0.0"
INSTALL_DIR="/usr/local/bin"
MAIN_SCRIPT="m.sh"
COMMAND_NAME="m"
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
   https://oss.naloong.de

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
			GITHUB_RAW="https://oss.naloong.de/sh/vps"
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

download_main_script(){
	echo -e "${Info} 正在下载主脚本..."
	
	# 根据下载源构建完整下载地址
	if [[ "${DOWNLOAD_SOURCE}" == "github" ]]; then
		download_url="${GITHUB_RAW}/m.sh"
		scripts_base_url="https://raw.githubusercontent.com/betteryjs/VPSToolKit/master/scripts"
	else
		download_url="${GITHUB_RAW}/m.sh"
		scripts_base_url="https://oss.naloong.de/sh/vps"
	fi
	
	# 下载主脚本
	wget --no-check-certificate -O "${INSTALL_DIR}/${MAIN_SCRIPT}" "${download_url}"
	
	if [[ ! -e "${INSTALL_DIR}/${MAIN_SCRIPT}" ]]; then
		echo -e "${Error} 主脚本下载失败！"
		exit 1
	fi
	
	# 在主脚本中写入下载源配置
	sed -i "s|local download_url=\".*\"|local download_url=\"${scripts_base_url}/\${script_name}\"|" "${INSTALL_DIR}/${MAIN_SCRIPT}"
	
	# 设置执行权限
	chmod +x "${INSTALL_DIR}/${MAIN_SCRIPT}"
	
	# 创建软链接
	if [[ -e "${INSTALL_DIR}/${COMMAND_NAME}" ]]; then
		rm -f "${INSTALL_DIR}/${COMMAND_NAME}"
	fi
	ln -s "${INSTALL_DIR}/${MAIN_SCRIPT}" "${INSTALL_DIR}/${COMMAND_NAME}"
	
	echo -e "${Success} 主脚本下载完成！"
}

show_usage(){
	clear
	echo -e "
========================================
    VPSToolKit 安装完成！
========================================

${Green_font_prefix}使用方法：${Font_color_suffix}

1. 运行主菜单：
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

${Green_font_prefix}项目地址：${Font_color_suffix}
  https://github.com/yourusername/VPSToolKit

${Green_font_prefix}文档地址：${Font_color_suffix}
  https://github.com/yourusername/VPSToolKit#readme

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
	download_main_script
	show_usage
}

main
