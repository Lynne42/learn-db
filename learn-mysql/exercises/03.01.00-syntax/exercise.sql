-- 请在这行下方编写你的 SQL 语句
-- 第一步：设置变量 @current_env 为 'production'
SET @current_env = 'production';
-- 第二步：查询变量，并将其列名命名为带空格的 App Environment
SELECT @current_env AS `App Environment`;

