# ==============================================
# Oh My Zsh 基础配置
# ==============================================

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# 设置主题为空，使用自定义提示符
ZSH_THEME=""

# 插件配置
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    sudo
    extract
)

# 禁用自动更新提示
zstyle ':omz:update' mode reminder

# 启用命令自动纠正
ENABLE_CORRECTION="true"

# 在等待补全时显示红点
COMPLETION_WAITING_DOTS="true"

# 加载 Oh My Zsh
source $ZSH/oh-my-zsh.sh

# ==============================================
# 环境变量和路径配置
# ==============================================

# 加载自定义环境变量文件
if [ -f "$HOME/.local/bin/env" ]; then
    source "$HOME/.local/bin/env"
fi

# Anaconda3 环境变量 - 更新为 Anaconda3 路径
export PATH="/home/radxa/anaconda3/bin:$PATH"

# 用户本地二进制目录
export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

# ==============================================
# Anaconda3 手动初始化
# ==============================================

# 手动初始化 Anaconda3
if [ -f "/home/radxa/anaconda3/bin/conda" ]; then
    # 设置 Conda 根目录
    __conda_setup="$('/home/radxa/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/home/radxa/anaconda3/etc/profile.d/conda.sh" ]; then
            . "/home/radxa/anaconda3/etc/profile.d/conda.sh"
        else
            export PATH="/home/radxa/anaconda3/bin:$PATH"
        fi
    fi
    unset __conda_setup
    
    # 可选：自动激活 base 环境（如果不需要请注释掉）
    # conda activate base 2>/dev/null || true
fi

# ==============================================
# 历史记录配置
# ==============================================

HISTSIZE=10000
SAVEHIST=10000
HISTFILE="$HOME/.zsh_history"

# 增强的历史记录选项
setopt append_history
setopt extended_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_verify
setopt share_history
setopt inc_append_history

# ==============================================
# Zsh 增强功能
# ==============================================

# 自动补全增强
autoload -U compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# 目录导航增强
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushdminus

# 其他有用的选项
setopt correct
setopt check_jobs
setopt interactive_comments
setopt no_beep
setopt multios

# ==============================================
# 自定义提示符配置（方案二 - 带用户名和时间）
# ==============================================

autoload -U colors && colors

# 方案二：带用户名和时间的简洁风格（避免红绿色）
PROMPT='%F{blue}[%*]%f %F{cyan}%n%f:%F{yellow}%~%f %# '

# 右侧显示git分支信息（使用蓝色和黄色，避免红绿色）
RPROMPT='$(git_prompt_info)'

# Git提示符设置（避免红绿色）
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}(%{$fg[yellow]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%})%{$fg[cyan]%}*%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})%{$fg[white]%}✓%{$reset_color%}"

# ==============================================
# 别名和外观
# ==============================================

# ls 颜色支持和别名
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# 常用 ls 别名
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias lh='ls -lah'

# 导航别名
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# 安全操作
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# 开发相关
alias py='python3'
alias pip='pip3'

# 快速编辑配置文件
alias zshconfig="nvim ~/.zshrc"
alias ohmyzsh="nvim ~/.oh-my-zsh"

# 系统信息
alias ipinfo="curl ipinfo.io"

# Anaconda 相关别名
alias ca='conda activate'
alias cda='conda deactivate'
alias cl='conda list'
alias ci='conda install'
alias cenv='conda env list'

# GCC 彩色输出
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# ==============================================
# 加载额外配置
# ==============================================

# 加载 bash 别名文件
if [ -f ~/.bash_aliases ]; then
    source ~/.bash_aliases
fi

# 加载自定义 zsh 配置
if [ -f ~/.zsh_aliases ]; then
    source ~/.zsh_aliases
fi

# ==============================================
# 终端和编辑器配置
# ==============================================

# 设置默认编辑器
export EDITOR='nvim'
export VISUAL='nvim'

# 设置语言环境
export LANG=en_US.UTF-8

# 设置终端标题（简洁版）
case "$TERM" in
    xterm*|rxvt*|alacritty*|kitty*|tmux*)
        precmd() { print -Pn "\e]0;%n:%~\a" }
        ;;
esac

# ==============================================
# 功能函数
# ==============================================

# 快速查找文件
fzf-find() {
    if command -v fzf >/dev/null 2>&1; then
        find . -type f 2>/dev/null | fzf --height 40% --reverse
    else
        echo "fzf is not installed"
    fi
}

# 进入选择的目录
fzf-cd() {
    if command -v fzf >/dev/null 2>&1; then
        local dir
        dir=$(find . -type d 2>/dev/null | fzf --height 40% --reverse) && cd "$dir"
    else
        echo "fzf is not installed"
    fi
}

# 显示路径信息
pathinfo() {
    echo "当前路径: $PWD"
    echo "Home目录: $HOME"
}

# 目录大小分析
ds() {
    du -h -d 1 "$@" | sort -h
}

# Anaconda 环境快速切换
ce() {
    conda activate "$1"
}

# 检查 conda 状态
conda-info() {
    echo "=== Anaconda 信息 ==="
    which conda
    conda --version
    echo "当前环境: $CONDA_DEFAULT_ENV"
    echo "环境列表:"
    conda env list
}

# ==============================================
# 编译和开发配置
# ==============================================

# 编译标志
export ARCHFLAGS="-arch $(uname -m)"

# Python开发相关
export PYTHONDONTWRITEBYTECODE=1
export PIP_DISABLE_PIP_VERSION_CHECK=1
export PATH="$HOME/.local/bin:$PATH"