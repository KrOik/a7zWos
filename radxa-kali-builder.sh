#!/bin/bash

# Radxa Cubie A7Z Kali Linux 构建系统
# 基于RadxaOS SDK和Kali metapackages的完整构建方案
# 作者: KrNormyDev
# 版本: 1.0.0

set -euo pipefail

# 全局变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/build.log"
VENDOR="KrNormyDev"
PRODUCT="a7zWos"
VERSION="1.0.0"
ARCH="arm64"
DISTRIBUTION="kali-rolling"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# 错误处理
trap 'log_error "构建在第 $LINENO 行失败"; exit 1' ERR

# 检查root权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        exit 1
    fi
}

# 检查系统要求
check_requirements() {
    log_info "检查系统要求..."
    
    # 检查架构
    if [[ "$(uname -m)" != "aarch64" ]]; then
        log_warning "当前架构不是ARM64，某些功能可能受限"
    fi
    
    # 检查磁盘空间
    local disk_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ $disk_space -lt 20 ]]; then
        log_error "磁盘空间不足，需要至少20GB可用空间"
        exit 1
    fi
    
    # 检查内存
    local memory=$(free -g | awk 'NR==2 {print $2}')
    if [[ $memory -lt 4 ]]; then
        log_warning "内存小于4GB，构建可能较慢"
    fi
    
    # 检查网络连接（使用HTTP而非ping，避免被禁）
    local urls=(
        "http://http.kali.org/"
        "https://archive.kali.org/archive-key.asc"
        "https://radxa-repo.github.io/bullseye/"
    )
    local http_ok=0
    for u in "${urls[@]}"; do
        if curl -fsSL --connect-timeout 5 --max-time 10 "$u" -o /dev/null; then
            http_ok=1
            break
        fi
    done
    if [[ $http_ok -eq 0 ]]; then
        log_error "网络不可用：无法通过HTTP访问必要的仓库地址"
        exit 1
    fi
    
    log_success "系统要求检查完成"
}

# 安装构建依赖
install_dependencies() {
    log_info "安装构建依赖..."
    
    # 避免交互式提示阻塞安装
    export DEBIAN_FRONTEND=noninteractive
    
    # 若系统尚未启用 merged-/usr，先安装 usrmerge，避免 base-files 升级失败
    if [[ -d /bin && ! -L /bin ]]; then
        if ! dpkg -l | grep -q "^ii.*usrmerge"; then
            log_info "检测到未合并的 /usr，先安装 usrmerge"
            apt-get install -y --no-install-recommends usrmerge || {
                log_warning "安装 usrmerge 失败，后续安装可能出错"
            }
        fi
    fi
    
    apt-get update
    
    local deps=(
        "git"
        "curl"
        "wget"
        "build-essential"
        "debootstrap"
        "live-build"
        "jq"
        "python3"
        "python3-pip"
        "qemu-user-static"
        "binfmt-support"
        "docker.io"
        "debootstrap"
        "arch-test"
        "dosfstools"
        "mtools"
        "parted"
        "rsync"
        "xorriso"
        "isolinux"
        "syslinux"
        "grub-pc-bin"
        "grub-efi-amd64-bin"
        "grub-efi-ia32-bin"
        "efibootmgr"
        "mokutil"
        "shim-signed"
        "sbsigntool"
        "faketime"
        "libarchive-tools"
        "squashfs-tools"
        "e2fsprogs"
        "btrfs-progs"
        "xfsprogs"
        "f2fs-tools"
        "udftools"
        "reiserfsprogs"
        "jfsutils"
        "nilfs-tools"
        "gparted"
        "testdisk"
        "gnupg"
        "ca-certificates"
    )
    
    for dep in "${deps[@]}"; do
        if ! dpkg -l | grep -q "^ii.*$dep"; then
            log_info "安装依赖: $dep"
            apt-get install -y "$dep" || log_warning "安装 $dep 失败"
        fi
    done
    
    log_success "构建依赖安装完成"
}

