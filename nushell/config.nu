# config.nu
#
# Installed by:
# version = "0.102.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# This file is loaded after env.nu and before login.nu
#
# You can open this file in your default editor using:
# config nu
#
# See `help config nu` for more options
#
# You can remove these comments if you want or leave
# them for future reference.

######################################################
####### mannually inserted by RJX on 2025/2/16 #######
######################################################
alias ll = ls -l
alias la = ls -a
alias lla = ls -al
alias vim = nvim
alias vide = neovide
alias y = yazi
alias lg = lazygit
alias top = btop

alias rjxssh = ssh ruanjx@192.168.22.171
alias server_proxy = ssh -v -N -R 1080:localhost:7897 ruanjx@192.168.22.171

$env.config = {
  show_banner: false,  # show/hide banner
  edit_mode: vi,
  keybindings: [
    # ctrl+v，按单词接受提示
    {
      name: Accept_HistoryHintWordComplete
      modifier: control
      keycode: char_v
      mode: [ emacs, vi_insert, vi_normal ]
      event: {
        send: HistoryHintWordComplete
      }
    },
    # ctrl+y，接受全部提示
    {
      name: Accept_HistoryHintComplete
      modifier: control
      keycode: char_y
      mode: [ emacs, vi_insert, vi_normal ]
      event: {
        send: HistoryHintComplete
      }
    },
  ]
}

$env.EDITOR = "nvim"
$env.CONDA_NO_PROMPT = true

source ~/.zoxide.nu
use ~/.config/nushell/virtual_environments/conda.nu

