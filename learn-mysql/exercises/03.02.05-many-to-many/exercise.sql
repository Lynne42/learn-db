-- TODO: 请在下方编写你的 SQL 语句
-- 创建用户角色关联表 user_roles
CREATE TABLE IF NOT EXISTS user_roles (
    user_id INT NOT NULL,
    role_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_user_id
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_role_id
        FOREIGN KEY (role_id) REFERENCES roles(id)
        ON DELETE CASCADE,
    KEY idx_user_roles_role_id (role_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
