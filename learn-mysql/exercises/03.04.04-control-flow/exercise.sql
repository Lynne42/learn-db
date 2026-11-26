-- TODO: 使用控制流和显式类型转换生成客服列表。
-- 返回列：id、display_name、status_label、numeric_score、result_label。
-- 按 id 升序排列。

SELECT id, 
       COALESCE(NULLIF(TRIM(nickname), ''), username) AS 'display_name',
       CASE 
        WHEN status = 1 THEN 'ACTIVE'
        ELSE  'DISABLED'
       END AS 'status_label',
       CAST(score_text AS UNSIGNED) AS 'numeric_score',
       IF(CAST(score_text AS UNSIGNED) >= 60, 'PASS', 'FAIL') AS 'result_label'
FROM users
ORDER BY id ASC;


