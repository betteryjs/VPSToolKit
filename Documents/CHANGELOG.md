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

## [2.0.0] - 2024-12-23

### 重大更新

VPSToolKit 2.0 采用全新的模块化架构，灵感来自 [NodeScriptKit](https://github.com/NodeSeekDev/NodeScriptKit)。

### 新增

- ✨ **模块化架构**：使用 TOML 配置文件管理菜单和脚本
- ✨ **配置文件系统**：
  - `modules.d/menu.toml` - 主菜单配置
  - `modules.d/proxy.toml` - 代理服务模块
  - `modules.d/system.toml` - 系统工具模块
  - `modules.d/tools.toml` - 实用工具模块
- ✨ **在线执行**：所有脚本通过 `bash <(curl -sL URL)` 在线执行
- ✨ **交互式菜单**：
  - 面包屑导航：`主菜单 > 代理服务管理`
  - 实时预览：显示脚本地址和执行命令
  - 优化性能：缓存机制消除闪烁
- ✨ **双下载源**：支持 OSS CDN 和 GitHub Raw
- ✨ **版本检测**：自动检测并提示更新
- ✨ **统一入口**：`m` 命令作为唯一入口
- ✨ **完善文档**：
  - `Documents/DEVELOPMENT.md` - 开发指南
  - `Documents/CONTRIBUTING.md` - 贡献指南
  - `Documents/INTERACTIVE.md` - 交互式菜单说明
  - `Documents/MOUDULES.D.README.md` - 模块配置说明
  - `Documents/CHANGELOG.md` - 更新日志

### 改进

- 🔧 **目录结构重构**：
  - `scripts/proxy/` - 代理服务脚本
  - `scripts/system/` - 系统工具脚本
  - `scripts/tools/` - 实用工具脚本
- 🔧 **脚本优化**：
  - `m.sh` - 主入口脚本（检查更新）
  - `menu.sh` - 交互式菜单核心脚本
  - `install.sh` - 一键安装脚本
  - `uninstall.sh` - 卸载脚本
- 🔧 **性能优化**：
  - 菜单加载时缓存父菜单标题
  - 减少文件 I/O 和 awk 处理次数
  - 内联 URL 生成逻辑
  - 消除选择菜单时的闪烁问题
- 🔧 **用户体验**：
  - 清晰的面包屑导航
  - 实时显示执行预览
  - 支持 vim 键位（j/k）
  - 友好的错误提示

### 技术细节

- 🛠️ **纯 Bash 实现**：无需额外依赖
- 🛠️ **TOML 解析**：使用 awk 解析配置文件
- 🛠️ **缓存机制**：减少重复解析，提升性能
- 🛠️ **环境变量**：`VTK_DOWNLOAD_SOURCE` 记录下载源选择

### 兼容性

- ✅ **向后兼容**：保持 `m` 命令可用
- ✅ **平滑升级**：自动处理目录结构变更
- ✅ **脚本保持不变**：`scripts/` 目录下所有脚本功能保持一致

### 移除

- ❌ **移除 vtk 命令**：统一使用 `m` 命令
- ❌ **移除本地脚本存储**：改为在线执行

### 文档

- 📝 完整的项目架构说明
- 📝 详细的交互式菜单使用指南
- 📝 配置文件使用说明
- 📝 扩展开发教程

## [1.0.0] - 2024-12-23

### 新增
- 🎉 项目初始化发布
- ✨ 主菜单系统（树形结构）
- 📦 一键安装脚本
- 🔧 模块化脚本管理
- 📝 完整项目文档

### 代理服务
- ✅ AnyTLS 管理脚本
- ✅ Shadowsocks 管理脚本
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
