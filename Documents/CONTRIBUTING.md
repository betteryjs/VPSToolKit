# VPSToolKit 贡献指南

感谢你对 VPSToolKit 项目的关注！我们欢迎所有形式的贡献，无论是新功能、Bug 修复、文档改进还是建议反馈。

VPSToolKit 采用了类似 NodeScriptKit 的模块化架构，使用 TOML 配置文件管理菜单和脚本。

## 📋 目录

- [行为准则](#行为准则)
- [如何贡献](#如何贡献)
- [项目架构](#项目架构)
- [开发流程](#开发流程)
- [代码规范](#代码规范)
- [提交规范](#提交规范)
- [问题反馈](#问题反馈)

## 行为准则

参与本项目即表示你同意遵守我们的行为准则：

- 尊重所有贡献者
- 接受建设性批评
- 专注于对项目最有利的事情
- 对他人表现出同理心

## 项目架构

VPSToolKit 采用模块化设计：

- `config.toml` - 主配置文件
- `modules.d/` - 模块配置目录
  - `default/` - 官方默认模块（更新时会覆盖）
  - `extend/` - 用户自定义模块（更新时保留）
- `scripts/` - 脚本文件目录
  - `proxy/` - 代理服务脚本
  - `system/` - 系统工具脚本
  - `tools/` - 实用工具脚本

详细架构请查看 [DEVELOPMENT.md](./DEVELOPMENT.md)

## 如何贡献

### 方式一：提交 Issue

如果你发现了 Bug 或有新功能建议：

1. 搜索现有 Issues，避免重复
2. 创建新 Issue，使用适当的模板
3. 清晰描述问题或建议
4. 提供复现步骤（Bug）或使用场景（功能）

### 方式二：提交 Pull Request

1. **Fork 仓库**
   ```bash
   # 在 GitHub 上点击 Fork 按钮
   ```

2. **克隆到本地**
   ```bash
   git clone https://github.com/你的用户名/VPSToolKit.git
   cd VPSToolKit
   ```

3. **创建功能分支**
   ```bash
   git checkout -b feature/your-feature-name
   # 或
   git checkout -b fix/your-bug-fix
   ```

4. **进行修改**
   - 遵循代码规范
   - 添加必要注释
   - 更新相关文档

5. **测试修改**
   ```bash
   # 在虚拟机或测试环境中测试
   bash vpstk.sh
   ```

6. **提交更改**
   ```bash
   git add .
   git commit -m "feat: 添加新功能描述"
   ```

7. **推送到 GitHub**
   ```bash
   git push origin feature/your-feature-name
   ```

8. **创建 Pull Request**
   - 访问你的 Fork 仓库
   - 点击 "New Pull Request"
   - 填写 PR 描述模板
   - 等待审核

## 开发流程

### 环境准备

```bash
# 系统要求
- Linux (Debian/Ubuntu/CentOS)
- Bash 4.0+
- Root 权限

# 工具要求
- git
- wget/curl
- 文本编辑器（vim/nano/vscode）
```

### 本地开发

```bash
# 1. 修改脚本
vim scripts/proxy/new-proxy.sh

# 2. 本地测试
bash scripts/proxy/new-proxy.sh

# 3. 集成测试
bash vpstk.sh
```

### 添加新脚本

1. **确定分类**
   - `scripts/proxy/` - 代理服务
   - `scripts/system/` - 系统工具
   - `scripts/tools/` - 实用工具

2. **使用模板**
   - 参考 `scripts/README.md` 中的模板
   - 包含完整的脚本头部信息
   - 实现必要的功能函数

3. **更新主菜单**
   - 编辑 `vpstk.sh`
   - 添加新的菜单项
   - 添加对应的函数调用

4. **更新文档**
   - 在 `README.md` 中添加说明
   - 在 `scripts/README.md` 中更新脚本清单

## 代码规范

### Bash 脚本规范

#### 1. 文件头部

```bash
#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: 脚本功能描述
#	Version: 1.0.0
#	Author: 作者名称
#=================================================
```

#### 2. 变量命名

```bash
# 全局变量：大写下划线
SCRIPT_VERSION="1.0.0"
DEFAULT_PORT=8080

# 局部变量：小写下划线
local_var="value"
user_input=""
```

#### 3. 函数命名

```bash
# 函数名：小写下划线
check_system(){
    # 函数体
}

install_service(){
    # 函数体
}
```

#### 4. 代码风格

```bash
# 使用 4 空格缩进
if [[ condition ]]; then
    echo "statement"
else
    echo "other"
fi

# 条件判断使用 [[ ]]
[[ -e file ]] && echo "exist"

# 命令替换使用 $()
result=$(command)
```

#### 5. 错误处理

```bash
# 检查命令执行结果
command || { echo "Error"; exit 1; }

# 检查文件存在
[[ ! -e /path ]] && echo "Error" && exit 1

# 检查变量为空
[[ -z "${var}" ]] && var="default"
```

#### 6. 用户提示

```bash
# 使用颜色变量
echo -e "${Info} 信息提示"
echo -e "${Error} 错误提示"
echo -e "${Success} 成功提示"
```

### 文档规范

#### README.md

- 使用 Markdown 格式
- 包含清晰的标题层级
- 添加必要的代码示例
- 包含使用说明和示例

#### 注释规范

```bash
# 单行注释：说明下面代码的作用
command

# 多行注释：复杂逻辑需要详细说明
# 这里是第一行说明
# 这里是第二行说明
complex_command

# 函数注释
# 功能：检查系统类型
# 参数：无
# 返回：设置 release 变量
check_system(){
    # 函数体
}
```

## 提交规范

### Commit Message 格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

#### Type 类型

- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式（不影响功能）
- `refactor`: 代码重构
- `test`: 测试相关
- `chore`: 构建/工具相关

#### 示例

```bash
# 新功能
git commit -m "feat(proxy): 添加 Hysteria 支持"

# Bug 修复
git commit -m "fix(bbr): 修复 CentOS 8 内核安装失败"

# 文档更新
git commit -m "docs(readme): 更新安装说明"

# 代码重构
git commit -m "refactor(vpstk): 优化菜单显示逻辑"
```

### Pull Request 标题

```
[Type] 简短描述

例如：
[Feat] 添加 Hysteria 代理支持
[Fix] 修复 BBR 安装脚本错误
[Docs] 完善安装文档说明
```

### Pull Request 描述

```markdown
## 变更类型
- [ ] 新功能
- [x] Bug 修复
- [ ] 文档更新
- [ ] 代码重构

## 变更说明
简要描述本次 PR 的内容

## 测试环境
- OS: Debian 12
- Kernel: 6.1.0

## 测试结果
- [x] 功能正常
- [x] 无明显错误
- [x] 文档已更新

## 相关 Issue
Closes #123
```

## 问题反馈

### Bug 报告

使用 Issue 模板提交 Bug 报告，包含：

1. **问题描述**：清晰描述遇到的问题
2. **复现步骤**：详细的操作步骤
3. **预期行为**：应该出现的正确结果
4. **实际行为**：实际发生的错误情况
5. **环境信息**：
   - 操作系统及版本
   - 内核版本
   - 脚本版本
6. **错误日志**：相关的错误输出
7. **截图**：如果适用

### 功能请求

使用 Issue 模板提交功能请求，包含：

1. **功能描述**：想要的功能是什么
2. **使用场景**：为什么需要这个功能
3. **解决方案**：你认为应该如何实现
4. **替代方案**：是否有其他解决方法
5. **附加信息**：其他相关信息

## 审核流程

1. **自动检查**
   - 代码格式检查
   - 基本语法检查

2. **人工审核**
   - 代码质量
   - 功能完整性
   - 文档完整性

3. **测试验证**
   - 功能测试
   - 兼容性测试

4. **合并**
   - 审核通过后合并到主分支
   - 更新版本号
   - 发布更新日志

## 社区资源

- **GitHub Issues**: [问题追踪](https://github.com/yourusername/VPSToolKit/issues)
- **GitHub Discussions**: [讨论区](https://github.com/yourusername/VPSToolKit/discussions)
- **文档**: [项目文档](https://github.com/yourusername/VPSToolKit#readme)

## 致谢

感谢所有为 VPSToolKit 做出贡献的开发者！

你的每一个贡献都让这个项目变得更好！❤️
