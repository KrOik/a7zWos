#!/bin/bash

# Radxa Cubie A7Z Kali Linux 项目启动脚本
# start-project.sh
# 
# 功能：
# - 项目初始化和环境检查
# - 交互式构建选项菜单
# - 错误处理和日志记录
# - 用户友好的界面
# - 构建验证和测试
#
# 作者: KrNormyDev
# 版本: 1.0.0
# 日期: $(date +%Y-%m-%d)

set -euo pipefail

# 全局变量
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
PROJECT_NAME="Radxa Cubie A7Z Kali Linux Build System"
PROJECT_VERSION="1.0.0"

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[0;37m'
readonly BOLD='\033[1m'
readonly UNDERLINE='\033[4m'
readonly RESET='\033[0m'

# 日志配置
LOG_DIR="$PROJECT_ROOT/logs"
LOG_FILE="$LOG_DIR/start-project-$(date +%Y%m%d-%H%M%S).log"
BUILD_LOG="$LOG_DIR/build-$(date +%Y%m%d-%H%M%S).log"

# 构建配置
BUILD_DIR="$PROJECT_ROOT/build"
OUTPUT_DIR="$PROJECT_ROOT/output"
CACHE_DIR="$PROJECT_ROOT/build/cache"
CONFIGS_DIR="$PROJECT_ROOT/configs"
PACKAGE_LISTS_DIR="$PROJECT_ROOT/package-lists"

# 进度条配置
PROGRESS_WIDTH=50
PROGRESS_CHAR="█"
PROGRESS_EMPTY="░"

# 错误代码
readonly ERROR_SUCCESS=0
readonly ERROR_GENERAL=1
readonly ERROR_MISSING_DEPENDENCY=2
readonly ERROR_BUILD_FAILED=3
readonly ERROR_INVALID_OPTION=4
readonly ERROR_PERMISSION_DENIED=5

# 信号处理
cleanup() {
    echo -e "\n${YELLOW}[INFO]${RESET} 正在清理..."
    # 清理临时文件
    rm -f /tmp/radxa-build-*.tmp
    
    # 恢复终端设置
    tput cnorm 2>/dev/null || true
    
    echo -e "${GREEN}[INFO]${RESET} 清理完成"
}

trap cleanup EXIT INT TERM

# 日志函数
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")
            echo -e "${CYAN}[INFO]${RESET} $message"
            echo "[$timestamp] [INFO] $message" >> "$LOG_FILE"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${RESET} $message"
            echo "[$timestamp] [SUCCESS] $message" >> "$LOG_FILE"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${RESET} $message"
            echo "[$timestamp] [WARNING] $message" >> "$LOG_FILE"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${RESET} $message"
            echo "[$timestamp] [ERROR] $message" >> "$LOG_FILE"
            ;;
        "DEBUG")
            if [[ "${DEBUG:-false}" == "true" ]]; then
                echo -e "${PURPLE}[DEBUG]${RESET} $message"
                echo "[$timestamp] [DEBUG] $message" >> "$LOG_FILE"
            fi
            ;;
    esac
}

# 错误处理函数
error_exit() {
    local error_code="${1:-$ERROR_GENERAL}"
    local error_message="$2"
    
    log "ERROR" "$error_message"
    echo -e "\n${RED}╭─────────────────────────────────────────────────╮${RESET}"
    echo -e "${RED}│${RESET}  ${BOLD}构建失败${RESET}                                         ${RED}│${RESET}"
    echo -e "${RED}├─────────────────────────────────────────────────┤${RESET}"
    echo -e "${RED}│${RESET}  错误代码: $error_code                            ${RED}│${RESET}"
    echo -e "${RED}│${RESET}  错误信息: $error_message                         ${RED}│${RESET}"
    echo -e "${RED}│${RESET}  日志文件: $LOG_FILE                              ${RED}│${RESET}"
    echo -e "${RED}╰─────────────────────────────────────────────────╯${RESET}"
    
    # 显示最近的错误日志
    if [[ -f "$LOG_FILE" ]]; then
        echo -e "\n${YELLOW}最近的错误日志:${RESET}"
        tail -n 10 "$LOG_FILE" | grep -E "(ERROR|FAILED)" | tail -n 5
    fi
    
    exit "$error_code"
}

