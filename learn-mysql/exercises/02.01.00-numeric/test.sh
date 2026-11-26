#!/bin/bash
# 自动生成的数值类型练习验证脚本
set -e

CONTAINER_NAME="mysql-learn"
DB_NAME="order_system"

# 1. 检查容器是否运行
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "❌ 错误：MySQL 容器未运行！请先在项目根目录运行 docker compose up -d"
    exit 1
fi

echo "⏳ 正在准备测试环境并清理同名表..."
docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" -e "DROP TABLE IF EXISTS temp_order_discounts;"

echo "🏃 正在执行你的 DDL 建表 SQL..."
docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < exercise.sql

echo "🔍 正在校验表结构..."
docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" -e "DESCRIBE temp_order_discounts;" > actual_result.txt

# 2. 对比结果
if diff -q actual_result.txt expected/result.txt > /dev/null; then
    echo "✅ 测试通过！你已成功掌握数值类型与自增主键的 DDL 定义！"
    rm -f actual_result.txt
    exit 0
else
    echo "❌ 测试失败！你的表结构与预期不符。"
    echo "【你的表结构】：(详见 actual_result.txt)"
    cat actual_result.txt
    echo "-------------------------"
    echo "【预期表结构】：(详见 expected/result.txt)"
    cat expected/result.txt
    exit 1
fi
