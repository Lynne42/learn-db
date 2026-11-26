# 模块 03.03: DML — 数据操作语言

> **模块定位**：在完成库与表结构设计 (DDL) 后，系统正式进入数据操作阶段。DML (Data Manipulation Language) 负责数据的持久化写入、更新与清除，是支撑业务系统（如订单创建、状态修改、废弃账号清理）运行的核心语言。本模块将深入探讨高效且安全的写入、单行与批量修改/删除技巧，理解 `sql_safe_updates` 的安全限制，并剖析 `TRUNCATE` 与 `DELETE` 的物理本质差异。

## 🎯 知识边界与生态位

**本模块覆盖**：
- 数据的插入语法：单行插入、批量插入、`INSERT ... SELECT` 数据迁移。
- 数据修改与删除：`UPDATE` 和 `DELETE` 的核心语法，带有 `WHERE` 条件的定位操作。
- 安全保障机制：安全更新模式 (`sql_safe_updates`) 的拦截原理。
- 物理清理对比：`TRUNCATE TABLE` 与 `DELETE` 在日志写入、空间回收、触发器及原子性上的物理差异。
- 冲突写入应对：使用 `INSERT IGNORE`、`REPLACE`、`ON DUPLICATE KEY UPDATE (Upsert)` 应对唯一性冲突。
- 批量执行与数据交换：SQL 文件、`LOAD DATA`、CSV、`mysqlimport` 与基础导出。

**本模块不覆盖**：
- 多表联查与子查询写入：涉及复杂 DQL 的写入优化将在高级查询篇展开。
- 事务并发与隔离：多线程下 `UPDATE` 造成的行锁冲突与超卖问题，将在【模块 04.03 事务与锁】详细讲解。
- 物理存储页面的数据裂变：DML 带来的聚簇索引页面分裂物理过程，详见存储引擎底层章节。

## 📚 本模块结构

| 小节 | 文件 | 状态 | 核心说明 |
|------|------|------|----------|
| 03.03.00. 数据插入 | [00-insert.md](./00-insert.md) | ✅已通关 | 掌握 INSERT INTO 语法 and 批量插入最佳实践。 |
| 03.03.01. 数据更新与删除 | [01-update-delete.md](./01-update-delete.md) | ✅已通关 | 学习 UPDATE/DELETE 安全边界，对比 TRUNCATE 物理原理。 |
| 03.03.02. Upsert、REPLACE 与 INSERT IGNORE | [02-upsert-replace-ignore.md](./02-upsert-replace-ignore.md) | ✅已通关 | 掌握唯一键冲突时的写入应对策略 (IGNORE, REPLACE, Upsert)。 |
| 03.03.03. 批处理 SQL 文件 | [03-batch-sql.md](./03-batch-sql.md) | ✅已通关 | 使用 mysql 批处理模式执行可复用 SQL 文件。 |
| 03.03.04. LOAD DATA 与 CSV 导入 | [04-load-data-csv.md](./04-load-data-csv.md) | 📝已生成 | 掌握 CSV 批量导入、NULL 处理与 `secure_file_priv` 边界。 |
| 03.03.05. mysqlimport 与基础导出 | [05-mysqlimport-export.md](./05-mysqlimport-export.md) | 📝已生成 | 理解 mysqlimport、`LOAD DATA` 和 `SELECT ... INTO OUTFILE` 的关系。 |

## 🗺️ 完整知识地图 (Knowledge Map)

> 从架构师的视角，重新梳理本章知识点的因果关系。

| 核心知识点 | 本质/语法 | 架构师视角 (Why & When) | 学习位置 |
|------------|-----------|-------------------------|----------|
| **安全更新模式 (`sql_safe_updates`)** | 客户端级安全限制 | 避免因漏写 `WHERE` 子句或未使用索引/主键定位而导致的全表更新/删除灾难。生产环境中强烈建议开启。 | 03.03.01 |
| **TRUNCATE TABLE** | DDL 级别的快速截断 | 物理上通过重建表结构（而不是逐行删除）来清理数据。速度极快，不记 Undo Log，直接释放表空间，但不支持事务回滚且无法触发触发器。用于大表快速重置。 | 03.03.01 |
| **DELETE 逐行清理** | DML 级别的条件清理 | 逐行标记数据为删除，并记录 Undo Log 和 Binlog。速度慢，占用空间不会立刻在物理盘释放，但支持事务回滚。用于日常精准的业务数据清理。 | 03.03.01 |
| **ON DUPLICATE KEY UPDATE** | 基于唯一约束的 Upsert | 如果写入时发生主键或唯一约束冲突，则自动转为执行更新操作。可有效减少应用层“先查再写”的网络往返，在支付幂等和指标累加中极常用。 | 03.03.02 |

## ⚡ 速查与避坑指南 (Cheat Sheet)

