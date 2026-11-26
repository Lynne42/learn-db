#!/bin/bash
# 自动生成的练习验证脚本 - SQL 语言分类

# 1. 确定容器名
CONTAINER_NAME="mysql-learn"
DB_NAME="order_system"

# 2. 检查容器是否运行
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "❌ 错误：MySQL 容器未运行！请先在项目根目录运行 docker compose up -d"
    exit 1
fi

echo "⏳ 正在准备测试环境..."

echo "🏃 正在执行你的 SQL 并校验匹配结果..."

# 执行用户的 SQL，输出到 raw_actual.txt
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < exercise.sql > raw_actual.txt; then
    echo "❌ 错误：SQL 脚本执行失败！请检查语法错误。"
    rm -f raw_actual.txt
    exit 1
fi

# 对用户的输出进行排序比对（提取首行作为头部，剩余行进行排序，最后拼接）
head -n 1 raw_actual.txt > actual_result.txt
tail -n +2 raw_actual.txt | sort >> actual_result.txt
rm -f raw_actual.txt

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
