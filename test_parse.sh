#!/usr/bin/env bash

# 测试 TOML 解析
MODULES_DIR="./modules.d"

# 解析 TOML 数组（兼容多种格式）
parse_toml_array() {
    local file=$1
    local key=$2
    
    # 方法1: 尝试使用 awk（大多数系统）
    local result=$(awk -v key="$key" '
    BEGIN { in_array=0 }
    $0 ~ key "[[:space:]]*=" {
        # 单行数组格式: key = ["a", "b", "c"]
        if ($0 ~ /\[.*\]/) {
            line = $0
            sub(/.*\[/, "", line)
            sub(/\].*/, "", line)
            gsub(/"/, "", line)
            gsub(/,[[:space:]]*/, "\n", line)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
            print line
            exit
        }
        # 多行数组格式
        in_array=1
        next
    }
    in_array {
        if ($0 ~ /\]/) { exit }
        gsub(/^[[:space:]]*"?/, "")
        gsub(/"?[[:space:]]*,?[[:space:]]*$/, "")
        if (length($0) > 0) print $0
    }
    ' "$file" 2>/dev/null)
    
    # 方法2: 如果 awk 失败，尝试使用 sed 和 grep
    if [ -z "$result" ]; then
        result=$(sed -n "/^[[:space:]]*${key}[[:space:]]*=/,/\]/p" "$file" 2>/dev/null | \
                 grep -v "^[[:space:]]*${key}" | \
                 grep -v "\]" | \
                 sed 's/^[[:space:]]*"//;s/"[[:space:]]*,*[[:space:]]*$//' | \
                 grep -v '^$')
    fi
    
    echo "$result"
}

echo "=== 测试解析 menu.toml ==="
menu_file="${MODULES_DIR}/menu.toml"

if [ ! -f "$menu_file" ]; then
    echo "错误: 文件不存在 $menu_file"
    exit 1
fi

echo ""
echo "文件内容:"
cat "$menu_file"

echo ""
echo "=== 解析 sub_menus ==="
ids=$(parse_toml_array "$menu_file" "sub_menus")
echo "结果:"
echo "$ids"
echo "行数: $(echo "$ids" | wc -l)"

echo ""
echo "=== 解析 titles ==="
titles=$(parse_toml_array "$menu_file" "titles")
echo "结果:"
echo "$titles"
echo "行数: $(echo "$titles" | wc -l)"
