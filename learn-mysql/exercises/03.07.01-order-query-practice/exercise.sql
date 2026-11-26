-- TODO: 先查询指定订单的商品明细，再统计每个用户的有效消费。
-- 两个 SELECT 的字段别名、状态口径、分组和排序要求见 README.md。
SELECT o.order_no, 
        u.username, 
        p.name AS product_name, 
        oi.quantity,
        oi.unit_price,
        oi.quantity * oi.unit_price AS line_amount
FROM orders AS o
JOIN users AS u ON u.id = o.user_id
JOIN order_items AS oi ON o.id = oi.order_id
JOIN products AS p ON oi.product_id = p.id
WHERE order_no = 'ORD-PROJ-002'
ORDER BY o.id ASC;

SELECT u.id AS user_id,
        u.username,
        COUNT(o.id) AS order_count,
        SUM(o.total_amount) AS total_spent
FROM users AS u
JOIN orders AS o ON o.user_id = u.id
WHERE o.status IN ('PAID', 'SHIPPED', 'COMPLETED')
GROUP BY u.id
ORDER BY user_id ASC;

