# VPSToolKit 2.0 升级说明

## 概述

VPSToolKit 2.0 是一次重大架构升级，采用了类似 [NodeScriptKit](https://github.com/NodeSeekDev/NodeScriptKit) 的模块化设计，使用 TOML 配置文件管理菜单和脚本，提供更灵活、可扩展的架构。

## 主要变化

### 1. 新增配置文件系统

- **主配置文件**：`config.toml`
  - 定义应用基本信息
  - 配置模块加载规则
  - 支持远程订阅

- **模块配置目录**：`modules.d/`
  - `default/` - 官方默认模块（更新时覆盖）
  - `extend/` - 用户自定义模块（更新时保留）

### 2. 目录结构重组

```
VPSToolKit/
├── config.toml              # 主配置文件（新增）
├── vtk.sh                   # 新版主入口（新增）
├── m.sh                     # 兼容旧版入口（更新）
├── install.sh               # 安装脚本（更新）
├── modules.d/               # 模块配置目录（新增）
│   ├── default/            # 官方模块
│   │   ├── 000-menu.toml
│   │   ├── 010-proxy.toml
│   │   ├── 020-system.toml
│   │   └── 030-tools.toml
│   └── extend/             # 用户模块
│       ├── README.md
│       └── example-custom.toml.example
└── scripts/                 # 脚本目录（保持不变）
    ├── proxy/              # 代理服务
    ├── system/             # 系统工具
    └── tools/              # 实用工具
```

### 3. 新增文档

- `DEVELOPMENT.md` - 详细的开发指南
- `Rules.md` - 开发规则和最佳实践
- `CONTRIBUTING.md` - 更新贡献指南
- `CHANGELOG.md` - 更新更新日志

## 核心特性

### 模块化配置

使用 TOML 配置文件定义菜单和脚本：

```toml
[scripts]
proxy_ss = "bash /usr/local/vpstoolkit/scripts/proxy/ss.sh"

[[menus]]
id = "proxy_services"
title = "代理服务管理"
sub_menus = ["proxy_ss"]
```

### 灵活扩展

1. **本地扩展**：
   ```bash
   vim /etc/vpstoolkit/modules.d/extend/100-custom.toml
   ```

2. **远程订阅**：
   ```toml
   [remote]
   subscribes = [
       "https://example.com/custom.toml",
   ]
   ```

### 优先级控制

- 文件名以数字开头（000-999）
- 数字越大，优先级越高
- 可以覆盖默认配置

## 向后兼容

### 保持兼容性

- ✅ 旧版 `m` 命令继续可用
- ✅ `scripts/` 目录下所有脚本保持不变
- ✅ 脚本功能完全一致
- ✅ 安装过程平滑升级

### 脚本路径变更

**旧版路径**（内部使用）：
```bash
./anytls.sh
./ss.sh
```

**新版路径**（推荐）：
```bash
/usr/local/vpstoolkit/scripts/proxy/anytls.sh
/usr/local/vpstoolkit/scripts/proxy/ss.sh
```

**注意**：旧版 `m.sh` 已更新以支持新路径，用户无需修改任何脚本。

## 升级指南

### 全新安装

```bash
# GitHub Raw
bash <(curl -sL https://raw.githubusercontent.com/betteryjs/VPSToolKit/master/install.sh)

# OSS CDN
bash <(curl -sL https://oss.naloong.de/VPSToolKit/install.sh)
```

### 从 1.0 升级

1. **备份自定义脚本**：
   ```bash
   cp -r /path/to/custom/scripts /tmp/backup/
   ```

2. **运行安装脚本**：
   ```bash
   bash <(curl -sL https://raw.githubusercontent.com/betteryjs/VPSToolKit/master/install.sh)
   ```

3. **恢复自定义配置**：
   ```bash
   # 创建自定义模块配置
   vim /etc/vpstoolkit/modules.d/extend/100-custom.toml
   ```

## 使用示例

### 基本使用

```bash
# 启动主菜单
m
```

### 扩展配置

```bash
# 创建自定义配置
cat > /etc/vpstoolkit/modules.d/extend/100-custom.toml << 'EOF'
[scripts]
custom_script = "bash /root/custom.sh"

[[menus]]
id = "main"
title = "VPSToolKit 主菜单"
sub_menus = ["custom_menu"]

[[menus]]
id = "custom_menu"
title = "自定义功能"
script = "custom_script"
EOF

# 重新运行查看效果
m
```

### 远程订阅

```bash
# 编辑主配置
vim /etc/vpstoolkit/config.toml

# 添加订阅地址
[remote]
subscribes = [
    "https://example.com/vpstoolkit-custom.toml",
]
```

## 开发指南

### 添加新脚本

1. **创建脚本文件**：
   ```bash
   vim scripts/proxy/new_proxy.sh
   ```

2. **注册到配置**：
   ```bash
   vim modules.d/default/010-proxy.toml
   ```
   
   ```toml
   [scripts]
   proxy_new = "bash /usr/local/vpstoolkit/scripts/proxy/new_proxy.sh"
   
   [[menus]]
   id = "proxy_services"
   sub_menus = ["proxy_new"]
   
   [[menus]]
   id = "proxy_new"
   title = "新代理服务"
   script = "proxy_new"
   ```

### 创建新模块

```bash
vim modules.d/default/040-new-module.toml
```

```toml
[scripts]
module_script = "bash /path/to/script.sh"

[[menus]]
id = "new_module"
title = "新模块"
sub_menus = ["module_script"]
```

## 未来计划

- [ ] 开发 vtkCore（Go 语言）用于配置解析
- [ ] 添加更多代理协议支持
- [ ] Web 管理界面
- [ ] Docker 支持
- [ ] 系统监控面板

## 获取帮助

- **GitHub Issues**：https://github.com/betteryjs/VPSToolKit/issues
- **GitHub Discussions**：https://github.com/betteryjs/VPSToolKit/discussions
- **开发文档**：[DEVELOPMENT.md](./DEVELOPMENT.md)
- **贡献指南**：[CONTRIBUTING.md](./CONTRIBUTING.md)

## 致谢

特别感谢 [NodeScriptKit](https://github.com/NodeSeekDev/NodeScriptKit) 项目提供的优秀架构设计灵感。

---

VPSToolKit 2.0 - 更灵活、更强大、更易扩展！
