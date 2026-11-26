# 练习：复合索引与覆盖索引

## 业务背景

商品运营需要查询某个商品出现在哪些订单明细中，并按订单 ID 顺序读取购买数量。当前只有 `product_id` 单列索引，查询仍需回表取得 `quantity`。你需要把它升级为能够同时支持过滤、排序和返回列的复合覆盖索引，并移除被替代的旧索引。

## 涉及的数据表

### `order_items`

| 字段 | 类型 | 可空 | Key / 约束 | 业务含义 |
|---|---|---|---|---|
| `id` | `BIGINT` | 否 | Primary Key / Auto Increment | 订单明细 ID |
| `order_id` | `BIGINT` | 否 | Foreign Key | 所属订单 ID |
| `product_id` | `INT` | 否 | Foreign Key / 现有单列索引 `idx_order_items_product_id` | 商品 ID |
| `quantity` | `INT` | 否 | 无 | 购买数量 |

**表关系：** `order_items.order_id → orders.id`；`order_items.product_id → products.id`。本题只修改 `order_items` 的索引，不修改外键。

## 测试数据说明

测试器会从空库应用当前 Schema，准备多个用户、商品、订单和订单明细。同一商品会出现在多笔订单中，另有其他商品作为干扰数据，用于验证按 `product_id` 过滤、按 `order_id` 排序以及只读取 `order_id`、`quantity` 时的覆盖能力。

## 任务要求

在 `exercise.sql` 中完成：

1. 创建复合索引 `idx_order_items_product_order_quantity`，列顺序必须依次为：
   - `product_id`
   - `order_id`
   - `quantity`
2. 新复合索引创建成功后，再删除旧单列索引 `idx_order_items_product_id`。旧索引支撑 `product_id` 外键，顺序反过来会触发 MySQL `ERROR 1553`。
3. 不要修改表字段、数据、主键或外键，也不要创建其他索引。

目标查询形态如下，仅用于解释索引契约，不需要把查询写入 `exercise.sql`：

```sql
SELECT order_id, quantity
FROM order_items
WHERE product_id = <PRODUCT_ID>
ORDER BY order_id;
```

## 如何验证

```bash
bash test.sh
```

如果输出“✅ 测试通过！”，发送 `/db.check mysql 04.01.01` 登记进度。
