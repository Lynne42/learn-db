-- 用途：为 03.07.01 提供订单详情与消费统计测试数据。
-- 参数：无。
-- 返回值：无。

INSERT INTO users (id, username, email, password_hash, status) VALUES
    (1, 'alice', 'alice@example.com', 'hash-alice', 1),
    (2, 'bob', 'bob@example.com', 'hash-bob', 1);

INSERT INTO products (id, category_id, spu_no, name, price, stock) VALUES
    (1, NULL, 'SPU-PROJ-001', '无线鼠标', 60.00, 20),
    (2, NULL, 'SPU-PROJ-002', '机械键盘', 220.00, 10);

INSERT INTO orders (id, order_no, user_id, total_amount, status) VALUES
    (101, 'ORD-PROJ-001', 1, 100.00, 'PAID'),
    (102, 'ORD-PROJ-002', 2, 200.00, 'SHIPPED'),
    (103, 'ORD-PROJ-003', 1, 999.00, 'CANCELLED');

INSERT INTO order_items (id, order_id, product_id, quantity, unit_price) VALUES
    (1001, 101, 1, 2, 50.00),
    (1002, 102, 2, 1, 200.00),
    (1003, 103, 2, 1, 999.00);

