-- 用途：为 03.04.06 提供用户、角色及授权关系测试数据。
-- 参数：无。
-- 返回值：无。
-- 约束：users、roles、user_roles 已由 test.sh 重建。

INSERT INTO users (id, username, email, password_hash, status) VALUES
    (1, 'alice', 'alice@example.com', 'hash-alice', 1),
    (2, 'bob', 'bob@example.com', 'hash-bob', 0),
    (3, 'carol', 'carol@example.com', 'hash-carol', 1),
    (4, 'dave', 'dave@example.com', 'hash-dave', 1);

INSERT INTO roles (id, role_name) VALUES
    (1, 'admin'),
    (2, 'customer'),
    (3, 'auditor');

INSERT INTO user_roles (user_id, role_id) VALUES
    (1, 1),
    (1, 2),
    (2, 2),
    (3, 3);
