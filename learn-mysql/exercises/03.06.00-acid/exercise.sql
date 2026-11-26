-- TODO: 在显式事务中扣减库存 2，并创建指定订单与订单明细。
-- 必须使用 START TRANSACTION 和 COMMIT；库存更新必须包含 stock >= 2 条件。
START TRANSACTION;

UPDATE products
SET stock = stock - 2
WHERE id = 1 AND stock >= 2;

INSERT INTO orders (id, order_no, user_id, total_amount, status)
VALUES (100, 'ORD-TX-001', 1, 200.00, 'PENDING');

INSERT INTO order_items (id, order_id, product_id, quantity, unit_price)
VALUES (100, 100, 1, 2, 100.00);

COMMIT;
