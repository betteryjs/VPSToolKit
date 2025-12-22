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
SCRIPTS_DIR="/usr/local/vpstoolkit/scripts"

# 菜单项数组
declare -a MENU_IDS
declare -a MENU_TITLES
declare -A MENU_ACTIONS
declare -A MENU_CHILDREN

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

# 加载主菜单配置（模拟从 TOML 加载）
load_main_menu() {
    MENU_IDS=()
    MENU_TITLES=()
    declare -gA MENU_CHILDREN
    declare -gA MENU_ACTIONS
    
    MENU_IDS+=("proxy_services")
    MENU_TITLES+=("代理服务管理")
    MENU_CHILDREN["proxy_services"]="1"
    
    MENU_IDS+=("system_tools")
    MENU_TITLES+=("系统工具")
    MENU_CHILDREN["system_tools"]="1"
    
    MENU_IDS+=("utility_tools")
    MENU_TITLES+=("实用工具")
    MENU_CHILDREN["utility_tools"]="1"
}

# 加载代理服务菜单
load_proxy_menu() {
    MENU_IDS=()
    MENU_TITLES=()
    declare -gA MENU_ACTIONS
    
    local script_base="/usr/local/vpstoolkit/scripts/proxy"
    
    MENU_IDS+=("proxy_anytls")
    MENU_TITLES+=("AnyTLS 管理")
    MENU_ACTIONS["proxy_anytls"]="${script_base}/anytls.sh"
    
    MENU_IDS+=("proxy_ss")
    MENU_TITLES+=("Shadowsocks 管理")
    MENU_ACTIONS["proxy_ss"]="${script_base}/ss.sh"
    
    MENU_IDS+=("proxy_trojan")
    MENU_TITLES+=("Trojan-Go 管理")
    MENU_ACTIONS["proxy_trojan"]="${script_base}/trojan.sh"
    
    MENU_IDS+=("proxy_snell4")
    MENU_TITLES+=("Snell v4 管理")
    MENU_ACTIONS["proxy_snell4"]="${script_base}/snell4.sh"
    
    MENU_IDS+=("proxy_snell5")
    MENU_TITLES+=("Snell v5 管理")
    MENU_ACTIONS["proxy_snell5"]="${script_base}/snell5.sh"
}

# 加载系统工具菜单
load_system_menu() {
    MENU_IDS=()
    MENU_TITLES=()
    declare -gA MENU_ACTIONS
    
    local script_base="/usr/local/vpstoolkit/scripts/system"
    
    MENU_IDS+=("system_bbr")
    MENU_TITLES+=("BBR 加速管理")
    MENU_ACTIONS["system_bbr"]="${script_base}/bbr.sh"
    
    MENU_IDS+=("system_dd")
    MENU_TITLES+=("DD 重装系统")
    MENU_ACTIONS["system_dd"]="${script_base}/dd.sh"
}

# 加载实用工具菜单
load_utility_menu() {
    MENU_IDS=()
    MENU_TITLES=()
    declare -gA MENU_ACTIONS
    
    local script_base="/usr/local/vpstoolkit/scripts/tools"
    
    MENU_IDS+=("tools_speedtest")
    MENU_TITLES+=("Speedtest 网络测速")
    MENU_ACTIONS["tools_speedtest"]="${script_base}/speedtest.sh"
}

# 加载菜单
load_menu() {
    local menu_id=$1
    case "$menu_id" in
        "main")
            load_main_menu
            ;;
        "proxy_services")
            load_proxy_menu
            ;;
        "system_tools")
            load_system_menu
            ;;
        "utility_tools")
            load_utility_menu
            ;;
    esac
}

# 渲染菜单
render_menu() {
    show_header
    
    case "$current_menu" in
        "main")
            show_menu_title "主菜单"
            ;;
        "proxy_services")
            show_menu_title "代理服务管理"
            ;;
        "system_tools")
            show_menu_title "系统工具"
            ;;
        "utility_tools")
            show_menu_title "实用工具"
            ;;
    esac
    
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
