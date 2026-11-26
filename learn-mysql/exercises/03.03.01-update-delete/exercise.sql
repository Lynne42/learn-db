-- TODO: 请在下方编写你的 SQL 语句
SET sql_safe_updates = 1;

-- 任务 1：使用 UPDATE 将 username 为 'alice' 的用户的 status 修改为 0
UPDATE users
SET status = 0
where username = 'alice';

-- 任务 2：使用 DELETE 删除所有 status = 0 的用户
-- 提示：安全模式下，DELETE 必须指定索引列过滤（例如搭配主键 id > 0）
DELETE 
FROM users
WHERE status=0 AND id > 0;

