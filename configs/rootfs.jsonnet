{
    // 基础配置
    "architecture": "arm64",
    "distribution": "kali-rolling",
    "vendor": "KrNormyDev",
    "product": "a7zWos", 
    "version": "1.0.0",
    
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
