# 练习：基础 CRUD 综合验收

## 业务背景

系统需要完成一次新订单处理，同时清理一笔测试取消订单：创建新订单和明细、扣减库存、更新为已支付、删除旧取消订单，最后输出新订单摘要。

## 涉及的数据表

### `users`

| 字段 | 类型 | 可空 | Key / 约束 | 业务含义 |
|---|---|---|---|---|
| `id` | `INT` | 否 | Primary Key | 下单用户 ID |

### `products`

| 字段 | 类型 | 可空 | Key / 约束 | 业务含义 |
|---|---|---|---|---|
| `id` | `INT` | 否 | Primary Key | 商品 ID |
| `stock` | `INT` | 否 | Default `0` | 当前库存 |

### `orders`

| 字段 | 类型 | 可空 | Key / 约束 | 业务含义 |
|---|---|---|---|---|
| `id` | `BIGINT` | 否 | Primary Key | 订单 ID |
| `order_no` | `VARCHAR(32)` | 否 | Unique | 订单号 |
| `user_id` | `INT` | 否 | Foreign Key | 下单用户 ID |
| `total_amount` | `DECIMAL(10,2)` | 否 | 无 | 订单总金额 |
| `status` | `ENUM` | 否 | Default `PENDING` | 订单状态 |
| `paid_at` | `TIMESTAMP` | 是 | 无 | 支付时间 |

### `order_items`

| 字段 | 类型 | 可空 | Key / 约束 | 业务含义 |
|---|---|---|---|---|
| `id` | `BIGINT` | 否 | Primary Key | 明细 ID |
| `order_id` | `BIGINT` | 否 | Foreign Key / `ON DELETE CASCADE` | 订单 ID |
| `product_id` | `INT` | 否 | Foreign Key | 商品 ID |
| `quantity` | `INT` | 否 | 无 | 购买数量 |
| `unit_price` | `DECIMAL(10,2)` | 否 | 无 | 成交单价 |

**表关系：** `orders.user_id → users.id`；`order_items.order_id → orders.id`；`order_items.product_id → products.id`。

## 测试数据说明

测试器会从空库应用 Schema V1，然后创建 1 个用户、1 个库存为 10 的商品，以及 1 笔已取消的测试订单和对应明细。新订单和新明细初始不存在，用于验证完整 CRUD、副作用与级联删除。

## 任务要求

在 `exercise.sql` 中完成：

1. 使用 `START TRANSACTION` 开启事务。
2. 创建新订单：`id = 201`、`order_no = 'ORD-CRUD-NEW'`、`user_id = 1`、`total_amount = 150.00`、初始状态 `PENDING`。
3. 创建明细：`id = 201`、`order_id = 201`、`product_id = 1`、`quantity = 3`、`unit_price = 50.00`。
4. 对 `products.id = 1` 条件扣减库存 3，并保证 `stock >= 3`。
5. 将新订单从 `PENDING` 更新为 `PAID`，设置 `paid_at = '2026-08-05 10:00:00'`；`WHERE` 必须包含旧状态条件。
6. 删除 `id = 200` 且状态为 `CANCELLED` 的旧订单，依赖外键级联删除其明细。
7. 使用 `COMMIT` 提交。
8. 事务结束后执行一个 `SELECT`，返回别名 `order_no`、`status`、`stock`、`item_count`、`total_quantity`，按新订单聚合最终状态。

不要关闭外键检查，不要使用 DDL，不要硬编码最终查询结果。

## 如何验证

```bash
bash test.sh
```

如果输出“✅ 测试通过！”，发送 `/db.check mysql 03.07.02` 登记进度。

