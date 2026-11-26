# 模块 03.01: SQL 基础与语言分类

> **模块定位**：学习 SQL 时，很多人容易迷失在零散的语法中。在关系型数据库中，SQL 并不是一整块单一的语言，而是由多种职责明确、行为截然不同的“子语言”组成的有机体。理解这些子语言的分类，是写出正确、高效 SQL 语句的基础。在写下任何一行 SQL 之前，作为架构师和高级开发，必须先明确它在生命周期中的职责与对数据或事务带来的副作用（如隐式提交）。本模块将带你系统建立起 SQL 语言分类的心智模型。

## 🎯 知识边界与生态位

**本模块覆盖**：
- SQL 子语言的五大理论分类：DDL、DML、DQL、DCL 和 TCL 的定义与作用边界。
- DDL (数据定义语言) 的完整操作对象：库、表、索引、视图、存储程序、触发器、事件调度等，及其"隐式提交"的底层副作用和 Atomic DDL 特性。
- DML (数据操作语言) 的完整操作集：INSERT 及其变体、UPDATE、DELETE、REPLACE、LOAD DATA、CALL、DO、集合操作（UNION/INTERSECT/EXCEPT）与 CTE。
- DQL (数据查询语言) 的完整能力：SELECT 及其子句、导出查询、子查询、锁定读取。
- DCL (数据控制语言) 的完整账户管理：GRANT/REVOKE 权限管理、用户管理、角色管理、密码管理。
- TCL (事务控制语言) 的完整控制能力：事务控制、保存点、事务特性设置、表级锁、实例级锁和 XA 分布式事务。
- 区分 DDL 中的 TRUNCATE 与 DML 中的 DELETE 在事务及性能上的物理差异。

**本模块不覆盖**：
- DDL 在高并发海量表下的 Online DDL 物理锁表原理（详见【模块 06.02】）。
- DCL 复杂的权限细粒度管理与安全审计策略（详见【模块 05.03】）。
- TCL 事务隔离级别下的具体 MVCC 实现细节（详见【模块 04.03】）。

## 📚 本模块结构

| 小节 | 文件 | 状态 | 核心说明 |
|------|------|------|----------|
| 03.01.00. 基础语法与结构 | [00-syntax.md](./00-syntax.md) | ✅已通关 | 掌握标识符、注释、字面量、表达式、运算符优先级和变量基础。 |
| 03.01.01. SQL 子语言分类全景 | [01-sql-categories.md](./01-sql-categories.md) | 📝已生成 | 系统掌握 DDL/DML/DQL/DCL/TCL 的定义与行为边界，厘清 TRUNCATE 与 DELETE 的物理差异。 |

## 🗺️ 完整知识地图 (Knowledge Map)

> 从架构师的视角，重新梳理本章知识点的因果关系。

