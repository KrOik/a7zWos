#!/bin/bash

# 安全工具功能测试脚本
# security-test.sh
# 测试Kali Linux安全工具的功能完整性和可用性

set -e

# 全局变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="/tmp/security-test.log"
TEST_REPORT="/tmp/security-test-report.txt"

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

# 初始化测试报告
init_report() {
    cat > "$TEST_REPORT" << EOF
# Kali Linux 安全工具功能测试报告
# 生成时间: $(date)
# 测试脚本: $0

## 测试环境

- 主机名: $(hostname)
- 内核版本: $(uname -r)
- 架构: $(uname -m)
- 发行版: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")
- 测试时间: $(date)

## 系统信息

EOF
    
    # 收集系统信息
    if command -v whoami >/dev/null 2>&1; then
        echo "当前用户: $(whoami)" >> "$TEST_REPORT"
    fi
    
    if command -v id >/dev/null 2>&1; then
        echo "用户ID: $(id)" >> "$TEST_REPORT"
    fi
    
    echo "PATH: $PATH" >> "$TEST_REPORT"
    echo "" >> "$TEST_REPORT"
}

# 添加测试结果到报告
add_test_result() {
    local test_name=$1
    local status=$2
    local details=$3
    local duration=$4
    
    echo "### $test_name" >> "$TEST_REPORT"
    echo "状态: $status" >> "$TEST_REPORT"
    echo "详情: $details" >> "$TEST_REPORT"
    if [ -n "$duration" ]; then
        echo "耗时: $duration 秒" >> "$TEST_REPORT"
    fi
    echo "" >> "$TEST_REPORT"
}

