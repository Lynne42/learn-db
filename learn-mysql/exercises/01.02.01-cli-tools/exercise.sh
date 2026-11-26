#!/bin/bash

# 请在这行下方写下你的那行极其硬核的组合命令：
# (注意：我们在外层目录运行 docker compose，所以直接写 docker compose exec ...)

Docker compose exec mysql-learn mysql -uroot -proot123 -e "SELECT 'Ready for duty' AS status;"