# 进度条函数
show_progress() {
    local current="$1"
    local total="$2"
    local message="${3:-处理中...}"
    
    local percentage=$((current * 100 / total))
    local filled=$((PROGRESS_WIDTH * current / total))
    local empty=$((PROGRESS_WIDTH - filled))
    
    printf "\r${CYAN}[进度]${RESET} %s [${GREEN}%s${RESET}${PROGRESS_EMPTY}%s] %d%%" \
        "$message" \
        "$(printf '%*s' "$filled" | tr ' ' "$PROGRESS_CHAR")" \
        "$(printf '%*s' "$empty" | tr ' ' ' ')" \
        "$percentage"
    
    if [[ "$current" -eq "$total" ]]; then
        echo # 换行
    fi
}

# 旋转进度指示器
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf ' [%c]  ' "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf '\b\b\b\b\b\b'
    done
    printf '    \b\b\b\b'
}

# 检查系统要求
check_system_requirements() {
    log "INFO" "检查系统要求..."
    
    # 检查操作系统
    if [[ ! -f /etc/os-release ]]; then
        error_exit $ERROR_GENERAL "无法检测操作系统版本"
    fi
    
    local os_id=$(grep -E '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
    local os_version=$(grep -E '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
    
    log "INFO" "检测到操作系统: $os_id $os_version"
    
    # 检查支持的系统
    case "$os_id" in
        "ubuntu")
            if [[ "$os_version" < "20.04" ]]; then
                log "WARNING" "Ubuntu版本低于20.04，可能遇到兼容性问题"
            fi
            ;;
        "debian")
            if [[ "$os_version" < "11" ]]; then
                log "WARNING" "Debian版本低于11，可能遇到兼容性问题"
            fi
            ;;
        *)
            log "WARNING" "未测试的操作系统: $os_id，继续执行但可能遇到问题"
            ;;
    esac
    
    # 检查内存
    local total_memory=$(free -g | awk '/^Mem:/{print $2}')
    if [[ "$total_memory" -lt 8 ]]; then
        log "WARNING" "内存不足8GB，构建过程可能较慢"
    else
        log "SUCCESS" "内存检查通过: ${total_memory}GB"
    fi
    
    # 检查磁盘空间
    local available_space=$(df -BG "$PROJECT_ROOT" | awk 'NR==2{print $4}' | tr -d 'G')
    if [[ "$available_space" -lt 50 ]]; then
        error_exit $ERROR_GENERAL "磁盘空间不足，需要至少50GB可用空间"
    else
        log "SUCCESS" "磁盘空间检查通过: ${available_space}GB可用"
    fi
    
    log "SUCCESS" "系统要求检查完成"
}

# 检查依赖项
check_dependencies() {
    log "INFO" "检查依赖项..."
    
    local required_tools=(
        "bash"
        "git"
        "curl"
        "wget"
        "tar"
        "gzip"
        "unzip"
        "jq"
        "debootstrap"
        "qemu-user-static"
        "binfmt-support"
    )
    
    local missing_tools=()
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log "ERROR" "缺少必需的依赖项: ${missing_tools[*]}"
        echo -e "\n${YELLOW}请运行以下命令安装缺失的依赖项:${RESET}"
        echo -e "${CYAN}sudo apt update && sudo apt install -y ${missing_tools[*]}${RESET}"
        error_exit $ERROR_MISSING_DEPENDENCY "缺少必需的依赖项"
    fi
    
    log "SUCCESS" "所有依赖项检查通过"
}

# 创建目录结构
create_directory_structure() {
    log "INFO" "创建目录结构..."
    
    local directories=(
        "$LOG_DIR"
        "$BUILD_DIR"
        "$OUTPUT_DIR"
        "$CACHE_DIR"
        "$CONFIGS_DIR"
        "$PACKAGE_LISTS_DIR"
        "$PROJECT_ROOT/tests"
        "$PROJECT_ROOT/docs"
    )
    
    for dir in "${directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log "DEBUG" "创建目录: $dir"
        fi
    done
    
    log "SUCCESS" "目录结构创建完成"
}

