# 练习：谓词、三值逻辑与 NULL 陷阱

## 业务背景

运营需要筛选可以参与营销活动的活跃用户。`lesson_030402_marketing_exclusions` 保存被排除的用户 ID，其中故意包含一条 `NULL`，用于复现 `NOT IN` 的空集陷阱。

## 任务要求

请在 `exercise.sql` 中编写一条查询：

1. 从 `users` 查询 `status = 1` 的活跃用户。
2. 使用 `NOT EXISTS` 排除 `lesson_030402_marketing_exclusions` 中已经存在的用户。
3. 仅返回 `id`、`username`，并按 `id` 升序排列。
4. 禁止通过删除排除表中的 `NULL`、硬编码用户 ID 或使用 `NOT IN` 绕过三值逻辑。

## 如何验证

```bash
bash test.sh
```

输出“✅ 测试通过！”表示查询结果与验收结果一致。随后可以发送 `/db.check mysql 03.04.02` 登记进度。
