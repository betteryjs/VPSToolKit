#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	Description: VPSToolKit 交互式菜单核心
#	Version: 2.0.0
#	Author: VPSToolKit Contributors
#=================================================

# 颜色定义
Green_font="\033[32m"
Red_font="\033[31m"
Yellow_font="\033[0;33m"
Blue_font="\033[0;34m"
Cyan_font="\033[0;36m"
Reset="\033[0m"

# 配置文件路径
CONFIG_DIR="/etc/vpstoolkit"
CONFIG_FILE="${CONFIG_DIR}/config.toml"
MODULES_DIR="${CONFIG_DIR}/modules.d"
SCRIPTS_DIR="/usr/local/vpstoolkit/scripts"
ENV_FILE="${CONFIG_DIR}/env"

# 加载环境变量配置
if [ -f "${ENV_FILE}" ]; then
    source "${ENV_FILE}"
fi

# 菜单项数组（全局声明）
declare -ga MENU_IDS
declare -ga MENU_TITLES
declare -gA MENU_ACTIONS
declare -gA MENU_CHILDREN

# 当前选择
current_selection=0
current_menu="main"
menu_stack=()

# 检查并下载脚本
# 获取脚本的远程 URL
get_script_url() {
    local script_path=$1
    
    # 如果已经是完整 URL，直接返回
    if [[ "$script_path" =~ ^https?:// ]]; then
        echo "$script_path"
        return
    fi
    
    # 如果是相对路径（如 scripts/proxy/anytls.sh），根据环境变量构建 URL
    if [[ "$script_path" =~ ^scripts/ ]]; then
        local download_source="${VTK_DOWNLOAD_SOURCE:-oss}"
        
        if [[ "${download_source}" == "oss" ]]; then
            echo "https://oss.naloong.de/VPSToolKit/${script_path}"
        else
            echo "https://raw.githubusercontent.com/betteryjs/VPSToolKit/master/${script_path}"
        fi
        return
    fi
    
    # 其他情况（本地路径等），直接返回
    echo "$script_path"
}

# 清屏并隐藏光标
hide_cursor() {
    tput civis
}

# 显示光标
show_cursor() {
    tput cnorm
}

# 退出清理
cleanup() {
    show_cursor
    tput sgr0
    echo ""
}

trap cleanup EXIT

# 移动光标到指定位置
move_cursor() {
    local row=$1
    local col=$2
    tput cup $row $col
}

# 清空从当前行到屏幕底部
clear_below() {
    tput ed
}

# 显示标题
show_header() {
    clear
    # 不显示大的 ASCII banner，保持简洁
}

# 显示菜单标题
show_menu_title() {
    local title=$1
    echo -e "${Cyan_font}━━━━━━━━━━ $title ━━━━━━━━━━${Reset}"
    echo ""
}

# 显示菜单项
show_menu_item() {
    local index=$1
    local title=$2
    local is_selected=$3
    local has_children=$4
    
    if [ "$is_selected" = "1" ]; then
        if [ "$has_children" = "1" ]; then
            echo -e " ${Green_font}>${Reset} ${Yellow_font}[+]${Reset} ${Green_font}$title${Reset}"
        else
            echo -e " ${Green_font}>${Reset} ${Yellow_font}[+]${Reset} $title"
        fi
    else
        if [ "$has_children" = "1" ]; then
            echo -e "   ${Yellow_font}[+]${Reset} $title"
        else
            echo -e "   ${Yellow_font}[+]${Reset} $title"
        fi
    fi
}

# 显示退出选项
show_exit_item() {
    local is_selected=$1
    if [ "$is_selected" = "1" ]; then
        echo -e " ${Green_font}>${Reset} ${Red_font}[x]${Reset} ${Green_font}退出${Reset}"
    else
        echo -e "   ${Red_font}[x]${Reset} 退出"
    fi
}

# 显示帮助信息
show_help() {
    echo ""
    echo -e "${Cyan_font}━━━━━━━━━━ 提醒 ━━━━━━━━━━${Reset}"
    
    # 根据当前选择显示不同的提示
    if [ $current_selection -lt ${#MENU_IDS[@]} ]; then
        local selected_id="${MENU_IDS[$current_selection]}"
        local selected_title="${MENU_TITLES[$current_selection]}"
        
        # 检查是否有子菜单
        if [ "${MENU_CHILDREN[$selected_id]}" = "1" ]; then
            echo "回车进入${selected_title}菜单"
        else
            # 显示实际要执行的命令
            local action="${MENU_ACTIONS[$selected_id]}"
            if [ -n "$action" ]; then
                local script_url=$(get_script_url "$action")
                echo "回车执行命令令："
                echo "  bash <(curl -sL ${script_url})"
            else
                echo "回车执行${selected_title}"
            fi
        fi
    else
        if [ ${#menu_stack[@]} -gt 0 ]; then
            echo "回车返回上级菜单"
        else
            echo "回车退出程序"
        fi
    fi
    echo ""
    echo "使用↑/↓或者j/k来移动光标"
    echo "Powered by betteryjs"
}

# 解析 TOML 数组（简单实现）
parse_toml_array() {
    local file=$1
    local key=$2
    local in_array=0
    local result=()
    
    while IFS= read -r line; do
        # 检测数组开始
        if [[ "$line" =~ ^[[:space:]]*"$key"[[:space:]]*=[[:space:]]*\[ ]]; then
            in_array=1
            # 检查是否在同一行结束
            if [[ "$line" =~ \] ]]; then
                # 单行数组
                local content="${line#*[}"
                content="${content%]*}"
                content="${content//\"/}"
                content="${content//,/ }"
                for item in $content; do
                    item=$(echo "$item" | xargs)
                    [ -n "$item" ] && result+=("$item")
                done
                break
            fi
            continue
        fi
        
        # 在数组中读取元素
        if [ $in_array -eq 1 ]; then
            # 检测数组结束
            if [[ "$line" =~ \] ]]; then
                # 处理最后一行（可能包含元素）
                local content="${line%]*}"
                content="${content//\"/}"
                content="${content//,/}"
                content=$(echo "$content" | xargs)
                [ -n "$content" ] && result+=("$content")
                break
            fi
            # 提取数组元素
            local item=$(echo "$line" | sed 's/^[[:space:]]*"\(.*\)"[[:space:]]*,\?[[:space:]]*$/\1/')
            [ -n "$item" ] && result+=("$item")
        fi
    done < "$file"
    
    # 输出结果
    for item in "${result[@]}"; do
        echo "$item"
    done
}

# 解析 TOML 键值对（scripts 部分）
parse_toml_key_value() {
    local file=$1
    local key=$2
    local in_section=0
    
    while IFS= read -r line; do
        # 检测 [scripts] 部分
        if [[ "$line" =~ ^\[scripts\] ]]; then
            in_section=1
            continue
        fi
        
        # 遇到新的 section 退出
        if [[ "$line" =~ ^\[\[.*\]\] ]] && [ $in_section -eq 1 ]; then
            break
        fi
        
        # 在 scripts 部分查找键值对
        if [ $in_section -eq 1 ]; then
            if [[ "$line" =~ ^[[:space:]]*"$key"[[:space:]]*=[[:space:]]*"(.*)"[[:space:]]*$ ]]; then
                echo "${BASH_REMATCH[1]}"
                return
            fi
            if [[ "$line" =~ ^[[:space:]]*$key[[:space:]]*=[[:space:]]*"(.*)"[[:space:]]*$ ]]; then
                echo "${BASH_REMATCH[1]}"
                return
            fi
        fi
    done < "$file"
}

# 加载主菜单配置（从 menu.toml 加载）
load_main_menu() {
    MENU_IDS=()
    MENU_TITLES=()
    MENU_CHILDREN=()
    MENU_ACTIONS=()
    
    local menu_file="${MODULES_DIR}/menu.toml"
    
    if [ ! -f "$menu_file" ]; then
        echo "Error: Main menu file not found: $menu_file" >&2
        return 1
    fi
    
    # 读取 sub_menus 和 titles 数组
    local menu_ids=($(parse_toml_array "$menu_file" "sub_menus"))
    local menu_titles=($(parse_toml_array "$menu_file" "titles"))
    
    # 填充数组
    for i in "${!menu_ids[@]}"; do
        MENU_IDS+=("${menu_ids[$i]}")
        MENU_TITLES+=("${menu_titles[$i]}")
        MENU_CHILDREN["${menu_ids[$i]}"]="1"
    done
}

# 加载二级菜单（从 proxy.toml, system.toml, tools.toml 等文件加载）
load_submenu() {
    local menu_id=$1
    
    MENU_IDS=()
    MENU_TITLES=()
    MENU_CHILDREN=()
    MENU_ACTIONS=()
    
    # 查找包含该菜单的 TOML 文件（排除 menu.toml）
    local toml_file=""
    for file in "${MODULES_DIR}"/*.toml; do
        [ -f "$file" ] || continue
        
        # 跳过主菜单文件
        local basename=$(basename "$file")
        [[ "$basename" == "menu.toml" ]] && continue
        
        # 检查是否包含目标菜单
        if grep -q "^[[:space:]]*id[[:space:]]*=[[:space:]]*\"$menu_id\"" "$file"; then
            toml_file="$file"
            break
        fi
    done
    
    if [ -z "$toml_file" ]; then
        echo "Error: Menu '$menu_id' not found in any TOML file" >&2
        return 1
    fi
    
    # 读取 sub_menus 数组
    local sub_ids=($(parse_toml_array "$toml_file" "sub_menus"))
    
    # 为每个子菜单项读取信息
    for item_id in "${sub_ids[@]}"; do
        MENU_IDS+=("$item_id")
        
        # 读取 title
        local title=$(grep -A 10 "^[[:space:]]*id[[:space:]]*=[[:space:]]*\"$item_id\"" "$toml_file" | \
                     grep -m 1 "^[[:space:]]*title[[:space:]]*=" | \
                     sed 's/^[[:space:]]*title[[:space:]]*=[[:space:]]*"\(.*\)"[[:space:]]*$/\1/')
        MENU_TITLES+=("$title")
        
        # 读取 script key
        local script_key=$(grep -A 10 "^[[:space:]]*id[[:space:]]*=[[:space:]]*\"$item_id\"" "$toml_file" | \
                          grep -m 1 "^[[:space:]]*script[[:space:]]*=" | \
                          sed 's/^[[:space:]]*script[[:space:]]*=[[:space:]]*"\(.*\)"[[:space:]]*$/\1/')
        
        # 通过 script key 查找实际路径
        if [ -n "$script_key" ]; then
            local script_path=$(parse_toml_key_value "$toml_file" "$script_key")
            MENU_ACTIONS["$item_id"]="$script_path"
        fi
    done
    
    return 0
}

# 加载菜单（统一入口）
load_menu() {
    local menu_id=$1
    
    if [ "$menu_id" = "main" ]; then
        load_main_menu
    else
        load_submenu "$menu_id"
    fi
}

# 获取菜单标题
get_menu_title() {
    local menu_id=$1
    
    # 主菜单
    if [ "$menu_id" = "main" ]; then
        echo "主菜单"
        return
    fi
    
    # 从 TOML 文件中查找标题（排除 menu.toml）
    for toml_file in "${MODULES_DIR}"/*.toml; do
        [ -f "$toml_file" ] || continue
        
        local basename=$(basename "$toml_file")
        [[ "$basename" == "menu.toml" ]] && continue
        
        local in_menu=0
        local current_id=""
        
        while IFS= read -r line; do
            if [[ "$line" =~ ^\[\[menus\]\] ]]; then
                in_menu=1
                current_id=""
                continue
            fi
            
            if [ $in_menu -eq 1 ]; then
                if [[ "$line" =~ ^[[:space:]]*id[[:space:]]*=[[:space:]]*\"(.*)\" ]]; then
                    current_id="${BASH_REMATCH[1]}"
                fi
                
                if [ "$current_id" = "$menu_id" ]; then
                    if [[ "$line" =~ ^[[:space:]]*title[[:space:]]*=[[:space:]]*\"(.*)\" ]]; then
                        echo "${BASH_REMATCH[1]}"
                        return
                    fi
                fi
            fi
        done < "$toml_file"
    done
    
    # 默认返回 ID
    echo "$menu_id"
}

# 渲染菜单
render_menu() {
    show_header
    
    local menu_title=$(get_menu_title "$current_menu")
    show_menu_title "$menu_title"
    
    local i=0
    for menu_id in "${MENU_IDS[@]}"; do
        local is_selected=0
        if [ $i -eq $current_selection ]; then
            is_selected=1
        fi
        local has_children=${MENU_CHILDREN[$menu_id]:-0}
        show_menu_item $i "${MENU_TITLES[$i]}" $is_selected $has_children
        ((i++))
    done
    
    # 显示退出选项
    if [ $current_selection -eq ${#MENU_IDS[@]} ]; then
        show_exit_item 1
    else
        show_exit_item 0
    fi
    
    show_help
}

# 处理选择
handle_selection() {
    local selected_id="${MENU_IDS[$current_selection]}"
    
    # 检查是否有子菜单
    if [ "${MENU_CHILDREN[$selected_id]}" = "1" ]; then
        menu_stack+=("$current_menu")
        current_menu="$selected_id"
        current_selection=0
        load_menu "$current_menu"
        return
    fi
    
    # 执行脚本
    local action="${MENU_ACTIONS[$selected_id]}"
    if [ -n "$action" ]; then
        show_cursor
        clear
        echo -e "${Green_font}正在执行: ${MENU_TITLES[$current_selection]}${Reset}"
        echo ""
        
        # 获取脚本 URL
        local script_url=$(get_script_url "$action")
        echo -e "${Cyan_font}[信息]${Reset} 脚本地址：${script_url}"
        echo -e "${Cyan_font}[信息]${Reset} 正在在线执行脚本（不保存到本地）..."
        echo ""
        
        # 直接通过 curl 在线执行，不保存到本地
        bash <(curl -sL "$script_url")
        local exit_code=$?
        
        if [ $exit_code -ne 0 ]; then
            echo ""
            echo -e "${Red_font}[错误]${Reset} 脚本执行失败或网络错误！"
        fi
        
        # 脚本执行完毕，提示后返回当前菜单
        echo ""
        echo -e "${Yellow_font}按回车键返回菜单...${Reset}"
        read
        hide_cursor
    else
        # 没有找到脚本
        show_cursor
        echo ""
        echo -e "${Red_font}[错误]${Reset} 未找到该菜单项的脚本配置！"
        echo "菜单ID: $selected_id"
        echo ""
        read -p "按回车键返回..."
        hide_cursor
    fi
}

# 返回上级菜单
go_back() {
    if [ ${#menu_stack[@]} -gt 0 ]; then
        current_menu="${menu_stack[-1]}"
        unset 'menu_stack[-1]'
        current_selection=0
        load_menu "$current_menu"
    fi
}

# 主循环
main_loop() {
    hide_cursor
    load_menu "$current_menu"
    
    while true; do
        render_menu
        
        # 读取单个字符
        read -rsn1 key
        
        # 处理方向键
        if [ "$key" = $'\x1b' ]; then
            read -rsn2 key
            case "$key" in
                '[A'|'[D') # 上箭头或左箭头
                    if [ $current_selection -gt 0 ]; then
                        ((current_selection--))
                    fi
                    ;;
                '[B'|'[C') # 下箭头或右箭头
                    if [ $current_selection -lt ${#MENU_IDS[@]} ]; then
                        ((current_selection++))
                    fi
                    ;;
            esac
        else
            case "$key" in
                'k'|'K') # k 键向上
                    if [ $current_selection -gt 0 ]; then
                        ((current_selection--))
                    fi
                    ;;
                'j'|'J') # j 键向下
                    if [ $current_selection -lt ${#MENU_IDS[@]} ]; then
                        ((current_selection++))
                    fi
                    ;;
                '') # 回车键
                    if [ $current_selection -eq ${#MENU_IDS[@]} ]; then
                        # 选择退出
                        if [ ${#menu_stack[@]} -gt 0 ]; then
                            go_back
                        else
                            break
                        fi
                    else
                        handle_selection
                    fi
                    ;;
                'q'|'Q') # q 键退出
                    if [ ${#menu_stack[@]} -gt 0 ]; then
                        go_back
                    else
                        break
                    fi
                    ;;
            esac
        fi
    done
}

# 检查 root 权限
check_root() {
    if [[ $EUID != 0 ]]; then
        echo -e "${Red_font}[错误]${Reset} 需要 root 权限运行此脚本"
        exit 1
    fi
}

# 主函数
main() {
    check_root
    main_loop
    cleanup
    echo -e "${Green_font}感谢使用 VPSToolKit！${Reset}"
}

main
