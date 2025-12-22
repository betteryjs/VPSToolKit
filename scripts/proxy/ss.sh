#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: Shadowsocks Rust 管理脚本（简化版）
#	功能：安装/卸载/更新/管理 Shadowsocks Rust
#=================================================

# 当前脚本版本号
sh_ver="1.0.0"

# Shadowsocks Rust 相关路径
SS_Folder="/etc/ss-rust"
SS_File="/usr/local/bin/ss-rust"
SS_Conf="/etc/ss-rust/config.json"
SS_Now_ver_File="/etc/ss-rust/ver.txt"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m" && Yellow_font_prefix="\033[0;33m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Yellow_font_prefix}[注意]${Font_color_suffix}"

check_root(){
	if [[ $EUID != 0 ]]; then
		echo -e "${Error} 当前账号非ROOT(或没有ROOT权限)，无法继续操作，请使用${Green_background_prefix} sudo su ${Font_color_suffix}来获取临时ROOT权限（执行后会提示输入当前账号的密码）。"
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
        arch="i686"
    elif [[ "$uname" == *"armv7"* ]] || [[ "$uname" == "armv6l" ]]; then
        arch="arm"
    elif [[ "$uname" == *"armv8"* ]] || [[ "$uname" == "aarch64" ]]; then
        arch="aarch64"
    else
        arch="x86_64"
    fi    
}

check_installed_status(){
	[[ ! -e ${SS_File} ]] && echo -e "${Error} Shadowsocks Rust 没有安装，请检查！" && exit 1
}

check_status(){
	status=`systemctl status ss-rust | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1`
}

check_new_ver(){
	new_ver=$(wget -qO- https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases| jq -r '[.[] | select(.prerelease == false) | select(.draft == false) | .tag_name] | .[0]')
	[[ -z ${new_ver} ]] && echo -e "${Error} Shadowsocks Rust 最新版本获取失败！" && exit 1
	echo -e "${Info} 检测到 Shadowsocks Rust 最新版本为 [ ${new_ver} ]"
}

check_ver_comparison(){
	now_ver=$(cat ${SS_Now_ver_File})
	if [[ "${now_ver}" != "${new_ver}" ]]; then
		echo -e "${Info} 发现 Shadowsocks Rust 已有新版本 [ ${new_ver} ]，旧版本 [ ${now_ver} ]"
		read -e -p "是否更新？[Y/n]：" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ $yn == [Yy] ]]; then
			check_status
			[[ "$status" == "running" ]] && stop
			\cp -f ${SS_Conf} "/tmp/ss_rust_config.json"
			rm -rf ${SS_Folder}
			download
			\cp -f "/tmp/ss_rust_config.json" ${SS_Conf}
			start
		fi
	else
		echo -e "${Info} 当前 Shadowsocks Rust 已是最新版本 [ ${new_ver} ] ！" && exit 1
	fi
}

# 官方源
stable_download() {
	echo -e "${Info} 默认开始下载官方源 Shadowsocks Rust ……"
	wget --no-check-certificate -N "https://github.com/shadowsocks/shadowsocks-rust/releases/download/${new_ver}/shadowsocks-${new_ver}.${arch}-unknown-linux-gnu.tar.xz"
	if [[ ! -e "shadowsocks-${new_ver}.${arch}-unknown-linux-gnu.tar.xz" ]]; then
		echo -e "${Error} Shadowsocks Rust 下载失败！"
		return 1 && exit 1
	else
		tar -xvf "shadowsocks-${new_ver}.${arch}-unknown-linux-gnu.tar.xz"
	fi
	if [[ ! -e "ssserver" ]]; then
		echo -e "${Error} Shadowsocks Rust 解压失败！"
		echo -e "${Error} 本次安装失败，请检查或更换系统后重新安装！"
		return 1 && exit 1
	else
		mv -f ssserver "${SS_File}"
		[[ ! -e ${SS_File} ]] && echo -e "${Error} Shadowsocks Rust 移动失败！" && return 1 && exit 1
		chmod +x "${SS_File}"
		echo "${new_ver}" > "${SS_Now_ver_File}"
		rm -rf "shadowsocks-${new_ver}.${arch}-unknown-linux-gnu.tar.xz"
		rm -rf sslocal ssmanager ssurl ssservice
		return 0
	fi
}

