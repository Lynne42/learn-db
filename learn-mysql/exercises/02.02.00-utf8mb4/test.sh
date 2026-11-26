#!/bin/bash
# 自动生成的练习验证脚本 - 字符集与排序规则

# 1. 确定容器名
CONTAINER_NAME="mysql-learn"
DB_NAME="order_system"

# 2. 检查容器是否运行
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "❌ 错误：MySQL 容器未运行！请先在项目根目录运行 docker compose up -d"
    exit 1
fi

echo "⏳ 正在准备测试环境..."
# 先行清理可能已存在的临时表，确保 DDL 能顺利重新运行
docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" -e "DROP TABLE IF EXISTS temp_international_reviews;"

echo "🏃 正在执行你的 SQL..."
# 执行用户的 SQL
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < exercise.sql; then
    echo "❌ 错误：SQL 脚本执行失败！请检查语法错误。"
    exit 1
fi

# 3. 提取用于验证的 Schema 状态
docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" -e "
SELECT COLUMN_NAME, CHARACTER_SET_NAME, COLLATION_NAME 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = '$DB_NAME' 
  AND TABLE_NAME = 'temp_international_reviews' 
ORDER BY ORDINAL_POSITION;
" > actual_result.txt

# 4. 对比结果
if diff -q actual_result.txt expected/result.txt > /dev/null; then
    echo "✅ 测试通过！你已成功完成本节练习。"
    rm -f actual_result.txt
    exit 0
else
    echo "❌ 测试失败！你的结果与预期不符。"
    echo "【你的结果】：(详见 actual_result.txt)"
    cat actual_result.txt
    echo "-------------------------"
    echo "【预期结果】：(详见 expected/result.txt)"
    cat expected/result.txt
    exit 1
fi
