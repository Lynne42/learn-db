#!/bin/bash
# 用途：在隔离数据库中验证 03.04.08 的 categories Self Join 查询。
# 参数：无。
# 返回值：结果一致返回 0；环境、SQL 或结果校验失败返回 1。
# 约束：必须从当前练习目录执行，且 mysql-learn 容器处于运行状态。

set -u

CONTAINER_NAME="mysql-learn"
DB_NAME="order_system_lesson_030408"

if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    echo "❌ 错误：MySQL 容器未运行！请先在项目根目录运行 docker compose up -d"
    exit 1
fi

echo "⏳ 正在重建隔离的分类 Schema..."
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' -e "
CREATE DATABASE IF NOT EXISTS ${DB_NAME}
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;
"; then
    echo "❌ 错误：创建隔离练习数据库失败。"
    exit 1
fi

if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" -e "
DROP TABLE IF EXISTS categories;
CREATE TABLE categories (
    id BIGINT UNSIGNED NOT NULL,
    name VARCHAR(100) NOT NULL,
    parent_id BIGINT UNSIGNED NULL,
    PRIMARY KEY (id),
    KEY idx_categories_parent_id (parent_id),
    CONSTRAINT fk_categories_parent
        FOREIGN KEY (parent_id) REFERENCES categories (id)
);
"; then
    echo "❌ 错误：重建隔离分类 Schema 失败。"
    exit 1
fi

echo "⏳ 正在导入分类层级测试数据..."
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < seed.sql; then
    echo "❌ 错误：导入 seed.sql 失败。"
    exit 1
fi

SQL_BODY=$(sed '/^[[:space:]]*--/d' exercise.sql)

if ! printf '%s\n' "$SQL_BODY" | grep -Eiq 'FROM[[:space:]]+categories[[:space:]]+(AS[[:space:]]+)?child'; then
    echo "❌ 错误：必须从 categories AS child 查询。"
    exit 1
fi

if ! printf '%s\n' "$SQL_BODY" | grep -Eiq 'LEFT([[:space:]]+OUTER)?[[:space:]]+JOIN[[:space:]]+categories[[:space:]]+(AS[[:space:]]+)?parent'; then
    echo "❌ 错误：必须使用 LEFT JOIN categories AS parent。"
    exit 1
fi

if ! printf '%s\n' "$SQL_BODY" | grep -Eiq 'ON[[:space:]]+parent\.id[[:space:]]*=[[:space:]]*child\.parent_id'; then
    echo "❌ 错误：连接条件必须是 parent.id = child.parent_id。"
    exit 1
fi

if printf '%s\n' "$SQL_BODY" | grep -Eiq '(INNER|RIGHT|NATURAL)[[:space:]]+JOIN|UNION|WITH[[:space:]]+RECURSIVE'; then
    echo "❌ 错误：本练习禁止 INNER/RIGHT/NATURAL JOIN、UNION 和 Recursive CTE。"
    exit 1
fi

if ! printf '%s\n' "$SQL_BODY" | grep -Eiq 'ORDER[[:space:]]+BY[[:space:]]+child\.id([[:space:]]+ASC)?([^[:alnum:]_]|$)'; then
    echo "❌ 错误：查询必须按 child.id 升序排序。"
    exit 1
fi

echo "🏃 正在执行 Self Join 查询..."
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < exercise.sql > actual_result.txt; then
    echo "❌ 错误：exercise.sql 执行失败，请检查别名和连接条件。"
    rm -f actual_result.txt
    exit 1
fi

if diff -q actual_result.txt expected/result.txt > /dev/null; then
    echo "✅ 测试通过！你已掌握 Self Join 与直接父子层级查询。"
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
