# DQL — 数据查询语言 / 基础子查询

> **故事线与承上启下**：前面的查询都直接面向表。本节把一条查询的结果交给另一条查询使用，用子查询表达“高于整体平均值”“属于某个结果集合”等两阶段问题。

## ⚡ 速查摘要

- 子查询按返回形状分为标量、列、行和表子查询。
- 标量位置必须最多返回一个值；多行会直接报错。
- 多值结果使用 `IN`、`EXISTS` 或集合比较，不能使用 `=`。
- `NOT IN` 子查询只要返回一个 `NULL`，外层判断就可能全部变成 `UNKNOWN`。
- 派生表必须有别名；相关子查询可能对外层每行重复执行。

## 🎯 学习目标与验收标准

**学习目标：**

- 根据子查询的结果形状选择合法上下文。
- 使用标量子查询完成整体基准比较。
- 使用列子查询完成集合成员过滤。
- 理解行子查询与派生表的基本语法。
- 识别多行报错、`NULL` 污染和相关子查询成本。

**验收标准：**

- [ ] 能查询存在高于全站平均金额订单的用户。
- [ ] 能解释 `=` 与 `IN` 对子查询基数的不同要求。
- [ ] 能说明 `NOT IN` 的 `NULL` 风险。
- [ ] 能独立完成 `exercises/03.04.12-basic-subqueries` 并通过测试。

## 📖 子查询的四种结果形状

### 1. 标量子查询

返回一行一列，可放在表达式位置：

```sql
SELECT order_no, total_amount
FROM orders
WHERE total_amount > (
    SELECT AVG(total_amount)
    FROM orders
);
```

聚合查询在没有 `GROUP BY` 时通常返回一个值，适合作为比较基准。若子查询返回多行，MySQL 会报 `Subquery returns more than 1 row`。

### 2. 列子查询

返回多行一列，常与 `IN` 配合：

```sql
SELECT id, username
FROM users
WHERE id IN (
    SELECT user_id
    FROM orders
    WHERE status = 'PAID'
);
```

子查询可能返回重复值，但 `IN` 只判断成员关系。若只关心“是否存在”，`EXISTS` 往往更直接。

### 3. 行子查询

返回一行多列，可进行 Row Constructor 比较：

```sql
SELECT id, order_no
FROM orders
WHERE (user_id, total_amount) = (
    SELECT user_id, MAX(total_amount)
    FROM orders
    WHERE user_id = 1
    GROUP BY user_id
);
```

左右两侧列数和类型必须可比较，子查询仍必须最多返回一行。

### 4. 表子查询（派生表）

返回多行多列，放在 `FROM` 中并必须设置别名：

```sql
SELECT summary.user_id, summary.total_amount
FROM (
    SELECT user_id, SUM(total_amount) AS total_amount
    FROM orders
    GROUP BY user_id
) AS summary
WHERE summary.total_amount >= 1000;
```

派生表可能被优化器合并，也可能物化为临时结果。不要假设它一定只执行一次或一定落盘，应通过后续 `EXPLAIN` 验证。

## 🔁 非相关与相关子查询

非相关子查询不引用外层列，可独立执行。相关子查询引用外层当前行：

```sql
SELECT u.id, u.username
FROM users AS u
WHERE EXISTS (
    SELECT 1
    FROM orders AS o
    WHERE o.user_id = u.id
      AND o.status = 'PAID'
);
```

相关子查询语义是“对每个外层用户检查是否存在订单”。优化器可能将其改写为 Semi Join，但不能把优化当成必然；大表路径需要用 `EXPLAIN` 验证索引与扫描行数。

## ⚠️ NULL 与否定集合

以下查询存在高危语义：

```sql
WHERE id NOT IN (SELECT nullable_user_id FROM audit_records)
```

只要子查询结果包含 `NULL`，`id NOT IN (...)` 可能对所有候选行返回 `UNKNOWN`。优先使用 `NOT EXISTS`，或在子查询中明确排除 `NULL`。

## 🛒 订单系统实战

查询至少有一笔订单高于全站平均订单金额的用户：

```sql
SELECT id, username
FROM users
WHERE id IN (
    SELECT user_id
    FROM orders
    WHERE total_amount > (
        SELECT AVG(total_amount)
        FROM orders
    )
)
ORDER BY id;
```

内层标量子查询计算基准，中间列子查询生成用户 ID 集合，外层查询返回用户契约。三层结构分别只有一个职责。

## ⚠️ 常见坑点

- **用 `=` 接多行结果**：结果超过一行时直接失败，应根据语义改用 `IN` 或约束为单行。
- **滥用 `LIMIT 1` 消除报错**：没有确定排序时只是随机隐藏数据问题。
- **`NOT IN` 遇到 `NULL`**：可能导致结果意外为空。
- **派生表缺少别名**：MySQL 语法错误。
- **相关子查询缺少索引**：外层行数乘以内层扫描成本，可能从毫秒放大到秒级。

## 🧠 主动回忆

1. 标量、列、行和表子查询分别返回什么形状？
2. 为什么不能用无排序的 `LIMIT 1` 修复多行子查询？
3. `NOT EXISTS` 如何规避 `NOT IN` 的 `NULL` 污染？

## 🧭 进阶路线提示

| 后续章节 | 会继续解决什么问题 |
|---|---|
| 04.01 索引基础与查询计划 | 使用 `EXPLAIN` 判断子查询是否被改写以及扫描成本。 |
| 04.04 高级查询表达 | 相关子查询优化、CTE、集合操作和窗口函数。 |

## ✅ 项目练习

去 `exercises/03.04.12-basic-subqueries`，查询存在高于平均金额订单的用户。

```bash
bash test.sh
```

