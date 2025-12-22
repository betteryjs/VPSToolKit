# Scripts 目录说明

本目录包含 VPSToolKit 的所有功能脚本，按功能分类存放。

## 📁 目录结构

```
scripts/
├── proxy/          # 代理服务脚本
├── system/         # 系统工具脚本
└── tools/          # 实用工具脚本
```

## 📝 脚本规范

### 脚本头部模板

每个脚本应包含以下标准头部信息：

```bash
#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: [脚本功能描述]
#	Version: 1.0.0
#	Author: [作者名称]
#	项目地址: https://github.com/yourusername/VPSToolKit
#=================================================

# 当前脚本版本号
sh_ver="1.0.0"

# 颜色定义
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Yellow_font_prefix="\033[0;33m"
Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Yellow_font_prefix}[注意]${Font_color_suffix}"
```

### 必要函数

所有脚本应包含以下基本函数：

#### 1. 权限检查
```bash
check_root(){
	if [[ $EUID != 0 ]]; then
		echo -e "${Error} 当前账号非ROOT权限，无法继续操作！"
		exit 1
	fi
}
```

#### 2. 系统检测
```bash
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	fi
}
```

#### 3. 架构检测
```bash
sys_arch() {
	uname=$(uname -m)
	if [[ "$uname" == "x86_64" ]]; then
		arch="amd64"
	elif [[ "$uname" == "aarch64" ]]; then
		arch="arm64"
	fi
}
```

### 功能模块

#### 安装函数
- 检查是否已安装
- 依赖安装
- 下载主程序
- 配置文件写入
- 服务创建
- 启动服务

#### 卸载函数
- 停止服务
- 删除服务文件
- 删除程序文件
- 删除配置文件
- 清理依赖（可选）

#### 更新函数
- 检查最新版本
- 下载新版本
- 备份配置
- 替换程序
- 重启服务

#### 配置函数
- 读取当前配置
- 修改配置选项
- 写入配置文件
- 重启服务生效

## 🔧 开发指南

### 1. 新增脚本

1. 根据功能确定所属分类
2. 复制模板创建新脚本
3. 实现必要功能函数
4. 添加主菜单入口
5. 测试脚本功能

### 2. 代码风格

- 使用 4 空格缩进
- 函数名使用小写下划线
- 变量名清晰有意义
- 添加必要注释

### 3. 错误处理

```bash
# 使用 || 处理错误
command || { echo -e "${Error} 命令执行失败！"; exit 1; }

# 检查文件是否存在
[[ ! -e /path/to/file ]] && echo -e "${Error} 文件不存在！" && exit 1

# 检查服务状态
systemctl is-active service >/dev/null 2>&1 || echo -e "${Error} 服务未运行！"
```

### 4. 用户交互

```bash
# 读取用户输入
read -e -p "请输入端口 [1-65535]：" port
[[ -z "${port}" ]] && port=8080

# 确认操作
read -e -p "确认执行？(y/n)：" confirm
[[ ${confirm} == [Yy] ]] || { echo "已取消"; exit 0; }
```

## 📋 脚本清单

### proxy/ - 代理服务脚本

| 脚本名    | 功能             | 状态 |
| --------- | ---------------- | ---- |
| anytls.sh | AnyTLS 管理      | ✅    |
| ss.sh     | Shadowsocks 管理 | ✅    |
| trojan.sh | Trojan-Go 管理   | ✅    |
| snell4.sh | Snell v4 管理    | ✅    |
| snell5.sh | Snell v5 管理    | ✅    |

### system/ - 系统工具脚本

| 脚本名 | 功能        | 状态 |
| ------ | ----------- | ---- |
| bbr.sh | BBR 加速    | ✅    |
| dd.sh  | DD 重装系统 | ✅    |

### tools/ - 实用工具脚本

| 脚本名       | 功能           | 状态 |
| ------------ | -------------- | ---- |
| speedtest.sh | Speedtest 测速 | ✅    |

## 🧪 测试

### 本地测试

```bash
# 直接运行脚本
bash scripts/proxy/ss.sh

# 或赋予执行权限后运行
chmod +x scripts/proxy/ss.sh
./scripts/proxy/ss.sh
```

### 集成测试

```bash
# 运行主菜单测试所有脚本
bash vpstk.sh
```

## 📚 参考资源

- [Bash 脚本编程指南](https://tldp.org/LDP/abs/html/)
- [Systemd 服务文件](https://www.freedesktop.org/software/systemd/man/systemd.service.html)
- [NodeScriptKit](https://github.com/NodeSeekDev/NodeScriptKit)

## 🤝 贡献

欢迎提交新的脚本或改进现有脚本！请遵循以上规范，确保代码质量。
