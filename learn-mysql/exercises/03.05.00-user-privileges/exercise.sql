-- TODO: 创建专用报表账户，授予 SELECT、INSERT 后再精确回收 INSERT。
-- 最终仅保留 order_system_lesson_030500.* 上的 SELECT 权限。

CREATE USER 'order_reporter_030500'@'%' IDENTIFIED BY 'Reporter030500!';
GRANT SELECT, INSERT ON order_system_lesson_030500.* TO 'order_reporter_030500'@'%';
REVOKE INSERT ON order_system_lesson_030500.* FROM 'order_reporter_030500'@'%';