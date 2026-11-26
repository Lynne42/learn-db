# 练习：外键、参照完整性与逻辑外键

## 业务背景

我们的电商订单系统需要支持用户角色授权，因此需要建立一张角色表 `roles`。同时，为了防止出现“用户被删除了，但其资料依然残留在库里”这种脏数据，我们需要创建一张临时用户个人资料表 `temp_user_profiles`，并在其上定义物理外键，使 `user_id` 关联 `users(id)` 字段，并指定为级联删除（`ON DELETE CASCADE`）。

## 任务要求

请在 `exercise.sql` 中编写两条 `CREATE TABLE` 语句，具体要求如下：

1. **创建角色表 `roles`**：
   - 表名：`roles`
   - 表的存储引擎指定为 `InnoDB`。
   - 默认字符集设为 `utf8mb4`，排序规则设为 `utf8mb4_unicode_ci`。
   - 字段设计：
     - `id`：整型（`INT`），主键自增。
     - `role_name`：变长字符串 `VARCHAR(50)`，必填（`NOT NULL`）且唯一（`UNIQUE KEY uk_roles_role_name`）。
     - `created_at`：时间戳（`TIMESTAMP`），默认值为当前时间 `CURRENT_TIMESTAMP`。

2. **创建用户资料表 `temp_user_profiles`**：
   - 表名：`temp_user_profiles`
   - 表的存储引擎指定为 `InnoDB`。
   - 默认字符集设为 `utf8mb4`，排序规则设为 `utf8mb4_unicode_ci`。
   - 字段设计：
     - `profile_id`：整型（`INT`），主键自增。
     - `user_id`：整型（`INT`），必填（`NOT NULL`）。
     - `real_name`：变长字符串 `VARCHAR(50)`，必填（`NOT NULL`）。
   - **外键约束**：为 `user_id` 列创建指向 `users` 表 `id` 列的物理外键约束，并将删除规则设定为级联删除（`ON DELETE CASCADE`）。

## 如何验证

请在终端进入本目录，然后执行：
```bash
bash test.sh
```
如果输出 "✅ 测试通过！"，则说明你已掌握本节内容。可以接着向 Agent 发送 `/db.check` 来登记进度。
