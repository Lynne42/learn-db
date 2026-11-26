# 练习：基础子查询

## 任务要求

在 `exercise.sql` 中查询至少存在一笔订单金额高于全站订单平均金额的用户，返回：

1. `users.id`。
2. `users.username`。
3. 外层使用 `WHERE id IN (...)`。
4. 中间子查询从 `orders` 返回 `user_id`。
5. 内层使用 `SELECT AVG(total_amount) FROM orders` 作为标量子查询。
6. 按用户 `id ASC` 排序。

完成后执行 `bash test.sh`，通过后发送 `/db.check mysql 03.04.12`。

