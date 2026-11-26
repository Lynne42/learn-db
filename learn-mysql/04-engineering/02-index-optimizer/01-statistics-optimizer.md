# 04.02.01. 统计信息与优化器选择

> **故事线与承上启下**：
> 上一节把 SQL 改写成了可使用索引的形式，但 SARGable 只代表“能够走索引”，不代表优化器“一定走索引”。MySQL 会根据统计信息估算扫描行数和访问成本，再在索引扫描与全表扫描之间选择成本更低的计划。

## ⚡ 速查摘要

- `SHOW INDEX` 的 `Cardinality` 是索引唯一值数量的估算，不是精确计数。
- 选择性约等于 `Cardinality / 总行数`；选择性越高，等值过滤通常越适合索引。
- `ANALYZE TABLE` 重新采样并更新统计信息，不会优化 SQL 本身，也不会保证使用某个索引。
- `EXPLAIN rows` 是基于统计信息的估算值；计划判断必须结合 `type`、`key`、`rows`、`filtered` 和 `Extra`。
- Histogram 适合补充非索引列或分布倾斜列的值分布信息，但有维护成本。

---

## 🎯 学习目标与验收标准

**学习目标：**

- 理解基数、选择性、数据分布与 Cost Model 的关系。
- 能使用 `ANALYZE TABLE` 刷新表和索引统计信息。
- 能区分“SQL 可以使用索引”和“优化器认为使用索引更便宜”。
- 理解 Histogram 的适用边界及其维护方式。

**验收标准：**

- [ ] 能解释为什么低选择性条件即使有索引，也可能选择全表扫描。
- [ ] 能说明 `ANALYZE TABLE` 更新的是统计信息，而不是业务数据或索引定义。
- [ ] 能用 `EXPLAIN` 证明优化器基于当前统计信息选择了哪条访问路径。

---

## 📖 优化器如何做选择

### 1. 可用不等于会用

假设存在索引：

```text
idx_orders_status_created(status, created_at)
```

下面的条件满足最左前缀，因此索引是候选访问路径：

```sql
WHERE status = 'PAID'
```

但如果一张表中 95% 的订单都是 `PAID`，索引需要读取大量二级索引记录，并可能为返回的非索引列进行大量回表。此时顺序扫描整表可能更便宜。优化器比较的是预计成本，不是机械执行“有索引就走索引”。

### 2. 基数与选择性

`SHOW INDEX FROM orders` 中的 `Cardinality` 表示索引前缀不同值数量的估算。可以粗略理解为：

```text
选择性 ≈ Cardinality / 表总行数
```

- 主键通常接近 1，选择性高。
- 性别、布尔状态等字段通常选择性低。
- `status` 单独看可能选择性低，但 `(status, created_at)` 仍能服务“指定状态下按时间过滤或排序”的查询。

选择性只是成本因素之一。是否覆盖、预计命中行数、行宽、页数量、随机 I/O 与顺序 I/O 成本都会影响最终计划。

### 3. `ANALYZE TABLE` 做什么

大量导入、删除或数据分布突变后，已有统计信息可能不能准确描述当前数据。可以执行：

```sql
ANALYZE TABLE orders;
```

它会重新采样并更新优化器使用的表与索引统计信息。注意：

- 它不修改索引结构；
- 它不保证某条 SQL 改走索引；
- 生产环境执行前要评估表规模、版本和元数据锁影响；
- 更新后必须重新执行 `EXPLAIN`，用计划变化验证结果。

### 4. Histogram 的边界

当某列没有合适索引，或值分布高度倾斜，仅靠基数不足以估算某个具体值的命中比例时，MySQL 8.0 可以维护 Histogram：

```sql
ANALYZE TABLE orders
UPDATE HISTOGRAM ON status WITH 16 BUCKETS;
```

删除时使用：

```sql
ANALYZE TABLE orders
DROP HISTOGRAM ON status;
```

Histogram 只帮助优化器估算分布，不提供数据访问路径；它不能替代索引。桶数量越多不代表越好，还会增加统计信息维护成本。本节练习只使用普通 `ANALYZE TABLE`，不创建 Histogram。

## 🛒 订单系统实战

测试库中有 1000 条订单，其中只有 10 条状态为 `PAID`。刷新统计信息后观察计划：

```sql
ANALYZE TABLE orders;

EXPLAIN
SELECT id, status, created_at
FROM orders
WHERE status = 'PAID'
ORDER BY created_at;
```

健康信号如下：

- `key = idx_orders_status_created`：优化器选择了状态与时间复合索引；
- `type = ref`：通过 `status` 等值定位索引范围；
- `rows` 接近低占比的 `PAID` 记录数，而不是整表行数；
- `Using index`：查询列由二级索引及其隐式主键覆盖；
- 没有 `Using filesort`：固定 `status` 后，索引内按 `created_at` 有序。

这不能推出“`PAID` 查询永远走索引”。当数据分布、返回列或查询范围改变时，成本也会改变，必须重新读取实际计划。

## ⚠️ 常见坑点

- **看到索引存在就断言会使用**：索引只是候选路径，最终由 Cost Model 选择。
- **把 `rows` 当作精确值**：它是估算；真实执行行数需要 `EXPLAIN ANALYZE`，且后者会执行查询。
- **计划异常就直接 `FORCE INDEX`**：hint 会掩盖统计信息、SQL 形态或索引设计问题。
- **频繁执行 `ANALYZE TABLE`**：统计信息维护是运维动作，应由数据分布变化和计划证据驱动。
- **把 Histogram 当索引**：Histogram 只改善估算，不能加速记录定位。

## 🧠 主动回忆

1. 为什么 SARGable 条件仍可能得到 `type = ALL`？
2. `Cardinality` 和 `rows` 为什么都不能当作精确计数？
3. `ANALYZE TABLE` 后为什么还必须重新执行 `EXPLAIN`？
4. Histogram 与 B+Tree 索引分别解决什么问题？

## ✅ 项目练习

前往 [04.02.01-statistics-optimizer](../../exercises/04.02.01-statistics-optimizer/) 刷新订单表统计信息，并验证优化器对低占比状态查询的自然选择。

```bash
bash test.sh
```

通过后发送 `/db.check mysql 04.02.01 你的掌握度` 登记进度。