download() {
	if [[ ! -e "${SS_Folder}" ]]; then
		mkdir "${SS_Folder}"
	fi
	stable_download
}

service(){
	echo "
[Unit]
Description= Shadowsocks Rust Service
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service
[Service]
LimitNOFILE=32767 
Type=simple
User=root
Restart=on-failure
RestartSec=5s
DynamicUser=true
ExecStartPre=/bin/sh -c 'ulimit -n 51200'
ExecStart=${SS_File} -c ${SS_Conf}
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/ss-rust.service
systemctl enable --now ss-rust
	echo -e "${Info} Shadowsocks Rust 服务配置完成！"
}

installation_dependency(){
	if [[ ${release} == "centos" ]]; then
		echo -e "${Info} 正在安装/更新依赖..."
		yum install jq gzip wget curl unzip xz openssl -y
	else
		echo -e "${Info} 正在更新软件包列表..."
		apt-get install jq gzip wget curl unzip xz-utils openssl -y
	fi
	\cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
}

write_config(){
	cat > ${SS_Conf}<<-EOF
{
    "server": "::",
    "server_port": ${port},
    "password": "${password}",
    "method": "${cipher}",
    "fast_open": ${tfo},
    "mode": "tcp_and_udp",
    "user":"nobody",
    "timeout":300,
    "nameserver":"1.1.1.1"
}
EOF
}

read_config(){
	[[ ! -e ${SS_Conf} ]] && echo -e "${Error} Shadowsocks Rust 配置文件不存在！" && exit 1
	port=$(cat ${SS_Conf}|jq -r '.server_port')
	password=$(cat ${SS_Conf}|jq -r '.password')
	cipher=$(cat ${SS_Conf}|jq -r '.method')
	tfo=$(cat ${SS_Conf}|jq -r '.fast_open')
}

set_port(){
	while true
	do
	echo -e "请输入 Shadowsocks Rust 端口 [1-65535]"
	read -e -p "(默认：随机生成)：" port
	[[ -z "${port}" ]] && port=$(shuf -i 10000-60000 -n 1)
	echo $((${port}+0)) &>/dev/null
	if [[ $? -eq 0 ]]; then
		if [[ ${port} -ge 1 ]] && [[ ${port} -le 65535 ]]; then
			echo && echo "=================================="
			echo -e "	端口：${Red_background_prefix} ${port} ${Font_color_suffix}"
			echo "==================================" && echo
			break
		else
			echo -e "${Error} 请输入正确的数字(1-65535)"
		fi
	else
		echo -e "${Error} 请输入正确的数字(1-65535)"
	fi
	done
}

set_tfo(){
	echo -e "是否开启 TCP Fast Open ？
========================================
${Green_font_prefix} 1.${Font_color_suffix} 开启  ${Green_font_prefix} 2.${Font_color_suffix} 关闭
========================================"
	read -e -p "(默认：1.开启)：" tfo
	[[ -z "${tfo}" ]] && tfo="1"
	if [[ ${tfo} == "1" ]]; then
		tfo=true
	else
		tfo=false
	fi
	echo && echo "=================================="
	echo -e "TCP Fast Open 开启状态：${Red_background_prefix} ${tfo} ${Font_color_suffix}"
	echo "==================================" && echo
}

set_password(){
	echo "请输入 Shadowsocks Rust 密码 [0-9][a-z][A-Z]"
	read -e -p "(默认：随机生成)：" password
	if [[ -z "${password}" ]]; then
		password=$(< /dev/urandom tr -dc 'a-zA-Z0-9' | head -c 16)
	fi
	echo && echo "========================================"
	echo -e "密码：${Red_font_prefix} ${password} ${Font_color_suffix}"
	echo "========================================" && echo
}

