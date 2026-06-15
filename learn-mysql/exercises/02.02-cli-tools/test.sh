#!/bin/bash
set -e

SCRIPT_FILE="exercise.sh"

if [ ! -f "$SCRIPT_FILE" ]; then
    echo "❌ 找不到 $SCRIPT_FILE 文件"
    exit 1
fi

# 给脚本赋予执行权限
chmod +x $SCRIPT_FILE

# 检查是否包含核心关键字
if ! grep -q "docker compose exec" $SCRIPT_FILE; then
    echo "❌ 你没有使用 docker compose exec 命令去穿透容器！"
    exit 1
fi

if ! grep -q "\-e " $SCRIPT_FILE; then
    echo "❌ 你忘记了最重要的非交互式执行参数 -e ！"
    exit 1
fi

# 执行用户的脚本，捕获输出
echo "⏳ 正在执行你的探针脚本..."
OUTPUT=$(cd ../../ && ./exercises/02.02-cli-tools/$SCRIPT_FILE)

if [[ "$OUTPUT" == *"Ready for duty"* ]]; then
    echo "✅ 测试通过！你成功从外部刺穿了容器，拿到了数据库的回应！"
else
    echo "❌ 测试失败！数据库没有返回期望的 'Ready for duty'。你的输出是："
    echo "$OUTPUT"
    exit 1
fi