# 设置Kali仓库
setup_kali_repositories() {
    log_info "设置Kali仓库..."
    
    # 创建必要目录
    mkdir -p /etc/apt/sources.list.d
    mkdir -p /etc/apt/keyrings

    # 确保密钥工具与证书
    if ! dpkg -l | grep -q "^ii.*gnupg"; then
        apt-get install -y --no-install-recommends gnupg || log_warning "安装 gnupg 失败"
    fi
    if ! dpkg -l | grep -q "^ii.*ca-certificates"; then
        apt-get install -y --no-install-recommends ca-certificates || log_warning "安装 ca-certificates 失败"
    fi

    # 导入Kali仓库密钥到keyrings
    if [[ ! -f /etc/apt/keyrings/kali-archive-keyring.gpg ]]; then
        if curl -fsSL https://archive.kali.org/archive-key.asc | gpg --dearmor -o /etc/apt/keyrings/kali-archive-keyring.gpg; then
            log_success "Kali仓库密钥导入完成"
        else
            log_error "Kali仓库密钥导入失败"
            return 1
        fi
    fi

    # 统一Radxa密钥路径（优先使用系统已有的 /usr/share/keyrings）
    # 清理可能存在的空文件，避免导致APT冲突
    if [[ -f /etc/apt/keyrings/radxa-archive-keyring.gpg && ! -s /etc/apt/keyrings/radxa-archive-keyring.gpg ]]; then
        rm -f /etc/apt/keyrings/radxa-archive-keyring.gpg
    fi
    local RADXA_KEYRING=""
    if [[ -e /usr/share/keyrings/radxa-archive-keyring.gpg ]]; then
        RADXA_KEYRING="/usr/share/keyrings/radxa-archive-keyring.gpg"
    elif [[ -s /etc/apt/keyrings/radxa-archive-keyring.gpg ]]; then
        RADXA_KEYRING="/etc/apt/keyrings/radxa-archive-keyring.gpg"
    else
        log_warning "未检测到 Radxa 密钥环，将跳过写入 Radxa 源"
    fi

    # 写入sources.list，使用signed-by指向keyrings
    cat > /etc/apt/sources.list.d/kali.list << 'EOF'
deb [signed-by=/etc/apt/keyrings/kali-archive-keyring.gpg] http://http.kali.org/kali kali-rolling main non-free contrib
deb-src [signed-by=/etc/apt/keyrings/kali-archive-keyring.gpg] http://http.kali.org/kali kali-rolling main non-free contrib
EOF

    # 写入 Radxa 源（若系统不存在同源定义且有可用密钥）
    if [[ -n "$RADXA_KEYRING" ]]; then
        if ! grep -Rqs "radxa-repo.github.io/bullseye" /etc/apt/sources.list.d; then
            cat > /etc/apt/sources.list.d/radxa.list << EOF
deb [signed-by=${RADXA_KEYRING}] https://radxa-repo.github.io/bullseye bullseye main
EOF
        else
            log_info "系统已存在 Radxa bullseye 源，跳过写入"
        fi
    fi

    apt-get update || {
        log_error "APT源更新失败"
        return 1
    }
    log_success "Kali仓库设置完成"
}

# 克隆RadxaOS SDK
clone_radxaos_sdk() {
    log_info "克隆RadxaOS SDK..."
    
    local sdk_dir="${SCRIPT_DIR}/rsdk"
    
    if [[ -d "$sdk_dir" ]]; then
        log_info "RadxaOS SDK已存在，更新中..."
        cd "$sdk_dir"
        git pull --recurse-submodules
    else
        log_info "克隆RadxaOS SDK..."
        git clone --recurse-submodules https://github.com/RadxaOS-SDK/rsdk.git "$sdk_dir"
    fi
    
    cd "$sdk_dir"
    
    # 安装Node.js依赖
    if command -v npm &> /dev/null; then
        npm install @devcontainers/cli || log_warning "npm安装失败"
    fi
    
    # 设置环境变量
    export PATH="$PWD/src/bin:$PWD/node_modules/.bin:$PATH"
    
    log_success "RadxaOS SDK准备完成"
}

