# VPSToolKit 模块配置文件目录

此目录包含 VPSToolKit 的所有模块配置文件。

## 目录结构

- `default/` - 官方默认模块，更新时会被覆盖
- `extend/` - 用户自定义模块，更新时保留

## 文件命名规范

- 文件名以三位数字开头，用于控制加载顺序
- 数字越大，优先级越高，可以覆盖之前的配置
- 格式：`XXX-module_name.toml`

示例：
- `010-proxy.toml` - 代理服务模块
- `020-system.toml` - 系统工具模块
- `030-tools.toml` - 实用工具模块
