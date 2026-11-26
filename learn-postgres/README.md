# 数据库实战学习项目（learn-postgres）

这是由 `sk-learn-db` 技能生成的 PostgreSQL 学习与练习环境。主线版本为 PostgreSQL 18，贯穿案例为电商订单管理系统。

## 启动环境

确保 Docker 引擎已启动，然后执行：

```bash
docker compose up -d
```

连接数据库：

```bash
docker compose exec postgres-learn psql -U postgres -d order_system
```

宿主机连接参数：`host=127.0.0.1 port=15432 dbname=order_system user=postgres password=root123`。

数据持久化目录为 `data/postgres`。PostgreSQL 18 使用 `/var/lib/postgresql/18/docker` 作为容器内数据目录，Compose 挂载其父目录以保持数据可持久化。

## 常用技能指令

- `/db postgres`：查看 PostgreSQL 大纲和当前进度。
- `/db.next postgres`：生成下一个 lesson 和练习。
- `/db.check postgres <小节编号>`：运行练习检查并登记进度。
- `/db.go postgres <目标>`：跳到指定模块或小节。
- `/db.status`：查看所有数据库的学习进度汇总。

## 阅读顺序

`01-prerequisite` → `02-foundation` → `03-sql-categories` → `04-engineering` → `05-operations` → `06-architecture`

### 👉 当前最新进度快速跳转

尚未生成 lesson。启动 Docker 后执行 `/db.next postgres`。

## 目录约定

- `docker-compose.yml`：PostgreSQL 18 实验环境。
- `progress.json`：独立学习进度与 Schema 版本。
- `data/postgres/`：数据库持久化数据。
- `schema/`：递增的建表、改表和数据变更 SQL。
- `exercises/`：每个 lesson 的独立练习与自动化检查。
