手动用管理员权限打开cmd:

```bat
kanata.kbd手动复制到装有kanata_gui.exe的文件夹下

# 文件
mklink "%USERPROFILE%\.config\starship.toml" "%USERPROFILE%\dotfiles\starship.toml"

mklink "%USERPROFILE%\AppData\Roaming\Code\User\settings.json" "%USERPROFILE%\dotfiles\code\settings.json"
mklink "%USERPROFILE%\AppData\Roaming\Code\User\keybindings.json" "%USERPROFILE%\dotfiles\code\keybindings.json"

mklink "%USERPROFILE%\AppData\Roaming\Rime\default.custom.yaml" "%USERPROFILE%\dotfiles\rime_ice\default.custom.yaml"
mklink "%USERPROFILE%\AppData\Roaming\Rime\rime_ice.custom.yaml" "%USERPROFILE%\dotfiles\rime_ice\rime_ice.custom.yaml"
mklink "%USERPROFILE%\AppData\Roaming\Rime\weasel.custom.yaml" "%USERPROFILE%\dotfiles\rime_ice\weasel.custom.yaml"

mklink "%USERPROFILE%\.condarc" "%USERPROFILE%\dotfiles\.condarc"
mklink "%USERPROFILE%\.wslconfig" "%USERPROFILE%\dotfiles\.wslconfig"

# 目录
mklink /D "%USERPROFILE%\.glzr\glazewm" "%USERPROFILE%\dotfiles\glazewm"
mklink /D "%USERPROFILE%\AppData\Local\nvim" "%USERPROFILE%\dotfiles\nvim"
mklink /D "%USERPROFILE%\AppData\Roaming\nushell" "%USERPROFILE%\dotfiles\nushell"
mklink /D "%USERPROFILE%\AppData\Roaming\yazi" "%USERPROFILE%\dotfiles\yazi"
mklink /D "%USERPROFILE%\AppData\Roaming\jj" "%USERPROFILE%\dotfiles\jj"
mklink /D "%USERPROFILE%\.config\wezterm" "%USERPROFILE%\dotfiles\wezterm"
mklink /D "%USERPROFILE%\.config\yasb" "%USERPROFILE%\dotfiles\yasb"
```
