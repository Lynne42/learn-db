-- Schema Version: 8
-- Description: 为全站订单时间范围查询补充 created_at 单列索引
-- Lesson: 04.01.00

CREATE INDEX idx_orders_created_at ON orders (created_at);
