手动用管理员权限打开cmd:

```bat
# 如果是文件
mklink "%USERPROFILE%\AppData\Roaming\Code\User\settings.json" "%USERPROFILE%\dotfiles\settings.json"

# 如果是文件夹
mklink /D "%USERPROFILE%\AppData\Roaming\nushell" "%USERPROFILE%\dotfiles\nushell"
```


