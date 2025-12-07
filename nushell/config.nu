alias ll = ls -l
alias la = ls -a
alias lla = ls -al
alias vim = nvim
alias vide = neovide
alias y = yazi
alias lg = lazygit
alias top = btop
alias jf = jj git fetch
alias jp = jj git push

alias rjxssh = ssh ruanjx@192.168.22.171
alias server_proxy = ssh -v -N -R 1080:localhost:7897 ruanjx@192.168.22.171

$env.config = {
  show_banner: false,  # show/hide banner
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
    },
  ]
}

$env.EDITOR = "nvim"
$env.CONDA_NO_PROMPT = true

source ~/.zoxide.nu
use ~/.config/nushell/virtual_environments/conda.nu
