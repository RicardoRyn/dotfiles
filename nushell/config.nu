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

###############################
####### Inserted by RJX #######
###############################
alias ll = ls -l
alias la = ls -a
alias lla = ls -al
alias vim = nvim
alias vide = neovide
alias y = yazi
alias lg = lazygit
alias lj = lazyjj

$env.config = {
  show_banner: false,
  edit_mode: vi,
  keybindings: [
    {
      name: Accept_HistoryHintWordComplete
      modifier: control
      keycode: char_v
      mode: [ emacs, vi_insert, vi_normal ]
      event: {
        send: HistoryHintWordComplete
      }
    },
    {
      name: Accept_HistoryHintComplete
      modifier: control
      keycode: char_y
      mode: [ emacs, vi_insert, vi_normal ]
      event: {
        send: HistoryHintComplete
      }
    }
  ]
}
$env.EDITOR = "nvim"
$env.CONDA_NO_PROMPT = true
$env.config.shell_integration.osc133 = false  # 修复按下任何键时屏幕滚动的问题

source ~/.zoxide.nu
use ~/appdata/roaming/nushell/virtual_environments/nu_conda_2/conda.nu
use ~/appdata/roaming/nushell/completions-jj.nu *
