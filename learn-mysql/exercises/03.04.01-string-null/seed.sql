-- 插入测试数据
INSERT INTO users (id, username, email, password_hash, status, phone) VALUES 
(1, 'test_alice', 'alice@example.com', 'pwd_alice', 1, NULL),       -- 符合：test_ 开头，phone 为 NULL
(2, 'test_bob', 'bob@example.com', 'pwd_bob', 1, '13800138000'),   -- 不符合：phone 不为 NULL
(3, 'charlie', 'charlie@example.com', 'pwd_charlie', 1, NULL),     -- 不符合：不是 test_ 开头
(4, 'test_david', 'david@example.com', 'pwd_david', 0, NULL);      -- 符合：test_ 开头，phone 为 NULL