# 测试信息收集工具
test_information_gathering() {
    log "INFO" "开始测试信息收集工具..."
    local start_time=$(date +%s)
    
    local tools=(
        "nmap:网络扫描工具"
        "masscan:高速端口扫描器"
        "amap:应用协议检测"
        "ike-scan:IKE扫描器"
        "legion:网络枚举工具"
        "netdiscover:网络发现"
        "recon-ng:Web侦察框架"
        "spiderfoot:OSINT工具"
        "theharvester:邮箱和子域名收集"
        "dnsrecon:DNS枚举"
        "dnsenum:DNS枚举"
        "fierce:DNS暴力破解"
        "gobuster:目录和文件爆破"
        "dirb:Web内容扫描器"
        "dirbuster:Web目录暴力破解"
        "whatweb:Web技术识别"
        "wig:Web应用识别"
        "wappalyzer:Web技术检测"
        "eyewitness:Web截图工具"
    )
    
    local available_tools=()
    local missing_tools=()
    
    for tool_info in "${tools[@]}"; do
        local tool_name=$(echo "$tool_info" | cut -d':' -f1)
        local tool_desc=$(echo "$tool_info" | cut -d':' -f2)
        
        if command -v "$tool_name" >/dev/null 2>&1; then
            available_tools+=("$tool_name ($tool_desc)")
            log "SUCCESS" "发现工具: $tool_name - $tool_desc"
        else
            missing_tools+=("$tool_name ($tool_desc)")
            log "WARNING" "缺少工具: $tool_name - $tool_desc"
        fi
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local total_tools=${#tools[@]}
    local available_count=${#available_tools[@]}
    local missing_count=${#missing_tools[@]}
    
    if [ "$available_count" -gt 0 ]; then
        log "SUCCESS" "信息收集工具测试完成: $available_count/$total_tools 个工具可用"
        add_test_result "信息收集工具" "通过" "可用工具: $available_count/$total_tools, 可用: ${available_tools[*]}, 缺少: ${missing_tools[*]}" "$duration"
        return 0
    else
        log "ERROR" "信息收集工具测试失败: 无工具可用"
        add_test_result "信息收集工具" "失败" "无工具可用，缺少: ${missing_tools[*]}" "$duration"
        return 1
    fi
}

# 测试漏洞分析工具
test_vulnerability_analysis() {
    log "INFO" "开始测试漏洞分析工具..."
    local start_time=$(date +%s)
    
    local tools=(
        "nikto:Web漏洞扫描器"
        "skipfish:Web应用安全扫描器"
        "uniscan:Web漏洞扫描器"
        "wapiti:Web应用漏洞扫描器"
        "webscarab:Web应用分析工具"
        "burpsuite:Web代理和扫描器"
        "owasp-zap:Web应用安全扫描器"
        "openvas:漏洞评估系统"
        "nessus:漏洞扫描器"
        "lynis:安全审计工具"
        "unix-privesc-check:权限提升检查"
        "linux-exploit-suggester:漏洞利用建议"
        "linux-smart-enumeration:Linux枚举工具"
        "pspy:进程监控"
        "strace:系统调用跟踪"
        "ltrace:库调用跟踪"
    )
    
    local available_tools=()
    local missing_tools=()
    
    for tool_info in "${tools[@]}"; do
        local tool_name=$(echo "$tool_info" | cut -d':' -f1)
        local tool_desc=$(echo "$tool_info" | cut -d':' -f2)
        
        if command -v "$tool_name" >/dev/null 2>&1; then
            available_tools+=("$tool_name ($tool_desc)")
            log "SUCCESS" "发现工具: $tool_name - $tool_desc"
        else
            missing_tools+=("$tool_name ($tool_desc)")
            log "WARNING" "缺少工具: $tool_name - $tool_desc"
        fi
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local total_tools=${#tools[@]}
    local available_count=${#available_tools[@]}
    local missing_count=${#missing_tools[@]}
    
    if [ "$available_count" -gt 0 ]; then
        log "SUCCESS" "漏洞分析工具测试完成: $available_count/$total_tools 个工具可用"
        add_test_result "漏洞分析工具" "通过" "可用工具: $available_count/$total_tools, 可用: ${available_tools[*]}, 缺少: ${missing_tools[*]}" "$duration"
        return 0
    else
        log "ERROR" "漏洞分析工具测试失败: 无工具可用"
        add_test_result "漏洞分析工具" "失败" "无工具可用，缺少: ${missing_tools[*]}" "$duration"
        return 1
    fi
}

# 测试Web应用工具
test_web_application_tools() {
    log "INFO" "开始测试Web应用工具..."
    local start_time=$(date +%s)
    
    local tools=(
        "sqlmap:SQL注入工具"
        "commix:命令注入工具"
        "xsstrike:XSS检测工具"
        "xsser:XSS测试框架"
        "dalfox:现代XSS扫描器"
        "corsy:CORS配置检测"
        "whatweb:Web技术识别"
        "wig:Web应用识别"
        "eyewitness:Web截图工具"
        "photon:Web爬虫"
        "hakrawler:Web爬虫"
        "gospider:Web爬虫"
        "waybackurls:Wayback Machine URL提取"
        "gau:Get All URLs"
        "httpx:HTTP探测工具"
        "httprobe:HTTP探测工具"
        "subfinder:子域名发现"
        "assetfinder:子域名发现"
        "sublist3r:子域名枚举"
        "amass:攻击面映射"
        "massdns:DNS解析工具"
    )
    
    local available_tools=()
    local missing_tools=()
    
    for tool_info in "${tools[@]}"; do
        local tool_name=$(echo "$tool_info" | cut -d':' -f1)
        local tool_desc=$(echo "$tool_info" | cut -d':' -f2)
        
        if command -v "$tool_name" >/dev/null 2>&1; then
            available_tools+=("$tool_name ($tool_desc)")
            log "SUCCESS" "发现工具: $tool_name - $tool_desc"
        else
            missing_tools+=("$tool_name ($tool_desc)")
            log "WARNING" "缺少工具: $tool_name - $tool_desc"
        fi
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local total_tools=${#tools[@]}
    local available_count=${#available_tools[@]}
    local missing_count=${#missing_tools[@]}
    
    if [ "$available_count" -gt 0 ]; then
        log "SUCCESS" "Web应用工具测试完成: $available_count/$total_tools 个工具可用"
        add_test_result "Web应用工具" "通过" "可用工具: $available_count/$total_tools, 可用: ${available_tools[*]}, 缺少: ${missing_tools[*]}" "$duration"
        return 0
    else
        log "ERROR" "Web应用工具测试失败: 无工具可用"
        add_test_result "Web应用工具" "失败" "无工具可用，缺少: ${missing_tools[*]}" "$duration"
        return 1
    fi
}

# 测试无线安全工具
test_wireless_security_tools() {
    log "INFO" "开始测试无线安全工具..."
    local start_time=$(date +%s)
    
    local tools=(
        "aircrack-ng:WEP/WPA破解套件"
        "airmon-ng:无线接口管理"
        "airodump-ng:无线数据包捕获"
        "aireplay-ng:无线数据包注入"
        "airbase-ng:伪造AP"
        "airdecloak-ng:去除WEP cloaking"
        "airdriver-ng:无线驱动管理"
        "aircrack-ng:WEP/WPA密钥破解"
        "airdecap-ng:WEP/WPA解密"
        "airserv-ng:无线数据包服务器"
        "buddy-ng:WEP攻击工具"
        "easside-ng:自动WEP攻击"
        "tkiptun-ng:TKIP攻击"
        "wesside-ng:自动WEP攻击"
        "fern-wifi-cracker:WiFi破解工具"
        "wifite:自动化WiFi破解"
        "reaver:WPS攻击工具"
        "bully:WPS攻击工具"
        "cowpatty:WPA-PSK破解"
        "hashcat:密码破解工具"
        "john:密码破解工具"
    )
    
    local available_tools=()
    local missing_tools=()
    
    for tool_info in "${tools[@]}"; do
        local tool_name=$(echo "$tool_info" | cut -d':' -f1)
        local tool_desc=$(echo "$tool_info" | cut -d':' -f2)
        
        if command -v "$tool_name" >/dev/null 2>&1; then
            available_tools+=("$tool_name ($tool_desc)")
            log "SUCCESS" "发现工具: $tool_name - $tool_desc"
        else
            missing_tools+=("$tool_name ($tool_desc)")
            log "WARNING" "缺少工具: $tool_name - $tool_desc"
        fi
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local total_tools=${#tools[@]}
    local available_count=${#available_tools[@]}
    local missing_count=${#missing_tools[@]}
    
    if [ "$available_count" -gt 0 ]; then
        log "SUCCESS" "无线安全工具测试完成: $available_count/$total_tools 个工具可用"
        add_test_result "无线安全工具" "通过" "可用工具: $available_count/$total_tools, 可用: ${available_tools[*]}, 缺少: ${missing_tools[*]}" "$duration"
        return 0
    else
        log "ERROR" "无线安全工具测试失败: 无工具可用"
        add_test_result "无线安全工具" "失败" "无工具可用，缺少: ${missing_tools[*]}" "$duration"
        return 1
    fi
}

# 测试后渗透工具
test_post_exploitation_tools() {
    log "INFO" "开始测试后渗透工具..."
    local start_time=$(date +%s)
    
    local tools=(
        "metasploit-framework:渗透测试框架"
        "empire:PowerShell后期利用框架"
        "covenant:.NET后期利用框架"
        "sliver:通用后期利用框架"
        "cobalt-strike:商业后期利用框架"
        "powersploit:PowerShell后期利用"
        "nishang:PowerShell攻击脚本"
        "bloodhound:Active Directory侦察"
        "sharphound:BloodHound数据收集器"
        "impacket:网络协议工具包"
        "crackmapexec:后期利用工具"
        "proxychains:代理工具"
        "nmap:网络扫描和发现"
        "netcat:网络瑞士军刀"
        "socat:多用途中继工具"
        "nishang:PowerShell攻击框架"
        "powercat:PowerShell版netcat"
        "mimikatz:Windows凭据提取"
        "secretsdump:凭据转储工具"
        "hashcat:密码破解工具"
        "john:密码破解工具"
    )
    
    local available_tools=()
    local missing_tools=()
    
    for tool_info in "${tools[@]}"; do
        local tool_name=$(echo "$tool_info" | cut -d':' -f1)
        local tool_desc=$(echo "$tool_info" | cut -d':' -f2)
        
        if command -v "$tool_name" >/dev/null 2>&1; then
            available_tools+=("$tool_name ($tool_desc)")
            log "SUCCESS" "发现工具: $tool_name - $tool_desc"
        else
            missing_tools+=("$tool_name ($tool_desc)")
            log "WARNING" "缺少工具: $tool_name - $tool_desc"
        fi
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local total_tools=${#tools[@]}
    local available_count=${#available_tools[@]}
    local missing_count=${#missing_tools[@]}
    
    if [ "$available_count" -gt 0 ]; then
        log "SUCCESS" "后渗透工具测试完成: $available_count/$total_tools 个工具可用"
        add_test_result "后渗透工具" "通过" "可用工具: $available_count/$total_tools, 可用: ${available_tools[*]}, 缺少: ${missing_tools[*]}" "$duration"
        return 0
    else
        log "ERROR" "后渗透工具测试失败: 无工具可用"
        add_test_result "后渗透工具" "失败" "无工具可用，缺少: ${missing_tools[*]}" "$duration"
        return 1
    fi
}

# 测试网络工具
test_network_tools() {
    log "INFO" "开始测试网络工具..."
    local start_time=$(date +%s)
    
    local tools=(
        "wireshark:网络协议分析器"
        "tshark:命令行网络分析器"
        "tcpdump:网络数据包分析器"
        "netcat:网络瑞士军刀"
        "socat:多用途中继工具"
        "hping3:网络扫描和包生成器"
        "nping:网络包生成器"
        "scapy:交互式数据包操作"
        "nmap:网络发现和安全审计"
        "masscan:高速端口扫描器"
        "zmap:互联网扫描器"
        "unicornscan:异步网络扫描器"
        "mtr:网络诊断工具"
        "traceroute:路由跟踪"
        "tracepath:路径MTU发现"
        "iftop:网络带宽监控"
        "nload:网络负载监控"
        "vnstat:网络流量监控"
        "darkstat:网络流量分析器"
        "bandwhich:终端网络监控"
        "nethogs:网络流量监控"
    )
    
    local available_tools=()
    local missing_tools=()
    
    for tool_info in "${tools[@]}"; do
        local tool_name=$(echo "$tool_info" | cut -d':' -f1)
        local tool_desc=$(echo "$tool_info" | cut -d':' -f2)
        
        if command -v "$tool_name" >/dev/null 2>&1; then
            available_tools+=("$tool_name ($tool_desc)")
            log "SUCCESS" "发现工具: $tool_name - $tool_desc"
        else
            missing_tools+=("$tool_name ($tool_desc)")
            log "WARNING" "缺少工具: $tool_name - $tool_desc"
        fi
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local total_tools=${#tools[@]}
    local available_count=${#available_tools[@]}
    local missing_count=${#missing_tools[@]}
    
    if [ "$available_count" -gt 0 ]; then
        log "SUCCESS" "网络工具测试完成: $available_count/$total_tools 个工具可用"
        add_test_result "网络工具" "通过" "可用工具: $available_count/$total_tools, 可用: ${available_tools[*]}, 缺少: ${missing_tools[*]}" "$duration"
        return 0
    else
        log "ERROR" "网络工具测试失败: 无工具可用"
        add_test_result "网络工具" "失败" "无工具可用，缺少: ${missing_tools[*]}" "$duration"
        return 1
    fi
}

# 测试密码破解工具
test_password_cracking_tools() {
    log "INFO" "开始测试密码破解工具..."
    local start_time=$(date +%s)
    
    local tools=(
        "hashcat:高级密码破解"
        "john:John the Ripper"
        "rainbowcrack:彩虹表破解"
        "crunch:密码列表生成器"
        "wordlistctl:密码列表管理"
        "cewl:自定义单词列表生成器"
        "rsmangler:单词列表变形工具"
        "wyd:从目标中提取单词"
        "cupp:通用用户密码分析器"
        "wordlist:密码列表工具"
        "hashid:哈希类型识别"
        "hash-identifier:哈希类型识别"
        "findmyhash:在线哈希破解"
        "medusa:网络登录暴力破解"
        "hydra:网络登录暴力破解"
        "ncrack:高速网络认证破解"
        "patator:多协议暴力破解"
        "brutespray:暴力破解工具"
        "crowbar:SSH暴力破解"
        "seclists:安全测试列表"
    )
    
    local available_tools=()
    local missing_tools=()
    
    for tool_info in "${tools[@]}"; do
        local tool_name=$(echo "$tool_info" | cut -d':' -f1)
        local tool_desc=$(echo "$tool_info" | cut -d':' -f2)
        
        if command -v "$tool_name" >/dev/null 2>&1; then
            available_tools+=("$tool_name ($tool_desc)")
            log "SUCCESS" "发现工具: $tool_name - $tool_desc"
        else
            missing_tools+=("$tool_name ($tool_desc)")
            log "WARNING" "缺少工具: $tool_name - $tool_desc"
        fi
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local total_tools=${#tools[@]}
    local available_count=${#available_tools[@]}
    local missing_count=${#missing_tools[@]}
    
    if [ "$available_count" -gt 0 ]; then
        log "SUCCESS" "密码破解工具测试完成: $available_count/$total_tools 个工具可用"
        add_test_result "密码破解工具" "通过" "可用工具: $available_count/$total_tools, 可用: ${available_tools[*]}, 缺少: ${missing_tools[*]}" "$duration"
        return 0
    else
        log "ERROR" "密码破解工具测试失败: 无工具可用"
        add_test_result "密码破解工具" "失败" "无工具可用，缺少: ${missing_tools[*]}" "$duration"
        return 1
    fi
}

# 测试逆向工程工具
test_reverse_engineering_tools() {
    log "INFO" "开始测试逆向工程工具..."
    local start_time=$(date +%s)
    
    local tools=(
        "radare2:逆向工程框架"
        "rabin2:二进制分析工具"
        "rasm2:汇编和反汇编"
        "rahash2:哈希计算工具"
        "radiff2:二进制比较"
        "ragg2:二进制生成器"
        "rarun2:程序执行工具"
        "rax2:表达式计算器"
        "gdb:GNU调试器"
        "gdb-peda:Python调试助手"
        "gdb-gef:高级调试环境"
        "strace:系统调用跟踪"
        "ltrace:库调用跟踪"
        "objdump:目标文件分析"
        "readelf:ELF文件分析"
        "nm:符号表工具"
        "strings:字符串提取"
        "hexdump:十六进制查看器"
        "xxd:十六进制编辑器"
        "binwalk:固件分析工具"
        "firmware-mod-kit:固件修改工具"
        "hashdeep:哈希深度分析"
        "foremost:文件恢复工具"
        "scalpel:文件雕刻工具"
        "bulk-extractor:数字取证工具"
    )
    
    local available_tools=()
    local missing_tools=()
    
    for tool_info in "${tools[@]}"; do
        local tool_name=$(echo "$tool_info" | cut -d':' -f1)
        local tool_desc=$(echo "$tool_info" | cut -d':' -f2)
        
        if command -v "$tool_name" >/dev/null 2>&1; then
            available_tools+=("$tool_name ($tool_desc)")
            log "SUCCESS" "发现工具: $tool_name - $tool_desc"
        else
            missing_tools+=("$tool_name ($tool_desc)")
            log "WARNING" "缺少工具: $tool_name - $tool_desc"
        fi
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local total_tools=${#tools[@]}
    local available_count=${#available_tools[@]}
    local missing_count=${#missing_tools[@]}
    
    if [ "$available_count" -gt 0 ]; then
        log "SUCCESS" "逆向工程工具测试完成: $available_count/$total_tools 个工具可用"
        add_test_result "逆向工程工具" "通过" "可用工具: $available_count/$total_tools, 可用: ${available_tools[*]}, 缺少: ${missing_tools[*]}" "$duration"
        return 0
    else
        log "ERROR" "逆向工程工具测试失败: 无工具可用"
        add_test_result "逆向工程工具" "失败" "无工具可用，缺少: ${missing_tools[*]}" "$duration"
        return 1
    fi
}

# 测试系统工具
test_system_tools() {
    log "INFO" "开始测试系统工具..."
    local start_time=$(date +%s)
    
    local tools=(
        "sudo:权限提升工具"
        "curl:数据传输工具"
        "wget:文件下载工具"
        "git:版本控制系统"
        "vim:文本编辑器"
        "nano:文本编辑器"
        "htop:交互式进程查看器"
        "tree:目录树显示"
        "ncdu:磁盘使用分析器"
        "tmux:终端复用器"
        "screen:终端复用器"
        "ssh:安全外壳协议"
        "scp:安全文件传输"
        "rsync:文件同步工具"
        "tar:归档工具"
        "gzip:压缩工具"
        "zip:压缩工具"
        "unzip:解压缩工具"
        "jq:JSON处理器"
        "python3:Python解释器"
        "python2:Python 2解释器"
        "ruby:Ruby解释器"
        "perl:Perl解释器"
        "bash:Bourne Again Shell"
        "zsh:Z Shell"
        "fish:Friendly Interactive Shell"
    )
    
    local available_tools=()
    local missing_tools=()
    
    for tool_info in "${tools[@]}"; do
        local tool_name=$(echo "$tool_info" | cut -d':' -f1)
        local tool_desc=$(echo "$tool_info" | cut -d':' -f2)
        
        if command -v "$tool_name" >/dev/null 2>&1; then
            available_tools+=("$tool_name ($tool_desc)")
            log "SUCCESS" "发现工具: $tool_name - $tool_desc"
        else
            missing_tools+=("$tool_name ($tool_desc)")
            log "WARNING" "缺少工具: $tool_name - $tool_desc"
        fi
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local total_tools=${#tools[@]}
    local available_count=${#available_tools[@]}
    local missing_count=${#missing_tools[@]}
    
    if [ "$available_count" -gt 0 ]; then
        log "SUCCESS" "系统工具测试完成: $available_count/$total_tools 个工具可用"
        add_test_result "系统工具" "通过" "可用工具: $available_count/$total_tools, 可用: ${available_tools[*]}, 缺少: ${missing_tools[*]}" "$duration"
        return 0
    else
        log "ERROR" "系统工具测试失败: 无工具可用"
        add_test_result "系统工具" "失败" "无工具可用，缺少: ${missing_tools[*]}" "$duration"
        return 1
    fi
}

# 测试Metasploit框架
test_metasploit_framework() {
    log "INFO" "开始测试Metasploit框架..."
    local start_time=$(date +%s)
    
    # 检查msfconsole
    if command -v msfconsole >/dev/null 2>&1; then
        log "SUCCESS" "发现msfconsole"
        
        # 检查Metasploit数据库
        if command -v msfdb >/dev/null 2>&1; then
            log "SUCCESS" "发现msfdb数据库工具"
            
            # 检查数据库状态
            local db_status=$(msfdb status 2>/dev/null | grep -E "Database|PostgreSQL" | head -1 || echo "unknown")
            
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            log "SUCCESS" "Metasploit框架测试通过: 数据库状态 - $db_status"
            add_test_result "Metasploit框架" "通过" "msfconsole可用, msfdb可用, 数据库状态: $db_status" "$duration"
            return 0
        else
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            log "WARNING" "Metasploit框架测试警告: 缺少msfdb数据库工具"
            add_test_result "Metasploit框架" "警告" "msfconsole可用, 但缺少msfdb数据库工具" "$duration"
            return 0
        fi
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log "ERROR" "Metasploit框架测试失败: 缺少msfconsole"
        add_test_result "Metasploit框架" "失败" "缺少msfconsole" "$duration"
        return 1
    fi
}

# 测试工具配置
test_tool_configurations() {
    log "INFO" "开始测试工具配置..."
    local start_time=$(date +%s)
    
    local config_issues=()
    local config_success=()
    
    # 检查Nmap脚本数据库
    if command -v nmap >/dev/null 2>&1; then
        if [ -d /usr/share/nmap/scripts ]; then
            local nmap_scripts=$(ls /usr/share/nmap/scripts/*.nse 2>/dev/null | wc -l)
            if [ "$nmap_scripts" -gt 0 ]; then
                config_success+=("Nmap脚本数据库: $nmap_scripts个脚本")
                log "SUCCESS" "Nmap脚本数据库正常: $nmap_scripts个脚本"
            else
                config_issues+=("Nmap脚本数据库: 无脚本文件")
                log "WARNING" "Nmap脚本数据库问题: 无脚本文件"
            fi
        else
            config_issues+=("Nmap脚本目录不存在")
            log "WARNING" "Nmap脚本目录不存在"
        fi
    fi
    
    # 检查Metasploit模块
    if command -v msfconsole >/dev/null 2>&1; then
        if [ -d /usr/share/metasploit-framework/modules ]; then
            local msf_modules=$(find /usr/share/metasploit-framework/modules -name "*.rb" 2>/dev/null | wc -l)
            if [ "$msf_modules" -gt 0 ]; then
                config_success+=("Metasploit模块: $msf_modules个模块")
                log "SUCCESS" "Metasploit模块正常: $msf_modules个模块"
            else
                config_issues+=("Metasploit模块: 无模块文件")
                log "WARNING" "Metasploit模块问题: 无模块文件"
            fi
        else
            config_issues+=("Metasploit模块目录不存在")
            log "WARNING" "Metasploit模块目录不存在"
        fi
    fi
    
    # 检查Wordlists
    if [ -d /usr/share/wordlists ]; then
        local wordlists=$(find /usr/share/wordlists -type f 2>/dev/null | wc -l)
        if [ "$wordlists" -gt 0 ]; then
            config_success+=("密码列表: $wordlists个文件")
            log "SUCCESS" "密码列表正常: $wordlists个文件"
        else
            config_issues+=("密码列表: 无文件")
            log "WARNING" "密码列表问题: 无文件"
        fi
    else
        config_issues+=("密码列表目录不存在")
        log "WARNING" "密码列表目录不存在"
    fi
    
    # 检查SecLists
    if [ -d /usr/share/seclists ]; then
        local seclists_files=$(find /usr/share/seclists -type f 2>/dev/null | wc -l)
        if [ "$seclists_files" -gt 0 ]; then
            config_success+=("SecLists: $seclists_files个文件")
            log "SUCCESS" "SecLists正常: $seclists_files个文件"
        else
            config_issues+=("SecLists: 无文件")
            log "WARNING" "SecLists问题: 无文件"
        fi
    else
        config_issues+=("SecLists目录不存在")
        log "WARNING" "SecLists目录不存在"
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [ ${#config_issues[@]} -eq 0 ]; then
        log "SUCCESS" "工具配置测试通过: 所有配置正常"
        add_test_result "工具配置" "通过" "所有配置正常: ${config_success[*]}" "$duration"
        return 0
    else
        log "WARNING" "工具配置测试警告: 发现配置问题"
        add_test_result "工具配置" "警告" "配置问题: ${config_issues[*]}, 正常配置: ${config_success[*]}" "$duration"
        return 0
    fi
}

# 生成最终报告
generate_final_report() {
    local total_tests=$1
    local passed_tests=$2
    local failed_tests=$3
    local warning_tests=$4
    
    cat >> "$TEST_REPORT" << EOF

## 测试统计

- 总测试数: $total_tests
- 通过测试: $passed_tests
- 失败测试: $failed_tests
- 警告测试: $warning_tests

## 测试结论

EOF
    
    if [ "$failed_tests" -eq 0 ]; then
        if [ "$warning_tests" -eq 0 ]; then
            echo "✅ **安全工具功能测试通过** - 所有测试都通过" >> "$TEST_REPORT"
        else
            echo "⚠️ **安全工具功能测试通过但有警告** - 所有必需测试通过，但有警告" >> "$TEST_REPORT"
        fi
    else
        echo "❌ **安全工具功能测试失败** - 有 $failed_tests 个测试失败" >> "$TEST_REPORT"
    fi
    
    cat >> "$TEST_REPORT" << EOF

## 安全工具分类统计

### 信息收集工具
- 网络扫描和发现工具
- DNS枚举和子域名收集工具
- Web内容扫描和识别工具

### 漏洞分析工具
- Web漏洞扫描器
- 系统安全审计工具
- 权限提升检测工具

### Web应用工具
- SQL注入和XSS检测工具
- Web爬虫和URL提取工具
- 子域名发现工具

### 无线安全工具
- WiFi破解和攻击工具
- 密码破解工具
- 网络包注入工具

### 后渗透工具
- 渗透测试框架
- 后期利用工具
- 网络代理和隧道工具

### 网络工具
- 网络协议分析器
- 网络扫描和数据包生成器
- 网络监控和诊断工具

### 密码破解工具
- 哈希破解工具
- 密码列表生成器
- 在线密码破解工具

### 逆向工程工具
- 二进制分析工具
- 调试器和反汇编器
- 固件分析工具

### 系统工具
- 基本系统工具
- 开发环境工具
- 网络和安全工具

## 建议

EOF
    
    if [ "$failed_tests" -gt 0 ]; then
        echo "1. 安装缺失的安全工具" >> "$TEST_REPORT"
        echo "2. 更新工具到最新版本" >> "$TEST_REPORT"
        echo "3. 配置工具数据库和模块" >> "$TEST_REPORT"
    fi
    
    if [ "$warning_tests" -gt 0 ]; then
        echo "4. 处理配置警告项目" >> "$TEST_REPORT"
        echo "5. 验证工具数据库连接" >> "$TEST_REPORT"
    fi
    
    echo "6. 定期更新安全工具" >> "$TEST_REPORT"
    echo "7. 测试工具实际功能" >> "$TEST_REPORT"
    echo "8. 保持工具配置最新" >> "$TEST_REPORT"
    echo "9. 监控系统资源使用" >> "$TEST_REPORT"
    echo "10. 建立工具使用文档" >> "$TEST_REPORT"
    
    cat >> "$TEST_REPORT" << EOF

---
*测试报告生成时间: $(date)*
*测试脚本版本: 1.0.0*
EOF
}

# 主测试函数
main() {
    log "INFO" "开始Kali Linux安全工具功能测试..."
    log "INFO" "项目根目录: $PROJECT_ROOT"
    log "INFO" "日志文件: $LOG_FILE"
    log "INFO" "测试报告: $TEST_REPORT"
    
    # 初始化报告
    init_report
    
    # 定义所有测试
    local tests=(
        "test_information_gathering"
        "test_vulnerability_analysis"
        "test_web_application_tools"
        "test_wireless_security_tools"
        "test_post_exploitation_tools"
        "test_network_tools"
        "test_password_cracking_tools"
        "test_reverse_engineering_tools"
        "test_system_tools"
        "test_metasploit_framework"
        "test_tool_configurations"
    )
    
    local total_tests=${#tests[@]}
    local passed_tests=0
    local failed_tests=0
    local warning_tests=0
    
    # 执行所有测试
    for test_func in "${tests[@]}"; do
        log "INFO" "执行测试: $test_func"
        
        if $test_func; then
            ((passed_tests++))
        else
            # 根据测试类型决定是警告还是失败
            case "$test_func" in
                *configurations*)
                    ((warning_tests++))
                    ;;
                *)
                    ((failed_tests++))
                    ;;
            esac
        fi
        
        echo  # 空行分隔
    done
    
    # 生成最终报告
    generate_final_report $total_tests $passed_tests $failed_tests $warning_tests
    
    log "INFO" "安全工具功能测试完成！"
    log "INFO" "总测试数: $total_tests"
    log "INFO" "通过测试: $passed_tests"
    log "INFO" "失败测试: $failed_tests"
    log "INFO" "警告测试: $warning_tests"
    log "INFO" "详细报告: $TEST_REPORT"
    
    if [ "$failed_tests" -eq 0 ]; then
        log "SUCCESS" "安全工具功能测试通过！"
        return 0
    else
        log "ERROR" "安全工具功能测试失败！"
        return 1
    fi
}

# 脚本入口
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi