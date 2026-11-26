# 练习：订单详情与用户消费统计

## 业务背景

运营需要查看指定订单的商品明细，同时按用户统计有效订单数量和消费金额。取消订单不能计入消费。

## 涉及的数据表

### `users`

| 字段 | 类型 | 可空 | Key / 约束 | 业务含义 |
|---|---|---|---|---|
| `id` | `INT` | 否 | Primary Key | 用户 ID |
| `username` | `VARCHAR(50)` | 否 | Unique | 用户名 |

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
| `order_id` | `BIGINT` | 否 | Foreign Key | 订单 ID |
| `product_id` | `INT` | 否 | Foreign Key | 商品 ID |
| `quantity` | `INT` | 否 | 无 | 商品数量 |
| `unit_price` | `DECIMAL(10,2)` | 否 | 无 | 成交单价 |

### `products`

| 字段 | 类型 | 可空 | Key / 约束 | 业务含义 |
|---|---|---|---|---|
| `id` | `INT` | 否 | Primary Key | 商品 ID |
| `name` | `VARCHAR(100)` | 否 | 无 | 商品名称 |

**表关系：** `orders.user_id → users.id`；`order_items.order_id → orders.id`；`order_items.product_id → products.id`。

## 测试数据说明

测试器会创建 2 个用户、2 个商品、3 个订单和 3 条订单明细。订单状态覆盖已支付、已发货和已取消；同一用户同时拥有有效订单和取消订单，用于验证消费口径是否正确排除取消数据。

## 任务要求

在 `exercise.sql` 中按顺序编写两个 `SELECT`：

### 查询一：指定订单商品明细

1. 查询订单号 `ORD-PROJ-002`。
2. 返回别名：`order_no`、`username`、`product_name`、`quantity`、`unit_price`、`line_amount`。
3. `line_amount` 使用 `quantity * unit_price` 计算。
4. 按订单明细 `id ASC` 排序。

### 查询二：用户有效消费统计

1. 只统计状态为 `PAID`、`SHIPPED`、`COMPLETED` 的订单。
2. 返回别名：`user_id`、`username`、`order_count`、`total_spent`。
3. 使用 `COUNT(*)` 统计有效订单数，使用 `SUM(total_amount)` 统计消费金额。
4. 按用户 ID 分组并按 `user_id ASC` 排序。

不要使用 `products.price` 计算历史成交金额，不要把 `CANCELLED` 计入消费。

## 如何验证

```bash
bash test.sh
```

如果输出“✅ 测试通过！”，发送 `/db.check mysql 03.07.01` 登记进度。

