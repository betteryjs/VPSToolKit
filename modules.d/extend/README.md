# 用户扩展模块目录

此目录用于存放用户自定义的模块配置文件。

## 特点

- ✅ 更新 VPSToolKit 时不会被覆盖
- ✅ 可以扩展或覆盖默认配置
- ✅ 支持优先级控制

## 使用方法

### 1. 创建自定义配置

在此目录创建配置文件，文件名以数字开头：

```bash
vim /etc/vpstoolkit/modules.d/extend/100-my-custom.toml
```

### 2. 编写配置内容

```toml
[scripts]
my_custom_script = "bash /path/to/my/script.sh"

[[menus]]
id = "main"
title = "VPSToolKit 主菜单"
sub_menus = [
    "my_custom_menu",  # 添加到主菜单
]

[[menus]]
id = "my_custom_menu"
title = "我的自定义功能"
script = "my_custom_script"
```

### 3. 测试

运行主菜单查看效果：

```bash
m
```

## 示例

查看 `example-custom.toml.example` 了解更多示例。

## 优先级

- 文件名数字越大，优先级越高
- 建议使用 100 以上的数字
- 可以覆盖默认配置中的菜单和脚本

## 远程订阅

除了本地扩展，还可以使用远程订阅：

编辑 `/etc/vpstoolkit/config.toml`：

```toml
[remote]
subscribes = [
    "https://example.com/custom-config.toml",
]
```

## 注意事项

- 确保 TOML 语法正确
- 脚本路径使用绝对路径
- ID 命名避免与官方模块冲突
- 定期备份自定义配置
