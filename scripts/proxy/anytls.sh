#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: AnyTLS 管理脚本
#	功能：安装/卸载/更新/管理 AnyTLS Server
#=================================================

# 当前脚本版本号
sh_ver="1.0.0"

# AnyTLS 相关路径
ANYTLS_DIR="/etc/anytls"
ANYTLS_FILE="${ANYTLS_DIR}/anytls-server"
ANYTLS_CONF="${ANYTLS_DIR}/config.txt"
SERVICE_FILE="/etc/systemd/system/anytls.service"

# 默认配置
DEFAULT_PORT=10243

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

check_installed_status(){
	[[ ! -e ${ANYTLS_FILE} ]] && echo -e "${Error} AnyTLS 没有安装，请检查！" && exit 1
}

check_status(){
	status=$(systemctl status anytls 2>/dev/null | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
	[[ -z "${status}" ]] && status="未运行"
}

check_new_ver(){
	LATEST_VERSION=$(curl -sL https://api.github.com/repos/anytls/anytls-go/releases/latest | jq -r '.tag_name')
	[[ -z ${LATEST_VERSION} ]] && echo -e "${Error} AnyTLS 最新版本获取失败！" && exit 1
	echo -e "${Info} 检测到 AnyTLS 最新版本为 [ ${LATEST_VERSION} ]"
}

installation_dependency(){
	echo -e "${Info} 正在安装/更新依赖..."
	if [[ ${release} == "centos" ]]; then
		yum install wget unzip jq curl -y
	else
		apt-get update
		apt-get install wget unzip jq curl -y
	fi
}

set_port(){
	echo -e "请输入 AnyTLS 监听端口 [1-65535]"
	read -e -p "(默认：${DEFAULT_PORT})：" port
	[[ -z "${port}" ]] && port=${DEFAULT_PORT}
	echo && echo "=================================="
	echo -e "	端口：${Red_background_prefix} ${port} ${Font_color_suffix}"
	echo "==================================" && echo
}

set_password(){
	echo "请输入 AnyTLS 密码"
	read -e -p "(默认：随机生成)：" password
	[[ -z "${password}" ]] && password=$(< /dev/urandom tr -dc 'a-zA-Z0-9' | head -c 16)
	echo && echo "========================================"
	echo -e "密码：${Red_font_prefix} ${password} ${Font_color_suffix}"
	echo "========================================" && echo
}

download(){
	cd /tmp
	VERSION=${LATEST_VERSION#v}
	ZIPFILE="anytls_${VERSION}_linux_amd64.zip"
	
	echo -e "${Info} 开始下载 AnyTLS ${LATEST_VERSION}..."
	wget "https://github.com/anytls/anytls-go/releases/download/${LATEST_VERSION}/${ZIPFILE}"
	
	if [[ ! -e "${ZIPFILE}" ]]; then
		echo -e "${Error} AnyTLS 下载失败！"
		exit 1
	fi
	
	echo -e "${Info} 解压文件..."
	unzip -o "$ZIPFILE"
	
	if [[ ! -e "anytls-server" ]]; then
		echo -e "${Error} AnyTLS 解压失败！"
		rm -f "$ZIPFILE"
		exit 1
	fi
	
	# 创建目录
	if [ ! -d "$ANYTLS_DIR" ]; then
		mkdir -p "$ANYTLS_DIR"
		echo -e "${Info} 文件夹 $ANYTLS_DIR 已创建。"
	fi
	
	# 移动文件
	chmod a+x anytls-server
	mv -f anytls-server "${ANYTLS_FILE}"
	
	# 清理
	rm -f "$ZIPFILE"
	rm -rf anytls-client
	rm -rf readme.md
	
	echo -e "${Info} AnyTLS 下载安装完成！"
}

write_config(){
	cat > ${ANYTLS_CONF}<<-EOF
port=${port}
password=${password}
EOF
}

read_config(){
	[[ ! -e ${ANYTLS_CONF} ]] && echo -e "${Error} AnyTLS 配置文件不存在！" && exit 1
	port=$(cat ${ANYTLS_CONF} | grep "port=" | awk -F= '{print $2}')
	password=$(cat ${ANYTLS_CONF} | grep "password=" | awk -F= '{print $2}')
}

create_service(){
	cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=AnyTLS Server
After=network.target

[Service]
Type=simple
ExecStart=${ANYTLS_FILE} -l 0.0.0.0:${port} -p "${password}"
Restart=on-failure
RestartSec=5
AmbientCapabilities=CAP_NET_BIND_SERVICE
WorkingDirectory=${ANYTLS_DIR}
User=root

[Install]
WantedBy=multi-user.target
EOF
	
	systemctl daemon-reload
	systemctl enable anytls.service
	echo -e "${Info} AnyTLS 服务配置完成！"
}

install(){
	[[ -e ${ANYTLS_FILE} ]] && echo -e "${Error} 检测到 AnyTLS 已安装！" && exit 1
	
	echo -e "${Info} 开始设置配置..."
	set_port
	set_password
	
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
	
	echo -e "${Info} AnyTLS 安装完成！"
	view
}

view(){
	check_installed_status
	read_config
	getipv4
	getipv6
	
	clear && echo
	echo -e "AnyTLS Server 配置："
	echo -e "————————————————————————————————————————"
	[[ "${ipv4}" != "IPv4_Error" ]] && echo -e " IPv4 地址：${Green_font_prefix}${ipv4}${Font_color_suffix}"
	[[ "${ipv6}" != "IPv6_Error" ]] && echo -e " IPv6 地址：${Green_font_prefix}${ipv6}${Font_color_suffix}"
	echo -e " 监听端口：${Green_font_prefix}${port}${Font_color_suffix}"
	echo -e " 连接密码：${Green_font_prefix}${password}${Font_color_suffix}"
	echo -e "————————————————————————————————————————"
	
	if [[ "${ipv4}" != "IPv4_Error" ]]; then
		echo -e "\n客户端连接命令："
		echo -e "${Green_font_prefix}anytls-client -s ${ipv4}:${port} -p \"${password}\" -l 127.0.0.1:1080${Font_color_suffix}"
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
 ${Green_font_prefix}2.${Font_color_suffix}  修改 密码配置
========================================
 ${Green_font_prefix}3.${Font_color_suffix}  修改 全部配置" && echo
	read -e -p "(默认：取消)：" modify
	[[ -z "${modify}" ]] && echo -e "已取消..." && exit 1
	
	if [[ ${modify} == "1" ]]; then
		read_config
		set_port
		write_config
		create_service
		restart
	elif [[ ${modify} == "2" ]]; then
		read_config
		set_password
		write_config
		create_service
		restart
	elif [[ ${modify} == "3" ]]; then
		set_port
		set_password
		write_config
		create_service
		restart
	else
		echo -e "${Error} 请输入正确的数字(1-3)" && exit 1
	fi
}

start(){
	check_installed_status
	check_status
	if [[ "$status" == "running" ]]; then
		echo -e "${Info} AnyTLS 已在运行！"
	else
		systemctl start anytls
		sleep 2s
		check_status
		if [[ "$status" == "running" ]]; then
			echo -e "${Info} AnyTLS 启动成功！"
		else
			echo -e "${Error} AnyTLS 启动失败！"
		fi
	fi
	sleep 2s
}

stop(){
	check_installed_status
	check_status
	[[ "$status" != "running" ]] && echo -e "${Error} AnyTLS 没有运行，请检查！" && exit 1
	systemctl stop anytls
	sleep 2s
	check_status
	if [[ "$status" == "running" ]]; then
		echo -e "${Error} AnyTLS 停止失败！"
	else
		echo -e "${Info} AnyTLS 停止成功！"
	fi
}

restart(){
	check_installed_status
	systemctl restart anytls
	sleep 2s
	check_status
	if [[ "$status" == "running" ]]; then
		echo -e "${Info} AnyTLS 重启成功！"
	else
		echo -e "${Error} AnyTLS 重启失败！"
	fi
	sleep 2s
}

update(){
	check_installed_status
	check_new_ver
	
	echo -e "${Info} 开始更新 AnyTLS..."
	check_status
	[[ "$status" == "running" ]] && stop
	
	# 备份配置
	if [[ -e ${ANYTLS_CONF} ]]; then
		cp -f ${ANYTLS_CONF} "/tmp/anytls_config_backup.txt"
	fi
	
	download
	
	# 恢复配置
	if [[ -e "/tmp/anytls_config_backup.txt" ]]; then
		cp -f "/tmp/anytls_config_backup.txt" ${ANYTLS_CONF}
		rm -f "/tmp/anytls_config_backup.txt"
		read_config
		create_service
	fi
	
	start
	echo -e "${Info} AnyTLS 更新完成！"
}

uninstall(){
	check_installed_status
	echo -e "确定要卸载 AnyTLS？[y/N]"
	read -e -p "(默认：n)：" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_status
		[[ "$status" == "running" ]] && stop
		systemctl disable anytls
		rm -rf "${ANYTLS_DIR}"
		rm -rf "${SERVICE_FILE}"
		systemctl daemon-reload
		echo -e "${Info} AnyTLS 卸载完成！"
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
	
	echo -e "\nAnyTLS Server 状态："
	if [[ "$status" == "running" ]]; then
		echo -e " 状态：${Green_font_prefix}运行中${Font_color_suffix}"
	else
		echo -e " 状态：${Red_font_prefix}已停止${Font_color_suffix}"
	fi
	echo -e " 地址：${ipv4} / ${ipv6}"
	echo -e " 端口：${port}"
	echo -e " 密码：${password}"
	echo && echo -n " 按回车键返回主菜单..." && read
	start_menu
}

view_log(){
	check_installed_status
	echo -e "${Info} 显示 AnyTLS 最近 50 行日志："
	journalctl -u anytls -n 50 --no-pager
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
	
	if [[ -e ${ANYTLS_FILE} ]]; then
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
     AnyTLS 管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
========================================
  
==================状态==================
 AnyTLS Server    : [${status_show}]
========================================
==================菜单==================
 ${Green_font_prefix}1.${Font_color_suffix}  安装 AnyTLS
 ${Green_font_prefix}2.${Font_color_suffix}  更新 AnyTLS
 ${Green_font_prefix}3.${Font_color_suffix}  卸载 AnyTLS
————————————————————————————————————————
 ${Green_font_prefix}4.${Font_color_suffix}  启动 AnyTLS
 ${Green_font_prefix}5.${Font_color_suffix}  停止 AnyTLS
 ${Green_font_prefix}6.${Font_color_suffix}  重启 AnyTLS
————————————————————————————————————————
 ${Green_font_prefix}7.${Font_color_suffix}  修改 AnyTLS 配置
 ${Green_font_prefix}8.${Font_color_suffix}  查看 AnyTLS 配置
 ${Green_font_prefix}9.${Font_color_suffix}  查看 AnyTLS 状态
 ${Green_font_prefix}10.${Font_color_suffix} 查看 AnyTLS 日志
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