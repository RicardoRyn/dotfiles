手动用管理员权限打开cmd:

```bat
# 如果是文件
mklink "%USERPROFILE%\.gitconfig" "%USERPROFILE%\dotfiles\.gitconfig"

# 如果是文件夹
mklink /D "%USERPROFILE%\AppData\Roaming\nushell" "%USERPROFILE%\dotfiles\nushell"
```


