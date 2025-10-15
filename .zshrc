# windwows特供
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -v
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/ricardo/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

# 这一段顺序不能错，因为zsh-vi-mode会覆盖绑定的快捷键
ZVM_INIT_MODE=sourcing
ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
source ~/.zsh/zsh-vi-mode/zsh-vi-mode.plugin.zsh
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
bindkey '^y' autosuggest-accept
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

export EDITOR='nvim'
alias grep='grep --color=auto'
alias ls='ls --color=auto'
alias ll='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias vim='nvim'
alias vide='neovide'
alias lg='lazygit'
alias lj='lazyjj'
alias y='yazi'

eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
