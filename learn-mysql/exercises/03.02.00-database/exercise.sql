-- TODO: 请在下方编写你的 SQL 语句
-- 1. 安全创建名为 temp_test_db 的数据库，设置其默认字符集为 utf8mb4，默认排序规则为 utf8mb4_bin
CREATE DATABASE IF NOT EXISTS temp_test_db
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_bin;

-- 2. 修改该数据库，将其默认排序规则改为 utf8mb4_unicode_ci
ALTER DATABASE temp_test_db
    COLLATE utf8mb4_unicode_ci;
