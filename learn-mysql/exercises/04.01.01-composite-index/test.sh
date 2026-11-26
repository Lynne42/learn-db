#!/bin/bash
# 用途：验证 order_items 复合索引的列顺序、冗余索引清理和覆盖查询能力。
# 参数：无。
# 返回值：全部索引契约成立时返回 0，否则返回 1。

set -u

CONTAINER_NAME="mysql-learn"
DB_NAME="order_system_lesson_040101"

# 检查本地实验依赖，避免把 Docker 未启动误判为 SQL 错误。
if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    echo "❌ 错误：MySQL 容器未运行。请先在项目根目录执行 docker compose up -d。"
    exit 1
fi

# 每次重建隔离数据库，保证索引状态不受上一次测试影响。
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' -e "DROP DATABASE IF EXISTS ${DB_NAME}; CREATE DATABASE ${DB_NAME} DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci;"; then
    echo "❌ 错误：重建隔离数据库失败。"
    exit 1
fi

# 本练习以 Schema V8 为基线；目标复合索引由用户在 exercise.sql 中创建。
for schema_file in ../../schema/v001-create-users.sql ../../schema/v002-alter-users.sql ../../schema/v003-users-unique.sql ../../schema/v004-create-roles.sql ../../schema/v005-create-user-roles.sql ../../schema/v006-users-index.sql ../../schema/v007-create-catalog-orders.sql ../../schema/v008-orders-created-index.sql; do
    if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < "$schema_file"; then
        echo "❌ 错误：应用 ${schema_file} 失败。"
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

# 限制练习操作边界，防止通过改表、改数据或关闭约束绕过索引设计任务。
SQL_FLAT=$(printf '%s\n' "$SQL_BODY" | tr '\n' ' ')
if ! printf '%s\n' "$SQL_FLAT" | grep -Eiq 'DROP[[:space:]]+INDEX'; then
    echo "❌ 错误：必须删除旧单列索引。"
    exit 1
fi
if ! printf '%s\n' "$SQL_FLAT" | grep -Eiq 'CREATE[[:space:]]+(INDEX|KEY)'; then
    echo "❌ 错误：必须创建复合索引。"
    exit 1
fi
if printf '%s\n' "$SQL_FLAT" | grep -Eiq 'INSERT|UPDATE|DELETE|TRUNCATE|DROP[[:space:]]+TABLE|ALTER[[:space:]]+TABLE|FOREIGN_KEY_CHECKS'; then
    echo "❌ 错误：只能删除旧索引并创建目标索引。"
    exit 1
fi

if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < exercise.sql; then
    echo "❌ 错误：exercise.sql 执行失败。"
    exit 1
fi

# 精确校验索引名、列顺序和唯一性。
docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" -e "
SELECT INDEX_NAME, SEQ_IN_INDEX, COLUMN_NAME, NON_UNIQUE
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = '${DB_NAME}'
  AND TABLE_NAME = 'order_items'
  AND INDEX_NAME = 'idx_order_items_product_order_quantity'
ORDER BY SEQ_IN_INDEX;
" > actual_result.txt

if ! diff -q actual_result.txt expected/result.txt > /dev/null; then
    echo "❌ 测试失败：复合索引名称或列顺序不符合要求。"
    cat actual_result.txt
    rm -f actual_result.txt
    exit 1
fi

# 旧单列索引必须移除，否则每次写入仍会维护两棵前缀重复的 B+Tree。
OLD_INDEX_COUNT=$(docker exec -i "$CONTAINER_NAME" mysql -N -s -u root -p'root123' "$DB_NAME" -e "SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA = '${DB_NAME}' AND TABLE_NAME = 'order_items' AND INDEX_NAME = 'idx_order_items_product_id';")
if [ "$OLD_INDEX_COUNT" != "0" ]; then
    echo "❌ 测试失败：旧索引 idx_order_items_product_id 尚未删除。"
    rm -f actual_result.txt
    exit 1
fi

# 使用目标索引验证查询可由叶子节点直接返回，Extra 应包含 Using index。
EXPLAIN_RESULT=$(docker exec -i "$CONTAINER_NAME" mysql -N -s -u root -p'root123' "$DB_NAME" -e "EXPLAIN SELECT order_id, quantity FROM order_items FORCE INDEX (idx_order_items_product_order_quantity) WHERE product_id = 301 ORDER BY order_id;")
if ! printf '%s\n' "$EXPLAIN_RESULT" | grep -Fq 'idx_order_items_product_order_quantity' || ! printf '%s\n' "$EXPLAIN_RESULT" | grep -Fq 'Using index'; then
    echo "❌ 测试失败：目标查询没有形成覆盖索引访问。"
    rm -f actual_result.txt
    exit 1
fi

echo "✅ 测试通过！你已完成复合索引与覆盖索引练习。"
rm -f actual_result.txt
