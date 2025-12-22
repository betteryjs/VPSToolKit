# VPSToolKit

VPSToolKit 是一个面向 VPS 服务器管理的开源脚本工具集，提供代理服务管理、系统优化和实用工具的一键式脚本解决方案。

## ✨ 特性

- 🚀 **代理服务管理**：支持 Shadowsocks、Trojan-Go、Snell、AnyTLS 等主流代理
- ⚡ **系统优化**：BBR 加速、系统重装等系统级优化工具
- 🛠️ **实用工具**：Speedtest 网络测速、磁盘测试等常用工具
- 📦 **模块化设计**：脚本自动下载，用完即删，保持系统整洁
- 🎨 **友好界面**：树形菜单结构，操作直观便捷

## 🚀 快速开始

### 一键安装

**方式一：OSS CDN（国内推荐）**

```bash
bash <(curl -sL https://oss.naloong.de/sh/install.sh)
```

或使用 wget：

```bash
bash <(wget -qO- https://oss.naloong.de/sh/install.sh)
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
bash /usr/local/bin/m
```

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
├── README.md              # 项目说明文档
├── LICENSE                # 许可证文件
├── install.sh             # 一键安装脚本
├── m.sh                  # 主菜单脚本
└── scripts/              # 脚本目录
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

## 📝 许可证

本项目采用 MIT 许可证，详见 [LICENSE](LICENSE) 文件。

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

### 贡献步骤

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

### 脚本编写规范

参考 [scripts/README.md](scripts/README.md) 了解脚本编写规范。

## 📮 联系方式

- **Issues**：[GitHub Issues](https://github.com/yourusername/VPSToolKit/issues)
- **讨论**：[GitHub Discussions](https://github.com/yourusername/VPSToolKit/discussions)

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
