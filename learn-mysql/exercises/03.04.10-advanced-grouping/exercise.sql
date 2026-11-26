-- TODO: 按订单状态生成订单号清单、数量和金额，并追加总计行。
-- 必须使用 GROUP_CONCAT、内部 ORDER BY、SEPARATOR 和 WITH ROLLUP。
SELECT COALESCE(CAST(status AS CHAR), 'ALL') AS status_label, 
        COUNT(*) AS order_count, 
        GROUP_CONCAT(order_no ORDER BY order_no SEPARATOR ',') AS order_nos,
        SUM(total_amount) AS total_amount
FROM orders
GROUP BY status WITH ROLLUP;