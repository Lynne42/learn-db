# 练习：控制流与转换

## 业务背景

历史用户昵称可能为 `NULL` 或只有空格，外部评分以字符串保存。客服列表需要输出稳定的展示名、状态文案、数字评分和及格结果。

## 任务要求

请在 `exercise.sql` 中查询全部用户并返回：

1. `id`。
2. `display_name`：使用 `COALESCE(NULLIF(TRIM(nickname), ''), username)`。
3. `status_label`：使用 `CASE`，`status = 1` 返回 `ACTIVE`，其他返回 `DISABLED`。
4. `numeric_score`：使用 `CAST(score_text AS UNSIGNED)`。
5. `result_label`：使用 `IF`，数字评分大于等于 60 返回 `PASS`，否则返回 `FAIL`。
6. 按 `id` 升序排列。

测试脚本会检查关键表达式，禁止硬编码预期结果。

## 如何验证

```bash
bash test.sh
```

通过后发送 `/db.check mysql 03.04.04`。
