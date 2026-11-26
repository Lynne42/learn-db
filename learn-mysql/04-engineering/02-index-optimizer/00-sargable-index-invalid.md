# 04.02.00. SARGable 条件与索引失效

> **故事线与承上启下**：
> 订单后台按“某个月创建的订单”筛选时，开发者写出了 `DATE_FORMAT(created_at, '%Y-%m') = '2026-08'`。索引明明存在，`EXPLAIN` 却显示全表扫描。问题不在索引缺失，而在于条件把索引列加工成了新值，B+Tree 无法按原值直接定位。

## ⚡ 速查摘要

- SARGable：条件可直接用索引列值界定搜索范围。
- 不要在 `WHERE` 中对索引列做函数、算术运算或隐式类型转换。
- 时间条件优先写成左闭右开范围：`>= 开始时间 AND < 下一时间边界`。
- 是否真正使用索引，必须用 `EXPLAIN` 看 `key`、`type`、`rows` 与 `Extra`。

---

## 🎯 学习目标与验收标准

**学习目标：**

- 理解 SARGable 条件与 B+Tree 有序边界的关系。
- 能把按天、按月的时间函数过滤改写为时间范围。
- 能识别函数、表达式、隐式转换和前导模糊匹配造成的索引失效。

**验收标准：**

- [ ] 能解释为什么 `DATE(created_at) = '2026-08-01'` 不会直接利用 `created_at` 的有序值定位。
- [ ] 能写出等价的 `created_at >= ... AND created_at < ...` 条件。
- [ ] 能用 `EXPLAIN` 验证 `idx_orders_created_at` 的 `range` 访问。

---

## 📖 什么是 SARGable

SARGable 是 **Search ARGument Able** 的缩写：优化器能够把条件转化为索引上的连续搜索边界。

对索引 `idx_orders_created_at(created_at)` 来说，下面两种写法的语义接近，但物理含义不同：

```sql
-- 非 SARGable：先对每一行的索引列执行函数，再比较结果。
WHERE DATE_FORMAT(created_at, '%Y-%m') = '2026-08'

-- SARGable：直接在 B+Tree 的 created_at 有序范围内定位。
WHERE created_at >= '2026-08-01 00:00:00'
  AND created_at <  '2026-09-01 00:00:00'
```

前者要求 MySQL 先计算 `DATE_FORMAT(created_at, ...)` 才知道是否匹配；B+Tree 只保存原始 `created_at` 值，不能直接跳到“格式化结果等于 2026-08”的位置。后者给出了明确的原始值区间，优化器可以从下界开始扫描，到上界停止。

### 左闭右开范围

时间范围推荐使用 `>= 开始` 与 `< 下一边界`：

```sql
WHERE created_at >= '2026-08-01 00:00:00'
  AND created_at <  '2026-09-01 00:00:00'
```

不要写成当天的 `23:59:59`。`DATETIME`、`TIMESTAMP` 可能包含更高精度的小数秒，右开边界不会漏掉 `2026-08-31 23:59:59.999999` 这样的记录。

## ⚠️ 四类常见失效写法

| 问题 | 非 SARGable 写法 | 可索引改写 |
|---|---|---|
| 时间函数 | `DATE(created_at) = '2026-08-01'` | `created_at >= '2026-08-01' AND created_at < '2026-08-02'` |
| 算术表达式 | `price * 100 > 5000` | `price > 50` |
| 隐式转换 | `phone = 13800000000`（列为 `VARCHAR`） | `phone = '13800000000'` |
| 前导模糊匹配 | `name LIKE '%耳机'` | `name LIKE '蓝牙%'`，或改用全文检索 |

“可索引改写”不等于绝对走索引。数据量太小、过滤比例过高、统计信息过期时，优化器仍可能认为全表扫描更便宜；此时需要读 `EXPLAIN`，而不是猜测。

## 🔍 用 EXPLAIN 验证

```sql
EXPLAIN
SELECT id, created_at
FROM orders
WHERE created_at >= '2026-08-01 00:00:00'
  AND created_at <  '2026-09-01 00:00:00';
```

本例的目标信号：

- `type` 为 `range`：只扫描时间范围对应的索引记录。
- `key` 为 `idx_orders_created_at`：实际选中了时间索引。
- `Extra` 包含 `Using index`：`id` 是二级索引隐式保存的主键，`created_at` 是索引列，不需要回表。

## 🛒 订单系统实战

月度运营报表需要拉取 2026 年 8 月订单的创建时间。若页面只展示订单 ID 和创建时间，`idx_orders_created_at` 可以同时完成范围过滤与覆盖读取：

```sql
EXPLAIN
SELECT id, created_at
FROM orders
WHERE created_at >= '2026-08-01 00:00:00'
  AND created_at <  '2026-09-01 00:00:00';
```

如果接口额外需要 `total_amount`，时间索引不再覆盖，会发生回表。是否将金额加入索引，应结合查询频率、命中行数与写入成本判断，不能因为看到一次回表就盲目扩宽索引。

## 🧠 主动回忆

1. 为什么函数包裹索引列会破坏 B+Tree 的搜索边界？
2. 为什么时间范围要使用左闭右开，而不是写 `23:59:59`？
3. `range` 比 `ALL` 好，是否意味着它一定足够快？为什么？

## ✅ 项目练习

前往 [04.02.00-sargable-index-invalid](../../exercises/04.02.00-sargable-index-invalid/) 将月度函数过滤改写为时间范围，并用 `EXPLAIN` 验证计划。

```bash
bash test.sh
```

通过后发送 `/db.check mysql 04.02.00` 登记进度。
