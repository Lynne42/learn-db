-- TODO: 查询所有分类及其直接父分类。
-- 必须将 categories 分别命名为 child 和 parent，并使用 LEFT JOIN。
-- 返回列依次为：category_id、category_name、parent_name。
-- 按 child.id 升序排序。
SELECT child.id AS category_id, child.name AS category_name, parent.name AS parent_name
FROM categories AS child
LEFT JOIN categories AS parent ON parent.id = child.parent_id
ORDER BY child.id ASC;