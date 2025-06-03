#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 默认值
DEFAULT_INSTALL_PATH="/usr/local/nginx"
DEFAULT_LANGUAGE="cn"
DEFAULT_HTTPS="yes"
DEFAULT_HTTP_PORT=80
DEFAULT_HTTPS_PORT=443

# 检查已安装的Nginx
check_existing_nginx() {
    NGINX_INSTALLED=false
    NGINX_RUNNING=false
    EXISTING_NGINX_PATHS=()
    EXISTING_NGINX_PIDS=()
    
    # 检查常见安装路径
    local common_paths=("/usr/local/nginx" "/usr/share/nginx" "/etc/nginx" "/opt/nginx" "/usr/local/nginx_*")
    
    # 检查是否有nginx进程运行
    if pgrep -x "nginx" > /dev/null; then
        NGINX_RUNNING=true
        EXISTING_NGINX_PIDS=($(pgrep -x "nginx"))
        
        # 尝试获取所有nginx安装路径
        for pid in "${EXISTING_NGINX_PIDS[@]}"; do
            local nginx_bin=$(readlink -f /proc/$pid/exe 2>/dev/null)
            if [ -n "$nginx_bin" ]; then
                local nginx_path=$(dirname $(dirname $nginx_bin))
                if [[ ! " ${EXISTING_NGINX_PATHS[@]} " =~ " ${nginx_path} " ]]; then
                    EXISTING_NGINX_PATHS+=("$nginx_path")
                fi
            fi
        done
    fi
    
    # 如果通过进程未找到所有路径，检查常见路径
    for path_pattern in "${common_paths[@]}"; do
        for path in $(find / -path "$path_pattern" -type d 2>/dev/null); do
            if [ -f "$path/sbin/nginx" ] || [ -f "$path/bin/nginx" ]; then
                NGINX_INSTALLED=true
                if [[ ! " ${EXISTING_NGINX_PATHS[@]} " =~ " ${path} " ]]; then
                    EXISTING_NGINX_PATHS+=("$path")
                fi
            fi
        done
    done
    
    # 检查命令是否在PATH中
    if command -v nginx > /dev/null; then
        NGINX_INSTALLED=true
        local nginx_bin_path=$(which nginx)
        local nginx_path=$(dirname $(dirname $nginx_bin_path))
        if [[ ! " ${EXISTING_NGINX_PATHS[@]} " =~ " ${nginx_path} " ]]; then
            EXISTING_NGINX_PATHS+=("$nginx_path")
        fi
    fi
    
    # 如果已安装，提供选项
    if $NGINX_INSTALLED; then
        if [ "$LANGUAGE" == "cn" ]; then
            echo -e "${YELLOW}检测到系统中已安装 ${#EXISTING_NGINX_PATHS[@]} 个Nginx${NC}"
            
            # 显示所有安装的Nginx
            for ((i=0; i<${#EXISTING_NGINX_PATHS[@]}; i++)); do
                echo -e "[$((i+1))] 安装路径: ${EXISTING_NGINX_PATHS[$i]}"
                
                # 检查是否正在运行
                local is_running=false
                for pid in "${EXISTING_NGINX_PIDS[@]}"; do
                    local nginx_bin=$(readlink -f /proc/$pid/exe 2>/dev/null)
                    if [ -n "$nginx_bin" ] && [[ "$nginx_bin" == "${EXISTING_NGINX_PATHS[$i]}/sbin/nginx" ]]; then
                        is_running=true
                        echo -e "    状态: 正在运行, PID: $pid"
                        break
                    fi
                done
                
                if ! $is_running; then
                    echo -e "    状态: 已安装但未运行"
                fi
                
                # 尝试获取端口信息
                if [ -f "${EXISTING_NGINX_PATHS[$i]}/conf/nginx.conf" ]; then
                    local http_port=$(grep -oP "listen\s+\K[0-9]+" "${EXISTING_NGINX_PATHS[$i]}/conf/nginx.conf" | head -1)
                    local https_port=$(grep -oP "listen\s+\K[0-9]+(?=\s+ssl)" "${EXISTING_NGINX_PATHS[$i]}/conf/nginx.conf" | head -1)
                    
                    if [ -n "$http_port" ]; then
                        echo -e "    HTTP端口: $http_port"
                    fi
                    
                    if [ -n "$https_port" ]; then
                        echo -e "    HTTPS端口: $https_port"
                    fi
                fi
            done
            
            echo -e "请选择操作:"
            echo -e "1. 卸载已有Nginx并重新安装"
            echo -e "2. 保留已有Nginx，更改新安装的端口和路径"
            echo -e "3. 取消安装"
            read -p "$(echo -e ${YELLOW}"请输入选项 [1/2/3]: "${NC})" nginx_action
        else
            echo -e "${YELLOW}Detected ${#EXISTING_NGINX_PATHS[@]} Nginx installations on the system${NC}"
            
            # 显示所有安装的Nginx
            for ((i=0; i<${#EXISTING_NGINX_PATHS[@]}; i++)); do
                echo -e "[$((i+1))] Installation path: ${EXISTING_NGINX_PATHS[$i]}"
                
                # 检查是否正在运行
                local is_running=false
                for pid in "${EXISTING_NGINX_PIDS[@]}"; do
                    local nginx_bin=$(readlink -f /proc/$pid/exe 2>/dev/null)
                    if [ -n "$nginx_bin" ] && [[ "$nginx_bin" == "${EXISTING_NGINX_PATHS[$i]}/sbin/nginx" ]]; then
                        is_running=true
                        echo -e "    Status: Running, PID: $pid"
                        break
                    fi
                done
                
                if ! $is_running; then
                    echo -e "    Status: Installed but not running"
                fi
                
                # 尝试获取端口信息
                if [ -f "${EXISTING_NGINX_PATHS[$i]}/conf/nginx.conf" ]; then
                    local http_port=$(grep -oP "listen\s+\K[0-9]+" "${EXISTING_NGINX_PATHS[$i]}/conf/nginx.conf" | head -1)
                    local https_port=$(grep -oP "listen\s+\K[0-9]+(?=\s+ssl)" "${EXISTING_NGINX_PATHS[$i]}/conf/nginx.conf" | head -1)
                    
                    if [ -n "$http_port" ]; then
                        echo -e "    HTTP port: $http_port"
                    fi
                    
                    if [ -n "$https_port" ]; then
                        echo -e "    HTTPS port: $https_port"
                    fi
                fi
            done
            
            echo -e "Please choose an action:"
            echo -e "1. Uninstall existing Nginx and reinstall"
            echo -e "2. Keep existing Nginx, change port and path for new installation"
            echo -e "3. Cancel installation"
            read -p "$(echo -e ${YELLOW}"Please enter option [1/2/3]: "${NC})" nginx_action
        fi
        
        case $nginx_action in
            1)
                # 如果有多个Nginx安装，询问要卸载哪个
                if [ ${#EXISTING_NGINX_PATHS[@]} -gt 1 ]; then
                    if [ "$LANGUAGE" == "cn" ]; then
                        echo -e "检测到多个Nginx安装，请选择要卸载的Nginx:"
                        echo -e "0. 卸载所有"
                        for ((i=0; i<${#EXISTING_NGINX_PATHS[@]}; i++)); do
                            echo -e "$((i+1)). ${EXISTING_NGINX_PATHS[$i]}"
                        done
                        read -p "$(echo -e ${YELLOW}"请输入选项 [0-${#EXISTING_NGINX_PATHS[@]}]: "${NC})" uninstall_choice
                    else
                        echo -e "Multiple Nginx installations detected, please choose which to uninstall:"
                        echo -e "0. Uninstall all"
                        for ((i=0; i<${#EXISTING_NGINX_PATHS[@]}; i++)); do
                            echo -e "$((i+1)). ${EXISTING_NGINX_PATHS[$i]}"
                        done
                        read -p "$(echo -e ${YELLOW}"Please enter option [0-${#EXISTING_NGINX_PATHS[@]}]: "${NC})" uninstall_choice
                    fi
                    
                    if [ "$uninstall_choice" == "0" ]; then
                        # 卸载所有
                        for path in "${EXISTING_NGINX_PATHS[@]}"; do
                            EXISTING_NGINX_PATH=$path
                            uninstall_nginx
                        done
                    elif [[ "$uninstall_choice" =~ ^[0-9]+$ ]] && [ "$uninstall_choice" -le "${#EXISTING_NGINX_PATHS[@]}" ]; then
                        # 卸载选定的
                        EXISTING_NGINX_PATH=${EXISTING_NGINX_PATHS[$((uninstall_choice-1))]}
                        uninstall_nginx
                    else
                        if [ "$LANGUAGE" == "cn" ]; then
                            echo -e "${RED}无效选项，安装已取消${NC}"
                        else
                            echo -e "${RED}Invalid option, installation cancelled${NC}"
                        fi
                        exit 1
                    fi
                else
                    EXISTING_NGINX_PATH=${EXISTING_NGINX_PATHS[0]}
                    uninstall_nginx
                fi
                ;;
            2)
                CHANGE_PORT=true
                # 如果有多个Nginx安装，记录所有端口
                EXISTING_HTTP_PORTS=()
                EXISTING_HTTPS_PORTS=()
                
                for path in "${EXISTING_NGINX_PATHS[@]}"; do
                    if [ -f "$path/conf/nginx.conf" ]; then
                        local http_port=$(grep -oP "listen\s+\K[0-9]+" "$path/conf/nginx.conf" | head -1)
                        local https_port=$(grep -oP "listen\s+\K[0-9]+(?=\s+ssl)" "$path/conf/nginx.conf" | head -1)
                        
                        if [ -n "$http_port" ]; then
                            EXISTING_HTTP_PORTS+=($http_port)
                        fi
                        
                        if [ -n "$https_port" ]; then
                            EXISTING_HTTPS_PORTS+=($https_port)
                        fi
                    fi
                done
                ;;
            3)
                if [ "$LANGUAGE" == "cn" ]; then
                    echo -e "${CYAN}安装已取消${NC}"
                else
                    echo -e "${CYAN}Installation cancelled${NC}"
                fi
                exit 0
                ;;
            *)
                if [ "$LANGUAGE" == "cn" ]; then
                    echo -e "${CYAN}安装已取消${NC}"
                else
                    echo -e "${CYAN}Installation cancelled${NC}"
                fi
                exit 0
                ;;
        esac
    fi
}

# 卸载已有Nginx
uninstall_nginx() {
    if [ "$LANGUAGE" == "cn" ]; then
        echo -e "${CYAN}正在卸载已有Nginx...${NC}"
    else
        echo -e "${CYAN}Uninstalling existing Nginx...${NC}"
    fi
    
    # 停止Nginx服务
    if $NGINX_RUNNING; then
        if [ "$HAS_SYSTEMD" = true ] && systemctl list-unit-files | grep -q nginx; then
            systemctl stop nginx
            systemctl disable nginx
        else
            # 尝试使用nginx二进制文件停止
            if [ -f "${EXISTING_NGINX_PATH}/sbin/nginx" ]; then
                ${EXISTING_NGINX_PATH}/sbin/nginx -s stop
            elif command -v nginx > /dev/null; then
                nginx -s stop
            else
                # 直接杀死进程
                kill $EXISTING_NGINX_PID
            fi
        fi
    fi
    
    # 移除文件
    if [ -d "$EXISTING_NGINX_PATH" ]; then
        rm -rf $EXISTING_NGINX_PATH
    fi
    
    # 移除系统服务
    if [ "$HAS_SYSTEMD" = true ]; then
        if [ -f "/etc/systemd/system/nginx.service" ]; then
            rm -f /etc/systemd/system/nginx.service
            systemctl daemon-reload
        fi
    fi
    
    # 移除启动脚本
    if [ -f "/usr/local/bin/nginx-ctl" ]; then
        rm -f /usr/local/bin/nginx-ctl
    fi
    
    # 检查是否成功卸载
    if [ -d "$EXISTING_NGINX_PATH" ] || command -v nginx > /dev/null; then
        if [ "$LANGUAGE" == "cn" ]; then
            echo -e "${RED}卸载失败，请手动卸载后重试${NC}"
        else
            echo -e "${RED}Uninstallation failed, please manually uninstall and try again${NC}"
        fi
        exit 1
    else
        if [ "$LANGUAGE" == "cn" ]; then
            echo -e "${GREEN}已成功卸载Nginx${NC}"
        else
            echo -e "${GREEN}Nginx successfully uninstalled${NC}"
        fi
    fi
}

# 查找可用端口
find_available_port() {
    local start_port=$1
    local end_port=$2
    local port=$start_port
    
    while [ $port -le $end_port ]; do
        if ! $(check_port_used $port); then
            echo $port
            return 0
        fi
        port=$((port + 1))
    done
    
    # 如果没有找到可用端口，返回0
    echo 0
    return 1
}

# 配置新安装的端口
configure_ports() {
    if [ "$CHANGE_PORT" = true ]; then
        if [ "$LANGUAGE" == "cn" ]; then
            echo -e "${BLUE}=== 配置端口 ===${NC}"
            echo -e "${YELLOW}为避免与现有Nginx冲突，请配置不同的端口${NC}"
            echo -e "1. 配置新端口"
            echo -e "2. 使用随机可用端口"
            echo -e "3. 取消安装"
            read -p "$(echo -e ${YELLOW}"请选择 [1/2/3]: "${NC})" port_choice
            
            case $port_choice in
                1)
                    # 显示现有Nginx使用的端口
                    if [ ${#EXISTING_HTTP_PORTS[@]} -gt 0 ]; then
                        echo -e "${YELLOW}现有Nginx正在使用以下HTTP端口: ${EXISTING_HTTP_PORTS[*]}${NC}"
                    fi
                    
                    if [ ${#EXISTING_HTTPS_PORTS[@]} -gt 0 ]; then
                        echo -e "${YELLOW}现有Nginx正在使用以下HTTPS端口: ${EXISTING_HTTPS_PORTS[*]}${NC}"
                    fi
                    
                    read -p "$(echo -e ${YELLOW}"请输入HTTP端口 (默认: 8080): "${NC})" http_port
                    if [ "$CONFIGURE_HTTPS" == "yes" ]; then
                        read -p "$(echo -e ${YELLOW}"请输入HTTPS端口 (默认: 8443): "${NC})" https_port
                    fi
                    ;;
                2)
                    # 查找随机可用端口
                    echo -e "${YELLOW}正在查找可用端口...${NC}"
                    http_port=$(find_available_port 8000 9000)
                    if [ "$http_port" == "0" ]; then
                        echo -e "${RED}错误: 无法找到可用的HTTP端口${NC}"
                        exit 1
                    fi
                    
                    if [ "$CONFIGURE_HTTPS" == "yes" ]; then
                        https_port=$(find_available_port 8443 9443)
                        if [ "$https_port" == "0" ]; then
                            echo -e "${RED}错误: 无法找到可用的HTTPS端口${NC}"
                            exit 1
                        fi
                    fi
                    
                    echo -e "${GREEN}已找到可用HTTP端口: ${http_port}${NC}"
                    if [ "$CONFIGURE_HTTPS" == "yes" ]; then
                        echo -e "${GREEN}已找到可用HTTPS端口: ${https_port}${NC}"
                    fi
                    ;;
                3)
                    echo -e "${CYAN}安装已取消${NC}"
                    exit 0
                    ;;
                *)
                    echo -e "${CYAN}安装已取消${NC}"
                    exit 0
                    ;;
            esac
        else
            echo -e "${BLUE}=== Configure Ports ===${NC}"
            echo -e "${YELLOW}To avoid conflicts with existing Nginx, please configure different ports${NC}"
            echo -e "1. Configure new ports"
            echo -e "2. Use random available ports"
            echo -e "3. Cancel installation"
            read -p "$(echo -e ${YELLOW}"Please select [1/2/3]: "${NC})" port_choice
            
            case $port_choice in
                1)
                    # 显示现有Nginx使用的端口
                    if [ ${#EXISTING_HTTP_PORTS[@]} -gt 0 ]; then
                        echo -e "${YELLOW}Existing Nginx is using these HTTP ports: ${EXISTING_HTTP_PORTS[*]}${NC}"
                    fi
                    
                    if [ ${#EXISTING_HTTPS_PORTS[@]} -gt 0 ]; then
                        echo -e "${YELLOW}Existing Nginx is using these HTTPS ports: ${EXISTING_HTTPS_PORTS[*]}${NC}"
                    fi
                    
                    read -p "$(echo -e ${YELLOW}"Please enter HTTP port (default: 8080): "${NC})" http_port
                    if [ "$CONFIGURE_HTTPS" == "yes" ]; then
                        read -p "$(echo -e ${YELLOW}"Please enter HTTPS port (default: 8443): "${NC})" https_port
                    fi
                    ;;
                2)
                    # 查找随机可用端口
                    echo -e "${YELLOW}Finding available ports...${NC}"
                    http_port=$(find_available_port 8000 9000)
                    if [ "$http_port" == "0" ]; then
                        echo -e "${RED}Error: Could not find available HTTP port${NC}"
                        exit 1
                    fi
                    
                    if [ "$CONFIGURE_HTTPS" == "yes" ]; then
                        https_port=$(find_available_port 8443 9443)
                        if [ "$https_port" == "0" ]; then
                            echo -e "${RED}Error: Could not find available HTTPS port${NC}"
                            exit 1
                        fi
                    fi
                    
                    echo -e "${GREEN}Found available HTTP port: ${http_port}${NC}"
                    if [ "$CONFIGURE_HTTPS" == "yes" ]; then
                        echo -e "${GREEN}Found available HTTPS port: ${https_port}${NC}"
                    fi
                    ;;
                3)
                    echo -e "${CYAN}Installation cancelled${NC}"
                    exit 0
                    ;;
                *)
                    echo -e "${CYAN}Installation cancelled${NC}"
                    exit 0
                    ;;
            esac
        fi
        
        # 设置默认值
        HTTP_PORT=${http_port:-8080}
        HTTPS_PORT=${https_port:-8443}
        
        # 检查端口是否与现有Nginx冲突
        for existing_port in "${EXISTING_HTTP_PORTS[@]}"; do
            if [ "$HTTP_PORT" = "$existing_port" ]; then
                if [ "$LANGUAGE" == "cn" ]; then
                    echo -e "${RED}错误: 新的HTTP端口与现有Nginx使用的端口相同${NC}"
                    echo -e "${RED}请选择不同的端口或取消安装${NC}"
                    read -p "$(echo -e ${YELLOW}"是否重新设置端口? [y/n]: "${NC})" retry_port
                    
                    if [[ $retry_port =~ ^[Yy]$ ]]; then
                        configure_ports
                        return
                    else
                        echo -e "${CYAN}安装已取消${NC}"
                        exit 0
                    fi
                else
                    echo -e "${RED}Error: New HTTP port conflicts with existing Nginx port${NC}"
                    echo -e "${RED}Please choose a different port or cancel installation${NC}"
                    read -p "$(echo -e ${YELLOW}"Reconfigure ports? [y/n]: "${NC})" retry_port
                    
                    if [[ $retry_port =~ ^[Yy]$ ]]; then
                        configure_ports
                        return
                    else
                        echo -e "${CYAN}Installation cancelled${NC}"
                        exit 0
                    fi
                fi
            fi
        done
        
        if [ "$CONFIGURE_HTTPS" == "yes" ]; then
            for existing_port in "${EXISTING_HTTPS_PORTS[@]}"; do
                if [ "$HTTPS_PORT" = "$existing_port" ]; then
                    if [ "$LANGUAGE" == "cn" ]; then
                        echo -e "${RED}错误: 新的HTTPS端口与现有Nginx使用的端口相同${NC}"
                        echo -e "${RED}请选择不同的端口或取消安装${NC}"
                        read -p "$(echo -e ${YELLOW}"是否重新设置端口? [y/n]: "${NC})" retry_port
                        
                        if [[ $retry_port =~ ^[Yy]$ ]]; then
                            configure_ports
                            return
                        else
                            echo -e "${CYAN}安装已取消${NC}"
                            exit 0
                        fi
                    else
                        echo -e "${RED}Error: New HTTPS port conflicts with existing Nginx port${NC}"
                        echo -e "${RED}Please choose a different port or cancel installation${NC}"
                        read -p "$(echo -e ${YELLOW}"Reconfigure ports? [y/n]: "${NC})" retry_port
                        
                        if [[ $retry_port =~ ^[Yy]$ ]]; then
                            configure_ports
                            return
                        else
                            echo -e "${CYAN}Installation cancelled${NC}"
                            exit 0
                        fi
                    fi
                fi
            done
        fi
    else
        # 默认情况下使用随机可用端口，而不是固定端口
        HTTP_PORT=$(find_available_port 8000 9000)
        if [ "$HTTP_PORT" == "0" ]; then
            if [ "$LANGUAGE" == "cn" ]; then
                echo -e "${RED}错误: 无法找到可用的HTTP端口${NC}"
            else
                echo -e "${RED}Error: Could not find available HTTP port${NC}"
            fi
            exit 1
        fi
        
        if [ "$CONFIGURE_HTTPS" == "yes" ]; then
            HTTPS_PORT=$(find_available_port 8443 9443)
            if [ "$HTTPS_PORT" == "0" ]; then
                if [ "$LANGUAGE" == "cn" ]; then
                    echo -e "${RED}错误: 无法找到可用的HTTPS端口${NC}"
                else
                    echo -e "${RED}Error: Could not find available HTTPS port${NC}"
                fi
                exit 1
            fi
        fi
    fi
    
    if [ "$LANGUAGE" == "cn" ]; then
        echo -e "${CYAN}HTTP端口: ${HTTP_PORT}${NC}"
        if [ "$CONFIGURE_HTTPS" == "yes" ]; then
            echo -e "${CYAN}HTTPS端口: ${HTTPS_PORT}${NC}"
        fi
    else
        echo -e "${CYAN}HTTP port: ${HTTP_PORT}${NC}"
        if [ "$CONFIGURE_HTTPS" == "yes" ]; then
            echo -e "${CYAN}HTTPS port: ${HTTPS_PORT}${NC}"
        fi
    fi
}

# 检测系统环境
check_system_env() {
    # 检查是否为Docker环境
    if [ -f /.dockerenv ] || grep -q 'docker\|lxc' /proc/1/cgroup 2>/dev/null; then
        IS_DOCKER=true
        show_message "检测到Docker环境" "Docker environment detected"
    else
        IS_DOCKER=false
    fi

    # 检查是否使用systemd
    if command -v systemctl &> /dev/null && systemctl --no-pager &> /dev/null; then
        HAS_SYSTEMD=true
    else
        HAS_SYSTEMD=false
        show_message "系统未使用systemd，将使用替代方法启动Nginx" "System is not using systemd, will use alternative method to start Nginx"
    fi
}

# 获取最新稳定版本
get_latest_stable_version() {
    echo "$(curl -s https://nginx.org/en/download.html | grep -oP 'nginx-\K[0-9]+\.[0-9]+\.[0-9]+(?=\.tar\.gz)' | sort -V | tail -1)"
}

# 语言选择
select_language() {
    echo -e "${BLUE}=== Nginx 自动安装脚本 / Nginx Auto Installation Script ===${NC}"
    echo -e "${CYAN}请选择语言 / Please select language:${NC}"
    echo -e "1. 中文 / Chinese"
    echo -e "2. 英文 / English"
    read -p "$(echo -e ${YELLOW}"请输入选项 [1/2] (默认: 中文): "${NC})" lang_choice
    
    case $lang_choice in
        2)
            LANGUAGE="en"
            ;;
        *)
            LANGUAGE="cn"
            ;;
    esac
}

# 显示消息
show_message() {
    local cn_msg="$1"
    local en_msg="$2"
    
    if [ "$LANGUAGE" == "cn" ]; then
        echo -e "${CYAN}${cn_msg}${NC}"
    else
        echo -e "${CYAN}${en_msg}${NC}"
    fi
}

# 显示成功消息
show_success() {
    local cn_msg="$1"
    local en_msg="$2"
    
    if [ "$LANGUAGE" == "cn" ]; then
        echo -e "${GREEN}${cn_msg}${NC}"
    else
        echo -e "${GREEN}${en_msg}${NC}"
    fi
}

# 显示错误消息
show_error() {
    local cn_msg="$1"
    local en_msg="$2"
    
    if [ "$LANGUAGE" == "cn" ]; then
        echo -e "${RED}${cn_msg}${NC}"
    else
        echo -e "${RED}${en_msg}${NC}"
    fi
}

# 显示警告消息
show_warning() {
    local cn_msg="$1"
    local en_msg="$2"
    
    if [ "$LANGUAGE" == "cn" ]; then
        echo -e "${YELLOW}${cn_msg}${NC}"
    else
        echo -e "${YELLOW}${en_msg}${NC}"
    fi
}

# 检查依赖
check_dependencies() {
    show_message "正在检查依赖..." "Checking dependencies..."
    
    local dependencies=("wget" "curl" "gcc" "make" "openssl" "pcre" "zlib")
    local missing_deps=()
    
    for dep in "${dependencies[@]}"; do
        if ! command -v $dep &> /dev/null && ! ldconfig -p | grep -q $dep; then
            missing_deps+=($dep)
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        show_warning "以下依赖未安装: ${missing_deps[*]}" "The following dependencies are missing: ${missing_deps[*]}"
        
        if [ "$LANGUAGE" == "cn" ]; then
            read -p "$(echo -e ${YELLOW}"是否自动安装这些依赖? [y/n]: "${NC})" install_deps
        else
            read -p "$(echo -e ${YELLOW}"Do you want to install these dependencies? [y/n]: "${NC})" install_deps
        fi
        
        if [[ $install_deps =~ ^[Yy]$ ]]; then
            if command -v apt-get &> /dev/null; then
                apt-get update
                apt-get install -y wget curl build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev openssl libssl-dev
            elif command -v yum &> /dev/null; then
                yum -y install wget curl gcc make pcre pcre-devel zlib zlib-devel openssl openssl-devel
            else
                show_error "无法自动安装依赖，请手动安装后重试" "Cannot install dependencies automatically. Please install them manually and try again"
                exit 1
            fi
        else
            show_error "请安装所需依赖后重试" "Please install the required dependencies and try again"
            exit 1
        fi
    else
        show_success "所有依赖已安装" "All dependencies are installed"
    fi
}

# 选择Nginx版本
select_nginx_version() {
    LATEST_VERSION=$(get_latest_stable_version)
    
    if [ "$LANGUAGE" == "cn" ]; then
        echo -e "${BLUE}=== 选择 Nginx 版本 ===${NC}"
        echo -e "1. 最新稳定版 (${LATEST_VERSION})"
        echo -e "2. 自定义版本"
        read -p "$(echo -e ${YELLOW}"请选择 [1/2] (默认: 1): "${NC})" version_choice
    else
        echo -e "${BLUE}=== Select Nginx Version ===${NC}"
        echo -e "1. Latest stable version (${LATEST_VERSION})"
        echo -e "2. Custom version"
        read -p "$(echo -e ${YELLOW}"Please select [1/2] (default: 1): "${NC})" version_choice
    fi
    
    # 检查输入是否直接包含版本号（包含点号）
    if [[ $version_choice == *"."* ]]; then
        # 用户直接输入了版本号
        NGINX_VERSION=$version_choice
        if [ "$LANGUAGE" == "cn" ]; then
            echo -e "${YELLOW}检测到直接输入版本号，将使用: ${NGINX_VERSION}${NC}"
        else
            echo -e "${YELLOW}Version number detected directly, will use: ${NGINX_VERSION}${NC}"
        fi
    else
        # 正常的选项处理
        case $version_choice in
            2)
                if [ "$LANGUAGE" == "cn" ]; then
                    read -p "$(echo -e ${YELLOW}"请输入 Nginx 版本 (例如 1.22.1): "${NC})" custom_version
                    # 确保用户输入了版本号
                    if [ -n "$custom_version" ]; then
                        NGINX_VERSION=$custom_version
                    else
                        echo -e "${YELLOW}未输入版本号，将使用最新稳定版 ${LATEST_VERSION}${NC}"
                        NGINX_VERSION=$LATEST_VERSION
                    fi
                else
                    read -p "$(echo -e ${YELLOW}"Please enter Nginx version (e.g., 1.22.1): "${NC})" custom_version
                    # 确保用户输入了版本号
                    if [ -n "$custom_version" ]; then
                        NGINX_VERSION=$custom_version
                    else
                        echo -e "${YELLOW}No version entered, will use latest stable version ${LATEST_VERSION}${NC}"
                        NGINX_VERSION=$LATEST_VERSION
                    fi
                fi
                ;;
            *)
                NGINX_VERSION=$LATEST_VERSION
                ;;
        esac
    fi
    
    if [ "$LANGUAGE" == "cn" ]; then
        echo -e "${CYAN}已选择 Nginx 版本: ${NGINX_VERSION}${NC}"
    else
        echo -e "${CYAN}Selected Nginx version: ${NGINX_VERSION}${NC}"
    fi
}

# 选择安装路径
select_install_path() {
    # 如果要保留现有Nginx，确保安装路径不同
    if [ "$CHANGE_PORT" = true ] && [ -n "$EXISTING_NGINX_PATH" ]; then
        if [ "$LANGUAGE" == "cn" ]; then
            echo -e "${BLUE}=== 选择安装路径 ===${NC}"
            echo -e "${YELLOW}已有Nginx安装路径: ${EXISTING_NGINX_PATH}${NC}"
            echo -e "${YELLOW}为避免冲突，请选择一个不同的安装路径${NC}"
            echo -e "1. 输入新安装路径"
            echo -e "2. 取消安装"
            read -p "$(echo -e ${YELLOW}"请选择 [1/2]: "${NC})" path_choice
            
            case $path_choice in
                2)
                    echo -e "${CYAN}安装已取消${NC}"
                    exit 0
                    ;;
                *)
                    read -p "$(echo -e ${YELLOW}"请输入新的安装路径: "${NC})" input_path
                    ;;
            esac
        else
            echo -e "${BLUE}=== Select Installation Path ===${NC}"
            echo -e "${YELLOW}Existing Nginx installation path: ${EXISTING_NGINX_PATH}${NC}"
            echo -e "${YELLOW}To avoid conflicts, please choose a different installation path${NC}"
            echo -e "1. Enter new installation path"
            echo -e "2. Cancel installation"
            read -p "$(echo -e ${YELLOW}"Please select [1/2]: "${NC})" path_choice
            
            case $path_choice in
                2)
                    echo -e "${CYAN}Installation cancelled${NC}"
                    exit 0
                    ;;
                *)
                    read -p "$(echo -e ${YELLOW}"Please enter new installation path: "${NC})" input_path
                    ;;
            esac
        fi
        
        # 确保输入了路径
        if [ -z "$input_path" ]; then
            if [ "$LANGUAGE" == "cn" ]; then
                echo -e "${RED}必须提供安装路径。安装已取消。${NC}"
            else
                echo -e "${RED}Installation path must be provided. Installation cancelled.${NC}"
            fi
            exit 0
        fi
        
        # 检查新路径是否与现有路径相同
        if [ "$input_path" == "$EXISTING_NGINX_PATH" ]; then
            if [ "$LANGUAGE" == "cn" ]; then
                echo -e "${RED}新路径不能与现有Nginx路径相同。安装已取消。${NC}"
            else
                echo -e "${RED}New path cannot be the same as existing Nginx path. Installation cancelled.${NC}"
            fi
            exit 0
        fi
        
        INSTALL_PATH=$input_path
    else
        # 正常的安装路径选择流程
        if [ "$LANGUAGE" == "cn" ]; then
            echo -e "${BLUE}=== 选择安装路径 ===${NC}"
            echo -e "1. 使用默认路径 (${DEFAULT_INSTALL_PATH})"
            echo -e "2. 输入自定义路径"
            echo -e "3. 取消安装"
            read -p "$(echo -e ${YELLOW}"请选择 [1/2/3] (默认: 1): "${NC})" path_choice
        else
            echo -e "${BLUE}=== Select Installation Path ===${NC}"
            echo -e "1. Use default path (${DEFAULT_INSTALL_PATH})"
            echo -e "2. Enter custom path"
            echo -e "3. Cancel installation"
            read -p "$(echo -e ${YELLOW}"Please select [1/2/3] (default: 1): "${NC})" path_choice
        fi
        
        case $path_choice in
            2)
                if [ "$LANGUAGE" == "cn" ]; then
                    read -p "$(echo -e ${YELLOW}"请输入安装路径: "${NC})" input_path
                else
                    read -p "$(echo -e ${YELLOW}"Please enter installation path: "${NC})" input_path
                fi
                INSTALL_PATH=$input_path
                ;;
            3)
                if [ "$LANGUAGE" == "cn" ]; then
                    echo -e "${CYAN}安装已取消${NC}"
                else
                    echo -e "${CYAN}Installation cancelled${NC}"
                fi
                exit 0
                ;;
            *)
                INSTALL_PATH=$DEFAULT_INSTALL_PATH
                ;;
        esac
        
        # 如果路径为空，使用默认路径
        if [ -z "$INSTALL_PATH" ]; then
            INSTALL_PATH=$DEFAULT_INSTALL_PATH
        fi
    fi
    
    # 检查路径是否已存在，如果存在但不是Nginx安装，提示用户
    if [ -d "$INSTALL_PATH" ] && [ "$INSTALL_PATH" != "$EXISTING_NGINX_PATH" ]; then
        if [ "$LANGUAGE" == "cn" ]; then
            echo -e "${YELLOW}警告: 目录 ${INSTALL_PATH} 已存在。${NC}"
            read -p "$(echo -e ${YELLOW}"是否继续安装到此目录? [y/n]: "${NC})" continue_install
        else
            echo -e "${YELLOW}Warning: Directory ${INSTALL_PATH} already exists.${NC}"
            read -p "$(echo -e ${YELLOW}"Continue installation to this directory? [y/n]: "${NC})" continue_install
        fi
        
        if [[ ! $continue_install =~ ^[Yy]$ ]]; then
            if [ "$LANGUAGE" == "cn" ]; then
                echo -e "${CYAN}安装已取消${NC}"
            else
                echo -e "${CYAN}Installation cancelled${NC}"
            fi
            exit 0
        fi
    fi
    
    show_message "安装路径: ${INSTALL_PATH}" "Installation path: ${INSTALL_PATH}"
}

# 选择是否配置HTTPS
select_https_option() {
    if [ "$LANGUAGE" == "cn" ]; then
        echo -e "${BLUE}=== HTTPS 配置 ===${NC}"
        echo -e "1. 配置 HTTPS (自签名证书)"
        echo -e "2. 不配置 HTTPS"
        read -p "$(echo -e ${YELLOW}"请选择 [1/2] (默认: 1): "${NC})" https_choice
    else
        echo -e "${BLUE}=== HTTPS Configuration ===${NC}"
        echo -e "1. Configure HTTPS (self-signed certificate)"
        echo -e "2. Do not configure HTTPS"
        read -p "$(echo -e ${YELLOW}"Please select [1/2] (default: 1): "${NC})" https_choice
    fi
    
    case $https_choice in
        2)
            CONFIGURE_HTTPS="no"
            ;;
        *)
            CONFIGURE_HTTPS="yes"
            ;;
    esac
    
    if [ "$CONFIGURE_HTTPS" == "yes" ]; then
        show_message "将配置 HTTPS 支持" "HTTPS support will be configured"
    else
        show_message "不配置 HTTPS 支持" "HTTPS support will not be configured"
    fi
}

# 检测端口占用
check_port_used() {
    local port=$1
    local port_occupied=false
    
    # 尝试通过netstat检查
    if command -v netstat > /dev/null; then
        if netstat -tuln | grep ":$port " > /dev/null; then
            port_occupied=true
        fi
    # 尝试通过ss检查
    elif command -v ss > /dev/null; then
        if ss -tuln | grep ":$port " > /dev/null; then
            port_occupied=true
        fi
    # 尝试通过lsof检查
    elif command -v lsof > /dev/null; then
        if lsof -i :$port > /dev/null; then
            port_occupied=true
        fi
    fi
    
    echo $port_occupied
}

# 下载并安装Nginx
install_nginx() {
    show_message "开始安装 Nginx ${NGINX_VERSION}..." "Starting installation of Nginx ${NGINX_VERSION}..."
    
    # 创建临时目录
    TMP_DIR=$(mktemp -d)
    cd $TMP_DIR
    
    # 下载Nginx
    show_message "正在下载 Nginx..." "Downloading Nginx..."
    DOWNLOAD_URL="https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"
    show_message "下载路径: ${DOWNLOAD_URL}" "Download URL: ${DOWNLOAD_URL}"
    wget -q "${DOWNLOAD_URL}"
    
    if [ $? -ne 0 ]; then
        show_error "下载 Nginx 失败，请检查版本号或网络连接" "Failed to download Nginx. Please check version number or network connection"
        exit 1
    fi
    
    # 解压
    show_message "正在解压..." "Extracting..."
    tar -xzf "nginx-${NGINX_VERSION}.tar.gz"
    cd "nginx-${NGINX_VERSION}"
    
    # 配置
    show_message "正在配置..." "Configuring..."
    
    CONFIGURE_OPTIONS="--prefix=${INSTALL_PATH} --with-http_ssl_module --with-http_v2_module --with-http_gzip_static_module"
    
    ./configure $CONFIGURE_OPTIONS
    
    if [ $? -ne 0 ]; then
        show_error "配置失败" "Configuration failed"
        exit 1
    fi
    
    # 编译和安装
    show_message "正在编译和安装..." "Compiling and installing..."
    make -j$(nproc)
    
    if [ $? -ne 0 ]; then
        show_error "编译失败" "Compilation failed"
        exit 1
    fi
    
    make install
    
    if [ $? -ne 0 ]; then
        show_error "安装失败" "Installation failed"
        exit 1
    fi
    
    show_success "Nginx 安装成功!" "Nginx installed successfully!"
}

# 配置HTTPS
configure_https() {
    if [ "$CONFIGURE_HTTPS" == "yes" ]; then
        show_message "正在配置 HTTPS..." "Configuring HTTPS..."
        
        # 创建证书目录
        mkdir -p "${INSTALL_PATH}/conf/ssl"
        
        # 生成自签名证书
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "${INSTALL_PATH}/conf/ssl/nginx.key" \
            -out "${INSTALL_PATH}/conf/ssl/nginx.crt" \
            -subj "/CN=localhost" -batch
        
        # 备份原始配置
        cp "${INSTALL_PATH}/conf/nginx.conf" "${INSTALL_PATH}/conf/nginx.conf.bak"
        
        # 创建新的配置文件
        cat > "${INSTALL_PATH}/conf/nginx.conf" << EOF
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;

    server {
        listen       ${HTTP_PORT};
        server_name  localhost;
        
        location / {
            root   html;
            index  index.html index.htm;
        }
        
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }

    # HTTPS server
    server {
        listen       ${HTTPS_PORT} ssl;
        server_name  localhost;

        ssl_certificate      ssl/nginx.crt;
        ssl_certificate_key  ssl/nginx.key;

        ssl_session_cache    shared:SSL:1m;
        ssl_session_timeout  5m;

        ssl_ciphers  HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers  on;

        location / {
            root   html;
            index  index.html index.htm;
        }
    }
}
EOF
        
        show_success "HTTPS 配置完成" "HTTPS configuration completed"
    else
        # 创建仅HTTP的配置
        cat > "${INSTALL_PATH}/conf/nginx.conf" << EOF
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;

    server {
        listen       ${HTTP_PORT};
        server_name  localhost;
        
        location / {
            root   html;
            index  index.html index.htm;
        }
        
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }
}
EOF
    fi
}

