<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
<!-- END doctoc generated TOC please keep comment here to allow auto update -->

| 子语言分类 | 全称 | 定义 |作用对象 | 核心关键字 | 事务回滚支持 | 核心行为特征 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **DDL** | Data Definition Language<br/>(数据定义语言) | 是 SQL 中专门用来创建、修改、删除数据库物理结构对象（包括数据库、表、索引、视图、触发器等）的指令集合 |库/表/索引等**结构元数据** | `CREATE`、`ALTER`、`DROP`、`TRUNCATE`、`RENAME` | **不支持**（执行即隐式提交） | 改变结构，涉及文件元数据写入，耗时通常较高。 |
| **DML** | Data Manipulation Language<br/>(数据操作语言)| 是 SQL 中专门用来对数据库表中的数据记录进行增、删、改的指令集合 | 表中的**数据行** | `INSERT`、`UPDATE`、`DELETE`、`REPLACE`、`LOAD DATA` | **支持**（需 COMMIT 生效） | 增删改行，写入 undo/redo 日志以保障事务安全。 |
| **DQL**| Data Query Language<br/>(数据查询语言) | 从数据库中检索数据，且绝对不修改原始数据 | 表中的**数据行** | `SELECT` | 不涉及（纯只读操作） | 检索数据，支持复杂的关联、过滤与聚合计算。 |
| **TCL** | Transaction Control Language<br/>(事务控制语言) | 是 SQL 中专门用来管理数据库事务（Transaction）的指令集合 | **事务的状态** | `START TRANSACTION`、`BEGIN`、`COMMIT`、`ROLLBACK`、`SAVEPOINT`、`ROLLBACK TO SAVEPOINT`、`RELEASE SAVEPOINT` | 不涉及 | 控制多条 DML 语句的原子性提交或撤销。 |
| **DCL** | Data Control Language<br/>(数据控制语言) | | **用户与权限** | `GRANT`、`REVOKE`、`CREATE USER`、`ALTER USER`、`DROP USER`、`SET PASSWORD` | 不支持 | 管理用户连接密码、读写授权等数据库防线。 |



```text
                     ┌── 1. DDL (Data Definition Language): CREATE, ALTER, DROP, TRUNCATE  (结构/容器)
                     ├── 2. DML (Data Manipulation Language): INSERT, UPDATE, DELETE         (数据记录)
【SQL 完整语言体系】  ──├── 3. DQL (Data Query Language):        SELECT                         (查询/分析)
                     ├── 4. TCL (Transaction Control): BEGIN, COMMIT, ROLLBACK, SAVEPOINT (事务/ACID)
                     └── 5. DCL (Data Control Language): CREATE USER, GRANT, REVOKE     (权限/安全)

```


1. [DDL](./01-DDL.md)
2. [DML](./03-DML.md)
3. [DQL](./04-DQL.md)
4. [TCL](./06-TCL.md)
5. [DCL](./05-DCL.md)