# 初始化项目
init_project() {
    log "INFO" "初始化项目..."
    
    # 显示项目信息
    echo -e "\n${BOLD}${BLUE}╔════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}  ${BOLD}Radxa Cubie A7Z Kali Linux Build System${RESET}                    ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}  版本: $PROJECT_VERSION                                          ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}  作者: KrNormyDev                                            ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════════╝${RESET}"
    echo
    
    # 检查系统要求
    check_system_requirements
    
    # 检查依赖项
    check_dependencies
    
    # 创建目录结构
    create_directory_structure
    
    log "SUCCESS" "项目初始化完成"
}

# 显示主菜单
show_main_menu() {
    clear
    echo -e "\n${BOLD}${BLUE}╔════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}  ${BOLD}Radxa Cubie A7Z Kali Linux Build System${RESET}                    ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}  版本: $PROJECT_VERSION                                          ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}╠════════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}  ${CYAN}构建选项:${RESET}                                                   ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}                                                               ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}  ${GREEN}1)${RESET} 快速构建 (推荐)                                         ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}  ${GREEN}2)${RESET} 完整构建 (包含所有组件)                                ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}  ${GREEN}3)${RESET} 自定义构建 (高级选项)                                  ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}  ${GREEN}4)${RESET} 验证和测试                                            ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}  ${GREEN}5)${RESET} 清理和重置                                            ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}                                                               ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}  ${YELLOW}系统选项:${RESET}                                                   ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}                                                               ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}  ${GREEN}6)${RESET} 检查依赖项                                            ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}  ${GREEN}7)${RESET} 查看日志                                              ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}  ${GREEN}8)${RESET} 帮助和文档                                            ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}                                                               ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}  ${RED}0)${RESET} 退出                                                  ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════════╝${RESET}"
    echo
}

# 快速构建
quick_build() {
    log "INFO" "开始快速构建..."
    
    echo -e "\n${YELLOW}[快速构建]${RESET} 正在执行快速构建流程..."
    echo -e "${CYAN}此选项将构建基本的Kali Linux系统，包含核心安全工具${RESET}"
    echo
    
    # 检查是否可以继续
    if [[ ! -f "$PROJECT_ROOT/radxa-kali-builder.sh" ]]; then
        error_exit $ERROR_GENERAL "找不到主构建脚本 radxa-kali-builder.sh"
    fi
    
    # 运行快速构建
    log "INFO" "执行快速构建脚本..."
    
    # 显示进度
    (
        echo "0"
        sleep 1
        echo "25"
        sleep 1
        echo "50"
        sleep 1
        echo "75"
        sleep 1
        echo "100"
    ) | while read -r progress; do
        show_progress "$progress" 100 "执行快速构建..."
    done
    
    # 实际构建
    if "$PROJECT_ROOT/radxa-kali-builder.sh" --quick 2>&1 | tee "$BUILD_LOG"; then
        log "SUCCESS" "快速构建完成"
        echo -e "\n${GREEN}✅ 快速构建成功完成！${RESET}"
        echo -e "${CYAN}构建日志: $BUILD_LOG${RESET}"
        
        # 询问是否运行测试
        echo -e "\n${YELLOW}是否运行构建验证测试？${RESET}"
        read -p "运行测试 [Y/n]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            run_validation_tests
        fi
    else
        error_exit $ERROR_BUILD_FAILED "快速构建失败，请检查日志: $BUILD_LOG"
    fi
}

