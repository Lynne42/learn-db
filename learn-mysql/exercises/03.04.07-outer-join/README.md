# 练习：外连接

## 业务背景

权限审计需要列出全部启用用户及其角色。尚未分配角色的启用用户也必须出现，其 `role_name` 应为 SQL `NULL`。

## 任务要求

在 `exercise.sql` 中编写一条查询：

1. 从 `users AS u` 开始。
2. 使用两次显式 `LEFT JOIN ... ON` 连接 `user_roles AS ur` 和 `roles AS r`。
3. 返回 `u.id AS user_id`、`u.username`、`r.role_name`。
4. 使用 `WHERE u.status = 1` 只保留启用用户。
5. 使用 `ORDER BY u.id ASC, r.role_name ASC` 保证结果稳定。

禁止使用 `INNER JOIN`、`RIGHT JOIN`、`NATURAL JOIN`、子查询、`UNION` 或写死结果。不要在 `WHERE` 中过滤右表 `ur`、`r` 的列。

## 如何验证

```bash
bash test.sh
```

通过后发送 `/db.check mysql 03.04.07`。
