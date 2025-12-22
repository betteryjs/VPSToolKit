# VPSToolKit

VPSToolKit 是一个面向 VPS 服务器管理的开源脚本工具集，提供代理服务管理、系统优化和实用工具的一键式脚本解决方案。

采用模块化架构设计，灵感来自 [NodeScriptKit](https://github.com/NodeSeekDev/NodeScriptKit)，使用 TOML 配置文件管理菜单和脚本，所有脚本在线执行，无需本地存储。

## ✨ 特性

- 🚀 **代理服务管理**：支持 Shadowsocks、Trojan-Go、Snell、AnyTLS 等主流代理
- ⚡ **系统优化**：BBR 加速、系统重装等系统级优化工具
- 🛠️ **实用工具**：Speedtest 网络测速等常用工具
- 📦 **模块化设计**：基于 TOML 配置，清晰的菜单结构
- 🌐 **在线执行**：所有脚本在线下载执行，无需本地存储
- 🎨 **友好界面**：交互式菜单，支持方向键和 vim 键位导航
- 🔧 **灵活扩展**：支持自定义模块配置
- 🔄 **双下载源**：支持 OSS CDN 和 GitHub Raw 下载源

## 🚀 快速开始

### 一键安装

```bash
bash <(curl -sL https://oss.naloong.de/VPSToolKit/install.sh)
```

```bash
bash <(curl -sL https://raw.githubusercontent.com/betteryjs/VPSToolKit/refs/heads/master/install.sh)
```

安装时会提示选择下载源：
- **OSS CDN**（国内推荐）：`https://oss.naloong.de/VPSToolKit`
- **GitHub Raw**（国外推荐）：`https://raw.githubusercontent.com`

### 使用方法

安装完成后，运行以下命令启动主菜单：

```bash
m
```

### 卸载

```bash
bash <(curl -sL https://oss.naloong.de/VPSToolKit/uninstall.sh)
```

```bash
bash <(curl -sL https://raw.githubusercontent.com/betteryjs/VPSToolKit/refs/heads/master/uninstall.sh)
```

> ⚠️ **注意**：卸载操作会删除 VPSToolKit 的所有文件和配置，但不会卸载已安装的代理服务（如 Shadowsocks、Trojan 等）。

### 🎮 交互式菜单

VPSToolKit 2.0 提供了类似 NodeScriptKit 的交互式菜单体验：

- 🎯 使用 **↑/↓** 或 **j/k** 移动光标
- ⏎ 按 **回车键** 选择菜单项
- 🔙 按 **q** 退出程序
- 📱 友好的可视化界面

## 📋 功能列表

### 代理服务管理

- **AnyTLS** - 多协议代理工具
- **Shadowsocks** - 高性能 Shadowsocks 实现
- **Trojan-Go** - 支持 WebSocket 的 Trojan 代理
- **Snell v4/v5** - Surge 专用代理协议

### 系统工具

- **BBR 加速** - TCP 拥塞控制算法，提升网络性能
- **DD 重装系统** - 一键重装 Debian/Ubuntu 等系统

### 实用工具

- **Speedtest** - 网络速度测试工具

## 📁 项目结构

```
VPSToolKit/
├── README.md                # 项目说明文档
├── LICENSE                  # 许可证文件
├── install.sh              # 一键安装脚本
├── uninstall.sh            # 卸载脚本
├── m.sh                    # 主入口脚本
├── menu.sh                 # 交互式菜单核心脚本
├── version                 # 版本号文件
├── Documents/              # 文档目录
│   ├── CHANGELOG.md       # 更新日志
│   ├── CONTRIBUTING.md    # 贡献指南
│   ├── DEVELOPMENT.md     # 开发指南
│   ├── INTERACTIVE.md     # 交互式菜单说明
│   └── MOUDULES.D.README.md # 模块配置说明
├── modules.d/              # 模块配置目录
│   ├── menu.toml          # 主菜单配置
│   ├── proxy.toml         # 代理服务模块
│   ├── system.toml        # 系统工具模块
│   └── tools.toml         # 实用工具模块
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

### 配置文件位置

所有配置文件位于：`/etc/vpstoolkit/modules.d/`

### 主菜单配置

文件：`/etc/vpstoolkit/modules.d/menu.toml`

```toml
[[menus]]
id = "main"
title = "VPSToolKit 主菜单"
sub_menus = [
    "proxy",
    "system",
    "tools",
]
titles = [
    "代理服务管理",
    "系统工具",
    "实用工具"
]
```

### 模块配置示例

文件：`/etc/vpstoolkit/modules.d/proxy.toml`

```toml
[scripts]
# 代理服务管理脚本
proxy_anytls = "scripts/proxy/anytls.sh"
proxy_ss = "scripts/proxy/ss.sh"
proxy_trojan = "scripts/proxy/trojan.sh"
proxy_snell4 = "scripts/proxy/snell4.sh"
proxy_snell5 = "scripts/proxy/snell5.sh"

[[menus]]
id = "proxy"
title = "代理服务管理"
sub_menus = [
    "proxy_anytls",
    "proxy_ss",
    "proxy_trojan",
    "proxy_snell4",
    "proxy_snell5",
]

[[menu]]
id = "proxy_anytls"
title = "AnyTLS 管理"
script = "proxy_anytls"

[[menu]]
id = "proxy_ss"
title = "Shadowsocks 管理"
script = "proxy_ss"

# ... 其他菜单项
```

### 配置说明

1. **[scripts]** 部分定义脚本路径（相对路径）
2. **[[menus]]** 定义菜单分类（一级菜单）
3. **[[menu]]** 定义具体菜单项（二级菜单）
4. 脚本路径会根据安装时选择的下载源自动转换为完整 URL

### 脚本执行方式

所有脚本采用在线执行方式：

```bash
bash <(curl -sL "https://oss.naloong.de/VPSToolKit/scripts/proxy/anytls.sh")
```

优点：
- ✅ 无需本地存储脚本
- ✅ 始终使用最新版本
- ✅ 减少磁盘占用
- ✅ 方便更新维护

## 🔧 自定义扩展

你可以在 `/etc/vpstoolkit/modules.d/` 目录下创建自定义配置：

```bash
# 创建自定义配置
vim /etc/vpstoolkit/modules.d/custom.toml
```

```toml
[scripts]
my_script = "scripts/custom/my_script.sh"

[[menus]]
id = "custom"
title = "自定义功能"
sub_menus = ["my_item"]

[[menu]]
id = "my_item"
title = "我的脚本"
script = "my_script"
```

然后在 `menu.toml` 中添加自定义模块：

```toml
[[menus]]
id = "main"
title = "VPSToolKit 主菜单"
sub_menus = [
    "proxy",
    "system",
    "tools",
    "custom",  # 添加自定义模块
]
titles = [
    "代理服务管理",
    "系统工具",
    "实用工具",
    "自定义功能"  # 添加标题
]
```
## 💡 工作原理

### 菜单加载流程

1. **启动入口**：运行 `m` 命令
2. **检查更新**：比对本地和远程版本号
3. **加载主菜单**：解析 `modules.d/menu.toml`
   - 读取 `sub_menus` 数组获取模块 ID
   - 读取 `titles` 数组获取模块标题
   - 显示面包屑导航：`主菜单 > 代理服务管理`
4. **加载子菜单**：用户选择模块后
   - 查找对应的 `.toml` 文件（如 `proxy.toml`）
   - 解析 `[[menu]]` 节点获取菜单项
   - 从 `[scripts]` 部分获取脚本路径
   - 实时显示执行预览信息
5. **执行脚本**：用户选择具体功能后
   - 根据下载源生成完整 URL
   - 使用 `bash <(curl -sL URL)` 在线执行

### 脚本执行方式

```bash
# OSS CDN
bash <(curl -sL "https://oss.naloong.de/VPSToolKit/scripts/proxy/anytls.sh")

# GitHub Raw
bash <(curl -sL "https://raw.githubusercontent.com/betteryjs/VPSToolKit/master/scripts/proxy/anytls.sh")
```

## 🎯 使用示例

### 安装 Shadowsocks

```bash
# 启动主菜单
m

# 1. 选择「代理服务管理」
# 2. 选择「Shadowsocks 管理」
# 3. 按提示完成安装配置
```

### 开启 BBR 加速

```bash
# 启动主菜单
m

# 1. 选择「系统工具」
# 2. 选择「BBR 加速管理」
# 3. 选择内核类型并安装
# 4. 重启后生效
```

### 测试网络速度

```bash
# 启动主菜单
m

# 1. 选择「实用工具」
# 2. 选择「Speedtest 测速」
# 3. 自动安装并执行测速
```

## 🔐 安全建议

1. **密码安全**：使用强密码，定期更换
2. **端口修改**：修改默认 SSH 端口（22）
3. **防火墙配置**：合理配置防火墙规则
4. **定期更新**：保持系统和脚本最新版本
5. **备份数据**：重要数据及时备份
6. **脚本安全**：仅执行来自可信源的脚本

## ❓ 常见问题

### 如何切换下载源？

重新运行安装脚本，选择不同的下载源：

```bash
bash <(curl -sL https://oss.naloong.de/VPSToolKit/install.sh)
```

### 如何更新到最新版本？

运行 `m` 命令时会自动检测更新，按提示操作即可。

或手动重新安装：

```bash
bash <(curl -sL https://oss.naloong.de/VPSToolKit/install.sh)
```

### 如何添加自定义脚本？

1. 创建自定义 TOML 配置文件
2. 在 `menu.toml` 中添加模块引用
3. 脚本可以是本地路径或远程 URL

详见「自定义扩展」章节。

### 卸载后如何清理服务？

卸载 VPSToolKit 不会删除已安装的服务，需要手动清理：

```bash
# 例如卸载 Shadowsocks
systemctl stop shadowsocks-rust
systemctl disable shadowsocks-rust
rm -rf /etc/shadowsocks-rust
```

### 支持哪些系统？

- Debian 9+
- Ubuntu 18.04+
- CentOS 7+
- 其他基于 Debian/Ubuntu/CentOS 的发行版

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

### 贡献方式

1. **报告问题**：在 Issues 中描述遇到的问题
2. **功能建议**：在 Discussions 中讨论新功能
3. **代码贡献**：Fork 本仓库，提交 PR
4. **文档改进**：完善文档和示例

### 开发流程

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
- 模块配置放在 `modules.d/`
- 使用清晰的变量和函数命名
- 添加必要的注释和文档
- 遵循 ShellCheck 规范

## 📚 相关项目

- [NodeScriptKit](https://github.com/NodeSeekDev/NodeScriptKit) - 本项目的灵感来源
- 感谢 NodeScriptKit 提供的优秀架构设计理念

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 📝 更新日志

### v2.0.0 (2024-12-23)

- ✨ 全新架构：采用模块化 TOML 配置系统
- ✨ 在线执行：所有脚本在线下载执行，无需本地存储
- ✨ 交互菜单：支持方向键和 vim 键位的友好界面
- ✨ 双下载源：支持 OSS CDN 和 GitHub Raw
- ✨ 版本检测：自动检测并提示更新
- ✨ 简化安装：统一入口命令 `vtk` 和 `m`
- 🔧 重构代码：更清晰的目录结构和代码组织
- 📝 完善文档：详细的配置说明和使用示例

### v1.0.0

- 🎉 初始版本发布
- ✅ 基础功能实现

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

**⭐ Star 本项目以获取更新通知！**

