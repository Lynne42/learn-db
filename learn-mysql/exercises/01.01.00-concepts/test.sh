#!/bin/bash
# 自动化测试脚本
set -e

CONTAINER_NAME="mysql-learn"
DB_USER="root"
DB_PASS="root123"

# 1. 检查 SQL 文件是否为空或未修改
if grep -q "TODO:" exercise.sql && [ $(wc -l < exercise.sql) -le 4 ]; then
    echo "❌ 错误：你似乎还没有完成 exercise.sql，请编写完 SQL 语句后再执行 /db.check"
    exit 1
fi

# 2. 检查容器是否运行
if ! docker compose ps | grep -q "$CONTAINER_NAME"; then
    echo "❌ 错误：MySQL 容器未运行！请先在项目根目录运行 docker compose up -d"
    exit 1
fi

echo "⏳ 正在连接 MySQL 并在测试环境中执行你的 SQL..."

# 3. 提取实际结果 (忽略 seed，因为本节没数据)
# 使用 -N 去掉外边框，避免格式问题影响对比
# 实际上测试我们需要保留列名以便校验
docker exec -i $CONTAINER_NAME mysql -u$DB_USER -p$DB_PASS < exercise.sql > actual_result.txt 2> error.log || {
    echo "❌ SQL 执行失败！错误信息如下："
    cat error.log
    exit 1
}

# 4. 对比结果
if diff -q actual_result.txt expected/result.txt > /dev/null; then
    echo "✅ 测试通过！你的第一条 SQL 成功执行！"
else
    echo "❌ 测试失败。输出不匹配："
    echo "--- 你的输出 ---"
    cat actual_result.txt
    echo "--- 期望输出 ---"
    cat expected/result.txt
    echo "请检查列名(使用 AS 别名)和输出的值是否完全一致。"
    exit 1
fi