set_cipher(){
	echo -e "请选择 Shadowsocks Rust 加密方式
========================================	
 ${Green_font_prefix} 1.${Font_color_suffix} aes-128-gcm ${Green_font_prefix}(默认)${Font_color_suffix}
 ${Green_font_prefix} 2.${Font_color_suffix} aes-256-gcm ${Green_font_prefix}(推荐)${Font_color_suffix}
 ${Green_font_prefix} 3.${Font_color_suffix} chacha20-ietf-poly1305
 ${Green_font_prefix} 4.${Font_color_suffix} 2022-blake3-aes-128-gcm ${Green_font_prefix}(推荐)${Font_color_suffix}
 ${Green_font_prefix} 5.${Font_color_suffix} 2022-blake3-aes-256-gcm ${Green_font_prefix}(推荐)${Font_color_suffix}
========================================" && echo
	read -e -p "(默认：2. aes-256-gcm)：" cipher_choice
	[[ -z "${cipher_choice}" ]] && cipher_choice="2"
	case "${cipher_choice}" in
		1) cipher="aes-128-gcm" ;;
		2) cipher="aes-256-gcm" ;;
		3) cipher="chacha20-ietf-poly1305" ;;
		4) 
			cipher="2022-blake3-aes-128-gcm"
			echo -e "${Tip} AEAD 2022 加密需要 Base64 编码的密码"
			password=$(openssl rand -base64 16)
			;;
		5) 
			cipher="2022-blake3-aes-256-gcm"
			echo -e "${Tip} AEAD 2022 加密需要 Base64 编码的密码"
			password=$(openssl rand -base64 32)
			;;
		*) cipher="aes-256-gcm" ;;
	esac
	echo && echo "=================================="
	echo -e "	加密：${Red_background_prefix} ${cipher} ${Font_color_suffix}"
	echo "==================================" && echo
}

set_config(){
	check_installed_status
	echo && echo -e "你要做什么？
========================================
 ${Green_font_prefix}1.${Font_color_suffix}  修改 端口配置
 ${Green_font_prefix}2.${Font_color_suffix}  修改 加密配置
 ${Green_font_prefix}3.${Font_color_suffix}  修改 密码配置
 ${Green_font_prefix}4.${Font_color_suffix}  修改 TFO 配置
========================================
 ${Green_font_prefix}5.${Font_color_suffix}  修改 全部配置" && echo
	read -e -p "(默认：取消)：" modify
	[[ -z "${modify}" ]] && echo -e "已取消..." && exit 1
	if [[ ${modify} == "1" ]]; then
		read_config
		set_port
		port=${port}
		write_config
		restart
	elif [[ ${modify} == "2" ]]; then
		read_config
		set_cipher
		cipher=${cipher}
		write_config
		restart
	elif [[ ${modify} == "3" ]]; then
		read_config
		set_password
		password=${password}
		write_config
		restart
	elif [[ ${modify} == "4" ]]; then
		read_config
		set_tfo
		tfo=${tfo}
		write_config
		restart
	elif [[ ${modify} == "5" ]]; then
		read_config
		set_port
		set_cipher
		set_password
		set_tfo
		write_config
		restart
	else
		echo -e "${Error} 请输入正确的数字(1-5)" && exit 1
	fi
}

install(){
	[[ -e ${SS_File} ]] && echo -e "${Error} 检测到 Shadowsocks Rust 已安装！" && exit 1
	echo -e "${Info} 开始设置 配置..."
	set_port
	set_cipher
	# 如果是 AEAD 2022 加密，密码已在 set_cipher 中生成
	if [[ "${cipher}" != "2022-blake3-aes-128-gcm" ]] && [[ "${cipher}" != "2022-blake3-aes-256-gcm" ]]; then
		set_password
	fi
	set_tfo
	echo -e "${Info} 开始安装/配置 依赖..."
	installation_dependency
	echo -e "${Info} 开始下载/安装..."
	check_new_ver
	download
	echo -e "${Info} 开始安装系统服务脚本..."
	service
	echo -e "${Info} 开始写入 配置文件..."
	write_config
	echo -e "${Info} 所有步骤 安装完毕，开始启动..."
	start
	echo -e "${Info} Shadowsocks Rust 安装完成！"
	view
}

