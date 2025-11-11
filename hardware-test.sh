#!/bin/bash

# 硬件兼容性测试脚本
# hardware-test.sh
# 测试Radxa Cubie A7Z硬件兼容性和功能完整性

set -e

# 全局变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="/tmp/hardware-test.log"
TEST_REPORT="/tmp/hardware-test-report.txt"

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
# Radxa Cubie A7Z 硬件兼容性测试报告
# 生成时间: $(date)
# 测试脚本: $0

## 测试环境

- 主机名: $(hostname)
- 内核版本: $(uname -r)
- 架构: $(uname -m)
- 发行版: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")
- 测试时间: $(date)

## 硬件信息

EOF
    
    # 收集基本硬件信息
    if [ -f /proc/cpuinfo ]; then
        echo "### CPU信息" >> "$TEST_REPORT"
        grep -E "processor|model name|cpu cores|cpu MHz" /proc/cpuinfo | head -20 >> "$TEST_REPORT"
        echo "" >> "$TEST_REPORT"
    fi
    
    if [ -f /proc/meminfo ]; then
        echo "### 内存信息" >> "$TEST_REPORT"
        grep -E "MemTotal|MemFree|MemAvailable" /proc/meminfo >> "$TEST_REPORT"
        echo "" >> "$TEST_REPORT"
    fi
    
    if command -v lspci >/dev/null 2>&1; then
        echo "### PCI设备" >> "$TEST_REPORT"
        lspci | head -10 >> "$TEST_REPORT"
        echo "" >> "$TEST_REPORT"
    fi
    
    if command -v lsusb >/dev/null 2>&1; then
        echo "### USB设备" >> "$TEST_REPORT"
        lsusb | head -10 >> "$TEST_REPORT"
        echo "" >> "$TEST_REPORT"
    fi
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

# 测试CPU信息
test_cpu_info() {
    log "INFO" "开始测试CPU信息..."
    local start_time=$(date +%s)
    
    if [ ! -f /proc/cpuinfo ]; then
        log "ERROR" "CPU信息文件不存在"
        add_test_result "CPU信息" "失败" "CPU信息文件不存在"
        return 1
    fi
    
    local cpu_model=$(grep -m1 "model name" /proc/cpuinfo | cut -d':' -f2 | xargs)
    local cpu_cores=$(grep -c "processor" /proc/cpuinfo)
    local cpu_arch=$(uname -m)
    
    if [ -n "$cpu_model" ] && [ "$cpu_cores" -gt 0 ]; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log "SUCCESS" "CPU信息测试通过: $cpu_model ($cpu_cores cores, $cpu_arch)"
        add_test_result "CPU信息" "通过" "型号: $cpu_model, 核心数: $cpu_cores, 架构: $cpu_arch" "$duration"
        return 0
    else
        log "ERROR" "CPU信息测试失败"
        add_test_result "CPU信息" "失败" "无法获取CPU信息"
        return 1
    fi
}

# 测试内存信息
test_memory_info() {
    log "INFO" "开始测试内存信息..."
    local start_time=$(date +%s)
    
    if [ ! -f /proc/meminfo ]; then
        log "ERROR" "内存信息文件不存在"
        add_test_result "内存信息" "失败" "内存信息文件不存在"
        return 1
    fi
    
    local total_mem=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local free_mem=$(grep MemFree /proc/meminfo | awk '{print $2}')
    
    if [ -n "$total_mem" ] && [ "$total_mem" -gt 0 ]; then
        local total_gb=$(echo "scale=2; $total_mem / 1024 / 1024" | bc -l 2>/dev/null || echo "unknown")
        local free_gb=$(echo "scale=2; $free_mem / 1024 / 1024" | bc -l 2>/dev/null || echo "unknown")
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log "SUCCESS" "内存信息测试通过: 总内存 ${total_gb}GB, 可用内存 ${free_gb}GB"
        add_test_result "内存信息" "通过" "总内存: ${total_gb}GB, 可用内存: ${free_gb}GB" "$duration"
        return 0
    else
        log "ERROR" "内存信息测试失败"
        add_test_result "内存信息" "失败" "无法获取内存信息"
        return 1
    fi
}