| 核心知识点 | 本质/语法 | 架构师视角 (Why & When) | 学习位置 |
|------------|-----------|-------------------------|----------|
| **DDL (数据定义)** | 库：`CREATE/ALTER/DROP DATABASE`；<br/>表：`CREATE/ALTER/DROP/RENAME/TRUNCATE TABLE`；<br/>索引：`CREATE/DROP INDEX`；<br/>视图：`CREATE/ALTER/DROP VIEW`；<br/>存储程序：`CREATE/ALTER/DROP PROCEDURE/FUNCTION`；<br/>触发器：`CREATE/DROP TRIGGER`；<br/>事件：`CREATE/ALTER/DROP EVENT` | 用来创建或改变数据库对象结构。在 MySQL 中，大部分 DDL 执行时都会触发**隐式提交**（Implicit Commit），无法在事务中被回滚。MySQL 8.0+ 支持 Atomic DDL，保证 DDL 操作的原子性。 | 03.01.01 |
| **DML (数据操作)** | 核心：`INSERT`、`UPDATE`、`DELETE`、`REPLACE`；<br/>变体：`INSERT ... SELECT`、`ON DUPLICATE KEY UPDATE`、`INSERT IGNORE`；<br/>导入：`LOAD DATA`、`LOAD XML`；<br/>调用：`CALL`、`DO`；<br/>集合：`UNION`、`INTERSECT`、`EXCEPT`；<br/>其他：`TABLE`、`VALUES`、`WITH (CTE)` | 用来操作表内的行数据。DML 可以在事务中进行，并支持通过 ROLLBACK 进行撤销。 | 03.01.01 |
| **DQL (数据查询)** | `SELECT` 及子句（`WHERE`、`GROUP BY`、`HAVING`、`ORDER BY`、`LIMIT`、`WINDOW`）；<br/>导出：`SELECT ... INTO OUTFILE/DUMPFILE/@var`；<br/>子查询：`EXISTS`、`IN`、`ANY/SOME/ALL`；<br/>锁定读取：`FOR UPDATE`、`FOR SHARE` | 专门的数据检索，通常不修改任何物理数据，只提供一致性读取。MySQL 官方将其归入 DML，但在工程上它的优化复杂度最高。 | 03.01.01 |
| **TCL (事务控制)** | 事务：`START TRANSACTION (BEGIN)`、`COMMIT`、`ROLLBACK`；<br/>保存点：`SAVEPOINT`、`ROLLBACK TO SAVEPOINT`、`RELEASE SAVEPOINT`；<br/>特性：`SET TRANSACTION`；<br/>表级锁：`LOCK/UNLOCK TABLES`；<br/>实例锁：`LOCK/UNLOCK INSTANCE`；<br/>分布式：`XA START/END/PREPARE/COMMIT/ROLLBACK/RECOVER` | 用于维护 ACID 特性中的原子性与一致性，显式决定多步骤的 DML 变更是物理落盘生效还是整批撤销。还包括显式锁管理和分布式事务协调。 | 03.01.01 |
| **DCL (数据控制)** | 权限：`GRANT`、`REVOKE`；<br/>用户：`CREATE/ALTER/DROP/RENAME USER`；<br/>角色：`CREATE/DROP ROLE`、`SET DEFAULT ROLE`、`SET ROLE`；<br/>密码：`SET PASSWORD` | 管理数据库的安全防线。控制哪些用户和连接能访问哪些库表，MySQL 8.0+ 引入角色机制简化权限管理，在初始化和生产运维阶段使用。 | 03.01.01 |


### DDL (数据定义)

按照操作语句：
1. CREATE  → DATABASE / TABLE / INDEX / VIEW / PROCEDURE / FUNCTION / TRIGGER / EVENT
2. ALTER   → DATABASE / TABLE / VIEW / PROCEDURE / FUNCTION / EVENT
3. DROP    → DATABASE / TABLE / INDEX / VIEW / PROCEDURE / FUNCTION / TRIGGER / EVENT
4. RENAME  → TABLE
5. TRUNCATE→ TABLE

---

按照操作对象分类：

#### 库操作
* **`CREATE DATABASE IF NOT EXISTS`**：创建数据库，指定字符集和排序规则。
* **`ALTER DATABASE`**：修改数据库的字符集、排序规则等属性。
* **`DROP DATABASE`**：删除整个数据库及其包含的所有对象和物理数据，不可逆。

#### 表操作
* **`CREATE TABLE`**：创建表，定义列、数据类型、约束和表选项。在物理层面上，它负责分配初始的存储空间并定义元数据结构。
* **`ALTER TABLE`**：修改现有表的结构（如增加/删除字段、修改数据类型、增删约束和索引）。在高并发场景下，大部分 `ALTER` 操作会触发表级锁或引发大量 IO（如重建表），具有高风险性。
* **`DROP TABLE`**：删除整个表及其包含的所有物理数据，直接释放磁盘空间，属于不可逆的物理擦除。
* **`RENAME TABLE`**：重命名表。属于元数据层面的修改，操作耗时极短，常用于蓝绿部署或表结构平滑切换的最后一步。
* **`TRUNCATE TABLE`**：清空表内所有行数据。其底层逻辑是直接销毁原表并重建一张空表，不记录逐行的撤销日志（Undo Log），因此执行速度极快，但无法回滚。

#### 索引操作
* **`CREATE INDEX`**：在表上创建索引（普通索引、唯一索引、全文索引、空间索引）。本质上是 `ALTER TABLE ... ADD INDEX` 的快捷方式。
* **`DROP INDEX`**：删除表上的索引。本质上是 `ALTER TABLE ... DROP INDEX` 的快捷方式。

#### 视图操作
* **`CREATE VIEW`**：基于 SELECT 查询定义虚拟表。视图本身不存储数据，每次查询时动态执行底层 SQL。
* **`ALTER VIEW`**：修改已有视图的定义。
* **`DROP VIEW`**：删除视图定义。

#### 存储程序
* **`CREATE PROCEDURE / CREATE FUNCTION`**：创建存储过程或存储函数。存储过程通过 `CALL` 调用，存储函数可在 SQL 表达式中使用。
* **`ALTER PROCEDURE / ALTER FUNCTION`**：修改存储程序的特性（如 SQL 安全性、注释），不修改逻辑本身。
* **`DROP PROCEDURE / DROP FUNCTION`**：删除存储过程或存储函数。

#### 触发器
* **`CREATE TRIGGER`**：在表上创建触发器，绑定 BEFORE/AFTER 的 INSERT/UPDATE/DELETE 事件，自动执行特定逻辑。
* **`DROP TRIGGER`**：删除触发器。

#### 事件调度
* **`CREATE EVENT`**：创建定时事件，由 MySQL 事件调度器（Event Scheduler）按计划执行指定的 SQL。
* **`ALTER EVENT`**：修改已有事件的调度计划、状态或执行体。
* **`DROP EVENT`**：删除定时事件。

#### 其他对象
* **`CREATE/ALTER/DROP TABLESPACE`**：管理 InnoDB 表空间。
* **`CREATE/DROP SERVER`**：管理联合存储引擎的远程服务器定义。
* **`CREATE/DROP SPATIAL REFERENCE SYSTEM`**：管理空间参考系统定义。

#### Atomic DDL
* MySQL 8.0+ 引入 **Atomic DDL**（原子数据定义）：DDL 操作要么完全成功，要么完全失败回滚到操作前状态，避免了 DDL 执行中断导致的元数据不一致问题。

### DML (数据操作)

#### 增删改核心
* **`INSERT`**：向表中插入新行。写入时会触发聚簇索引的页分裂（Page Split）以及二级索引的维护，直接影响磁盘 IO 写入模式。
* **`UPDATE`**：修改表中已存在的行数据。采用原地更新（In-place）或先删后插（Delete-and-Insert）策略，具体取决于是否修改了主键或变长字段。
* **`DELETE`**：删除表中的特定行。在 InnoDB 中，它并非立即物理删除物理数据，而是将行标记为"已删除"（Delete-mark），由后台 Purge 线程异步清理，因此不会立即释放磁盘空间。
* **`REPLACE`**：根据主键或唯一索引判断，若记录不存在则直接插入；若存在，则**先删除旧记录，再插入新记录**。会带来双倍的 IO 开销并递增自增 ID。

#### INSERT 变体
* **`INSERT ... VALUES`**：标准的单行或批量多行插入语法。
* **`INSERT ... SELECT`**：将查询结果集直接插入目标表，常用于数据迁移和归档。
* **`INSERT ... ON DUPLICATE KEY UPDATE`**：Upsert 语义——当主键或唯一键冲突时执行 UPDATE 而非报错，实现"有则更新，无则插入"。
* **`INSERT IGNORE`**：忽略主键/唯一键冲突等错误，静默跳过冲突行。代价是可能掩盖真正的数据问题。

#### 批量导入
* **`LOAD DATA`**：将外部文本文件（如 CSV）高速批量导入数据库。跳过了大量的 SQL 解析层开销，直接在引擎层进行数据的批量构建与页写入。
* **`LOAD XML`**：将 XML 格式文件导入表中，语法类似 `LOAD DATA`。
* **`IMPORT TABLE`**：导入由 `SELECT ... INTO OUTFILE` 等方式导出的表数据文件。

