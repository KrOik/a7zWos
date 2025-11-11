#!/bin/bash

# 项目结构创建脚本
# project-setup.sh
# 创建完整的项目目录结构和基础文件

set -e

# 全局变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Radxa Cubie A7Z Kali Linux Build System Project Setup ===${NC}"
echo

# 创建项目目录结构
echo -e "${GREEN}创建项目目录结构...${NC}"

# 主目录
mkdir -p "$PROJECT_ROOT"/{configs/hooks,package-lists,tests,docs,build,logs,output}

# 配置文件目录
mkdir -p "$PROJECT_ROOT"/configs/{hooks,templates,overlays}

# 包列表目录
mkdir -p "$PROJECT_ROOT"/package-lists/{core,desktop,hardware,security,development}

# 测试目录
mkdir -p "$PROJECT_ROOT"/tests/{unit,integration,hardware,security}

# 文档目录
mkdir -p "$PROJECT_ROOT"/docs/{user-guide,developer-guide,api-reference}

# 构建输出目录
mkdir -p "$PROJECT_ROOT"/{build,logs,output}/{images,packages,cache}

echo -e "${GREEN}✓ 目录结构创建完成${NC}"

# 创建基础文件
echo -e "${GREEN}创建基础文件...${NC}"

# 创建 .gitignore
cat > "$PROJECT_ROOT/.gitignore" << 'EOF'
# 构建输出
build/
output/
logs/
*.log
*.img
*.iso
*.tar.gz
*.zip

# 缓存文件
.cache/
*.cache
*.tmp
*.temp

# 临时文件
*.swp
*.swo
*~
.DS_Store
Thumbs.db

# 编辑器文件
.vscode/
.idea/
*.sublime-*

# 系统文件
*.deb
*.rpm
*.tar
*.gz
*.bz2
*.xz

# 镜像文件
*.img
*.iso
*.qcow2
*.vmdk
*.vdi

# 密钥和证书
*.key
*.pem
*.crt
*.csr
*.p12
*.pfx

# 配置文件（本地覆盖）
configs/local/
configs/overlays/local/

# 测试结果
tests/results/
tests/reports/
*.test-results
*.test-report

# 包缓存
packages/
cache/

# 下载文件
downloads/
EOF

echo -e "${GREEN}✓ .gitignore 创建完成${NC}"

# 创建项目元数据
cat > "$PROJECT_ROOT/PROJECT_INFO" << 'EOF'
Radxa Cubie A7Z Kali Linux Build System
========================================

项目信息:
- 名称: Radxa Cubie A7Z Kali Linux Build System
- 版本: 1.0.0
- 作者: KrNormyDev
- 许可证: MIT
- 描述: 基于KrNormyDev/a7zWos的Radxa Cubie A7Z开发板Kali Linux构建系统

构建目标:
- Radxa Cubie A7Z开发板
- Kali Linux Rolling
- Wayland桌面环境
- Waydroid Android容器
- 完整的安全工具套件

特性:
- 硬件兼容性优化
- 现代桌面环境
- 容器化Android支持
- 完整的渗透测试工具
- 自动化构建流程
- 全面的测试验证
EOF

echo -e "${GREEN}✓ 项目信息文件创建完成${NC}"

# 创建版本文件
cat > "$PROJECT_ROOT/VERSION" << 'EOF'
1.0.0
EOF

echo -e "${GREEN}✓ 版本文件创建完成${NC}"

# 创建构建说明
cat > "$PROJECT_ROOT/BUILD_INSTRUCTIONS.md" << 'EOF'
# 构建说明

## 快速构建
```bash
# 运行快速部署
./quick-deploy.sh

# 开始构建
./radxa-kali-builder.sh
```

## 手动构建
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

## 高级构建选项
```bash
# 使用自定义配置
./radxa-kali-builder.sh --config configs/custom.jsonnet

# 启用调试模式
./radxa-kali-builder.sh --debug

# 指定输出目录
./radxa-kali-builder.sh --output-dir /path/to/output

# 并行构建
./radxa-kali-builder.sh --parallel 4
```

## 构建验证
```bash
# 验证构建系统
./build-validator.sh

# 验证特定组件
./build-validator.sh --component hardware
./build-validator.sh --component security
```

