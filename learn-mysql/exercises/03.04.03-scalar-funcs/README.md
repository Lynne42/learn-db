# 练习：标量函数

## 业务背景

客服列表需要对历史用户名做首尾空格清理，并展示确定的用户标签、距离分数、注册日期和距活动锚点日的天数。

## 任务要求

请在 `exercise.sql` 中查询全部用户并返回以下列：

1. `id`。
2. `user_label`：使用 `CONCAT`、`TRIM`、`CHAR_LENGTH`，格式为 `清理后的用户名#字符数`。
3. `distance_score`：使用 `ROUND(ABS(id - 4) / 3, 2)`。
4. `registered_date`：使用 `DATE_FORMAT` 输出 `%Y-%m-%d`。
5. `days_from_anchor`：使用 `ABS(DATEDIFF(created_at, '2026-07-01'))`。
6. 按 `id` 升序排列。

禁止硬编码预期结果；测试脚本会检查要求使用的函数。

## 如何验证

```bash
bash test.sh
```

通过后发送 `/db.check mysql 03.04.03` 登记进度。
