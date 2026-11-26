-- 构造包含首尾空格和固定注册日期的用户数据，确保函数结果可重复。
INSERT INTO users (id, username, email, password_hash, status, created_at) VALUES
    (1, ' alice ', 'alice@example.com', 'pwd_alice', 1, '2026-06-28 09:00:00'),
    (2, 'bob', 'bob@example.com', 'pwd_bob', 1, '2026-07-03 10:30:00'),
    (3, ' carol', 'carol@example.com', 'pwd_carol', 0, '2026-07-01 23:59:59');
