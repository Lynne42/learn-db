#!/bin/bash
# 用途：验证时间条件是否可被 orders.created_at 索引直接搜索。
# 参数：无。
# 返回值：目标 EXPLAIN 计划成立时返回 0，否则返回 1。

set -u

CONTAINER_NAME="mysql-learn"
DB_NAME="order_system_lesson_040200"
TARGET_INDEX="idx_orders_created_at"

# 检查 Docker 依赖，避免将环境故障误报为 SQL 问题。
if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    echo "❌ 错误：MySQL 容器未运行。请先在项目根目录执行 docker compose up -d。"
    exit 1
fi

# 重建隔离数据库，排除已有统计信息、数据和索引对测试的影响。
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' -e "DROP DATABASE IF EXISTS ${DB_NAME}; CREATE DATABASE ${DB_NAME} DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci;"; then
    echo "❌ 错误：重建隔离数据库失败。"
    exit 1
fi

# 应用到 V8，保证订单时间索引已存在且练习不依赖后续 Schema。
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

# 删除注释后检查练习边界，防止通过改表、改索引或索引提示绕开优化目标。
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
if printf '%s\n' "$SQL_FLAT" | grep -Eiq 'EXPLAIN[[:space:]]+ANALYZE|FORCE[[:space:]]+INDEX|USE[[:space:]]+INDEX|IGNORE[[:space:]]+INDEX|DATE[[:space:]]*\(|DATE_FORMAT[[:space:]]*\(|YEAR[[:space:]]*\(|MONTH[[:space:]]*\('; then
    echo "❌ 错误：本题不能使用时间函数、EXPLAIN ANALYZE 或索引提示。"
    exit 1
fi
# 使用标识符边界匹配写操作关键字，避免将 created_at 等字段名误判为 CREATE。
if printf '%s\n' "$SQL_FLAT" | grep -Eiq '(^|[^[:alnum:]_])(INSERT|UPDATE|DELETE|TRUNCATE|CREATE|ALTER|DROP|RENAME)([^[:alnum:]_]|$)|(^|[^[:alnum:]_])ANALYZE[[:space:]]+TABLE([^[:alnum:]_]|$)'; then
    echo "❌ 错误：exercise.sql 只能包含目标 EXPLAIN 查询。"
    exit 1
fi
if ! printf '%s\n' "$SQL_FLAT" | grep -Eiq 'SELECT[[:space:]]+id[[:space:]]*,[[:space:]]*created_at[[:space:]]+FROM[[:space:]]+orders'; then
    echo "❌ 错误：查询列或目标表不符合要求。"
    exit 1
fi
if ! printf '%s\n' "$SQL_FLAT" | grep -Eiq "created_at[[:space:]]*>=[[:space:]]*'2026-08-01[[:space:]]+00:00:00'"; then
    echo "❌ 错误：缺少 8 月开始时间的下界。"
    exit 1
fi
if ! printf '%s\n' "$SQL_FLAT" | grep -Eiq "created_at[[:space:]]*<[[:space:]]*'2026-09-01[[:space:]]+00:00:00'"; then
    echo "❌ 错误：缺少 9 月开始时间的右开上界。"
    exit 1
fi

# 执行用户 SQL，并以制表符格式读取计划以避免表格排版差异。
if ! EXPLAIN_RESULT=$(docker exec -i "$CONTAINER_NAME" mysql -N -B -u root -p'root123' "$DB_NAME" < exercise.sql); then
    echo "❌ 错误：exercise.sql 执行失败。"
    exit 1
fi

# 校验范围访问、实际索引和覆盖读取；不存在 filesort 也说明本题没有额外排序。
if ! printf '%s\n' "$EXPLAIN_RESULT" | awk -F '\t' -v target_index="$TARGET_INDEX" '
    $3 == "orders" && $5 == "range" && $7 == target_index && $12 ~ /Using index/ && $12 !~ /Using filesort/ { matched = 1 }
    END { exit matched ? 0 : 1 }
'; then
    echo "❌ 测试失败：执行计划未显示 range + 时间索引 + Using index。"
    printf '%s\n' "$EXPLAIN_RESULT"
    exit 1
fi

echo "✅ 测试通过！你已将时间函数过滤改写为可使用索引的范围条件。"
