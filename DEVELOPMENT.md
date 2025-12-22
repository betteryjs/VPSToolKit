# VPSToolKit 开发指南

欢迎参与 VPSToolKit 项目开发！本指南将帮助你快速上手开发流程，贡献代码并参与项目建设。

## 一、项目架构

VPSToolKit 采用模块化架构设计，受 NodeScriptKit 启发，使用 TOML 配置文件管理菜单和脚本。

### 目录结构

```
VPSToolKit/
├── config.toml              # 主配置文件
├── vtk.sh                   # 新版主入口脚本（需要 vtkCore）
├── m.sh                     # 兼容旧版入口脚本
├── install.sh               # 一键安装脚本
├── modules.d/               # 模块配置目录
│   ├── default/            # 官方默认模块
│   │   ├── 000-menu.toml
│   │   ├── 010-proxy.toml
│   │   ├── 020-system.toml
│   │   └── 030-tools.toml
│   └── extend/             # 用户自定义模块
└── scripts/                 # 脚本文件目录
    ├── proxy/              # 代理服务脚本
    ├── system/             # 系统工具脚本
    └── tools/              # 实用工具脚本
```

### 配置文件说明

#### 主配置文件 (config.toml)

主配置文件定义了应用的基本信息、启动画面和模块加载规则：

```toml
[app]
title = "VPSToolKit - VPS 服务统一管理脚本"
entry = 'main'  # 入口菜单 ID

[local]
include = [
    '/etc/vpstoolkit/modules.d/default/*.toml',
    '/etc/vpstoolkit/modules.d/extend/*.toml',
]

[remote]
subscribes = []  # 远程订阅配置
```

#### 模块配置文件

模块配置文件包含脚本定义和菜单结构：

```toml
[scripts]
# 脚本 ID = 脚本命令
proxy_ss = "bash /usr/local/vpstoolkit/scripts/proxy/ss.sh"

[[menus]]
id = "proxy_services"      # 菜单 ID
title = "代理服务管理"      # 显示标题
sub_menus = ["proxy_ss"]   # 子菜单列表

[[menus]]
id = "proxy_ss"
title = "Shadowsocks 管理"
script = "proxy_ss"        # 指向脚本 ID
```

## 二、开发环境搭建

### 前置条件

- **操作系统**：Linux（推荐 Debian、Ubuntu、CentOS 或 Alpine）
- **权限**：需要 root 权限运行脚本
- **工具**：
  - `bash`：核心脚本语言
  - `curl` 和 `wget`：用于下载外部资源
  - `git`：用于版本控制

### 获取代码

```bash
git clone https://github.com/betteryjs/VPSToolKit.git
cd VPSToolKit
```

### 安装依赖

```bash
# Debian/Ubuntu
apt update && apt install -y curl wget git

# CentOS
yum install -y curl wget git

# Alpine
apk add curl wget git
```

## 三、开发规范

### 脚本开发规范

1. **文件位置**：
   - 代理服务脚本：`scripts/proxy/`
   - 系统工具脚本：`scripts/system/`
   - 实用工具脚本：`scripts/tools/`

2. **命名规则**：
   - 文件名：小写字母，使用下划线分隔，如 `ss.sh`
   - 函数名：小写加下划线，如 `get_system_info`
   - 变量名：清晰描述用途，如 `ipv4_address`

3. **脚本模板**：

```bash
#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	Description: Shadowsocks 管理脚本
#	Version: 1.0.0
#	Author: VPSToolKit Contributors
#=================================================

# 颜色定义
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Yellow_font_prefix="\033[0;33m"
Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Success="${Green_font_prefix}[成功]${Font_color_suffix}"

# 检查 root 权限
check_root(){
    if [[ $EUID != 0 ]]; then
        echo -e "${Error} 需要 root 权限"
        exit 1
    fi
}

# 主函数
main(){
    check_root
    # 你的代码
}

main
```

### 模块配置规范

1. **文件命名**：
   - 格式：`XXX-module_name.toml`
   - 数字越大，优先级越高
   - 官方模块：`default/` 目录
   - 用户模块：`extend/` 目录

2. **配置结构**：

```toml
# 1. 定义脚本
[scripts]
script_id = "bash /path/to/script.sh"

# 2. 定义菜单层次
[[menus]]
id = "parent_menu"
title = "父菜单"
sub_menus = ["child_menu"]

[[menus]]
id = "child_menu"
title = "子菜单"
script = "script_id"
```

### 代码风格

1. **缩进**：使用 4 个空格
2. **注释**：关键功能需添加注释
3. **错误处理**：使用 Info/Error/Success 提示用户

