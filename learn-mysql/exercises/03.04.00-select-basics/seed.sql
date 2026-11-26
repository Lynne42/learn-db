-- 插入测试数据
INSERT INTO users (id, username, email, password_hash, status) VALUES 
(1, 'alice', 'alice@example.com', 'pwd_alice', 1),   -- id 1-10, 但 status = 1，不应被查出
(2, 'bob', 'bob@example.com', 'pwd_bob', 0),       -- id 1-10, status = 0, 应被查出
(3, 'charlie', 'charlie@example.com', 'pwd_charlie', 0), -- id 1-10, status = 0, 应被查出
(10, 'david', 'david@example.com', 'pwd_david', 0), -- id 1-10, status = 0, 应被查出
(11, 'eve', 'eve@example.com', 'pwd_eve', 0),       -- status = 0, 但 id > 10，不应被查出
(12, 'frank', 'frank@example.com', 'pwd_frank', 1); -- id > 10, status = 1, 不应被查出
