-- TODO: 请在下方编写你的 SQL 语句
-- 使用 CREATE INDEX 为 users 表的 created_at 字段创建名为 idx_users_created_at 的二级索引
CREATE INDEX idx_users_created_at ON users (created_at);