# 创建启动脚本
create_startup_script() {
    show_message "正在创建启动脚本..." "Creating startup script..."
    
    cat > /usr/local/bin/nginx-ctl << EOF
#!/bin/bash
NGINX_PATH="${INSTALL_PATH}/sbin/nginx"
NGINX_CONF="${INSTALL_PATH}/conf/nginx.conf"
NGINX_PID="${INSTALL_PATH}/logs/nginx.pid"

case "\$1" in
    start)
        \$NGINX_PATH -c \$NGINX_CONF
        echo "Nginx started"
        ;;
    stop)
        \$NGINX_PATH -s stop
        echo "Nginx stopped"
        ;;
    reload)
        \$NGINX_PATH -s reload
        echo "Nginx reloaded"
        ;;
    restart)
        \$NGINX_PATH -s stop
        sleep 1
        \$NGINX_PATH -c \$NGINX_CONF
        echo "Nginx restarted"
        ;;
    status)
        if [ -f \$NGINX_PID ] && ps -p \$(cat \$NGINX_PID) > /dev/null; then
            echo "Nginx is running"
        else
            echo "Nginx is not running"
        fi
        ;;
    *)
        echo "Usage: \$0 {start|stop|reload|restart|status}"
        exit 1
        ;;
esac
EOF
    
    chmod +x /usr/local/bin/nginx-ctl
    
    show_success "启动脚本创建完成" "Startup script created"
}

