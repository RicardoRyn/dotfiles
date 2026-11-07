# 0. 非交互 shell 直接返回
[[ $- != *i* ]] && return

# 1. PATH 与环境变量
case ":$PATH:" in
*":$HOME/.local/bin:"*) ;;
*) export PATH="$HOME/.local/bin:$PATH" ;;
esac

export EDITOR="nvim"

# 2. 工具初始化
eval "$(zoxide init bash)"

# 3. 自定义函数
function y() {
  local tmp cwd
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd <"$tmp"
  [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true
  command rm -f -- "$tmp"
}
function jj() {
    local theme_dir="$HOME/.config/jj/themes"
    local theme
    if [[ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" == "Dark" ]]; then
        theme="$theme_dir/dark.toml"
    else
        theme="$theme_dir/light.toml"
    fi
    command jj --config-file "$theme" "$@"
}

# 4. 别名
alias grep='grep --color=auto'
alias ls='ls --color=auto' # 若 macOS 自带 ls 报错，改成 alias ls='ls -G'
alias ll='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias jf='jj git fetch'
alias jp='jj git push'
alias sshruanjx='ssh ruanjx@192.168.22.171'
alias sshnhp='ssh nhp@192.168.3.103'

# # 5. tmux 自动启动
# if [[ -z "$TMUX" ]] && [[ -n "$PS1" ]]; then
#   tmux new-session -A -s main
# fi

# 6. flyline
enable flyline 2>/dev/null ||
  enable -f /opt/homebrew/lib/libflyline.dylib flyline 2>/dev/null ||
  true

flyline key bind Ctrl+y 'inlineSuggestionAvailable+cursorAtEnd=inlineSuggestionAccept'
flyline set-cursor --backend terminal
flyline create-prompt-widget last-command-duration
flyline create-prompt-widget copy-buffer '[copy]'
flyline create-prompt-widget custom --name VCS_STATUS --command 'bash $HOME/.config/flyline/vcs_prompt.sh' --placeholder prev

# 根据操作系统设置图标变量
case "$(uname -s)" in
    Darwin)  OS_ICON=" " ;;
    Linux)   OS_ICON=" " ;;
    *)       OS_ICON="" ;;
esac

PS1='\e[01;32m╭─ ${OS_ICON}\u\e[00m \e[01;34m\w\e[00m VCS_STATUS\n\e[01;32m╰─\e[00m $ '
PS2='\e[2mline FLYLINE_PROMPT_LINE_NUMBER:\e[0m '
PS1_FINAL='\e[01;32m--- Ran\e[00m at \D{%Y-%m-%d %H:%M:%S} \e[01;32m---\e[00m > '
RPS1=' FLYLINE_COPY_BUFFER FLYLINE_LAST_COMMAND_DURATION'

################################################################################
