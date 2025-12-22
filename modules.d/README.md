# VPSToolKit 模块配置文件目录

此目录包含 VPSToolKit 的所有模块配置文件。

## 目录说明

所有模块配置文件直接放在此目录下，统一管理。

## 文件命名规范

- 文件名以三位数字开头，用于控制加载顺序
- 数字越大，优先级越高，可以覆盖之前的配置
- 格式：`XXX-module_name.toml`

## 官方模块（000-099）

- `000-menu.toml` - 主菜单配置
- `010-proxy.toml` - 代理服务模块
- `020-system.toml` - 系统工具模块
- `030-tools.toml` - 实用工具模块

## 自定义扩展（100-999）

你可以创建自己的配置文件来扩展功能：

```bash
# 创建自定义模块
vim /etc/vpstoolkit/modules.d/100-custom.toml
```

示例：

```toml
# 自定义脚本定义（在线执行模式）
[scripts]
custom_script = "bash <(curl -sL https://example.com/custom.sh)"

# 添加到主菜单
[[menus]]
id = "main"
title = "VPSToolKit 主菜单"
sub_menus = [
    "custom_menu",
]

# 自定义菜单项
[[menus]]
id = "custom_menu"
title = "我的自定义功能"
script = "custom_script"
```

> 💡 **提示**：VPSToolKit 使用在线执行模式，脚本不会保存到本地，每次执行都从远程获取最新版本。你也可以使用本地路径：`bash /path/to/local.sh`

## 优先级说明

- `000-099`: 核心功能（官方模块）
- `100-199`: 代理服务扩展
- `200-299`: 系统工具扩展
- `300-399`: 实用工具扩展
- `400-999`: 用户自定义功能

后加载的配置可以覆盖先加载的配置，因此使用更高的数字前缀可以覆盖官方配置。