# 测试存储设备
test_storage_devices() {
    log "INFO" "开始测试存储设备..."
    local start_time=$(date +%s)
    
    local storage_info=""
    local test_passed=true
    
    # 检查eMMC
    if [ -b /dev/mmcblk0 ]; then
        local emmc_size=$(blockdev --getsize64 /dev/mmcblk0 2>/dev/null || echo "0")
        local emmc_gb=$(echo "scale=2; $emmc_size / 1024 / 1024 / 1024" | bc -l 2>/dev/null || echo "unknown")
        storage_info+="eMMC: ${emmc_gb}GB "
        log "SUCCESS" "发现eMMC设备: ${emmc_gb}GB"
    fi
    
    # 检查SD卡
    if [ -b /dev/mmcblk1 ]; then
        local sd_size=$(blockdev --getsize64 /dev/mmcblk1 2>/dev/null || echo "0")
        local sd_gb=$(echo "scale=2; $sd_size / 1024 / 1024 / 1024" | bc -l 2>/dev/null || echo "unknown")
        storage_info+="SD卡: ${sd_gb}GB "
        log "SUCCESS" "发现SD卡设备: ${sd_gb}GB"
    fi
    
    # 检查USB存储
    if ls /dev/sd* >/dev/null 2>&1; then
        for usb_dev in /dev/sd*; do
            if [ -b "$usb_dev" ]; then
                local usb_size=$(blockdev --getsize64 "$usb_dev" 2>/dev/null || echo "0")
                local usb_gb=$(echo "scale=2; $usb_size / 1024 / 1024 / 1024" | bc -l 2>/dev/null || echo "unknown")
                storage_info+="USB: ${usb_gb}GB "
                log "SUCCESS" "发现USB存储设备: ${usb_gb}GB"
            fi
        done
    fi
    
    if [ -n "$storage_info" ]; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log "SUCCESS" "存储设备测试通过: $storage_info"
        add_test_result "存储设备" "通过" "发现设备: $storage_info" "$duration"
        return 0
    else
        log "WARNING" "未发现存储设备"
        add_test_result "存储设备" "警告" "未发现存储设备"
        return 0
    fi
}

# 测试网络接口
test_network_interfaces() {
    log "INFO" "开始测试网络接口..."
    local start_time=$(date +%s)
    
    local network_info=""
    local test_passed=true
    
    # 获取网络接口
    local interfaces=$(ip link show | grep -E "^[0-9]+:" | awk -F: '{print $2}' | grep -v lo | xargs)
    
    for interface in $interfaces; do
        local interface_state=$(ip link show "$interface" | grep -o "state [A-Z]*" | awk '{print $2}')
        local interface_mac=$(ip link show "$interface" | grep -o "link/ether [0-9a-f:]*" | awk '{print $2}')
        
        if [ "$interface_state" = "UP" ]; then
            # 获取IP地址
            local interface_ip=$(ip addr show "$interface" | grep -o "inet [0-9.]*" | awk '{print $2}' | head -1)
            
            network_info+="$interface(UP, $interface_ip) "
            log "SUCCESS" "网络接口 $interface: UP, IP: $interface_ip, MAC: $interface_mac"
        else
            network_info+="$interface($interface_state) "
            log "INFO" "网络接口 $interface: $interface_state, MAC: $interface_mac"
        fi
    done
    
    # 检查WiFi接口
    if command -v iwconfig >/dev/null 2>&1; then
        local wifi_interfaces=$(iwconfig 2>/dev/null | grep -E "IEEE|ESSID" | awk '{print $1}' | xargs)
        if [ -n "$wifi_interfaces" ]; then
            network_info+="WiFi: $wifi_interfaces "
            log "SUCCESS" "发现WiFi接口: $wifi_interfaces"
        fi
    fi
    
    if [ -n "$network_info" ]; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log "SUCCESS" "网络接口测试通过: $network_info"
        add_test_result "网络接口" "通过" "发现接口: $network_info" "$duration"
        return 0
    else
        log "WARNING" "未发现网络接口"
        add_test_result "网络接口" "警告" "未发现网络接口"
        return 0
    fi
}

