-- TODO: 先按 README.md 的列顺序创建复合覆盖索引。
-- TODO: 再删除被复合索引最左前缀替代的 product_id 单列索引。

CREATE INDEX idx_order_items_product_order_quantity ON order_items (product_id, order_id, quantity);
DROP INDEX idx_order_items_product_id ON order_items;