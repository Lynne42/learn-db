# 分类
## 1. 关系型数据库
以二维表结构组织数据，强依赖预定义 Schema，提供严密的 ACID 事务保证。核心基于 B-Tree / B+Tree 索引体系与 WAL（Write-Ahead Logging）持久化机制

### 适用场景
核心业务数据、账户计费、多实体复杂关联查询、对数据一致性与事务隔离级别要求苛刻的场景

### 主流数据库代表
- PostgreSQL：全能型选手。支持复杂查询、JSONB 扩展、全文检索、地理信息（PostGIS）与向量检索（pgvector）。

- MySQL / MariaDB：互联网工业标准。主从读写分离与高并发行级锁成熟，生态 tooling 完备。

- SQLite：零配置嵌入式文件数据库，无独立服务端，适合轻量应用、桌面端及本地边缘计算。

### 常用工具
常见搭配生态：

- ORM / Query Builder：Prisma、Drizzle、SQLAlchemy、TypeORM

- 迁移工具：Alembic、Flyway、Liquibase

- 连接池中间件：PgBouncer、ProxySQL

### RDBMS：Relational Database Management System（关系型数据库管理系统）的缩写


## 2. 键值与内存缓存数据库（Key-Value / In-Memory）
数据驻留在内存中（或支持快速持久化），基于哈希表提供 $O(1)$ 读写，主要解决高并发读吞吐与状态共享问题。

### 适用场景
Session 存储、API 响应缓存、分布式锁、高频计数器、临时速率限制（Rate Limiting）。

### 主流数据库代表
- Redis：支持丰富数据结构（Strings |  Hashes |  Lists |  Sets |  Sorted Sets |  HyperLogLog |  Pub/Sub）。

- Valkey：基于开源协议分叉的 Redis 兼容替代品。

- Memcached：纯粹的多线程内存键值缓存，无复杂数据结构与持久化。

### 常见搭配生态

- 搭配 RDBMS 构成“Cache-Aside”读写缓存模式。
- 搭配消息队列与分布式任务框架（如 Celery、BullMQ）。

## 3. 文档型数据库（Document-Store）
存储半结构化数据（BSON / JSON 格式），无强固 Schema 约束，支持内嵌数组与嵌套对象查询。

### 适用场景
适用场景：动态字段配置、CMS 内容管理、多变的用户元数据、快速原型验证。

### 主流数据库代表
- MongoDB：通过分片集群（Sharding）提供水平扩展能力，聚合管道（Aggregation Pipeline）支持复杂处理。

- CouchDB：强调离线同步与多主复制。

### 常见搭配生态：

- ODM：Mongoose、Beanie、Motor

- 冷热分离：搭配 S3 或云归档存储做历史大文档归档。

## 4. 向量数据库（Vector DB）
底层基于近似最近邻算法（如 HNSW |  IVF-Flat |  SCaNN），专门索引和检索由 Embedding 模型生成的高维稠密向量。

### 适用场景
LLM 外部检索增强生成（RAG）、语义相似度搜索、多模态推荐系统。

### 主流代表

- 专用型：Qdrant、Milvus、Chroma、Pinecone

- 插件扩展型：PostgreSQL (pgvector)、Redis Stack

### 常见搭配生态

- 框架：LangChain、LlamaIndex

- Embedding 模型：OpenAI embeddings、BGE、Sentence-Transformers

## 5. 搜索引擎与倒排索引库（Search Engine）
基于倒排索引（Inverted Index）与 TF-IDF / BM25 算法构建，解决非结构化文本的模糊匹配、分词与多维聚合统计。

### 适用场景
电商商品全文检索、日志收集分析（ELK 架构）、APM 监控看板。

### 主流代表

- Elasticsearch / OpenSearch：分布式检索与近实时日志分析标准。

- Meilisearch / Typesense：轻量、低配置开箱即用，专为前端即搜即显（Instant Search）优化。

### 常见搭配生态

CDC / 同步工具：Logstash、Debezium、Kafka（将 RDBMS 变更实时同步至搜索库）。

## 6. 分析型与时序数据库（OLAP / Time-Series）
采用列式存储与向量化执行引擎，牺牲单行低延迟写入，换取海量数据大范围扫描与聚合的高吞吐。

### 适用场景
数据仓库、BI 报表、IoT 传感器时序指标、金融行情回测。