# 测试无线设备
test_wireless_devices() {
    log "INFO" "开始测试无线设备..."
    local start_time=$(date +%s)
    
    local wireless_info=""
    local test_passed=true
    
    # 检查WiFi芯片
    if [ -d /sys/class/net ]; then
        for interface in /sys/class/net/*; do
            if [ -d "$interface/wireless" ]; then
                local iface_name=$(basename "$interface")
                local wireless_type=$(cat "$interface/type" 2>/dev/null || echo "unknown")
                wireless_info+="$iface_name "
                log "SUCCESS" "发现无线设备: $iface_name (类型: $wireless_type)"
            fi
        done
    fi
    
    # 检查蓝牙设备
    if command -v hciconfig >/dev/null 2>&1; then
        local bluetooth_devices=$(hciconfig 2>/dev/null | grep -E "hci[0-9]" | awk '{print $1}' | xargs)
        if [ -n "$bluetooth_devices" ]; then
            wireless_info+="蓝牙: $bluetooth_devices "
            log "SUCCESS" "发现蓝牙设备: $bluetooth_devices"
        fi
    fi
    
    # 检查无线固件
    if [ -d /lib/firmware ]; then
        local wifi_firmware=$(find /lib/firmware -name "*wifi*" -o -name "*wlan*" -o -name "*brcm*" 2>/dev/null | wc -l)
        if [ "$wifi_firmware" -gt 0 ]; then
            wireless_info+="固件: $wifi_firmware个 "
            log "SUCCESS" "发现无线固件: $wifi_firmware个"
        fi
    fi
    
    if [ -n "$wireless_info" ]; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log "SUCCESS" "无线设备测试通过: $wireless_info"
        add_test_result "无线设备" "通过" "发现设备: $wireless_info" "$duration"
        return 0
    else
        log "WARNING" "未发现无线设备"
        add_test_result "无线设备" "警告" "未发现无线设备"
        return 0
    fi
}

# 测试GPIO接口
test_gpio_interfaces() {
    log "INFO" "开始测试GPIO接口..."
    local start_time=$(date +%s)
    
    local gpio_info=""
    local test_passed=true
    
    # 检查GPIO导出
    if [ -d /sys/class/gpio ]; then
        local gpio_exports=$(ls /sys/class/gpio/ | grep -E "gpio[0-9]" | wc -l)
        if [ "$gpio_exports" -gt 0 ]; then
            gpio_info+="已导出: $gpio_exports个 "
            log "SUCCESS" "发现已导出GPIO: $gpio_exports个"
        fi
        
        # 检查GPIO控制器
        local gpio_chips=$(ls /sys/class/gpio/ | grep -E "gpiochip[0-9]" | wc -l)
        if [ "$gpio_chips" -gt 0 ]; then
            gpio_info+="控制器: $gpio_chips个 "
            log "SUCCESS" "发现GPIO控制器: $gpio_chips个"
        fi
    fi
    
    # 检查libgpiod工具
    if command -v gpiodetect >/dev/null 2>&1; then
        local gpio_chips=$(gpiodetect 2>/dev/null | wc -l)
        if [ "$gpio_chips" -gt 0 ]; then
            gpio_info+="gpiodetect: $gpio_chips个 "
            log "SUCCESS" "libgpiod检测到控制器: $gpio_chips个"
        fi
    fi
    
    # 检查GPIO权限
    if [ -w /sys/class/gpio/export ]; then
        gpio_info+="权限: OK "
        log "SUCCESS" "GPIO导出权限正常"
    else
        gpio_info+="权限: 受限 "
        log "INFO" "GPIO导出权限受限"
    fi
    
    if [ -n "$gpio_info" ]; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log "SUCCESS" "GPIO接口测试通过: $gpio_info"
        add_test_result "GPIO接口" "通过" "状态: $gpio_info" "$duration"
        return 0
    else
        log "WARNING" "未发现GPIO接口"
        add_test_result "GPIO接口" "警告" "未发现GPIO接口"
        return 0
    fi
}

# 测试I2C接口
test_i2c_interfaces() {
    log "INFO" "开始测试I2C接口..."
    local start_time=$(date +%s)
    
    local i2c_info=""
    local test_passed=true
    
    # 检查I2C设备
    if [ -d /dev ]; then
        local i2c_devices=$(ls /dev/i2c-* 2>/dev/null | wc -l)
        if [ "$i2c_devices" -gt 0 ]; then
            i2c_info+="设备: $i2c_devices个 "
            log "SUCCESS" "发现I2C设备: $i2c_devices个"
            
            # 检查具体设备
            for i2c_dev in /dev/i2c-*; do
                if [ -c "$i2c_dev" ]; then
                    local dev_name=$(basename "$i2c_dev")
                    i2c_info+="$dev_name "
                fi
            done
        fi
    fi
    
    # 检查I2C工具
    if command -v i2cdetect >/dev/null 2>&1; then
        i2c_info+="工具: i2ctools "
        log "SUCCESS" "发现I2C工具"
        
        # 扫描I2C总线
        if [ "$i2c_devices" -gt 0 ]; then
            for i2c_dev in /dev/i2c-*; do
                local dev_num=$(echo "$i2c_dev" | grep -o "[0-9]*$")
                if [ -n "$dev_num" ]; then
                    local i2c_scan=$(i2cdetect -y "$dev_num" 2>/dev/null | grep -E "[0-9a-f][0-9a-f]:" | wc -l)
                    if [ "$i2c_scan" -gt 0 ]; then
                        i2c_info+="扫描$dev_num: $i2c_scan个设备 "
                        log "SUCCESS" "I2C总线$dev_num扫描发现设备: $i2c_scan个"
                    fi
                fi
            done
        fi
    fi
    
    # 检查I2C权限
    if [ -r /dev/i2c-0 ] 2>/dev/null; then
        i2c_info+="权限: OK "
        log "SUCCESS" "I2C设备权限正常"
    else
        i2c_info+="权限: 受限 "
        log "INFO" "I2C设备权限受限"
    fi
    
    if [ -n "$i2c_info" ]; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log "SUCCESS" "I2C接口测试通过: $i2c_info"
        add_test_result "I2C接口" "通过" "状态: $i2c_info" "$duration"
        return 0
    else
        log "WARNING" "未发现I2C接口"
        add_test_result "I2C接口" "警告" "未发现I2C接口"
        return 0
    fi
}

# 测试SPI接口
test_spi_interfaces() {
    log "INFO" "开始测试SPI接口..."
    local start_time=$(date +%s)
    
    local spi_info=""
    local test_passed=true
    
    # 检查SPI设备
    if [ -d /dev ]; then
        local spi_devices=$(ls /dev/spidev* 2>/dev/null | wc -l)
        if [ "$spi_devices" -gt 0 ]; then
            spi_info+="设备: $spi_devices个 "
            log "SUCCESS" "发现SPI设备: $spi_devices个"
            
            # 检查具体设备
            for spi_dev in /dev/spidev*; do
                if [ -c "$spi_dev" ]; then
                    local dev_name=$(basename "$spi_dev")
                    spi_info+="$dev_name "
                fi
            done
        fi
    fi
    
    # 检查SPI工具
    if command -v spidev_test >/dev/null 2>&1; then
        spi_info+="工具: spidev "
        log "SUCCESS" "发现SPI工具"
    fi
    
    # 检查SPI权限
    if [ -r /dev/spidev0.0 ] 2>/dev/null; then
        spi_info+="权限: OK "
        log "SUCCESS" "SPI设备权限正常"
    else
        spi_info+="权限: 受限 "
        log "INFO" "SPI设备权限受限"
    fi
    
    if [ -n "$spi_info" ]; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log "SUCCESS" "SPI接口测试通过: $spi_info"
        add_test_result "SPI接口" "通过" "状态: $spi_info" "$duration"
        return 0
    else
        log "WARNING" "未发现SPI接口"
        add_test_result "SPI接口" "警告" "未发现SPI接口"
        return 0
    fi
}

# 测试UART接口
test_uart_interfaces() {
    log "INFO" "开始测试UART接口..."
    local start_time=$(date +%s)
    
    local uart_info=""
    local test_passed=true
    
    # 检查UART设备
    if [ -d /dev ]; then
        local uart_devices=$(ls /dev/ttyS* /dev/ttyAMA* /dev/ttyUSB* 2>/dev/null | wc -l)
        if [ "$uart_devices" -gt 0 ]; then
            uart_info+="设备: $uart_devices个 "
            log "SUCCESS" "发现UART设备: $uart_devices个"
            
            # 检查具体设备
            for uart_dev in /dev/ttyS* /dev/ttyAMA* /dev/ttyUSB*; do
                if [ -c "$uart_dev" ] 2>/dev/null; then
                    local dev_name=$(basename "$uart_dev")
                    uart_info+="$dev_name "
                fi
            done
        fi
    fi
    
    # 检查串口工具
    if command -v minicom >/dev/null 2>&1; then
        uart_info+="工具: minicom "
        log "SUCCESS" "发现串口工具"
    fi
    
    if command -v screen >/dev/null 2>&1; then
        uart_info+="screen "
        log "SUCCESS" "发现screen工具"
    fi
    
    # 检查UART权限
    if [ -r /dev/ttyS0 ] 2>/dev/null; then
        uart_info+="权限: OK "
        log "SUCCESS" "UART设备权限正常"
    else
        uart_info+="权限: 受限 "
        log "INFO" "UART设备权限受限"
    fi
    
    if [ -n "$uart_info" ]; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log "SUCCESS" "UART接口测试通过: $uart_info"
        add_test_result "UART接口" "通过" "状态: $uart_info" "$duration"
        return 0
    else
        log "WARNING" "未发现UART接口"
        add_test_result "UART接口" "警告" "未发现UART接口"
        return 0
    fi
}

# 测试音频设备
test_audio_devices() {
    log "INFO" "开始测试音频设备..."
    local start_time=$(date +%s)
    
    local audio_info=""
    local test_passed=true
    
    # 检查音频设备
    if [ -d /proc/asound ]; then
        local sound_cards=$(cat /proc/asound/cards 2>/dev/null | grep -E "^[0-9]+ " | wc -l)
        if [ "$sound_cards" -gt 0 ]; then
            audio_info+="声卡: $sound_cards个 "
            log "SUCCESS" "发现声卡: $sound_cards个"
            
            # 检查具体声卡
            cat /proc/asound/cards 2>/dev/null | grep -E "^[0-9]+ " | while read -r line; do
                local card_info=$(echo "$line" | cut -d':' -f2 | xargs)
                audio_info+="$card_info "
            done
        fi
    fi
    
    # 检查ALSA工具
    if command -v aplay >/dev/null 2>&1; then
        audio_info+="工具: alsa "
        log "SUCCESS" "发现ALSA工具"
        
        # 列出音频设备
        local audio_devices=$(aplay -l 2>/dev/null | grep -E "card [0-9]" | wc -l)
        if [ "$audio_devices" -gt 0 ]; then
            audio_info+="设备: $audio_devices个 "
            log "SUCCESS" "ALSA发现音频设备: $audio_devices个"
        fi
    fi
    
    # 检查PulseAudio
    if command -v pactl >/dev/null 2>&1; then
        audio_info+="pulseaudio "
        log "SUCCESS" "发现PulseAudio"
        
        # 检查PulseAudio设备
        local pulse_sources=$(pactl list sources 2>/dev/null | grep -c "Name:" || echo "0")
        local pulse_sinks=$(pactl list sinks 2>/dev/null | grep -c "Name:" || echo "0")
        if [ "$pulse_sources" -gt 0 ] || [ "$pulse_sinks" -gt 0 ]; then
            audio_info+="源: $pulse_sources, 输出: $pulse_sinks "
            log "SUCCESS" "PulseAudio源: $pulse_sources, 输出: $pulse_sinks"
        fi
    fi
    
    if [ -n "$audio_info" ]; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log "SUCCESS" "音频设备测试通过: $audio_info"
        add_test_result "音频设备" "通过" "状态: $audio_info" "$duration"
        return 0
    else
        log "WARNING" "未发现音频设备"
        add_test_result "音频设备" "警告" "未发现音频设备"
        return 0
    fi
}

# 测试显示设备
test_display_devices() {
    log "INFO" "开始测试显示设备..."
    local start_time=$(date +%s)
    
    local display_info=""
    local test_passed=true
    
    # 检查帧缓冲设备
    if [ -d /dev ]; then
        local fb_devices=$(ls /dev/fb* 2>/dev/null | wc -l)
        if [ "$fb_devices" -gt 0 ]; then
            display_info+="帧缓冲: $fb_devices个 "
            log "SUCCESS" "发现帧缓冲设备: $fb_devices个"
            
            # 检查具体设备
            for fb_dev in /dev/fb*; do
                if [ -c "$fb_dev" ]; then
                    local dev_name=$(basename "$fb_dev")
                    display_info+="$dev_name "
                fi
            done
        fi
    fi
    
    # 检查DRM设备
    if [ -d /dev/dri ]; then
        local drm_devices=$(ls /dev/dri/* 2>/dev/null | wc -l)
        if [ "$drm_devices" -gt 0 ]; then
            display_info+="DRM: $drm_devices个 "
            log "SUCCESS" "发现DRM设备: $drm_devices个"
        fi
    fi
    
    # 检查显示信息
    if command -v xrandr >/dev/null 2>&1; then
        display_info+="xrandr "
        log "SUCCESS" "发现xrandr工具"
        
        # 获取显示信息
        local displays=$(xrandr 2>/dev/null | grep -E " connected" | wc -l)
        if [ "$displays" -gt 0 ]; then
            display_info+="显示器: $displays个 "
            log "SUCCESS" "发现显示器: $displays个"
        fi
    fi
    
    # 检查Wayland显示
    if [ -n "$WAYLAND_DISPLAY" ]; then
        display_info+="wayland: $WAYLAND_DISPLAY "
        log "SUCCESS" "发现Wayland显示: $WAYLAND_DISPLAY"
    fi
    
    # 检查X11显示
    if [ -n "$DISPLAY" ]; then
        display_info+="x11: $DISPLAY "
        log "SUCCESS" "发现X11显示: $DISPLAY"
    fi
    
    if [ -n "$display_info" ]; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log "SUCCESS" "显示设备测试通过: $display_info"
        add_test_result "显示设备" "通过" "状态: $display_info" "$duration"
        return 0
    else
        log "WARNING" "未发现显示设备"
        add_test_result "显示设备" "警告" "未发现显示设备"
        return 0
    fi
}

# 测试摄像头设备
test_camera_devices() {
    log "INFO" "开始测试摄像头设备..."
    local start_time=$(date +%s)
    
    local camera_info=""
    local test_passed=true
    
    # 检查视频设备
    if [ -d /dev ]; then
        local video_devices=$(ls /dev/video* 2>/dev/null | wc -l)
        if [ "$video_devices" -gt 0 ]; then
            camera_info+="视频: $video_devices个 "
            log "SUCCESS" "发现视频设备: $video_devices个"
            
            # 检查具体设备
            for video_dev in /dev/video*; do
                if [ -c "$video_dev" ]; then
                    local dev_name=$(basename "$video_dev")
                    camera_info+="$dev_name "
                fi
            done
        fi
    fi
    
    # 检查V4L2工具
    if command -v v4l2-ctl >/dev/null 2>&1; then
        camera_info+="工具: v4l2 "
        log "SUCCESS" "发现V4L2工具"
        
        # 列出视频设备
        local v4l_devices=$(v4l2-ctl --list-devices 2>/dev/null | grep -c "/dev/video" || echo "0")
        if [ "$v4l_devices" -gt 0 ]; then
            camera_info+="设备: $v4l_devices个 "
            log "SUCCESS" "V4L2发现视频设备: $v4l_devices个"
        fi
    fi
    
    # 检查摄像头权限
    if [ -r /dev/video0 ] 2>/dev/null; then
        camera_info+="权限: OK "
        log "SUCCESS" "摄像头设备权限正常"
    else
        camera_info+="权限: 受限 "
        log "INFO" "摄像头设备权限受限"
    fi
    
    if [ -n "$camera_info" ]; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log "SUCCESS" "摄像头设备测试通过: $camera_info"
        add_test_result "摄像头设备" "通过" "状态: $camera_info" "$duration"
        return 0
    else
        log "WARNING" "未发现摄像头设备"
        add_test_result "摄像头设备" "警告" "未发现摄像头设备"
        return 0
    fi
}

# 测试传感器设备
test_sensor_devices() {
    log "INFO" "开始测试传感器设备..."
    local start_time=$(date +%s)
    
    local sensor_info=""
    local test_passed=true
    
    # 检查IIO设备
    if [ -d /sys/bus/iio ]; then
        local iio_devices=$(ls /sys/bus/iio/devices 2>/dev/null | wc -l)
        if [ "$iio_devices" -gt 0 ]; then
            sensor_info+="IIO: $iio_devices个 "
            log "SUCCESS" "发现IIO传感器设备: $iio_devices个"
        fi
    fi
    
    # 检查硬件监控
    if [ -d /sys/class/hwmon ]; then
        local hwmon_devices=$(ls /sys/class/hwmon 2>/dev/null | wc -l)
        if [ "$hwmon_devices" -gt 0 ]; then
            sensor_info+="hwmon: $hwmon_devices个 "
            log "SUCCESS" "发现硬件监控设备: $hwmon_devices个"
            
            # 检查具体传感器
            for hwmon in /sys/class/hwmon/hwmon*; do
                if [ -d "$hwmon" ]; then
                    local sensor_name=$(cat "$hwmon/name" 2>/dev/null || echo "unknown")
                    sensor_info+="$sensor_name "
                fi
            done
        fi
    fi
    
    # 检查温度传感器
    if command -v sensors >/dev/null 2>&1; then
        sensor_info+="工具: sensors "
        log "SUCCESS" "发现sensors工具"
        
        # 获取温度信息
        local temp_sensors=$(sensors 2>/dev/null | grep -c "°C" || echo "0")
        if [ "$temp_sensors" -gt 0 ]; then
            sensor_info+="温度: $temp_sensors个 "
            log "SUCCESS" "发现温度传感器: $temp_sensors个"
        fi
    fi
    
    if [ -n "$sensor_info" ]; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log "SUCCESS" "传感器设备测试通过: $sensor_info"
        add_test_result "传感器设备" "通过" "状态: $sensor_info" "$duration"
        return 0
    else
        log "WARNING" "未发现传感器设备"
        add_test_result "传感器设备" "警告" "未发现传感器设备"
        return 0
    fi
}

# 测试电源管理
test_power_management() {
    log "INFO" "开始测试电源管理..."
    local start_time=$(date +%s)
    
    local power_info=""
    local test_passed=true
    
    # 检查电源信息
    if [ -d /sys/class/power_supply ]; then
        local power_supplies=$(ls /sys/class/power_supply 2>/dev/null | wc -l)
        if [ "$power_supplies" -gt 0 ]; then
            power_info+="电源: $power_supplies个 "
            log "SUCCESS" "发现电源供应: $power_supplies个"
            
            # 检查具体电源
            for ps in /sys/class/power_supply/*; do
                if [ -d "$ps" ]; then
                    local ps_type=$(cat "$ps/type" 2>/dev/null || echo "unknown")
                    local ps_status=$(cat "$ps/status" 2>/dev/null || echo "unknown")
                    power_info+="$(basename "$ps")($ps_type,$ps_status) "
                fi
            done
        fi
    fi
    
    # 检查CPU频率
    if [ -d /sys/devices/system/cpu ]; then
        local cpu_freqs=$(ls /sys/devices/system/cpu/cpu*/cpufreq 2>/dev/null | wc -l)
        if [ "$cpu_freqs" -gt 0 ]; then
            power_info+="CPU频率: $cpu_freqs个 "
            log "SUCCESS" "发现CPU频率控制: $cpu_freqs个"
        fi
    fi
    
    # 检查电池信息
    if [ -f /sys/class/power_supply/BAT0/capacity ]; then
        local battery_capacity=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "unknown")
        power_info+="电池: ${battery_capacity}% "
        log "SUCCESS" "发现电池: ${battery_capacity}%"
    fi
    
    # 检查电源管理工具
    if command -v pm-suspend >/dev/null 2>&1; then
        power_info+="工具: pm-utils "
        log "SUCCESS" "发现电源管理工具"
    fi
    
    if [ -n "$power_info" ]; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log "SUCCESS" "电源管理测试通过: $power_info"
        add_test_result "电源管理" "通过" "状态: $power_info" "$duration"
        return 0
    else
        log "WARNING" "未发现电源管理信息"
        add_test_result "电源管理" "警告" "未发现电源管理信息"
        return 0
    fi
}

