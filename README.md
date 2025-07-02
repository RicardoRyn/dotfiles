手动用管理员权限打开cmd:

```bat
# 如果是文件
mklink "%USERPROFILE%\.config\starship.toml" "%USERPROFILE%\dotfiles\starship.toml"

# 如果是文件夹
mklink /D "%USERPROFILE%\AppData\Roaming\nushell" "%USERPROFILE%\dotfiles\nushell"
```


