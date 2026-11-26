-- 用途：准备统计信息与优化器选择练习的固定倾斜数据。
-- 参数：无。
-- 返回值：无；向隔离测试库写入 1000 条订单。

INSERT INTO users (id, username, email, password_hash, status, created_at) VALUES
    (421, 'statistics_user', 'statistics@example.com', 'hash-statistics', 1, '2026-08-01 00:00:00');

INSERT INTO orders (id, order_no, user_id, total_amount, status, created_at)
SELECT
    421000 + sequence_no,
    CONCAT('ORD-STAT-', LPAD(sequence_no, 4, '0')),
    421,
    100.00,
    IF(sequence_no < 10, 'PAID', 'CANCELLED'),
    TIMESTAMP('2026-08-01 00:00:00') + INTERVAL sequence_no MINUTE
FROM (
    SELECT ones.n + tens.n * 10 + hundreds.n * 100 AS sequence_no
    FROM
        (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS ones
    CROSS JOIN
        (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS tens
    CROSS JOIN
        (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS hundreds
) AS sequence_source;
