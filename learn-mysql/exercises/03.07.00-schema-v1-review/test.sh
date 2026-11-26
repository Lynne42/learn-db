#!/bin/bash
# 用途：在隔离数据库中验证 03.07.00 的 Schema 外键元数据审计查询。
# 参数：无。
# 返回值：外键依赖清单与 Schema V1 一致时返回 0，否则返回 1。

set -u
CONTAINER_NAME="mysql-learn"
DB_NAME="order_system_lesson_030700"

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

SQL_BODY=$(sed '/^[[:space:]]*--/d' exercise.sql)
if [ -z "${SQL_BODY//[[:space:]]/}" ]; then
    echo "❌ 错误：exercise.sql 尚未完成。"
    exit 1
fi

SQL_FLAT=$(printf '%s\n' "$SQL_BODY" | tr '\n' ' ')
for keyword in SELECT INFORMATION_SCHEMA KEY_COLUMN_USAGE TABLE_SCHEMA TABLE_NAME COLUMN_NAME REFERENCED_TABLE_NAME REFERENCED_COLUMN_NAME DATABASE IN IS NOT NULL ORDER; do
    if ! printf '%s\n' "$SQL_FLAT" | grep -Eiq "(^|[^[:alnum:]_])${keyword}([^[:alnum:]_]|$)"; then
        echo "❌ 错误：exercise.sql 必须使用 ${keyword}。"
        exit 1
    fi
done

if ! printf '%s\n' "$SQL_FLAT" | grep -Eiq 'TABLE_SCHEMA[[:space:]]*=[[:space:]]*DATABASE[[:space:]]*\([[:space:]]*\)'; then
    echo "❌ 错误：必须使用 TABLE_SCHEMA = DATABASE() 限定当前数据库。"
    exit 1
fi

if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < exercise.sql > actual_result.txt; then
    echo "❌ 错误：exercise.sql 执行失败。"
    rm -f actual_result.txt
    exit 1
fi

if diff -q actual_result.txt expected/result.txt > /dev/null; then
    echo "✅ 测试通过！你已完成 Schema V1 外键依赖审计。"
    rm -f actual_result.txt
    exit 0
fi

echo "❌ 测试失败：外键依赖清单与 Schema V1 不一致。"
cat actual_result.txt
echo "-------------------------"
cat expected/result.txt
rm -f actual_result.txt
exit 1