### 主流代表

- ClickHouse：极高写入吞吐与极限查询速度的列式分析引擎。

- DuckDB：嵌入式进程内 OLAP 引擎，类似“分析界的 SQLite”。

- TimescaleDB / InfluxDB：时序数据引擎（Timescale 基于 PostgreSQL 扩展）。

### 常见搭配生态

可视化与管道：Grafana、Apache Superset、dbt。



# 标准的数据库搭配形态
```text
                    [ 客户端 / 前端应用 ]
                             │
                             ▼
                     [ 业务后端 API ]
                             │
       ┌─────────────────────┼─────────────────────┐
       ▼                     ▼                     ▼
 [ 主数据源 (RDBMS) ]   [ 高速缓存 (Redis) ]  [ 专用引擎 (Vector/Search) ]
  • 用户/订单/租户/权限   • Session/高频热点    • RAG 知识检索 / 全文搜索
  • 保证 ACID 强一致     • 分布式锁/RateLimit  • 倒排索引 / HNSW 向量索引
```

|组合模式 | 核心技术栈示例 | 适用系统特征 | 关键权衡（Trade-off）|
|-- | -- | -- | -- |
|全能简洁型 (MVP/中小项目) | PostgreSQL + Prisma/SQLAlchemy | 单体或中小型全栈应用，业务字段结构清晰，暂无超高并发 | 架构负担最小。可用 PostgreSQL 原生 JSONB 和 pgvector 兼顾半结构化与向量，无需维护多库一致性。|
|标准双核型 (生产级标准架构) | PostgreSQL/MySQL + Redis | 电商、SaaS 平台、多租户协作系统 | 性能与成本平衡点。需要处理缓存穿透、雪崩及 Cache-DB 双写一致性逻辑。|
|AI 增强型 (现代智能应用) | PostgreSQL + Redis + Qdrant / pgvector | 具备文档对话、智能助手、知识库的业务系统 | 异构读写分离。结构化数据走关系表，非结构化语料走分块向量化入库，复杂度在于管道维护。|

# 技术选型评估
在敲定依赖前，明确以下 4 个系统约束：
1. 关系模型复杂度：多表一对多、多对多是否频繁关联？（是 $\rightarrow$ 强制 RDBMS；否 $\rightarrow$ 可考虑 Document/KV）
2. 读写比与延迟容忍：读多写少且 QPS 过万？（是 $\rightarrow$ 必须配置缓存层）
3. 一致性底线：能否容忍最终一致（Eventual Consistency）？（否 $\rightarrow$ 杜绝仅靠 NoSQL 作为主库）
4. 运维与认知成本：每引入一种不同数据引擎，本地开发容器、迁移脚本、CI/CD 与备份恢复成本翻倍。

# 数据映射工具
缩写 | 全称 | 针对的数据库类型 | 核心映射机制 |
| -- | -- | -- | -- |
| ORM | Object-Relational Mapping（对象关系映射） | "关系型数据库 (RDBMS)(PostgreSQL |  MySQL |  SQLite |  Oracle 等)" | 类（Class） → 数据库表（Table）对象属性 → 表字段（Column）对象实例 → 某一行数据（Row）|
| ODM | Object-Document Mapping（对象文档映射） | "文档型数据库 (NoSQL)(MongoDB |  CouchDB 等)" | 类（Class） → 集合（Collection）对象属性 → 文档键值对（Key-Value）对象实例 → 一个 BSON/JSON 文档（Document）|

## 主流选型
技术栈 | 主流 ORM (关系型) | 主流 ODM (文档型/MongoDB) | 特点简评 |
| -- | -- | -- | -- |
| Python | SQLAlchemy 2.0+ (老牌严谨)Tortoise-ORM (异步友好) | MongoEngineBeanie (基于 Pydantic 的现代异步库) | SQLAlchemy 是企业级标杆，生态极稳。|
| TypeScript / Node.js | Prisma (Schema 驱动，类型安全)Drizzle (轻量极速，贴近原生 SQL) | Mongoose (工业级霸主) | Prisma 开发体验好；Drizzle 性能极致、无冷启动负担。|
| Go | GORM、Ent | 官方 Go Driver (Go 很少单独封装重度 ODM) | Ent 偏向代码生成，类型严格。|
| Java | Hibernate / Spring Data JPAMyBatis (半 ORM) | Spring Data MongoDB | 国内大厂偏爱 MyBatis（保留手写 SQL 调优能力）。|

