# VPSToolKit 开发规则

本文档定义了 VPSToolKit 项目的开发规则和最佳实践。

## 目录

- [代码组织](#代码组织)
- [脚本规范](#脚本规范)
- [配置文件规范](#配置文件规范)
- [命名规范](#命名规范)
- [提交规范](#提交规范)
- [测试规范](#测试规范)

## 代码组织

### 目录结构

```
VPSToolKit/
├── config.toml              # 主配置文件
├── vtk-interactive.sh       # 交互式菜单脚本
├── m.sh                     # 主入口脚本
├── install.sh               # 安装脚本
├── uninstall.sh             # 卸载脚本
├── modules.d/               # 模块配置目录
│   ├── 000-menu.toml       # 主菜单配置
│   ├── 010-proxy.toml      # 代理服务模块
│   ├── 020-system.toml     # 系统工具模块
│   └── 030-tools.toml      # 实用工具模块
└── scripts/                 # 脚本文件
    ├── proxy/              # 代理服务
    ├── system/             # 系统工具
    └── tools/              # 实用工具
```

### 文件放置规则

1. **脚本文件**：
   - 代理服务：`scripts/proxy/`
   - 系统工具：`scripts/system/`
   - 实用工具：`scripts/tools/`

2. **配置文件**：
   - 模块配置：`modules.d/`（使用数字前缀控制加载顺序）

3. **文档文件**：
   - 根目录：README、LICENSE、CHANGELOG 等
   - 开发文档：DEVELOPMENT.md、CONTRIBUTING.md、Rules.md

## 脚本规范

### 脚本模板

每个脚本应遵循以下模板：

```bash
#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	Description: 脚本功能描述
#	Version: x.y.z
#	Author: 作者名称
#	Date: 创建日期
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
        echo -e "${Error} 需要 root 权限运行此脚本"
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

### 脚本编写规则

1. **Shebang**：统一使用 `#!/usr/bin/env bash`
2. **PATH**：在脚本开头设置完整的 PATH
3. **颜色定义**：使用统一的颜色变量
4. **错误处理**：
   - 检查命令执行结果
   - 提供清晰的错误信息
   - 适当的退出码

5. **用户交互**：
   - 使用 `read -p` 进行交互
   - 提供默认值选项
   - 显示进度信息

6. **代码风格**：
   - 缩进：4 个空格
   - 函数定义：`function_name(){ ... }`
   - 变量引用：使用双引号 `"${var}"`
   - 条件判断：使用 `[[ ]]` 而非 `[ ]`

### 脚本功能要求

1. **独立运行**：脚本应该能够独立执行
2. **幂等性**：多次运行应该产生相同结果
3. **清理资源**：失败时清理临时文件
4. **日志记录**：关键操作记录日志
5. **兼容性**：支持主流 Linux 发行版

## 配置文件规范

### TOML 格式

所有配置文件使用 TOML 格式：

```toml
# 脚本定义
[scripts]
script_id = "bash /path/to/script.sh"

# 菜单定义
[[menus]]
id = "menu_id"
title = "菜单标题"
sub_menus = ["child1", "child2"]

[[menus]]
id = "child1"
title = "子菜单"
script = "script_id"
```

### 配置规则

1. **文件命名**：
   - 格式：`XXX-module_name.toml`
   - 数字范围：000-999
   - 数字越大，优先级越高

2. **ID 命名**：
   - 格式：`category_name`
   - 使用下划线分隔
   - 全部小写字母

3. **脚本路径**：
   - 使用绝对路径
   - 指向 `/usr/local/vpstoolkit/scripts/`

4. **菜单层次**：
   - main 为根菜单
   - 合理组织子菜单层次
   - 避免过深的嵌套

### 模块优先级

- `000-099`：核心菜单配置
- `100-199`：代理服务
- `200-299`：系统工具
- `300-399`：实用工具
- `400-499`：扩展功能
- `500-999`：用户自定义

## 命名规范

### 文件命名

1. **脚本文件**：
   - 格式：`service_name.sh`
   - 使用小写字母
   - 用下划线分隔单词

2. **配置文件**：
   - 格式：`XXX-module_name.toml`
   - 三位数字前缀
   - 小写字母，下划线分隔

### 变量命名

1. **全局变量**：大写字母，下划线分隔
   ```bash
   INSTALL_DIR="/usr/local/bin"
   CONFIG_FILE="/etc/vpstoolkit/config.toml"
   ```

2. **局部变量**：小写字母，下划线分隔
   ```bash
   local script_name="ss.sh"
   local download_url="https://example.com"
   ```

3. **函数名**：小写字母，下划线分隔
   ```bash
   check_root()
   install_service()
   get_system_info()
   ```

### ID 命名规范

配置文件中的 ID：

```toml
# 脚本 ID：category_name
proxy_ss = "..."
system_bbr = "..."
tools_speedtest = "..."

# 菜单 ID：category 或 category_name
[[menus]]
id = "proxy_services"  # 分类菜单
id = "proxy_ss"        # 具体功能
```

## 提交规范

### Commit Message

格式：

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
- `[Perf]` - 性能优化
- `[Test]` - 测试相关
- `[Chore]` - 构建/工具相关

### 示例

```bash
git commit -m "[Feat] 添加 Hysteria 代理支持"
git commit -m "[Fix] 修复 BBR 安装失败问题"
git commit -m "[Docs] 更新安装文档"
git commit -m "[Refactor] 重构配置加载逻辑"
```

### 分支命名

- `feature/功能名称` - 新功能分支
- `fix/问题描述` - Bug 修复分支
- `docs/文档说明` - 文档更新分支
- `refactor/重构说明` - 重构分支

## 测试规范

### 语法检查

```bash
# 检查 Bash 语法
bash -n script.sh

# 使用 shellcheck（推荐）
shellcheck script.sh
```

### 功能测试

1. **单脚本测试**：
   ```bash
   bash scripts/proxy/ss.sh
   ```

2. **集成测试**：
   ```bash
   bash install.sh
   m  # 测试主菜单
   ```

3. **兼容性测试**：
   - Debian 11/12
   - Ubuntu 20.04/22.04/24.04
   - CentOS 7/8/9
   - Alpine Linux

### 测试清单

- [ ] 脚本语法正确
- [ ] 能够独立运行
- [ ] root 权限检查有效
- [ ] 错误处理完善
- [ ] 用户交互友好
- [ ] 清理临时文件
- [ ] 多发行版兼容

## 文档规范

### README.md

- 项目简介
- 快速开始
- 功能列表
- 配置说明
- 使用示例

### DEVELOPMENT.md

- 开发环境搭建
- 项目架构
- 开发流程
- API 文档

### CONTRIBUTING.md

- 贡献方式
- 代码规范
- 提交流程
- 行为准则

### CHANGELOG.md

- 版本号
- 发布日期
- 更改类型（新增/改进/修复）
- 具体内容

## 版本管理

### 语义化版本

- **主版本号（Major）**：不兼容的 API 修改
- **次版本号（Minor）**：向下兼容的功能性新增
- **修订号（Patch）**：向下兼容的问题修正

### 版本示例

- `1.0.0` - 初始版本
- `1.1.0` - 添加新功能
- `1.1.1` - 修复 Bug
- `2.0.0` - 重大更新

## 安全规范

### 脚本安全

1. **输入验证**：验证所有用户输入
2. **路径安全**：避免路径遍历攻击
3. **命令注入**：正确引用变量
4. **权限检查**：只在需要时要求 root

### 敏感信息

1. **密码**：不在代码中硬编码
2. **密钥**：不提交到仓库
3. **证书**：安全存储和传输

### 下载安全

1. **HTTPS**：优先使用 HTTPS
2. **校验**：验证下载文件
3. **来源**：使用可信的下载源

## 最佳实践

### 代码质量

1. **模块化**：功能拆分成独立函数
2. **可读性**：添加适当注释
3. **可维护性**：避免重复代码
4. **可扩展性**：设计灵活的接口

### 用户体验

1. **清晰提示**：明确的操作说明
2. **错误处理**：友好的错误信息
3. **进度反馈**：显示执行进度
4. **默认值**：提供合理的默认选项

### 性能优化

1. **并行处理**：适当使用并行
2. **缓存机制**：避免重复下载
3. **资源清理**：及时释放资源

---

遵循这些规则，让 VPSToolKit 更加规范、易用、可靠！
