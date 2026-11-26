-- TODO: 请在下方编写你的 SQL 语句
-- 任务：筛选出 status = 0 且 id 在 1 到 10 之间（闭区间）的用户
-- 要求：仅投影 id 和 username 字段，且将 username 重命名为 user_name，并按 id 升序排序
SELECT id, username AS user_name
from users
WHERE status = 0 AND id BETWEEN 1 AND 10
ORDER BY id ASC;