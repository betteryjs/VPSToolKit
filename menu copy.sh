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

# 解析 TOML 数组
parse_toml_array() {
    local file=$1
    local key=$2
    
    awk -v key="$key" '
    BEGIN { in_array=0 }
    $0 ~ "^[[:space:]]*" key "[[:space:]]*=[[:space:]]*\\[" {
        in_array=1
        if ($0 ~ /\]/) {
            match($0, /\[([^\]]*)\]/, arr)
            content = arr[1]
            gsub(/"/, "", content)
            gsub(/,/, "\n", content)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", content)
            print content
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
        match($0, /"([^"]*)"/, arr)
        print arr[1]
        exit
    }
    ' "$file"
}

# 解析菜单项详细信息
parse_menu_item() {
    local file=$1
    local item_id=$2
    local field=$3
    
    awk -v id="$item_id" -v field="$field" '
    /^\[\[menu\]\]/ { in_menu=1; found=0; next }
    in_menu && /^id = / {
        if ($0 ~ id) { found=1 }
        else { found=0; in_menu=0 }
    }
    found && $0 ~ "^" field " = " {
        match($0, /"([^"]*)"/, arr)
        print arr[1]
        exit
    }
    ' "$file"
}

# 加载主菜单
load_main_menu() {
    MENU_IDS=()
    MENU_TITLES=()
    MENU_SCRIPTS=()
    
    local menu_file="${MODULES_DIR}/menu.toml"
    
    if [ ! -f "$menu_file" ]; then
        echo -e "${Red}[错误]${Reset} 主菜单配置文件不存在"
        exit 1
    fi
    
    # 读取子菜单 ID
    local ids=$(parse_toml_array "$menu_file" "sub_menus")
    local titles=$(parse_toml_array "$menu_file" "titles")
    
    # 转为数组
    while IFS= read -r line; do
        [ -n "$line" ] && MENU_IDS+=("$line")
    done <<< "$ids"
    
    while IFS= read -r line; do
        [ -n "$line" ] && MENU_TITLES+=("$line")
    done <<< "$titles"
}

# 加载子菜单
load_submenu() {
    local menu_id=$1
    
    MENU_IDS=()
    MENU_TITLES=()
    MENU_SCRIPTS=()
    
    # 查找对应的配置文件
    local menu_file=""
    for file in "${MODULES_DIR}"/*.toml; do
        [ -f "$file" ] || continue
        [ "$(basename "$file")" = "menu.toml" ] && continue
        
        if grep -q "^id = \"$menu_id\"" "$file"; then
            menu_file="$file"
            break
        fi
    done
    
    if [ -z "$menu_file" ]; then
        echo -e "${Red}[错误]${Reset} 未找到菜单配置"
        return 1
    fi
    
    # 读取子菜单项
    local item_ids=$(parse_toml_array "$menu_file" "sub_menus")
    
    while IFS= read -r item_id; do
        [ -z "$item_id" ] && continue
        
        MENU_IDS+=("$item_id")
        
        # 读取标题
        local title=$(parse_menu_item "$menu_file" "$item_id" "title")
        MENU_TITLES+=("$title")
        
        # 读取脚本 key
        local script_key=$(parse_menu_item "$menu_file" "$item_id" "script")
        
        # 通过 key 获取脚本路径
        if [ -n "$script_key" ]; then
            local script_path=$(parse_toml_value "$menu_file" "scripts" "$script_key")
            MENU_SCRIPTS["$item_id"]="$script_path"
        fi
    done <<< "$item_ids"
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
        local menu_title=""
        for i in "${!MENU_IDS[@]}"; do
            if [ "${MENU_IDS[$i]}" = "$current_menu" ]; then
                menu_title="${MENU_TITLES[$i]}"
                break
            fi
        done
        echo -e "${Cyan}======================================${Reset}"
        echo -e "${Cyan}       $menu_title${Reset}"
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
        echo -e "${Green}[执行]${Reset} ${MENU_TITLES[$selected_index]}"
        echo -e "${Cyan}======================================${Reset}"
        echo -e "${Yellow}脚本地址：${Reset}${script_url}"
        echo ""
        echo -e "${Yellow}执行命令：${Reset}bash <(curl -sL \"${script_url}\")"
        echo ""
        sleep 1
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
