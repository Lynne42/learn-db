# 练习：多对多关系与关联表设计

## 业务背景

在我们的订单系统中，用户与角色是典型的多对多关系（一个用户可以有多个角色，一个角色下包含多个用户）。为了在物理数据库层打通二者的关联，我们需要设计并创建关联表 `user_roles`。

为了保证性能，该表采用 `(user_id, role_id)` 联合主键的形式组织，并且我们需要分别对这两个字段建立物理外键关联，以确保删除用户或删除角色时，中间表的关联数据能级联删除（`ON DELETE CASCADE`）。同时，为了能快速通过角色反向过滤出用户，我们需要为 `role_id` 单独创建二级索引。

## 任务要求

请在 `exercise.sql` 中编写一条 `CREATE TABLE` 语句，创建 `user_roles` 关联表，具体字段与约束要求如下：

1. 表名为 `user_roles`。
2. 表的存储引擎指定为 `InnoDB`，默认字符集为 `utf8mb4`，排序规则为 `utf8mb4_unicode_ci`。
3. 字段设计：
   - `user_id`：整型（`INT`），必填（`NOT NULL`）。
   - `role_id`：整型（`INT`），必填（`NOT NULL`）。
   - `created_at`：时间戳（`TIMESTAMP`），默认值为当前时间 `CURRENT_TIMESTAMP`。
4. 约束设计：
   - **联合主键**：`(user_id, role_id)`。
   - **物理外键 1**：使 `user_id` 关联 `users` 表的 `id` 字段，删除动作设为级联删除（`ON DELETE CASCADE`）。
   - **物理外键 2**：使 `role_id` 关联 `roles` 表的 `id` 字段，删除动作设为级联删除（`ON DELETE CASCADE`）。
   - **二级索引**：单独为 `role_id` 字段创建一个普通二级索引，索引名命名为 `idx_user_roles_role_id`。

## 如何验证

请在终端进入本目录，然后执行：
```bash
bash test.sh
```
如果输出 "✅ 测试通过！"，则说明你已掌握本节内容。可以接着向 Agent 发送 `/db.check` 来登记进度。
