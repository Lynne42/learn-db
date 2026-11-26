-- 用途：为 03.07.02 准备用户、商品和待清理的取消订单。
-- 参数：无。
-- 返回值：无。

INSERT INTO users (id, username, email, password_hash, status) VALUES
    (1, 'alice', 'alice@example.com', 'hash-alice', 1);

INSERT INTO products (id, category_id, spu_no, name, price, stock) VALUES
    (1, NULL, 'SPU-CRUD-001', 'CRUD 综合商品', 50.00, 10);

INSERT INTO orders (id, order_no, user_id, total_amount, status) VALUES
    (200, 'ORD-CRUD-CANCELLED', 1, 50.00, 'CANCELLED');

INSERT INTO order_items (id, order_id, product_id, quantity, unit_price) VALUES
    (200, 200, 1, 1, 50.00);

