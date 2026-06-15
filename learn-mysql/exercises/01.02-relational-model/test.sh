#!/bin/bash
set -e

FILE="exercise.txt"

if [ ! -f "$FILE" ]; then
    echo "❌ 找不到 $FILE 文件"
    exit 1
fi

# 提取第一题和第二题的答案（转小写，去空格）
ANS1=$(grep -E "^1\." $FILE | awk -F'：' '{print $2}' | tr -d ' ' | tr '[:upper:]' '[:lower:]')
ANS2=$(grep -E "^2\." $FILE | awk -F'：' '{print $2}' | tr -d ' ' | tr '[:upper:]' '[:lower:]')

# 第一题应该是 1:N 或者 一对多
if [[ "$ANS1" != "1:n" && "$ANS1" != "一对多" && "$ANS1" != "1:m" ]]; then
    echo "❌ 第一题错误！请重新思考：一个用户可以有几个订单？一个订单能属于几个用户？"
    exit 1
fi

# 第二题应该是 N:M 或者 多对多
if [[ "$ANS2" != "n:m" && "$ANS2" != "多对多" && "$ANS2" != "m:n" ]]; then
    echo "❌ 第二题错误！请重新思考：一个订单里能买几种商品？一种商品能出现在几个订单里？"
    exit 1
fi

echo "✅ 测试通过！完美的架构直觉！你已经掌握了最核心的实体关系映射原理。"