# 生成配置文件
generate_configs() {
    log_info "生成配置文件..."
    
    # 创建配置目录
    mkdir -p "${SCRIPT_DIR}/configs"
    mkdir -p "${SCRIPT_DIR}/hooks"
    mkdir -p "${SCRIPT_DIR}/package-lists"
    
    # 生成rootfs.jsonnet
    cat > "${SCRIPT_DIR}/configs/rootfs.jsonnet" << EOF
{
    // 基础配置
    "architecture": "$ARCH",
    "distribution": "$DISTRIBUTION",
    "vendor": "$VENDOR",
    "product": "$PRODUCT", 
    "version": "$VERSION",
    
    // 仓库配置
    "repositories": [
        "deb http://http.kali.org/kali kali-rolling main non-free contrib",
        "deb-src http://http.kali.org/kali kali-rolling main non-free contrib",
        "deb https://radxa-repo.github.io/bullseye bullseye main"
    ],
    
    // 基础包
    "base_packages": [
        "kali-linux-core",
        "kali-desktop-core",
        "kali-tools-information-gathering",
        "kali-tools-vulnerability", 
        "kali-tools-web",
        "kali-tools-802-11",
        "kali-tools-bluetooth",
        "kali-tools-rfid",
        "kali-tools-sdr"
    ],
    
    // 桌面环境 - 改为XFCE for Wayland
    "desktop_packages": [
        "xfce4",
        "xfce4-goodies", 
        "xfce4-panel",
        "thunar",
        "gtk3-engines-xfce"
    ],
    
    // Wayland支持包
    "wayland_packages": [
        "wayland-protocols",
        "libwayland-client0",
        "weston",
        "sway",
        "waybar",
        "wofi",
        "foot"
    ],
    
    // ZSH终端包
    "shell_packages": [
        "zsh",
        "git",
        "curl",
        "wget"
    ],
    
    // Radxa硬件支持包
    "radxa_packages": [
        "firmware-realtek",
        "firmware-atheros", 
        "firmware-brcm80211",
        "firmware-libertas",
        "firmware-misc-nonfree",
        "radxa-system-config",
        "libmraa-dev"
    ],
    
    // Waydroid支持
    "waydroid_packages": [
        "waydroid",
        "python3-gbinder",
        "lxc",
        "cgroupfs-mount"
    ],
    
    // 自定义钩子脚本
    "custom_hooks": [
        "9990-radxa-hardware-initialization.chroot",
        "9991-waydroid-nokvm-configuration.chroot", 
        "9992-kali-tools-configuration.chroot",
        "9993-zsh-configuration.chroot",
        "9994-wayland-desktop-configuration.chroot", 
        "9995-vendor-information.chroot"
    ],
    
    // 构建参数
    "build_options": {
        "compression": "xz",
        "memtest": true,
        "apt_recommends": false,
        "apt_secure": false
    }
}
EOF
    
    log_success "配置文件生成完成"
}

# 生成钩子脚本
generate_hooks() {
    log_info "生成钩子脚本..."
    
    # 9990 - Radxa硬件初始化
    cat > "${SCRIPT_DIR}/hooks/9990-radxa-hardware-initialization.chroot" << 'EOF'
#!/bin/bash

echo "=== Radxa硬件初始化 ==="

# 安装Radxa特定包
apt-get install -y firmware-realtek firmware-atheros firmware-brcm80211
apt-get install -y firmware-libertas firmware-misc-nonfree radxa-system-config

# 配置设备树
cp /usr/lib/linux-image-*/allwinner/a733-cubie-a7z.dtb /boot/

# 配置GPIO支持
apt-get install -y libmraa-dev python3-mraa

# 配置I2C支持
echo "i2c-dev" >> /etc/modules-load.d/radxa.conf

# 配置SPI支持  
echo "spidev" >> /etc/modules-load.d/radxa.conf

# 设置硬件权限
usermod -a -G gpio,dialout,i2c,spi kali

echo "Radxa硬件初始化完成"
EOF

    # 9991 - Waydroid无KVM配置
    cat > "${SCRIPT_DIR}/hooks/9991-waydroid-nokvm-configuration.chroot" << 'EOF'
#!/bin/bash

echo "=== Waydroid无KVM配置 ==="

# 安装Waydroid
apt-get install -y waydroid python3-gbinder lxc cgroupfs-mount

# 配置Waydroid无KVM模式
cat > /etc/waydroid.cfg << 'WAYDROID_EOF'
[waydroid]
arch = arm64
vendor_type = MAINLINE
mount_overlays = True
auto_adb = True
images_path = /usr/share/waydroid-images
system_ota = https://ota.waydro.id/system/lineage/waydroid_arm64/VANILLA.json
vendor_ota = https://ota.waydro.id/vendor/waydroid_arm64/MAINLINE.json
binder = anbox-binder
vndbinder = anbox-vndbinder
hwbinder = anbox-hwbinder
WAYDROID_EOF

# 配置LXC无特权容器
cat > /etc/lxc/default.conf << 'LXC_EOF'
lxc.net.0.type = veth
lxc.net.0.link = lxcbr0
lxc.net.0.flags = up
lxc.net.0.hwaddr = 00:16:3e:xx:xx:xx
lxc.idmap = u 0 100000 65536
lxc.idmap = g 0 100000 65536
LXC_EOF

# 启用IP转发
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

echo "Waydroid无KVM配置完成"
EOF

    # 9992 - Kali工具配置
    cat > "${SCRIPT_DIR}/hooks/9992-kali-tools-configuration.chroot" << 'EOF'
#!/bin/bash

echo "=== Kali工具配置 ==="

# 安装核心Kali工具
apt-get install -y kali-linux-core kali-desktop-core

# 安装信息收集工具
apt-get install -y kali-tools-information-gathering

# 安装漏洞分析工具
apt-get install -y kali-tools-vulnerability

# 安装Web应用工具
apt-get install -y kali-tools-web

# 安装无线安全工具
apt-get install -y kali-tools-802-11 kali-tools-bluetooth kali-tools-rfid kali-tools-sdr

# 配置网络工具
apt-get install -y wireless-tools rfkill crda

# 创建工具启动脚本
mkdir -p /usr/local/bin

cat > /usr/local/bin/kali-tools-info << 'TOOLS_EOF'
#!/bin/bash
echo "=== Kali工具状态 ==="
echo "Nmap版本: $(nmap --version | head -1)"
echo "Aircrack-ng版本: $(aircrack-ng --version 2>/dev/null | head -1)"
echo "Metasploit版本: $(msfconsole --version 2>/dev/null)"
echo "Wireshark版本: $(tshark --version 2>/dev/null | head -1)"
echo "SQLMap版本: $(sqlmap --version 2>/dev/null)"
TOOLS_EOF

chmod +x /usr/local/bin/kali-tools-info

echo "Kali工具配置完成"
EOF

    # 9993 - ZSH配置
    cat > "${SCRIPT_DIR}/hooks/9993-zsh-configuration.chroot" << 'EOF'
#!/bin/bash

echo "=== ZSH终端配置 ==="

# 安装ZSH
apt-get install -y zsh git curl wget

# 安装oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# 配置ZSH插件
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# 配置.zshrc
cat > /etc/skel/.zshrc << 'ZSH_EOF'
# oh-my-zsh配置
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting docker)
source $ZSH/oh-my-zsh.sh

# 自定义别名
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias update='sudo apt update && sudo apt upgrade'
alias kali='kali-tools-info'

# Kali特定配置
export PATH=$PATH:/usr/share/metasploit-framework
export MSF_DATABASE_CONFIG=/usr/share/metasploit-framework/config/database.yml
ZSH_EOF

# 设置ZSH为默认shell
chsh -s /bin/zsh
chsh -s /bin/zsh kali

