#!/bin/bash

# 設定項目の定義
declare -A git_configs=(
    ["user.name"]=""
    ["user.email"]=""
    ["color.ui"]="auto"
    ["core.editor"]="vim"
)

# エイリアスの定義
declare -A git_aliases=(
    ["delete-merged-branch"]="!f () { git checkout \$1; git branch --merged|egrep -v '\*|develop|master|main'|xargs git branch -d; };f"
)

# ドライランモードのフラグ
DRY_RUN=false

# コマンドライン引数の解析
while getopts "d" opt; do
    case $opt in
        d) DRY_RUN=true ;;
        *) echo "Usage: $0 [-d]" >&2
           echo "  -d: ドライランモード（実際の設定は行いません）" >&2
           exit 1 ;;
    esac
done

printf '\033[33m%s\033[m\n' "setting git config..."
if $DRY_RUN; then
    printf '\033[33m%s\033[m\n' "ドライランモード: 実際の設定は行いません"
fi

# 基本設定の適用
for key in "${!git_configs[@]}"; do
    current_value=$(git config --global "$key")
    if [ "$current_value" == '' ]; then
        if [[ "$key" == "user."* ]]; then
            # ユーザー情報は対話的に設定
            printf '\033[33m%s\033[m\n' "${key#user.}"
            read -p "${key#user.}: " value
            if ! $DRY_RUN; then
                git config --global "$key" "$value"
            else
                echo "設定予定: $key = $value"
            fi
        else
            # その他の設定は既定値を使用
            if ! $DRY_RUN; then
                git config --global "$key" "${git_configs[$key]}"
            else
                echo "設定予定: $key = ${git_configs[$key]}"
            fi
            printf '\033[33m%s\033[m\n' "$key"
        fi
    fi
done

# エイリアスの設定
for alias_name in "${!git_aliases[@]}"; do
    current_alias=$(git config --global "alias.$alias_name")
    if [ "$current_alias" == '' ]; then
        printf '\033[33m%s\033[m\n' "alias.$alias_name"
        if ! $DRY_RUN; then
            git config --global "alias.$alias_name" "${git_aliases[$alias_name]}"
        else
            echo "設定予定: alias.$alias_name = ${git_aliases[$alias_name]}"
        fi
    fi
done

# Git 2.27.0以降の場合のpull設定
GIT_VERSION=$(git --version | sed -e 's/[^0-9]//g')
if [ $GIT_VERSION -ge 2270 ]; then
    PULL_REBASE=$(git config --global pull.rebase)
    if [ "$PULL_REBASE" == '' ]; then
        if ! $DRY_RUN; then
            git config --global pull.rebase false
        else
            echo "設定予定: pull.rebase = false"
        fi
    fi
    printf '\033[33m%s\033[m\n' "git pull config"
else
    printf '\033[33m%s\033[m\n' "git version lower 2.27.0"
fi
