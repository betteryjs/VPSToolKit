#!/bin/bash

# 测试脚本 - 检查菜单加载逻辑

CONFIG_DIR="/etc/vpstoolkit"
MODULES_DIR="${CONFIG_DIR}/modules.d"

echo "===== 测试环境检查 ====="
echo "MODULES_DIR: $MODULES_DIR"
echo ""

echo "===== 检查 TOML 文件 ====="
if [ -d "$MODULES_DIR" ]; then
    ls -la "$MODULES_DIR"/*.toml
else
    echo "错误: $MODULES_DIR 目录不存在"
fi
echo ""

echo "===== 查找 proxy_services 配置 ====="
for toml_file in "${MODULES_DIR}"/*.toml; do
    [ -f "$toml_file" ] || continue
    echo "检查文件: $toml_file"
    grep -n "proxy_services" "$toml_file" || echo "  未找到"
done
echo ""

echo "===== 查看 010-proxy.toml 内容 ====="
if [ -f "${MODULES_DIR}/010-proxy.toml" ]; then
    cat "${MODULES_DIR}/010-proxy.toml"
else
    echo "文件不存在: ${MODULES_DIR}/010-proxy.toml"
fi
