#!/bin/bash
# 自动生成的练习验证脚本 - 数据更新与删除

# 1. 确定容器名
CONTAINER_NAME="mysql-learn"
DB_NAME="order_system"

# 2. 检查容器是否运行
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "❌ 错误：MySQL 容器未运行！请先在项目根目录运行 docker compose up -d"
    exit 1
fi

echo "⏳ 正在重置测试环境并应用演进表结构..."
# 显式重置表并依次执行历史架构演进脚本
docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" -e "
DROP TABLE IF EXISTS user_roles;
DROP TABLE IF EXISTS roles;
DROP TABLE IF EXISTS users;
"
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < ../../schema/v001-create-users.sql; then
    echo "❌ 错误：导入 v001 基础表失败！"
    exit 1
fi
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < ../../schema/v002-alter-users.sql; then
    echo "❌ 错误：应用 v002 表结构变更失败！"
    exit 1
fi
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < ../../schema/v003-users-unique.sql; then
    echo "❌ 错误：应用 v003 唯一约束失败！"
    exit 1
fi
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < ../../schema/v004-create-roles.sql; then
    echo "❌ 错误：导入 v004 角色表失败！"
    exit 1
fi
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < ../../schema/v005-create-user-roles.sql; then
    echo "❌ 错误：应用 v005 多对多关联表失败！"
    exit 1
fi
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < ../../schema/v006-users-index.sql; then
    echo "❌ 错误：应用 v006 索引失败！"
    exit 1
fi

echo "⏳ 正在导入测试数据..."
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < seed.sql; then
    echo "❌ 错误：导入测试数据 seed.sql 失败！"
    exit 1
fi

echo "🏃 正在安全更新模式下执行你的 SQL..."
# 拼接 SET sql_safe_updates = 1 并执行用户的 SQL
if ! (echo "SET sql_safe_updates = 1;" && cat exercise.sql) | docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME"; then
    echo "❌ 错误：SQL 脚本执行失败！请检查语法错误，或者确认你没有触发安全更新模式 (sql_safe_updates) 的拦截。"
    exit 1
fi

# 3. 提取用于验证的结果
docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" -e "
SELECT username, status 
FROM users 
ORDER BY username;
" > actual_result.txt

# 4. 对比结果
if diff -q actual_result.txt expected/result.txt > /dev/null; then
    echo "✅ 测试通过！你已成功完成本节练习。"
    rm -f actual_result.txt
    exit 0
else
    echo "❌ 测试失败！你的结果与预期不符。"
    echo "【你的结果】：(详见 actual_result.txt)"
    cat actual_result.txt
    echo "-------------------------"
    echo "【预期结果】：(详见 expected/result.txt)"
    cat expected/result.txt
    rm -f actual_result.txt
    exit 1
fi
