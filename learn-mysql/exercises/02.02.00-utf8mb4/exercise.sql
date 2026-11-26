-- TODO: 请在下方编写你的 SQL 语句
-- 创建临时国际化评论表 temp_international_reviews
CREATE TABLE temp_international_reviews (
    review_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    order_no VARCHAR(50) NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    sku_code VARCHAR(50) NOT NULL COLLATE utf8mb4_bin,
    review_text TEXT NOT NULL
) DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci
