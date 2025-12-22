#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: 统一管理脚本（兼容旧版本）
#	功能：整合所有服务管理脚本
#	注意：本脚本保留用于向后兼容，建议使用新的 vtk 命令
#=================================================

sh_ver="2.0.0"

Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Yellow_font_prefix="\033[0;33m"
Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Yellow_font_prefix}[注意]${Font_color_suffix}"

# 脚本所在目录
SCRIPT_DIR="/usr/local/vpstoolkit/scripts"
# 兼容安装路径
if [[ ! -d "${SCRIPT_DIR}" ]]; then
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts"
fi

check_root(){
	if [[ $EUID != 0 ]]; then
		echo -e "${Error} 当前账号非ROOT(或没有ROOT权限)，无法继续操作，请使用 sudo su 来获取临时ROOT权限。"
		exit 1
	fi
}

check_script_exists(){
	local script_name=$1
	local script_path="${SCRIPT_DIR}/${script_name}"
	
	if [[ ! -e "${script_path}" ]]; then
		return 1
	fi
	return 0
}

download_script(){
	local script_name=$1
	local script_path="${SCRIPT_DIR}/${script_name}"
	local download_url=""
	
	# 根据环境变量或默认值选择下载源
	local download_source="${VTK_DOWNLOAD_SOURCE:-github}"
	
	if [[ "${download_source}" == "oss" ]]; then
		download_url="https://oss.naloong.de/VPSToolKit/scripts/${script_name}"
	else
		download_url="https://raw.githubusercontent.com/betteryjs/VPSToolKit/master/scripts/${script_name}"
	fi
	
	echo -e "${Info} 脚本 ${script_name} 不存在，正在从远程下载..."
	echo -e "${Info} 下载地址：${download_url}"
	
	# 确保目录存在
	mkdir -p "$(dirname "${script_path}")"
	
	wget --no-check-certificate -O "${script_path}" "${download_url}"
	
	if [[ $? -eq 0 && -e "${script_path}" ]]; then
		chmod +x "${script_path}"
		echo -e "${Info} 脚本下载成功！"
		return 0
	else
		echo -e "${Error} 脚本下载失败！"
		return 1
	fi
}

run_script(){
	local script_name=$1
	local script_path="${SCRIPT_DIR}/${script_name}"
	
	# 检查脚本是否存在，不存在则下载
	if ! check_script_exists "${script_name}"; then
		if ! download_script "${script_name}"; then
			echo -e "${Error} 无法获取 ${script_name}"
			echo && echo -n " 按回车键返回主菜单..." && read
			start_menu
			return
		fi
	fi
	
	# 运行脚本
	echo -e "${Info} 正在启动 ${script_name}..."
	echo "========================================"
	bash "${script_path}"
	
	# 子脚本执行完毕后的二级菜单
	echo ""
	echo "========================================"
	echo -e " ${Green_font_prefix}1.${Font_color_suffix} 返回主菜单"
	echo -e " ${Green_font_prefix}0.${Font_color_suffix} 退出脚本"
	echo "========================================"
	read -e -p " 请选择 [0-1]：" choice
	
	# 删除临时脚本
	if [[ -e "${script_path}" ]]; then
		rm -f "${script_path}"
		echo -e "${Info} 已清理临时脚本 ${script_name}"
	fi
	
	case "$choice" in
		1|"")
			start_menu
			;;
		0)
			echo -e "${Info} 退出脚本"
			exit 0
			;;
		*)
			echo -e "${Info} 默认返回主菜单"
			sleep 1s
			start_menu
			;;
	esac
}

manage_anytls(){
	run_script "proxy/anytls.sh"
}

manage_ss(){
	run_script "proxy/ss.sh"
}

manage_bbr(){
	run_script "system/bbr.sh"
}

manage_dd(){
	run_script "system/dd.sh"
}

manage_trojan(){
	run_script "proxy/trojan.sh"
}

manage_speedtest(){
	run_script "tools/speedtest.sh"
}

manage_snell4(){
	run_script "proxy/snell4.sh"
}

manage_snell5(){
	run_script "proxy/snell5.sh"
}

start_menu(){
	clear
	echo -e "
========================================
    VPS 服务统一管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
    ${Yellow_font_prefix}兼容模式 - 建议使用 vtk 命令${Font_color_suffix}
========================================

${Yellow_font_prefix}代理服务管理${Font_color_suffix}
├── ${Green_font_prefix}1.${Font_color_suffix} AnyTLS 管理
├── ${Green_font_prefix}2.${Font_color_suffix} Shadowsocks 管理
├── ${Green_font_prefix}3.${Font_color_suffix} Trojan-Go 管理
├── ${Green_font_prefix}4.${Font_color_suffix} Snell v4 管理
└── ${Green_font_prefix}5.${Font_color_suffix} Snell v5 管理

${Yellow_font_prefix}系统工具${Font_color_suffix}
├── ${Green_font_prefix}6.${Font_color_suffix} BBR 加速管理
├── ${Green_font_prefix}7.${Font_color_suffix} DD 重装系统
├── ${Green_font_prefix}8.${Font_color_suffix} Speedtest 管理
└── ${Green_font_prefix}0.${Font_color_suffix} 退出脚本

========================================
当前目录: ${Green_font_prefix}${SCRIPT_DIR}${Font_color_suffix}
========================================
" && echo
	
	read -e -p " 请输入数字 [0-8]：" num
	case "$num" in
		1)
			manage_anytls
			;;
		2)
			manage_ss
			;;
		3)
			manage_trojan
			;;
		4)
			manage_snell4
			;;
		5)
			manage_snell5
			;;
		6)
			manage_bbr
			;;
		7)
			manage_dd
			;;
		8)
			manage_speedtest
			;;
		0)
			echo -e "${Info} 退出脚本"
			exit 0
			;;
		*)
			echo -e "${Error} 请输入正确的数字 [0-8]"
			sleep 2s
			start_menu
			;;
	esac
}
			;;
	esac
}

# 脚本执行入口
check_root
start_menu
