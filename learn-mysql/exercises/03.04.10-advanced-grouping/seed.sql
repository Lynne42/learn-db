-- 用途：为 03.04.10 提供高级分组测试数据。
-- 参数：无。
-- 返回值：无。

INSERT INTO users (id, username, email, password_hash, status) VALUES
    (1, 'alice', 'alice@example.com', 'hash-alice', 1);

INSERT INTO orders (id, order_no, user_id, total_amount, status) VALUES
    (1, 'ORD-001', 1, 100.00, 'PAID'),
    (2, 'ORD-002', 1, 200.00, 'PAID'),
    (3, 'ORD-003', 1, 50.00, 'PAID'),
    (4, 'ORD-004', 1, 80.00, 'PENDING'),
    (5, 'ORD-005', 1, 120.00, 'PENDING'),
    (6, 'ORD-006', 1, 30.00, 'CANCELLED');
