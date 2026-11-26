# 练习：聚合函数与分组

## 任务要求

在 `exercise.sql` 中按 `orders.status` 分组，返回：

1. `status`。
2. `COUNT(*) AS order_count`。
3. `SUM(total_amount) AS total_amount`。
4. `ROUND(AVG(total_amount), 2) AS avg_amount`。
5. `MIN(total_amount) AS min_amount`。
6. `MAX(total_amount) AS max_amount`。
7. 使用 `HAVING COUNT(*) >= 2`，并按 `status ASC` 排序。

完成后执行 `bash test.sh`，通过后发送 `/db.check mysql 03.04.09`。
