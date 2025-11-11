#!/bin/bash

# 构建验证脚本
# build-validator.sh
# 验证Radxa Cubie A7Z Kali Linux构建系统的完整性和正确性

set -e

# 全局变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="/tmp/build-validator.log"
VALIDATION_REPORT="/tmp/validation-report.txt"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] [$level] $message"
    
    echo "$log_entry" | tee -a "$LOG_FILE"
    
    case $level in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
    esac
}

# 初始化验证报告
init_report() {
    cat > "$VALIDATION_REPORT" << EOF
# Radxa Cubie A7Z Kali Linux 构建验证报告
# 生成时间: $(date)
# 验证脚本: $0

## 验证摘要

EOF
}

# 添加验证结果到报告
add_to_report() {
    local test_name=$1
    local status=$2
    local details=$3
    
    echo "### $test_name" >> "$VALIDATION_REPORT"
    echo "状态: $status" >> "$VALIDATION_REPORT"
    echo "详情: $details" >> "$VALIDATION_REPORT"
    echo "" >> "$VALIDATION_REPORT"
}

# 验证项目结构
validate_project_structure() {
    log "INFO" "开始验证项目结构..."
    
    local required_dirs=(
        "configs"
        "configs/hooks"
        "package-lists"
        "scripts"
        "logs"
        "output"
        "cache"
    )
    
    local required_files=(
        "radxa-kali-builder.sh"
        "quick-deploy.sh"
        "configs/rootfs.jsonnet"
        "package-lists/kali-core.list"
        "package-lists/radxa-hardware.list"
        "package-lists/wayland-desktop.list"
        "package-lists/zsh-shell.list"
        "package-lists/waydroid.list"
    )
    
    local hooks=(
        "configs/hooks/9990-radxa-hardware-init.chroot"
        "configs/hooks/9991-waydroid-nokvm-setup.chroot"
        "configs/hooks/9992-kali-tools-config.chroot"
        "configs/hooks/9993-zsh-terminal-setup.chroot"
        "configs/hooks/9994-wayland-desktop-setup.chroot"
        "configs/hooks/9995-vendor-information.chroot"
    )
    
    local missing_items=()
    
    # 检查目录
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$PROJECT_ROOT/$dir" ]; then
            missing_items+=("目录: $dir")
        fi
    done
    
    # 检查文件
    for file in "${required_files[@]}"; do
        if [ ! -f "$PROJECT_ROOT/$file" ]; then
            missing_items+=("文件: $file")
        fi
    done
    
    # 检查钩子脚本
    for hook in "${hooks[@]}"; do
        if [ ! -f "$PROJECT_ROOT/$hook" ]; then
            missing_items+=("钩子脚本: $hook")
        fi
    done
    
    if [ ${#missing_items[@]} -eq 0 ]; then
        log "SUCCESS" "项目结构验证通过"
        add_to_report "项目结构" "通过" "所有必需的目录和文件都存在"
        return 0
    else
        log "ERROR" "项目结构验证失败，缺少以下项目:"
        for item in "${missing_items[@]}"; do
            log "ERROR" "  - $item"
        done
        add_to_report "项目结构" "失败" "缺少项目: ${missing_items[*]}"
        return 1
    fi
}

# 验证配置文件
validate_config_files() {
    log "INFO" "开始验证配置文件..."
    
    local config_file="$PROJECT_ROOT/configs/rootfs.jsonnet"
    
    if [ ! -f "$config_file" ]; then
        log "ERROR" "配置文件不存在: $config_file"
        add_to_report "配置文件" "失败" "配置文件不存在"
        return 1
    fi
    
    # 检查配置文件的关键字段
    local required_fields=(
        "architecture"
        "distribution"
        "vendor"
        "packages"
        "hooks"
        "vendor_info"
        "environment"
        "validation"
    )
    
    local missing_fields=()
    
    for field in "${required_fields[@]}"; do
        if ! grep -q "$field" "$config_file"; then
            missing_fields+=("$field")
        fi
    done
    
    if [ ${#missing_fields[@]} -eq 0 ]; then
        log "SUCCESS" "配置文件验证通过"
        add_to_report "配置文件" "通过" "所有必需字段都存在"
        return 0
    else
        log "ERROR" "配置文件验证失败，缺少字段: ${missing_fields[*]}"
        add_to_report "配置文件" "失败" "缺少字段: ${missing_fields[*]}"
        return 1
    fi
}

# 验证包列表文件
validate_package_lists() {
    log "INFO" "开始验证包列表文件..."
    
    local package_lists=(
        "kali-core.list"
        "radxa-hardware.list"
        "wayland-desktop.list"
        "zsh-shell.list"
        "waydroid.list"
    )
    
    local invalid_files=()
    
    for list_file in "${package_lists[@]}"; do
        local full_path="$PROJECT_ROOT/package-lists/$list_file"
        
        if [ ! -f "$full_path" ]; then
            invalid_files+=("$list_file (不存在)")
            continue
        fi
        
        # 检查文件格式
        if grep -q '^[[:space:]]*#' "$full_path" || grep -q '^[[:space:]]*$' "$full_path"; then
            # 文件包含注释或空行，这是允许的
            continue
        fi
        
        # 检查是否包含有效的包名
        local valid_packages=$(grep -c '^[a-zA-Z0-9+-]' "$full_path" 2>/dev/null || echo "0")
        if [ "$valid_packages" -eq 0 ]; then
            invalid_files+=("$list_file (无有效包名)")
        fi
    done
    
    if [ ${#invalid_files[@]} -eq 0 ]; then
        log "SUCCESS" "包列表文件验证通过"
        add_to_report "包列表文件" "通过" "所有包列表文件都有效"
        return 0
    else
        log "ERROR" "包列表文件验证失败:"
        for file in "${invalid_files[@]}"; do
            log "ERROR" "  - $file"
        done
        add_to_report "包列表文件" "失败" "无效文件: ${invalid_files[*]}"
        return 1
    fi
}

# 验证钩子脚本
validate_hook_scripts() {
    log "INFO" "开始验证钩子脚本..."
    
    local hooks_dir="$PROJECT_ROOT/configs/hooks"
    local hooks=($(find "$hooks_dir" -name "*.chroot" -type f 2>/dev/null || true))
    
    if [ ${#hooks[@]} -eq 0 ]; then
        log "ERROR" "未找到任何钩子脚本"
        add_to_report "钩子脚本" "失败" "未找到钩子脚本"
        return 1
    fi
    
    local invalid_hooks=()
    
    for hook in "${hooks[@]}"; do
        local hook_name=$(basename "$hook")
        
        # 检查shebang
        if ! head -1 "$hook" | grep -q '^#!/bin/bash'; then
            invalid_hooks+=("$hook_name (缺少bash shebang)")
            continue
        fi
        
        # 检查set -e
        if ! grep -q 'set -e' "$hook"; then
            invalid_hooks+=("$hook_name (缺少set -e)")
            continue
        fi
        
        # 检查日志函数
        if ! grep -q 'log()' "$hook"; then
            invalid_hooks+=("$hook_name (缺少日志函数)")
            continue
        fi
        
        # 检查执行权限
        if [ ! -x "$hook" ]; then
            invalid_hooks+=("$hook_name (缺少执行权限)")
            continue
        fi
    done
    
    if [ ${#invalid_hooks[@]} -eq 0 ]; then
        log "SUCCESS" "钩子脚本验证通过，共找到 ${#hooks[@]} 个钩子脚本"
        add_to_report "钩子脚本" "通过" "找到 ${#hooks[@]} 个有效钩子脚本"
        return 0
    else
        log "ERROR" "钩子脚本验证失败:"
        for hook in "${invalid_hooks[@]}"; do
            log "ERROR" "  - $hook"
        done
        add_to_report "钩子脚本" "失败" "无效钩子: ${invalid_hooks[*]}"
        return 1
    fi
}

# 验证主构建脚本
validate_main_builder() {
    log "INFO" "开始验证主构建脚本..."
    
    local builder_script="$PROJECT_ROOT/radxa-kali-builder.sh"
    
    if [ ! -f "$builder_script" ]; then
        log "ERROR" "主构建脚本不存在: $builder_script"
        add_to_report "主构建脚本" "失败" "脚本不存在"
        return 1
    fi
    
    # 检查基本结构
    local checks=(
        "shebang:#!/bin/bash"
        "set_e:set -e"
        "functions:function"
        "logging:log()"
        "error_handling:trap"
        "main_function:main()"
    )
    
    local missing_checks=()
    
    for check in "${checks[@]}"; do
        local name=$(echo "$check" | cut -d':' -f1)
        local pattern=$(echo "$check" | cut -d':' -f2)
        
        if ! grep -q "$pattern" "$builder_script"; then
            missing_checks+=("$name")
        fi
    done
    
    if [ ${#missing_checks[@]} -eq 0 ]; then
        log "SUCCESS" "主构建脚本验证通过"
        add_to_report "主构建脚本" "通过" "基本结构完整"
        return 0
    else
        log "ERROR" "主构建脚本验证失败，缺少: ${missing_checks[*]}"
        add_to_report "主构建脚本" "失败" "缺少: ${missing_checks[*]}"
        return 1
    fi
}

# 验证快速部署脚本
validate_quick_deploy() {
    log "INFO" "开始验证快速部署脚本..."
    
    local deploy_script="$PROJECT_ROOT/quick-deploy.sh"
    
    if [ ! -f "$deploy_script" ]; then
        log "ERROR" "快速部署脚本不存在: $deploy_script"
        add_to_report "快速部署脚本" "失败" "脚本不存在"
        return 1
    fi
    
    # 检查关键功能
    local required_functions=(
        "check_root"
        "check_dependencies"
        "install_dependencies"
        "setup_environment"
        "run_builder"
        "main"
    )
    
    local missing_functions=()
    
    for func in "${required_functions[@]}"; do
        if ! grep -q "$func()" "$deploy_script"; then
            missing_functions+=("$func")
        fi
    done
    
    if [ ${#missing_functions[@]} -eq 0 ]; then
        log "SUCCESS" "快速部署脚本验证通过"
        add_to_report "快速部署脚本" "通过" "所有必需函数都存在"
        return 0
    else
        log "ERROR" "快速部署脚本验证失败，缺少函数: ${missing_functions[*]}"
        add_to_report "快速部署脚本" "失败" "缺少函数: ${missing_functions[*]}"
        return 1
    fi
}

# 验证依赖关系
validate_dependencies() {
    log "INFO" "开始验证依赖关系..."
    
    # 检查系统工具
    local required_tools=(
        "bash"
        "grep"
        "sed"
        "awk"
        "find"
        "curl"
        "wget"
        "tar"
        "gzip"
        "jq"
        "jsonnet"
    )
    
    local missing_tools=()
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -eq 0 ]; then
        log "SUCCESS" "依赖关系验证通过"
        add_to_report "依赖关系" "通过" "所有必需工具都可用"
        return 0
    else
        log "WARNING" "依赖关系验证警告，缺少工具: ${missing_tools[*]}"
        add_to_report "依赖关系" "警告" "缺少工具: ${missing_tools[*]}"
        return 0  # 警告级别，不中断验证
    fi
}

# 验证安全性
validate_security() {
    log "INFO" "开始验证安全性..."
    
    local security_issues=()
    
    # 检查脚本中的硬编码密码
    if grep -r "password.*=" "$PROJECT_ROOT"/*.sh 2>/dev/null | grep -v "example\|test\|demo"; then
        security_issues+=("发现硬编码密码")
    fi
    
    # 检查不安全的curl/wget使用
    if grep -r "curl.*-k\|wget.*--no-check-certificate" "$PROJECT_ROOT"/*.sh 2>/dev/null; then
        security_issues+=("发现不安全的SSL/TLS配置")
    fi
    
    # 检查setuid/setgid设置
    if grep -r "chmod.*[47][57][57]" "$PROJECT_ROOT"/*.sh 2>/dev/null; then
        security_issues+=("发现过度权限设置")
    fi
    
    if [ ${#security_issues[@]} -eq 0 ]; then
        log "SUCCESS" "安全性验证通过"
        add_to_report "安全性" "通过" "未发现安全问题"
        return 0
    else
        log "WARNING" "安全性验证发现以下问题:"
        for issue in "${security_issues[@]}"; do
            log "WARNING" "  - $issue"
        done
        add_to_report "安全性" "警告" "发现安全问题: ${security_issues[*]}"
        return 0  # 警告级别，不中断验证
    fi
}

# 生成最终报告
generate_final_report() {
    local total_tests=$1
    local passed_tests=$2
    local failed_tests=$3
    local warning_tests=$4
    
    cat >> "$VALIDATION_REPORT" << EOF
## 验证统计

- 总测试数: $total_tests
- 通过测试: $passed_tests
- 失败测试: $failed_tests
- 警告测试: $warning_tests

## 验证结果

EOF
    
    if [ "$failed_tests" -eq 0 ]; then
        if [ "$warning_tests" -eq 0 ]; then
            echo "✅ **验证通过** - 所有测试都通过" >> "$VALIDATION_REPORT"
        else
            echo "⚠️ **验证通过但有警告** - 所有必需测试通过，但有警告" >> "$VALIDATION_REPORT"
        fi
    else
        echo "❌ **验证失败** - 有 $failed_tests 个测试失败" >> "$VALIDATION_REPORT"
    fi
    
    cat >> "$VALIDATION_REPORT" << EOF

## 建议

EOF
    
    if [ "$failed_tests" -gt 0 ]; then
        echo "1. 修复失败的测试项目" >> "$VALIDATION_REPORT"
        echo "2. 重新运行验证脚本" >> "$VALIDATION_REPORT"
    fi
    
    if [ "$warning_tests" -gt 0 ]; then
        echo "3. 考虑处理警告项目" >> "$VALIDATION_REPORT"
    fi
    
    echo "4. 在生产环境使用前进行充分测试" >> "$VALIDATION_REPORT"
    echo "5. 定期更新和维护构建系统" >> "$VALIDATION_REPORT"
    
    cat >> "$VALIDATION_REPORT" << EOF

---
*验证报告生成时间: $(date)*
*验证脚本版本: 1.0.0*
EOF
}

# 主验证函数
main() {
    log "INFO" "开始Radxa Cubie A7Z Kali Linux构建系统验证..."
    log "INFO" "项目根目录: $PROJECT_ROOT"
    log "INFO" "日志文件: $LOG_FILE"
    log "INFO" "验证报告: $VALIDATION_REPORT"
    
    # 初始化报告
    init_report
    
    # 验证测试
    local tests=(
        "validate_project_structure"
        "validate_config_files"
        "validate_package_lists"
        "validate_hook_scripts"
        "validate_main_builder"
        "validate_quick_deploy"
        "validate_dependencies"
        "validate_security"
    )
    
    local total_tests=${#tests[@]}
    local passed_tests=0
    local failed_tests=0
    local warning_tests=0
    
    for test_func in "${tests[@]}"; do
        log "INFO" "执行测试: $test_func"
        
        if $test_func; then
            ((passed_tests++))
        else
            if [ "$test_func" = "validate_dependencies" ] || [ "$test_func" = "validate_security" ]; then
                ((warning_tests++)
            else
                ((failed_tests++))
            fi
        fi
        
        echo  # 空行分隔
    done
    
    # 生成最终报告
    generate_final_report $total_tests $passed_tests $failed_tests $warning_tests
    
    log "INFO" "验证完成！"
    log "INFO" "总测试数: $total_tests"
    log "INFO" "通过测试: $passed_tests"
    log "INFO" "失败测试: $failed_tests"
    log "INFO" "警告测试: $warning_tests"
    log "INFO" "详细报告: $VALIDATION_REPORT"
    
    if [ "$failed_tests" -eq 0 ]; then
        log "SUCCESS" "构建系统验证通过！"
        return 0
    else
        log "ERROR" "构建系统验证失败！"
        return 1
    fi
}

# 脚本入口
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi