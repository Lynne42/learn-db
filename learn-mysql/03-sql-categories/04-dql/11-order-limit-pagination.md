# DQL — 数据查询语言 / 排序、限制与分页

> **故事线与承上启下**：聚合报表解决了“看什么”，列表接口还必须解决“先看什么”和“每次取多少”。本节用稳定排序定义结果顺序，用 `LIMIT/OFFSET` 完成基础分页，并识别深度分页的扫描成本。

## ⚡ 速查摘要

- `ORDER BY` 是结果顺序的唯一契约；没有它，返回顺序不确定。
- 排序键不唯一时追加主键，避免跨页重复或遗漏。
- `LIMIT row_count OFFSET offset` 与 `LIMIT offset, row_count` 等价，前者语义更清晰。
- 深度 `OFFSET` 仍需扫描并丢弃前面的行，页码越深成本越高。
- 连续浏览大数据集优先使用 Keyset Pagination。

## 🎯 学习目标与验收标准

**学习目标：**

- 掌握单列、多列以及升降序混合排序。
- 使用 `LIMIT/OFFSET` 实现基础分页。
- 通过唯一 Tie-breaker 构造稳定排序。
- 理解深度分页成本与 Keyset Pagination 的适用边界。

**验收标准：**

- [ ] 能按创建时间倒序、主键倒序稳定排列订单。
- [ ] 能正确计算页码对应的 `OFFSET`。
- [ ] 能解释为什么非唯一排序键会导致跨页漂移。
- [ ] 能独立完成 `exercises/03.04.11-order-limit-pagination` 并通过测试。

## 📖 核心概念

### 1. ORDER BY 定义顺序契约

```sql
SELECT id, order_no, created_at
FROM orders
ORDER BY created_at DESC, id DESC;
```

数据库不会承诺“自然顺序”。即使当前执行计划看似按主键返回，索引、数据量或执行计划变化都可能改变结果。

当多个订单的 `created_at` 相同时，仅按时间排序无法确定它们的相对位置。追加唯一主键 `id` 作为 Tie-breaker，才能形成全序关系。

### 2. LIMIT 与 OFFSET

```sql
SELECT id, order_no
FROM orders
ORDER BY created_at DESC, id DESC
LIMIT 20 OFFSET 40;
```

页大小为 `page_size`、页码从 1 开始时：

```text
offset = (page - 1) * page_size
```

必须限制 `page_size` 上限。无限制的大页会放大数据库扫描、网络传输和应用内存占用。

### 3. 深度分页风险

`LIMIT 20 OFFSET 100000` 并不会直接跳到第 100001 行。MySQL 通常仍需定位、扫描前面的记录，再丢弃 100000 行。若查询还需要回表或 filesort，成本会进一步放大。

### 4. Keyset Pagination

已知上一页最后一条记录的 `(created_at, id)` 时，可继续向后读取：

```sql
SELECT id, order_no, created_at
FROM orders
WHERE (created_at, id) < ('2026-08-03 12:00:00', 9001)
ORDER BY created_at DESC, id DESC
LIMIT 20;
```

它避免扫描巨大 OFFSET，适合信息流和“加载更多”。代价是不能低成本随机跳到任意页，客户端还需要保存 Cursor。

## 🛒 订单系统实战

查询订单列表的第 2 页，每页 3 条：

```sql
SELECT order_no, total_amount, created_at
FROM orders
ORDER BY created_at DESC, id DESC
LIMIT 3 OFFSET 3;
```

排序字段应与访问路径匹配。当前 `orders` 已有 `(user_id, created_at)` 和 `(status, created_at)` 索引；全站订单流是否需要新索引，应在 04.01 使用 `EXPLAIN` 基于真实查询验证，不能仅因出现 `ORDER BY` 就盲目加索引。

## ⚠️ 常见坑点

- **无 `ORDER BY` 直接分页**：不同请求可能返回重复或遗漏数据。
- **只按非唯一字段排序**：相同值的记录顺序不稳定，必须追加唯一键。
- **页码与 OFFSET 混淆**：第 1 页的 OFFSET 是 0。
- **任意放大 page_size**：单次请求可能从几十行膨胀到数万行。
- **深度 OFFSET**：扫描成本随偏移量近似线性增长，应评估 Keyset Pagination。

## 🧠 主动回忆

1. 为什么主键看似递增时仍不能省略 `ORDER BY`？
2. `ORDER BY created_at DESC` 为什么不足以保证稳定分页？
3. Keyset Pagination 用什么能力换取了深页性能？

## ✅ 项目练习

去 `exercises/03.04.11-order-limit-pagination`，完成稳定排序与分页查询。

```bash
bash test.sh
```

