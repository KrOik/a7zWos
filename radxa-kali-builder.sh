#!/bin/bash

# Radxa Cubie A7Z Kali Linux build system
# Complete build based on RadxaOS SDK and Kali metapackages
# Author: KrNormyDev
# Version: 1.0.0

set -euo pipefail

# Globals
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/build.log"
VENDOR="KrNormyDev"
PRODUCT="a7zWos"
VERSION="1.0.0"
ARCH="arm64"
DISTRIBUTION="kali-rolling"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Command helpers
run_cmd() {
    # Usage: run_cmd "<command>" "<description>"
    local cmd="$1"; shift || true
    local desc="${1:-Command}"
    log_info "${desc}: ${cmd}"
    bash -c "$cmd" || {
        log_error "Failed: ${desc}"
        return 1
    }
}

run_with_retry() {
    # Usage: run_with_retry <retries> <delay_seconds> "<command>" "<description>"
    local retries="$1"; local delay="$2"; shift 2
    local cmd="$1"; shift || true
    local desc="${1:-Command}"
    local attempt=1
    while true; do
        if bash -c "$cmd"; then
            log_success "${desc} succeeded"
            return 0
        fi
        if (( attempt >= retries )); then
            log_error "${desc} failed after ${attempt} attempts"
            return 1
        fi
        log_warning "${desc} failed (attempt ${attempt}/${retries}); retrying in ${delay}s..."
        sleep "$delay"
        ((attempt++))
    done
}

# Error handling
trap 'log_error "Build failed at line $LINENO"; exit 1' ERR

# Root privilege check
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script requires root privileges"
        exit 1
    fi
}

# System requirements check
check_requirements() {
    log_info "Checking system requirements..."
    
    # Check architecture
    if [[ "$(uname -m)" != "aarch64" ]]; then
        log_warning "Current architecture is not ARM64; some features may be limited"
    fi
    
    # Check disk space
    local disk_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ $disk_space -lt 20 ]]; then
        log_error "Insufficient disk space: need at least 20GB free"
        exit 1
    fi
    
    # Check memory
    local memory=$(free -g | awk 'NR==2 {print $2}')
    if [[ $memory -lt 4 ]]; then
        log_warning "Memory is less than 4GB; build might be slow"
    fi
    
    # Check network connectivity (HTTP-based)
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
        log_error "Network unavailable: cannot access required repositories via HTTP"
        exit 1
    fi
    
    log_success "System requirements check passed"
}

