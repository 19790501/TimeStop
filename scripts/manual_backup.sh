#!/bin/bash

# 手动备份脚本 - 可以在需要时随时运行进行手动备份
# 使用方法: ./manual_backup.sh [备份说明]

# 设置工作目录为项目根目录
cd "$(dirname "$0")/.." || exit 1

# 获取当前时间戳
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# 获取备份描述（可选参数）
if [ $# -gt 0 ]; then
    BACKUP_DESC="$1"
else
    BACKUP_DESC="手动触发的备份"
fi

# 获取当前分支名称
CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null) || CURRENT_BRANCH="unknown"

echo "开始手动备份 - $TIMESTAMP"
echo "备份描述: $BACKUP_DESC"
echo "当前分支: $CURRENT_BRANCH"

# 检查是否有未提交的更改
if [[ $(git status --porcelain | wc -l) -gt 0 ]]; then
    echo "检测到未提交的更改，正在备份..."
    
    # 添加所有更改
    git add -A
    
    # 创建提交
    git commit -m "MANUAL-BACKUP: $BACKUP_DESC [$CURRENT_BRANCH] @ $TIMESTAMP"
    
    echo "备份完成，提交详情："
    git show --stat HEAD
else
    echo "没有需要备份的更改。"
    exit 0
fi

# 询问是否要创建备份分支
echo ""
echo "是否需要创建备份分支? (y/n)"
read -r CREATE_BRANCH

if [[ $CREATE_BRANCH == "y" || $CREATE_BRANCH == "Y" ]]; then
    # 创建备份分支
    BACKUP_BRANCH="backup/manual-$(date '+%Y%m%d-%H%M%S')"
    git branch "$BACKUP_BRANCH"
    echo "已创建备份分支: $BACKUP_BRANCH"
fi

# 询问是否要推送到远程仓库
echo ""
echo "是否要推送到远程仓库? (y/n)"
read -r PUSH_REMOTE

if [[ $PUSH_REMOTE == "y" || $PUSH_REMOTE == "Y" ]]; then
    # 检查是否有配置远程仓库
    if git remote -v | grep -q 'origin'; then
        echo "正在推送到远程仓库..."
        git push origin "$CURRENT_BRANCH"
        
        # 如果创建了备份分支并且需要推送
        if [[ $CREATE_BRANCH == "y" || $CREATE_BRANCH == "Y" ]]; then
            echo "正在推送备份分支..."
            git push origin "$BACKUP_BRANCH"
        fi
    else
        echo "未配置远程仓库，无法推送。"
    fi
fi

echo "手动备份完成于 $(date "+%Y-%m-%d %H:%M:%S")" 