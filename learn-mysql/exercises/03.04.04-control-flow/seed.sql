-- 插入 NULL、正常昵称和空白昵称三类数据，覆盖控制流边界。
INSERT INTO users (
    id,
    username,
    email,
    password_hash,
    status,
    nickname,
    score_text
) VALUES
    (1, 'alice', 'alice@example.com', 'pwd_alice', 1, NULL, '88'),
    (2, 'bob', 'bob@example.com', 'pwd_bob', 0, 'Bobby', '59'),
    (3, 'carol', 'carol@example.com', 'pwd_carol', 1, '   ', '72');
