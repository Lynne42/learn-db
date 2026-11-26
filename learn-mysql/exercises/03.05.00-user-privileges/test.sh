#!/bin/bash
# 用途：验证 03.05.00 的账户创建、授权与权限回收结果。
# 参数：无。
# 返回值：最终仅保留隔离数据库 SELECT 权限时返回 0，否则返回 1。

set -u
CONTAINER_NAME="mysql-learn"
DB_NAME="order_system_lesson_030500"
TEST_ACCOUNT="'order_reporter_030500'@'%'"

# 用途：无论测试成功或失败，都删除实例级测试账户。
# 参数：无。
# 返回值：无；清理失败不覆盖原测试退出码。
cleanup() {
    docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' -e "DROP USER IF EXISTS ${TEST_ACCOUNT};" > /dev/null 2>&1 || true
}

if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    echo "❌ 错误：MySQL 容器未运行。"
    exit 1
fi

trap cleanup EXIT
cleanup

if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' -e "DROP DATABASE IF EXISTS ${DB_NAME}; CREATE DATABASE ${DB_NAME} DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci;"; then
    echo "❌ 错误：重建隔离数据库失败。"
    exit 1
fi

SQL_BODY=$(sed '/^[[:space:]]*--/d' exercise.sql)
if [ -z "${SQL_BODY//[[:space:]]/}" ]; then
    echo "❌ 错误：exercise.sql 尚未完成。"
    exit 1
fi

SQL_FLAT=$(printf '%s\n' "$SQL_BODY" | tr '\n' ' ')
for keyword in CREATE USER IDENTIFIED BY GRANT SELECT INSERT REVOKE ON TO FROM; do
    if ! printf '%s\n' "$SQL_FLAT" | grep -Eiq "(^|[^[:alnum:]_])${keyword}([^[:alnum:]_]|$)"; then
        echo "❌ 错误：exercise.sql 必须使用 ${keyword}。"
        exit 1
    fi
done

if printf '%s\n' "$SQL_FLAT" | grep -Eiq 'ALL[[:space:]]+PRIVILEGES|ON[[:space:]]+\*[.]\*'; then
    echo "❌ 错误：禁止授予 ALL PRIVILEGES 或全局权限。"
    exit 1
fi

if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' < exercise.sql; then
    echo "❌ 错误：exercise.sql 执行失败。"
    exit 1
fi

if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' -e "SHOW GRANTS FOR ${TEST_ACCOUNT};" > actual_result.txt; then
    echo "❌ 错误：无法读取测试账户授权。"
    rm -f actual_result.txt
    exit 1
fi

if diff -q actual_result.txt expected/result.txt > /dev/null; then
    echo "✅ 测试通过！你已掌握 CREATE USER、GRANT 与 REVOKE。"
    rm -f actual_result.txt
    exit 0
fi

echo "❌ 测试失败：最终权限不是数据库级只读权限。"
cat actual_result.txt
echo "-------------------------"
cat expected/result.txt
rm -f actual_result.txt
exit 1

