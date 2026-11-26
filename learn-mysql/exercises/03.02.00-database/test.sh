#!/bin/bash
# 自动生成的练习验证脚本 - 数据库管理

# 1. 确定容器名
CONTAINER_NAME="mysql-learn"
DB_NAME="order_system"

# 2. 检查容器是否运行
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "❌ 错误：MySQL 容器未运行！请先在项目根目录运行 docker compose up -d"
    exit 1
fi

echo "⏳ 正在准备测试环境..."
# 先清理可能残留的测试库
docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' -e "DROP DATABASE IF EXISTS temp_test_db;"

echo "🏃 正在执行你的 DDL SQL..."
# 执行用户的 SQL
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' < exercise.sql; then
    echo "❌ 错误：SQL 脚本执行失败！请检查语法错误。"
    exit 1
fi

# 3. 提取用于验证的 Schema 状态
docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' -e "
SELECT SCHEMA_NAME, DEFAULT_CHARACTER_SET_NAME, DEFAULT_COLLATION_NAME 
FROM INFORMATION_SCHEMA.SCHEMATA 
WHERE SCHEMA_NAME = 'temp_test_db';
" > actual_result.txt

# 4. 清理环境，不残留垃圾库
docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' -e "DROP DATABASE IF EXISTS temp_test_db;"

# 5. 对比结果
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
