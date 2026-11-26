# 练习：数据插入

## 业务背景

为了跑通电商系统最基础的“用户登录与角色授权”逻辑，我们需要往系统里录入第一批测试账号与初始系统角色。
由于我们之前创建了多对多关联表关系（`user_roles`），我们需要根据依赖关系，以正确的顺序往三张表中注入初始数据。

## 任务要求

请在 `exercise.sql` 中编写 SQL 语句，完成以下数据的批量写入：

1. 往角色表 `roles` 中批量插入以下两个角色：
   - 角色 1：`id` 为 `1`，`role_name` 为 `'Administrator'`，`description` 为 `'Super Admin'`。
   - 角色 2：`id` 为 `2`，`role_name` 为 `'User'`，`description` 为 `'Regular User'`。

2. 往用户表 `users` 中批量插入以下两个用户：
   - 用户 1：`id` 为 `1`，`username` 为 `'root_user'`，`email` 为 `'root@order.com'`，`password_hash` 为 `'hash_root'`，`status` 为 `1`。
   - 用户 2：`id` 为 `2`，`username` 为 `'dev_user'`，`email` 为 `'dev@order.com'`，`password_hash` 为 `'hash_dev'`，`status` 为 `1`。

3. 往用户角色关联表 `user_roles` 中插入绑定关系：
   - 用户 `'root_user'` (id=1) 拥有 `'Administrator'` (id=1) 角色。
   - 用户 `'dev_user'` (id=2) 拥有 `'User'` (id=2) 角色。

## 如何验证

请在终端进入本目录，然后执行：
```bash
bash test.sh
```
如果输出 "✅ 测试通过！"，则说明你已成功完成。可以接着向 Agent 发送 `/db.check` 来登记进度。
