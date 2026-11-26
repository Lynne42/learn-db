# 练习：内连接

## 业务背景

后台需要查询所有启用用户及其角色。用户、授权关系、角色分别存放在 `users`、`user_roles`、`roles` 中。

## 任务要求

在 `exercise.sql` 中编写一条查询：

1. 从 `users AS u` 开始。
2. 使用显式 `INNER JOIN ... ON` 连接 `user_roles AS ur` 和 `roles AS r`。
3. 返回 `u.id AS user_id`、`u.username`、`r.role_name`。
4. 使用 `WHERE u.status = 1` 只保留启用用户。
5. 使用 `ORDER BY u.id ASC, r.role_name ASC` 保证结果稳定。

禁止使用逗号连接、`NATURAL JOIN`、子查询或写死结果。

## 如何验证

```bash
bash test.sh
```

通过后发送 `/db.check mysql 03.04.06`。
