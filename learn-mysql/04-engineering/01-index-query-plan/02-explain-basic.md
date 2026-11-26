# 04.01.02. EXPLAIN 入门

> **故事线与承上启下**：
> 上一节已经为商品维度的订单明细查询设计了复合覆盖索引。但“建了索引”不等于“查询一定在用它”。本节用 `EXPLAIN` 读取优化器选择的访问路径，确认过滤、排序和返回列是否真的由目标索引承担。

## ⚡ 速查摘要

- `EXPLAIN SELECT ...`：查看优化器计划，不执行查询。
- 优先看 `type`、`key`、`rows`、`Extra`，而不是只看某一个字段。
- `possible_keys` 是候选索引；`key` 才是实际选中的索引。
- `Using index` 表示覆盖索引；不等于“扫描行数一定少”。

---

## 🎯 学习目标与验收标准

**学习目标：**

- 区分 `possible_keys` 与 `key`，判断优化器最终选择了哪条访问路径。
- 理解 `type`、`key_len`、`rows`、`filtered` 和 `Extra` 的职责与边界。
- 能用 `EXPLAIN` 验证复合索引是否同时完成过滤、排序和覆盖读取。

**验收标准：**

- [ ] 能解释 `type = ref` 表示通过非唯一索引进行等值匹配，而不是全表扫描。
- [ ] 能指出 `key = idx_order_items_product_order_quantity` 说明实际使用了目标复合索引。
- [ ] 能解释 `Extra: Using index` 表示 `order_id`、`quantity` 都可直接从二级索引叶子节点返回。

---

## 📖 EXPLAIN 读法

### 1. `EXPLAIN` 给出的是什么

`EXPLAIN` 展示的是优化器在当前统计信息、索引和 SQL 形态下选择的**计划**，不是实际耗时报告。它适合先判断“会怎么查”；需要测量实际执行和每个算子耗时时，MySQL 8.0 可使用 `EXPLAIN ANALYZE`，但后者会真实执行 SQL。

```sql
EXPLAIN
SELECT order_id, quantity
FROM order_items
WHERE product_id = 401
ORDER BY order_id;
```

这条查询对应索引：

```text
idx_order_items_product_order_quantity(product_id, order_id, quantity)
```

`product_id = 401` 固定最左列，索引记录在该范围内天然按 `order_id` 排列；`order_id`、`quantity` 又都在叶子节点中，因此没有必要回表。

### 2. 第一轮只看四列

| 列 | 要回答的问题 | 本题的健康信号 |
|---|---|---|
| `type` | 用什么访问方式取行？   | `ref`，表示按非唯一索引等值查找 |
| `key`  | 实际使用了哪条索引？   | `idx_order_items_product_order_quantity` |
| `rows` | 优化器预计扫描多少行？ | 接近该商品的订单明细数，而不是整张表 |
| `Extra`| 是否还有额外代价？     | `Using index`，且没有 `Using filesort` |

不要把 `rows` 当成精确计数。它来自统计信息，是优化器的估算值；数据分布或统计信息变化后会变化。

### 3. 其余关键列

| 列 | 含义 | 常见误读 |
|---|---|---|
| `possible_keys` | 理论上可用的候选索引 | 出现在这里不代表一定会被使用 |
| `key_len`       | 本次用于定位的索引字节数 | 不是整个索引定义的总长度；复合索引可能只用到左侧若干列 |
| `ref`           | 与索引列比较的值或列 | `const` 表示与常量比较，不表示查询结果一定只有一行 |
| `filtered`      | 存储引擎取到行后，估计还能通过其余条件的比例 | 不是“索引过滤率”的唯一指标 |

### 4. `type` 的常见访问方式

`type` 不是绝对排行榜，要结合 SQL 目的和扫描行数判断；下面是入门阶段最常见的几种：

| `type` | 含义 | 典型场景 |
|---|---|---|
| `const` | 主键或唯一索引常量等值，最多一行 | `WHERE id = 1` |
| `eq_ref` | JOIN 时通过主键或唯一索引匹配一行 | 关联查询的被驱动表 |
| `ref` | 非唯一索引等值匹配 | `WHERE product_id = 401` |
| `range` | 索引范围扫描 | `WHERE created_at >= ...` |
| `index` | 扫描整棵索引 | 覆盖查询但没有有效过滤时可能出现 |
| `ALL` | 全表扫描 | 没有合适索引或优化器认为扫描全表更便宜 |

### 5. `Extra` 的三个高频信号

- `Using index`：查询需要的列都在索引里，形成覆盖索引，避免回表。
- `Using index condition`：Index Condition Pushdown（ICP）生效，部分条件在索引层提前过滤；它不等于覆盖索引。
- `Using filesort`：不能直接按索引顺序输出 `ORDER BY`，MySQL 需要额外排序；名称不代表一定写入磁盘文件。

---

## 🛒 订单系统实战

商品运营需要查看商品 `401` 出现在哪些订单中，并按订单 ID 查看购买数量：

```sql
EXPLAIN
SELECT order_id, quantity
FROM order_items
WHERE product_id = 401
ORDER BY order_id;
```

预期的阅读顺序：

1. `key` 是 `idx_order_items_product_order_quantity`，确认不是误走其他索引。
2. `type` 是 `ref`，确认通过 `product_id` 做了等值定位。
3. `Extra` 包含 `Using index`，确认返回列不需要回表。
4. `Extra` 没有 `Using filesort`，确认 `order_id` 排序复用了索引顺序。

如果 `key` 为 `NULL` 或 `type` 为 `ALL`，先核对 SQL 是否跳过了联合索引的最左列；不要立刻用 `FORCE INDEX` 掩盖问题。

---

## ⚠️ 常见坑点

- 💣 **只看 `possible_keys`**：它只说明候选项，必须以 `key` 为准。
- 💣 **看到 `Using index` 就停止分析**：这只能证明不回表；若 `rows` 很大，扫描仍可能很慢。
- 💣 **把 `key_len` 当作索引长度**：它只表示本次访问用到的前缀长度。
- 💣 **用 `FORCE INDEX` 代替理解计划**：它会改变优化器选择，适合作为诊断实验，不能替代索引设计。

## 🧠 主动回忆

1. `possible_keys` 和 `key` 分别表示什么？
2. 为什么本题的 `ORDER BY order_id` 不需要 `Using filesort`？
3. `Using index` 与 `Using index condition` 的区别是什么？

## ✅ 项目练习

前往 [04.01.02-explain-basic](../../exercises/04.01.02-explain-basic/) 编写一条 `EXPLAIN`，验证复合覆盖索引的真实访问计划。

在练习目录执行：

```bash
bash test.sh
```

通过后发送 `/db.check mysql 04.01.02` 登记进度。