# 启动Nginx
start_nginx() {
    show_message "正在启动 Nginx..." "Starting Nginx..."
    
    if [ "$HAS_SYSTEMD" = true ]; then
        if systemctl start nginx; then
            show_success "Nginx 已成功启动" "Nginx has been started successfully"
            # 获取PID
            sleep 1
            NGINX_PID=$(systemctl show -p MainPID nginx | cut -d= -f2)
            if [ -n "$NGINX_PID" ] && [ "$NGINX_PID" != "0" ]; then
                show_message "Nginx 进程 PID: $NGINX_PID" "Nginx process PID: $NGINX_PID"
                show_message "PID 文件位置: ${INSTALL_PATH}/logs/nginx.pid" "PID file location: ${INSTALL_PATH}/logs/nginx.pid"
                show_message "HTTP 端口: ${HTTP_PORT}" "HTTP port: ${HTTP_PORT}"
                if [ "$CONFIGURE_HTTPS" == "yes" ]; then
                    show_message "HTTPS 端口: ${HTTPS_PORT}" "HTTPS port: ${HTTPS_PORT}"
                fi
                
                # 检查端口是否真的在监听
                if command -v netstat > /dev/null; then
                    echo ""
                    if [ "$LANGUAGE" == "cn" ]; then
                        echo -e "${GREEN}端口监听状态:${NC}"
                    else
                        echo -e "${GREEN}Port listening status:${NC}"
                    fi
                    netstat -tlnp | grep nginx
                elif command -v ss > /dev/null; then
                    echo ""
                    if [ "$LANGUAGE" == "cn" ]; then
                        echo -e "${GREEN}端口监听状态:${NC}"
                    else
                        echo -e "${GREEN}Port listening status:${NC}"
                    fi
                    ss -tlnp | grep nginx
                fi
            fi
        else
            show_error "Nginx 启动失败，尝试直接启动" "Failed to start Nginx with systemd, trying direct method"
            ${INSTALL_PATH}/sbin/nginx
            if [ $? -eq 0 ]; then
                show_success "Nginx 已成功启动" "Nginx has been started successfully"
                # 获取PID
                sleep 1
                if [ -f "${INSTALL_PATH}/logs/nginx.pid" ]; then
                    NGINX_PID=$(cat ${INSTALL_PATH}/logs/nginx.pid)
                    show_message "Nginx 进程 PID: $NGINX_PID" "Nginx process PID: $NGINX_PID"
                    show_message "PID 文件位置: ${INSTALL_PATH}/logs/nginx.pid" "PID file location: ${INSTALL_PATH}/logs/nginx.pid"
                    show_message "HTTP 端口: ${HTTP_PORT}" "HTTP port: ${HTTP_PORT}"
                    if [ "$CONFIGURE_HTTPS" == "yes" ]; then
                        show_message "HTTPS 端口: ${HTTPS_PORT}" "HTTPS port: ${HTTPS_PORT}"
                    fi
                    
                    # 检查端口是否真的在监听
                    if command -v netstat > /dev/null; then
                        echo ""
                        if [ "$LANGUAGE" == "cn" ]; then
                            echo -e "${GREEN}端口监听状态:${NC}"
                        else
                            echo -e "${GREEN}Port listening status:${NC}"
                        fi
                        netstat -tlnp | grep nginx
                    elif command -v ss > /dev/null; then
                        echo ""
                        if [ "$LANGUAGE" == "cn" ]; then
                            echo -e "${GREEN}端口监听状态:${NC}"
                        else
                            echo -e "${GREEN}Port listening status:${NC}"
                        fi
                        ss -tlnp | grep nginx
                    fi
                else
                    NGINX_PID=$(pgrep -f "${INSTALL_PATH}/sbin/nginx")
                    if [ -n "$NGINX_PID" ]; then
                        show_message "Nginx 进程 PID: $NGINX_PID" "Nginx process PID: $NGINX_PID"
                        show_message "HTTP 端口: ${HTTP_PORT}" "HTTP port: ${HTTP_PORT}"
                        if [ "$CONFIGURE_HTTPS" == "yes" ]; then
                            show_message "HTTPS 端口: ${HTTPS_PORT}" "HTTPS port: ${HTTPS_PORT}"
                        fi
                        
                        # 检查端口是否真的在监听
                        if command -v netstat > /dev/null; then
                            echo ""
                            if [ "$LANGUAGE" == "cn" ]; then
                                echo -e "${GREEN}端口监听状态:${NC}"
                            else
                                echo -e "${GREEN}Port listening status:${NC}"
                            fi
                            netstat -tlnp | grep nginx
                        elif command -v ss > /dev/null; then
                            echo ""
                            if [ "$LANGUAGE" == "cn" ]; then
                                echo -e "${GREEN}端口监听状态:${NC}"
                            else
                                echo -e "${GREEN}Port listening status:${NC}"
                            fi
                            ss -tlnp | grep nginx
                        fi
                    fi
                fi
            else
                show_error "Nginx 启动失败" "Failed to start Nginx"
            fi
        fi
    else
        ${INSTALL_PATH}/sbin/nginx
        if [ $? -eq 0 ]; then
            show_success "Nginx 已成功启动" "Nginx has been started successfully"
            # 获取PID
            sleep 1
            if [ -f "${INSTALL_PATH}/logs/nginx.pid" ]; then
                NGINX_PID=$(cat ${INSTALL_PATH}/logs/nginx.pid)
                show_message "Nginx 进程 PID: $NGINX_PID" "Nginx process PID: $NGINX_PID"
                show_message "PID 文件位置: ${INSTALL_PATH}/logs/nginx.pid" "PID file location: ${INSTALL_PATH}/logs/nginx.pid"
                show_message "HTTP 端口: ${HTTP_PORT}" "HTTP port: ${HTTP_PORT}"
                if [ "$CONFIGURE_HTTPS" == "yes" ]; then
                    show_message "HTTPS 端口: ${HTTPS_PORT}" "HTTPS port: ${HTTPS_PORT}"
                fi
                
                # 检查端口是否真的在监听
                if command -v netstat > /dev/null; then
                    echo ""
                    if [ "$LANGUAGE" == "cn" ]; then
                        echo -e "${GREEN}端口监听状态:${NC}"
                    else
                        echo -e "${GREEN}Port listening status:${NC}"
                    fi
                    netstat -tlnp | grep nginx
                elif command -v ss > /dev/null; then
                    echo ""
                    if [ "$LANGUAGE" == "cn" ]; then
                        echo -e "${GREEN}端口监听状态:${NC}"
                    else
                        echo -e "${GREEN}Port listening status:${NC}"
                    fi
                    ss -tlnp | grep nginx
                fi
            else
                NGINX_PID=$(pgrep -f "${INSTALL_PATH}/sbin/nginx")
                if [ -n "$NGINX_PID" ]; then
                    show_message "Nginx 进程 PID: $NGINX_PID" "Nginx process PID: $NGINX_PID"
                    show_message "HTTP 端口: ${HTTP_PORT}" "HTTP port: ${HTTP_PORT}"
                    if [ "$CONFIGURE_HTTPS" == "yes" ]; then
                        show_message "HTTPS 端口: ${HTTPS_PORT}" "HTTPS port: ${HTTPS_PORT}"
                    fi
                    
                    # 检查端口是否真的在监听
                    if command -v netstat > /dev/null; then
                        echo ""
                        if [ "$LANGUAGE" == "cn" ]; then
                            echo -e "${GREEN}端口监听状态:${NC}"
                        else
                            echo -e "${GREEN}Port listening status:${NC}"
                        fi
                        netstat -tlnp | grep nginx
                    elif command -v ss > /dev/null; then
                        echo ""
                        if [ "$LANGUAGE" == "cn" ]; then
                            echo -e "${GREEN}端口监听状态:${NC}"
                        else
                            echo -e "${GREEN}Port listening status:${NC}"
                        fi
                        ss -tlnp | grep nginx
                    fi
                fi
            fi
        else
            show_error "Nginx 启动失败" "Failed to start Nginx"
        fi
    fi
}

