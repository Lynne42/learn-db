#!/bin/bash
set -e

SQL_FILE="exercise.sql"

if [ ! -f "$SQL_FILE" ]; then
    echo "❌ 找不到 $SQL_FILE 文件"
    exit 1
fi

# 在 Docker 中执行用户的 SQL
echo "⏳ 正在连接 MySQL 并在测试环境中执行你的 SQL..."
OUTPUT=$(docker compose -f ../../docker-compose.yml exec -T mysql-learn mysql -uroot -proot123 < "$SQL_FILE")

# 检查是否包含预期的列名和值
if [[ "$OUTPUT" == *"App Environment"* && "$OUTPUT" == *"production"* ]]; then
    echo "✅ 测试通过！你完美地掌握了变量赋值和转义符的用法！"
else
    echo "❌ 测试失败！没有检测到正确的列别名或变量值。你的输出是："
    echo "$OUTPUT"
    exit 1
fi
