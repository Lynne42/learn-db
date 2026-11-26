-- TODO: 请在下方编写你的 CREATE TABLE 语句
-- 创建名为 temp_products_preview 的表，字段及约束定义需与 README.md 中的契约一致
CREATE TABLE temp_products_preview (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    spu_no CHAR(12) NOT NULL,
    preview_title VARCHAR(150) NOT NULL,
    detail_desc TEXT DEFAULT NULL,
    product_type ENUM('PHYSICAL', 'DIGITAL', 'VIRTUAL') NOT NULL DEFAULT 'PHYSICAL'
)