# 复制配置到现有用户
if id "kali" &>/dev/null; then
    cp /etc/skel/.zshrc /home/kali/
    chown kali:kali /home/kali/.zshrc
fi

echo "ZSH终端配置完成"
EOF

    # 9994 - Wayland桌面配置
    cat > "${SCRIPT_DIR}/hooks/9994-wayland-desktop-configuration.chroot" << 'EOF'
#!/bin/bash

echo "=== Wayland桌面配置 ==="

# 安装Wayland compositor
apt-get install -y wayland-protocols libwayland-client0 weston sway waybar wofi foot

# 安装XFCE for Wayland
apt-get install -y xfce4 xfce4-goodies xfce4-panel thunar gtk3-engines-xfce

# 配置Sway compositor
cat > /etc/sway/config << 'SWAY_EOF'
# Sway配置 - 适用于Radxa Kali
set $mod Mod4

# 基本配置
output * bg /usr/share/backgrounds/kali/kali-linux.png fill
xwayland enable

# 快捷键
bindsym $mod+Return exec foot
bindsym $mod+Shift+q kill
bindsym $mod+d exec wofi --show drun
bindsym $mod+Shift+e exec swaynag -t warning -m '退出Sway?' -b '是' 'swaymsg exit'

# 工作区
bindsym $mod+1 workspace number 1
bindsym $mod+2 workspace number 2
bindsym $mod+3 workspace number 3
bindsym $mod+4 workspace number 4

# 窗口管理
floating_modifier $mod
bindsym $mod+h focus left
bindsym $mod+j focus down
bindsym $mod+k focus up
bindsym $mod+l focus right

# 启动应用
exec waybar
exec nm-applet
SWAY_EOF

# 配置Waybar
cat > /etc/waybar/config << 'WAYBAR_EOF'
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "modules-left": ["sway/workspaces", "sway/mode"],
    "modules-center": ["sway/window"],
    "modules-right": ["network", "cpu", "memory", "battery", "clock", "tray"],
    
    "network": {
        "format": "{icon} {essid}",
        "format-icons": ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]
    },
    
    "cpu": {
        "format": "CPU: {usage}%",
        "tooltip": false
    },
    
    "memory": {
        "format": "MEM: {percentage}%",
        "tooltip": false
    },
    
    "battery": {
        "format": "{icon} {capacity}%",
        "format-icons": ["󰂃", "󰁻", "󰁽", "󰁿", "󰁹"]
    },
    
    "clock": {
        "format": "{:%Y-%m-%d %H:%M}",
        "tooltip": false
    }
}
WAYBAR_EOF

# 创建启动脚本
cat > /usr/local/bin/start-wayland.sh << 'START_EOF'
#!/bin/bash
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export WAYLAND_DISPLAY=wayland-0
export XWAYLAND_ENABLE=1
export XWAYLAND_GLAMOR=1

# 启动Sway
exec sway
START_EOF

cat > /usr/local/bin/start-xfce-wayland.sh << 'XFCE_START_EOF'
#!/bin/bash
export GDK_BACKEND=wayland
export CLUTTER_BACKEND=wayland
export XDG_SESSION_TYPE=wayland

# 启动XFCE Wayland会话
exec dbus-run-session startxfce4
XFCE_START_EOF

chmod +x /usr/local/bin/start-wayland.sh /usr/local/bin/start-xfce-wayland.sh

# 兼容性库
apt-get install -y xwayland qtwayland5 qt5-qpa-plugin-wayland gtk-layer-shell libgtk-3-0

echo "Wayland桌面配置完成"
EOF

    # 9995 - 厂商信息配置
    cat > "${SCRIPT_DIR}/hooks/9995-vendor-information.chroot" << EOF
#!/bin/bash

echo "=== 配置厂商信息 ==="

# 设置系统厂商信息
echo "$VENDOR" > /etc/vendor-name
echo "$PRODUCT" > /etc/product-name
echo "$VERSION" > /etc/product-version

