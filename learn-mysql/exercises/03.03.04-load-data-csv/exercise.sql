-- TODO: 请在下方编写你的 SQL 语句
-- 使用 LOAD DATA INFILE 将 '/var/lib/mysql-files/seed_data.csv' 导入到 users 表中

LOAD DATA INFILE '/var/lib/mysql-files/seed_data.csv'
INTO TABLE users
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(username, email, password_hash, status)