-- TODO: 查询所有启用用户及其角色。
-- 必须显式使用两次 INNER JOIN ... ON。
-- 返回列依次为：user_id、username、role_name。
-- 按 user_id、role_name 升序排序。
SELECT u.id AS user_id, u.username, r.role_name
FROM users AS u
INNER JOIN user_roles AS ur ON ur.user_id = u.id
INNER JOIN roles AS r ON ur.role_id = r.id
WHERE u.status = 1
ORDER BY u.id ASC, r.role_name ASC;