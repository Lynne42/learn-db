# 练习：高级分组特性

按订单状态生成报表，并追加总计行。返回：

1. `COALESCE(CAST(status AS CHAR), 'ALL') AS status_label`。
2. `COUNT(*) AS order_count`。
3. 使用 `GROUP_CONCAT(order_no ORDER BY order_no SEPARATOR ',') AS order_nos`。
4. `SUM(total_amount) AS total_amount`。
5. 使用 `GROUP BY status WITH ROLLUP`。

完成后运行 `bash test.sh`，通过后发送 `/db.check mysql 03.04.10`。
