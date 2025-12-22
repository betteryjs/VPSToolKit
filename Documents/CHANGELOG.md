# VPSToolKit 更新日志

所有重要的项目变更都会记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
项目遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 计划功能
- [ ] vtkCore 核心引擎开发（Go 语言）
- [ ] Hysteria 代理支持
- [ ] Xray 代理支持
- [ ] Docker 容器管理
- [ ] 系统监控面板
- [ ] 自动备份功能
- [ ] Web 管理界面

## [2.0.0] - 2024-12-23

### 重大更新

VPSToolKit 2.0 采用全新的模块化架构，灵感来自 [NodeScriptKit](https://github.com/NodeSeekDev/NodeScriptKit)。

### 新增

- ✨ **模块化架构**：使用 TOML 配置文件管理菜单和脚本
- ✨ **配置文件系统**：
  - `config.toml` - 主配置文件
  - `modules.d/default/` - 官方默认模块（更新时覆盖）
  - `modules.d/extend/` - 用户自定义模块（更新时保留）
- ✨ **灵活扩展**：支持本地扩展和远程订阅
- ✨ **新入口脚本**：`vtk.sh`（需要 vtkCore）
- ✨ **完善文档**：
  - `DEVELOPMENT.md` - 开发指南
  - 更新 `CONTRIBUTING.md` - 贡献指南
  - 更新 `README.md` - 项目说明

### 改进

- 🔧 **目录结构重构**：
  - `scripts/proxy/` - 代理服务脚本
  - `scripts/system/` - 系统工具脚本
  - `scripts/tools/` - 实用工具脚本
- 🔧 **脚本优化**：
  - 更新 `m.sh` 支持新目录结构
  - 更新 `install.sh` 支持配置文件安装
  - 改进下载逻辑，支持多源下载
- 🔧 **用户体验**：
  - 优化菜单显示
  - 改进错误提示
  - 支持环境变量配置

### 兼容性

- ✅ **向后兼容**：保持旧版 `m` 命令可用
- ✅ **平滑升级**：自动处理目录结构变更
- ✅ **脚本保持不变**：`scripts/` 目录下所有脚本功能保持一致

### 文档

- 📝 完整的项目架构说明
- 📝 详细的开发指南和示例
- 📝 配置文件使用说明
- 📝 扩展和订阅教程

## [1.0.0] - 2024-12-23

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