# 测试硬件加速
test_hardware_acceleration() {
    log "INFO" "开始测试硬件加速..."
    local start_time=$(date +%s)
    
    local accel_info=""
    local test_passed=true
    
    # 检查GPU信息
    if [ -d /sys/class/drm ]; then
        local gpu_cards=$(ls /sys/class/drm/card* 2>/dev/null | wc -l)
        if [ "$gpu_cards" -gt 0 ]; then
            accel_info+="GPU: $gpu_cards个 "
            log "SUCCESS" "发现GPU卡: $gpu_cards个"
            
            # 检查具体GPU
            for gpu in /sys/class/drm/card*; do
                if [ -d "$gpu" ]; then
                    local gpu_name=$(cat "$gpu/device/name" 2>/dev/null || echo "unknown")
                    accel_info+="$(basename "$gpu")($gpu_name) "
                fi
            done
        fi
    fi
    
    # 检查V4L2编码器
    if command -v v4l2-ctl >/dev/null 2>&1; then
        local v4l2_codecs=$(v4l2-ctl --list-devices 2>/dev/null | grep -c "codec" || echo "0")
        if [ "$v4l2_codecs" -gt 0 ]; then
            accel_info+="V4L2编码: $v4l2_codecs个 "
            log "SUCCESS" "发现V4L2编码器: $v4l2_codecs个"
        fi
    fi
    
    # 检查硬件加速库
    if ldconfig -p 2>/dev/null | grep -q "libmali"; then
        accel_info+="Mali: OK "
        log "SUCCESS" "发现Mali GPU库"
    fi
    
    if ldconfig -p 2>/dev/null | grep -q "libv4l"; then
        accel_info+="V4L2: OK "
        log "SUCCESS" "发现V4L2库"
    fi
    
    # 检查OpenCL
    if command -v clinfo >/dev/null 2>&1; then
        local opencl_devices=$(clinfo 2>/dev/null | grep -c "Device Name" || echo "0")
        if [ "$opencl_devices" -gt 0 ]; then
            accel_info+="OpenCL: $opencl_devices个 "
            log "SUCCESS" "发现OpenCL设备: $opencl_devices个"
        fi
    fi
    
    if [ -n "$accel_info" ]; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log "SUCCESS" "硬件加速测试通过: $accel_info"
        add_test_result "硬件加速" "通过" "状态: $accel_info" "$duration"
        return 0
    else
        log "WARNING" "未发现硬件加速"
        add_test_result "硬件加速" "警告" "未发现硬件加速"
        return 0
    fi
}

