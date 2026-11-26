# 练习：数值类型应用实战

## 业务背景

在我们的「电商订单管理系统」中，每笔订单在结算时，系统都会根据用户使用的优惠券或促销活动，计算每个商品的折扣明细。为了精准记录每次折扣并进行后续的财务审计，我们需要创建一张名为 `temp_order_discounts` 的临时流水明细表。

## 任务要求

请在 `exercise.sql` 中编写一条 `CREATE TABLE` 语句，创建 `temp_order_discounts` 表，其字段定义必须严格符合以下设计契约：

| 字段名 | 类型与属性 | 空值限制 | 默认值 | 额外说明 |
|:---|:---|:---|:---|:---|
| **id** | `BIGINT UNSIGNED` | `NOT NULL` | - | 自增属性 (`AUTO_INCREMENT`)，且作为表的主键 (`PRIMARY KEY`) |
| **order_id** | `BIGINT UNSIGNED` | `NOT NULL` | - | 下单订单 ID |
| **product_id** | `INT UNSIGNED` | `NOT NULL` | - | 关联商品 ID |
| **discount_amount** | `DECIMAL(10, 2)` | `NOT NULL` | `0.00` | 高精度折扣金额，支持到分 |
| **is_coupon_applied** | `TINYINT(1)` 或 `BOOLEAN` | `NOT NULL` | `0` | 标识是否使用了优惠券 |

## 如何验证

请在终端进入本目录，然后执行：
```bash
bash test.sh
```

如果输出 "✅ 测试通过！"，说明建表契约完全吻合，接着可以向 Agent 发送 `/db.check` 登记进度。
