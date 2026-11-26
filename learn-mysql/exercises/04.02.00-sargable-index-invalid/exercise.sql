-- TODO: 将“查询 2026 年 8 月订单”的条件写成 SARGable 时间范围。
-- 使用标准 EXPLAIN；返回 id、created_at；不要对 created_at 使用函数。
EXPLAIN
SELECT id, created_at
FROM orders
WHERE created_at >= '2026-08-01 00:00:00'
  AND created_at <  '2026-09-01 00:00:00';