## 故障排除
```bash
# 检查依赖
./build-validator.sh --check-deps

# 清理构建缓存
sudo rm -rf build/

# 重新构建
./radxa-kali-builder.sh --clean
```
EOF

echo -e "${GREEN}✓ 构建说明创建完成${NC}"

# 创建测试说明
cat > "$PROJECT_ROOT/TESTING_GUIDE.md" << 'EOF'
# 测试指南

## 硬件测试
```bash
# 运行完整硬件测试
./hardware-test.sh

# 测试特定组件
./hardware-test.sh --test cpu
./hardware-test.sh --test wireless
./hardware-test.sh --test gpio
```

## 安全工具测试
```bash
# 运行安全工具测试
./security-test.sh

# 测试特定工具类别
./security-test.sh --category web
./security-test.sh --category wireless
./security-test.sh --category exploitation
```

## 构建验证
```bash
# 验证构建系统
./build-validator.sh

# 验证特定组件
./build-validator.sh --component hardware
./build-validator.sh --component security
./build-validator.sh --component waydroid
```

## 集成测试
```bash
# 运行所有测试
./run-all-tests.sh

# 生成测试报告
./generate-test-report.sh
```

## 测试报告
测试报告将生成在:
- `/tmp/hardware-test-report.txt`
- `/tmp/security-test-report.txt`
- `/tmp/build-validation-report.txt`
EOF

echo -e "${GREEN}✓ 测试指南创建完成${NC}"

# 创建使用说明
cat > "$PROJECT_ROOT/USAGE_GUIDE.md" << 'EOF'
# 使用指南

## 系统信息
```bash
# 查看系统信息
radxa-info

# 系统验证
system-validate

# 硬件信息
radxa-test
```

## 桌面环境
```bash
# 启动Wayland会话
wayland-start

# 测试Wayland
wayland-test

# Wayland故障排除
wayland-troubleshoot
```

## Waydroid容器
```bash
# 初始化Waydroid
waydroid-init

# 启动Waydroid
waydroid-start

# 检查Waydroid状态
waydroid status

# 查看Waydroid日志
waydroid log
```

## 安全工具
```bash
# 启动渗透测试环境
pentest-launcher

# 更新安全工具
kali-tools-update

# 查看工具列表
kali-tools-list
```

## ZSH终端
```bash
# 配置ZSH
zsh-config

# 快速设置ZSH
zsh-quick-setup

# 查看ZSH状态
zsh-status
```

## 系统管理
```bash
# 系统更新
apt update && apt upgrade

# 清理系统
apt autoremove && apt autoclean

# 查看系统日志
journalctl -xe
```
EOF

echo -e "${GREEN}✓ 使用指南创建完成${NC}"

# 创建开发指南
cat > "$PROJECT_ROOT/DEVELOPMENT_GUIDE.md" << 'EOF'
# 开发指南

## 项目结构
```
radxa-cubie-a7z-kali-build-system/
├── configs/                    # 配置文件
│   ├── rootfs.jsonnet         # 主配置模板
│   └── hooks/                 # 构建钩子
├── package-lists/              # 软件包列表
├── tests/                     # 测试脚本
├── docs/                      # 文档
├── build/                     # 构建输出
├── logs/                      # 日志文件
└── output/                    # 最终输出
```

## 添加新功能

### 1. 添加新的包列表
```bash
# 创建新的包列表文件
echo "package1\npackage2" > package-lists/custom.list

# 在配置中添加引用
sed -i '/packages:/a\    "custom"' configs/rootfs.jsonnet
```

### 2. 添加新的钩子脚本
```bash
# 创建新的钩子脚本
cp configs/hooks/template.chroot configs/hooks/9996-custom.chroot

# 编辑钩子内容
vim configs/hooks/9996-custom.chroot

# 在配置中添加引用
sed -i '/hooks:/a\    "9996-custom"' configs/rootfs.jsonnet
```

