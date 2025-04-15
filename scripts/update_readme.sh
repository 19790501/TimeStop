#!/bin/bash

# 手动更新README.md的版本历史记录
# 用法: ./scripts/update_readme.sh [版本号] [注释]

# 切换到项目根目录
cd "$(dirname "$0")/.." || exit 1

# 获取当前日期
CURRENT_DATE=$(date +%Y-%m-%d)

# 检查参数
if [ $# -lt 1 ]; then
    echo "用法: $0 [版本号] [注释]"
    echo "例如: $0 v1.2.6 '修复了界面问题，优化了性能'"
    exit 1
fi

VERSION=$1
COMMENT=$2

# 如果没有提供注释，则使用最近一次提交的信息
if [ -z "$COMMENT" ]; then
    COMMENT=$(git log -1 --pretty=format:"%s")
    echo "使用最近提交信息: $COMMENT"
fi

# 将注释分割成多行
BULLET_POINTS=$(echo "$COMMENT" | sed 's/，/\n- /g' | sed 's/、/\n- /g')

# 检查是否存在版本历史部分
if ! grep -q "## 版本历史" README.md; then
    echo "在README.md中未找到版本历史部分。请先添加'## 版本历史'标题。"
    exit 1
fi

# 检查版本是否已存在
if grep -q "$VERSION" README.md; then
    echo "版本 $VERSION 已存在于README.md中。"
    exit 1
fi

# 格式化为README.md的版本历史条目
NEW_VERSION_ENTRY="### $VERSION ($CURRENT_DATE)\n- ${BULLET_POINTS}\n\n"

# 将新条目插入到版本历史部分的开始
awk -v new_entry="$NEW_VERSION_ENTRY" '
/^## 版本历史/ {
    print $0;
    print "";
    print new_entry;
    next_is_version = 1;
    next;
}
next_is_version && /^###/ {
    next_is_version = 0;
    print $0;
    next;
}
{print $0}
' README.md > README.md.tmp && mv README.md.tmp README.md

echo "README.md 已更新，添加了版本 $VERSION 记录。"

# 如果没有对应的Git标签，创建一个
if ! git rev-parse "$VERSION" >/dev/null 2>&1; then
    echo "创建Git标签: $VERSION"
    git tag -a "$VERSION" -m "$COMMENT"
fi

# 提示用户提交更改
echo "请运行以下命令提交更改:"
echo "  git add README.md"
echo "  git commit -m \"更新README.md：添加版本$VERSION记录\""
echo "  git push"
echo "  git push --tags  # 如果需要推送标签" 