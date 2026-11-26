-- TODO: 请在下方编写你的 SQL 语句
-- 向 categories 表批量插入三条初始商品分类记录：Electronics, Clothing, Books
INSERT INTO categories (category_name)
VALUES
('Electronics'),
('Clothing'),
('Books')
AS c
ON DUPLICATE KEY UPDATE 
    category_name = c.category_name;
