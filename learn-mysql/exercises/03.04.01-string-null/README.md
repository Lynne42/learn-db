# 练习：字符串匹配与空值

## 业务背景

为了清理系统中的垃圾测试账号，客服部门需要筛选出没有绑定手机号（`phone IS NULL`）且用户名是以 `test_` 开头的用户。

由于主系统 schema 并不包含 `phone` 列，测试脚本会在测试容器中为 `users` 表临时挂载一个允许为 `NULL` 的 `phone` 字段以供练习。

## 任务要求

请在 `exercise.sql` 中编写 SQL 语句，完成以下任务：
1. 筛选出 `phone` 字段为 `NULL`，且 `username` 以 `test_` 开头的所有用户。
2. 仅投影 `id`、`username` 和 `email` 三个字段，并按 `id` 升序排列。

## 如何验证

请在终端进入本目录，然后执行：
```bash
bash test.sh
```
如果输出 "✅ 测试通过！"，则说明你已掌握本节内容。可以接着向 Agent 发送 `/db.check` 来登记进度。
