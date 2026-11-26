-- 重建本 lesson 专用排除表，避免重复执行时残留数据影响结果。
DROP TABLE IF EXISTS lesson_030402_marketing_exclusions;

CREATE TABLE lesson_030402_marketing_exclusions (
    user_id INT NULL
);

-- 用户 2 被明确排除；NULL 用于验证 NOT IN 的三值逻辑陷阱。
INSERT INTO lesson_030402_marketing_exclusions (user_id) VALUES
    (2),
    (NULL);

-- 构造三个活跃用户和一个禁用用户。
INSERT INTO users (id, username, email, password_hash, status) VALUES
    (1, 'active_alice', 'active_alice@example.com', 'pwd_alice', 1),
    (2, 'blocked_bob', 'blocked_bob@example.com', 'pwd_bob', 1),
    (3, 'active_carol', 'active_carol@example.com', 'pwd_carol', 1),
    (4, 'disabled_david', 'disabled_david@example.com', 'pwd_david', 0);