# 配置开机自启动
configure_autostart() {
    if [ "$LANGUAGE" == "cn" ]; then
        echo -e "${BLUE}=== 配置开机自启动 ===${NC}"
        read -p "$(echo -e ${YELLOW}"是否将Nginx配置为开机自启动? [y/n] (默认: y): "${NC})" autostart_choice
    else
        echo -e "${BLUE}=== Configure Auto-start ===${NC}"
        read -p "$(echo -e ${YELLOW}"Configure Nginx to start on boot? [y/n] (default: y): "${NC})" autostart_choice
    fi
    
    case $autostart_choice in
        [Nn]*)
            CONFIGURE_AUTOSTART=false
            ;;
        *)
            CONFIGURE_AUTOSTART=true
            ;;
    esac
    
    if [ "$CONFIGURE_AUTOSTART" = true ]; then
        if [ "$HAS_SYSTEMD" = true ]; then
            # 对于systemd系统
            systemctl enable nginx
            if [ $? -eq 0 ]; then
                show_success "Nginx已配置为开机自启动" "Nginx configured to start on boot"
            else
                show_error "配置开机自启动失败" "Failed to configure auto-start"
            fi
        else
            # 对于非systemd系统
            if [ -f "/etc/rc.local" ]; then
                # 检查rc.local是否有执行权限
                if [ ! -x "/etc/rc.local" ]; then
                    chmod +x /etc/rc.local
                fi
                
                # 添加启动命令到rc.local
                if ! grep -q "${INSTALL_PATH}/sbin/nginx" /etc/rc.local; then
                    # 检查文件末尾是否有exit 0
                    if grep -q "exit 0" /etc/rc.local; then
                        # 在exit 0之前插入命令
                        sed -i "s|^exit 0|${INSTALL_PATH}/sbin/nginx\\nexit 0|" /etc/rc.local
                    else
                        # 直接追加到文件末尾
                        echo "${INSTALL_PATH}/sbin/nginx" >> /etc/rc.local
                    fi
                    show_success "Nginx已配置为开机自启动" "Nginx configured to start on boot"
                else
                    show_message "Nginx已经配置为开机自启动" "Nginx is already configured to start on boot"
                fi
            elif [ -d "/etc/init.d" ]; then
                # 创建启动脚本
                cat > /etc/init.d/nginx << EOF