#### 存储过程调用与执行
* **`CALL`**：调用已创建的存储过程。存储过程可以封装复杂的业务逻辑，支持事务控制和条件分支。
* **`DO`**：执行表达式但不返回结果集，通常用于调用有副作用的函数（如 `DO SLEEP(1)`）。

#### 集合操作
* **`UNION`**：合并多个 SELECT 结果集并去重（`UNION ALL` 保留重复行）。
* **`INTERSECT`**：返回多个 SELECT 结果集的交集（MySQL 8.0.31+ 支持）。
* **`EXCEPT`**：返回第一个 SELECT 结果集中有但后续结果集中没有的行（MySQL 8.0.31+ 支持）。

#### 其他 DML
* **`TABLE`**：简化语法，等价于 `SELECT * FROM table_name`，无法添加 WHERE 等子句。
* **`VALUES`**：构造行/表值表达式，可独立使用或与 `INSERT` 配合。
* **`WITH (CTE)`**：公用表表达式，定义临时结果集在 SELECT/INSERT/UPDATE/DELETE 中引用，支持递归查询。

### DQL (数据查询)

#### 核心查询
* **`SELECT`**：从数据库中检索数据。在事务段内，它通过 MVCC（多版本并发控制）读取快照数据，实现无锁的一致性读（Consistent Read）；但在高并发下，错误的索引导致的全表扫描会引发内存（Buffer Pool）污染和 CPU 暴涨。
* **核心子句**：`WHERE`（过滤）、`GROUP BY`（分组）、`HAVING`（分组后过滤）、`ORDER BY`（排序）、`LIMIT`（分页）、`WINDOW`（窗口函数）。

#### 导出查询
* **`SELECT ... INTO OUTFILE`**：将查询结果导出为服务器端文件（如 CSV），受 `secure_file_priv` 限制。
* **`SELECT ... INTO DUMPFILE`**：将单行二进制数据导出为文件，常用于导出 BLOB 内容。
* **`SELECT ... INTO @var`**：将查询结果存入用户变量，用于后续 SQL 中引用。

#### 子查询
* **标量子查询**：返回单一值，可用在 SELECT 列表、WHERE 条件等位置。
* **`EXISTS / NOT EXISTS`**：判断子查询是否返回行，常用于关联子查询的存在性检查。
* **`IN / NOT IN`**：判断值是否在子查询结果集中。注意 `NOT IN` 遇到 NULL 的反直觉行为。
* **`ANY / SOME / ALL`**：与比较运算符配合，对子查询结果集进行量化比较。

#### 锁定读取
* **`SELECT ... FOR UPDATE`**：对查询命中的行加排他锁（X Lock），阻止其他事务修改这些行，直到当前事务结束。
* **`SELECT ... FOR SHARE`**（MySQL 8.0+，替代 `LOCK IN SHARE MODE`）：对查询命中的行加共享锁（S Lock），允许其他事务读取但阻止修改。

### TCL (事务控制)

#### 事务控制
* **`START TRANSACTION` / `BEGIN`**：显式开启一个事务。通知数据库接下来的 DML 操作进入暂存状态，分配事务 ID（TxID），并开始生成 Undo Log 以支持原子性。
* **`COMMIT`**：提交事务。将当前事务的所有数据变更进行物理持久化，触发 Redo Log 刷盘（WAL 机制），并向其他事务释放当前持有的锁。
* **`ROLLBACK`**：回滚事务。利用 Undo Log 中的逆向操作（如利用 `DELETE` 撤销 `INSERT`），将数据完全恢复到事务开始前的状态，清除临时变更。

#### 保存点
* **`SAVEPOINT`**：在事务内部设置一个保存点（逻辑快照）。允许在复杂业务流程中进行局部控制。
* **`ROLLBACK TO SAVEPOINT`**：将数据状态回滚到指定的保存点，回滚该点之后的所有变更，而保留该点之前的操作，不结束当前事务。
* **`RELEASE SAVEPOINT`**：删除指定的保存点。仅释放快照定义，不引发任何数据的提交或回滚。

