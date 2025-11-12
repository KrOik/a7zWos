DONT! USE! THIS! WAIT FOR NEWER RELEASE! its not fully prepared!
# Radxa Cubie A7Z Kali Linux Build System

基于KrNormyDev/a7zWos的Radxa Cubie A7Z开发板Kali Linux构建系统，支持Wayland桌面环境、Waydroid容器和完整的Kali安全工具套件。

## 🚀 项目概述

本项目提供了一个完整的Kali Linux构建系统，专门为Radxa Cubie A7Z开发板优化，包含：

- **硬件兼容性**: 完整的Radxa Cubie A7Z硬件驱动支持
- **桌面环境**: 基于Wayland的现代桌面环境（Weston/Sway）
- **容器支持**: Waydroid Android容器运行环境
- **安全工具**: 完整的Kali Linux安全工具套件
- **开发环境**: 完整的开发工具链和调试环境

## 📋 系统特性

### 硬件支持
- ✅ Radxa Cubie A7Z专用硬件驱动
- ✅ GPIO/I2C/SPI/UART接口支持
- ✅ 摄像头和传感器支持
- ✅ 无线网络和蓝牙支持
- ✅ GPU和显示支持
- ✅ 音频和多媒体支持

### 桌面环境
- ✅ Wayland显示服务器
- ✅ Weston和Sway窗口管理器
- ✅ Waybar状态栏
- ✅ Wofi应用启动器
- ✅ Foot终端模拟器
- ✅ XWayland兼容性

### 容器支持
- ✅ Waydroid Android容器
- ✅ 无需KVM支持
- ✅ 完整的Android应用兼容性
- ✅ 网络和硬件访问

### 安全工具
- ✅ 信息收集工具（Nmap、Masscan、Recon-ng等）
- ✅ 漏洞分析工具（Nikto、OpenVAS、Lynis等）
- ✅ Web应用工具（SQLMap、Burp Suite、ZAP等）
- ✅ 无线安全工具（Aircrack-ng、Wifite等）
- ✅ 后渗透工具（Metasploit、Empire等）
- ✅ 网络工具（Wireshark、Tcpdump等）
- ✅ 密码破解工具（Hashcat、John the Ripper等）
- ✅ 逆向工程工具（Radare2、GDB等）

## 🛠️ 构建系统

### 项目结构
```
radxa-cubie-a7z-kali-build-system/
├── configs/                    # 配置文件目录
│   ├── rootfs.jsonnet         # 主构建配置模板
│   └── hooks/                 # 构建钩子脚本
│       ├── 9990-radxa-hardware-init.chroot
│       ├── 9991-waydroid-nokvm-setup.chroot
│       ├── 9992-kali-tools-config.chroot
│       ├── 9993-zsh-terminal-setup.chroot
│       ├── 9994-wayland-desktop-setup.chroot
│       └── 9995-vendor-information.chroot
├── package-lists/              # 软件包列表
│   ├── kali-core.list         # Kali核心工具
│   ├── radxa-hardware.list    # Radxa硬件驱动
│   ├── wayland-desktop.list   # Wayland桌面环境
│   ├── zsh-shell.list       # ZSH终端环境
│   └── waydroid.list          # Waydroid容器支持
├── radxa-kali-builder.sh     # 主构建脚本
├── quick-deploy.sh            # 快速部署脚本
├── build-validator.sh         # 构建验证脚本
├── hardware-test.sh           # 硬件兼容性测试
├── security-test.sh           # 安全工具功能测试
└── README.md                  # 项目文档
```

### 核心脚本

#### 主构建脚本 (`radxa-kali-builder.sh`)
- 环境检查和依赖安装
- 配置文件生成
- 软件包列表管理
- 钩子脚本执行
- 构建过程监控

#### 快速部署脚本 (`quick-deploy.sh`)
- 一键部署功能
- 自动依赖安装
- 构建环境配置
- 错误处理和恢复

#### 验证和测试脚本
- `build-validator.sh`: 构建系统完整性验证
- `hardware-test.sh`: 硬件兼容性测试
- `security-test.sh`: 安全工具功能测试

## 🔧 快速开始

### 系统要求
- Ubuntu 20.04+ 或 Debian 11+
- 至少8GB内存
- 50GB可用磁盘空间
- 网络连接

### 快速部署
```bash
# 克隆项目
git clone https://github.com/KrNormyDev/radxa-cubie-a7z-kali-build-system.git
cd radxa-cubie-a7z-kali-build-system

# 运行快速部署
./quick-deploy.sh

# 开始构建
./radxa-kali-builder.sh
```

### 手动构建
```bash
# 安装依赖
sudo apt update
sudo apt install -y build-essential git debootstrap qemu-user-static

# 配置构建环境
mkdir -p build
chmod +x *.sh

# 运行构建
./radxa-kali-builder.sh --config configs/rootfs.jsonnet
```

## 📊 构建配置

