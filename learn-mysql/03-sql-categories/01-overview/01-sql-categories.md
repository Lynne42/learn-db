# 03.01.01. SQL 子语言分类全景

> **故事线与承上启下**：
> 在前一模块中，我们统一了本地的字符编码底座，确保不论是 Emoji 表情还是大小写敏感的字段都能正常存取。接下来，在动笔建表之前，我们必须先从宏观视角认识 SQL 的“语法军团”。很多初学者把所有的 SQL 语句混为一谈，导致在事务处理中因为误用命令而造成数据损坏。本节我们就来完整拆解 SQL 的五大子语言分支：DDL、DML、DQL、DCL 与 TCL。

## ⚡ 速查摘要

- **DDL (数据定义)**：`CREATE`、`ALTER`、`DROP`、`TRUNCATE`、`RENAME`。结构级操作，**自带隐式提交，不可回滚**。
- **DML (数据操作)**：`INSERT`、`UPDATE`、`DELETE`、`REPLACE`、`LOAD DATA`。行数据级操作，**受事务保护，可回滚**。
- **DQL (数据查询)**：`SELECT`。读取数据，无副作用，为性能优化的重灾区。
- **DCL (数据控制)**：`GRANT`、`REVOKE`、`CREATE USER`、`ALTER USER`、`DROP USER`、`SET PASSWORD`。管理数据库权限和安全隔离。
- **TCL (事务控制)**：`START TRANSACTION`、`BEGIN`、`COMMIT`、`ROLLBACK`、`SAVEPOINT`、`ROLLBACK TO SAVEPOINT`、`RELEASE SAVEPOINT`。控制 DML 提交与回滚的时机。

---

## 🎯 学习目标与验收标准

**学习目标：**
- 掌握 SQL 理论分类中的五大子语言（DDL, DML, DQL, DCL, TCL）。
- 掌握 DDL 与 DML 的物理行为差异，特别理解 DDL 的“隐式提交”副作用。
- 搞清楚 `TRUNCATE` (DDL) 与 `DELETE` (DML) 的本质差异及选用时机。
- 理解理论分类与 MySQL 官方文档分类的对照映射关系。

**验收标准：**
- [ ] 能说出每个子语言分类的简称含义及代表性关键字。
- [ ] 能解释为什么在事务运行中插入一条 DDL 命令会导致之前的 DML 无法回滚。
- [ ] 能够通过在练习中用 SQL 匹配各个子语言的概念题，完成自动化脚本验证。

---

## 📖 概念全景

SQL (Structured Query Language) 是一门功能大而全的特殊声明式语言。根据它们操作的对象（是“表结构”还是“表数据”）以及操作的目的，SQL 在理论上被划分为以下五个子语言（Sublanguages）：

### 1. 五大子语言对比矩阵

| 子语言分类 | 全称 | 作用对象 | 核心关键字 | 事务回滚支持 | 核心行为特征 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **DDL** | Data Definition Language<br/>(数据定义语言) | 库/表/索引等**结构元数据** | `CREATE`、`ALTER`、`DROP`、`TRUNCATE`、`RENAME` | **不支持**（执行即隐式提交） | 改变结构，涉及文件元数据写入，耗时通常较高。 |
| **DML** | Data Manipulation Language<br/>(数据操作语言) | 表中的**数据行** | `INSERT`、`UPDATE`、`DELETE`、`REPLACE`、`LOAD DATA` | **支持**（需 COMMIT 生效） | 增删改行，写入 undo/redo 日志以保障事务安全。 |
| **DQL**| Data Query Language<br/>(数据查询语言) | 表中的**数据行** | `SELECT` | 不涉及（纯只读操作） | 检索数据，支持复杂的关联、过滤与聚合计算。 |
| **TCL** | Transaction Control Language<br/>(事务控制语言) | **事务的状态** | `START TRANSACTION`、`BEGIN`、`COMMIT`、`ROLLBACK`、`SAVEPOINT`、`ROLLBACK TO SAVEPOINT`、`RELEASE SAVEPOINT` | 不涉及 | 控制多条 DML 语句的原子性提交或撤销。 |
| **DCL** | Data Control Language<br/>(数据控制语言) | **用户与权限** | `GRANT`、`REVOKE`、`CREATE USER`、`ALTER USER`、`DROP USER`、`SET PASSWORD` | 不支持 | 管理用户连接密码、读写授权等数据库防线。 |

### 2. DDL 的隐式提交（Implicit Commit）

在 MySQL 中，大部分 DDL 语句在执行前和执行后都会**自动触发一次提交操作**，这在数据库底层被称为“隐式提交”。
这就解释了为什么下面的事务无法回滚：

```sql
START TRANSACTION;
INSERT INTO users (username) VALUES ('test_user'); -- DML，已写入
ALTER TABLE users ADD age INT;                      -- DDL，触发隐式提交！
ROLLBACK;                                           -- 事务其实已被强制提交，回滚无效！
```

> [!WARNING]
> 绝对不要在写业务核心 DML 事务的过程中穿插 DDL 语句。DDL 会截断你之前的事务保护，直接强制持久化之前的变更。

### 3. TRUNCATE 与 DELETE 物理本质差异

很多新手认为 `TRUNCATE TABLE foo;` 就是 `DELETE FROM foo;` 的简写。其实不然，它们的物理执行方式完全不同：
- **`DELETE` (DML)**：MySQL 必须**一行一行**读取记录，为其在 Undo Log 写入历史版本数据（以便可以回滚），然后将其标记为删除。如果表有一百万行，就会产生大量 IO 和日志。
- **`TRUNCATE` (DDL)**：MySQL 直接跳过行记录，采用“快刀斩乱麻”的方式，在物理上直接**删除表并重新创建一个空表**。执行速度极快，不记行级 Undo 日志，因此**绝不可被回滚**。

---

## 💻 SQL 语法

在日常开发和运维中，不同子语言的核心指令举例如下：

```sql
-- DDL：定义结构
CREATE TABLE temp_log (id INT, info TEXT);
ALTER TABLE temp_log ADD created_at TIMESTAMP;
DROP TABLE temp_log;

-- DML：数据写入/变更
INSERT INTO temp_log (id, info) VALUES (1, 'System Boot');
UPDATE temp_log SET info = 'System Restart' WHERE id = 1;
DELETE FROM temp_log WHERE id = 1;

-- DQL：数据检索
SELECT id, info FROM temp_log WHERE created_at IS NOT NULL;

-- TCL：事务边界控制
START TRANSACTION;  -- 开始事务
-- ... 几条 DML ...
COMMIT;            -- 确认落盘
-- 或
ROLLBACK;          -- 撤销回滚

-- DCL：权限管理
GRANT SELECT, INSERT ON order_system.* TO 'developer'@'%';
REVOKE INSERT ON order_system.* FROM 'developer'@'%';
```

---

## 🛒 订单系统实战

**业务场景：**
在我们的「电商订单管理系统」的完整开发及运维生命周期中，五个子语言扮演着完全不同的“兵种”：

1. **开发阶段（DDL）**：我们需要设计表结构，创建 `users`、`orders` 等表。
2. **交易结算（DML + TCL）**：用户支付时，需要在一笔事务（`START TRANSACTION`）中同时扣减库存（`UPDATE`）并生成支付单（`INSERT`）。如果有一步失败，则由事务管理器回滚（`ROLLBACK`）；如果全部成功，则提交（`COMMIT`）。
3. **报表分析（DQL）**：运营人员需要查询当天的总销售额报表（`SELECT`）。
4. **安全隔离（DCL）**：DBA 在生产环境只给前台服务授权增删改查权限，不赋予 DROP 表和删除库的超级权限（`GRANT`），实现最小特权安全底线。

---

## ⚠️ 常见坑点

- 💣 **坑点 1：大表执行 DELETE 导致数据库卡死**
  - **现象**：执行 `DELETE FROM massive_logs;` 清理几个月前的旧数据，发现连接被占满，数据库 CPU 飙升。
  - **对策**：因为 DELETE 是 DML，需要逐行记录并写入日志以支持事务，对大表清理应该使用 `TRUNCATE`（DDL）直接重建表，或者按时间段进行分批删除（Batching）。
- 💣 **坑点 2：在事务里写 DDL 导致的回滚失效**
  - **现象**：在事务里新增了商品，然后为了演示临时加了个测试字段 `ALTER TABLE`，最后发生错误回滚了事务，但是却发现商品仍然写入了数据库。
  - **对策**：牢记 DDL 具有“隐式提交”特征，不要在业务事务块中混入任何 DDL 语句。

---

## 🧠 主动回忆

请在不看上文的情况下，尝试回答以下问题：

1. DDL、DML 和 DQL 它们的首字母英文全称分别代表什么？
2. 为什么 `TRUNCATE TABLE` 命令比 `DELETE FROM` 快很多倍？它们能被 `ROLLBACK` 撤销吗？
3. 在开始一个事务后（`START TRANSACTION`），如果我先写了一个 `INSERT`，紧接着跑了一个 `CREATE TABLE`，最后我手动输入 `ROLLBACK;`，请问这个 `INSERT` 插入的数据被撤销了吗？为什么？

## 🧭 进阶路线提示

> 本节只覆盖当前阶段需要掌握的最小知识。这五个语言大类会在以后的章节中全面拆解：

| 后续章节 | 会继续解决什么问题 |
|---|---|
| 03.02 DDL — 库与表 | 深入学习 DDL 创建、修改和删除库表的具体指令和高级约束。 |
| 03.03 DML — 写入与变更 | 深入掌握 INSERT、UPDATE、DELETE 的高级写法与变体。 |
| 03.04 DQL — 单表查询 | 正式开始数据查询 (SELECT) 语法的系统构建。 |
| 04.03 事务与并发控制 | 全面学习 TCL 所控制的事务，深入探讨 ACID、隔离级别和多版本并发控制（MVCC）。 |
| 05.03 用户权限与安全 | 系统掌握 DCL 在生产环境下的用户账户授权与权限回收机制。 |

---

## ✅ 项目练习

去 `exercises/03.01.01-sql-categories` 目录下，完成你的概念匹配练习！

**任务描述：**
请在 `exercises/03.01.01-sql-categories/exercise.sql` 中编写一条 `SELECT` 联合查询语句，完成子语言分类与代表性 SQL 语句的匹配。
你的 SELECT 输出结果必须具有如下表结构和值（顺序不限）：

| category | example_statement |
|:---|:---|
| DDL | CREATE TABLE |
| DML | INSERT INTO |
| DQL | SELECT |
| DCL | GRANT |
| TCL | COMMIT |

**运行验证：**
在终端进入该练习目录，执行自动化测试脚本：
```bash
bash test.sh
```
