-- TODO: 请在下方编写你的 CREATE TABLE 语句
-- 创建名为 temp_orders_lifecycle 的表，字段及约束定义需与 README.md 中的契约一致
CREATE TABLE temp_orders_lifecycle (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    order_no CHAR(20) NOT NULL,
    user_birthday DATE,
    order_created_at TIMESTAMP NOT NULL  DEFAULT CURRENT_TIMESTAMP,
    last_status_updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
