# 练习：排序、限制与分页

## 任务要求

在 `exercise.sql` 中查询订单列表，返回：

1. `order_no`。
2. `total_amount`。
3. `created_at`。
4. 按 `created_at DESC, id DESC` 稳定排序。
5. 使用 `LIMIT 3 OFFSET 2` 返回排序后的第 3 至第 5 条记录。

完成后执行 `bash test.sh`，通过后发送 `/db.check mysql 03.04.11`。

