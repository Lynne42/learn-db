# 练习：EXPLAIN 入门

## 业务背景

商品运营需要查看商品 `401` 出现在哪些订单明细中，并按订单 ID 读取购买数量。上一节已建立复合索引 `idx_order_items_product_order_quantity(product_id, order_id, quantity)`；本题不再创建索引，而是用 `EXPLAIN` 证明优化器确实使用了它。

## 涉及的数据表

### `order_items`

| 字段 | 类型 | 可空 | Key / 约束 | 业务含义 |
|---|---|---|---|---|
| `id` | `BIGINT` | 否 | Primary Key / Auto Increment | 订单明细 ID |
| `order_id` | `BIGINT` | 否 | Foreign Key | 所属订单 ID |
| `product_id` | `INT` | 否 | 复合索引第 1 列 | 商品 ID |
| `quantity` | `INT` | 否 | 复合索引第 3 列 | 购买数量 |
| `unit_price` | `DECIMAL(10,2)` | 否 | 无 | 下单时商品单价 |

本题使用的索引为 `idx_order_items_product_order_quantity(product_id, order_id, quantity)`。`order_id`、`quantity` 都在索引叶子节点中，因此目标查询可以形成覆盖索引。

## 测试数据说明

测试器会建立独立数据库，并为商品 `401` 写入多条订单明细。另有商品 `402` 的干扰数据，用于验证查询按 `product_id` 过滤，而不是扫描全部订单明细。

## 任务要求

在 `exercise.sql` 中只写一条标准 `EXPLAIN` 查询：

```sql
EXPLAIN
SELECT order_id, quantity
FROM order_items
WHERE product_id = 401
ORDER BY order_id;
```

不要使用 `FORCE INDEX`、`USE INDEX` 或 `EXPLAIN ANALYZE`；本题要观察优化器自然选择的计划，也不要修改表结构或数据。

## 如何验证

```bash
bash test.sh
```

如果输出“✅ 测试通过！”，发送 `/db.check mysql 04.01.02` 登记进度。
