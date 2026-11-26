-- TODO: 请在下方编写你的 CREATE TABLE 语句
-- 创建名为 temp_product_specs 的表，字段及约束定义需与 README.md 中的契约一致
CREATE TABLE temp_product_specs (
    -- 在此处编写字段定义
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(100) NOT NULL,
    specs JSON NOT NULL,
    ext_attrs JSON
);
