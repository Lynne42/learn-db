#!/bin/bash
# 自动生成的练习验证脚本 - 表结构变更

# 1. 确定容器名
CONTAINER_NAME="mysql-learn"
DB_NAME="order_system"

# 2. 检查容器是否运行
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "❌ 错误：MySQL 容器未运行！请先在项目根目录运行 docker compose up -d"
    exit 1
fi

echo "⏳ 正在重置测试环境并创建初始 users 表..."
# 显式删除旧表，再使用项目中的 schema v001 创表，确保有干净的初始 users 表
docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" -e "DROP TABLE IF EXISTS users;"
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < ../../schema/v001-create-users.sql; then
    echo "❌ 错误：重置测试环境失败！无法读取或执行 schema 历史脚本。"
    exit 1
fi

echo "🏃 正在执行你的 ALTER TABLE SQL 变更..."
# 执行用户的 SQL
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < exercise.sql; then
    echo "❌ 错误：SQL 脚本执行失败！请检查语法错误。"
    exit 1
fi

# 3. 提取用于验证的 Schema 状态
docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" -e "
SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, 
       IF(EXTRA LIKE '%VIRTUAL%' OR EXTRA LIKE '%STORED%', 'YES', 'NO') AS IS_GENERATED, 
       IF(EXTRA LIKE '%on update%', 'YES', 'NO') AS HAS_ON_UPDATE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = '$DB_NAME' 
  AND TABLE_NAME = 'users' 
  AND COLUMN_NAME IN ('created_at', 'updated_at', 'username_lower') 
ORDER BY COLUMN_NAME;
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
    rm -f actual_result.txt
    exit 1
fi
