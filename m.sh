#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	Description: VPSToolKit 菜单核心脚本
#	Version: 2.0.0
#	Author: VPSToolKit Contributors
#=================================================

# 配置路径
CONFIG_DIR="/etc/vpstoolkit"
MODULES_DIR="${CONFIG_DIR}/modules.d"
ENV_FILE="${CONFIG_DIR}/env"

# 加载环境配置
if [ -f "${ENV_FILE}" ]; then
    source "${ENV_FILE}"
fi

# 颜色定义
Green="\033[32m"
Red="\033[31m"
Yellow="\033[0;33m"
Blue="\033[0;34m"
Cyan="\033[0;36m"
Reset="\033[0m"

# 全局变量
declare -ga MENU_IDS
declare -ga MENU_TITLES
declare -gA MENU_SCRIPTS
current_selection=0
current_menu="main"
parent_menu_title=""

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

# 加载主菜单
load_main_menu() {
    MENU_IDS=()
    MENU_TITLES=()
    MENU_SCRIPTS=()
    parent_menu_title=""
    
    local menu_file="${MODULES_DIR}/menu.toml"
    
    if [ ! -f "$menu_file" ]; then
        echo -e "${Red}[错误]${Reset} 主菜单配置文件不存在: $menu_file"
        exit 1
    fi
    
    # 读取子菜单 ID
    local ids=$(parse_toml_array "$menu_file" "sub_menus")
    local titles=$(parse_toml_array "$menu_file" "titles")
    
    # 调试：检查是否读取到数据
    if [ -z "$ids" ]; then
        echo -e "${Red}[错误]${Reset} 无法从配置文件读取菜单数据"
        echo -e "${Yellow}[调试]${Reset} 配置文件: $menu_file"
        echo -e "${Yellow}[调试]${Reset} 请检查配置文件格式是否正确"
        exit 1
    fi
    
    # 转为数组
    while IFS= read -r line; do
        [ -n "$line" ] && MENU_IDS+=("$line")
    done <<< "$ids"
    
    while IFS= read -r line; do
        [ -n "$line" ] && MENU_TITLES+=("$line")
    done <<< "$titles"
    
    # 检查菜单是否为空
    if [ ${#MENU_IDS[@]} -eq 0 ]; then
        echo -e "${Red}[错误]${Reset} 菜单配置为空"
        exit 1
    fi
}

# 加载子菜单
load_submenu() {
    local menu_id=$1
    
    MENU_IDS=()
    MENU_TITLES=()
    MENU_SCRIPTS=()
    
    # 获取并缓存父菜单标题
    local menu_file="${MODULES_DIR}/menu.toml"
    local ids=$(parse_toml_array "$menu_file" "sub_menus")
    local titles=$(parse_toml_array "$menu_file" "titles")
    
    local id_array=()
    local title_array=()
    
    while IFS= read -r line; do
        [ -n "$line" ] && id_array+=("$line")
    done <<< "$ids"
    
    while IFS= read -r line; do
        [ -n "$line" ] && title_array+=("$line")
    done <<< "$titles"
    
    for i in "${!id_array[@]}"; do
        if [ "${id_array[$i]}" = "$menu_id" ]; then
            parent_menu_title="${title_array[$i]}"
            break
        fi
    done
    
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
        echo -e "${Red}[错误]${Reset} 未找到菜单配置"
        return 1
    fi
    
    # 读取子菜单项
    local item_ids=$(parse_toml_array "$submenu_file" "sub_menus")
    
    # 调试信息
    if [ -z "$item_ids" ]; then
        echo -e "${Red}[错误]${Reset} 无法从配置文件读取子菜单项" >&2
        echo -e "${Yellow}[调试]${Reset} 配置文件: $submenu_file" >&2
        echo -e "${Yellow}[调试]${Reset} 菜单ID: $menu_id" >&2
        return 1
    fi
    
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
            MENU_SCRIPTS["$item_id"]="$script_path"
        fi
    done <<< "$item_ids"
    
    # 检查是否成功加载菜单项
    if [ ${#MENU_IDS[@]} -eq 0 ]; then
        echo -e "${Red}[错误]${Reset} 子菜单配置为空" >&2
        echo -e "${Yellow}[调试]${Reset} 请检查配置文件格式" >&2
        return 1
    fi
}

# 获取脚本 URL
get_script_url() {
    local script_path=$1
    
    if [[ "$script_path" =~ ^https?:// ]]; then
        echo "$script_path"
        return
    fi
    
    if [[ "${VTK_DOWNLOAD_SOURCE}" == "oss" ]]; then
        echo "https://oss.naloong.de/VPSToolKit/${script_path}"
    else
        echo "https://raw.githubusercontent.com/betteryjs/VPSToolKit/master/${script_path}"
    fi
}

# 渲染菜单
render_menu() {
    clear
    
    # 显示标题
    if [ "$current_menu" = "main" ]; then
        echo -e "${Cyan}======================================${Reset}"
        echo -e "${Cyan}       VPSToolKit 主菜单${Reset}"
        echo -e "${Cyan}======================================${Reset}"
    else
        echo -e "${Cyan}======================================${Reset}"
        echo -e "${Cyan}   主菜单 ${Yellow}>${Reset} ${Green}${parent_menu_title}${Reset}"
        echo -e "${Cyan}======================================${Reset}"
    fi
    
    echo ""
    
    # 显示菜单项
    for i in "${!MENU_IDS[@]}"; do
        if [ $i -eq $current_selection ]; then
            echo -e " ${Green}▶${Reset} ${Yellow}${MENU_TITLES[$i]}${Reset}"
        else
            echo -e "   ${MENU_TITLES[$i]}"
        fi
    done
   
    # 显示退出/返回选项
    if [ $current_selection -eq ${#MENU_IDS[@]} ]; then
        if [ "$current_menu" = "main" ]; then
            echo -e " ${Green}▶${Reset} ${Yellow}退出${Reset}"
        else
            echo -e " ${Green}▶${Reset} ${Yellow}返回上级菜单${Reset}"
        fi
    else
        if [ "$current_menu" = "main" ]; then
            echo -e "   退出"
        else
            echo -e "   返回上级菜单"
        fi
    fi
    
    echo ""
    echo -e "${Cyan}======================================${Reset}"
    echo -e "使用 ${Green}↑/↓${Reset} 或 ${Green}j/k${Reset} 选择，${Green}Enter${Reset} 确认"
    
    # 如果是二级菜单且有选中项，显示脚本执行预览（使用缓存的数据）
    if [ "$current_menu" != "main" ] && [ $current_selection -lt ${#MENU_IDS[@]} ]; then
        local selected_id="${MENU_IDS[$current_selection]}"
        local script_path="${MENU_SCRIPTS[$selected_id]}"
        
        if [ -n "$script_path" ]; then
            # 直接使用缓存的数据，不再重复调用 get_script_url
            if [[ "$script_path" =~ ^https?:// ]]; then
                local script_url="$script_path"
            elif [[ "${VTK_DOWNLOAD_SOURCE}" == "oss" ]]; then
                local script_url="https://oss.naloong.de/VPSToolKit/${script_path}"
            else
                local script_url="https://raw.githubusercontent.com/betteryjs/VPSToolKit/master/${script_path}"
            fi
            
            echo ""
            echo -e "${Yellow}[执行预览]${Reset}"
            echo -e "${Cyan}脚本地址：${Reset}${script_url}"
            echo -e "${Cyan}执行命令：${Reset}bash <(curl -sL \"${script_url}\")"
        fi
    fi
}

# 处理选择
handle_selection() {
    local selected_index=$current_selection
    
    # 退出/返回选项
    if [ $selected_index -eq ${#MENU_IDS[@]} ]; then
        if [ "$current_menu" = "main" ]; then
            clear
            echo -e "${Green}感谢使用 VPSToolKit！${Reset}"
            exit 0
        else
            current_menu="main"
            current_selection=0
            load_main_menu
            return
        fi
    fi
    
    local selected_id="${MENU_IDS[$selected_index]}"
    
    # 检查是否有子菜单
    if [ "$current_menu" = "main" ]; then
        current_menu="$selected_id"
        current_selection=0
        load_submenu "$selected_id"
    else
        # 执行脚本
        local script_path="${MENU_SCRIPTS[$selected_id]}"
        
        if [ -z "$script_path" ]; then
            echo -e "${Red}[错误]${Reset} 脚本路径未配置"
            read -p "按回车继续..."
            return
        fi
        
        local script_url=$(get_script_url "$script_path")
        
        clear
        echo -e "${Cyan}======================================${Reset}"
        echo -e "${Green}[执行中]${Reset} ${MENU_TITLES[$selected_index]}"
        echo -e "${Cyan}======================================${Reset}"
        echo ""
        
        # 在线执行脚本
        bash <(curl -sL "${script_url}")
        
        echo ""
        echo -e "${Green}脚本执行完成${Reset}"
        read -p "按回车返回菜单..."
    fi
}

# 主循环
main_loop() {
    local key
    
    # 隐藏光标
    tput civis
    trap 'tput cnorm' EXIT
    
    # 加载主菜单
    load_main_menu
    
    while true; do
        render_menu
        
        # 读取按键
        read -rsn1 key
        
        case "$key" in
            A|k) # 上
                if [ $current_selection -gt 0 ]; then
                    ((current_selection--))
                fi
                ;;
            B|j) # 下
                if [ $current_selection -lt ${#MENU_IDS[@]} ]; then
                    ((current_selection++))
                fi
                ;;
            "") # Enter
                handle_selection
                ;;
            q|Q) # 退出
                clear
                echo -e "${Green}感谢使用 VPSToolKit！${Reset}"
                exit 0
                ;;
        esac
    done
}

# 检查 Root 权限
check_root() {
    if [[ $EUID != 0 ]]; then
        echo -e "${Red}[错误]${Reset} 需要 ROOT 权限运行"
        exit 1
    fi
}

# 主函数
main() {
    check_root
    main_loop
}

main