view(){
	check_installed_status
	read_config
	getipv4
	getipv6
	link_qr
	clear && echo
	echo -e "Shadowsocks Rust 配置："
	echo -e "————————————————————————————————————————"
	[[ "${ipv4}" != "IPv4_Error" ]] && echo -e " 地址：${Green_font_prefix}${ipv4}${Font_color_suffix}"
	[[ "${ipv6}" != "IPv6_Error" ]] && echo -e " 地址：${Green_font_prefix}${ipv6}${Font_color_suffix}"
	echo -e " 端口：${Green_font_prefix}${port}${Font_color_suffix}"
	echo -e " 密码：${Green_font_prefix}${password}${Font_color_suffix}"
	echo -e " 加密：${Green_font_prefix}${cipher}${Font_color_suffix}"
	echo -e " TFO ：${Green_font_prefix}${tfo}${Font_color_suffix}"
	echo -e "————————————————————————————————————————"
	[[ ! -z "${link_ipv4}" ]] && echo -e "${link_ipv4}"
	[[ ! -z "${link_ipv6}" ]] && echo -e "${link_ipv6}"
	echo -e "—————————————————————————"
	echo -e "${Info} Surge 配置："
	if [[ "${ipv4}" != "IPv4_Error" ]]; then
		echo -e "$(uname -n) = ss, ${ipv4},${port}, encrypt-method=${cipher}, password=${password}, tfo=${tfo}, udp-relay=true"
	else
		echo -e "$(uname -n) = ss, ${ipv6},${port}, encrypt-method=${cipher}, password=${password}, tfo=${tfo}, udp-relay=true"
	fi
	echo -e "—————————————————————————"
	echo && echo -n " 按回车键返回主菜单..." && read
	start_menu
}

start(){
	check_installed_status
	check_status
	if [[ "$status" == "running" ]]; then
		echo -e "${Info} Shadowsocks Rust 已在运行！"
	else
		systemctl start ss-rust
		sleep 2s
		check_status
		if [[ "$status" == "running" ]]; then
			echo -e "${Info} Shadowsocks Rust 启动成功！"
		else
			echo -e "${Error} Shadowsocks Rust 启动失败！"
		fi
	fi
	sleep 3s
}

stop(){
	check_installed_status
	check_status
	[[ "$status" != "running" ]] && echo -e "${Error} Shadowsocks Rust 没有运行，请检查！" && exit 1
	systemctl stop ss-rust
	sleep 2s
	check_status
	if [[ "$status" == "running" ]]; then
		echo -e "${Error} Shadowsocks Rust 停止失败！"
	else
		echo -e "${Info} Shadowsocks Rust 停止成功！"
	fi
}

restart(){
	check_installed_status
	systemctl restart ss-rust
	sleep 2s
	check_status
	if [[ "$status" == "running" ]]; then
		echo -e "${Info} Shadowsocks Rust 重启成功！"
	else
		echo -e "${Error} Shadowsocks Rust 重启失败！"
	fi
	sleep 3s
}

update(){
	check_installed_status
	check_new_ver
	check_ver_comparison
}

update_sh(){
	sh_new_ver=$(wget -qO- -t1 -T3 "https://raw.githubusercontent.com/xOS/Others/master/shadowsocks-rust/ss-rust.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1)
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 无法连接到 Github！" && exit 0
	if [[ "${sh_new_ver}" != "${sh_ver}" ]]; then
		echo -e "发现新版本 [ ${sh_new_ver} ]，是否更新？[Y/n]"
		read -p "(默认：y)：" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ ${yn} == [Yy] ]]; then
			wget -N --no-check-certificate "https://raw.githubusercontent.com/xOS/Others/master/shadowsocks-rust/ss-rust.sh" && chmod +x ss-rust.sh
			echo -e "脚本已更新为最新版本 [ ${sh_new_ver} ] ！(注意：因为更新方式为直接覆盖当前运行的脚本，所以可能下面会提示一些报错，无视即可)"
		fi
	else
		echo -e "当前已是最新版本 [ ${sh_new_ver} ] ！"
	fi
}

uninstall(){
	check_installed_status
	echo -e "确定要卸载 Shadowsocks Rust？[y/N]"
	read -e -p "(默认：n)：" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_status
		[[ "$status" == "running" ]] && stop
		systemctl disable --now ss-rust
		rm -rf "${SS_Folder}"
		rm -rf "${SS_File}"
		rm -rf "/etc/systemd/system/ss-rust.service"
		systemctl daemon-reload
		echo -e "${Info} Shadowsocks Rust 卸载完成！"
	else
		echo -e "${Info} 卸载已取消..."
	fi
}