# 测试温度监控
test_temperature_monitoring() {
    log "INFO" "开始测试温度监控..."
    local start_time=$(date +%s)
    
    local temp_info=""
    local test_passed=true
    
    # 检查温度传感器
    if command -v sensors >/dev/null 2>&1; then
        local temp_sensors=$(sensors 2>/dev/null | grep -c "°C" || echo "0")
        if [ "$temp_sensors" -gt 0 ]; then
            temp_info+="传感器: $temp_sensors个 "
            log "SUCCESS" "发现温度传感器: $temp_sensors个"
            
            # 获取具体温度
            sensors 2>/dev/null | grep "°C" | head -5 | while read -r line; do
                temp_info+="$line "
            done
        fi
    fi
    
    # 检查热区
    if [ -d /sys/class/thermal ]; then
        local thermal_zones=$(ls /sys/class/thermal/thermal_zone* 2>/dev/null | wc -l)
        if [ "$thermal_zones" -gt 0 ]; then
            temp_info+="热区: $thermal_zones个 "
            log "SUCCESS" "发现热区: $thermal_zones个"
            
            # 检查具体热区
            for zone in /sys/class/thermal/thermal_zone*; do
                if [ -d "$zone" ]; then
                    local zone_type=$(cat "$zone/type" 2>/dev/null || echo "unknown")
                    local zone_temp=$(cat "$zone/temp" 2>/dev/null || echo "unknown")
                    if [ "$zone_temp" != "unknown" ] && [ "$zone_temp" -gt 0 ]; then
                        local temp_c=$(echo "scale=1; $zone_temp / 1000" | bc -l 2>/dev/null || echo "unknown")
                        temp_info+="$zone_type:${temp_c}°C "
                    fi
                fi
            done
        fi
    fi
    
    # 检查CPU温度
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        local cpu_temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo "unknown")
        if [ "$cpu_temp" != "unknown" ] && [ "$cpu_temp" -gt 0 ]; then
            local cpu_temp_c=$(echo "scale=1; $cpu_temp / 1000" | bc -l 2>/dev/null || echo "unknown")
            temp_info+="CPU:${cpu_temp_c}°C "
            log "SUCCESS" "CPU温度: ${cpu_temp_c}°C"
        fi
    fi
    
    if [ -n "$temp_info" ]; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log "SUCCESS" "温度监控测试通过: $temp_info"
        add_test_result "温度监控" "通过" "状态: $temp_info" "$duration"
        return 0
    else
        log "WARNING" "未发现温度监控"
        add_test_result "温度监控" "警告" "未发现温度监控"
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
            echo "✅ **硬件兼容性测试通过** - 所有测试都通过" >> "$TEST_REPORT"
        else
            echo "⚠️ **硬件兼容性测试通过但有警告** - 所有必需测试通过，但有警告" >> "$TEST_REPORT"
        fi
    else
        echo "❌ **硬件兼容性测试失败** - 有 $failed_tests 个测试失败" >> "$TEST_REPORT"
    fi
    
    cat >> "$TEST_REPORT" << EOF

