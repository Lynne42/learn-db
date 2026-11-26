-- 用途：为 03.04.12 提供基础子查询测试数据。
-- 参数：无。
-- 返回值：无。

INSERT INTO users (id, username, email, password_hash, status) VALUES
    (1, 'alice', 'alice@example.com', 'hash-alice', 1),
    (2, 'bob', 'bob@example.com', 'hash-bob', 1),
    (3, 'carol', 'carol@example.com', 'hash-carol', 1);

INSERT INTO orders (id, order_no, user_id, total_amount, status) VALUES
    (1, 'ORD-001', 1, 100.00, 'PAID'),
    (2, 'ORD-002', 1, 200.00, 'PAID'),
    (3, 'ORD-003', 2, 300.00, 'SHIPPED'),
    (4, 'ORD-004', 3, 500.00, 'PAID');

