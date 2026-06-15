#!/bin/bash
set -e

FILE="exercise.txt"

if [ ! -f "$FILE" ]; then
    echo "❌ 找不到 $FILE 文件"
    exit 1
fi

ANS1=$(grep -E "^1\." $FILE | awk -F'：' '{print $2}' | tr -d ' ' | tr -d '\r')
ANS2=$(grep -E "^2\." $FILE | awk -F'：' '{print $2}' | tr -d ' ' | tr -d '\r')
ANS3=$(grep -E "^3\." $FILE | awk -F'：' '{print $2}' | tr -d ' ' | tr -d '\r')

if [[ "$ANS1" != "/var/lib/mysql" && "$ANS1" != "/var/lib/mysql/" ]]; then
    echo "❌ 第一题错误！请去课件中查找“容器内存储路径”。"
    exit 1
fi

if [[ "$ANS2" != "./data/mysql" && "$ANS2" != "./data/mysql/" && "$ANS2" != "data/mysql" ]]; then
    echo "❌ 第二题错误！请检查我们在 docker-compose.yml 冒号左边写的是哪个路径。"
    exit 1
fi

if [[ "$ANS3" != "13306" && "$ANS3" != *"左"* ]]; then
    echo "❌ 第三题错误！请回想端口映射格式 (宿主机端口:容器内端口)，本机连接使用的是哪个？"
    exit 1
fi

echo "✅ 测试通过！你已经彻底看透了容器化部署的黑盒！"
