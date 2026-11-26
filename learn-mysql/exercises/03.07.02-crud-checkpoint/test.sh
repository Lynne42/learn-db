#!/bin/bash
# 用途：在隔离数据库中验证 03.07.02 的跨表 CRUD 与最终查询。
# 参数：无。
# 返回值：输出契约和状态不变量同时成立时返回 0，否则返回 1。

set -u
CONTAINER_NAME="mysql-learn"
DB_NAME="order_system_lesson_030702"

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
for keyword in START TRANSACTION INSERT UPDATE DELETE COMMIT SELECT JOIN COUNT SUM GROUP BY; do
    if ! printf '%s\n' "$SQL_FLAT" | grep -Eiq "(^|[^[:alnum:]_])${keyword}([^[:alnum:]_]|$)"; then
        echo "❌ 错误：exercise.sql 必须使用 ${keyword}。"
        exit 1
    fi
done

if ! printf '%s\n' "$SQL_FLAT" | grep -Eiq 'stock[[:space:]]*>=[[:space:]]*3'; then
    echo "❌ 错误：库存扣减必须包含 stock >= 3。"
    exit 1
fi

if ! printf '%s\n' "$SQL_FLAT" | grep -Eiq "status[[:space:]]*=[[:space:]]*'PENDING'"; then
    echo "❌ 错误：订单状态更新必须限定旧状态 PENDING。"
    exit 1
fi

if printf '%s\n' "$SQL_FLAT" | grep -Eiq 'CREATE|ALTER|DROP|FOREIGN_KEY_CHECKS'; then
    echo "❌ 错误：禁止 DDL 或关闭外键检查。"
    exit 1
fi

if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < exercise.sql > actual_result.txt; then
    echo "❌ 错误：exercise.sql 执行失败。"
    rm -f actual_result.txt
    exit 1
fi

STATE_SQL="SELECT CONCAT((SELECT status FROM orders WHERE id = 201), '|', (SELECT stock FROM products WHERE id = 1), '|', (SELECT COUNT(*) FROM orders WHERE id = 200), '|', (SELECT COUNT(*) FROM order_items WHERE order_id = 200));"
ACTUAL_STATE=$(docker exec -i "$CONTAINER_NAME" mysql -N -s -u root -p'root123' "$DB_NAME" -e "$STATE_SQL")
if [ "$ACTUAL_STATE" != "PAID|7|0|0" ]; then
    echo "❌ 测试失败：订单状态、库存或级联删除不变量不成立。"
    echo "实际状态：$ACTUAL_STATE"
    rm -f actual_result.txt
    exit 1
fi

if diff -q actual_result.txt expected/result.txt > /dev/null; then
    echo "✅ 测试通过！你已完成基础 CRUD 综合验收。"
    rm -f actual_result.txt
    exit 0
fi

echo "❌ 测试失败：最终订单摘要不符合要求。"
cat actual_result.txt
echo "-------------------------"
cat expected/result.txt
rm -f actual_result.txt
exit 1

