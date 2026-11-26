#!/bin/bash
# 自动生成的练习验证脚本 - mysqlimport 与基础导出

# 1. 确定容器名
CONTAINER_NAME="mysql-learn"
DB_NAME="order_system"

# 2. 检查容器是否运行
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "❌ 错误：MySQL 容器未运行！请先在项目根目录运行 docker compose up -d"
    exit 1
fi

# 在开始前，物理清理可能残留在容器安全目录下的旧文件（防止 File exists 报错）
docker exec -u root "$CONTAINER_NAME" rm -f /var/lib/mysql-files/active_users.csv

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

echo "⏳ 正在载入测试数据 seed.sql..."
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < seed.sql; then
    echo "❌ 错误：载入测试数据失败！"
    exit 1
fi

echo "🏃 正在执行你的 SELECT ... INTO OUTFILE 导出 SQL..."
if ! docker exec -i "$CONTAINER_NAME" mysql -u root -p'root123' "$DB_NAME" < exercise.sql; then
    echo "❌ 错误：SQL 脚本执行失败！请检查语法，或确认输出文件路径正确且尚未被占用。"
    exit 1
fi

# 3. 将容器内导出的文件拷贝出来进行检验
if ! docker cp "$CONTAINER_NAME":/var/lib/mysql-files/active_users.csv actual_result.txt; then
    echo "❌ 错误：无法从容器安全目录中获取导出的数据文件！请确认你的文件确实被正确写入到指定目录。"
    exit 1
fi

# 清理容器内的导出文件以防二次报错
docker exec -u root "$CONTAINER_NAME" rm -f /var/lib/mysql-files/active_users.csv

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
