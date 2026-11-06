eval "$(/opt/homebrew/bin/brew shellenv bash)"

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi
