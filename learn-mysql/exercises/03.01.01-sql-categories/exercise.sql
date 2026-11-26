-- TODO: 请在下方编写你的 SQL 语句
-- 使用 SELECT 与 UNION ALL 输出概念匹配结果
SELECT 'DDL' AS category, 'CREATE TABLE' AS example_statement
UNION ALL
SELECT 'DML' AS category, 'INSERT INTO' AS example_statement
UNION ALL
SELECT 'DQL' AS category, 'SELECT' AS example_statement
UNION ALL
SELECT 'DCL' AS category, 'GRANT' AS example_statement
UNION ALL
SELECT 'TCL' AS category, 'COMMIT' AS example_statement
