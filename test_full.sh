#!/usr/bin/env bash

# 完整模拟测试脚本

MODULES_DIR="modules.d"

# 解析 TOML 数组
parse_toml_array() {
    local file=$1
    local key=$2
    
    awk -v key="$key" '
    BEGIN { in_array=0 }
    $0 ~ "^[[:space:]]*" key "[[:space:]]*=[[:space:]]*\\[" {
        in_array=1
        if ($0 ~ /\]/) {
            line = $0
            gsub(/.*\[/, "", line)
            gsub(/\].*/, "", line)
            gsub(/"/, "", line)
            gsub(/,/, "\n", line)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
            print line
            exit
        }
        next
    }
    in_array {
        if ($0 ~ /\]/) { exit }
        gsub(/^[[:space:]]*"|"[[:space:]]*,?[[:space:]]*$/, "")
        if ($0 != "") print $0
    }
    ' "$file"
}

# 解析 TOML 键值对
parse_toml_value() {
    local file=$1
    local section=$2
    local key=$3
    
    awk -v section="$section" -v key="$key" '
    BEGIN { in_section=0 }
    $0 ~ "^\\[" section "\\]" { in_section=1; next }
    in_section && /^\[/ { in_section=0 }
    in_section && $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
        gsub(/"/, "", $0)
        sub(/^[^=]*= */, "", $0)
        print $0
        exit
    }
    ' "$file"
}

# 解析菜单项详细信息
parse_menu_item() {
    local file=$1
    local item_id=$2
    local field=$3
    
    grep -A 20 '^\[\[menu\]\]' "$file" | awk -v id="$item_id" -v field="$field" '
    BEGIN { found=0 }
    /^\[\[menu\]\]/ { 
        found=0
        next 
    }
    /^id = / {
        gsub(/"/, "", $0)
        gsub(/id = /, "", $0)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
        if ($0 == id) { 
            found=1 
        } else { 
            found=0 
        }
        next
    }
    found && $0 ~ "^" field " = " {
        gsub(/"/, "", $0)
        sub(/^[^=]*= */, "", $0)
        print $0
        exit
    }
    '
}

# 模拟加载子菜单
load_submenu() {
    local menu_id=$1
    
    declare -a MENU_IDS
    declare -a MENU_TITLES
    declare -A MENU_SCRIPTS
    
    # 查找对应的配置文件
    local submenu_file=""
    for file in "${MODULES_DIR}"/*.toml; do
        [ -f "$file" ] || continue
        [ "$(basename "$file")" = "menu.toml" ] && continue
        
        if grep -q "^id = \"$menu_id\"" "$file"; then
            submenu_file="$file"
            break
        fi
    done
    
    if [ -z "$submenu_file" ]; then
        echo "[错误] 未找到菜单配置"
        return 1
    fi
    
    echo "找到配置文件: $submenu_file"
    echo ""
    
    # 读取子菜单项
    local item_ids=$(parse_toml_array "$submenu_file" "sub_menus")
    
    echo "子菜单项:"
    while IFS= read -r item_id; do
        [ -z "$item_id" ] && continue
        
        MENU_IDS+=("$item_id")
        
        # 读取标题
        local title=$(parse_menu_item "$submenu_file" "$item_id" "title")
        MENU_TITLES+=("$title")
        
        # 读取脚本 key
        local script_key=$(parse_menu_item "$submenu_file" "$item_id" "script")
        
        # 通过 key 获取脚本路径
        if [ -n "$script_key" ]; then
            local script_path=$(parse_toml_value "$submenu_file" "scripts" "$script_key")
            if [ -n "$script_path" ]; then
                MENU_SCRIPTS["$item_id"]="$script_path"
            fi
        fi
        
        echo "  ID: $item_id"
        echo "    标题: $title"
        echo "    脚本键: $script_key"
        echo "    脚本路径: ${MENU_SCRIPTS[$item_id]}"
        echo ""
    done <<< "$item_ids"
    
    # 测试访问
    echo "=== 测试访问 MENU_SCRIPTS ==="
    for id in "${MENU_IDS[@]}"; do
        echo "  MENU_SCRIPTS[$id] = ${MENU_SCRIPTS[$id]}"
    done
}

echo "=========================================="
echo "         测试菜单加载流程"
echo "=========================================="
echo ""

load_submenu "system"
