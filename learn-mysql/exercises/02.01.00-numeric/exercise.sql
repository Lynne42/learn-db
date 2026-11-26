-- TODO: 请在下方编写你的 CREATE TABLE 语句
-- 创建名为 temp_order_discounts 的表，字段及约束定义需与 README.md 中的契约一致
CREATE TABLE temp_order_discounts (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    product_id INT UNSIGNED NOT NULL,
    discount_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    is_coupon_applied TINYINT(1) NOT NULL DEFAULT 0

)
