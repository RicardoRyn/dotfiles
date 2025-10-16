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
      keycode: char_w
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

source ~/.zoxide.nu
use ~/.config/nushell/virtual_environments/nu_conda_2/conda.nu
use ~/.config/nushell/completions-jj.nu *
