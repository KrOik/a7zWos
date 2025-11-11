#!/bin/bash

# Radxa Cubie A7Z Kali Linux 快速部署脚本
# 一键部署完整构建环境
# 作者: KrNormyDev
# 版本: 1.0.0

set -euo pipefail

# 全局变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/quick-deploy.log"
VENDOR="KrNormyDev"
PRODUCT="a7zWos"
VERSION="1.0.0"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_header() {
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}  $VENDOR $PRODUCT Kali Linux 快速部署${NC}"
    echo -e "${PURPLE}  版本: $VERSION${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
}

# 检查root权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        echo "请使用: sudo $0"
        exit 1
    fi
}

# 显示系统信息
show_system_info() {
    log_info "系统信息:"
    echo -e "  ${CYAN}架构:${NC} $(uname -m)"
    echo -e "  ${CYAN}内核:${NC} $(uname -r)"
    echo -e "  ${CYAN}发行版:${NC} $(lsb_release -d -s 2>/dev/null || echo "Unknown")"
    echo -e "  ${CYAN}磁盘空间:${NC} $(df -h / | awk 'NR==2 {print $4}') 可用"
    echo -e "  ${CYAN}内存:${NC} $(free -h | awk 'NR==2 {print $2}')"
    echo ""
}

# 检查网络连接
check_network() {
    # log_info "检查网络连接..."
    
    # local sites=(
    #     "http.kali.org"
    #     "github.com"
    #     "radxa-repo.github.io"
    # )
    
    # for site in "${sites[@]}"; do
    #     if ping -c 1 "$site" &> /dev/null; then
    #         log_success "✓ $site 可访问"
    #     else
    #         log_error "✗ $site 无法访问"
    #         return 1
    #     fi
    # done
    
    return 0
}

# 检查磁盘空间
check_disk_space() {
    log_info "检查磁盘空间..."
    
    local required_space=20 # GB
    local available_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    
    if [[ $available_space -ge $required_space ]]; then
        log_success "✓ 磁盘空间充足: ${available_space}GB (需要 ${required_space}GB)"
    else
        log_error "✗ 磁盘空间不足: ${available_space}GB (需要 ${required_space}GB)"
        return 1
    fi
    
    return 0
}

# 检查内存
check_memory() {
    log_info "检查内存..."
    
    local required_memory=4 # GB
    local total_memory=$(free -g | awk 'NR==2 {print $2}')
    
    if [[ $total_memory -ge $required_memory ]]; then
        log_success "✓ 内存充足: ${total_memory}GB (推荐 ${required_memory}GB)"
    else
        log_warning "⚠ 内存较少: ${total_memory}GB (推荐 ${required_memory}GB+)"
        log_warning "构建可能需要更长时间"
    fi
}

# 检查必需工具
check_required_tools() {
    log_info "检查必需工具..."
    
    local tools=(
        "git"
        "curl"
        "wget"
        "tar"
        "gzip"
        "xz"
        "make"
        "gcc"
        "g++"
    )
    
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log_success "✓ $tool 已安装"
        else
            log_error "✗ $tool 未安装"
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_info "安装缺失的工具: ${missing_tools[*]}"
        apt-get update
        apt-get install -y "${missing_tools[@]}" || {
            log_error "工具安装失败"
            return 1
        }
    fi
    
    return 0
}

# 安装构建依赖
install_build_dependencies() {
    log_info "安装构建依赖..."
    
    local packages=(
        # 基础构建工具
        "build-essential"
        "debootstrap"
        "live-build"
        "jq"
        "python3"
        "python3-pip"
        
        # 虚拟化支持
        "qemu-user-static"
        "binfmt-support"
        "docker.io"
        
        # 文件系统工具
        "squashfs-tools"
        "dosfstools"
        "mtools"
        "parted"
        "e2fsprogs"
        "btrfs-progs"
        "xfsprogs"
        
        # 镜像工具
        "xorriso"
        "isolinux"
        "syslinux"
        "grub-pc-bin"
        "grub-efi-amd64-bin"
        "grub-efi-ia32-bin"
        "efibootmgr"
        
        # 其他工具
        "rsync"
        "faketime"
        "libarchive-tools"
        "arch-test"
        "udftools"
        "gparted"
        "testdisk"
    )
    
    apt-get update
    
    for package in "${packages[@]}"; do
        if dpkg -l | grep -q "^ii.*$package"; then
            log_success "✓ $package 已安装"
        else
            log_info "安装 $package..."
            apt-get install -y "$package" || {
                log_warning "$package 安装失败，继续..."
            }
        fi
    done
    
    log_success "构建依赖安装完成"
}

# 设置Docker（如果需要）
setup_docker() {
    if command -v docker &> /dev/null; then
        log_info "配置Docker..."
        
        # 启动Docker服务
        systemctl start docker || log_warning "Docker服务启动失败"
        systemctl enable docker || log_warning "Docker服务启用失败"
        
        # 检查Docker状态
        if systemctl is-active --quiet docker; then
            log_success "✓ Docker服务运行正常"
        else
            log_warning "⚠ Docker服务未运行"
        fi
    fi
}

# 下载主构建脚本
download_main_script() {
    log_info "检查主构建脚本..."
    
    local main_script="${SCRIPT_DIR}/radxa-kali-builder.sh"
    
    if [[ -f "$main_script" ]]; then
        log_success "✓ 主构建脚本已存在"
        chmod +x "$main_script"
    else
        log_error "✗ 主构建脚本不存在: $main_script"
        log_info "请确保radxa-kali-builder.sh在同一目录下"
        return 1
    fi
    
    return 0
}