# 创建厂商信息文件
cat > /etc/kali-radxa-info << 'VENDOR_EOF'
# Radxa Kali Linux - $VENDOR Edition
VENDOR=$VENDOR
PRODUCT=$PRODUCT
VERSION=$VERSION
BUILD_DATE=\$(date +%Y%m%d)
KALI_VERSION=kali-rolling
RADXA_TARGET=cubie-a7z
VENDOR_EOF

# 创建系统标识
cat > /etc/os-release-radxa << 'OS_EOF'
NAME="Kali Linux"
VERSION="2024.1"
ID=kali
ID_LIKE=debian
PRETTY_NAME="Kali Linux $VENDOR Edition"
VERSION_ID="2024.1"
HOME_URL="https://www.kali.org/"
SUPPORT_URL="https://forums.kali.org/"
BUG_REPORT_URL="https://bugs.kali.org/"
VENDOR=$VENDOR
PRODUCT=$PRODUCT
OS_EOF

# 创建欢迎信息
cat > /etc/motd << 'MOTD_EOF'
Welcome to Kali Linux $VENDOR Edition!
→ Wayland桌面环境已就绪
→ ZSH终端已配置完成  
→ Kali渗透测试工具已安装
→ Radxa硬件支持已激活
→ Waydroid Android容器已配置

系统信息:
- 厂商: $VENDOR
- 产品: $PRODUCT
- 版本: $VERSION
- 架构: $ARCH
- 发行版: $DISTRIBUTION
MOTD_EOF

