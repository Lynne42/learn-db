-- TODO: 请在下方编写你的 SQL 语句
-- 任务：筛选出没有绑定手机号 (phone 为 NULL) 且用户名以 test_ 开头的用户
-- 要求：仅投影 id, username, email 字段，并按 id 升序排序
SELECT id, username, email
FROM users
WHERE (phone IS NULL) AND (username LIKE 'test\_%')
ORDER BY id ASC;