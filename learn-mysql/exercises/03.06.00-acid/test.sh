#!/bin/bash
# 用途：在隔离数据库中验证 03.06.00 的原子下单事务。
# 参数：无。
# 返回值：库存、订单和明细状态一致时返回 0，否则返回 1。

set -u
CONTAINER_NAME="mysql-learn"
DB_NAME="order_system_lesson_030600"

if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    echo "❌ 错误：MySQL 容器未运行。"
    exit 1
fi

if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' -e "DROP DATABASE IF EXISTS ${DB_NAME}; CREATE DATABASE ${DB_NAME} DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci;"; then
    echo "❌ 错误：重建隔离数据库失败。"
    exit 1
fi

for schema_file in ../../schema/v001-create-users.sql ../../schema/v002-alter-users.sql ../../schema/v003-users-unique.sql ../../schema/v004-create-roles.sql ../../schema/v005-create-user-roles.sql ../../schema/v006-users-index.sql ../../schema/v007-create-catalog-orders.sql; do
    if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < "$schema_file"; then
        echo "❌ 错误：应用 $schema_file 失败。"
        exit 1
    fi
done

if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < seed.sql; then
    echo "❌ 错误：导入测试数据失败。"
    exit 1
fi

SQL_BODY=$(sed '/^[[:space:]]*--/d' exercise.sql)
if [ -z "${SQL_BODY//[[:space:]]/}" ]; then
    echo "❌ 错误：exercise.sql 尚未完成。"
    exit 1
fi

SQL_FLAT=$(printf '%s\n' "$SQL_BODY" | tr '\n' ' ')
for keyword in START TRANSACTION UPDATE INSERT COMMIT; do
    if ! printf '%s\n' "$SQL_FLAT" | grep -Eiq "(^|[^[:alnum:]_])${keyword}([^[:alnum:]_]|$)"; then
        echo "❌ 错误：exercise.sql 必须使用 ${keyword}。"
        exit 1
    fi
done

if ! printf '%s\n' "$SQL_FLAT" | grep -Eiq 'stock[[:space:]]*>=[[:space:]]*2'; then
    echo "❌ 错误：库存扣减必须包含 stock >= 2 条件。"
    exit 1
fi

if printf '%s\n' "$SQL_FLAT" | grep -Eiq 'CREATE|ALTER|DROP|FOREIGN_KEY_CHECKS'; then
    echo "❌ 错误：事务练习禁止 DDL 或关闭外键检查。"
    exit 1
fi

if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < exercise.sql; then
    echo "❌ 错误：exercise.sql 执行失败。"
    exit 1
fi

VERIFY_SQL="SELECT p.id AS product_id, p.stock, COUNT(DISTINCT o.id) AS order_count, COUNT(oi.id) AS item_count, COALESCE(SUM(oi.quantity), 0) AS total_quantity FROM products AS p LEFT JOIN order_items AS oi ON oi.product_id = p.id LEFT JOIN orders AS o ON o.id = oi.order_id WHERE p.id = 1 GROUP BY p.id, p.stock;"
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" -e "$VERIFY_SQL" > actual_result.txt; then
    echo "❌ 错误：读取事务结果失败。"
    rm -f actual_result.txt
    exit 1
fi

if diff -q actual_result.txt expected/result.txt > /dev/null; then
    echo "✅ 测试通过！你已掌握 ACID 与显式事务控制。"
    rm -f actual_result.txt
    exit 0
fi

echo "❌ 测试失败：库存、订单与明细状态不一致。"
cat actual_result.txt
echo "-------------------------"
cat expected/result.txt
rm -f actual_result.txt
exit 1