echo "厂商信息配置完成"
EOF

    # 设置钩子脚本权限
    chmod +x "${SCRIPT_DIR}/hooks"/*.chroot
    
    log_success "钩子脚本生成完成"
}

# 生成包列表
generate_package_lists() {
    log_info "生成包列表..."
    
    # Kali核心包
    cat > "${SCRIPT_DIR}/package-lists/kali-core.list" << 'EOF'
# Kali Linux核心包
kali-linux-core
kali-desktop-core
kali-tools-information-gathering
kali-tools-vulnerability
kali-tools-web
kali-tools-802-11
kali-tools-bluetooth
kali-tools-rfid
kali-tools-sdr
EOF

    # Radxa硬件支持包
    cat > "${SCRIPT_DIR}/package-lists/radxa-hardware.list" << 'EOF'
# Radxa硬件支持包
firmware-realtek
firmware-atheros
firmware-brcm80211
firmware-libertas
firmware-misc-nonfree
radxa-system-config
libmraa-dev
python3-mraa
EOF

    # Wayland桌面包
    cat > "${SCRIPT_DIR}/package-lists/wayland-desktop.list" << 'EOF'
# Wayland桌面环境
wayland-protocols
libwayland-client0
weston
sway
waybar
wofi
foot
xfce4
xfce4-goodies
xfce4-panel
thunar
gtk3-engines-xfce
xwayland
qtwayland5
qt5-qpa-plugin-wayland
gtk-layer-shell
libgtk-3-0
EOF

    # ZSH终端包
    cat > "${SCRIPT_DIR}/package-lists/zsh-shell.list" << 'EOF'
# ZSH终端和工具
zsh
git
curl
wget
vim
nano
htop
tree
jq
EOF

    # Waydroid支持包
    cat > "${SCRIPT_DIR}/package-lists/waydroid.list" << 'EOF'
# Waydroid Android容器支持
waydroid
python3-gbinder
lxc
cgroupfs-mount
bridge-utils
iptables
EOF

    # 网络工具包
    cat > "${SCRIPT_DIR}/package-lists/network-tools.list" << 'EOF'
# 网络工具
wireless-tools
rfkill
crda
iw
hostapd
aircrack-ng
reaver
pixiewps
wifite
EOF

    log_success "包列表生成完成"
}

# 主构建函数
build_system() {
    log_info "开始构建Radxa Kali Linux系统..."
    
    local build_dir="${SCRIPT_DIR}/build"
    local output_dir="${SCRIPT_DIR}/output"
    
    # 创建构建目录
    mkdir -p "$build_dir" "$output_dir"
    
    # 复制配置文件到构建目录
    cp -r "${SCRIPT_DIR}/configs"/* "$build_dir/"
    cp -r "${SCRIPT_DIR}/hooks" "$build_dir/"
    cp -r "${SCRIPT_DIR}/package-lists" "$build_dir/"
    
    cd "$build_dir"
    
    # 使用live-build构建系统
    log_info "初始化live-build..."
    lb config \
        --architectures "$ARCH" \
        --distribution "$DISTRIBUTION" \
        --archive-areas "main contrib non-free" \
        --bootappend-live "boot=live components" \
        --memtest "memtest86+" \
        --win32-loader false \
        --debian-installer false \
        --updates true \
        --security true \
        --apt-recommends false \
        --apt-secure false \
        --binary-images iso-hybrid \
        --iso-volume "${VENDOR}-${PRODUCT}-${VERSION}" \
        --iso-publisher "$VENDOR" \
        --iso-application "Kali Linux for Radxa Cubie A7Z" \
        --zsync false \
        --jffs2 false \
        --checksums md5 \
        --chroot-filesystem squashfs \
        --compression xz \
        --firmware-binary true \
        --firmware-chroot true \
        --swap-file-path /live-swap \
        --swap-file-size 1024 \
        --build-with-chroot true
    
    # 添加自定义配置
    if [[ -f "rootfs.jsonnet" ]]; then
        log_info "应用自定义配置..."
        # 这里可以添加jsonnet到实际配置的转换逻辑
    fi
    
    # 复制钩子脚本
    if [[ -d "hooks" ]]; then
        cp hooks/* config/hooks/normal/
    fi
    
    # 复制包列表
    if [[ -d "package-lists" ]]; then
        cp package-lists/* config/package-lists/
    fi
    
    # 开始构建
    log_info "开始构建过程，这可能需要几个小时..."
    lb build 2>&1 | tee -a "$LOG_FILE"
    
    if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
        log_success "构建成功完成！"
        
        # 移动输出文件
        mv *.iso *.img *.tar* "$output_dir/" 2>/dev/null || true
        
        log_info "构建输出位于: $output_dir"
        ls -lh "$output_dir"
    else
        log_error "构建失败，请检查日志文件: $LOG_FILE"
        exit 1
    fi
}

# 清理函数
cleanup() {
    log_info "清理构建环境..."
    
    # 清理临时文件
    rm -rf /tmp/tmp.*
    apt-get clean
    apt-get autoremove -y
    
    log_success "清理完成"
}

# 显示帮助信息
show_help() {
    echo "Radxa Cubie A7Z Kali Linux 构建系统"
    echo "作者: $VENDOR"
    echo "版本: $VERSION"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help      显示帮助信息"
    echo "  -c, --clean     清理构建环境"
    echo "  -v, --version   显示版本信息"
    echo "  --deps-only     仅安装依赖"
    echo "  --config-only   仅生成配置文件"
    echo ""
    echo "示例:"
    echo "  $0              完整构建"
    echo "  $0 --deps-only  仅安装依赖"
    echo "  $0 --clean      清理环境"
}

# 主函数
main() {
    local action="full"
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--clean)
                action="clean"
                shift
                ;;
            -v|--version)
                echo "$PRODUCT $VERSION"
                exit 0
                ;;
            --deps-only)
                action="deps"
                shift
                ;;
            --config-only)
                action="config"
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 初始化日志
    echo "构建开始于: $(date)" > "$LOG_FILE"
    
    case "$action" in
        "full")
            check_root
            check_requirements
            install_dependencies
            setup_kali_repositories
            clone_radxaos_sdk
            generate_configs
            generate_hooks
            generate_package_lists
            build_system
            cleanup
            ;;
        "deps")
            check_root
            install_dependencies
            ;;
        "config")
            generate_configs
            generate_hooks
            generate_package_lists
            ;;
        "clean")
            cleanup
            ;;
    esac
    
    log_success "所有任务完成！"
    echo "构建结束于: $(date)" >> "$LOG_FILE"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
