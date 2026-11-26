-- TODO: 在事务中完成新订单的 Create/Update、库存 Update、旧订单 Delete。
-- COMMIT 后查询新订单摘要；完整固定值与输出别名见 README.md。
START TRANSACTION;

INSERT INTO orders (id, order_no, user_id, total_amount, status)
VALUES (201, 'ORD-CRUD-NEW', 1, 150.00, 'PENDING');

INSERT INTO order_items (id, order_id, product_id, quantity, unit_price)
VALUES (201, 201, 1, 3, 50.00);

UPDATE products
SET stock = stock - 3
WHERE id = 1 AND stock >= 3;

UPDATE orders
SET status = 'PAID', paid_at = '2026-08-05 10:00:00'
WHERE id = 201 AND status = 'PENDING';

DELETE FROM orders WHERE id = 200 AND status = 'CANCELLED';

COMMIT;

SELECT o.order_no, 
    o.status, 
    p.stock, 
    COUNT(oi.id) AS item_count, 
    SUM(oi.quantity) AS total_quantity
FROM orders AS O
JOIN order_items AS oi ON oi.order_id = o.id
JOIN products AS p ON p.id = oi.product_id
WHERE o.id = 201
GROUP BY o.status