# 数据管道的四层分工体系
> 口诀：“ORM 编排逻辑，驱动搬运数据，数据库负责落盘，迁移掌控版本。”

```text
           [ 运行时：从业务到物理存储 ]
┌──────────────────────────────────────────────┐
│  1. 业务逻辑 (Python Code)                   │
│       │                                      │
│       ▼                                      │
│  2. ORM (如 SQLAlchemy)     -> 负责「翻译」   │
│       │ (SQL 语句与参数)                      │
│       ▼                                      │
│  3. 驱动 (如 asyncpg)        -> 负责「搬运」   │
│       │ (TCP 二进制网络流)                    │
│       ▼                                      │
│  4. 数据库 (如 PostgreSQL)   -> 负责「落盘」   │
└──────────────────────────────────────────────┘

           [ 开发时：表结构的生命周期 ]
┌──────────────────────────────────────────────┐
│  迁移工具 (如 Alembic)       -> 负责「版本」   │
│  (对比 ORM 模型与数据库元数据，充当 DDL 的 Git)│
└──────────────────────────────────────────────┘
```

| 角色                      | 现实世界类比     | 核心职责                                              | Python 当前常用实现 / 库                                                                                                               | 缺少它的代价                          |
| ----------------------- | ---------- | ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- | ------------------------------- |
| **数据库 Database**        | 物理仓库       | 数据磁盘持久化、索引、并发控制、事务 ACID、SQL 执行                    | **PostgreSQL**、**MySQL**、SQLite                                                                                                 | 系统无法可靠持久化业务状态                   |
| **驱动 Driver**           | 货运卡车 + 通译  | 建立 TCP/Socket 连接；实现数据库网络协议；负责 Python 类型 ↔ DB 类型转换 | PostgreSQL：**psycopg 3**、**asyncpg**；MySQL：**PyMySQL**、**mysqlclient**、**aiomysql**、**asyncmy**；SQLite：内置 **sqlite3**、aiosqlite | Python 进程无法真正和数据库通信             |
| **ORM / Query Builder** | 调度大脑       | 对象建模、SQL 构造、参数绑定、结果映射、Session/实体生命周期管理            | **SQLAlchemy 2.x**；Django ORM；SQLModel；Tortoise ORM                                                                             | 需要大量手写 SQL、参数绑定、结果映射和对象状态管理     |
| **迁移工具 Migration**      | 数据库结构的 Git | 版本化管理 DDL；创建/修改/删除表、列、索引、约束；支持升级/回滚               | SQLAlchemy 常配 **Alembic**；Django 自带 Migrations                                                                                  | 开发/测试/生产环境 Schema 容易漂移，多人协作难以控制 |


## 运行时调用链
```text
[ 你的业务代码 (FastAPI/Agent) ]
         │ 1. 面向对象调用: session.get(User, id=1)
         ▼
[ ORM 层 (如 SQLAlchemy) ]
         │ 2. 翻译与组装: 生成文本 SQL "SELECT * FROM users WHERE id = 1"
         │    并将参数 (1,) 准备好
         ▼
[ 驱动层 (Driver, 如 asyncpg / psycopg) ]
         │ 3. 协议序列化与网络通信:
         │    将 SQL 与参数按 PG 专有网络协议打包成二进制 TCP 数据包
         ▼ (通过网络 / Socket)
[ 数据库引擎 (PostgreSQL / MySQL) ]
         │ 4. 执行计划、命中索引、读取磁盘、执行事务
         ▼
[ 驱动层 (Driver) ]
         │ 5. 收到原始响应字节，反序列化成 Python 元组: (1, "alice", 20)
         ▼
[ ORM 层 (SQLAlchemy) ]
         │ 6. 实例化与填充对象: 创建 User(id=1, name="alice", age=20)
         ▼
[ 你的业务代码 ] 拿到强类型的 user 对象
```

## 开发时调用链

表结构变化时：

```text
SQLAlchemy Models
        │
        │ 对比 metadata
        ▼
Alembic autogenerate
        │
        ▼
Migration Python 文件
        │
        │ 人工 Review
        ▼
alembic upgrade head
        │
        ▼
Database Schema
```

