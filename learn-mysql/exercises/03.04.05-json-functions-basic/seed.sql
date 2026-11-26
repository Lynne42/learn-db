-- 用途：为 03.04.05 提供商品 JSON 属性测试数据。
-- 参数：无。
-- 返回值：无。
-- 约束：lesson_030405_products 已由 test.sh 创建。

INSERT INTO lesson_030405_products (id, name, attributes) VALUES
    (1, 'Mechanical Keyboard', '{"color":"black","layout":"87-key","tags":["wireless","office"]}'),
    (2, 'Gaming Mouse', '{"color":"white","dpi":26000,"tags":["wired","gaming"]}'),
    (3, 'USB-C Headset', '{"color":"black","tags":["wireless","audio"],"warranty_months":12}');