#!/bin/sh
### BEGIN INIT INFO
# Provides:          nginx
# Required-Start:    $network $remote_fs $local_fs
# Required-Stop:     $network $remote_fs $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start and stop nginx
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=${INSTALL_PATH}/sbin/nginx
NAME=nginx
DESC=nginx

test -x \$DAEMON || exit 0

# Include nginx defaults if available
if [ -f /etc/default/nginx ] ; then
    . /etc/default/nginx
fi

set -e

case "\$1" in
  start)
    echo -n "Starting \$DESC: "
    \$DAEMON
    echo "done."
    ;;
  stop)
    echo -n "Stopping \$DESC: "
    \$DAEMON -s stop
    echo "done."
    ;;
  restart|force-reload)
    echo -n "Restarting \$DESC: "
    \$DAEMON -s stop
    sleep 1
    \$DAEMON
    echo "done."
    ;;
  *)
    echo "Usage: \$NAME {start|stop|restart|force-reload}" >&2
    exit 1
    ;;
esac

exit 0
EOF
                chmod +x /etc/init.d/nginx
                
                # 配置为开机启动
                if command -v update-rc.d > /dev/null; then
                    update-rc.d nginx defaults
                elif command -v chkconfig > /dev/null; then
                    chkconfig --add nginx
                    chkconfig nginx on
                fi
                
                show_success "Nginx已配置为开机自启动" "Nginx configured to start on boot"
            else
                show_warning "无法配置开机自启动，请手动配置" "Cannot configure auto-start, please configure manually"
            fi
        fi
    else
        show_message "未配置开机自启动" "Auto-start not configured"
    fi
}

