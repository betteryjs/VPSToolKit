# VPSToolKit

VPSToolKit 是一个面向 VPS 服务器管理的开源脚本工具集，提供代理服务管理、系统优化和实用工具的一键式脚本解决方案。

采用模块化架构设计，灵感来自 [NodeScriptKit](https://github.com/NodeSeekDev/NodeScriptKit)，使用 TOML 配置文件管理菜单和脚本，支持灵活扩展和远程订阅。

## ✨ 特性

- 🚀 **代理服务管理**：支持 Shadowsocks、Trojan-Go、Snell、AnyTLS 等主流代理
- ⚡ **系统优化**：BBR 加速、系统重装等系统级优化工具
- 🛠️ **实用工具**：Speedtest 网络测速、磁盘测试等常用工具
- 📦 **模块化设计**：基于 TOML 配置，脚本按需下载，用完即删
- 🎨 **友好界面**：树形菜单结构，操作直观便捷
- 🔧 **灵活扩展**：支持本地扩展和远程订阅配置
- 🔄 **向后兼容**：保留旧版 `m` 命令，平滑升级

## 🚀 快速开始

### 一键安装

**方式一：OSS CDN（国内推荐）**

```bash
bash <(curl -sL https://oss.naloong.de/VPSToolKit/install.sh)
```

或使用 wget：

```bash
bash <(wget -qO- https://oss.naloong.de/VPSToolKit/install.sh)
```

**方式二：GitHub Raw（国外推荐）**

```bash
bash <(curl -sL https://raw.githubusercontent.com/betteryjs/VPSToolKit/master/install.sh)
```

或使用 wget：

```bash
bash <(wget -qO- https://raw.githubusercontent.com/betteryjs/VPSToolKit/master/install.sh)
```

> 💡 **提示**：安装时会提示选择下载源，可根据网络环境选择 GitHub Raw 或 OSS CDN。

### 使用方法

安装完成后，运行以下命令启动主菜单：

```bash
m
```

或者使用完整路径：

```bash
bash /usr/local/bin/m.sh
```

### 🎮 交互式菜单

VPSToolKit 2.0 提供了类似 NodeScriptKit 的交互式菜单体验：

- 🎯 使用 **↑/↓** 或 **j/k** 移动光标
- ⏎ 按 **回车键** 选择菜单项
- 🔙 按 **q** 返回上级菜单或退出
- 📱 友好的可视化界面

## 📋 功能列表

### 代理服务管理

- **Shadowsocks Rust** - 高性能 Shadowsocks 实现
- **Trojan-Go** - 支持 WebSocket 的 Trojan 代理
- **Snell v4/v5** - Surge 专用代理协议
- **AnyTLS** - 多协议代理工具

### 系统工具

- **BBR 加速** - TCP 拥塞控制算法，提升网络性能
- **DD 重装系统** - 一键重装 Debian/Ubuntu 等系统
- **Speedtest** - 网络速度测试工具

## 📁 项目结构

```
VPSToolKit/
├── README.md                # 项目说明文档
├── LICENSE                  # 许可证文件
├── DEVELOPMENT.md           # 开发指南
├── CONTRIBUTING.md          # 贡献指南
├── config.toml             # 主配置文件
├── vtk.sh                  # 新版主入口脚本（需要 vtkCore）
├── m.sh                    # 兼容旧版入口脚本
├── install.sh              # 一键安装脚本
├── modules.d/              # 模块配置目录
│   ├── default/           # 官方默认模块
│   │   ├── 000-menu.toml  # 主菜单配置
│   │   ├── 010-proxy.toml # 代理服务模块
│   │   ├── 020-system.toml# 系统工具模块
│   │   └── 030-tools.toml # 实用工具模块
│   └── extend/            # 用户自定义模块
└── scripts/               # 脚本目录
    ├── proxy/            # 代理服务脚本
    │   ├── anytls.sh
    │   ├── ss.sh
    │   ├── trojan.sh
    │   ├── snell4.sh
    │   └── snell5.sh
    ├── system/           # 系统工具脚本
    │   ├── bbr.sh
    │   └── dd.sh
    └── tools/            # 实用工具脚本
        └── speedtest.sh
```

## 🎯 配置系统

VPSToolKit 采用 TOML 配置文件系统，支持模块化管理和灵活扩展。

### 主配置文件

位置：`/etc/vpstoolkit/config.toml`

```toml
[app]
title = "VPSToolKit - VPS 服务统一管理脚本"
entry = 'main'

[local]
include = [
    '/etc/vpstoolkit/modules.d/default/*.toml',
    '/etc/vpstoolkit/modules.d/extend/*.toml',
]

[remote]
subscribes = []
```

### 模块配置文件

模块配置文件包含脚本定义和菜单结构：

```toml
[scripts]
proxy_ss = "bash /usr/local/vpstoolkit/scripts/proxy/ss.sh"

[[menus]]
id = "proxy_services"
title = "代理服务管理"
sub_menus = ["proxy_ss"]

[[menus]]
id = "proxy_ss"
title = "Shadowsocks 管理"
script = "proxy_ss"
```

### 扩展配置

你可以在 `/etc/vpstoolkit/modules.d/extend/` 目录下创建自定义配置：

```bash
# 创建自定义配置
vim /etc/vpstoolkit/modules.d/extend/100-custom.toml
```

```toml
[scripts]
custom_script = "bash /path/to/custom.sh"

[[menus]]
id = "main"
title = "VPSToolKit 主菜单"
sub_menus = [
    "custom_menu",
]

[[menus]]
id = "custom_menu"
title = "自定义功能"
script = "custom_script"
```

### 远程订阅

支持订阅远程配置文件，编辑主配置：

```bash
vim /etc/vpstoolkit/config.toml
```

```toml
[remote]
subscribes = [
    "https://example.com/custom-scripts.toml",
]
```

## 🔧 脚本说明

### 代理服务脚本

#### Shadowsocks Rust (ss.sh)
- 安装/卸载/更新 Shadowsocks Rust
- 支持多种加密方式
- 2022-blake3 系列加密
- TCP Fast Open 优化
- 自动证书配置

#### Trojan-Go (trojan.sh)
- WebSocket 模式（无需证书）
- TLS 模式（自动申请证书）
- 自动续期证书
- 回退 HTTP 服务

#### Snell v4/v5 (snell4.sh, snell5.sh)
- PSK 密钥认证
- IPv6 支持
- 自动生成 Surge 配置
- 服务状态监控

#### AnyTLS (anytls.sh)
- 多协议支持
- 灵活配置
- 性能优化

### 系统工具脚本

#### BBR 加速 (bbr.sh)
- BBR/BBRplus/Lotserver
- xanmod 内核
- 一键安装内核
- 系统参数优化

#### DD 重装 (dd.sh)
- 支持 Debian 12
- 自定义 SSH 端口
- 自定义 root 密码
- 多源选择（GitHub/清华源/阿里源）

### 实用工具脚本

#### Speedtest (speedtest.sh)
- 官方 Speedtest CLI
- 一键安装/卸载
- 网络速度测试

## 🎯 使用示例

### 安装 Shadowsocks

```bash
# 启动主菜单
m

# 选择 1 -> AnyTLS 管理
# 或选择 2 -> Shadowsocks 管理

# 按提示完成安装配置
```

### 开启 BBR 加速

```bash
# 启动主菜单
m

# 选择 6 -> BBR 加速管理

# 选择内核类型并安装
# 重启后生效
```

### 系统重装

```bash
# 启动主菜单
m

# 选择 7 -> DD 重装系统

# 选择安装源和配置
# 系统将自动重启并安装
```

## 🔐 安全建议

1. **密码安全**：使用强密码，定期更换
2. **端口修改**：修改默认 SSH 端口（22）
3. **防火墙配置**：合理配置防火墙规则
4. **定期更新**：保持系统和脚本最新版本
5. **备份数据**：重要数据及时备份

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

### 贡献方式

1. **报告问题**：在 Issues 中描述遇到的问题
2. **功能建议**：在 Discussions 中讨论新功能
3. **代码贡献**：Fork 本仓库，提交 PR

### 开发流程

详见 [DEVELOPMENT.md](./DEVELOPMENT.md) 和 [CONTRIBUTING.md](./CONTRIBUTING.md)

#### 快速开始

1. Fork 本仓库
2. 创建功能分支
   ```bash
   git checkout -b feature/AmazingFeature
   ```
3. 提交更改
   ```bash
   git commit -m '[Feat] Add some AmazingFeature'
   ```
4. 推送到分支
   ```bash
   git push origin feature/AmazingFeature
   ```
5. 创建 Pull Request

### 代码规范

- 脚本文件放在 `scripts/` 相应子目录
- 模块配置放在 `modules.d/default/`
- 遵循项目命名和编码规范
- 添加必要的注释和文档

## 📚 相关项目

- [NodeScriptKit](https://github.com/NodeSeekDev/NodeScriptKit) - 本项目的灵感来源
- 感谢 NodeScriptKit 提供的优秀架构设计

## 📝 更新日志

### v2.0.0 (2024)

- ✨ 采用模块化架构，使用 TOML 配置文件
- ✨ 支持本地扩展和远程订阅
- ✨ 重构目录结构，更清晰的组织方式
- ✨ 添加配置系统，灵活管理菜单和脚本
- ✨ 保持向后兼容，支持旧版 `m` 命令
- 📝 完善文档，添加开发指南

### v1.0.0

- 🎉 初始版本发布
- ✅ 基础功能实现
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

### 脚本编写规范

参考 [scripts/README.md](scripts/README.md) 了解脚本编写规范。

## 📮 联系方式

- **Issues**：[GitHub Issues](https://github.com/betteryjs/VPSToolKit/issues)
- **讨论**：[GitHub Discussions](https://github.com/betteryjs/VPSToolKit/discussions)

## 🙏 致谢

感谢以下项目的启发和支持：

- [NodeScriptKit](https://github.com/NodeSeekDev/NodeScriptKit)
- [Shadowsocks Rust](https://github.com/shadowsocks/shadowsocks-rust)
- [Trojan-Go](https://github.com/p4gefau1t/trojan-go)
- [BBR Script](https://github.com/ylx2016/Linux-NetSpeed)
- 以及所有贡献者

## ⚠️ 免责声明

本项目仅供学习交流使用，使用本工具所产生的任何后果由使用者自行承担。请遵守当地法律法规，合理使用代理工具。

---

**Star ⭐ 本项目以获取更新通知！**
# VPSToolKit
