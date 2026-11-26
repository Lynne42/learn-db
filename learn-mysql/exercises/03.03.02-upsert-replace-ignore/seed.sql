-- 插入一条初始回调记录，用来触发之后的唯一键冲突
INSERT INTO payment_callbacks (payment_no, amount, callback_count) VALUES 
('pay_202607090001', 50.00, 1);