# 完整构建
full_build() {
    log "INFO" "开始完整构建..."
    
    echo -e "\n${YELLOW}[完整构建]${RESET} 正在执行完整构建流程..."
    echo -e "${CYAN}此选项将构建包含所有组件的完整系统${RESET}"
    echo -e "${CYAN}包括：Wayland桌面、Waydroid容器、完整安全工具套件${RESET}"
    echo
    
    # 确认操作
    echo -e "${YELLOW}警告：完整构建需要较长时间和更多磁盘空间${RESET}"
    read -p "是否继续完整构建？ [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "INFO" "用户取消完整构建"
        return 1
    fi
    
    # 检查是否可以继续
    if [[ ! -f "$PROJECT_ROOT/radxa-kali-builder.sh" ]]; then
        error_exit $ERROR_GENERAL "找不到主构建脚本 radxa-kali-builder.sh"
    fi
    
    # 运行完整构建
    log "INFO" "执行完整构建脚本..."
    
    # 显示进度
    (
        for i in {0..100..5}; do
            echo "$i"
            sleep 0.5
        done
    ) | while read -r progress; do
        show_progress "$progress" 100 "执行完整构建..."
    done
    
    # 实际构建
    if "$PROJECT_ROOT/radxa-kali-builder.sh" --full 2>&1 | tee "$BUILD_LOG"; then
        log "SUCCESS" "完整构建完成"
        echo -e "\n${GREEN}✅ 完整构建成功完成！${RESET}"
        echo -e "${CYAN}构建日志: $BUILD_LOG${RESET}"
        
        # 自动运行测试
        echo -e "\n${GREEN}正在运行构建验证测试...${RESET}"
        run_validation_tests
    else
        error_exit $ERROR_BUILD_FAILED "完整构建失败，请检查日志: $BUILD_LOG"
    fi
}

