-- TODO: 按创建时间和主键倒序查询订单，并返回指定分页窗口。
-- 必须使用 ORDER BY created_at DESC, id DESC 和 LIMIT 3 OFFSET 2。
SELECT order_no, total_amount, created_at
FROM orders
ORDER BY created_at DESC, id DESC
LIMIT 3 OFFSET 2