```bash
# 获取系统运行时间
runtime=$(cat /proc/uptime | awk '{print $1}')

# 检查命令是否成功
if [[ $? -eq 0 ]]; then
    echo -e "${Success} 执行成功！"
else
    echo -e "${Error} 执行失败！"
    exit 1
fi
```

## 四、开发流程

### 1. Fork 与分支

1. Fork 本仓库到你的 GitHub 账号
2. 克隆你的 Fork：

```bash
git clone https://github.com/你的用户名/VPSToolKit.git
cd VPSToolKit
```

3. 创建功能分支：

```bash
git checkout -b feature/add-new-script
```

### 2. 添加新功能

#### 添加新脚本

1. 在相应目录创建脚本文件：

```bash
vim scripts/proxy/new_proxy.sh
```

2. 在模块配置中注册脚本：

```toml
# modules.d/default/010-proxy.toml

[scripts]
# ... 其他脚本
proxy_new = "bash /usr/local/vpstoolkit/scripts/proxy/new_proxy.sh"

[[menus]]
id = "proxy_services"
title = "代理服务管理"
sub_menus = [
    # ... 其他菜单
    "proxy_new",
]

[[menus]]
id = "proxy_new"
title = "新代理服务"
script = "proxy_new"
```

#### 添加新模块

1. 创建新的模块配置文件：

```bash
vim modules.d/default/040-new-module.toml
```

2. 在主菜单中添加入口：

```toml
# modules.d/default/000-menu.toml

[[menus]]
id = "main"
title = "VPSToolKit 主菜单"
sub_menus = [
    # ... 其他菜单
    "new_module",
]
```

### 3. 测试

```bash
# 在测试环境安装
bash install.sh

# 运行测试
m

# 测试新功能
```

### 4. 提交代码

```bash
git add .
git commit -m "[Feat] 添加新代理服务支持"
git push origin feature/add-new-script
```

### 5. 创建 Pull Request

1. 在 GitHub 上打开你的 Fork
2. 点击 "Pull Request"
3. 填写 PR 描述
4. 等待审核

## 五、提交规范

### Commit Message 格式

```
[类别] 简短描述

详细描述（可选）
```

### 类别标签

- `[Feat]` - 新功能
- `[Fix]` - Bug 修复
- `[Docs]` - 文档更新
- `[Style]` - 代码格式
- `[Refactor]` - 重构
- `[Test]` - 测试相关
- `[Chore]` - 构建/工具相关

### 示例

```bash
git commit -m "[Feat] 添加 V2Ray 支持"
git commit -m "[Fix] 修复 BBR 安装失败问题"
git commit -m "[Docs] 更新安装文档"
```

## 六、测试指南

### 单元测试

```bash
# 测试脚本语法
bash -n scripts/proxy/ss.sh

# 测试配置文件
# 需要安装 TOML 解析工具
```

### 集成测试

```bash
# 在虚拟机或 VPS 上完整测试
bash install.sh
m
# 逐个测试功能
```

### 兼容性测试

在不同系统上测试：
- Debian 11/12
- Ubuntu 20.04/22.04/24.04
- CentOS 7/8/9
- Alpine Linux

## 七、扩展开发

### 添加远程订阅支持

用户可以通过修改 `config.toml` 添加远程订阅：

```toml
[remote]
subscribes = [
    "https://example.com/custom-scripts.toml",
]
```

### 开发自定义模块

在 `modules.d/extend/` 目录创建自定义模块：

```bash
vim /etc/vpstoolkit/modules.d/extend/100-custom.toml
```

```toml
[scripts]
custom_script = "bash /path/to/custom.sh"

[[menus]]
id = "main"
title = "VPSToolKit 主菜单"
sub_menus = [
    "custom_menu",  # 扩展主菜单
]

[[menus]]
id = "custom_menu"
title = "自定义功能"
script = "custom_script"
```

## 八、常见问题

### Q: 如何调试脚本？

A: 使用 `bash -x` 模式：

```bash
bash -x scripts/proxy/ss.sh
```

### Q: 配置文件不生效？

A: 检查：
1. 文件命名是否正确
2. TOML 语法是否正确
3. 文件优先级（数字越大越优先）

### Q: 如何测试配置合并？

A: 创建测试配置文件，使用更大的数字前缀覆盖默认配置。

## 九、项目路线图

- [ ] 完善 vtkCore（Go 语言实现的配置解析器）
- [ ] 添加更多代理协议支持
- [ ] 支持 Docker 部署
- [ ] Web 管理界面
- [ ] 多语言支持

## 十、获取帮助

- **GitHub Issues**：https://github.com/betteryjs/VPSToolKit/issues
- **GitHub Discussions**：https://github.com/betteryjs/VPSToolKit/discussions
- **参考项目**：[NodeScriptKit](https://github.com/NodeSeekDev/NodeScriptKit)

---

感谢你对 VPSToolKit 的贡献！