# 自定义构建
custom_build() {
    log "INFO" "开始自定义构建..."
    
    echo -e "\n${YELLOW}[自定义构建]${RESET} 自定义构建选项..."
    echo
    
    # 显示可用选项
    echo -e "${CYAN}可用组件:${RESET}"
    echo -e "  ${GREEN}1)${RESET} Kali核心工具"
    echo -e "  ${GREEN}2)${RESET} Radxa硬件支持"
    echo -e "  ${GREEN}3)${RESET} Wayland桌面环境"
    echo -e "  ${GREEN}4)${RESET} Waydroid容器"
    echo -e "  ${GREEN}5)${RESET} ZSH终端环境"
    echo -e "  ${GREEN}6)${RESET} 完整安全工具套件"
    echo
    
    # 让用户选择组件
    local components=()
    read -p "选择要包含的组件（用空格分隔数字）: " -r choices
    
    for choice in $choices; do
        case "$choice" in
            1) components+=("kali-core") ;;
            2) components+=("radxa-hardware") ;;
            3) components+=("wayland-desktop") ;;
            4) components+=("waydroid") ;;
            5) components+=("zsh-shell") ;;
            6) components+=("security-tools") ;;
            *) log "WARNING" "无效的选择: $choice" ;;
        esac
    done
    
    if [[ ${#components[@]} -eq 0 ]]; then
        log "ERROR" "未选择任何组件"
        return 1
    fi
    
    echo -e "\n${CYAN}选择的组件:${RESET} ${components[*]}"
    read -p "是否继续？ [Y/n]: " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log "INFO" "用户取消自定义构建"
        return 1
    fi
    
    # 生成自定义配置
    log "INFO" "生成自定义构建配置..."
    generate_custom_config "${components[@]}"
    
    # 运行自定义构建
    log "INFO" "执行自定义构建..."
    if "$PROJECT_ROOT/radxa-kali-builder.sh" --config "$PROJECT_ROOT/configs/custom.jsonnet" 2>&1 | tee "$BUILD_LOG"; then
        log "SUCCESS" "自定义构建完成"
        echo -e "\n${GREEN}✅ 自定义构建成功完成！${RESET}"
        echo -e "${CYAN}构建日志: $BUILD_LOG${RESET}"
    else
        error_exit $ERROR_BUILD_FAILED "自定义构建失败，请检查日志: $BUILD_LOG"
    fi
}

# 生成自定义配置
generate_custom_config() {
    local components=("$@")
    
    cat > "$PROJECT_ROOT/configs/custom.jsonnet" << EOF
{
  // 自定义构建配置
  architecture: "arm64",
  base_system: "kali-rolling",
  hostname: "radxa-cubie-a7z-kali-custom",
  kernel_version: "5.15.0-radxa-cubie-a7z",
  
  // 选择的组件
  packages: [
EOF
    
    for component in "${components[@]}"; do
        echo "    \"$component\"," >> "$PROJECT_ROOT/configs/custom.jsonnet"
    done
    
    cat >> "$PROJECT_ROOT/configs/custom.jsonnet" << EOF
  ],
  
  // 钩子脚本
  hooks: [
EOF
    
    # 根据组件添加相应的钩子
    if [[ " ${components[*]} " =~ " radxa-hardware " ]]; then
        echo "    \"9990-radxa-hardware-init\"," >> "$PROJECT_ROOT/configs/custom.jsonnet"
    fi
    
    if [[ " ${components[*]} " =~ " waydroid " ]]; then
        echo "    \"9991-waydroid-nokvm-setup\"," >> "$PROJECT_ROOT/configs/custom.jsonnet"
    fi
    
    # 基础钩子（总是包含）
    cat >> "$PROJECT_ROOT/configs/custom.jsonnet" << EOF
    \"9992-kali-tools-config\",
    \"9993-zsh-terminal-setup\",
    \"9994-wayland-desktop-setup\",
    \"9995-vendor-information\"
  ]
}
EOF
    
    log "SUCCESS" "自定义配置生成完成: $PROJECT_ROOT/configs/custom.jsonnet"
}

# 运行验证测试
run_validation_tests() {
    log "INFO" "开始运行验证测试..."
    
    echo -e "\n${YELLOW}[验证测试]${RESET} 正在运行构建验证测试..."
    
    # 检查验证脚本是否存在
    if [[ ! -f "$PROJECT_ROOT/build-validator.sh" ]]; then
        log "WARNING" "找不到构建验证脚本，跳过验证"
        return 0
    fi
    
    # 运行验证
    if "$PROJECT_ROOT/build-validator.sh" --quick; then
        log "SUCCESS" "构建验证测试通过"
        echo -e "\n${GREEN}✅ 构建验证测试通过！${RESET}"
    else
        log "WARNING" "构建验证测试发现一些问题，但构建仍可继续"
        echo -e "\n${YELLOW}⚠️ 构建验证测试发现一些问题${RESET}"
        echo -e "${CYAN}请查看详细报告以了解详情${RESET}"
    fi
}

# 清理和重置
cleanup_and_reset() {
    log "INFO" "开始清理和重置..."
    
    echo -e "\n${YELLOW}[清理和重置]${RESET} 清理选项..."
    echo
    echo -e "${RED}警告：此操作将删除构建文件和缓存${RESET}"
    echo -e "${CYAN}可用选项:${RESET}"
    echo -e "  ${GREEN}1)${RESET} 清理构建缓存"
    echo -e "  ${GREEN}2)${RESET} 清理输出文件"
    echo -e "  ${GREEN}3)${RESET} 清理所有构建文件"
    echo -e "  ${GREEN}4)${RESET} 完全重置项目"
    echo -e "  ${GREEN}0)${RESET} 返回主菜单"
    echo
    
    read -p "选择清理选项: " -r choice
    
    case "$choice" in
        1)
            log "INFO" "清理构建缓存..."
            rm -rf "$CACHE_DIR"/*
            log "SUCCESS" "构建缓存清理完成"
            ;;
        2)
            log "INFO" "清理输出文件..."
            rm -rf "$OUTPUT_DIR"/*
            log "SUCCESS" "输出文件清理完成"
            ;;
        3)
            log "INFO" "清理所有构建文件..."
            rm -rf "$BUILD_DIR"/*
            rm -rf "$CACHE_DIR"/*
            rm -rf "$OUTPUT_DIR"/*
            log "SUCCESS" "所有构建文件清理完成"
            ;;
        4)
            log "INFO" "完全重置项目..."
            echo -e "${RED}警告：此操作将删除所有构建文件和配置${RESET}"
            read -p "是否确认完全重置？ [y/N]: " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -rf "$BUILD_DIR"/*
                rm -rf "$CACHE_DIR"/*
                rm -rf "$OUTPUT_DIR"/*
                rm -f "$PROJECT_ROOT/configs/custom.jsonnet"
                log "SUCCESS" "项目完全重置完成"
            else
                log "INFO" "用户取消完全重置"
            fi
            ;;
        0)
            log "INFO" "用户取消清理操作"
            return 0
            ;;
        *)
            log "ERROR" "无效的清理选项"
            return 1
            ;;
    esac
    
    echo -e "\n${GREEN}✅ 清理操作完成！${RESET}"
}

# 查看日志
view_logs() {
    log "INFO" "查看日志选项..."
    
    echo -e "\n${YELLOW}[查看日志]${RESET} 可用日志文件:"
    
    # 列出日志文件
    local log_files=($(ls -t "$LOG_DIR"/*.log 2>/dev/null))
    
    if [[ ${#log_files[@]} -eq 0 ]]; then
        log "WARNING" "没有找到日志文件"
        return 1
    fi
    
    for i in "${!log_files[@]}"; do
        echo -e "  ${GREEN}$((i+1)))${RESET} $(basename "${log_files[$i]}")"
    done
    
    echo -e "  ${GREEN}0)${RESET} 返回主菜单"
    echo
    
    read -p "选择要查看的日志文件: " -r choice
    
    if [[ "$choice" == "0" ]]; then
        return 0
    fi
    
    local selected_index=$((choice-1))
    if [[ "$selected_index" -ge 0 ]] && [[ "$selected_index" -lt ${#log_files[@]} ]]; then
        local selected_log="${log_files[$selected_index]}"
        echo -e "\n${CYAN}查看日志: $(basename "$selected_log")${RESET}"
        echo -e "${CYAN}按 q 退出，空格翻页${RESET}"
        read -p "按回车键继续..."
        less "$selected_log"
    else
        log "ERROR" "无效的选择"
    fi
}

# 显示帮助
show_help() {
    clear
    echo -e "\n${BOLD}${BLUE}╔════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}  ${BOLD}Radxa Cubie A7Z Kali Linux Build System - 帮助${RESET}         ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo -e "${CYAN}项目描述:${RESET}"
    echo -e "  基于KrNormyDev/a7zWos的Radxa Cubie A7Z开发板Kali Linux构建系统"
    echo -e "  支持Wayland桌面环境、Waydroid容器和完整的Kali安全工具套件"
    echo
    echo -e "${CYAN}使用方法:${RESET}"
    echo -e "  $SCRIPT_NAME [选项]"
    echo
    echo -e "${CYAN}命令行选项:${RESET}"
    echo -e "  ${GREEN}-h, --help${RESET}      显示帮助信息"
    echo -e "  ${GREEN}-q, --quick${RESET}     直接开始快速构建"
    echo -e "  ${GREEN}-f, --full${RESET}      直接开始完整构建"
    echo -e "  ${GREEN}-c, --custom${RESET}    直接开始自定义构建"
    echo -e "  ${GREEN}-v, --version${RESET}   显示版本信息"
    echo -e "  ${GREEN}--validate${RESET}     运行构建验证"
    echo -e "  ${GREEN}--clean${RESET}        清理构建环境"
    echo -e "  ${GREEN}--deps${RESET}         检查依赖项"
    echo
    echo -e "${CYAN}交互式菜单选项:${RESET}"
    echo -e "  ${GREEN}1)${RESET} 快速构建 - 构建基本Kali系统"
    echo -e "  ${GREEN}2)${RESET} 完整构建 - 构建包含所有组件的系统"
    echo -e "  ${GREEN}3)${RESET} 自定义构建 - 选择特定组件进行构建"
    echo -e "  ${GREEN}4)${RESET} 验证和测试 - 运行构建验证测试"
    echo -e "  ${GREEN}5)${RESET} 清理和重置 - 清理构建文件和缓存"
    echo -e "  ${GREEN}6)${RESET} 检查依赖项 - 检查系统依赖项"
    echo -e "  ${GREEN}7)${RESET} 查看日志 - 查看构建日志文件"
    echo -e "  ${GREEN}8)${RESET} 帮助和文档 - 显示帮助信息"
    echo
    echo -e "${CYAN}示例:${RESET}"
    echo -e "  $SCRIPT_NAME              # 启动交互式菜单"
    echo -e "  $SCRIPT_NAME --quick      # 直接开始快速构建"
    echo -e "  $SCRIPT_NAME --full       # 直接开始完整构建"
    echo -e "  $SCRIPT_NAME --validate   # 运行构建验证"
    echo -e "  $SCRIPT_NAME --clean      # 清理构建环境"
    echo
    echo -e "${CYAN}日志文件:${RESET}"
    echo -e "  主日志: $LOG_FILE"
    echo -e "  构建日志: $BUILD_LOG"
    echo
    echo -e "${CYAN}项目文件:${RESET}"
    echo -e "  主构建脚本: $PROJECT_ROOT/radxa-kali-builder.sh"
    echo -e "  快速部署脚本: $PROJECT_ROOT/quick-deploy.sh"
    echo -e "  构建验证脚本: $PROJECT_ROOT/build-validator.sh"
    echo -e "  硬件测试脚本: $PROJECT_ROOT/hardware-test.sh"
    echo -e "  安全测试脚本: $PROJECT_ROOT/security-test.sh"
    echo
    echo -e "${CYAN}更多信息:${RESET}"
    echo -e "  项目文档: $PROJECT_ROOT/README.md"
    echo -e "  构建说明: $PROJECT_ROOT/BUILD_INSTRUCTIONS.md"
    echo -e "  使用指南: $PROJECT_ROOT/USAGE_GUIDE.md"
    echo
    read -p "按回车键返回主菜单..."
}

# 显示版本信息
show_version() {
    echo -e "\n${BOLD}${BLUE}Radxa Cubie A7Z Kali Linux Build System${RESET}"
    echo -e "版本: ${GREEN}$PROJECT_VERSION${RESET}"
    echo -e "作者: ${CYAN}KrNormyDev${RESET}"
    echo -e "日期: $(date +%Y-%m-%d)"
    echo -e "脚本: $SCRIPT_NAME"
    echo -e "项目: $PROJECT_ROOT"
    echo
}

# 主菜单循环
main_menu() {
    while true; do
        show_main_menu
        read -p "选择操作 [0-8]: " -r choice
        
        case "$choice" in
            1)
                quick_build
                read -p "按回车键继续..."
                ;;
            2)
                full_build
                read -p "按回车键继续..."
                ;;
            3)
                custom_build
                read -p "按回车键继续..."
                ;;
            4)
                run_validation_tests
                read -p "按回车键继续..."
                ;;
            5)
                cleanup_and_reset
                read -p "按回车键继续..."
                ;;
            6)
                check_dependencies
                read -p "按回车键继续..."
                ;;
            7)
                view_logs
                read -p "按回车键继续..."
                ;;
            8)
                show_help
                ;;
            0)
                log "INFO" "用户选择退出"
                echo -e "\n${GREEN}感谢使用 Radxa Cubie A7Z Kali Linux Build System！${RESET}"
                echo -e "${CYAN}项目地址: https://github.com/KrNormyDev/radxa-cubie-a7z-kali-build-system${RESET}"
                exit 0
                ;;
            *)
                log "ERROR" "无效的选择: $choice"
                read -p "按回车键继续..."
                ;;
        esac
    done
}

# 命令行参数处理
handle_command_line_args() {
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            show_version
            exit 0
            ;;
        -q|--quick)
            init_project
            quick_build
            exit 0
            ;;
        -f|--full)
            init_project
            full_build
            exit 0
            ;;
        -c|--custom)
            init_project
            custom_build
            exit 0
            ;;
        --validate)
            if [[ -f "$PROJECT_ROOT/build-validator.sh" ]]; then
                "$PROJECT_ROOT/build-validator.sh"
            else
                log "ERROR" "构建验证脚本不存在"
                exit 1
            fi
            exit 0
            ;;
        --clean)
            cleanup_and_reset
            exit 0
            ;;
        --deps)
            check_dependencies
            exit 0
            ;;
        "")
            # 无参数，启动交互式菜单
            return 0
            ;;
        *)
            log "ERROR" "未知选项: $1"
            echo -e "${CYAN}使用 '$SCRIPT_NAME --help' 查看帮助${RESET}"
            exit $ERROR_INVALID_OPTION
            ;;
    esac
}

# 主函数
main() {
    # 隐藏光标
    tput civis 2>/dev/null || true
    
    # 处理命令行参数
    handle_command_line_args "$@"
    
    # 初始化项目
    init_project
    
    # 启动主菜单
    main_menu
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi