#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '  # 定义了Bash提示符的外观

export EDITOR='nvim'

alias ll='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias vim='nvim'
alias vide='neovide'
alias lg='lazygit'
alias lj='lazyjj'
alias y='yazi'

eval "$(zoxide init bash)"
. "$HOME/.local/bin/env"  # uv

# node.js 和 npm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
. "$HOME/.cargo/env"
