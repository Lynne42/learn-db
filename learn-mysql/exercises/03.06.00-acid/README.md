# 练习：ACID 与事务控制

## 业务背景

用户购买 2 件商品。库存扣减、订单创建和订单明细写入必须在同一个事务中提交，避免任一步骤单独成功。

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

### `order_items`

| 字段 | 类型 | 可空 | Key / 约束 | 业务含义 |
|---|---|---|---|---|
| `id` | `BIGINT` | 否 | Primary Key | 明细 ID |
| `order_id` | `BIGINT` | 否 | Foreign Key | 所属订单 ID |
| `product_id` | `INT` | 否 | Foreign Key | 商品 ID |
| `quantity` | `INT` | 否 | 无 | 购买数量 |
| `unit_price` | `DECIMAL(10,2)` | 否 | 无 | 下单单价 |

**表关系：** `orders.user_id → users.id`；`order_items.order_id → orders.id`；`order_items.product_id → products.id`。

## 测试数据说明

测试器会创建 1 个用户和 1 个商品。商品 ID 为 `1`、初始库存为 `10`、单价为 `100.00`。订单与明细初始为空，用于验证一次购买 2 件商品后的三表一致性。

## 任务要求

在 `exercise.sql` 中按顺序完成：

1. 使用 `START TRANSACTION` 开启显式事务。
2. 将 `products.id = 1` 的库存扣减 `2`，并在 `WHERE` 中保证 `stock >= 2`。
3. 创建订单：`id = 100`、`order_no = 'ORD-TX-001'`、`user_id = 1`、`total_amount = 200.00`、`status = 'PENDING'`。
4. 创建订单明细：`id = 100`、`order_id = 100`、`product_id = 1`、`quantity = 2`、`unit_price = 100.00`。
5. 使用 `COMMIT` 提交事务。

不要执行 DDL，不要关闭外键检查，不要删除 seed 数据。

## 如何验证

```bash
bash test.sh
```

如果输出“✅ 测试通过！”，发送 `/db.check mysql 03.06.00` 登记进度。