### 3. 添加新的测试
```bash
# 创建测试脚本
cat > tests/hardware/test-custom.sh << 'EOF'
#!/bin/bash
# 自定义硬件测试


# 添加执行权限
# chmod +x tests/hardware/test-custom.sh  # 文件不存在，跳过


## 代码规范
- 使用Bash 4.0+语法
- 添加适当的错误处理
- 包含详细的注释
- 遵循ShellCheck规范

## 测试要求
- 所有新功能必须包含测试
- 测试必须覆盖主要用例
- 测试结果必须可验证
- 添加适当的文档

## 提交规范
- 使用清晰的提交消息
- 包含适当的测试
- 更新相关文档
- 遵循项目风格指南
EOF

echo -e "${GREEN}✓ 开发指南创建完成${NC}"

# 创建变更日志
cat > "$PROJECT_ROOT/CHANGELOG.md" << 'EOF'
# 变更日志

## [1.0.0] - 2024-01-01

### 新增
- 完整的Radxa Cubie A7Z Kali Linux构建系统
- Wayland桌面环境支持（Weston/Sway）
- Waydroid Android容器支持
- 完整的Kali安全工具套件
- 硬件兼容性测试
- 安全工具功能测试
- 构建系统验证
- 自动化部署脚本

### 特性
- 硬件驱动自动检测和配置
- 现代Wayland桌面环境
- 无需KVM的Waydroid支持
- 完整的渗透测试工具环境
- ZSH终端和oh-my-zsh配置
- 系统验证和故障排除工具

### 优化
- 构建过程优化
- 包管理优化
- 测试流程优化
- 文档完善

### 修复
- 硬件兼容性问题
- 构建依赖问题
- 工具配置问题
- 系统稳定性问题
EOF

echo -e "${GREEN}✓ 变更日志创建完成${NC}"

# 创建许可证文件
cat > "$PROJECT_ROOT/LICENSE" << 'EOF'
MIT License

Copyright (c) 2024 KrNormyDev

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

echo -e "${GREEN}✓ 许可证文件创建完成${NC}"

# 创建运行所有测试的脚本
cat > "$PROJECT_ROOT/run-all-tests.sh" << 'EOF'
#!/bin/bash

# 运行所有测试脚本
# run-all-tests.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== 运行所有测试 ==="
echo

# 运行构建验证
echo "1. 运行构建验证测试..."
if [ -f "$PROJECT_ROOT/build-validator.sh" ]; then
    "$PROJECT_ROOT/build-validator.sh"
else
    echo "警告: build-validator.sh 不存在"
fi
echo

# 运行硬件测试
echo "2. 运行硬件兼容性测试..."
if [ -f "$PROJECT_ROOT/hardware-test.sh" ]; then
    "$PROJECT_ROOT/hardware-test.sh"
else
    echo "警告: hardware-test.sh 不存在"
fi
echo

# 运行安全工具测试
echo "3. 运行安全工具功能测试..."
if [ -f "$PROJECT_ROOT/security-test.sh" ]; then
    "$PROJECT_ROOT/security-test.sh"
else
    echo "警告: security-test.sh 不存在"
fi
echo

echo "=== 所有测试完成 ==="
echo "测试报告位置:"
echo "- /tmp/build-validation-report.txt"
echo "- /tmp/hardware-test-report.txt"
echo "- /tmp/security-test-report.txt"
EOF

chmod +x "$PROJECT_ROOT/run-all-tests.sh"

echo -e "${GREEN}✓ 测试运行脚本创建完成${NC}"

# 创建测试报告生成脚本
cat > "$PROJECT_ROOT/generate-test-report.sh" << 'SCRIPT'
#!/bin/bash

# 生成综合测试报告
# generate-test-report.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_DIR="/tmp"
REPORT_FILE="$REPORT_DIR/combined-test-report-$(date +%Y%m%d-%H%M%S).html"

echo "=== 生成综合测试报告 ==="

# 创建HTML报告
cat > "$REPORT_FILE" << 'HTML'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Radxa Cubie A7Z Kali Linux 构建系统测试报告</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .pass { color: green; }
        .fail { color: red; }
        .warning { color: orange; }
        .info { color: blue; }
        pre { background-color: #f5f5f5; padding: 10px; border-radius: 3px; overflow-x: auto; }
        .timestamp { font-size: 0.9em; color: #666; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Radxa Cubie A7Z Kali Linux 构建系统测试报告</h1>
        <p class="timestamp">生成时间: EOF
date '+%Y-%m-%d %H:%M:%S' >> "$REPORT_FILE"

cat >> "$REPORT_FILE" << 'EOF'
</p>
    </div>

    <div class="section">
        <h2>测试概述</h2>
        <p>本报告包含构建系统验证、硬件兼容性测试和安全工具功能测试的综合结果。</p>
    </div>

    <div class="section">
        <h2>构建系统验证</h2>
EOF

# 添加构建验证结果
if [ -f "/tmp/build-validation-report.txt" ]; then
    echo "<pre>$(cat /tmp/build-validation-report.txt)</pre>" >> "$REPORT_FILE"
else
    echo "<p class="warning">构建验证报告不存在</p>" >> "$REPORT_FILE"
fi

echo "    </div>" >> "$REPORT_FILE"

echo "    <div class=\"section\">" >> "$REPORT_FILE"
echo "        <h2>硬件兼容性测试</h2>" >> "$REPORT_FILE"

# 添加硬件测试结果
if [ -f "/tmp/hardware-test-report.txt" ]; then
    echo "<pre>$(cat /tmp/hardware-test-report.txt)</pre>" >> "$REPORT_FILE"
else
    echo "<p class=\"warning\">硬件测试报告不存在</p>" >> "$REPORT_FILE"
fi

echo "    </div>" >> "$REPORT_FILE"

echo "    <div class=\"section\">" >> "$REPORT_FILE"
echo "        <h2>安全工具功能测试</h2>" >> "$REPORT_FILE"

# 添加安全工具测试结果
if [ -f "/tmp/security-test-report.txt" ]; then
    echo "<pre>$(cat /tmp/security-test-report.txt)</pre>" >> "$REPORT_FILE"
else
    echo "<p class=\"warning\">安全工具测试报告不存在</p>" >> "$REPORT_FILE"
fi

echo "    </div>" >> "$REPORT_FILE"

cat >> "$REPORT_FILE" << 'EOF'

    <div class="section">
        <h2>测试结论</h2>
        <p>基于以上测试结果，系统整体状态评估如下：</p>
        <ul>
            <li class="info">构建系统: 根据验证结果评估</li>
            <li class="info">硬件兼容性: 根据测试结果评估</li>
            <li class="info">安全工具: 根据功能测试结果评估</li>
        </ul>
    </div>

    <div class="section">
        <h2>建议</h2>
        <p>基于测试结果，建议采取以下措施：</p>
        <ol>
            <li>修复失败的测试项目</li>
            <li>处理警告项目</li>
            <li>更新相关工具和配置</li>
            <li>进行进一步的集成测试</li>
        </ol>
    </div>

    <div class="footer">
        <p class="timestamp">报告生成时间: EOF
date '+%Y-%m-%d %H:%M:%S' >> "$REPORT_FILE"

cat >> "$REPORT_FILE" << 'EOF'
</p>
    </div>
</body>
</html>
EOF

echo "综合测试报告已生成: $REPORT_FILE"
echo "可以在浏览器中打开查看报告"

SCRIPT

chmod +x "$PROJECT_ROOT/generate-test-report.sh"

echo -e "${GREEN}✓ 测试报告生成脚本创建完成${NC}"

echo
echo -e "${GREEN}=== 项目结构创建完成 ===${NC}"
echo
echo "项目结构:"
tree "$PROJECT_ROOT" -L 3 2>/dev/null || find "$PROJECT_ROOT" -type d -name ".*" -prune -o -type d -print | head -20
echo
echo "创建的文件:"
ls -la "$PROJECT_ROOT"/*.md "$PROJECT_ROOT"/*.sh "$PROJECT_ROOT"/*INFO* "$PROJECT_ROOT"/*VERSION* "$PROJECT_ROOT"/LICENSE 2>/dev/null | head -20
echo
echo -e "${GREEN}项目结构创建成功！${NC}"
echo "现在可以开始构建和测试了。"

echo -e "${GREEN}✓ 测试报告生成脚本创建完成${NC}"

echo
echo -e "${GREEN}=== 项目结构创建完成 ===${NC}"
echo
echo "项目结构:"
tree "$PROJECT_ROOT" -L 3 2>/dev/null || find "$PROJECT_ROOT" -type d -name ".*" -prune -o -type d -print | head -20
echo
echo "创建的文件:"
ls -la "$PROJECT_ROOT"/*.md "$PROJECT_ROOT"/*.sh "$PROJECT_ROOT"/*INFO* "$PROJECT_ROOT"/*VERSION* "$PROJECT_ROOT"/LICENSE 2>/dev/null | head -20
echo
echo -e "${GREEN}项目结构创建成功！${NC}"
echo "现在可以开始构建和测试了。"