-- TODO: 请在下方编写你的 SQL 语句
-- 1. 创建角色表 roles
CREATE TABLE IF NOT EXISTS roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_roles_role_name UNIQUE (role_name)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- 2. 创建临时用户个人资料表 temp_user_profiles（包含指向 users(id) ON DELETE CASCADE 的外键）
CREATE TABLE IF NOT EXISTS temp_user_profiles(
    profile_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    real_name VARCHAR(50) NOT NULL,
    CONSTRAINT fk_profiles_users
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 标准的
-- CREATE TABLE IF NOT EXISTS temp_user_profiles (
--     profile_id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '自增主键',
--     user_id BIGINT NOT NULL COMMENT '用户ID（关联users表id，逻辑外键）',
--     real_name VARCHAR(50) NOT NULL COMMENT '真实姓名',
--     -- 建立唯一索引，既保证一个用户只有一个档案，又加速了关联查询
--     CONSTRAINT uk_user_id UNIQUE (user_id)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户档案扩展表';