-- Schema Version: 6
-- Description: 为 users 表补充 created_at 索引 idx_users_created_at
-- Lesson: 04.01.00

CREATE INDEX idx_users_created_at ON users (created_at);