getipv4(){
	ipv4=$(wget -qO- -4 -t1 -T2 ipinfo.io/ip)
	if [[ -z "${ipv4}" ]]; then
		ipv4=$(wget -qO- -4 -t1 -T2 api.ip.sb/ip)
		if [[ -z "${ipv4}" ]]; then
			ipv4=$(wget -qO- -4 -t1 -T2 members.3322.org/dyndns/getip)
			if [[ -z "${ipv4}" ]]; then
				ipv4="IPv4_Error"
			fi
		fi
	fi
}

getipv6(){
	ipv6=$(wget -qO- -6 -t1 -T2 ifconfig.co)
	[[ -z "${ipv6}" ]] && ipv6="IPv6_Error"
}

urlsafe_base64(){
	date=$(echo -n "$1"|base64|sed ':a;N;s/\n/ /g;ta'|sed 's/ //g;s/=//g;s/+/-/g;s/\//_/g')
	echo -e "${date}"
}

link_qr(){
	if [[ "${ipv4}" != "IPv4_Error" ]]; then
		ss_link=$(urlsafe_base64 "${cipher}:${password}@${ipv4}:${port}")
		ss_link="ss://${ss_link}"
		link_ipv4=" 链接：${Red_font_prefix}${ss_link}${Font_color_suffix} \n 二维码：https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${ss_link}"
	fi
	if [[ "${ipv6}" != "IPv6_Error" ]]; then
		ss_link=$(urlsafe_base64 "${cipher}:${password}@${ipv6}:${port}")
		ss_link="ss://${ss_link}"
		link_ipv6=" 链接：${Red_font_prefix}${ss_link}${Font_color_suffix} \n 二维码：https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${ss_link}"
	fi
}

view_status(){
	check_installed_status
	check_status
	read_config
	getipv4
	getipv6
	echo -e "\nShadowsocks Rust 状态："
	if [[ "$status" == "running" ]]; then
		echo -e " 状态：${Green_font_prefix}运行中${Font_color_suffix}"
	else
		echo -e " 状态：${Red_font_prefix}已停止${Font_color_suffix}"
	fi
	echo -e " 地址：${ipv4} / ${ipv6}"
	echo -e " 端口：${port}"
	echo -e " 密码：${password}"
	echo -e " 加密：${cipher}"
	echo && echo -n " 按回车键返回主菜单..." && read
	start_menu
}

start_menu(){
	clear
	check_root
	check_sys
	sys_arch
	
	if [[ -e ${SS_File} ]]; then
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
  Shadowsocks Rust 管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
========================================
  
==================状态==================
 Shadowsocks Rust : [${status_show}]
========================================
 ${Green_font_prefix}1.${Font_color_suffix}  更新脚本
==================菜单==================
 ${Green_font_prefix}2.${Font_color_suffix}  安装 Shadowsocks Rust
 ${Green_font_prefix}3.${Font_color_suffix}  更新 Shadowsocks Rust
 ${Green_font_prefix}4.${Font_color_suffix}  卸载 Shadowsocks Rust
————————————————————————————————————————
 ${Green_font_prefix}5.${Font_color_suffix}  启动 Shadowsocks Rust
 ${Green_font_prefix}6.${Font_color_suffix}  停止 Shadowsocks Rust
 ${Green_font_prefix}7.${Font_color_suffix}  重启 Shadowsocks Rust
————————————————————————————————————————
 ${Green_font_prefix}8.${Font_color_suffix}  修改 Shadowsocks Rust 配置
 ${Green_font_prefix}9.${Font_color_suffix}  查看 Shadowsocks Rust 配置
 ${Green_font_prefix}10.${Font_color_suffix}  查看 Shadowsocks Rust 状态
————————————————————————————————————————
 ${Green_font_prefix}0.${Font_color_suffix} 退出脚本
========================================" && echo
	
	read -e -p " 请输入数字 [0-9]：" num
	case "$num" in
		1)
		update_sh
		;;
		2)
		install
		;;
		3)
		update
		;;
		4)
		uninstall
		;;
		5)
		start
		;;
		6)
		stop
		;;
		7)
		restart
		;;
		8)
		set_config
		;;
		9)
		view
		;;
		10)
		view_status
		;;
		0)
		return
		;;
		*)
		echo -e "${Error} 请输入正确的数字 [0-9]"
		sleep 2s
		start_menu
		;;
	esac
}

# 脚本执行入口
start_menu