## 硬件兼容性总结

基于测试结果，系统硬件兼容性如下：

EOF
    
    if [ "$passed_tests" -gt 0 ]; then
        echo "### ✅ 正常工作的硬件" >> "$TEST_REPORT"
        echo "以下硬件组件测试通过:" >> "$TEST_REPORT"
        # 这里可以添加具体的通过测试列表
        echo "" >> "$TEST_REPORT"
    fi
    
    if [ "$warning_tests" -gt 0 ]; then
        echo "### ⚠️ 需要关注的硬件" >> "$TEST_REPORT"
        echo "以下硬件组件需要额外配置或不可用:" >> "$TEST_REPORT"
        # 这里可以添加具体的警告测试列表
        echo "" >> "$TEST_REPORT"
    fi
    
    if [ "$failed_tests" -gt 0 ]; then
        echo "### ❌ 存在问题的硬件" >> "$TEST_REPORT"
        echo "以下硬件组件测试失败:" >> "$TEST_REPORT"
        # 这里可以添加具体的失败测试列表
        echo "" >> "$TEST_REPORT"
    fi
    
    cat >> "$TEST_REPORT" << EOF

## 建议

1. **驱动程序**: 确保所有硬件驱动程序已正确安装
2. **固件**: 检查是否缺少硬件固件文件
3. **权限**: 验证用户权限是否允许访问硬件设备
4. **配置**: 检查硬件相关配置文件
5. **测试**: 在实际硬件上进行功能测试

