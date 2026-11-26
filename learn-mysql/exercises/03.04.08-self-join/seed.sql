-- 用途：为 03.04.08 提供分类层级测试数据。
-- 参数：无。
-- 返回值：无。
-- 约束：categories 已由 test.sh 在隔离数据库中创建。

INSERT INTO categories (id, name, parent_id) VALUES
    (1, 'Electronics', NULL),
    (2, 'Computers', 1),
    (3, 'Laptops', 2),
    (4, 'Phones', 1),
    (5, 'Home', NULL),
    (6, 'Kitchen', 5);
