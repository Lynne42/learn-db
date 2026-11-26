#!/bin/bash
# 用途：验证 EXPLAIN 查询是否自然使用订单明细复合覆盖索引。
# 参数：无。
# 返回值：计划契约成立时返回 0，否则返回 1。

set -u

CONTAINER_NAME="mysql-learn"
DB_NAME="order_system_lesson_040102"
TARGET_INDEX="idx_order_items_product_order_quantity"

# 检查 Docker 依赖，避免将环境问题误判为 SQL 错误。
if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    echo "❌ 错误：MySQL 容器未运行。请先在项目根目录执行 docker compose up -d。"
    exit 1
fi

# 重建隔离数据库，保证优化器计划不受已有数据和索引状态影响。
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' -e "DROP DATABASE IF EXISTS ${DB_NAME}; CREATE DATABASE ${DB_NAME} DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci;"; then
    echo "❌ 错误：重建隔离数据库失败。"
    exit 1
fi

# 应用到 V9，确保上一节设计的复合覆盖索引已存在。
for schema_file in ../../schema/v001-create-users.sql ../../schema/v002-alter-users.sql ../../schema/v003-users-unique.sql ../../schema/v004-create-roles.sql ../../schema/v005-create-user-roles.sql ../../schema/v006-users-index.sql ../../schema/v007-create-catalog-orders.sql ../../schema/v008-orders-created-index.sql ../../schema/v009-order-items-covering-index.sql; do
    if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < "$schema_file"; then
        echo "❌ 错误：应用 ${schema_file} 失败。"
        exit 1
    fi
done

if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < seed.sql; then
    echo "❌ 错误：导入测试数据失败。"
    exit 1
fi

# 删除注释后检查 SQL 边界，防止通过改索引、改数据或索引提示绕过练习目的。
SQL_BODY=$(sed '/^[[:space:]]*--/d' exercise.sql)
if [ -z "${SQL_BODY//[[:space:]]/}" ]; then
    echo "❌ 错误：exercise.sql 尚未完成。"
    exit 1
fi

SQL_FLAT=$(printf '%s\n' "$SQL_BODY" | tr '\n' ' ')
if ! printf '%s\n' "$SQL_FLAT" | grep -Eiq 'EXPLAIN[[:space:]]+SELECT'; then
    echo "❌ 错误：必须使用标准 EXPLAIN SELECT。"
    exit 1
fi
if printf '%s\n' "$SQL_FLAT" | grep -Eiq 'EXPLAIN[[:space:]]+ANALYZE|FORCE[[:space:]]+INDEX|USE[[:space:]]+INDEX|IGNORE[[:space:]]+INDEX'; then
    echo "❌ 错误：本题不能使用 EXPLAIN ANALYZE 或索引提示。"
    exit 1
fi
if printf '%s\n' "$SQL_FLAT" | grep -Eiq 'INSERT|UPDATE|DELETE|TRUNCATE|CREATE|ALTER|DROP|RENAME|ANALYZE[[:space:]]+TABLE'; then
    echo "❌ 错误：exercise.sql 只能包含目标 EXPLAIN 查询。"
    exit 1
fi
if ! printf '%s\n' "$SQL_FLAT" | grep -Eiq 'SELECT[[:space:]]+order_id[[:space:]]*,[[:space:]]*quantity[[:space:]]+FROM[[:space:]]+order_items'; then
    echo "❌ 错误：查询列或目标表不符合要求。"
    exit 1
fi
if ! printf '%s\n' "$SQL_FLAT" | grep -Eiq 'WHERE[[:space:]]+product_id[[:space:]]*=[[:space:]]*401'; then
    echo "❌ 错误：必须使用 product_id = 401 作为过滤条件。"
    exit 1
fi
if ! printf '%s\n' "$SQL_FLAT" | grep -Eiq 'ORDER[[:space:]]+BY[[:space:]]+order_id'; then
    echo "❌ 错误：必须按 order_id 排序。"
    exit 1
fi

# 执行用户 SQL，并读取制表符格式的计划结果以减少表格格式差异。
if ! EXPLAIN_RESULT=$(docker exec -i "$CONTAINER_NAME" mysql -N -B -u root -p'root123' "$DB_NAME" < exercise.sql); then
    echo "❌ 错误：exercise.sql 执行失败。"
    exit 1
fi

# 校验实际访问方式、目标索引和覆盖读取；同时确保没有额外排序。
if ! printf '%s\n' "$EXPLAIN_RESULT" | awk -F '\t' -v target_index="$TARGET_INDEX" '
    $3 == "order_items" && $5 == "ref" && $7 == target_index && $12 ~ /Using index/ && $12 !~ /Using filesort/ { matched = 1 }
    END { exit matched ? 0 : 1 }
'; then
    echo "❌ 测试失败：执行计划未显示 ref + 目标索引 + Using index，或仍发生 Using filesort。"
    printf '%s\n' "$EXPLAIN_RESULT"
    exit 1
fi

echo "✅ 测试通过！你已能用 EXPLAIN 验证复合覆盖索引计划。"
