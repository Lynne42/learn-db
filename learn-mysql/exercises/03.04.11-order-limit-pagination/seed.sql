-- 用途：为 03.04.11 提供稳定排序与分页测试数据。
-- 参数：无。
-- 返回值：无。

INSERT INTO users (id, username, email, password_hash, status) VALUES
    (1, 'alice', 'alice@example.com', 'hash-alice', 1);

INSERT INTO orders (id, order_no, user_id, total_amount, status, created_at) VALUES
    (1, 'ORD-001', 1, 100.00, 'PAID', '2026-08-01 09:00:00'),
    (2, 'ORD-002', 1, 200.00, 'PAID', '2026-08-02 09:00:00'),
    (3, 'ORD-003', 1, 300.00, 'SHIPPED', '2026-08-02 09:00:00'),
    (4, 'ORD-004', 1, 400.00, 'PENDING', '2026-08-03 09:00:00'),
    (5, 'ORD-005', 1, 500.00, 'PAID', '2026-08-04 09:00:00'),
    (6, 'ORD-006', 1, 600.00, 'COMPLETED', '2026-08-04 09:00:00');

