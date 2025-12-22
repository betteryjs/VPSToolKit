#!/usr/bin/env bash

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: VPSToolKit 卸载脚本
#	Version: 2.0.0
#	Author: VPSToolKit Contributors
#=================================================

SCRIPT_VERSION="2.0.0"
INSTALL_DIR="/usr/local/bin"
SCRIPTS_DIR="/usr/local/vpstoolkit"
CONFIG_DIR="/etc/vpstoolkit"
MAIN_SCRIPT="m.sh"
VTK_SCRIPT="vtk.sh"
COMMAND_NAME="m"
VTK_COMMAND="vtk"

Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Yellow_font_prefix="\033[0;33m"
Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Success="${Green_font_prefix}[成功]${Font_color_suffix}"
Warning="${Yellow_font_prefix}[警告]${Font_color_suffix}"

check_root(){
	if [[ $EUID != 0 ]]; then
		echo -e "${Error} 当前账号非ROOT(或没有ROOT权限)，无法继续操作，请使用 sudo su 来获取临时ROOT权限。"
		exit 1
	fi
}

confirm_uninstall(){
	clear
	echo -e "
========================================
    VPSToolKit 卸载确认
========================================

${Warning} 此操作将删除以下内容：

${Red_font_prefix}文件和目录：${Font_color_suffix}
  - ${INSTALL_DIR}/${MAIN_SCRIPT}
  - ${INSTALL_DIR}/${COMMAND_NAME}
  - ${INSTALL_DIR}/${VTK_SCRIPT}
  - ${INSTALL_DIR}/${VTK_COMMAND}
  - ${SCRIPTS_DIR}/
  - ${CONFIG_DIR}/

${Yellow_font_prefix}注意：${Font_color_suffix}
  - 不会卸载已安装的代理服务（如 Shadowsocks、Trojan 等）
  - 不会删除代理服务的配置文件
  - 如需完全清理，请先使用各服务的卸载功能

========================================
"
	
	read -e -p "确定要卸载 VPSToolKit 吗？[y/N]：" confirm
	[[ -z "${confirm}" ]] && confirm="n"
	
	if [[ "${confirm}" != [Yy] ]]; then
		echo -e "${Info} 已取消卸载"
		exit 0
	fi
}

stop_services(){
	echo -e "${Info} 检查运行中的服务..."
	
	# 这里可以添加额外的服务检查
	# 目前 VPSToolKit 本身不作为服务运行，所以无需停止
	
	echo -e "${Success} 服务检查完成"
}

remove_scripts(){
	echo -e "${Info} 正在删除脚本文件..."
	
	# 删除主脚本
	if [[ -f "${INSTALL_DIR}/${MAIN_SCRIPT}" ]]; then
		rm -f "${INSTALL_DIR}/${MAIN_SCRIPT}"
		echo -e "${Success} 已删除 ${MAIN_SCRIPT}"
	fi
	
	# 删除 VTK 脚本（如果存在）
	if [[ -f "${INSTALL_DIR}/${VTK_SCRIPT}" ]]; then
		rm -f "${INSTALL_DIR}/${VTK_SCRIPT}"
		echo -e "${Success} 已删除 ${VTK_SCRIPT}"
	fi
	
	# 删除软链接
	if [[ -L "${INSTALL_DIR}/${COMMAND_NAME}" ]]; then
		rm -f "${INSTALL_DIR}/${COMMAND_NAME}"
		echo -e "${Success} 已删除命令 ${COMMAND_NAME}"
	fi
	
	if [[ -L "${INSTALL_DIR}/${VTK_COMMAND}" ]]; then
		rm -f "${INSTALL_DIR}/${VTK_COMMAND}"
		echo -e "${Success} 已删除命令 ${VTK_COMMAND}"
	fi
}

remove_directories(){
	echo -e "${Info} 正在删除目录..."
	
	# 删除脚本目录
	if [[ -d "${SCRIPTS_DIR}" ]]; then
		rm -rf "${SCRIPTS_DIR}"
		echo -e "${Success} 已删除 ${SCRIPTS_DIR}"
	fi
	
	# 删除配置目录
	if [[ -d "${CONFIG_DIR}" ]]; then
		rm -rf "${CONFIG_DIR}"
		echo -e "${Success} 已删除 ${CONFIG_DIR}"
	fi
}

remove_environment(){
	echo -e "${Info} 清理环境变量..."
	
	# 清理可能存在的环境变量配置
	if grep -q "VTK_DOWNLOAD_SOURCE" ~/.bashrc 2>/dev/null; then
		sed -i '/VTK_DOWNLOAD_SOURCE/d' ~/.bashrc
		echo -e "${Success} 已清理 ~/.bashrc 中的环境变量"
	fi
	
	if grep -q "VTK_DOWNLOAD_SOURCE" ~/.zshrc 2>/dev/null; then
		sed -i '/VTK_DOWNLOAD_SOURCE/d' ~/.zshrc
		echo -e "${Success} 已清理 ~/.zshrc 中的环境变量"
	fi
}

check_remaining_services(){
	echo -e ""
	echo -e "${Info} 检查残留的代理服务..."
	
	local services_found=0
	
	# 检查常见的代理服务
	if systemctl list-units --all | grep -q "ss-rust"; then
		echo -e "${Warning} 发现 Shadowsocks Rust 服务仍在运行"
		services_found=1
	fi
	
	if systemctl list-units --all | grep -q "trojan"; then
		echo -e "${Warning} 发现 Trojan 服务仍在运行"
		services_found=1
	fi
	
	if systemctl list-units --all | grep -q "snell"; then
		echo -e "${Warning} 发现 Snell 服务仍在运行"
		services_found=1
	fi
	
	if [[ ${services_found} -eq 1 ]]; then
		echo -e ""
		echo -e "${Yellow_font_prefix}提示：${Font_color_suffix}"
		echo -e "  发现已安装的代理服务未被卸载"
		echo -e "  这些服务需要手动卸载或使用其自带的卸载脚本"
		echo -e ""
	else
		echo -e "${Success} 未发现残留的代理服务"
	fi
}

show_completion(){
	clear
	echo -e "
========================================
    VPSToolKit 卸载完成！
========================================

${Success} 以下内容已被删除：

  ✓ 主脚本和命令
  ✓ 脚本目录 (${SCRIPTS_DIR})
  ✓ 配置目录 (${CONFIG_DIR})
  ✓ 环境变量配置

${Info} 如需重新安装，请运行：

  ${Yellow_font_prefix}bash <(curl -sL https://oss.naloong.de/VPSToolKit/install.sh)${Font_color_suffix}

  或

  ${Yellow_font_prefix}bash <(curl -sL https://raw.githubusercontent.com/betteryjs/VPSToolKit/master/install.sh)${Font_color_suffix}

========================================
感谢使用 VPSToolKit！
========================================
"
}

main(){
	clear
	echo -e "
========================================
    VPSToolKit 卸载脚本
    版本: ${SCRIPT_VERSION}
========================================
"
	
	check_root
	confirm_uninstall
	stop_services
	remove_scripts
	remove_directories
	remove_environment
	check_remaining_services
	show_completion
}

main