# 创建系统服务
create_systemd_service() {
    if [ "$HAS_SYSTEMD" = true ]; then
        show_message "正在创建系统服务..." "Creating system service..."
        
        cat > /etc/systemd/system/nginx.service << EOF
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=${INSTALL_PATH}/logs/nginx.pid
ExecStartPre=${INSTALL_PATH}/sbin/nginx -t
ExecStart=${INSTALL_PATH}/sbin/nginx
ExecReload=${INSTALL_PATH}/sbin/nginx -s reload
ExecStop=/bin/kill -s QUIT \$MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
        
        systemctl daemon-reload
        
        show_success "系统服务创建完成" "System service created"
    else
        create_startup_script
    fi
}

# 显示安装信息
show_installation_info() {
    echo -e "${BLUE}=== Nginx 安装信息 / Nginx Installation Information ===${NC}"
    echo -e "${GREEN}版本 / Version: ${NGINX_VERSION}${NC}"
    echo -e "${GREEN}安装路径 / Installation path: ${INSTALL_PATH}${NC}"
    echo -e "${GREEN}HTTP 端口 / HTTP port: ${HTTP_PORT}${NC}"
    echo -e "${GREEN}配置文件 / Configuration file: ${INSTALL_PATH}/conf/nginx.conf${NC}"
    echo -e "${GREEN}可执行文件 / Executable: ${INSTALL_PATH}/sbin/nginx${NC}"
    
    if [ "$CONFIGURE_HTTPS" == "yes" ]; then
        echo -e "${GREEN}HTTPS: 已配置 / Configured${NC}"
        echo -e "${GREEN}HTTPS 端口 / HTTPS port: ${HTTPS_PORT}${NC}"
        echo -e "${GREEN}证书路径 / Certificate path: ${INSTALL_PATH}/conf/ssl/nginx.crt${NC}"
        echo -e "${GREEN}私钥路径 / Key path: ${INSTALL_PATH}/conf/ssl/nginx.key${NC}"
    else
        echo -e "${GREEN}HTTPS: 未配置 / Not configured${NC}"
    fi
    
    echo -e "${GREEN}开机自启动 / Auto-start: $([ "$CONFIGURE_AUTOSTART" = true ] && echo "已配置 / Configured" || echo "未配置 / Not configured")${NC}"
    
    if [ "$HAS_SYSTEMD" = true ]; then
        echo -e "${YELLOW}使用以下命令启动 Nginx / Use the following command to start Nginx:${NC}"
        echo -e "${CYAN}systemctl start nginx${NC}"
        
        echo -e "${YELLOW}使用以下命令检查 Nginx 状态 / Use the following command to check Nginx status:${NC}"
        echo -e "${CYAN}systemctl status nginx${NC}"
    else
        echo -e "${YELLOW}使用以下命令控制 Nginx / Use the following commands to control Nginx:${NC}"
        echo -e "${CYAN}nginx-ctl start${NC} - 启动 Nginx / Start Nginx"
        echo -e "${CYAN}nginx-ctl stop${NC} - 停止 Nginx / Stop Nginx"
        echo -e "${CYAN}nginx-ctl reload${NC} - 重新加载配置 / Reload configuration"
        echo -e "${CYAN}nginx-ctl restart${NC} - 重启 Nginx / Restart Nginx"
        echo -e "${CYAN}nginx-ctl status${NC} - 检查 Nginx 状态 / Check Nginx status"
        
        echo -e "${YELLOW}或者直接使用 / Or directly use:${NC}"
        echo -e "${CYAN}${INSTALL_PATH}/sbin/nginx${NC} - 启动 Nginx / Start Nginx"
        echo -e "${CYAN}${INSTALL_PATH}/sbin/nginx -s stop${NC} - 停止 Nginx / Stop Nginx"
        echo -e "${CYAN}${INSTALL_PATH}/sbin/nginx -s reload${NC} - 重新加载配置 / Reload configuration"
    fi
}