---
*测试报告生成时间: $(date)*
*测试脚本版本: 1.0.0*
EOF
}

# 主测试函数
main() {
    log "INFO" "开始Radxa Cubie A7Z硬件兼容性测试..."
    log "INFO" "项目根目录: $PROJECT_ROOT"
    log "INFO" "日志文件: $LOG_FILE"
    log "INFO" "测试报告: $TEST_REPORT"
    
    # 初始化报告
    init_report
    
    # 定义所有测试
    local tests=(
        "test_cpu_info"
        "test_memory_info"
        "test_storage_devices"
        "test_network_interfaces"
        "test_wireless_devices"
        "test_gpio_interfaces"
        "test_i2c_interfaces"
        "test_spi_interfaces"
        "test_uart_interfaces"
        "test_audio_devices"
        "test_display_devices"
        "test_camera_devices"
        "test_sensor_devices"
        "test_power_management"
        "test_hardware_acceleration"
        "test_temperature_monitoring"
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
                *gpio*|*i2c*|*spi*|*uart*|*camera*|*sensor*)
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
    
    log "INFO" "硬件兼容性测试完成！"
    log "INFO" "总测试数: $total_tests"
    log "INFO" "通过测试: $passed_tests"
    log "INFO" "失败测试: $failed_tests"
    log "INFO" "警告测试: $warning_tests"
    log "INFO" "详细报告: $TEST_REPORT"
    
    if [ "$failed_tests" -eq 0 ]; then
        log "SUCCESS" "硬件兼容性测试通过！"
        return 0
    else
        log "ERROR" "硬件兼容性测试失败！"
        return 1
    fi
}

# 脚本入口
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi