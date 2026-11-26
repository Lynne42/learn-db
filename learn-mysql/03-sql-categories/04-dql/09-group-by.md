# DQL — 数据查询语言 / 聚合函数与分组

> **故事线与承上启下**：
> Join 解决了“把哪些明细行组合起来”，但运营报表需要回答“每种订单状态有多少单、金额多少、均值和极值是什么”。这要求把明细行折叠为分组，并对每组执行聚合。

## ⚡ 速查摘要

- `COUNT`、`SUM`、`AVG`、`MIN`、`MAX` 把一组多行归约为一个标量结果。
- `GROUP BY` 定义分组键；没有 `GROUP BY` 时，整个结果集视为一组。
- `WHERE` 在分组前过滤明细行，`HAVING` 在分组后过滤聚合结果。
- `COUNT(*)` 统计行数，`COUNT(col)` 忽略 `NULL`；`COUNT(1)` 在 MySQL 中通常与 `COUNT(*)` 等价，但表达意图不如后者清晰。
- 开启 `ONLY_FULL_GROUP_BY` 时，非聚合输出列必须属于分组键或可被证明函数依赖于分组键。

---

## 🎯 学习目标与验收标准

**学习目标：**

- 掌握五个核心聚合函数的 NULL 语义。
- 理解 `GROUP BY` 如何把明细行划分为组。
- 能正确选择 `WHERE` 与 `HAVING`。
- 理解 `ONLY_FULL_GROUP_BY` 防止不确定结果的原因。
- 能为订单状态构建可重复验证的统计报表。

**验收标准：**

- [ ] 能解释 `COUNT(*)` 与 `COUNT(nullable_col)` 的差异。
- [ ] 能按订单状态计算数量、总额、均值、最小值和最大值。
- [ ] 能使用 `HAVING` 筛选订单数不少于 2 的分组。
- [ ] 能独立完成 `exercises/03.04.09-group-by` 并通过测试。

---

## 📖 概念全景

### 1. 从明细行到分组结果

聚合查询的逻辑过程：

```mermaid
flowchart LR
    A["FROM / JOIN 产生明细行"] --> B["WHERE 过滤明细"]
    B --> C["GROUP BY 按键分桶"]
    C --> D["每组执行 COUNT/SUM/AVG/MIN/MAX"]
    D --> E["HAVING 过滤分组"]
    E --> F["SELECT 输出并 ORDER BY"]
```

例如 6 条订单按 `status` 分组后，结果不再是一单一行，而是一种状态一行。分组改变了结果粒度：输出列必须在“每组”层面有唯一含义。

### 2. 五个核心聚合函数

| 函数 | 语义 | NULL 行为 |
|---|---|---|
| `COUNT(*)` | 统计行数 | 包含列值为 NULL 的行 |
| `COUNT(col)` | 统计非 NULL 值数量 | 忽略 NULL |
| `SUM(col)` | 求和 | 忽略 NULL；无有效值时返回 NULL |
| `AVG(col)` | 平均值 | 忽略 NULL，分母是非 NULL 数量 |
| `MIN(col)` / `MAX(col)` | 最小值 / 最大值 | 忽略 NULL |

`AVG(amount)` 等价于非 NULL 金额的 `SUM(amount) / COUNT(amount)`，不是除以 `COUNT(*)`。

### 3. COUNT(*)、COUNT(1)、COUNT(col)

- `COUNT(*)` 明确表示统计行数，是首选。
- `COUNT(1)` 统计常量表达式的非 NULL 次数，优化器通常产生与 `COUNT(*)` 相同的计划。
- `COUNT(col)` 用于统计该列有值的行数，语义不同。

不要以“`COUNT(1)` 一定更快”为依据写代码。现代 MySQL 优化器会针对行计数优化；应先表达正确语义，再用 `EXPLAIN` 和基准验证性能。

### 4. GROUP BY 与结果粒度

```sql
SELECT status, COUNT(*) AS order_count
FROM orders
GROUP BY status;
```

`status` 是分组键，每个分组内它只有一个确定值。若同时输出 `order_no`，同一状态可能有多个订单号，数据库无法确定该返回哪一个。

### 5. ONLY_FULL_GROUP_BY

`ONLY_FULL_GROUP_BY` 会拒绝不确定查询：

```sql
SELECT status, order_no, COUNT(*)
FROM orders
GROUP BY status;
```

正确做法不是随意把所有列塞进 `GROUP BY`，而是先确认报表粒度：

- 要“一种状态一行”：删除 `order_no`，或对其做明确聚合。
- 要“一张订单一行”：分组键应包含订单主键，但此时聚合价值可能消失。
- 若列由主键函数依赖，MySQL 在部分场景能识别并允许。

### 6. WHERE 与 HAVING

```sql
SELECT status, COUNT(*) AS order_count
FROM orders
WHERE created_at >= '2026-01-01'
GROUP BY status
HAVING COUNT(*) >= 2;
```

- `WHERE` 过滤单条订单，发生在分组前，通常能更早减少数据量并利用索引。
- `HAVING` 过滤聚合后的组，可引用聚合表达式。
- 能放在 `WHERE` 的明细条件不要无故推迟到 `HAVING`。

### 7. 分组执行与性能

MySQL 可通过索引顺序完成部分分组，也可能使用临时表、排序或 Hash Aggregation。成本主要由扫描行数、分组基数、聚合状态大小决定。

高风险场景：

- 对亿级明细无时间范围聚合。
- 按高基数字段分组，结果接近原始行数。
- 在分组键上包函数，阻碍索引使用。
- 在线接口实时计算多年报表。

生产报表应限制时间范围，必要时使用汇总表、异步任务或 OLAP 系统。

---

## 💻 SQL 语法

```sql
SELECT
    group_key,
    COUNT(*) AS row_count,
    SUM(amount) AS total_amount,
    AVG(amount) AS avg_amount,
    MIN(amount) AS min_amount,
    MAX(amount) AS max_amount
FROM table_name
WHERE detail_condition
GROUP BY group_key
HAVING COUNT(*) >= 2
ORDER BY group_key;
```

---

## 🛒 订单系统实战

**业务场景：**

运营需要查看各订单状态的订单数、总金额、平均金额和金额区间，只展示订单数不少于 2 的状态。

**实战 SQL：**

```sql
SELECT
    status,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_amount,
    ROUND(AVG(total_amount), 2) AS avg_amount,
    MIN(total_amount) AS min_amount,
    MAX(total_amount) AS max_amount
FROM orders
GROUP BY status
HAVING COUNT(*) >= 2
ORDER BY status;
```

**解析：**

- 一种 `status` 形成一个分组。
- 五个聚合结果都在同一分组粒度上。
- `ROUND` 仅用于稳定展示平均值的小数位。
- `HAVING` 根据聚合后的订单数量过滤。

---

## ⚠️ 常见坑点

- 💣 **在 WHERE 中使用聚合函数**
  - 分组尚未发生，聚合结果不存在。
  - 使用 `HAVING COUNT(*) >= 2`。

- 💣 **SELECT 输出未分组明细列**
  - 结果不确定，并被 `ONLY_FULL_GROUP_BY` 拒绝。
  - 重新确认结果粒度，而不是机械扩展分组键。

- 💣 **把 COUNT(col) 当行数**
  - 可空列会被忽略，统计值偏小。
  - 统计行数使用 `COUNT(*)`。

- 💣 **无边界扫描大表**
  - 聚合可能占用大量 CPU、内存和临时磁盘。
  - 增加可索引时间范围，复杂报表异步化。

---

## 🧠 主动回忆

1. `COUNT(*)` 与 `COUNT(paid_at)` 在未支付订单上有什么差异？
2. 为什么聚合条件通常必须写在 `HAVING`？
3. `ONLY_FULL_GROUP_BY` 阻止了哪类不确定结果？

## 🧭 进阶路线提示

| 后续章节 | 会继续解决什么问题 |
|---|---|
| 03.04.10 高级分组特性 | `GROUP_CONCAT`、`WITH ROLLUP` 与小计总计。 |
| 04.04 高级查询表达 | 窗口函数在保留明细行的同时计算聚合与排名。 |
| 04.01 索引基础与查询计划 | 判断分组是否使用临时表、排序或索引。 |

---

## ✅ 项目练习

去 `exercises/03.04.09-group-by`，完成订单状态聚合报表。

**运行验证：**

```bash
bash test.sh
```

---

## 🚀 延伸学习

- [选读] MySQL Reference Manual：Aggregate Function Descriptions、GROUP BY Modifiers。
- [思考] 订单达到十亿行后，哪些指标应预聚合而不是实时计算？
