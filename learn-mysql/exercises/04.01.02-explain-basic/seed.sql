-- 用途：准备 EXPLAIN 入门练习的确定性订单明细数据。
-- 参数：无。
-- 返回值：无；向隔离测试库写入商品、订单及订单明细。

INSERT INTO users (id, username, email, password_hash, status) VALUES
    (401, 'explain_user', 'explain@example.com', 'hash-explain', 1);

INSERT INTO categories (id, name) VALUES
    (401, '执行计划测试分类');

INSERT INTO products (id, category_id, spu_no, name, price, stock) VALUES
    (401, 401, 'SPU-EXPLAIN-401', '执行计划测试商品 A', 20.00, 100),
    (402, 401, 'SPU-EXPLAIN-402', '执行计划测试商品 B', 30.00, 100);

INSERT INTO orders (id, order_no, user_id, total_amount, status) VALUES
    (401, 'ORD-EXPLAIN-401', 401, 40.00, 'PAID'),
    (402, 'ORD-EXPLAIN-402', 401, 60.00, 'PAID'),
    (403, 'ORD-EXPLAIN-403', 401, 30.00, 'PENDING');

INSERT INTO order_items (id, order_id, product_id, quantity, unit_price) VALUES
    (401, 401, 401, 2, 20.00),
    (402, 402, 401, 3, 20.00),
    (403, 403, 402, 1, 30.00);
