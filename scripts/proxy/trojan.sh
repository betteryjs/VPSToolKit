#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: Trojan-Go 管理脚本
#	功能：安装/卸载/更新/管理 Trojan-Go
#	项目地址：https://github.com/p4gefau1t/trojan-go
#=================================================

# 当前脚本版本号
sh_ver="1.0.0"

# Trojan-Go 相关路径
TROJAN_DIR="/etc/trojan-go"
TROJAN_FILE="${TROJAN_DIR}/trojan-go"
TROJAN_CONF="${TROJAN_DIR}/config.json"
SERVICE_FILE="/etc/systemd/system/trojan-go.service"
CERT_DIR="${TROJAN_DIR}/cert"

# 默认配置
DEFAULT_PORT=10244

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
		arch="386"
	elif [[ "$uname" == *"armv7"* ]] || [[ "$uname" == "armv6l" ]]; then
		arch="armv7"
	elif [[ "$uname" == *"armv8"* ]] || [[ "$uname" == "aarch64" ]]; then
		arch="arm64"
	else
		arch="amd64"
	fi
}

check_installed_status(){
	[[ ! -e ${TROJAN_FILE} ]] && echo -e "${Error} Trojan-Go 没有安装，请检查！" && exit 1
}

check_status(){
	status=$(systemctl status trojan-go 2>/dev/null | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
	[[ -z "${status}" ]] && status="未运行"
}

check_new_ver(){
	new_ver=$(curl -sL https://api.github.com/repos/p4gefau1t/trojan-go/releases/latest | jq -r '.tag_name')
	[[ -z ${new_ver} ]] && echo -e "${Error} Trojan-Go 最新版本获取失败！" && exit 1
	echo -e "${Info} 检测到 Trojan-Go 最新版本为 [ ${new_ver} ]"
}

installation_dependency(){
	echo -e "${Info} 正在安装/更新依赖..."
	if [[ ${release} == "centos" ]]; then
		yum install wget unzip jq curl socat -y
	else
		apt-get update
		apt-get install wget unzip jq curl socat -y
	fi
}

install_acme(){
	if [[ ! -e ~/.acme.sh/acme.sh ]]; then
		echo -e "${Info} 安装 acme.sh..."
		curl https://get.acme.sh | sh
		if [[ ! -e ~/.acme.sh/acme.sh ]]; then
			echo -e "${Error} acme.sh 安装失败！"
			return 1
		fi
		# 启用自动升级
		~/.acme.sh/acme.sh --upgrade --auto-upgrade
	fi
	
	# 确保 cron 任务已安装（用于自动续订证书）
	if ! crontab -l 2>/dev/null | grep -q "acme.sh"; then
		echo -e "${Info} 配置 acme.sh 自动续订任务..."
		~/.acme.sh/acme.sh --install-cronjob
	fi
	
	return 0
}

set_domain(){
	echo -e "请输入绑定到本 VPS 的域名"
	read -e -p "域名：" your_domain
	[[ -z "${your_domain}" ]] && echo -e "${Error} 域名不能为空！" && return 1
	
	# 验证域名格式（基本检查：至少包含一个点，不包含非法字符）
	if [[ ! "$your_domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)+$ ]]; then
		echo -e "${Error} 域名格式不正确！"
		echo -e "${Error} 域名应为类似 example.com 或 sub.example.com 的格式"
		return 1
	fi
	
	echo && echo "=================================="
	echo -e "	域名：${Red_background_prefix} ${your_domain} ${Font_color_suffix}"
	echo "==================================" && echo
	
	# 验证域名解析
	echo -e "${Info} 正在验证域名解析..."
	real_addr=$(ping ${your_domain} -c 1 2>/dev/null | sed '1{s/[^(]*(//;s/).*//;q}')
	
	# 如果 ping 失败，尝试使用 nslookup 或 dig
	if [[ -z "${real_addr}" ]]; then
		real_addr=$(nslookup ${your_domain} 2>/dev/null | grep -A1 "Name:" | tail -1 | awk '{print $2}')
	fi
	
	if [[ -z "${real_addr}" ]]; then
		echo -e "${Error} 无法解析域名 ${your_domain}！"
		echo -e "${Error} 请检查：1) 域名是否正确  2) DNS 是否已配置  3) DNS 记录是否已生效"
		return 1
	fi
	
	local_addr=$(curl -s ipv4.icanhazip.com)
	
	if [[ "$real_addr" == "$local_addr" ]]; then
		echo -e "${Info} 域名解析正常"
		echo -e "域名: ${Green_font_prefix}${your_domain}${Font_color_suffix} → IP: ${Green_font_prefix}${local_addr}${Font_color_suffix}"
	else
		echo -e "${Error} 域名解析地址与本 VPS IP 地址不一致！"
		echo -e "域名解析地址: ${Red_font_prefix}${real_addr}${Font_color_suffix}"
		echo -e "本机 IP 地址: ${Red_font_prefix}${local_addr}${Font_color_suffix}"
		echo -e "${Error} 请确保域名已正确解析到本 VPS 后再运行脚本！"
		return 1
	fi
	return 0
}

set_mode(){
	echo -e "请选择 Trojan-Go 运行模式
========================================
 ${Green_font_prefix}1.${Font_color_suffix} Websocket 模式 (推荐，无需证书)
 ${Green_font_prefix}2.${Font_color_suffix} TLS 模式 (需要证书)
========================================"
	read -e -p "(默认：1. Websocket)：" mode_choice
	[[ -z "${mode_choice}" ]] && mode_choice="1"
	
	if [[ ${mode_choice} == "2" ]]; then
		mode="tls"
		echo -e "请选择证书配置方式
========================================
 ${Green_font_prefix}1.${Font_color_suffix} 自动申请证书 (推荐)
 ${Green_font_prefix}2.${Font_color_suffix} 使用已有证书
========================================"
		read -e -p "(默认：1. 自动申请)：" cert_choice
		[[ -z "${cert_choice}" ]] && cert_choice="1"
		
		if [[ ${cert_choice} == "1" ]]; then
			apply_cert
			if [[ $? != 0 ]]; then
				echo -e "${Error} 证书申请失败，安装终止！"
				exit 1
			fi
		else
			echo -e "${Tip} 请提供已有的证书文件"
			read -e -p "请输入证书路径 (fullchain.cer)：" cert_path
			read -e -p "请输入密钥路径 (private.key)：" key_path
			
			if [[ ! -f "${cert_path}" ]] || [[ ! -f "${key_path}" ]]; then
				echo -e "${Error} 证书文件不存在！"
				exit 1
			fi
		fi
		port=10244
	else
		mode="websocket"
		read -e -p "请输入 Websocket 路径 (默认: /ws)：" ws_path
		[[ -z "${ws_path}" ]] && ws_path="/ws"
	fi
	
	echo && echo "=================================="
	echo -e "	模式：${Red_background_prefix} ${mode} ${Font_color_suffix}"
	echo "==================================" && echo
}

apply_cert(){
	set_domain
	if [[ $? != 0 ]]; then
		echo -e "${Error} 域名解析验证失败，无法申请证书！"
		return 1
	fi
	
	# 创建证书目录
	if [[ ! -d "${CERT_DIR}/${your_domain}" ]]; then
		mkdir -p "${CERT_DIR}/${your_domain}"
	fi
	
	# 检查是否已有证书且未过期（使用 openssl 检查证书有效期）
	if [[ -f "${CERT_DIR}/${your_domain}/fullchain.cer" ]] && [[ -f "${CERT_DIR}/${your_domain}/private.key" ]]; then
		# 获取证书过期时间（秒数）
		cert_end_time=$(openssl x509 -enddate -noout -in "${CERT_DIR}/${your_domain}/fullchain.cer" 2>/dev/null | cut -d= -f2)
		if [[ -n "$cert_end_time" ]]; then
			cert_end_timestamp=$(date -d "$cert_end_time" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$cert_end_time" +%s 2>/dev/null)
			now_timestamp=$(date +%s)
			days_left=$(( (cert_end_timestamp - now_timestamp) / 86400 ))
			
			if [[ $days_left -gt 30 ]]; then
				echo -e "${Info} 检测到域名 ${your_domain} 证书有效期还剩 ${days_left} 天"
				echo -e "${Info} 证书有效期充足，无需重新申请"
				cert_path="${CERT_DIR}/${your_domain}/fullchain.cer"
				key_path="${CERT_DIR}/${your_domain}/private.key"
				return 0
			else
				echo -e "${Tip} 证书有效期仅剩 ${days_left} 天，将重新申请证书"
			fi
		else
			echo -e "${Tip} 无法读取证书有效期，将重新申请证书"
		fi
	fi
	
	# 安装依赖
	echo -e "${Info} 检查并安装必要的依赖..."
	installation_dependency
	
	# 安装 acme.sh
	install_acme
	if [[ $? != 0 ]]; then
		return 1
	fi
	
	# 检查80端口
	Port80=$(netstat -tlpn 2>/dev/null | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 80)
	if [[ -n "$Port80" ]]; then
		echo -e "${Error} 检测到80端口被占用，无法申请证书！"
		return 1
	fi
	
	echo -e "${Info} 开始申请 SSL 证书..."
	~/.acme.sh/acme.sh --register-account -m test@${your_domain} --server zerossl
	
	# 如果证书已存在但需要续订，使用 --force 强制续订
	if [[ -f "${CERT_DIR}/${your_domain}/fullchain.cer" ]]; then
		echo -e "${Info} 强制续订证书..."
		~/.acme.sh/acme.sh --issue -d ${your_domain} --standalone --force
	else
		~/.acme.sh/acme.sh --issue -d ${your_domain} --standalone
	fi
	
	# 检查证书是否申请成功（支持 ECC 和 RSA）
	if [[ -s ~/.acme.sh/${your_domain}_ecc/fullchain.cer ]]; then
		cert_dir="~/.acme.sh/${your_domain}_ecc"
		echo -e "${Info} 检测到 ECC 证书申请成功"
	elif [[ -s ~/.acme.sh/${your_domain}/fullchain.cer ]]; then
		cert_dir="~/.acme.sh/${your_domain}"
		echo -e "${Info} 检测到 RSA 证书申请成功"
	else
		echo -e "${Error} 证书申请失败！"
		return 1
	fi
	
	# 安装证书到目标目录
	echo -e "${Info} 安装证书到 ${CERT_DIR}/${your_domain}/"
	~/.acme.sh/acme.sh --installcert -d ${your_domain} \
		--key-file "${CERT_DIR}/${your_domain}/private.key" \
		--fullchain-file "${CERT_DIR}/${your_domain}/fullchain.cer" \
		--reloadcmd "systemctl restart trojan-go 2>/dev/null || true"
	
	# 验证证书是否安装成功
	if [[ -s "${CERT_DIR}/${your_domain}/fullchain.cer" ]] && [[ -s "${CERT_DIR}/${your_domain}/private.key" ]]; then
		echo -e "${Info} 证书安装成功！"
		echo -e "${Info} 证书路径: ${CERT_DIR}/${your_domain}/"
		echo -e "${Info} acme.sh 将自动续订证书并同步到此目录"
		echo -e "${Info} 续订后会自动重启 trojan-go 服务"
		cert_path="${CERT_DIR}/${your_domain}/fullchain.cer"
		key_path="${CERT_DIR}/${your_domain}/private.key"
		return 0
	else
		echo -e "${Error} 证书安装失败！"
		return 1
	fi
}

repair_cert(){
	check_installed_status
	
	echo -e "${Info} 开始修复/更新证书..."
	
	# 检查是否安装了 acme.sh
	if [[ ! -e ~/.acme.sh/acme.sh ]]; then
		echo -e "${Error} 未安装 acme.sh，请先申请证书！"
		return 1
	fi
	
	set_domain
	if [[ $? != 0 ]]; then
		echo -e "${Error} 域名解析验证失败，无法修复证书！"
		return 1
	fi
	
	# 创建证书目录
	if [[ ! -d "${CERT_DIR}/${your_domain}" ]]; then
		mkdir -p "${CERT_DIR}/${your_domain}"
	fi
	
	# 安装依赖
	echo -e "${Info} 检查并安装必要的依赖..."
	installation_dependency
	
	# 检查80端口
	Port80=$(netstat -tlpn 2>/dev/null | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 80)
	if [[ -n "$Port80" ]]; then
		echo -e "${Error} 检测到80端口被占用，无法申请证书！"
		return 1
	fi
	
	echo -e "${Info} 重新申请证书..."
	~/.acme.sh/acme.sh --register-account -m test@${your_domain} --server zerossl
	~/.acme.sh/acme.sh --issue -d ${your_domain} --standalone --force
	
	# 检查证书是否申请成功（支持 ECC 和 RSA）
	if [[ -s ~/.acme.sh/${your_domain}_ecc/fullchain.cer ]]; then
		echo -e "${Info} 检测到 ECC 证书申请成功"
	elif [[ -s ~/.acme.sh/${your_domain}/fullchain.cer ]]; then
		echo -e "${Info} 检测到 RSA 证书申请成功"
	else
		echo -e "${Error} 证书申请失败！"
		return 1
	fi
	
	# 安装证书到目标目录
	echo -e "${Info} 安装证书到 ${CERT_DIR}/${your_domain}/"
	~/.acme.sh/acme.sh --installcert -d ${your_domain} \
		--key-file "${CERT_DIR}/${your_domain}/private.key" \
		--fullchain-file "${CERT_DIR}/${your_domain}/fullchain.cer" \
		--reloadcmd "systemctl restart trojan-go"
	
	# 验证证书是否安装成功
	if [[ -s "${CERT_DIR}/${your_domain}/fullchain.cer" ]] && [[ -s "${CERT_DIR}/${your_domain}/private.key" ]]; then
		echo -e "${Info} 证书修复成功！"
		echo -e "${Info} 证书路径: ${CERT_DIR}/${your_domain}/"
		echo -e "${Info} acme.sh 将自动续订证书并同步到此目录"
		systemctl restart trojan-go
		return 0
	else
		echo -e "${Error} 证书安装失败！"
		return 1
	fi
}

set_port(){
	echo -e "请输入 Trojan-Go 监听端口 [1-65535]"
	read -e -p "(默认：${DEFAULT_PORT})：" port
	[[ -z "${port}" ]] && port=${DEFAULT_PORT}
	echo && echo "=================================="
	echo -e "	端口：${Red_background_prefix} ${port} ${Font_color_suffix}"
	echo "==================================" && echo
}

set_password(){
	echo "请输入 Trojan-Go 密码"
	read -e -p "(默认：随机生成)：" password
	[[ -z "${password}" ]] && password=$(< /dev/urandom tr -dc 'a-zA-Z0-9' | head -c 16)
	echo && echo "========================================"
	echo -e "密码：${Red_font_prefix} ${password} ${Font_color_suffix}"
	echo "========================================" && echo
}

set_mode(){
	echo -e "请选择 Trojan-Go 运行模式
========================================
 ${Green_font_prefix}1.${Font_color_suffix} Websocket 模式 (推荐)
 ${Green_font_prefix}2.${Font_color_suffix} TLS 模式
========================================"
	read -e -p "(默认：1. Websocket)：" mode_choice
	[[ -z "${mode_choice}" ]] && mode_choice="1"
	
	# 无论哪种模式都需要证书
	echo -e "${Info} Trojan-Go 需要 TLS 证书，开始申请..."
	apply_cert
	if [[ $? != 0 ]]; then
		echo -e "${Error} 证书申请失败，安装终止！"
		exit 1
	fi
	
	if [[ ${mode_choice} == "2" ]]; then
		mode="tls"
		port=10244
	else
		mode="websocket"
		port=10244
		read -e -p "请输入 Websocket 路径 (默认: /ws)：" ws_path
		[[ -z "${ws_path}" ]] && ws_path="/ws"
	fi
	
	echo && echo "=================================="
	echo -e "	模式：${Red_background_prefix} ${mode} ${Font_color_suffix}"
	echo "==================================" && echo
}

download(){
	cd /tmp
	sys_arch
	
	echo -e "${Info} 开始下载 Trojan-Go ${new_ver}..."
	ZIPFILE="trojan-go-linux-${arch}.zip"
	
	# 清理旧的下载文件
	rm -f "${ZIPFILE}" "${ZIPFILE}."*
	rm -f trojan-go geoip.dat geosite.dat example/
	
	# 下载文件（使用 -O 强制指定文件名，避免 .1 .2 等后缀）
	wget -O "${ZIPFILE}" "https://github.com/p4gefau1t/trojan-go/releases/download/${new_ver}/${ZIPFILE}"
	
	if [[ ! -e "${ZIPFILE}" ]]; then
		echo -e "${Error} Trojan-Go 下载失败！"
		exit 1
	fi
	
	# 检查文件是否为有效的 zip 文件
	if ! unzip -t "${ZIPFILE}" >/dev/null 2>&1; then
		echo -e "${Error} 下载的文件损坏或不是有效的 ZIP 文件！"
		rm -f "${ZIPFILE}"
		exit 1
	fi
	
	echo -e "${Info} 解压文件..."
	unzip -o "$ZIPFILE"
	
	if [[ ! -e "trojan-go" ]]; then
		echo -e "${Error} Trojan-Go 解压失败！"
		rm -f "$ZIPFILE"
		exit 1
	fi
	
	# 创建目录
	if [ ! -d "$TROJAN_DIR" ]; then
		mkdir -p "$TROJAN_DIR"
		echo -e "${Info} 文件夹 $TROJAN_DIR 已创建。"
	fi
	
	# 移动文件
	chmod +x trojan-go
	mv -f trojan-go "${TROJAN_FILE}"
	
	# 清理
	rm -f "$ZIPFILE"
	rm -rf geoip.dat geosite.dat example/
	
	echo -e "${Info} Trojan-Go 下载安装完成！"
}

write_config(){
	if [[ "${mode}" == "websocket" ]]; then
		cat > ${TROJAN_CONF}<<-EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": ${port},
    "remote_addr": "127.0.0.1",
    "remote_port": 8080,
    "password": [
        "${password}"
    ],
    "log_level": 1,
    "ssl": {
        "verify": true,
        "verify_hostname": true,
        "cert": "${cert_path}",
        "key": "${key_path}",
        "sni": "",
        "fallback_port": 8080
    },
    "tcp": {
        "prefer_ipv4": false
    },
    "websocket": {
        "enabled": true,
        "path": "${ws_path}",
        "hostname": ""
    }
}
EOF
	else
		cat > ${TROJAN_CONF}<<-EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": ${port},
    "remote_addr": "127.0.0.1",
    "remote_port": 8080,
    "password": [
        "${password}"
    ],
    "log_level": 1,
    "ssl": {
        "verify": true,
        "verify_hostname": true,
        "cert": "${cert_path}",
        "key": "${key_path}",
        "sni": "",
        "fallback_port": 8080
    },
    "tcp": {
        "prefer_ipv4": false
    }
}
EOF
	fi
}

read_config(){
	[[ ! -e ${TROJAN_CONF} ]] && echo -e "${Error} Trojan-Go 配置文件不存在！" && exit 1
	port=$(cat ${TROJAN_CONF} | jq -r '.local_port')
	password=$(cat ${TROJAN_CONF} | jq -r '.password[0]')
	ws_enabled=$(cat ${TROJAN_CONF} | jq -r '.websocket.enabled')
	if [[ "${ws_enabled}" == "true" ]]; then
		mode="websocket"
		ws_path=$(cat ${TROJAN_CONF} | jq -r '.websocket.path')
	else
		mode="tls"
		cert_path=$(cat ${TROJAN_CONF} | jq -r '.ssl.cert')
		key_path=$(cat ${TROJAN_CONF} | jq -r '.ssl.key')
	fi
}

create_service(){
	cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Trojan-Go Server
After=network.target

[Service]
Type=simple
ExecStart=${TROJAN_FILE} -config ${TROJAN_CONF}
Restart=on-failure
RestartSec=5
WorkingDirectory=${TROJAN_DIR}
User=root

[Install]
WantedBy=multi-user.target
EOF
	
	systemctl daemon-reload
	systemctl enable trojan-go.service
	echo -e "${Info} Trojan-Go 服务配置完成！"
}

setup_fallback_http(){
	echo -e "${Info} 设置 Fallback HTTP 服务..."
	
	# 创建 HTML 目录和页面
	mkdir -p /var/www/trojan-fallback
	cat > /var/www/trojan-fallback/index.html <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 50px; text-align: center; }
        h1 { color: #333; }
    </style>
</head>
<body>
    <h1>Welcome to My Server</h1>
    <p>This is a simple web page.</p>
</body>
</html>
EOF
	
	# 检查是否安装了 Python3
	if ! command -v python3 &> /dev/null; then
		echo -e "${Info} 安装 Python3..."
		if [[ ${release} == "centos" ]]; then
			yum install -y python3
		else
			apt-get install -y python3
		fi
	fi
	
	# 创建 systemd 服务用于 fallback HTTP
	cat > /etc/systemd/system/trojan-fallback.service <<EOF
[Unit]
Description=Trojan Fallback HTTP Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 -m http.server 8080 -d /var/www/trojan-fallback
Restart=on-failure
RestartSec=5
WorkingDirectory=/var/www/trojan-fallback
User=root

[Install]
WantedBy=multi-user.target
EOF
	
	systemctl daemon-reload
	systemctl enable trojan-fallback.service
	systemctl start trojan-fallback.service
	
	# 检查服务状态
	sleep 1
	if systemctl is-active --quiet trojan-fallback; then
		echo -e "${Info} Fallback HTTP 服务启动成功（端口 8080）"
	else
		echo -e "${Error} Fallback HTTP 服务启动失败"
		return 1
	fi
	
	return 0
}

install(){
	[[ -e ${TROJAN_FILE} ]] && echo -e "${Error} 检测到 Trojan-Go 已安装！" && exit 1
	
	echo -e "${Info} 开始设置配置..."
	set_port
	set_password
	set_mode
	
	echo -e "${Info} 开始安装/配置依赖..."
	installation_dependency
	
	echo -e "${Info} 开始下载/安装..."
	check_new_ver
	download
	
	echo -e "${Info} 开始写入配置文件..."
	write_config
	
	echo -e "${Info} 开始安装系统服务..."
	create_service
	
	# 两种模式都需要设置 fallback HTTP 服务
	setup_fallback_http
	
	echo -e "${Info} 所有步骤安装完毕，开始启动..."
	start
	
	echo -e "${Info} Trojan-Go 安装完成！"
	view
}

view(){
	check_installed_status
	read_config
	getipv4
	getipv6
	
	echo -e "========================================"

	# clear && echo
	echo -e "Trojan-Go Server 配置："
	echo -e "————————————————————————————————————————"
	[[ "${ipv4}" != "IPv4_Error" ]] && echo -e " IPv4 地址：${Green_font_prefix}${ipv4}${Font_color_suffix}"
	[[ "${ipv6}" != "IPv6_Error" ]] && echo -e " IPv6 地址：${Green_font_prefix}${ipv6}${Font_color_suffix}"
	echo -e " 监听端口：${Green_font_prefix}${port}${Font_color_suffix}"
	echo -e " 连接密码：${Green_font_prefix}${password}${Font_color_suffix}"
	echo -e " 运行模式：${Green_font_prefix}${mode}${Font_color_suffix}"
	
	if [[ "${mode}" == "websocket" ]]; then
		echo -e " WS 路径：${Green_font_prefix}${ws_path}${Font_color_suffix}"
	else
		echo -e " 证书路径：${Green_font_prefix}${cert_path}${Font_color_suffix}"
		echo -e " 密钥路径：${Green_font_prefix}${key_path}${Font_color_suffix}"
	fi
	
	echo -e "————————————————————————————————————————"
	
	if [[ "${ipv4}" != "IPv4_Error" ]] && [[ "${mode}" == "websocket" ]]; then
		echo -e "\n客户端配置示例："
		echo -e "${Green_font_prefix}服务器地址: ${ipv4}${Font_color_suffix}"
		echo -e "${Green_font_prefix}端口: ${port}${Font_color_suffix}"
		echo -e "${Green_font_prefix}密码: ${password}${Font_color_suffix}"
		echo -e "${Green_font_prefix}Websocket: 是${Font_color_suffix}"
		echo -e "${Green_font_prefix}路径: ${ws_path}${Font_color_suffix}"
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
		read_config  # 保留原有模式配置
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
		echo -e "${Info} Trojan-Go 已在运行！"
	else
		systemctl start trojan-go
		sleep 2s
		check_status
		if [[ "$status" == "running" ]]; then
			echo -e "${Info} Trojan-Go 启动成功！"
		else
			echo -e "${Error} Trojan-Go 启动失败！"
			echo -e "${Error} 正在显示错误日志和配置..."
			echo -e "==================================配置文件=================================="
			cat ${TROJAN_CONF}
			echo -e "==================================错误日志=================================="
			journalctl -u trojan-go -n 20 --no-pager
			echo -e "=========================================================================="
			echo -e "${Tip} 请检查配置文件: ${TROJAN_CONF}"
			echo -e "${Tip} 或使用命令查看完整日志: journalctl -u trojan-go -f"
		fi
	fi
	sleep 2s
}

stop(){
	check_installed_status
	check_status
	[[ "$status" != "running" ]] && echo -e "${Error} Trojan-Go 没有运行，请检查！" && exit 1
	systemctl stop trojan-go
	sleep 2s
	check_status
	if [[ "$status" == "running" ]]; then
		echo -e "${Error} Trojan-Go 停止失败！"
	else
		echo -e "${Info} Trojan-Go 停止成功！"
	fi
}

restart(){
	check_installed_status
	systemctl restart trojan-go
	sleep 2s
	check_status
	if [[ "$status" == "running" ]]; then
		echo -e "${Info} Trojan-Go 重启成功！"
	else
		echo -e "${Error} Trojan-Go 重启失败！"
	fi
	sleep 2s
}

update(){
	check_installed_status
	check_new_ver
	
	# 获取当前版本
	current_ver=$(${TROJAN_FILE} --version 2>/dev/null | head -n 1 | awk '{print $2}')
	
	if [[ -z "${current_ver}" ]]; then
		echo -e "${Error} 无法获取当前版本信息！"
		exit 1
	fi
	
	echo -e "${Info} 当前版本：${current_ver}"
	echo -e "${Info} 最新版本：${new_ver}"
	
	# 比较版本
	if [[ "${current_ver}" == "${new_ver}" ]]; then
		echo -e "${Info} 已经是最新版本了！无需更新！"
		return 0
	fi
	
	echo -e "${Info} 开始更新 Trojan-Go..."
	check_status
	[[ "$status" == "running" ]] && stop
	
	# 备份配置
	if [[ -e ${TROJAN_CONF} ]]; then
		cp -f ${TROJAN_CONF} "/tmp/trojan_go_config_backup.json"
	fi
	
	download
	
	# 恢复配置
	if [[ -e "/tmp/trojan_go_config_backup.json" ]]; then
		cp -f "/tmp/trojan_go_config_backup.json" ${TROJAN_CONF}
		rm -f "/tmp/trojan_go_config_backup.json"
		read_config
		create_service
	fi
	
	start
	echo -e "${Info} Trojan-Go 更新完成！"
}

uninstall(){
	check_installed_status
	echo -e "确定要卸载 Trojan-Go？[y/N]"
	read -e -p "(默认：n)：" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_status
		[[ "$status" == "running" ]] && stop
		
		# 停止并卸载 Trojan-Go 服务
		systemctl stop trojan-go 2>/dev/null
		systemctl disable trojan-go 2>/dev/null
		
		# 停止并卸载 Fallback HTTP 服务（无条件执行）
		echo -e "${Info} 停止 Fallback HTTP 服务..."
		systemctl stop trojan-fallback 2>/dev/null
		systemctl disable trojan-fallback 2>/dev/null
		
		# 查找并杀死所有相关进程
		pkill -f "python3 -m http.server 8080" 2>/dev/null
		pkill -f "trojan-go" 2>/dev/null
		
		# 删除文件和目录
		rm -rf "${TROJAN_DIR}"
		rm -f "${SERVICE_FILE}"
		rm -f /etc/systemd/system/trojan-fallback.service
		rm -rf /var/www/trojan-fallback
		
		systemctl daemon-reload
		echo -e "${Info} Trojan-Go 及相关服务卸载完成！"
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
	
	echo -e "\nTrojan-Go Server 状态："
	if [[ "$status" == "running" ]]; then
		echo -e " 状态：${Green_font_prefix}运行中${Font_color_suffix}"
	else
		echo -e " 状态：${Red_font_prefix}已停止${Font_color_suffix}"
	fi
	echo -e " 地址：${ipv4} / ${ipv6}"
	echo -e " 端口：${port}"
	echo -e " 密码：${password}"
	echo -e " 模式：${mode}"
	echo && echo -n " 按回车键返回主菜单..." && read
	start_menu
}

view_log(){
	check_installed_status
	echo -e "${Info} 显示 Trojan-Go 最近 50 行日志："
	journalctl -u trojan-go -n 50 --no-pager
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
	
	if [[ -e ${TROJAN_FILE} ]]; then
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
   Trojan-Go 管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
========================================
  
==================状态==================
 Trojan-Go Server : [${status_show}]
========================================
==================菜单==================
 ${Green_font_prefix}1.${Font_color_suffix}  安装 Trojan-Go
 ${Green_font_prefix}2.${Font_color_suffix}  更新 Trojan-Go
 ${Green_font_prefix}3.${Font_color_suffix}  卸载 Trojan-Go
————————————————————————————————————————
 ${Green_font_prefix}4.${Font_color_suffix}  启动 Trojan-Go
 ${Green_font_prefix}5.${Font_color_suffix}  停止 Trojan-Go
 ${Green_font_prefix}6.${Font_color_suffix}  重启 Trojan-Go
————————————————————————————————————————
 ${Green_font_prefix}7.${Font_color_suffix}  修改 Trojan-Go 配置
 ${Green_font_prefix}8.${Font_color_suffix}  查看 Trojan-Go 配置
 ${Green_font_prefix}9.${Font_color_suffix}  查看 Trojan-Go 状态
 ${Green_font_prefix}10.${Font_color_suffix} 查看 Trojan-Go 日志
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
		return
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
