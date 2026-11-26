#!/bin/bash
# 用途：在隔离数据库中验证 03.04.12 的标量与列子查询。
# 参数：无。
# 返回值：结果一致返回 0；失败返回 1。

set -u
CONTAINER_NAME="mysql-learn"
DB_NAME="order_system_lesson_030412"

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

# 将多行 SQL 折叠为单行，仅用于跨行结构校验，不改变实际执行内容。
SQL_FLAT=$(printf '%s\n' "$SQL_BODY" | tr '\n' ' ')

for keyword in SELECT FROM WHERE IN AVG ORDER; do
    if ! printf '%s\n' "$SQL_BODY" | grep -Eiq "(^|[^[:alnum:]_])${keyword}([^[:alnum:]_]|$)"; then
        echo "❌ 错误：exercise.sql 必须使用 ${keyword}。"
        exit 1
    fi
done

if ! printf '%s\n' "$SQL_BODY" | grep -Eiq 'AVG[[:space:]]*\([[:space:]]*total_amount[[:space:]]*\)'; then
    echo "❌ 错误：必须使用 AVG(total_amount) 计算全站平均订单金额。"
    exit 1
fi

if ! printf '%s\n' "$SQL_FLAT" | grep -Eiq 'SELECT[[:space:]]+([[:alnum:]_]+\.)?user_id[[:space:]]+FROM[[:space:]]+orders'; then
    echo "❌ 错误：列子查询必须从 orders 返回 user_id。"
    exit 1
fi

if ! printf '%s\n' "$SQL_BODY" | grep -Eiq 'ORDER[[:space:]]+BY[[:space:]]+id[[:space:]]+ASC'; then
    echo "❌ 错误：必须使用 ORDER BY id ASC。"
    exit 1
fi

if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < exercise.sql > actual_result.txt; then
    echo "❌ 错误：exercise.sql 执行失败。"
    rm -f actual_result.txt
    exit 1
fi

if diff -q actual_result.txt expected/result.txt > /dev/null; then
    echo "✅ 测试通过！你已掌握标量子查询与列子查询。"
    rm -f actual_result.txt
    exit 0
fi

echo "❌ 测试失败：查询结果与预期不符。"
cat actual_result.txt
echo "-------------------------"
cat expected/result.txt
rm -f actual_result.txt
exit 1
