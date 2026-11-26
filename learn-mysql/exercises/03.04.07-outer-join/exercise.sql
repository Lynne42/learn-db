-- TODO: 查询全部启用用户及其角色，无角色用户也必须保留。
-- 必须显式使用两次 LEFT JOIN ... ON。
-- 返回列依次为：user_id、username、role_name。
-- 按 user_id、role_name 升序排序。
SELECT u.id AS user_id, u.username, r.role_name
FROM users AS u
LEFT JOIN user_roles AS ur ON ur.user_id = u.id
LEFT JOIN roles AS r ON r.id = ur.role_id
WHERE u.status = 1
ORDER BY u.id ASC, r.role_name ASC;