### 主要配置选项
```jsonnet
{
  architecture: "arm64",
  base_system: "kali-rolling",
  hostname: "radxa-cubie-a7z-kali",
  kernel_version: "5.15.0-radxa-cubie-a7z",
  packages: [
    "kali-core",
    "radxa-hardware", 
    "wayland-desktop",
    "zsh-shell",
    "waydroid"
  ],
  hooks: [
    "9990-radxa-hardware-init",
    "9991-waydroid-nokvm-setup",
    "9992-kali-tools-config",
    "9993-zsh-terminal-setup",
    "9994-wayland-desktop-setup",
    "9995-vendor-information"
  ]
}
```

### 自定义配置
```bash
# 创建自定义配置
cp configs/rootfs.jsonnet configs/custom.jsonnet

# 编辑配置
vim configs/custom.jsonnet

# 使用自定义配置构建
./radxa-kali-builder.sh --config configs/custom.jsonnet
```

## 🧪 测试和验证

### 构建验证
```bash
# 验证构建系统
./build-validator.sh

# 验证特定组件
./build-validator.sh --component hardware
./build-validator.sh --component security
./build-validator.sh --component waydroid
```

### 硬件测试
```bash
# 运行硬件兼容性测试
./hardware-test.sh

# 测试特定硬件组件
./hardware-test.sh --test cpu
./hardware-test.sh --test wireless
./hardware-test.sh --test gpio
```

### 安全工具测试
```bash
# 运行安全工具功能测试
./security-test.sh

# 测试特定工具类别
./security-test.sh --category web
./security-test.sh --category wireless
./security-test.sh --category exploitation
```

## 📦 软件包管理

### 包列表文件
- `kali-core.list`: Kali Linux核心安全工具
- `radxa-hardware.list`: Radxa Cubie A7Z硬件驱动
- `wayland-desktop.list`: Wayland桌面环境组件
- `zsh-shell.list`: ZSH终端和基础工具
- `waydroid.list`: Waydroid容器运行环境

### 添加自定义包
```bash
# 创建新的包列表
echo "custom-package" >> package-lists/custom.list

# 在配置中添加包列表
sed -i '/packages:/a\    "custom"' configs/rootfs.jsonnet
```

## 🔧 钩子脚本

### 钩子脚本功能
1. **9990-radxa-hardware-init**: 初始化Radxa硬件支持
2. **9991-waydroid-nokvm-setup**: 配置Waydroid无需KVM
3. **9992-kali-tools-config**: 配置Kali安全工具
4. **9993-zsh-terminal-setup**: 设置ZSH终端环境
5. **9994-wayland-desktop-setup**: 配置Wayland桌面
6. **9995-vendor-information**: 设置厂商信息

### 自定义钩子
```bash
# 创建自定义钩子
cp configs/hooks/9995-vendor-information.chroot configs/hooks/9996-custom-setup.chroot

# 编辑钩子脚本
vim configs/hooks/9996-custom-setup.chroot

# 在配置中添加钩子
sed -i '/hooks:/a\    "9996-custom-setup"' configs/rootfs.jsonnet
```

## 🐛 故障排除

### 常见问题

#### 构建失败
```bash
# 检查依赖
./build-validator.sh --check-deps

# 清理构建缓存
sudo rm -rf build/

# 重新构建
./radxa-kali-builder.sh --clean
```

#### 硬件兼容性问题
```bash
# 运行硬件测试
./hardware-test.sh --verbose

# 检查硬件信息
radxa-info

# 查看系统日志
journalctl -xe
```

#### 安全工具问题
```bash
# 运行安全工具测试
./security-test.sh --verbose

# 检查工具配置
kali-tools-update

# 重新配置工具
msfdb init
```

#### Waydroid问题
```bash
# 检查Waydroid状态
waydroid status

# 重新初始化Waydroid
waydroid-init

# 查看Waydroid日志
waydroid log
```

## 📚 使用文档

### 基本使用
```bash
# 系统信息
radxa-info
system-validate

# 硬件测试
radxa-test

# 安全工具
pentest-launcher
kali-tools-update

# Wayland桌面
wayland-test
wayland-troubleshoot

# ZSH配置
zsh-config
zsh-quick-setup
```

### 高级功能
```bash
# 系统验证
system-validate --full

# 硬件诊断
radxa-test --stress-test

# 网络诊断
network-troubleshoot

# 性能监控
performance-monitor
```

## 🤝 贡献指南

### 开发环境设置
```bash
# 安装开发依赖
sudo apt install -y shellcheck bats

# 运行代码检查
shellcheck *.sh

# 运行测试
bats tests/
```

### 提交规范
- 使用清晰的提交消息
- 添加适当的测试
- 更新相关文档
- 遵循代码风格指南

## 📄 许可证

本项目基于KrNormyDev/a7zWos项目，遵循相应的开源许可证。

## 🙏 致谢

- [KrNormyDev/a7zWos](https://github.com/KrNormyDev/a7zWos) - 基础构建系统
- [Kali Linux](https://www.kali.org/) - 安全工具发行版
- [Radxa](https://radxa.com/) - 硬件支持
- [Wayland](https://wayland.freedesktop.org/) - 显示服务器协议
- [Waydroid](https://waydro.id/) - Android容器运行时

## 📞 支持

如有问题或建议，请通过以下方式联系：
- 提交Issue
- 发送邮件
- 社区论坛

---

**注意**: 本项目仅供教育和授权测试使用。请确保在合法授权的情况下使用安全工具。
