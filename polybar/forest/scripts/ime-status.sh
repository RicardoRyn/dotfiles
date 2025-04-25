#!/bin/bash

# 获取当前 fcitx5 输入法引擎
engine=$(fcitx5-remote)

# 检查是否是英文输入法（假设英文输入法包含 "eng"）
if [[ $engine -eq 1 ]]; then
    echo "EN"
elif [[ $engine -eq 2 ]]; then
    echo "CN"
fi