# 主函数
main() {
    select_language
    check_system_env
    check_existing_nginx
    check_dependencies
    select_nginx_version
    select_install_path
    select_https_option
    configure_ports
    
    # 检查配置的端口是否被其他进程占用
    if [ "$(check_port_used $HTTP_PORT)" = "true" ] && [ "$HTTP_PORT" != "$EXISTING_HTTP_PORT" ]; then
        if [ "$LANGUAGE" == "cn" ]; then
            echo -e "${YELLOW}警告: HTTP端口 $HTTP_PORT 已被其他进程占用${NC}"
            read -p "$(echo -e ${YELLOW}"是否继续安装? [y/n]: "${NC})" continue_install
            
            if [[ ! $continue_install =~ ^[Yy]$ ]]; then
                echo -e "${CYAN}安装已取消${NC}"
                exit 0
            fi
        else
            echo -e "${YELLOW}Warning: HTTP port $HTTP_PORT is already in use by another process${NC}"
            read -p "$(echo -e ${YELLOW}"Continue installation? [y/n]: "${NC})" continue_install
            
            if [[ ! $continue_install =~ ^[Yy]$ ]]; then
                echo -e "${CYAN}Installation cancelled${NC}"
                exit 0
            fi
        fi
    fi
    
    if [ "$CONFIGURE_HTTPS" == "yes" ] && [ "$(check_port_used $HTTPS_PORT)" = "true" ] && [ "$HTTPS_PORT" != "$EXISTING_HTTPS_PORT" ]; then
        if [ "$LANGUAGE" == "cn" ]; then
            echo -e "${YELLOW}警告: HTTPS端口 $HTTPS_PORT 已被其他进程占用${NC}"
            read -p "$(echo -e ${YELLOW}"是否继续安装? [y/n]: "${NC})" continue_install
            
            if [[ ! $continue_install =~ ^[Yy]$ ]]; then
                echo -e "${CYAN}安装已取消${NC}"
                exit 0
            fi
        else
            echo -e "${YELLOW}Warning: HTTPS port $HTTPS_PORT is already in use by another process${NC}"
            read -p "$(echo -e ${YELLOW}"Continue installation? [y/n]: "${NC})" continue_install
            
            if [[ ! $continue_install =~ ^[Yy]$ ]]; then
                echo -e "${CYAN}Installation cancelled${NC}"
                exit 0
            fi
        fi
    fi
    
    configure_autostart
    
    # 确认安装
    if [ "$LANGUAGE" == "cn" ]; then
        echo -e "${BLUE}=== 安装确认 ===${NC}"
        echo -e "Nginx 版本: ${NGINX_VERSION}"
        echo -e "安装路径: ${INSTALL_PATH}"
        echo -e "HTTP 端口: ${HTTP_PORT}"
        if [ "$CONFIGURE_HTTPS" == "yes" ]; then
            echo -e "HTTPS 端口: ${HTTPS_PORT}"
        fi
        echo -e "配置 HTTPS: ${CONFIGURE_HTTPS}"
        echo -e "开机自启动: $([ "$CONFIGURE_AUTOSTART" = true ] && echo "是" || echo "否")"
        
        if [ "$CHANGE_PORT" = true ] && [ -n "$EXISTING_NGINX_PATH" ]; then
            echo -e "${YELLOW}注意: 将与现有Nginx (${EXISTING_NGINX_PATH}) 共存${NC}"
        fi
        
        read -p "$(echo -e ${YELLOW}"确认安装? [y/n]: "${NC})" confirm
    else
        echo -e "${BLUE}=== Installation Confirmation ===${NC}"
        echo -e "Nginx version: ${NGINX_VERSION}"
        echo -e "Installation path: ${INSTALL_PATH}"
        echo -e "HTTP port: ${HTTP_PORT}"
        if [ "$CONFIGURE_HTTPS" == "yes" ]; then
            echo -e "HTTPS port: ${HTTPS_PORT}"
        fi
        echo -e "Configure HTTPS: ${CONFIGURE_HTTPS}"
        echo -e "Auto-start: $([ "$CONFIGURE_AUTOSTART" = true ] && echo "Yes" || echo "No")"
        
        if [ "$CHANGE_PORT" = true ] && [ -n "$EXISTING_NGINX_PATH" ]; then
            echo -e "${YELLOW}Note: Will coexist with existing Nginx (${EXISTING_NGINX_PATH})${NC}"
        fi
        
        read -p "$(echo -e ${YELLOW}"Confirm installation? [y/n]: "${NC})" confirm
    fi
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        install_nginx
        configure_https
        create_systemd_service
        show_installation_info
        
        # 启动Nginx
        if [ "$LANGUAGE" == "cn" ]; then
            read -p "$(echo -e ${YELLOW}"是否立即启动 Nginx? [y/n]: "${NC})" start_now
        else
            read -p "$(echo -e ${YELLOW}"Start Nginx now? [y/n]: "${NC})" start_now
        fi
        
        if [[ $start_now =~ ^[Yy]$ ]]; then
            start_nginx
        fi
    else
        show_message "安装已取消" "Installation cancelled"
    fi
}

# 检查是否为root用户
if [ "$(id -u)" != "0" ]; then
    show_error "此脚本需要 root 权限运行" "This script must be run as root"
    exit 1
fi

# 执行主函数
main
