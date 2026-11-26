-- TODO: 使用标量函数生成客服列表字段。
-- 返回列：id、user_label、distance_score、registered_date、days_from_anchor。
-- 按 id 升序排列。

SELECT id, CONCAT(TRIM(username),'#',CHAR_LENGTH(TRIM(username))) AS user_label, ROUND(ABS(id - 4) / 3, 2) AS distance_score, DATE_FORMAT(created_at, '%Y-%m-%d') AS registered_date, ABS(DATEDIFF(created_at, '2026-07-01')) AS days_from_anchor
FROM users
ORDER BY id ASC;

