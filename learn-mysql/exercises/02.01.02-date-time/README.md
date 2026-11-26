# 练习：日期与时间类型应用实战

## 业务背景

为了完整追踪订单的生命周期状态并进行时区对账，我们需要创建一张名为 `temp_orders_lifecycle` 的订单生命周期时间跟踪表，用于自动捕获订单的创建时间、最后一次状态更新时间，以及购买用户的生日。

## 任务要求

请在 `exercise.sql` 中编写一条 `CREATE TABLE` 语句，创建 `temp_orders_lifecycle` 表，其字段定义必须严格符合以下设计契约：

| 字段名 | 类型与属性 | 空值限制 | 默认值 | 额外说明与自动更新逻辑 |
|:---|:---|:---|:---|:---|
| **id** | `BIGINT UNSIGNED` | `NOT NULL` | - | 自增主键 (`AUTO_INCREMENT PRIMARY KEY`) |
| **order_no** | `CHAR(20)` | `NOT NULL` | - | 固定长度 20 位的业务订单号 |
| **user_birthday** | `DATE` | `YES` (允许为空) | `NULL` | 仅需要保存用户的出生年月日 |
| **order_created_at** | `TIMESTAMP` | `NOT NULL` | `CURRENT_TIMESTAMP` | 订单创建时间。由数据库在**数据行首次插入时自动填充为当前系统时间**。 |
| **last_status_updated_at** | `TIMESTAMP` | `NOT NULL` | `CURRENT_TIMESTAMP` | 订单状态修改时间。在**数据行插入时初始化为当前系统时间，且在任何后续更新（UPDATE）时自动刷新为最新的当前系统时间**。 |

## 如何验证

请在终端进入本目录，然后执行：
```bash
bash test.sh
```

如果输出 "✅ 测试通过！"，说明建表契约完全吻合，接着可以向 Agent 发送 `/db.check` 登记进度。
