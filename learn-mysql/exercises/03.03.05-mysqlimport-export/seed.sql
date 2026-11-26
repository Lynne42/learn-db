-- 预置测试用户数据
INSERT INTO users (username, email, password_hash, status) VALUES 
('active_bob', 'bob@order.com', 'pwd_bob', 1),
('active_alice', 'alice@order.com', 'pwd_alice', 1),
('inactive_charlie', 'charlie@order.com', 'pwd_charlie', 0);
