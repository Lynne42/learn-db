-- Schema Version: 9
-- Description: 将订单明细的商品单列索引升级为复合覆盖索引
-- Lesson: 04.01.01

CREATE INDEX idx_order_items_product_order_quantity
    ON order_items (product_id, order_id, quantity);

DROP INDEX idx_order_items_product_id ON order_items;