| 场景/操作 | 最佳实践 / 核心命令 | ⚠️ 常见避坑提示 |
|-----------|--------------------|----------------|
| **安全删除/更新限制** | `SET sql_safe_updates = 1;` | 开启后，`UPDATE` 或 `DELETE` 语句必须在 `WHERE` 中提供包含主键或索引列的过滤条件，否则 MySQL 拒绝执行。 |
| **极速重置表数据** | `TRUNCATE TABLE users;` | 此操作为 DDL 语句，**不可在事务中回滚**，会物理释放数据空间，不要在主从延迟敏感或需要触发器的场景使用。 |
| **安全更新多列** | `UPDATE users SET status = 0, email = 'x@x.com' WHERE id = 1;` | 多个更新字段用逗号分隔，**千万不要在 SET 中混用 AND**，如 `SET a=1 AND b=2` 会将表达式 `1 AND b=2` 的布尔结果赋值给 `a`！ |


## 语句模版
### INSERT
1. 普通插入
```sql
INSERT INTO table_name (column1, column2, column3)
VALUES 
    (value1_1, value1_2, value1_3),
    (value2_1, value2_2, value2_3);
```

2. 防冲突插入
当表中设置了主键，或者至少一个唯一性索引的时候， 必须始终这种方式插入数据以避免唯一键冲突
```sql
INSERT INTO table_name (id, biz_status, updated_at)
VALUES (10023, 2, '2026-07-09 18:38:00')
-- 将新插入的数据行虚拟为别名 t
AS t 
-- 若 id 发生主键冲突，则转为更新以下字段
ON DUPLICATE KEY UPDATE 
    biz_status = t.biz_status,  -- 直接引用新数据的状态值 (2)
    updated_at = t.updated_at;
```

### UPDATE
1. 单条精准修改
```sql
UPDATE table_name 
SET column1 = new_value1, column2 = new_value2
WHERE id = target_id; -- 必须是主键或唯一索引
```

2. 大表多数据修改
```sql
UPDATE table_name 
SET status = 1 
WHERE category_id = 5     -- category_id 必须是索引列
  AND id > last_processed_id -- 配合主键防止重复扫描
ORDER BY id ASC           -- 保证批量操作的物理顺序一致，防死锁
LIMIT 1000;               -- 单次熔断阀门，只锁 1000 行
```

### DELETE
1. 单条精准删除

```sql
DELETE FROM table_name 
WHERE id = target_id; -- 严格基于主键，纳米级释放，无并发冲突
```

2. 大表历史数据清理（分批消灭迭代器模式）
```sql
DELETE FROM table_name 
WHERE create_time < '2026-01-01' -- create_time 必须是索引列
  AND id > 0                     -- 抬出主键放行安全模式 (sql_safe_updates)
ORDER BY id ASC                  -- 按主键顺序删除，避免索引碎片化
LIMIT 5000;                      -- 每次只切除 5000 条，执行完由后端代码循环拉取
```

## 安全更新模式（sql_safe_updates = 1）下， 拦截对则对操作方式 INSERT，UPDATE，DELETE有何不同
### 1️⃣ UPDATE 和 DELETE（受严格限制）
这两个是写操作，它们**必须在 WHERE 条件中包含索引列**。

- 错误路径（被禁止）：UPDATE users SET nickname = 'Neo' WHERE age = 18; （如果 age 不是索引，直接报错拦截）。

- 正确路径（放行）：UPDATE users SET nickname = 'Neo' WHERE id = 10; （id 是主键索引，放行。虽然修改的是没索引的 nickname，但寻找路径走的是索引 id）。

### 2️⃣ INSERT（完全不受限制）
INSERT 是向表里插入一条全新的记录，它根本没有 WHERE 条件，所以它完全不受安全更新模式的限制。不管表里有没有索引，新数据都能直接塞进去。

1. 触发冲突的引擎底层真相：主键或唯一索引（Unique Index）
只要插入数据，在表中的任意一个具有唯一性约束的字段上产生了重复，这个“别名更新机制”就会被激活。

2. 唯一约束是前提：
使用这种别名冲突更新语法，表结构中必须存在主键或至少一个唯一索引（UNIQUE KEY）。

3. 致命崩溃点（多唯一索引陷阱）：
如果一张表里同时存在两个唯一索引（比如 id 是主键，phone 也是唯一索引）。当你插入一条 id=1 且 phone='1380000' 的数据时，如果表里已经有一行的 phone 已经是 '1380000' 但 id 不同，MySQL 同样会判定冲突并执行更新。这会导致你本来想插入新用户，结果却意外修改了另一个老用户的状态。

4. 失效判定标准：
在线上环境设计高并发流水表或幂等去重表时，如果误将 UNIQUE 索引建成了普通的 INDEX，导致 ODKU 语法失效、数据疯狂重复插入，判定方案彻底崩溃。必须立即通过 ALTER TABLE ... ADD UNIQUE (...) 补齐唯一性闸门。

### 底层锁与安全本质
操作类型 | 是否受 sql_safe_updates 限制 | WHERE 条件的要求 | 底层加锁行为 (InnoDB) | 
-- | -- | -- | -- |
INSERT | ❌ 完全不受限 | 无 WHERE 条件 | 隐式锁，仅锁住新插入的那一行（行锁）。 | 
UPDATE | 严格受限 | WHERE 必须包含索引列 | 走索引锁行（X锁）；不走索引（没开安全模式时）退化为全表锁。 | 
DELETE | 严格受限 | WHERE 必须包含索引列 | 走索引锁行+间隙锁（Gap Lock）；不走索引直接锁死整张表。 | 
