#!/bin/bash
# 用途：重建 V1-V6 测试环境并验证 03.04.02 的 NOT EXISTS 查询结果。
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

echo "⏳ 正在重建测试 Schema..."
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" -e "
DROP TABLE IF EXISTS lesson_030402_marketing_exclusions;
DROP TABLE IF EXISTS user_roles;
DROP TABLE IF EXISTS roles;
DROP TABLE IF EXISTS users;
"; then
    echo "❌ 错误：清理测试 Schema 失败。"
    exit 1
fi

for schema_file in \
    ../../schema/v001-create-users.sql \
    ../../schema/v002-alter-users.sql \
    ../../schema/v003-users-unique.sql \
    ../../schema/v004-create-roles.sql \
    ../../schema/v005-create-user-roles.sql \
    ../../schema/v006-users-index.sql; do
    if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < "$schema_file"; then
        echo "❌ 错误：应用 $schema_file 失败。"
        exit 1
    fi
done

echo "⏳ 正在导入三值逻辑测试数据..."
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < seed.sql; then
    echo "❌ 错误：导入 seed.sql 失败。"
    exit 1
fi

if ! sed '/^[[:space:]]*--/d' exercise.sql | grep -Eiq '(^|[^[:alnum:]_])NOT[[:space:]]+EXISTS([^[:alnum:]_]|$)'; then
    echo "❌ 错误：本练习必须使用 NOT EXISTS。"
    exit 1
fi

if sed '/^[[:space:]]*--/d' exercise.sql | grep -Eiq '(^|[^[:alnum:]_])NOT[[:space:]]+IN([^[:alnum:]_]|$)'; then
    echo "❌ 错误：本练习禁止使用 NOT IN。"
    exit 1
fi

echo "🏃 正在执行查询..."
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < exercise.sql > actual_result.txt; then
    echo "❌ 错误：exercise.sql 执行失败，请检查 SQL 语法。"
    rm -f actual_result.txt
    exit 1
fi

if diff -q actual_result.txt expected/result.txt > /dev/null; then
    echo "✅ 测试通过！你已安全处理 NOT IN 与 NULL 的陷阱。"
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
