#!/bin/bash

# 设置自动备份 cron 任务脚本
# 注意：该脚本需要管理员权限运行

# 获取项目绝对路径
PROJECT_DIR=$(cd "$(dirname "$0")/.." && pwd)
BACKUP_SCRIPT="$PROJECT_DIR/scripts/auto_backup.sh"

# 确保备份脚本存在且可执行
if [ ! -f "$BACKUP_SCRIPT" ]; then
    echo "错误：备份脚本不存在: $BACKUP_SCRIPT"
    exit 1
fi

chmod +x "$BACKUP_SCRIPT"

# 创建临时 crontab 文件
TEMP_CRONTAB=$(mktemp)

# 导出当前用户的 crontab
crontab -l > "$TEMP_CRONTAB" 2>/dev/null || echo "# 新建 crontab 文件" > "$TEMP_CRONTAB"

# 检查是否已经设置了备份任务
if grep -q "auto_backup.sh" "$TEMP_CRONTAB"; then
    echo "备份任务已存在，将更新现有配置..."
    # 移除旧的备份任务配置
    sed -i '' '/auto_backup.sh/d' "$TEMP_CRONTAB"
fi

# 添加新的 cron 任务 - 每4小时运行一次
echo "# TimeStop 自动备份任务 - 每4小时运行一次" >> "$TEMP_CRONTAB"
echo "0 */4 * * * $BACKUP_SCRIPT >> \"$PROJECT_DIR/logs/backup.log\" 2>&1" >> "$TEMP_CRONTAB"

# 确保日志目录存在
mkdir -p "$PROJECT_DIR/logs"

# 安装新的 crontab
crontab "$TEMP_CRONTAB"
if [ $? -eq 0 ]; then
    echo "成功设置了自动备份任务！"
    echo "TimeStop 项目将每4小时自动备份一次。"
    echo "备份日志将保存在: $PROJECT_DIR/logs/backup.log"
else
    echo "设置自动备份任务失败。"
    echo "请手动将以下行添加到 crontab (使用 'crontab -e'):"
    echo "0 */4 * * * $BACKUP_SCRIPT >> \"$PROJECT_DIR/logs/backup.log\" 2>&1"
fi

# 删除临时文件
rm "$TEMP_CRONTAB"

# 显示当前的 cron 任务
echo ""
echo "当前设置的 cron 任务:"
crontab -l | grep -v "^#" 