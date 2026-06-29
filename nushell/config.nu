alias ll = ls -l
alias la = ls -a
alias lla = ls -al
alias vide = neovide
alias lg = lazygit
alias lj = lazyjj -r "all()"
alias ju = jjui -r "all()"
alias jf = jj git fetch
alias jp = jj git push
alias rjxssh = ssh ruanjx@192.168.22.171

$env.config = {
  hooks: {
    display_output: { table --icons }
  }
  show_banner: false,
  edit_mode: vi,
  cursor_shape: {
    vi_insert: line
    vi_normal: block
  },
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
$env.CONDA_NO_PROMPT = true  # 不显示conda的环境提示，由starship接管
$env.NHP_SAMBASHARE = "\\\\172.28.178.224\\nhp_sambashare"
$env.MI_SAMBASHARE = "\\\\192.168.3.102\\MI_sambashare"

source ~/.zoxide.nu
use ~/appdata/roaming/nushell/virtual_environments/nu_conda_2/conda.nu
use ~/appdata/roaming/nushell/completions-jj.nu *
use ~/appdata/roaming/nushell/utils.nu *
