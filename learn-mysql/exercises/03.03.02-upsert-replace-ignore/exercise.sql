-- TODO: 请在下方编写你的 SQL 语句
-- 任务：向 payment_callbacks 表写入数据
INSERT INTO payment_callbacks (payment_no, amount) 
VALUES ('pay_202607090001', 99.00) 
AS pay_call
ON DUPLICATE KEY UPDATE 
    callback_count = payment_callbacks.callback_count + 1,
    amount = pay_call.amount;
-- 字段：payment_no='pay_202607090001', amount=99.00
-- 冲突规则：若冲突，则 callback_count 加 1，amount 更新为 99.00

