-- TODO: 查询未进入营销排除表的活跃用户。
-- 要求：
-- 1. 使用 NOT EXISTS，禁止使用 NOT IN。
-- 2. 仅返回 id、username。
-- 3. 按 id 升序排列。

SELECT id, username
FROM users AS a
WHERE status = 1 
AND NOT EXISTS (
    SELECT 1
    from lesson_030402_marketing_exclusions AS b
    WHERE b.user_id = a.id
)
ORDER BY id ASC;