## ORM使用哲学
在实际开发中，ORM与手写SQL往往是共同存在的状态
```
                     [ 业务系统划分 ]
                           │
       ┌───────────────────┴───────────────────┐
       ▼                                       ▼
 [ 80% 的常规业务 CRUD ]                  [ 20% 的核心高频/复杂报表 ]
  • 用户注册、登录、修改资料               • 核心计费对账、实时仪表盘
  • 订单创建、状态流转                     • 大数据量批量导入导出
  • 严格使用 ORM / 自动迁移                • 果断手写原生 SQL / 走驱动层
  • 追求：开发速度、类型安全、规范统一       • 追求：执行计划可控、零内存开销、极致性能
```


# 工程实践选型
在工业级后端开发中，数据层的完整工程栈遵循四层标准化分工：

```text
业务调用 (ORM / Query Builder) --> 底层驱动 (Driver) --> 迁移工具 (Migration) --> 存储引擎 (RDBMS)

应用代码
   │
   ▼
ORM / Query Builder
SQLAlchemy
   │
   ▼
Driver
asyncpg / psycopg / aiomysql / asyncmy
   │
   ▼
Database
PostgreSQL / MySQL


旁路：
Model → Alembic → Migration → Database Schema
```

编程语言 | 方案类型 | ORM / Query Builder | 底层驱动 (Driver) | 迁移工具 (Migration) | 适用场景与技术特质 |
| -- | -- | -- | -- | -- | -- |
| Python | 现代异步标配 (推荐) | SQLAlchemy 2.0 (async) | asyncpg (PG) / aiomysql (MySQL) | Alembic | FastAPI / Litestar 黄金搭档。完全类型提示，兼顾复杂查询与高吞吐。|
| | 全包一体化 | Django ORM | psycopg (PG) / mysqlclient (MySQL) | Django Migrations | 传统 Django 单体系统。开箱即用自带管理后台与开箱即用的迁移体系。|
| TypeScript / Node.js | 极致控制 / Serverless | Drizzle ORM | pg / postgres-js / @neondatabase/serverless | Drizzle Kit | Next.js / 边缘计算新宠。纯 TS 建模无黑盒，零运行时引擎，极速冷启动。|
| | 开箱即用 / 快速原型 | Prisma | Prisma 引擎内置连接 / Driver Adapters | Prisma Migrate | 全栈/SaaS 团队首选。独立 DSL 建模，自动生成全套类型安全的 Client API。|
| | 传统企业级 | TypeORM / MikroORM | pg / mysql2 | 自带 Migration 体系 | NestJS 经典企业方案。采用装饰器风格（Class-based），适合 Java 转来的团队。|
| Golang | 图式生成 / 编译期安全 | Ent | pgx (PG) / go-sql-driver/mysql | Atlas / Ent 自带迁移 | 大型微服务基石。Facebook 出品，代码生成模式，零反射消耗，编译期排错。|
| | 上手最快 | GORM | gorm.io/driver/postgres 或 mysql | golang-migrate | 业务 CRUD 快速迭代。社区庞大，但处理复杂关联时需额外配合第三方迁移工具。|
| | 纯 SQL 驱动型 | SQLc | pgx/v5 / database/sql | Goose | 高性能团队首选。手写原生 .sql，自动编译生成类型安全的 Go 结构体与查询。|
|Java | 国内大厂标配 (半ORM) | MyBatis-Plus | HikariCP + JDBC 驱动 (postgresql / mysql-connector-j) | Flyway | 核心 SQL 手动可控，易于做复杂 SQL 调优与索引命中分析，国内企业系统主流。|
| | 国际/企业标配 (纯ORM) | Spring Data JPA (Hibernate) | HikariCP + 对应 JDBC 驱动 | Liquibase / Flyway | 面向对象规范严密的 DDD 领域驱动开发，抽象层级高，但存在 N+1 性能陷阱。
Rust | 编译期校验 | SQLx | 内部集成异步驱动 (基于 tokio) | sqlx-cli | 编写原生 SQL，编译阶段连库校验语法与类型，零运行时反射开销。|
| | 纯强类型 ORM | Diesel | pq (PG) / mysqlclient-sys | diesel_cli | 查询逻辑全部映射进 Rust 类型系统，类型系统强保证，编译通过即运行安全。|