# 创建项目结构
create_project_structure() {
    log_info "创建项目结构..."
    
    local dirs=(
        "configs"
        "hooks"
        "package-lists"
        "build"
        "output"
        "logs"
        "tests"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "${SCRIPT_DIR}/$dir"
        log_success "✓ 创建目录: $dir"
    done
}

# 显示部署选项
show_deployment_options() {
    echo ""
    log_info "部署选项:"
    echo "  1) 完整部署 (推荐) - 安装所有依赖并生成配置"
    echo "  2) 仅安装依赖 - 只安装构建依赖包"
    echo "  3) 仅生成配置 - 只生成配置文件和钩子脚本"
    echo "  4) 开始构建 - 直接开始构建过程"
    echo ""
}

# 获取用户选择
get_user_choice() {
    local choice
    read -p "请选择部署方式 [1-4]: " choice
    
    case $choice in
        1)
            DEPLOY_MODE="full"
            ;;
        2)
            DEPLOY_MODE="deps"
            ;;
        3)
            DEPLOY_MODE="config"
            ;;
        4)
            DEPLOY_MODE="build"
            ;;
        *)
            log_error "无效选择，使用默认完整部署"
            DEPLOY_MODE="full"
            ;;
    esac
    
    log_info "选择部署模式: $DEPLOY_MODE"
}

# 执行完整部署
execute_full_deployment() {
    log_info "执行完整部署..."
    
    # 创建项目结构
    create_project_structure
    
    # 下载或检查主脚本
    download_main_script
    
    # 运行主脚本生成配置
    local main_script="${SCRIPT_DIR}/radxa-kali-builder.sh"
    
    log_info "生成配置文件..."
    "$main_script" --config-only
    
    log_success "完整部署完成！"
}

# 执行依赖安装
execute_deps_install() {
    log_info "执行依赖安装..."
    install_build_dependencies
    setup_docker
    log_success "依赖安装完成！"
}

# 执行配置生成
execute_config_generation() {
    log_info "执行配置生成..."
    
    create_project_structure
    download_main_script
    
    local main_script="${SCRIPT_DIR}/radxa-kali-builder.sh"
    "$main_script" --config-only
    
    log_success "配置生成完成！"
}

# 执行构建
execute_build() {
    log_info "执行构建过程..."
    
    local main_script="${SCRIPT_DIR}/radxa-kali-builder.sh"
    
    if [[ ! -f "$main_script" ]]; then
        log_error "主构建脚本不存在"
        return 1
    fi
    
    log_info "开始完整构建过程..."
    log_warning "这可能需要几个小时，请耐心等待..."
    
    "$main_script"
    
    log_success "构建完成！"
}

# 显示完成信息
show_completion_info() {
    echo ""
    log_success "========================================"
    log_success "  部署完成！"
    log_success "========================================"
    echo ""
    
    case $DEPLOY_MODE in
        "full")
            log_info "下一步:"
            echo "  1. 运行构建: sudo ./radxa-kali-builder.sh"
            echo "  2. 查看日志: tail -f build.log"
            echo "  3. 检查输出: ls -la output/"
            ;;
        "deps")
            log_info "依赖安装完成，可以开始构建"
            echo "  运行: sudo ./radxa-kali-builder.sh"
            ;;
        "config")
            log_info "配置生成完成"
            echo "  查看配置: ls -la configs/ hooks/ package-lists/"
            ;;
        "build")
            log_info "构建完成"
            echo "  检查输出: ls -la output/"
            ;;
    esac
    
    echo ""
    log_info "更多信息请查看日志: $LOG_FILE"
}

# 主函数
main() {
    # 初始化日志
    echo "快速部署开始于: $(date)" > "$LOG_FILE"
    
    # 显示标题
    log_header
    
    # 检查root权限
    check_root
    
    # 显示系统信息
    show_system_info
    
    # 系统检查
    if ! check_network; then
        log_error "网络连接检查失败"
        exit 1
    fi
    
    if ! check_disk_space; then
        log_error "磁盘空间检查失败"
        exit 1
    fi
    
    check_memory
    
    if ! check_required_tools; then
        log_error "必需工具检查失败"
        exit 1
    fi
    
    # 显示部署选项
    show_deployment_options
    
    # 获取用户选择
    get_user_choice
    
    # 执行部署
    case $DEPLOY_MODE in
        "full")
            execute_full_deployment
            ;;
        "deps")
            execute_deps_install
            ;;
        "config")
            execute_config_generation
            ;;
        "build")
            execute_build
            ;;
    esac
    
    # 显示完成信息
    show_completion_info
    
    # 完成日志
    echo "快速部署结束于: $(date)" >> "$LOG_FILE"
}

# 显示帮助
show_help() {
    echo "Radxa Cubie A7Z Kali Linux 快速部署脚本"
    echo "作者: $VENDOR"
    echo "版本: $VERSION"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help      显示帮助信息"
    echo "  -v, --version   显示版本信息"
    echo "  --full          完整部署 (默认)"
    echo "  --deps          仅安装依赖"
    echo "  --config        仅生成配置"
    echo "  --build         直接开始构建"
    echo ""
    echo "示例:"
    echo "  sudo $0              # 交互式部署"
    echo "  sudo $0 --full       # 完整部署"
    echo "  sudo $0 --deps       # 仅安装依赖"
    echo "  sudo $0 --config     # 仅生成配置"
    echo "  sudo $0 --build      # 直接构建"
}

# 解析命令行参数
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "$PRODUCT $VERSION"
                exit 0
                ;;
            --full)
                DEPLOY_MODE="full"
                shift
                ;;
            --deps)
                DEPLOY_MODE="deps"
                shift
                ;;
            --config)
                DEPLOY_MODE="config"
                shift
                ;;
            --build)
                DEPLOY_MODE="build"
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    DEPLOY_MODE=""
    parse_arguments "$@"
    main
fi