-- TODO: 请在下方编写你的 SQL 语句
-- 1. 为 users 表的 username 字段添加唯一约束，命名为 uk_users_username
ALTER TABLE users ADD CONSTRAINT uk_users_username UNIQUE (username);

-- 2. 为 users 表的 email 字段添加唯一约束，命名为 uk_users_email
ALTER TABLE users ADD CONSTRAINT uk_users_email UNIQUE (email);
