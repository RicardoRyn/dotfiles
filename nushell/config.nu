alias ll = ls -l
alias la = ls -a
alias lla = ls -al
alias vim = nvim
alias vide = neovide
alias y = yazi
alias lg = lazygit
alias lj = lazyjj -r "all()"
alias ju = jjui -r "all()"
alias jf = jj git fetch
alias jp = jj git push

$env.config = {
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
$env.config.shell_integration.osc133 = false  # 修复按下任何键时屏幕滚动的问题
$env.NHP_SAMBASHARE = "\\\\172.28.178.224\\nhp_sambashare"

source ~/.zoxide.nu
use ~/appdata/roaming/nushell/virtual_environments/nu_conda_2/conda.nu
use ~/appdata/roaming/nushell/completions-jj.nu *
