-- Schema Version: 3
-- Description: 为 users 表补充唯一键约束 uk_users_username 与 uk_users_email
-- Lesson: 03.02.03

ALTER TABLE users 
  ADD CONSTRAINT uk_users_username UNIQUE (username),
  ADD CONSTRAINT uk_users_email UNIQUE (email);
