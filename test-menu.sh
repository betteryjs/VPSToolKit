#!/bin/bash

# 测试脚本 - 模拟菜单加载

CONFIG_DIR="/etc/vpstoolkit"
MODULES_DIR="${CONFIG_DIR}/modules.d"

echo "===== 测试 load_submenu_from_toml 逻辑 ====="
echo ""

menu_id="proxy_services"
toml_file="${MODULES_DIR}/010-proxy.toml"

echo "测试参数:"
echo "  menu_id: $menu_id"
echo "  toml_file: $toml_file"
echo ""

# 模拟查找 sub_menus
echo "===== 查找 sub_menus 数组 ====="
awk '
BEGIN { in_menus=0; in_target=0; found_id="" }
/^\[\[menus\]\]/ { in_menus=1; in_target=0; found_id=""; next }
in_menus && /^[[:space:]]*id[[:space:]]*=/ {
    match($0, /id[[:space:]]*=[[:space:]]*"([^"]*)"/, arr)
    found_id = arr[1]
    if (found_id == "'"$menu_id"'") {
        in_target=1
        print "找到目标菜单: " found_id
    }
}
in_target && /^[[:space:]]*sub_menus[[:space:]]*=/ {
    print "找到 sub_menus 数组"
    in_array=1
    if ($0 ~ /\]/) {
        # 单行数组
        match($0, /\[([^\]]*)\]/, arr)
        content = arr[1]
        gsub(/"/, "", content)
        gsub(/,/, " ", content)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", content)
        split(content, items, /[[:space:]]+/)
        for (i in items) {
            if (items[i] != "") print "  子菜单: " items[i]
        }
        exit
    }
    next
}
in_array {
    if ($0 ~ /\]/) {
        # 数组结束
        exit
    }
    # 提取元素
    gsub(/^[[:space:]]*"|"[[:space:]]*,?[[:space:]]*$/, "")
    if ($0 != "") print "  子菜单: " $0
}
' "$toml_file"

echo ""
echo "===== 查找每个子菜单项的 title 和 script ====="

# 获取所有子菜单 ID
sub_ids=$(awk '
BEGIN { in_menus=0; in_target=0 }
/^\[\[menus\]\]/ { in_menus=1; in_target=0; next }
in_menus && /^[[:space:]]*id[[:space:]]*=/ {
    match($0, /id[[:space:]]*=[[:space:]]*"([^"]*)"/, arr)
    if (arr[1] == "'"$menu_id"'") in_target=1
}
in_target && /^[[:space:]]*sub_menus[[:space:]]*=/ {
    in_array=1
    if ($0 ~ /\]/) {
        match($0, /\[([^\]]*)\]/, arr)
        content = arr[1]
        gsub(/"/, "", content)
        print content
        exit
    }
    next
}
in_array {
    if ($0 ~ /\]/) exit
    gsub(/^[[:space:]]*"|"[[:space:]]*,?[[:space:]]*$/, "")
    printf "%s ", $0
}
' "$toml_file" | tr ',' ' ')

for sub_id in $sub_ids; do
    echo "处理子菜单: $sub_id"
    
    # 查找 title 和 script
    awk '
    BEGIN { in_menus=0; found_id="" }
    /^\[\[menus\]\]/ { in_menus=1; found_id=""; next }
    in_menus && /^[[:space:]]*id[[:space:]]*=/ {
        match($0, /id[[:space:]]*=[[:space:]]*"([^"]*)"/, arr)
        found_id = arr[1]
    }
    found_id == "'"$sub_id"'" && /^[[:space:]]*title[[:space:]]*=/ {
        match($0, /title[[:space:]]*=[[:space:]]*"([^"]*)"/, arr)
        print "  title: " arr[1]
    }
    found_id == "'"$sub_id"'" && /^[[:space:]]*script[[:space:]]*=/ {
        match($0, /script[[:space:]]*=[[:space:]]*"([^"]*)"/, arr)
        script_key = arr[1]
        print "  script_key: " script_key
        
        # 查找脚本路径
        cmd = "awk '\''BEGIN{in_scripts=0} /^\\[scripts\\]/{in_scripts=1;next} /^\\[\\[/{in_scripts=0} in_scripts && /^[[:space:]]*" script_key "[[:space:]]*=/{match($0,/\"([^\"]*)\"/,a);print a[1]}'\'' " "'"$toml_file"'"
        cmd | getline script_path
        close(cmd)
        print "  script_path: " script_path
    }
    ' "$toml_file"
    echo ""
done

