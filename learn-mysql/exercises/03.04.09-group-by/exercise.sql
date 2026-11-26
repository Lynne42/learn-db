-- TODO: 按订单状态生成聚合报表。
-- 必须使用 COUNT、SUM、AVG、MIN、MAX、GROUP BY、HAVING。
-- 按 status 升序排序。
SELECT status, COUNT(*) AS order_count, SUM(total_amount) AS total_amount, ROUND(AVG(total_amount), 2) AS avg_amount, MIN(total_amount) AS min_amount, MAX(total_amount) AS max_amount
FROM orders
GROUP BY status
HAVING COUNT(*) >= 2
ORDER BY status ASC;
