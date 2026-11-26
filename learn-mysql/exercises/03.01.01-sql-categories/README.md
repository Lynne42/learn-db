# 练习：SQL 子语言分类全景

## 业务背景

为了巩固对 SQL 子语言分类（DDL, DML, DQL, DCL, TCL）的整体直觉认知，我们将使用 SQL 语句本身来完成一次概念匹配。在以后的具体开发中，你需要时刻分清写下的语句属于哪类分支，以预估其是否受事务保护，或是否自带隐式提交的副作用。

## 任务要求

请在 `exercise.sql` 中编写一条 `SELECT` 查询语句，通过使用 `UNION ALL` 联合输出以下 5 对映射记录：

| category (分类) | example_statement (经典指令示例) |
| :--- | :--- |
| DDL | CREATE TABLE |
| DML | INSERT INTO |
| DQL | SELECT |
| DCL | GRANT |
| TCL | COMMIT |

要求输出的列名必须分别为 `category` 和 `example_statement`（大小写必须完全一致，注意别名）。

例如，你可以这样编写：
```sql
SELECT 'DDL' AS category, 'CREATE TABLE' AS example_statement
UNION ALL
...
```

## 如何验证

请在终端进入本目录，然后执行：
```bash
bash test.sh
```
如果输出 "✅ 测试通过！"，则说明你已掌握本节内容。可以接着向 Agent 发送 `/db.check` 来登记进度。
