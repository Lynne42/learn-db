-- TODO: 请在下方编写你的 SQL 语句

-- 任务 1：向 roles 表批量插入角色 (Administrator 和 User)
INSERT INTO
    roles (role_name)
VALUES ('Administrator'),
    ('User');

-- 任务 2：向 users 表批量插入用户 (root_user 和 dev_user)
INSERT INTO
    users (
        username,
        email,
        password_hash,
        status
    )
VALUES (
        'root_user',
        'root@order.com',
        'hash_root',
        1
    ),
    (
        'dev_user',
        'dev@order.com',
        'hash_dev',
        1
    );

-- 任务 3：向 user_roles 表插入多对多绑定关联记录
INSERT INTO user_roles (user_id, role_id) VALUES (1, 1), (2, 2);