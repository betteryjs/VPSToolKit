#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: 统一管理脚本
#	功能：整合所有服务管理脚本
#=================================================

sh_ver="1.0.0"

Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Yellow_font_prefix="\033[0;33m"
Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Yellow_font_prefix}[注意]${Font_color_suffix}"

# 脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
	local download_url="https://raw.githubusercontent.com/betteryjs/VPSToolKit/master/scripts/${script_name}"
	
	echo -e "${Info} 脚本 ${script_name} 不存在，正在从远程下载..."
	echo -e "${Info} 下载地址：${download_url}"
	
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
	run_script "anytls.sh"
}

manage_ss(){
	run_script "ss.sh"
}

manage_bbr(){
	run_script "bbr.sh"
}

manage_dd(){
	run_script "dd.sh"
}

manage_trojan(){
	run_script "trojan.sh"
}

manage_speedtest(){
	run_script "speedtest.sh"
}

manage_snell4(){
	run_script "snell4.sh"
}

manage_snell5(){
	run_script "snell5.sh"
}

update_script(){
	echo -e "${Info} 开始更新管理脚本..."
	cd "${SCRIPT_DIR}"
	
	# 检查是否为 git 仓库
	if [[ -d .git ]]; then
		echo -e "${Info} 检测到 Git 仓库，正在执行 git pull..."
		git pull
		if [[ $? -eq 0 ]]; then
			echo -e "${Info} 脚本更新完成！"
		else
			echo -e "${Error} Git 更新失败！"
		fi
	else
		echo -e "${Tip} 当前目录不是 Git 仓库"
		echo -e "${Info} 请手动更新脚本或使用 git clone 获取最新版本"
	fi
	
	echo && echo -n " 按回车键返回主菜单..." && read
	start_menu
}

start_menu(){
	clear
	echo -e "
========================================
    VPS 服务统一管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
========================================

${Yellow_font_prefix}代理服务管理${Font_color_suffix}
├── ${Green_font_prefix}1.${Font_color_suffix} AnyTLS 管理 (anytls.sh)
├── ${Green_font_prefix}2.${Font_color_suffix} Shadowsocks 管理 (ss.sh)
├── ${Green_font_prefix}3.${Font_color_suffix} Trojan-Go 管理 (trojan.sh)
├── ${Green_font_prefix}4.${Font_color_suffix} Snell v4 管理 (snell4.sh)
└── ${Green_font_prefix}5.${Font_color_suffix} Snell v5 管理 (snell5.sh)

${Yellow_font_prefix}系统工具${Font_color_suffix}
├── ${Green_font_prefix}6.${Font_color_suffix} BBR 加速管理 (bbr.sh)
├── ${Green_font_prefix}7.${Font_color_suffix} DD 重装系统 (dd.sh)
└── ${Green_font_prefix}8.${Font_color_suffix} Speedtest 管理 (speedtest.sh)

${Yellow_font_prefix}脚本管理${Font_color_suffix}
├── ${Green_font_prefix}9.${Font_color_suffix} 更新所有脚本
└── ${Green_font_prefix}0.${Font_color_suffix} 退出脚本

========================================
当前目录: ${Green_font_prefix}${SCRIPT_DIR}${Font_color_suffix}
========================================
" && echo
	
	read -e -p " 请输入数字 [0-9]：" num
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
		9)
			update_script
			;;
		0)
			echo -e "${Info} 退出脚本"
			exit 0
			;;
		*)
			echo -e "${Error} 请输入正确的数字 [0-9]"
			sleep 2s
			start_menu
			;;
	esac
}

# 脚本执行入口
check_root
start_menu
