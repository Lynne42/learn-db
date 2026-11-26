#!/bin/bash
# 用途：在隔离数据库中验证 03.04.11 的稳定排序与分页查询。
# 参数：无。
# 返回值：结果一致返回 0；失败返回 1。

set -u
CONTAINER_NAME="mysql-learn"
DB_NAME="order_system_lesson_030411"

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

if ! printf '%s\n' "$SQL_BODY" | grep -Eiq 'ORDER[[:space:]]+BY[[:space:]]+created_at[[:space:]]+DESC[[:space:]]*,[[:space:]]*id[[:space:]]+DESC'; then
    echo "❌ 错误：必须使用 ORDER BY created_at DESC, id DESC。"
    exit 1
fi

if ! printf '%s\n' "$SQL_BODY" | grep -Eiq 'LIMIT[[:space:]]+3[[:space:]]+OFFSET[[:space:]]+2'; then
    echo "❌ 错误：必须使用 LIMIT 3 OFFSET 2。"
    exit 1
fi

if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < exercise.sql > actual_result.txt; then
    echo "❌ 错误：exercise.sql 执行失败。"
    rm -f actual_result.txt
    exit 1
fi

if diff -q actual_result.txt expected/result.txt > /dev/null; then
    echo "✅ 测试通过！你已掌握稳定排序、LIMIT 与 OFFSET。"
    rm -f actual_result.txt
    exit 0
fi

echo "❌ 测试失败：查询结果与预期不符。"
cat actual_result.txt
echo "-------------------------"
cat expected/result.txt
rm -f actual_result.txt
exit 1