# Install build dependencies
install_dependencies() {
    log_info "Installing build dependencies..."
    
    # Avoid interactive prompts
    export DEBIAN_FRONTEND=noninteractive
    
    run_with_retry 3 3 "apt-get update" "apt-get update"

    # Temporarily hold critical base packages to avoid host upgrades
    local protect_pkgs=("base-files" "libc6" "libc-bin")
    local held_pkgs=()
    for p in "${protect_pkgs[@]}"; do
        if dpkg -l | grep -q "^ii.*$p"; then
            if apt-mark hold "$p" >/dev/null 2>&1; then
                held_pkgs+=("$p")
                log_info "Held package to prevent upgrade: $p"
            fi
        fi
    done

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
        "arch-test"
        "dosfstools"
        "mtools"
        "parted"
        "rsync"
        "xorriso"
        "grub-efi-arm64-bin"
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
    
    local failed_pkgs=()
    for dep in "${deps[@]}"; do
        if ! dpkg -l | grep -q "^ii.*$dep"; then
            log_info "Installing dependency: $dep"
            if ! run_with_retry 2 5 "apt-get install -y --no-upgrade --no-install-recommends $dep" "apt-get install $dep"; then
                failed_pkgs+=("$dep")
            fi
        fi
    done
    if (( ${#failed_pkgs[@]} > 0 )); then
        log_error "Failed to install packages: ${failed_pkgs[*]}"
        return 1
    fi

    # Unhold previously held packages
    for p in "${held_pkgs[@]}"; do
        apt-mark unhold "$p" >/dev/null 2>&1 || true
        log_info "Unheld package: $p"
    done
    
    log_success "Build dependencies installation completed"
}

# Setup Kali repositories
setup_kali_repositories() {
    log_info "Skipping host APT repo changes; using Kali mirrors inside live-build"
    log_success "Repository setup delegated to live-build configuration"
}

# Clone RadxaOS SDK
clone_radxaos_sdk() {
    log_info "Cloning RadxaOS SDK..."
    
    local sdk_dir="${SCRIPT_DIR}/rsdk"
    
    if [[ -d "$sdk_dir" ]]; then
        log_info "RadxaOS SDK exists; updating..."
        cd "$sdk_dir"
        run_cmd "git pull --recurse-submodules" "git pull"
    else
        log_info "Cloning RadxaOS SDK..."
        run_cmd "git clone --recurse-submodules https://github.com/RadxaOS-SDK/rsdk.git $sdk_dir" "git clone"
    fi
    
    cd "$sdk_dir"
    
    # Install Node.js dependencies
    if command -v npm &> /dev/null; then
        npm install @devcontainers/cli || log_warning "npm installation failed"
    fi
    
    # Set environment variables
    export PATH="$PWD/src/bin:$PWD/node_modules/.bin:$PATH"
    
    log_success "RadxaOS SDK ready"
}

# Generate configuration files
generate_configs() {
    log_info "Generating configuration files..."
    
    # Create config directories
    mkdir -p "${SCRIPT_DIR}/configs"
    mkdir -p "${SCRIPT_DIR}/hooks"
    mkdir -p "${SCRIPT_DIR}/package-lists"
    
    # Generate rootfs.jsonnet
    cat > "${SCRIPT_DIR}/configs/rootfs.jsonnet" << EOF
{
    // Base configuration
    "architecture": "$ARCH",
    "distribution": "$DISTRIBUTION",
    "vendor": "$VENDOR",
    "product": "$PRODUCT", 
    "version": "$VERSION",
    
    // Repository configuration
    "repositories": [
        "deb http://http.kali.org/kali kali-rolling main non-free contrib",
        "deb-src http://http.kali.org/kali kali-rolling main non-free contrib",
        "deb https://radxa-repo.github.io/bullseye bullseye main"
    ],
    
    // Base packages
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
    
    // Desktop environment - XFCE for Wayland
    "desktop_packages": [
        "xfce4",
        "xfce4-goodies", 
        "xfce4-panel",
        "thunar",
        "gtk3-engines-xfce"
    ],
    
    // Wayland packages
    "wayland_packages": [
        "wayland-protocols",
        "libwayland-client0",
        "weston",
        "sway",
        "waybar",
        "wofi",
        "foot"
    ],
    
    // ZSH shell packages
    "shell_packages": [
        "zsh",
        "git",
        "curl",
        "wget"
    ],
    
    // Radxa hardware support packages
    "radxa_packages": [
        "firmware-realtek",
        "firmware-atheros", 
        "firmware-brcm80211",
        "firmware-libertas",
        "firmware-misc-nonfree",
        "radxa-system-config",
        "libmraa-dev"
    ],
    
    // Waydroid support
    "waydroid_packages": [
        "waydroid",
        "python3-gbinder",
        "lxc",
        "cgroupfs-mount"
    ],
    
    // Custom hook scripts
    "custom_hooks": [
        "9990-radxa-hardware-initialization.chroot",
        "9991-waydroid-nokvm-configuration.chroot", 
        "9992-kali-tools-configuration.chroot",
        "9993-zsh-configuration.chroot",
        "9994-wayland-desktop-configuration.chroot", 
        "9995-vendor-information.chroot"
    ],
    
    // Build options
    "build_options": {
        "compression": "xz",
        "memtest": true,
        "apt_recommends": false,
        "apt_secure": false
    }
}
EOF
    
    log_success "Configuration files generated"
}

# Generate hook scripts
generate_hooks() {
    log_info "Generating hook scripts..."
    
    # 9990 - Radxa hardware initialization
    cat > "${SCRIPT_DIR}/hooks/9990-radxa-hardware-initialization.chroot" << 'EOF'
#!/bin/bash

set -Eeuo pipefail

echo "=== Radxa Hardware Initialization ==="

RADXA_FW=(
  firmware-realtek
  firmware-atheros
  firmware-brcm80211
  firmware-libertas
  firmware-misc-nonfree
  radxa-system-config
)
apt-get install -y "${RADXA_FW[@]}"

# Configure device tree
cp /usr/lib/linux-image-*/allwinner/a733-cubie-a7z.dtb /boot/

# GPIO support
apt-get install -y libmraa-dev python3-mraa

# I2C support
echo "i2c-dev" >> /etc/modules-load.d/radxa.conf

# SPI support
echo "spidev" >> /etc/modules-load.d/radxa.conf

# Hardware permissions
if id "kali" &>/dev/null; then
  usermod -a -G gpio,dialout,i2c,spi kali
fi

echo "Radxa hardware initialization completed"
EOF

    # 9991 - Waydroid no-KVM configuration
    cat > "${SCRIPT_DIR}/hooks/9991-waydroid-nokvm-configuration.chroot" << 'EOF'
#!/bin/bash

set -Eeuo pipefail

echo "=== Waydroid no-KVM Configuration ==="

# Install Waydroid and dependencies
apt-get install -y waydroid python3-gbinder lxc cgroupfs-mount

# Waydroid no-KVM mode
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

# Unprivileged LXC container config
cat > /etc/lxc/default.conf << 'LXC_EOF'
lxc.net.0.type = veth
lxc.net.0.link = lxcbr0
lxc.net.0.flags = up
lxc.net.0.hwaddr = 00:16:3e:xx:xx:xx
lxc.idmap = u 0 100000 65536
lxc.idmap = g 0 100000 65536
LXC_EOF

# Enable IP forwarding
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

echo "Waydroid no-KVM configuration completed"
EOF

    # 9992 - Kali tools configuration
    cat > "${SCRIPT_DIR}/hooks/9992-kali-tools-configuration.chroot" << 'EOF'
#!/bin/bash

set -Eeuo pipefail

echo "=== Kali Tools Configuration ==="

KALI_BASE=(kali-linux-core kali-desktop-core)
apt-get install -y "${KALI_BASE[@]}"

apt-get install -y kali-tools-information-gathering

apt-get install -y kali-tools-vulnerability

apt-get install -y kali-tools-web

apt-get install -y kali-tools-802-11 kali-tools-bluetooth kali-tools-rfid kali-tools-sdr

# Networking tools
apt-get install -y wireless-tools rfkill crda

# Create helper script
mkdir -p /usr/local/bin

cat > /usr/local/bin/kali-tools-info << 'TOOLS_EOF'
#!/bin/bash
echo "=== Kali Tools Status ==="
echo "Nmap: $(nmap --version | head -1)"
echo "Aircrack-ng: $(aircrack-ng --version 2>/dev/null | head -1)"
echo "Metasploit: $(msfconsole --version 2>/dev/null)"
echo "Wireshark: $(tshark --version 2>/dev/null | head -1)"
echo "SQLMap: $(sqlmap --version 2>/dev/null)"
TOOLS_EOF

chmod +x /usr/local/bin/kali-tools-info

echo "Kali tools configuration completed"
EOF

    # 9993 - ZSH configuration
    cat > "${SCRIPT_DIR}/hooks/9993-zsh-configuration.chroot" << 'EOF'
#!/bin/bash

set -Eeuo pipefail

echo "=== ZSH Shell Configuration ==="

# Install ZSH and tools
apt-get install -y zsh git curl wget

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Configure .zshrc
cat > /etc/skel/.zshrc << 'ZSH_EOF'
# oh-my-zsh configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting docker)
source $ZSH/oh-my-zsh.sh

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias update='sudo apt update && sudo apt upgrade'
alias kali='kali-tools-info'

# Kali-specific settings
export PATH=$PATH:/usr/share/metasploit-framework
export MSF_DATABASE_CONFIG=/usr/share/metasploit-framework/config/database.yml
ZSH_EOF

# Set ZSH as default shell
if command -v chsh >/dev/null 2>&1; then
  chsh -s /bin/zsh || true
  chsh -s /bin/zsh kali || true
fi

# Copy config to existing user
if id "kali" &>/dev/null; then
    cp /etc/skel/.zshrc /home/kali/
    chown kali:kali /home/kali/.zshrc
fi

echo "ZSH configuration completed"
EOF

    # 9994 - Wayland desktop configuration
    cat > "${SCRIPT_DIR}/hooks/9994-wayland-desktop-configuration.chroot" << 'EOF'
#!/bin/bash

set -Eeuo pipefail

echo "=== Wayland Desktop Configuration ==="

# Install Wayland compositor
apt-get install -y wayland-protocols libwayland-client0 weston sway waybar wofi foot

# Install XFCE for Wayland
apt-get install -y xfce4 xfce4-goodies xfce4-panel thunar gtk3-engines-xfce

# Sway compositor configuration
cat > /etc/sway/config << 'SWAY_EOF'
# Sway configuration - for Radxa Kali
set $mod Mod4

# Basic configuration
output * bg /usr/share/backgrounds/kali/kali-linux.png fill
xwayland enable

# Key bindings
bindsym $mod+Return exec foot
bindsym $mod+Shift+q kill
bindsym $mod+d exec wofi --show drun
bindsym $mod+Shift+e exec swaynag -t warning -m 'Exit Sway?' -b 'Yes' 'swaymsg exit'

# Workspaces
bindsym $mod+1 workspace number 1
bindsym $mod+2 workspace number 2
bindsym $mod+3 workspace number 3
bindsym $mod+4 workspace number 4

# Window management
floating_modifier $mod
bindsym $mod+h focus left
bindsym $mod+j focus down
bindsym $mod+k focus up
bindsym $mod+l focus right

# Autostart apps
exec waybar
exec nm-applet
SWAY_EOF

# Waybar configuration
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

# Startup scripts
cat > /usr/local/bin/start-wayland.sh << 'START_EOF'
#!/bin/bash
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export WAYLAND_DISPLAY=wayland-0
export XWAYLAND_ENABLE=1
export XWAYLAND_GLAMOR=1

# Start Sway
exec sway
START_EOF

cat > /usr/local/bin/start-xfce-wayland.sh << 'XFCE_START_EOF'
#!/bin/bash
export GDK_BACKEND=wayland
export CLUTTER_BACKEND=wayland
export XDG_SESSION_TYPE=wayland

# Start XFCE Wayland session
exec dbus-run-session startxfce4
XFCE_START_EOF

chmod +x /usr/local/bin/start-wayland.sh /usr/local/bin/start-xfce-wayland.sh

# Compatibility libraries
apt-get install -y xwayland qtwayland5 qt5-qpa-plugin-wayland gtk-layer-shell libgtk-3-0

echo "Wayland desktop configuration completed"
EOF

    # 9995 - Vendor information configuration
    cat > "${SCRIPT_DIR}/hooks/9995-vendor-information.chroot" << EOF
#!/bin/bash

set -Eeuo pipefail

echo "=== Vendor Information Configuration ==="

# Set vendor/product/version files
echo "$VENDOR" > /etc/vendor-name
echo "$PRODUCT" > /etc/product-name
echo "$VERSION" > /etc/product-version

# Create vendor info file (expand variables here)
cat > /etc/kali-radxa-info << VENDOR_EOF
# Radxa Kali Linux - $VENDOR Edition
VENDOR=$VENDOR
PRODUCT=$PRODUCT
VERSION=$VERSION
BUILD_DATE=$(date +%Y%m%d)
KALI_VERSION=kali-rolling
RADXA_TARGET=cubie-a7z
VENDOR_EOF

# Create system identifier
cat > /etc/os-release-radxa << OS_EOF
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

# Create MOTD (expand variables here; keep ASCII to avoid encoding issues)
cat > /etc/motd << MOTD_EOF
Welcome to Kali Linux $VENDOR Edition!
- Wayland desktop is ready
- ZSH shell is configured
- Kali pentest tools installed
- Radxa hardware support enabled
- Waydroid container configured

System info:
- Vendor: $VENDOR
- Product: $PRODUCT
- Version: $VERSION
- Architecture: $ARCH
- Distribution: $DISTRIBUTION
MOTD_EOF

echo "Vendor information configuration completed"
EOF

    # 设置钩子脚本权限
    chmod +x "${SCRIPT_DIR}/hooks"/*.chroot
    
    log_success "Hook scripts generated"
}

# Generate package lists
generate_package_lists() {
    log_info "Generating package lists..."
    
    # Kali core packages
    cat > "${SCRIPT_DIR}/package-lists/kali-core.list" << 'EOF'
# Kali Linux core packages
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

    # Radxa hardware support
    cat > "${SCRIPT_DIR}/package-lists/radxa-hardware.list" << 'EOF'
# Radxa hardware support packages
firmware-realtek
firmware-atheros
firmware-brcm80211
firmware-libertas
firmware-misc-nonfree
radxa-system-config
libmraa-dev
python3-mraa
EOF

    # Wayland desktop
    cat > "${SCRIPT_DIR}/package-lists/wayland-desktop.list" << 'EOF'
# Wayland desktop packages
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

    # ZSH shell
    cat > "${SCRIPT_DIR}/package-lists/zsh-shell.list" << 'EOF'
# ZSH shell and tools
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

    # Waydroid support
    cat > "${SCRIPT_DIR}/package-lists/waydroid.list" << 'EOF'
# Waydroid Android container support
waydroid
python3-gbinder
lxc
cgroupfs-mount
bridge-utils
iptables
EOF

    # Network tools
    cat > "${SCRIPT_DIR}/package-lists/network-tools.list" << 'EOF'
# Network tools
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

    log_success "Package lists generated"
}

# Build system
build_system() {
    log_info "Starting Radxa Kali Linux build..."
    
    local build_dir="${SCRIPT_DIR}/build"
    local output_dir="${SCRIPT_DIR}/output"
    
    # Create build directories
    mkdir -p "$build_dir" "$output_dir"
    
    # Copy configs to build directory
    cp -r "${SCRIPT_DIR}/configs"/* "$build_dir/"
    cp -r "${SCRIPT_DIR}/hooks" "$build_dir/"
    cp -r "${SCRIPT_DIR}/package-lists" "$build_dir/"
    
    cd "$build_dir"
    
    # Configure live-build
    log_info "Initializing live-build..."
    # Ensure prior configs do not leak outdated mirrors or options
    lb clean || true
    lb config \
        --architectures "$ARCH" \
        --distribution "$DISTRIBUTION" \
        --archive-areas "main contrib non-free" \
        --bootappend-live "boot=live components" \
        --memtest "memtest86+" \
        --win32-loader false \
        --debian-installer none \
        --updates true \
        --security true \
        --apt-recommends false \
        --apt-secure false \
        --bootloaders grub-efi \
        --mirror-bootstrap "http://http.kali.org/kali" \
        --mirror-chroot "http://http.kali.org/kali" \
        --mirror-binary "http://http.kali.org/kali" \
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
    
    # Apply custom config if present
    if [[ -f "rootfs.jsonnet" ]]; then
        log_info "Applying custom configuration..."
        # TODO: convert jsonnet to actual config if needed
    fi
    
    # Copy hook scripts
    if [[ -d "hooks" ]]; then
        cp hooks/* config/hooks/normal/
    fi
    
    # Copy package lists
    if [[ -d "package-lists" ]]; then
        cp package-lists/* config/package-lists/
    fi
    
    # Build
    log_info "Starting build; this may take several hours..."
    lb build 2>&1 | tee -a "$LOG_FILE"
    
    if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
        log_success "Build completed successfully!"
        
        # Move output files
        mv *.iso *.img *.tar* "$output_dir/" 2>/dev/null || true
        
        log_info "Build artifacts located at: $output_dir"
        ls -lh "$output_dir"
    else
        log_error "Build failed; check log file: $LOG_FILE"
        exit 1
    fi
}

# Cleanup
cleanup() {
    log_info "Cleaning build environment..."
    
    # Clean temporary files
    rm -rf /tmp/tmp.*
    apt-get clean
    apt-get autoremove -y
    
    log_success "Cleanup completed"
}

# Help
show_help() {
    echo "Radxa Cubie A7Z Kali Linux build system"
    echo "Author: $VENDOR"
    echo "Version: $VERSION"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show help"
    echo "  -c, --clean     Clean build environment"
    echo "  -v, --version   Show version"
    echo "  --deps-only     Install dependencies only"
    echo "  --config-only   Generate configs only"
    echo ""
    echo "Examples:"
    echo "  $0              Full build"
    echo "  $0 --deps-only  Dependencies only"
    echo "  $0 --clean      Clean environment"
}

# Main
main() {
    local action="full"
    
    # Parse CLI arguments
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
                log_error "Unknown argument: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Initialize log
    echo "Build started at: $(date)" > "$LOG_FILE"
    
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
    
    log_success "All tasks completed!"
    echo "Build finished at: $(date)" >> "$LOG_FILE"
}

# Entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
