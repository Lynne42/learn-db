#!/bin/bash
# 用途：验证学员刷新统计信息后，能读取优化器对低占比状态查询的自然计划。
# 参数：无。
# 返回值：ANALYZE 与 EXPLAIN 计划契约成立时返回 0，否则返回 1。

set -u

CONTAINER_NAME="mysql-learn"
DB_NAME="order_system_lesson_040201"
TARGET_INDEX="idx_orders_status_created"

# 检查 Docker 依赖，避免将环境问题误判为 SQL 错误。
if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    echo "❌ 错误：MySQL 容器未运行。请先在项目根目录执行 docker compose up -d。"
    exit 1
fi

# 重建隔离数据库，固定本题的数据分布与统计信息起点。
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' -e "DROP DATABASE IF EXISTS ${DB_NAME}; CREATE DATABASE ${DB_NAME} DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci;"; then
    echo "❌ 错误：重建隔离数据库失败。"
    exit 1
fi

# 应用到 V8，确保订单表及目标复合索引存在。
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

# 删除注释后检查练习边界，确保学员同时完成统计刷新与计划观察。
SQL_BODY=$(sed '/^[[:space:]]*--/d' exercise.sql)
if [ -z "${SQL_BODY//[[:space:]]/}" ]; then
    echo "❌ 错误：exercise.sql 尚未完成。"
    exit 1
fi

SQL_FLAT=$(printf '%s\n' "$SQL_BODY" | tr '\n' ' ')
if ! printf '%s\n' "$SQL_FLAT" | grep -Eiq '(^|[^[:alnum:]_])ANALYZE[[:space:]]+TABLE[[:space:]]+orders([^[:alnum:]_]|$)'; then
    echo "❌ 错误：必须先使用 ANALYZE TABLE orders 刷新统计信息。"
    exit 1
fi
if ! printf '%s\n' "$SQL_FLAT" | grep -Eiq 'EXPLAIN[[:space:]]+SELECT'; then
    echo "❌ 错误：必须使用标准 EXPLAIN SELECT 观察查询计划。"
    exit 1
fi
if printf '%s\n' "$SQL_FLAT" | grep -Eiq 'EXPLAIN[[:space:]]+ANALYZE|FORCE[[:space:]]+INDEX|USE[[:space:]]+INDEX|IGNORE[[:space:]]+INDEX|UPDATE[[:space:]]+HISTOGRAM|DROP[[:space:]]+HISTOGRAM'; then
    echo "❌ 错误：本题不能使用 EXPLAIN ANALYZE、索引提示或 Histogram 操作。"
    exit 1
fi
if printf '%s\n' "$SQL_FLAT" | grep -Eiq '(^|[^[:alnum:]_])(INSERT|UPDATE|DELETE|TRUNCATE|CREATE|ALTER|DROP|RENAME)([^[:alnum:]_]|$)'; then
    echo "❌ 错误：exercise.sql 不能修改表结构或业务数据。"
    exit 1
fi
if ! printf '%s\n' "$SQL_FLAT" | grep -Eiq 'SELECT[[:space:]]+id[[:space:]]*,[[:space:]]*status[[:space:]]*,[[:space:]]*created_at[[:space:]]+FROM[[:space:]]+orders'; then
    echo "❌ 错误：查询列或目标表不符合要求。"
    exit 1
fi
if ! printf '%s\n' "$SQL_FLAT" | grep -Eiq "WHERE[[:space:]]+status[[:space:]]*=[[:space:]]*'PAID'"; then
    echo "❌ 错误：必须使用 status = 'PAID' 作为过滤条件。"
    exit 1
fi
if ! printf '%s\n' "$SQL_FLAT" | grep -Eiq 'ORDER[[:space:]]+BY[[:space:]]+created_at([[:space:]]+ASC)?([^[:alnum:]_]|$)'; then
    echo "❌ 错误：必须按 created_at 升序排列。"
    exit 1
fi

# 执行学员 SQL；ANALYZE 结果为 4 列，EXPLAIN 结果为 12 列，可按表名区分。
if ! SQL_RESULT=$(docker exec -i "$CONTAINER_NAME" mysql -N -B -u root -p'root123' "$DB_NAME" < exercise.sql); then
    echo "❌ 错误：exercise.sql 执行失败。"
    exit 1
fi

# 校验 ANALYZE 成功，并验证低占比条件使用目标覆盖索引且不额外排序。
if ! printf '%s\n' "$SQL_RESULT" | awk -F '\t' -v target_index="$TARGET_INDEX" '
    $2 == "analyze" && $3 == "status" && $4 == "OK" { analyzed = 1 }
    $3 == "orders" && $5 == "ref" && $7 == target_index && $12 ~ /Using index/ && $12 !~ /Using filesort/ { explained = 1 }
    END { exit analyzed && explained ? 0 : 1 }
'; then
    echo "❌ 测试失败：未同时得到 ANALYZE 成功与 ref + 目标索引 + Using index 的执行计划。"
    printf '%s\n' "$SQL_RESULT"
    exit 1
fi

echo "✅ 测试通过！你已刷新统计信息并验证优化器的自然索引选择。"
