# VPSToolKit 更新日志

所有重要的项目变更都会记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
项目遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 计划功能
- [ ] Hysteria 代理支持
- [ ] Xray 代理支持
- [ ] Docker 容器管理
- [ ] 系统监控面板
- [ ] 自动备份功能

## [1.0.0] - 2025-12-23

### 新增
- 🎉 项目初始化发布
- ✨ 主菜单系统（树形结构）
- 📦 一键安装脚本
- 🔧 模块化脚本管理
- 📝 完整项目文档

### 代理服务
- ✅ Shadowsocks Rust 管理脚本
- ✅ Trojan-Go 管理脚本（支持 WebSocket 和 TLS 模式）
- ✅ Snell v4 管理脚本
- ✅ Snell v5 管理脚本
- ✅ AnyTLS 管理脚本

### 系统工具
- ✅ BBR 加速脚本（支持多种内核）
- ✅ DD 重装系统脚本（Debian 12）
- ✅ 系统优化脚本

### 实用工具
- ✅ Speedtest 测速工具

### 功能特性
- 🔄 自动下载脚本
- 🧹 用完即删，保持整洁
- 🌲 树形菜单显示
- 🔙 二级菜单返回/退出
- 📡 远程脚本更新
- 🎨 彩色输出提示

### 文档
- 📖 完整的 README.md
- 🤝 贡献指南 (CONTRIBUTING.md)
- 📋 脚本开发文档 (scripts/README.md)
- 📜 MIT 许可证

---

## 版本说明

### [Unreleased]
- 正在开发中的功能

### [1.0.0]
- 项目首次正式发布
- 包含核心功能和完整文档

---

## 如何更新

### 自动更新（推荐）

```bash
# 运行主菜单
vpstk

# 选择 "9. 更新所有脚本"
```

### 手动更新

```bash
# 重新运行安装脚本
bash <(curl -sL https://oss.naloong.de/sh/install.sh)
```

---

## 贡献者

感谢所有为 VPSToolKit 做出贡献的开发者！

- [@yourname](https://github.com/yourname) - 项目创建者和主要维护者

---

## 支持

如果遇到问题或有建议，请：

1. 查看 [常见问题](https://github.com/yourusername/VPSToolKit/wiki/FAQ)
2. 搜索 [Issues](https://github.com/yourusername/VPSToolKit/issues)
3. 提交新的 [Issue](https://github.com/yourusername/VPSToolKit/issues/new)
4. 参与 [Discussions](https://github.com/yourusername/VPSToolKit/discussions)
