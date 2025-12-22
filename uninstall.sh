#!/usr/bin/env bash

#=================================================
#	Description: VPSToolKit 卸载脚本
#	Version: 2.0.0
#	Author: VPSToolKit Contributors
#=================================================

# 配置变量
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/vpstoolkit"
MAIN_SCRIPT="vtk"

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

# 确认卸载
confirm_uninstall() {
	clear
	echo -e "
========================================
    VPSToolKit 卸载程序
========================================

${Yellow}警告：此操作将删除以下内容：${Reset}

  - 主脚本：${INSTALL_DIR}/${MAIN_SCRIPT}
  - 软链接：${INSTALL_DIR}/m
  - 配置文件：${CONFIG_DIR}
  
${Red}注意：已部署的服务（如代理）不会被删除${Reset}

========================================
"
	
	read -e -p "确定要卸载 VPSToolKit 吗？[y/N] " confirm
	
	if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
		echo -e "${Info} 已取消卸载"
		exit 0
	fi
}

# 删除文件
remove_files() {
	echo -e "${Info} 正在删除文件..."
	
	# 删除主脚本
	if [[ -f "${INSTALL_DIR}/${MAIN_SCRIPT}" ]]; then
		rm -f "${INSTALL_DIR}/${MAIN_SCRIPT}"
		echo -e "${Success} 已删除主脚本"
	fi
	
	# 删除软链接
	if [[ -L "${INSTALL_DIR}/m" ]]; then
		rm -f "${INSTALL_DIR}/m"
		echo -e "${Success} 已删除软链接"
	fi
	
	# 删除配置目录
	if [[ -d "${CONFIG_DIR}" ]]; then
		rm -rf "${CONFIG_DIR}"
		echo -e "${Success} 已删除配置目录"
	fi
}

# 显示完成信息
show_complete() {
	clear
	echo -e "
========================================
    VPSToolKit 已卸载完成！
========================================

${Green}卸载内容：${Reset}

  ✓ 主脚本已删除
  ✓ 配置文件已删除
  ✓ 软链接已删除

${Yellow}注意：${Reset}

  已部署的服务（如代理服务）未被删除
  如需清理，请手动停止和卸载相关服务

${Green}重新安装：${Reset}

  bash <(curl -Ls https://oss.naloong.de/VPSToolKit/install.sh)

========================================
感谢使用 VPSToolKit！
========================================
"
}

# 主函数
main() {
	check_root
	confirm_uninstall
	remove_files
	show_complete
}

main
