#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: Snell v4 管理脚本
#	功能：安装/卸载/更新/管理 Snell Server v4
#=================================================

# 当前脚本版本号
sh_ver="1.0.0"

# Snell v4 相关路径
SNELL_DIR="/etc/snell"
SNELL_FILE="/usr/bin/snell4-server"
SNELL_CONF="${SNELL_DIR}/snell4-server.conf"
SERVICE_FILE="/etc/systemd/system/snell4.service"

# 默认配置
DEFAULT_PORT=10241
DEFAULT_VERSION="v4.1.1"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m" && Yellow_font_prefix="\033[0;33m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Yellow_font_prefix}[注意]${Font_color_suffix}"

check_root(){
	if [[ $EUID != 0 ]]; then
		echo -e "${Error} 当前账号非ROOT(或没有ROOT权限)，无法继续操作，请使用${Green_background_prefix} sudo su ${Font_color_suffix}来获取临时ROOT权限。"
		exit 1
	fi
}

check_sys(){
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

sys_arch() {
	uname=$(uname -m)
	if [[ "$uname" == "i686" ]] || [[ "$uname" == "i386" ]]; then
		arch="i386"
	elif [[ "$uname" == *"armv7"* ]] || [[ "$uname" == "armv6l" ]]; then
		arch="armv7l"
	elif [[ "$uname" == *"armv8"* ]] || [[ "$uname" == "aarch64" ]]; then
		arch="aarch64"
	else
		arch="amd64"
	fi
}

check_installed_status(){
	[[ ! -e ${SNELL_FILE} ]] && echo -e "${Error} Snell v4 没有安装，请检查！" && exit 1
}

check_status(){
	status=$(systemctl status snell4 2>/dev/null | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
	[[ -z "${status}" ]] && status="未运行"
}

check_new_ver(){
	# Snell 官方没有公开 API，使用默认版本
	new_ver="${DEFAULT_VERSION}"
	echo -e "${Info} 使用 Snell v4 版本 [ ${new_ver} ]"
}

installation_dependency(){
	echo -e "${Info} 正在安装/更新依赖..."
	if [[ ${release} == "centos" ]]; then
		yum install wget unzip curl -y
	else
		apt-get update
		apt-get install wget unzip curl -y
	fi
}

set_port(){
	echo -e "请输入 Snell v4 监听端口 [1-65535]"
	read -e -p "(默认：${DEFAULT_PORT})：" port
	[[ -z "${port}" ]] && port=${DEFAULT_PORT}
	echo && echo "=================================="
	echo -e "	端口：${Red_background_prefix} ${port} ${Font_color_suffix}"
	echo "==================================" && echo
}

set_password(){
	echo "请输入 Snell v4 PSK 密钥"
	read -e -p "(默认：随机生成)：" password
	[[ -z "${password}" ]] && password=$(< /dev/urandom tr -dc 'a-zA-Z0-9' | head -c 16)
	echo && echo "========================================"
	echo -e "PSK：${Red_font_prefix} ${password} ${Font_color_suffix}"
	echo "========================================" && echo
}

set_ipv6(){
	echo -e "是否启用 IPv6 支持？
========================================
 ${Green_font_prefix}1.${Font_color_suffix} 启用  ${Green_font_prefix}2.${Font_color_suffix} 禁用
========================================"
	read -e -p "(默认：1.启用)：" ipv6_choice
	[[ -z "${ipv6_choice}" ]] && ipv6_choice="1"
	if [[ ${ipv6_choice} == "1" ]]; then
		ipv6_enabled="true"
	else
		ipv6_enabled="false"
	fi
	echo && echo "=================================="
	echo -e "IPv6：${Red_background_prefix} ${ipv6_enabled} ${Font_color_suffix}"
	echo "==================================" && echo
}

download(){
	cd /tmp
	sys_arch
	VERSION=${new_ver#v}
	ZIPFILE="snell-server-${new_ver}-linux-${arch}.zip"
	
	echo -e "${Info} 开始下载 Snell v4 ${new_ver}..."
	wget --no-check-certificate "https://dl.nssurge.com/snell/${ZIPFILE}"
	
	if [[ ! -e "${ZIPFILE}" ]]; then
		echo -e "${Error} Snell v4 下载失败！"
		exit 1
	fi
	
	echo -e "${Info} 解压文件..."
	unzip -o "$ZIPFILE"
	
	if [[ ! -e "snell-server" ]]; then
		echo -e "${Error} Snell v4 解压失败！"
		rm -f "$ZIPFILE"
		exit 1
	fi
	
	# 创建目录
	if [ ! -d "$SNELL_DIR" ]; then
		mkdir -p "$SNELL_DIR"
		echo -e "${Info} 文件夹 $SNELL_DIR 已创建。"
	fi
	
	# 移动文件
	chmod +x snell-server
	mv -f snell-server "${SNELL_FILE}"
	
	# 清理
	rm -f "$ZIPFILE"
	
	echo -e "${Info} Snell v4 下载安装完成！"
}

write_config(){
	cat > ${SNELL_CONF}<<-EOF
[snell-server]
listen = ::0:${port}
psk = ${password}
ipv6 = ${ipv6_enabled}
EOF
}

read_config(){
	[[ ! -e ${SNELL_CONF} ]] && echo -e "${Error} Snell v4 配置文件不存在！" && exit 1
	port=$(cat ${SNELL_CONF} | grep "listen" | awk -F':' '{print $NF}')
	password=$(cat ${SNELL_CONF} | grep "psk" | awk -F'=' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
	ipv6_enabled=$(cat ${SNELL_CONF} | grep "ipv6" | awk -F'=' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
}

create_service(){
	cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Snell v4 Proxy Service
After=network.target

[Service]
Type=simple
User=nobody
Group=nogroup
LimitNOFILE=32768
ExecStart=${SNELL_FILE} -c ${SNELL_CONF}
AmbientCapabilities=CAP_NET_BIND_SERVICE
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=snell4-server
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
	
	systemctl daemon-reload
	systemctl enable snell4.service
	echo -e "${Info} Snell v4 服务配置完成！"
}

install(){
	[[ -e ${SNELL_FILE} ]] && echo -e "${Error} 检测到 Snell v4 已安装！" && exit 1
	
	echo -e "${Info} 开始设置配置..."
	set_port
	set_password
	set_ipv6
	
	echo -e "${Info} 开始安装/配置依赖..."
	installation_dependency
	
	echo -e "${Info} 开始下载/安装..."
	check_new_ver
	download
	
	echo -e "${Info} 开始写入配置文件..."
	write_config
	
	echo -e "${Info} 开始安装系统服务..."
	create_service
	
	echo -e "${Info} 所有步骤安装完毕，开始启动..."
	start
	
	echo -e "${Info} Snell v4 安装完成！"
	view
}

view(){
	check_installed_status
	read_config
	getipv4
	getipv6
	
	clear && echo
	echo -e "Snell v4 Server 配置："
	echo -e "————————————————————————————————————————"
	[[ "${ipv4}" != "IPv4_Error" ]] && echo -e " IPv4 地址：${Green_font_prefix}${ipv4}${Font_color_suffix}"
	[[ "${ipv6}" != "IPv6_Error" ]] && echo -e " IPv6 地址：${Green_font_prefix}${ipv6}${Font_color_suffix}"
	echo -e " 监听端口：${Green_font_prefix}${port}${Font_color_suffix}"
	echo -e " PSK 密钥：${Green_font_prefix}${password}${Font_color_suffix}"
	echo -e " IPv6 支持：${Green_font_prefix}${ipv6_enabled}${Font_color_suffix}"
	echo -e "————————————————————————————————————————"
	
	if [[ "${ipv4}" != "IPv4_Error" ]]; then
		echo -e "\nSurge 配置示例："
		echo -e "${Green_font_prefix}[Proxy]${Font_color_suffix}"
		echo -e "${Green_font_prefix}Snell = snell, ${ipv4}, ${port}, psk=${password}, version=4${Font_color_suffix}"
	fi
	
	echo -e "\n————————————————————————————————————————"
	echo && echo -n " 按回车键返回主菜单..." && read
	start_menu
}

set_config(){
	check_installed_status
	echo && echo -e "你要做什么？
========================================
 ${Green_font_prefix}1.${Font_color_suffix}  修改 端口配置
 ${Green_font_prefix}2.${Font_color_suffix}  修改 PSK 密钥
 ${Green_font_prefix}3.${Font_color_suffix}  修改 IPv6 配置
========================================
 ${Green_font_prefix}4.${Font_color_suffix}  修改 全部配置" && echo
	read -e -p "(默认：取消)：" modify
	[[ -z "${modify}" ]] && echo -e "已取消..." && exit 1
	
	if [[ ${modify} == "1" ]]; then
		read_config
		set_port
		write_config
		restart
	elif [[ ${modify} == "2" ]]; then
		read_config
		set_password
		write_config
		restart
	elif [[ ${modify} == "3" ]]; then
		read_config
		set_ipv6
		write_config
		restart
	elif [[ ${modify} == "4" ]]; then
		set_port
		set_password
		set_ipv6
		write_config
		restart
	else
		echo -e "${Error} 请输入正确的数字(1-4)" && exit 1
	fi
}

start(){
	check_installed_status
	check_status
	if [[ "$status" == "running" ]]; then
		echo -e "${Info} Snell v4 已在运行！"
	else
		systemctl start snell4
		sleep 2s
		check_status
		if [[ "$status" == "running" ]]; then
			echo -e "${Info} Snell v4 启动成功！"
		else
			echo -e "${Error} Snell v4 启动失败！"
		fi
	fi
	sleep 2s
}

stop(){
	check_installed_status
	check_status
	[[ "$status" != "running" ]] && echo -e "${Error} Snell v4 没有运行，请检查！" && exit 1
	systemctl stop snell4
	sleep 2s
	check_status
	if [[ "$status" == "running" ]]; then
		echo -e "${Error} Snell v4 停止失败！"
	else
		echo -e "${Info} Snell v4 停止成功！"
	fi
}

restart(){
	check_installed_status
	systemctl restart snell4
	sleep 2s
	check_status
	if [[ "$status" == "running" ]]; then
		echo -e "${Info} Snell v4 重启成功！"
	else
		echo -e "${Error} Snell v4 重启失败！"
	fi
	sleep 2s
}

update(){
	check_installed_status
	check_new_ver
	
	# 获取当前版本
	current_ver=$(${SNELL_FILE} --version 2>&1 | grep -oP 'v\d+\.\d+\.\d+' || echo "unknown")
	
	echo -e "${Info} 当前版本：${current_ver}"
	echo -e "${Info} 最新版本：${new_ver}"
	
	if [[ "${current_ver}" == "${new_ver}" ]]; then
		echo -e "${Info} 已经是最新版本了！"
		return 0
	fi
	
	echo -e "${Info} 开始更新 Snell v4..."
	check_status
	[[ "$status" == "running" ]] && stop
	
	# 备份配置
	if [[ -e ${SNELL_CONF} ]]; then
		cp -f ${SNELL_CONF} "/tmp/snell4_config_backup.conf"
	fi
	
	download
	
	# 恢复配置
	if [[ -e "/tmp/snell4_config_backup.conf" ]]; then
		cp -f "/tmp/snell4_config_backup.conf" ${SNELL_CONF}
		rm -f "/tmp/snell4_config_backup.conf"
	fi
	
	start
	echo -e "${Info} Snell v4 更新完成！"
}

uninstall(){
	check_installed_status
	echo -e "确定要卸载 Snell v4？[y/N]"
	read -e -p "(默认：n)：" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_status
		[[ "$status" == "running" ]] && stop
		systemctl disable snell4
		rm -rf "${SNELL_DIR}"
		rm -f "${SNELL_FILE}"
		rm -f "${SERVICE_FILE}"
		systemctl daemon-reload
		echo -e "${Info} Snell v4 卸载完成！"
	else
		echo -e "${Info} 卸载已取消..."
	fi
}

view_status(){
	check_installed_status
	check_status
	read_config
	getipv4
	getipv6
	
	echo -e "\nSnell v4 Server 状态："
	if [[ "$status" == "running" ]]; then
		echo -e " 状态：${Green_font_prefix}运行中${Font_color_suffix}"
	else
		echo -e " 状态：${Red_font_prefix}已停止${Font_color_suffix}"
	fi
	echo -e " 地址：${ipv4} / ${ipv6}"
	echo -e " 端口：${port}"
	echo -e " PSK：${password}"
	echo -e " IPv6：${ipv6_enabled}"
	echo && echo -n " 按回车键返回主菜单..." && read
	start_menu
}

view_log(){
	check_installed_status
	echo -e "${Info} 显示 Snell v4 最近 50 行日志："
	journalctl -u snell4 -n 50 --no-pager
	echo && echo -n " 按回车键返回主菜单..." && read
	start_menu
}

getipv4(){
	ipv4=$(wget -qO- -4 -t1 -T2 ipinfo.io/ip)
	if [[ -z "${ipv4}" ]]; then
		ipv4=$(wget -qO- -4 -t1 -T2 api.ip.sb/ip)
		if [[ -z "${ipv4}" ]]; then
			ipv4="IPv4_Error"
		fi
	fi
}

getipv6(){
	ipv6=$(wget -qO- -6 -t1 -T2 ifconfig.co)
	[[ -z "${ipv6}" ]] && ipv6="IPv6_Error"
}

start_menu(){
	clear
	check_root
	check_sys
	
	if [[ -e ${SNELL_FILE} ]]; then
		check_status
		if [[ "$status" == "running" ]]; then
			status_show="${Green_font_prefix}运行中${Font_color_suffix}"
		else
			status_show="${Red_font_prefix}已停止${Font_color_suffix}"
		fi
	else
		status_show="${Red_font_prefix}未安装${Font_color_suffix}"
	fi
	
	echo -e "
========================================
   Snell v4 管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
========================================
  
==================状态==================
 Snell v4 Server  : [${status_show}]
========================================
==================菜单==================
 ${Green_font_prefix}1.${Font_color_suffix}  安装 Snell v4
 ${Green_font_prefix}2.${Font_color_suffix}  更新 Snell v4
 ${Green_font_prefix}3.${Font_color_suffix}  卸载 Snell v4
————————————————————————————————————————
 ${Green_font_prefix}4.${Font_color_suffix}  启动 Snell v4
 ${Green_font_prefix}5.${Font_color_suffix}  停止 Snell v4
 ${Green_font_prefix}6.${Font_color_suffix}  重启 Snell v4
————————————————————————————————————————
 ${Green_font_prefix}7.${Font_color_suffix}  修改 Snell v4 配置
 ${Green_font_prefix}8.${Font_color_suffix}  查看 Snell v4 配置
 ${Green_font_prefix}9.${Font_color_suffix}  查看 Snell v4 状态
 ${Green_font_prefix}10.${Font_color_suffix} 查看 Snell v4 日志
————————————————————————————————————————
 ${Green_font_prefix}0.${Font_color_suffix}  退出脚本
========================================" && echo
	
	read -e -p " 请输入数字 [0-10]：" num
	case "$num" in
		1)
		install
		;;
		2)
		update
		;;
		3)
		uninstall
		;;
		4)
		start
		;;
		5)
		stop
		;;
		6)
		restart
		;;
		7)
		set_config
		;;
		8)
		view
		;;
		9)
		view_status
		;;
		10)
		view_log
		;;
		0)
		exit 0
		;;
		*)
		echo -e "${Error} 请输入正确的数字 [0-10]"
		sleep 2s
		start_menu
		;;
	esac
}

# 脚本执行入口
start_menu
