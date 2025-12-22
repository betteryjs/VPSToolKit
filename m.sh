#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: VPSToolKit 统一管理脚本（交互式版本）
#	功能：调用交互式菜单系统
#	Version: 2.0.0
#=================================================

sh_ver="2.0.0"

# 颜色定义
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Yellow_font_prefix="\033[0;33m"
Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"

# 检查 Root 权限
check_root(){
	if [[ $EUID != 0 ]]; then
		echo -e "${Error} 当前账号非ROOT(或没有ROOT权限)，无法继续操作，请使用 sudo su 来获取临时ROOT权限。"
		exit 1
	fi
}

# 下载交互式脚本
download_interactive_script(){
	local script_path=$1
	local download_source="${VTK_DOWNLOAD_SOURCE:-oss}"
	local download_url
	
	if [[ "${download_source}" == "oss" ]]; then
		download_url="https://oss.naloong.de/VPSToolKit/vtk-interactive.sh"
	else
		download_url="https://raw.githubusercontent.com/betteryjs/VPSToolKit/master/vtk-interactive.sh"
	fi
	
	echo -e "${Info} 正在下载交互式菜单脚本..."
	echo -e "${Info} 下载地址：${download_url}"
	
	# 确保目录存在
	mkdir -p "$(dirname "${script_path}")"
	
	wget --no-check-certificate -O "${script_path}" "${download_url}" 2>&1
	
	if [[ $? -eq 0 && -f "${script_path}" ]]; then
		chmod +x "${script_path}"
		echo -e "${Info} 交互式菜单脚本下载成功！"
		return 0
	else
		echo -e "${Error} 交互式菜单脚本下载失败！"
		return 1
	fi
}

# 主函数
main(){
	check_root
	
	# 查找交互式菜单脚本
	local interactive_script=""
	
	if [ -f "/usr/local/vpstoolkit/scripts/vtk-interactive.sh" ]; then
		interactive_script="/usr/local/vpstoolkit/scripts/vtk-interactive.sh"
	elif [ -f "/usr/local/vpstoolkit/vtk-interactive.sh" ]; then
		interactive_script="/usr/local/vpstoolkit/vtk-interactive.sh"
	else
		# 脚本不存在，尝试下载
		echo -e "${Info} 未找到交互式菜单脚本"
		interactive_script="/usr/local/vpstoolkit/vtk-interactive.sh"
		
		if ! download_interactive_script "${interactive_script}"; then
			echo -e "${Error} 无法获取交互式菜单脚本！"
			echo -e "${Info} 请检查网络连接或手动安装："
			echo -e "  ${Yellow_font_prefix}bash <(curl -sL https://oss.naloong.de/VPSToolKit/install.sh)${Font_color_suffix}"
			exit 1
		fi
	fi
	
	# 运行交互式菜单
	echo -e "${Info} 启动交互式菜单..."
	bash "${interactive_script}"
}

# 脚本执行入口
main
