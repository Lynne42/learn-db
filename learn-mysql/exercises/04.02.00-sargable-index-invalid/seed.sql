-- 用途：准备 SARGable 时间范围练习的确定性订单数据。
-- 参数：无。
-- 返回值：无；向隔离测试库写入跨月订单记录。

INSERT INTO users (id, username, email, password_hash, status, created_at) VALUES
    (420, 'sargable_user', 'sargable@example.com', 'hash-sargable', 1, '2026-07-01 00:00:00');

INSERT INTO orders (id, order_no, user_id, total_amount, status, created_at) VALUES
    (4201, 'ORD-SARG-4201', 420, 10.00, 'PAID', '2026-07-31 23:59:59'),
    (4202, 'ORD-SARG-4202', 420, 20.00, 'PAID', '2026-08-01 00:00:00'),
    (4203, 'ORD-SARG-4203', 420, 30.00, 'PENDING', '2026-08-15 12:00:00'),
    (4204, 'ORD-SARG-4204', 420, 40.00, 'PAID', '2026-09-01 00:00:00');
