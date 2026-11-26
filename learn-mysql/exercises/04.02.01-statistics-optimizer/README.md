# 练习：统计信息与优化器选择

## 业务背景

订单表刚完成一批历史数据导入，运营需要查询少量 `PAID` 订单并按创建时间输出。表上已有复合索引 `idx_orders_status_created(status, created_at)`。本题先刷新统计信息，再用 `EXPLAIN` 验证优化器是否自然选择该索引。

## 涉及的数据表

### `orders`

| 字段 | 类型 | 可空 | Key / 约束 | 业务含义 |
|---|---|---|---|---|
| `id` | `BIGINT` | 否 | Primary Key / Auto Increment | 订单 ID |
| `order_no` | `VARCHAR(32)` | 否 | Unique Key | 订单编号 |
| `user_id` | `INT` | 否 | Foreign Key | 下单用户 ID |
| `status` | `ENUM` | 否 | 复合索引第 1 列 | 订单状态 |
| `created_at` | `TIMESTAMP` | 否 | 复合索引第 2 列 | 创建时间 |

本题使用既有索引 `idx_orders_status_created(status, created_at)`。二级索引叶子节点隐式保存主键 `id`，因此返回 `id`、`status`、`created_at` 时可以形成覆盖索引。

## 测试数据说明

测试器会在独立数据库写入 1000 条订单：10 条为 `PAID`，其余 990 条为 `CANCELLED`。固定的数据分布用于观察低占比状态条件的估算和访问路径，不代表生产环境中的状态比例。

## 任务要求

在 `exercise.sql` 中依次完成两条语句：

1. 使用 `ANALYZE TABLE orders` 刷新普通表与索引统计信息；
2. 使用标准 `EXPLAIN` 查询 `PAID` 订单的 `id`、`status`、`created_at`，并按 `created_at` 升序排列。

不要创建或删除 Histogram，不要使用 `FORCE INDEX`、`USE INDEX`、`IGNORE INDEX` 或 `EXPLAIN ANALYZE`，也不要修改表结构和业务数据。

## 如何验证

```bash
bash test.sh
```

如果输出“✅ 测试通过！”，发送 `/db.check mysql 04.02.01 你的掌握度` 登记进度。
