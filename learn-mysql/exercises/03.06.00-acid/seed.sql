-- 用途：为 03.06.00 准备用户与商品初始状态。
-- 参数：无。
-- 返回值：无。

INSERT INTO users (id, username, email, password_hash, status) VALUES
    (1, 'alice', 'alice@example.com', 'hash-alice', 1);

INSERT INTO products (id, category_id, spu_no, name, price, stock) VALUES
    (1, NULL, 'SPU-TX-001', '事务练习商品', 100.00, 10);

