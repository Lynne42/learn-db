# 数据库实战学习项目 (learn-mysql)

这是一个由 `sk-learn-db` 技能生成的 MySQL 学习与练习环境。当前大纲版本为 v3，阅读顺序为：`01-prerequisite` → `02-foundation` → `03-sql-categories` → `04-engineering` → `05-operations` → `06-architecture`。

## 🚀 如何启动环境

本环境基于 Docker，启动前请确保已经安装并启动 Docker 引擎。

```bash
docker compose up -d
```

数据持久化保存在 `data/mysql`，本次大纲迁移不会重置数据库数据。

## 进入容器

```bash
docker compose exec mysql-learn bash
```

或直接连接 MySQL：

```bash
docker compose exec mysql-learn mysql -uroot -proot123 order_system
```

## 🛠️ 常用技能指令

- `/db.next`：生成下一节 lesson 和练习。
- `/db.check`：验证当前练习并登记进度。
- `/db mysql`：查看 MySQL 大纲和当前进度。
- `/db.status`：查看学习进度汇总。
- `/db.go mysql <目标>`：跳到指定模块或小节。

## 🗺️ 阅读顺序

1. **`01-prerequisite/`（先导篇）**：数据库世界观、关系模型、Docker 和客户端。
2. **`02-foundation/`（数据库基础篇）**：数据类型、字符集与排序规则。
3. **`03-sql-categories/`（SQL 语言分类篇）**：DDL、DML、DQL、DCL、TCL 与基础闭环项目。
4. **`04-engineering/`（工程进阶篇）**：索引、优化器、事务并发、高级查询和 Stored Objects。
5. **`05-operations/`（生产运维篇）**：配置、日志、安全、监控诊断、备份恢复和迁移。
6. **`06-architecture/`（架构演进篇）**：表设计、InnoDB 存储、分区、复制、高可用和分库分表。

未学习到的模块目录可能尚未生成，这是正常状态。

---

### 👉 当前最新进度快速跳转

**[点击前往：模块 04.02（当前小节 04.02.01 统计信息与优化器选择）知识地图与课件列表](./04-engineering/02-index-optimizer/index.md)**

---

## 📚 详细目录大纲

### 1. 先导篇

- [模块 01.01：数据库概论](./01-prerequisite/01-intro/index.md)
- [模块 01.02：环境搭建与工具](./01-prerequisite/02-env/index.md)

### 2. 数据库基础篇

- [模块 02.01：数据类型](./02-foundation/01-data-types/index.md)
- [模块 02.02：字符集与排序规则](./02-foundation/02-charsets/index.md)

### 3. SQL 语言分类篇

- [模块 03.01：SQL 基础与语言分类](./03-sql-categories/01-overview/index.md)
- [模块 03.02：DDL — 数据定义语言](./03-sql-categories/02-ddl/index.md)
- [模块 03.03：DML — 数据操作语言](./03-sql-categories/03-dml/index.md)
- [模块 03.04：DQL — 数据查询语言](./03-sql-categories/04-dql/index.md)
- [模块 03.05：DCL — 数据控制语言](./03-sql-categories/05-dcl/index.md)
- [模块 03.06：TCL — 事务控制语言](./03-sql-categories/06-tcl/index.md)
- [模块 03.07：SQL 基础闭环项目](./03-sql-categories/07-sql-project/index.md)

### 4. 工程进阶篇

- [模块 04.01：索引基础与查询计划](./04-engineering/01-index-query-plan/index.md)
- [模块 04.02：索引工程化与优化器](./04-engineering/02-index-optimizer/index.md)
- 模块 04.03：事务与并发控制（尚未生成）
- 模块 04.04：高级查询表达（尚未生成）
- 模块 04.05：视图与查询封装（尚未生成）
- 模块 04.06：存储过程与函数（尚未生成）
- 模块 04.07：触发器与事件（尚未生成）

### 5. 生产运维篇

- 模块 05.01：MySQL 运行配置与状态（尚未生成）
- 模块 05.02：日志与问题定位（尚未生成）
- 模块 05.03：用户权限与安全（尚未生成）
- 模块 05.04：监控诊断与元数据（尚未生成）
- 模块 05.05：备份恢复与数据迁移（尚未生成）

### 6. 架构演进篇

- 模块 06.01：架构视角的表设计方法论（尚未生成）
- 模块 06.02：InnoDB 存储与 Online DDL（尚未生成）
- 模块 06.03：分区表与大表治理（尚未生成）
- 模块 06.04：复制基础（尚未生成）
- 模块 06.05：高可用与读写分离（尚未生成）
- 模块 06.06：分库分表与架构取舍（尚未生成）

## 📁 系统保留目录

- `docker-compose.yml`：Docker 环境编排配置。
- `progress.json`：学习进度与迁移记录。
- `data/`：数据库本地持久化目录。
- `schema/`：递增的建表、改表和数据变更 SQL。
- `exercises/`：练习文件与自动化检查脚本。

## 迁移说明

- 已生成 lesson 和练习目录已迁移到 outline v3 对应路径。
- 已完成、已生成状态及复习字段均已保留。
- DDL、DML、DQL 已按完整 SQL 子功能聚合。
- `data/mysql`、Docker 配置和 Schema SQL 内容未重置。