#### 事务特性
* **`SET TRANSACTION`**：设置事务的隔离级别（`READ UNCOMMITTED`、`READ COMMITTED`、`REPEATABLE READ`、`SERIALIZABLE`）和访问模式（`READ ONLY`、`READ WRITE`）。可作用于下一个事务或全局/会话级别。

#### 表级锁
* **`LOCK TABLES`**：显式对一个或多个表加读锁（`READ`）或写锁（`WRITE`）。在 InnoDB 行级锁机制下极少使用，主要用于 MyISAM 或特殊的一致性快照场景。
* **`UNLOCK TABLES`**：释放当前会话持有的所有表级锁。

#### 实例级锁
* **`LOCK INSTANCE FOR BACKUP`**：获取实例级备份锁，阻止可能导致快照不一致的操作（如 DDL），但允许 DML 继续执行。用于物理备份工具（如 Percona XtraBackup）。
* **`UNLOCK INSTANCE`**：释放实例级备份锁。

#### 分布式事务 (XA)
* **`XA START / XA BEGIN`**：启动一个 XA 事务分支。
* **`XA END`**：结束 XA 事务分支的工作阶段，进入空闲状态。
* **`XA PREPARE`**：对 XA 事务分支执行两阶段提交的第一阶段（Prepare），持久化事务状态。
* **`XA COMMIT`**：提交已 Prepare 的 XA 事务分支。
* **`XA ROLLBACK`**：回滚 XA 事务分支。
* **`XA RECOVER`**：列出所有处于 Prepare 状态的 XA 事务分支，用于故障恢复。

### DCL (数据控制)

#### 权限管理
* **`GRANT`**：授予特定用户或角色对特定数据库对象的访问与操作权限（如 `SELECT`, `UPDATE`）。
* **`REVOKE`**：撤销已授予用户或角色的权限，属于权限的收回操作。

#### 用户管理
* **`CREATE USER`**：创建新的数据库用户账号，定义认证方式（如密码、插件）。
* **`ALTER USER`**：修改现有用户的属性，通常用于修改密码、锁定账号或更改鉴权插件。
* **`DROP USER`**：删除用户账号，同时撤销该用户拥有的所有权限。
* **`RENAME USER`**：重命名已有用户账号，保留原有权限不变。

#### 角色管理
* **`CREATE ROLE`**：创建角色（MySQL 8.0+ 引入）。角色是权限的命名集合，可批量授予/回收用户权限，简化权限管理。
* **`DROP ROLE`**：删除角色。
* **`SET DEFAULT ROLE`**：设置用户登录时自动激活的默认角色。
* **`SET ROLE`**：在当前会话中激活或停用已授予的角色。

#### 密码管理
* **`SET PASSWORD`**：针对特定用户直接设置或修改其登录密码。


## ⚡ 速查与避坑指南 (Cheat Sheet)

> 快速查阅本章最常用的命令、最佳实践或最容易踩坑的设定。

| 场景/操作 | 最佳实践 / 核心命令 | ⚠️ 常见避坑提示 |
|-----------|--------------------|----------------|
| **清空整表数据** | 区分 `TRUNCATE TABLE` (DDL) 与 `DELETE FROM` (DML) | `TRUNCATE` 会直接重建表，速度极快且不产生大量 undo log，但它是一个 DDL 操作，**一旦执行绝对无法通过事务回滚**。若需要支持事务撤销，必须使用 `DELETE`。 |
| **事务中执行 DDL 踩坑**| 避免在 `START TRANSACTION` 后编写 `CREATE` / `ALTER` | 执行 DDL 语句会使 MySQL 自动提交当前未完成的事务。如果在 DML 执行途中穿插了 DDL，之前的 DML 会直接被强制落盘，无法整体回滚。 |
| **快速判断语句分类** | 查看命令作用的对象是“表结构”还是“表数据” | 凡是修改元数据（Meta Data）及结构的都是 DDL；凡是修改表内行数据的都是 DML。 |
