# 练习：自连接与层级关系

## 业务背景

商品后台需要展示所有分类及其直接父分类。根分类也必须出现，其 `parent_name` 为 SQL `NULL`。

## 任务要求

在 `exercise.sql` 中编写一条查询：

1. 从 `categories AS child` 查询。
2. 使用 `LEFT JOIN categories AS parent ON parent.id = child.parent_id` 完成 Self Join。
3. 返回 `child.id AS category_id`、`child.name AS category_name`、`parent.name AS parent_name`。
4. 使用 `ORDER BY child.id ASC` 保证结果稳定。

禁止使用子查询、Recursive CTE、`UNION`、`INNER JOIN`、`RIGHT JOIN` 或写死结果。

## 如何验证

```bash
bash test.sh
```

通过后发送 `/db.check mysql 03.04.08`。
