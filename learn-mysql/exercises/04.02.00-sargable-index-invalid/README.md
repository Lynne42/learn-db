# 练习：SARGable 条件与索引失效

## 业务背景

运营需要查询 2026 年 8 月创建的订单。`orders.created_at` 已有单列索引 `idx_orders_created_at`，但如果使用 `DATE_FORMAT(created_at, '%Y-%m')` 过滤，会破坏索引的有序搜索边界。本题将其改写为可直接使用索引的时间范围。

## 涉及的数据表

### `orders`

| 字段 | 类型 | 可空 | Key / 约束 | 业务含义 |
|---|---|---|---|---|
| `id` | `BIGINT` | 否 | Primary Key / Auto Increment | 订单 ID |
| `order_no` | `VARCHAR(32)` | 否 | Unique Key | 订单编号 |
| `user_id` | `INT` | 否 | Foreign Key | 下单用户 ID |
| `total_amount` | `DECIMAL(10,2)` | 否 | 无 | 订单总金额 |
| `status` | `ENUM` | 否 | 复合索引前缀 | 订单状态 |
| `created_at` | `TIMESTAMP` | 否 | 单列索引 `idx_orders_created_at` | 创建时间 |

本题只使用 `idx_orders_created_at(created_at)`。二级索引叶子节点还隐式保存主键 `id`，因此仅返回 `id`、`created_at` 时可形成覆盖索引。

## 测试数据说明

测试器会在独立数据库写入 7 月、8 月、9 月的订单。只有 8 月的两条订单应落入目标时间范围，用于验证查询没有跨月误匹配。

## 任务要求

在 `exercise.sql` 中写一条标准 `EXPLAIN` 查询，返回 2026 年 8 月订单的 `id` 与 `created_at`：

```sql
EXPLAIN
SELECT id, created_at
FROM orders
WHERE created_at >= '2026-08-01 00:00:00'
  AND created_at <  '2026-09-01 00:00:00';
```

不要使用 `DATE`、`DATE_FORMAT`、`YEAR`、`MONTH`、`FORCE INDEX` 或 `EXPLAIN ANALYZE`，也不要修改表结构、数据和索引。

## 如何验证

```bash
bash test.sh
```

如果输出“✅ 测试通过！”，发送 `/db.check mysql 04.02.00` 登记进度。
