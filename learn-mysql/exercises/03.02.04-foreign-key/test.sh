#!/bin/bash
# 自动生成的练习验证脚本 - 外键与参照完整性

# 1. 确定容器名
CONTAINER_NAME="mysql-learn"
DB_NAME="order_system"

# 2. 检查容器是否运行
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "❌ 错误：MySQL 容器未运行！请先在项目根目录运行 docker compose up -d"
    exit 1
fi

echo "⏳ 正在重置测试环境并应用演进表结构..."
# 显式重置旧表
docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" -e "
DROP TABLE IF EXISTS temp_user_profiles;
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

echo "🏃 正在执行你的 DDL 建表及外键关联..."
# 执行用户的 SQL
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < exercise.sql; then
    echo "❌ 错误：SQL 脚本执行失败！请检查语法错误。"
    exit 1
fi

# 3. 进行外键级联删除测试
echo "⏳ 正在测试 ON DELETE CASCADE 级联删除特性..."
docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" -e "
INSERT INTO users (id, username, email, password_hash) VALUES (999, 'test_fk_user', 'fk_test@example.com', 'hash');
INSERT INTO temp_user_profiles (user_id, real_name) VALUES (999, 'FK Test Real Name');
"
# 执行物理删除
docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" -e "DELETE FROM users WHERE id = 999;"
# 校验子表记录数
COUNT=$(docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" -N -e "SELECT COUNT(*) FROM temp_user_profiles WHERE user_id = 999;")
if [ "$COUNT" -eq 0 ]; then
    echo "✅ 级联删除校验成功！子表关联记录已自动被 CASCADE 清除。"
else
    echo "❌ 错误：级联删除校验失败！父表记录删除后，子表关联行依然残留。"
    docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" -e "DROP TABLE IF EXISTS temp_user_profiles; DROP TABLE IF EXISTS roles;"
    exit 1
fi

# 4. 提取用于验证的外键元数据状态
docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" -e "
SELECT TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME 
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
WHERE TABLE_SCHEMA = '$DB_NAME' 
  AND TABLE_NAME = 'temp_user_profiles' 
  AND REFERENCED_TABLE_NAME = 'users';
" > actual_result.txt

# 5. 清理临时资料表，释放资源（主线 roles 表保留以备后用）
docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" -e "DROP TABLE IF EXISTS temp_user_profiles;"

# 6. 对比结果
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
