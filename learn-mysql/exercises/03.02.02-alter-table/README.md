# 练习：表结构变更

## 业务背景

我们的电商订单系统需要追踪用户的账号注册时间与最后修改时间。同时，后台管理系统需要支持不区分大小写地检索用户名，为此我们需要在数据库层增加一个虚拟生成列 `username_lower`，自动实时提取并存储小写形式的用户名。

## 任务要求

请在 `exercise.sql` 中编写 SQL 语句，使用 `ALTER TABLE` 对已存在的 `users` 表进行表结构变更，具体要求如下：

1. 增加必填字段 `created_at`，数据类型为 `TIMESTAMP`，默认值为当前时间 `CURRENT_TIMESTAMP`。
2. 增加必填字段 `updated_at`，数据类型为 `TIMESTAMP`，默认值为当前时间，且在更新记录时自动刷新（`CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP`）。
3. 增加虚拟生成列 `username_lower`，数据类型为 `VARCHAR(50)`，定义为 `LOWER(username)` 的虚拟列（`GENERATED ALWAYS AS (LOWER(username)) VIRTUAL`）。由于不写 `NOT NULL`，默认允许为空。

## 如何验证

请在终端进入本目录，然后执行：
```bash
bash test.sh
```
如果输出 "✅ 测试通过！"，则说明你已掌握本节内容。可以接着向 Agent 发送 `/db.check` 来登记进度。
