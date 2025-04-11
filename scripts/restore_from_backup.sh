#!/bin/bash

# 从备份恢复脚本 - 当需要恢复到之前的备份点时使用
# 使用方法: ./restore_from_backup.sh

# 设置工作目录为项目根目录
cd "$(dirname "$0")/.." || exit 1

# 获取当前时间戳
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# 获取当前分支
CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null) || CURRENT_BRANCH="unknown"

# 在恢复前创建安全备份
SAFETY_BRANCH="backup/safety-before-restore-$(date '+%Y%m%d-%H%M%S')"
git branch "$SAFETY_BRANCH"
echo "已创建当前状态的安全备份分支: $SAFETY_BRANCH"

# 查找所有备份分支
echo ""
echo "可用备份分支列表:"
git branch | grep -E "backup/" | sed 's/^\*//' | sed 's/^[ \t]*//' | nl

# 查找自动和手动备份的提交
echo ""
echo "最近的备份提交 (显示最新的10个):"
git log --oneline --grep="AUTO-BACKUP\|MANUAL-BACKUP" -n 10 | nl

# 询问用户恢复方式
echo ""
echo "请选择恢复方式:"
echo "1) 从备份分支恢复"
echo "2) 从备份提交恢复"
read -r RESTORE_TYPE

if [ "$RESTORE_TYPE" == "1" ]; then
    # 从备份分支恢复
    echo ""
    echo "请输入要恢复的备份分支编号:"
    read -r BRANCH_NUM
    
    # 获取分支名称
    BACKUP_BRANCH=$(git branch | grep -E "backup/" | sed 's/^\*//' | sed 's/^[ \t]*//' | sed -n "${BRANCH_NUM}p")
    
    if [ -z "$BACKUP_BRANCH" ]; then
        echo "错误: 无效的分支编号"
        exit 1
    fi
    
    echo "将从分支 '$BACKUP_BRANCH' 恢复..."
    
    # 检查是否有未提交的更改
    if [[ $(git status --porcelain | wc -l) -gt 0 ]]; then
        echo "检测到未提交的更改。"
        echo "1) 放弃这些更改并继续恢复"
        echo "2) 取消恢复操作"
        read -r UNSTAGED_CHOICE
        
        if [ "$UNSTAGED_CHOICE" == "1" ]; then
            git reset --hard HEAD
        else
            echo "恢复操作已取消。"
            exit 0
        fi
    fi
    
    # 从备份分支恢复
    git checkout "$BACKUP_BRANCH"
    echo "已切换到备份分支: $BACKUP_BRANCH"
    
    # 询问是否要将备份分支合并回原分支
    echo ""
    echo "是否要将此备份内容合并回 '$CURRENT_BRANCH' 分支? (y/n)"
    read -r MERGE_BACK
    
    if [[ $MERGE_BACK == "y" || $MERGE_BACK == "Y" ]]; then
        git checkout "$CURRENT_BRANCH"
        git merge "$BACKUP_BRANCH" -m "RESTORE: 从 $BACKUP_BRANCH 分支恢复 @ $TIMESTAMP"
        echo "已将备份内容合并到 '$CURRENT_BRANCH' 分支"
    fi
    
elif [ "$RESTORE_TYPE" == "2" ]; then
    # 从备份提交恢复
    echo ""
    echo "请输入要恢复的备份提交编号:"
    read -r COMMIT_NUM
    
    # 获取提交哈希
    BACKUP_COMMIT=$(git log --oneline --grep="AUTO-BACKUP\|MANUAL-BACKUP" -n 10 | sed -n "${COMMIT_NUM}p" | awk '{print $1}')
    
    if [ -z "$BACKUP_COMMIT" ]; then
        echo "错误: 无效的提交编号"
        exit 1
    fi
    
    echo "将恢复到提交: $BACKUP_COMMIT"
    
    # 检查是否有未提交的更改
    if [[ $(git status --porcelain | wc -l) -gt 0 ]]; then
        echo "检测到未提交的更改。"
        echo "1) 放弃这些更改并继续恢复"
        echo "2) 取消恢复操作"
        read -r UNSTAGED_CHOICE
        
        if [ "$UNSTAGED_CHOICE" == "1" ]; then
            git reset --hard HEAD
        else
            echo "恢复操作已取消。"
            exit 0
        fi
    fi
    
    # 创建恢复分支
    RESTORE_BRANCH="restore/from-commit-${BACKUP_COMMIT}-$(date '+%Y%m%d-%H%M%S')"
    git checkout -b "$RESTORE_BRANCH" "$BACKUP_COMMIT"
    echo "已创建并切换到恢复分支: $RESTORE_BRANCH"
    
    # 询问是否要将恢复分支合并回原分支
    echo ""
    echo "是否要将此恢复内容合并回 '$CURRENT_BRANCH' 分支? (y/n)"
    read -r MERGE_BACK
    
    if [[ $MERGE_BACK == "y" || $MERGE_BACK == "Y" ]]; then
        git checkout "$CURRENT_BRANCH"
        git merge "$RESTORE_BRANCH" -m "RESTORE: 从提交 $BACKUP_COMMIT 恢复 @ $TIMESTAMP"
        echo "已将恢复内容合并到 '$CURRENT_BRANCH' 分支"
    fi
else
    echo "无效的选择，恢复操作已取消。"
    exit 1
fi

echo "恢复操作完成于 $(date "+%Y-%m-%d %H:%M:%S")"
echo "如需撤销此恢复操作，可使用安全备份分支: $SAFETY_BRANCH" 