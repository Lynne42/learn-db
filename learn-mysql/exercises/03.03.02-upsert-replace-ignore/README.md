# 练习：Upsert 与冲突写入

## 业务背景

在高并发的电商环境中，支付服务可能会在极短时间内多次接收到第三方网关推送的同一条支付单的回调通知。
为了避免网络重试导致的数据冗余或数据覆盖错误，我们需要设计一条幂等的写入 SQL 语句。如果记录首次进入，则正常写入；如果交易号已存在，则自动递增该记录的回调次数。

## 任务要求

本节练习我们需要使用到 `payment_callbacks` 表。表结构定义已预置在 `test.sh` 环境重置脚本中，定义如下：
```sql
CREATE TABLE payment_callbacks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    payment_no VARCHAR(64) NOT NULL UNIQUE,
    amount DECIMAL(10,2) NOT NULL,
    callback_count INT DEFAULT 1,
    last_callback_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

请在 `exercise.sql` 中编写 SQL 语句，完成以下任务：

1. 使用 `ON DUPLICATE KEY UPDATE` 语法向 `payment_callbacks` 表写入一条数据。
2. 写入的内容为：`payment_no` 为 `'pay_202607090001'`，金额 `amount` 为 `99.00`。
3. 如果写入发生唯一约束冲突（即 `'pay_202607090001'` 已经存在），则不报错，而是将已存在行的 `callback_count` 字段加 `1`，同时将该行的 `amount` 字段更新为新传入的 `99.00`。

> 💡 **提示**：MySQL 8.0 推荐使用别名语法 `INSERT INTO ... VALUES (...) AS alias ON DUPLICATE KEY UPDATE ...`。

## 如何验证

请在终端进入本目录，然后执行：
```bash
bash test.sh
```
如果输出 "✅ 测试通过！"，则说明你已成功完成。可以接着向 Agent 发送 `/db.check` 来登记进度。
