#!/bin/bash

# 自动备份脚本 - 每4小时将未提交的更改自动保存到 Git 仓库
# 使用方法：将此脚本设置为定时任务（cron job）

# 设置工作目录为项目根目录
cd "$(dirname "$0")/.." || exit 1

# 获取当前时间戳，用于提交信息
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# 获取当前分支名称
CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null) || CURRENT_BRANCH="unknown"

# 如果工作目录有更改，则进行自动保存
if [[ $(git status --porcelain | wc -l) -gt 0 ]]; then
    echo "检测到未提交的更改，正在创建自动备份..."
    
    # 添加所有更改（包括新文件）
    git add -A

    # 创建提交，带有时间戳和自动保存标记
    git commit -m "AUTO-BACKUP: 自动保存 [$CURRENT_BRANCH] @ $TIMESTAMP"
    
    echo "自动备份完成，提交详情："
    git show --stat HEAD
else
    echo "[$TIMESTAMP] 没有需要备份的更改。"
fi

# 如果本地配置了远程仓库，则尝试推送
if git remote -v | grep -q 'origin'; then
    echo "尝试将备份推送到远程仓库..."
    git push origin "$CURRENT_BRANCH" || echo "推送失败，将在下次备份时重试"
fi

# 创建本地备份分支（每日一个）
BACKUP_BRANCH="backup/daily-$(date '+%Y-%m-%d')"

# 检查备份分支是否已存在
if ! git show-ref --verify --quiet "refs/heads/$BACKUP_BRANCH"; then
    # 如果不存在，创建新的备份分支
    git branch "$BACKUP_BRANCH"
    echo "已创建备份分支: $BACKUP_BRANCH"
else
    # 如果已存在，更新备份分支
    git branch -f "$BACKUP_BRANCH"
    echo "已更新备份分支: $BACKUP_BRANCH"
fi

echo "自动备份完成于 $TIMESTAMP" 