-- TODO: 查询 INFORMATION_SCHEMA.KEY_COLUMN_USAGE，生成交易子图的外键依赖清单。
-- 必须限定当前 DATABASE()、目标表集合和 REFERENCED_TABLE_NAME IS NOT NULL。
SELECT TABLE_NAME AS table_name, 
        COLUMN_NAME AS column_name, 
        REFERENCED_TABLE_NAME AS referenced_table_name, 
        REFERENCED_COLUMN_NAME AS referenced_column_name
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME in ('categories', 'products', 'orders', 'order_items')
AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY table_name ASC, column_name ASC;