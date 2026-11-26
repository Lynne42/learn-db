-- 用途：准备复合索引练习的订单明细数据。
-- 参数：无。
-- 返回值：无；向隔离测试库写入确定性测试数据。

INSERT INTO users (id, username, email, password_hash, status) VALUES
    (301, 'index_user_a', 'index-a@example.com', 'hash-a', 1),
    (302, 'index_user_b', 'index-b@example.com', 'hash-b', 1);

INSERT INTO categories (id, name) VALUES
    (301, '索引测试分类');

INSERT INTO products (id, category_id, spu_no, name, price, stock) VALUES
    (301, 301, 'SPU-IDX-301', '索引测试商品 A', 20.00, 100),
    (302, 301, 'SPU-IDX-302', '索引测试商品 B', 30.00, 100);

INSERT INTO orders (id, order_no, user_id, total_amount, status) VALUES
    (301, 'ORD-IDX-301', 301, 40.00, 'PAID'),
    (302, 'ORD-IDX-302', 302, 70.00, 'PAID'),
    (303, 'ORD-IDX-303', 301, 30.00, 'PENDING');

INSERT INTO order_items (id, order_id, product_id, quantity, unit_price) VALUES
    (301, 301, 301, 2, 20.00),
    (302, 302, 301, 2, 20.00),
    (303, 302, 302, 1, 30.00),
    (304, 303, 302, 1, 30.00);
