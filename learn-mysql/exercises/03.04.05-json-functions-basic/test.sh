#!/bin/bash
# 用途：重建隔离商品表并验证 03.04.05 的 JSON 提取、包含判断和文档更新表达式。
# 参数：无。
# 返回值：结果一致返回 0；环境、SQL 或结果校验失败返回 1。
# 约束：必须从当前练习目录执行，且 mysql-learn 容器处于运行状态。

set -u

CONTAINER_NAME="mysql-learn"
DB_NAME="order_system"

if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    echo "❌ 错误：MySQL 容器未运行！请先在项目根目录运行 docker compose up -d"
    exit 1
fi

echo "⏳ 正在重建 JSON 测试表..."
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" -e "
DROP TABLE IF EXISTS lesson_030405_products;
CREATE TABLE lesson_030405_products (
    id BIGINT UNSIGNED NOT NULL,
    name VARCHAR(100) NOT NULL,
    attributes JSON NOT NULL,
    PRIMARY KEY (id)
);
"; then
    echo "❌ 错误：创建 JSON 测试表失败。"
    exit 1
fi

echo "⏳ 正在导入商品属性测试数据..."
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < seed.sql; then
    echo "❌ 错误：导入 seed.sql 失败。"
    exit 1
fi

SQL_BODY=$(sed '/^[[:space:]]*--/d' exercise.sql)
for keyword in JSON_CONTAINS JSON_SET JSON_EXTRACT JSON_UNQUOTE; do
    if ! printf '%s\n' "$SQL_BODY" | grep -Eiq "(^|[^[:alnum:]_])${keyword}([^[:alnum:]_]|$)"; then
        echo "❌ 错误：exercise.sql 必须使用 ${keyword}。"
        exit 1
    fi
done

if ! printf '%s\n' "$SQL_BODY" | grep -Fq -- '->>'; then
    echo "❌ 错误：exercise.sql 必须使用 ->> 提取 JSON 标量文本。"
    exit 1
fi

if ! printf '%s\n' "$SQL_BODY" | grep -Eiq 'ORDER[[:space:]]+BY[[:space:]]+([^,;]+\.)?id([[:space:]]+ASC)?([^[:alnum:]_]|$)'; then
    echo "❌ 错误：查询必须显式使用 ORDER BY id ASC。"
    exit 1
fi

echo "🏃 正在执行 JSON 查询..."
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < exercise.sql > actual_result.txt; then
    echo "❌ 错误：exercise.sql 执行失败，请检查 SQL 语法和 JSON Path。"
    rm -f actual_result.txt
    exit 1
fi

if diff -q actual_result.txt expected/result.txt > /dev/null; then
    echo "✅ 测试通过！你已掌握 JSON 提取、包含判断和 JSON_SET。"
    rm -f actual_result.txt
    exit 0
fi

echo "❌ 测试失败：查询结果与预期不符。"
echo "【实际结果】"
cat actual_result.txt
echo "-------------------------"
echo "【预期结果】"
cat expected/result.txt
rm -f actual_result.txt
exit 1
