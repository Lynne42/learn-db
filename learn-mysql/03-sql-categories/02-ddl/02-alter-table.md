# 03.02.02. 表结构变更

> **故事线与承上启下**：
> 在上一节中，我们从无到有创建了用户表 `users`，完成了实体对象的存储基础。然而在真实的互联网系统演进中，业务需求是不断变化的。为了记录用户的注册时间，我们需要为表增加时间维度；为了提高检索便利，我们需要用到生成列。这就是 `ALTER TABLE` 登场的时刻。本节我们将攻克结构变更的各种 DDL 变体，并深入探讨生产环境中修改表结构的安全防线。

## ⚡ 速查摘要

- **增加列**：`ALTER TABLE <表名> ADD COLUMN <列名> <类型> [约束];`
- **删除列**：`ALTER TABLE <表名> DROP COLUMN <列名>;`
- **修改列属性**：`ALTER TABLE <表名> MODIFY COLUMN <列名> <新类型> [新约束];`
- **重命名列**：`ALTER TABLE <表名> CHANGE COLUMN <旧名> <新名> <类型> [约束];`
- **重命名表**：`RENAME TABLE <旧表名> TO <新表名>;`
- **虚拟生成列**：`ALTER TABLE <表名> ADD COLUMN <列名> <类型> GENERATED ALWAYS AS (表达式) VIRTUAL;`

---

## 🎯 学习目标与验收标准

**学习目标：**
- 熟练掌握使用 `ALTER TABLE` 增、删、改、重命名列的各种 DDL 语法。
- 掌握虚拟生成列（`Generated Columns`）的原理和设计方法。
- 建立对 DDL 带来的元数据锁（Metadata Lock, MDL）和生产大表变更风险的认知。

**验收标准：**
- [ ] 能在已有的表上正确增加多个字段并配置其自动初始化及更新属性。
- [ ] 能编写语句创建基于表达式的 Virtual Column 虚拟生成列。
- [ ] 能够成功完成练习：修改本地 `users` 表，添加时间戳和虚拟小写列，并通过测试脚本。

---

## 📖 概念全景

### 1. ALTER TABLE 兵器库

`ALTER TABLE` 就像是针对物理表结构的外科手术刀。它有多种切入方式：
- **`ADD`**：注入新字段。可使用 `FIRST` 或 `AFTER <已有列>` 指定物理顺序。
- **`DROP`**：物理切除字段，会直接删除对应字段中的所有历史数据，不可逆。
- **`MODIFY`**：用于改变列的“属性”（如将 `VARCHAR(50)` 扩容到 `VARCHAR(100)`，或者把允许为 NULL 改为 NOT NULL）。
- **`CHANGE`**：不仅能改“属性”，还能同时改“字段名”（有些老版本 MySQL 只支持 CHANGE 改名字，8.0 引入了专门的 `RENAME COLUMN`）。

### 2. 虚拟生成列 (Generated Columns)

MySQL 5.7+ 引入的极其惊艳的特性。它的值**不需要**由应用层 INSERT 传入，而是**由数据库自动基于表内的其他列计算生成**。

它有两种类型：
1. **`VIRTUAL` (虚拟列，默认)**：数据不存储在磁盘上。每次查询时动态计算。它不占用额外的存储空间，只在读取时消耗微量 CPU。**推荐使用**。
2. **`STORED` (存储列)**：数据在 DML 写入时被计算好并存储在磁盘上。它占用物理存储空间，但能省去查询时的动态计算开销。

> 💡 **架构师视角**：
> 虚拟生成列在对非结构化数据（如 JSON 里的特定字段）进行提炼、或者实现忽略大小写的联合字段计算时非常有用。而且，**MySQL 支持在 VIRTUAL 虚拟列上直接创建二级索引**！

### 3. 生产环境大表变更 MDL 风险

在开发阶段，`ALTER TABLE` 几乎是瞬间完成的。但是在高并发的生产环境大表上，执行 DDL 是一项极高危的操作。
当对表执行 DDL 时，MySQL 会申请 **元数据排他锁（Metadata Lock - MDL Write Lock）**。如果有正在进行的慢查询或者长事务持有了该表的 MDL Read 锁，DDL 就会被阻塞等待。
一旦 DDL 在 MDL 队列中被阻塞，它会**直接阻塞后续所有进入的对该表的 SELECT/DML 操作**，导致整个系统的线程迅速耗尽，引发雪崩 Crash。


### 4. 锁级别
锁级别 | 读锁 (共享锁 / S锁) 表现 | 写锁 (排他锁 / X锁) 表现 | 冲突规则 | 
-- | -- | -- | -- |
行级锁(保护表里某一行数据) | 多个 SELECT ... FOR SHARE 可以同时读取同一行。 | 一个 UPDATE 正在改这一行，其他人都必须等着。 | 读读兼容读写冲突写写冲突  | 
元数据锁 (MDL)(保护表的结构) | 1000个 SELECT 可以同时无阻碍地查这张表。 | 一个 ALTER TABLE 进场，所有人（包括读和写）都得停下排队。 | 读读兼容读写冲突写写冲突 | 

在绝大多数情况下，这些锁不是用户手动去创建或声明的，而是 MySQL 引擎为了保证数据安全和事务隔离，根据你输入的 SQL 语句“自适应、自动加锁”的。

你的业务操作 (SQL) | 数据库在底层自动为你加的锁 | 锁的生命周期 (何时释放) | 
-- | -- | -- |
SELECT ... | 自动加 MDL 共享读锁 | SQL 语句执行完，立刻自动释放。 | 
INSERT / UPDATE / DELETE | ① 自动加 MDL 共享读锁 (防止表结构被改)② 自动加 行级排他写锁 (防止别人改这几行) | 必须等到整个事务提交（COMMIT）或回滚（ROLLBACK）时，才会统一自动释放。 | 
ALTER TABLE / DROP | 自动加 MDL 排他写锁 | DDL 变更完全结束、元数据刷新到磁盘后，自动释放。 | 

手动干预：
1. 强行加行级读锁（S锁）
```sql
SELECT * FROM orders WHERE id = 1001 FOR SHARE;
```
含义：我手头要用这行数据算账，别人可以看，但在我算完账（事务提交）之前，谁也别想改它。

2. 强行加行级写锁（X锁，即悲观锁）
```sql
SELECT * FROM wallet WHERE user_id = 888 FOR UPDATE;
```
含义：这行数据（比如余额）我要准备扣款了，数据库你现在立刻帮我把它锁死。谁也别想读（指通过 FOR SHARE 读），谁也别想改，直到我事务结束。


---

## 💻 SQL 语法

### 1. 基础字段变更

```sql
-- 1. 增加列
ALTER TABLE users ADD COLUMN age INT NOT NULL AFTER email;

-- 2. 修改列宽度
ALTER TABLE users MODIFY COLUMN username VARCHAR(100) NOT NULL;

-- 3. 字段重命名
ALTER TABLE users RENAME COLUMN email TO user_email;
```

### 2. 虚拟生成列语法

```sql
-- 增加一个由 价格 * 数量 自动计算而成的虚拟生成列 amount
ALTER TABLE order_items 
  ADD COLUMN amount DECIMAL(10,2) GENERATED ALWAYS AS (unit_price * quantity) VIRTUAL;
```

---

## 🛒 订单系统实战

**业务场景：**
我们的订单系统用户表 `users` 需要支持记录用户的注册和最后更新时间。同时，客服系统在检索用户名时需要无视大小写，为了提高这一检索的直觉性能，我们需要为表增加一个虚拟列 `username_lower`，存放自动转为小写后的用户名。

**实战 SQL：**

```sql
-- 1. 增加时间戳管理列，支持自动初始化和级联更新
ALTER TABLE users 
  ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL;

-- 2. 增加基于 username 字段的小写虚拟生成列
ALTER TABLE users
  ADD COLUMN username_lower VARCHAR(50) GENERATED ALWAYS AS (LOWER(username)) VIRTUAL;
```

---

## ⚠️ 常见坑点

- 💣 **坑点 1：大表直接 MODIFY COLUMN 造成全表重建**
  - **现象**：为了防止邮箱溢出，执行了 `ALTER TABLE orders MODIFY COLUMN note VARCHAR(500);`。结果导致数据库连接超时，业务直接卡死。
  - **对策**：MODIFY 字段类型如果涉及数据类型转换或缩小长度，MySQL 会通过复制表的形式重建整表。在生产环境中，需要评估大表数据量，或使用 pt-osc 等工具进行变更。
- 💣 **坑点 2：DDL 阻塞引发连接池爆满**
  - **现象**：凌晨跑大表 DDL 时认为业务量小，但因为被一个未提交的分析长查询锁住，后续正常交易进来的 SELECT 被全部堵在 MDL 队列后面，系统报错 `Too many connections`。
  - **对策**：在执行 DDL 前，先排查 `SHOW PROCESSLIST` 确认没有任何当前表上的活跃事务或长查询。

---

## 🧠 主动回忆

请在不看上文的情况下，尝试回答以下问题：

1. 虚拟生成列的 `VIRTUAL` 与 `STORED` 这两个修饰词在物理存储和计算时有什么区别？
VIRTUAL 生成虚拟列，不占用磁盘存储，在获取数据的时候动态计算该列的值
STORED 生成的虚拟列，直接建数据卸载该列，占用磁盘存储，计算时可以直接拿到值不需要额外计算

2. 为什么在 MySQL 8.0 中，如果一个大表上的 DDL 变更为何会把后面的 SELECT 查询也全部堵死？底层锁机制是什么？
在进行DDL操作时， 会自动申请一个元数据排他锁，

3. `ALTER TABLE` 时使用 `MODIFY COLUMN` 和 `CHANGE COLUMN` 的核心区别是什么？

CHANGE COLUMN 不仅能修改列的属性， 还能修改列的名字

## 🧭 进阶路线提示

> 本主题后续还会在以下章节继续展开：

| 后续章节 | 会继续解决什么问题 |
|---|---|
| 04.02 索引工程化与优化器 | 详解如何直接在 Virtual Column 上建立辅助索引以优化 JSON 或复杂字符串的检索速度。 |
| 06.02 InnoDB 存储与 Online DDL | 深入探讨 Online DDL 在不同 MySQL 版本底层的物理机制，解构 Instant/Copy/Inplace 三种算法，以及如何防范 MDL 锁。 |

---

# 扩展与延伸
## 为什么在 MySQL 8.0 中，如果一个大表上的 DDL 变更为何会把后面的 SELECT 查询也全部堵死？底层锁机制是什么？

在 MySQL 8.0 中，一个大表上的 DDL（如 `ALTER TABLE`）把后面的 `SELECT` 查询全部堵死，其底层的罪魁祸首是 **MDL（Metadata Lock，元数据锁）**。

---

### 1. 为什么需要元数据锁（MDL）？

试想一个场景：如果你的 `SELECT` 查询需要扫描一张 1000 万行的表，耗时 10 秒。当查询进行到第 5 秒时，另一个线程突然执行了 `DROP TABLE` 或者 `ALTER TABLE` 把某个字段删了。
如果没有保护机制，你的 `SELECT` 查到一半，表结构变了，数据库直接就会崩溃。

为了防止这种情况，MySQL 引入了 MDL。它的核心原则是：**当有读操作在进行时，不允许改表结构；当有改表结构操作在进行时，不允许读写数据。**

---

### 2. 核心锁冲突：共享锁（Shared） vs 排他锁（Exclusive）

MDL 分为很多种模式，我们看最核心的两个：

* **`MDL_SHARED_READ`（共享读锁）**：所有 DQL/DML（`SELECT`、`UPDATE`、`INSERT`、`DELETE`）在执行时，都会自动去申请这个共享读锁。**“共享”意味着大家可以同时读**，1000 个 `SELECT` 可以同时持有这个锁。
* **`MDL_EXCLUSIVE`（排他锁，即 X 锁）**：所有的结构变更（`ALTER TABLE`、`DROP TABLE`）在执行时，都会申请排他锁。**“排他”意味着顺我者昌逆我者亡，它不与任何其他 MDL 锁兼容**。

---

### 3. 线上全站堵死的“多米诺骨牌”现场（底层阻塞机制）

为什么大表的 DDL 会把后面的 `SELECT` 也堵死？因为 MySQL 底层维护了一个 **MDL 锁队列（Queue）**，并且**写锁（排他锁）的优先级天然高于读锁（共享锁）**。

我们用一个时间线来复现这个致命的死锁链条：

#### 第一步：慢查询占坑

有一个长事务、慢 `SELECT`（或者一个没提交的显式事务），正在大表上慢吞吞地执行。此时，它持有该表的 **MDL 共享读锁**。

#### 第二步：DDL 进场排队

你执行了 `ALTER TABLE`。DDL 想要修改表结构，于是向系统申请 **MDL 排他锁**。
系统一看：“不行，前面还有一个 `SELECT` 没执行完呢，它占着共享锁，排他锁必须等待。”
于是，**DDL 进入 MDL 队列中开始等待**。

#### 第三步：灾难降临，后续 `SELECT` 全部全军覆没

此时，后续的高并发短 `SELECT` 疯狂涌入。
它们也想申请 **MDL 共享读锁**。按照常理，共享锁和共享锁是兼容的，它们应该可以绕过 DDL 继续执行对吧？
**错误！MySQL 锁队列的规则是：一旦队列里有一个“写锁（排他锁）”在排队，后面所有新来的“读锁”申请全部必须在后面排队等着！**

> **底层逻辑**：为了防止写操作被无限期“饿死”（Starvation），MySQL 规定写锁排队时，后续的读锁不能插队。

结果就是：

1. **DDL 被老的 `SELECT` 堵住**。
2. **所有新的 `SELECT` 被 DDL 堵住**。
3. 数据库连接池（Connection Pool）在几秒钟内被后续的 `SELECT` 撑爆，前端报 504 响应超时，全站瘫痪。

---

### 架构师的“终止开关”与防崩溃路径

如果你必须在生产环境操作大表 DDL，如何打破这个死锁链条？

1. **设置 DDL 锁超时时间（立即开始的核心）**
绝不允许 DDL 无限期排队。通过设置 `lock_wait_timeout`，让 DDL 拿不到锁时立刻超时失败，退出队列，释放后续的 `SELECT`。
```sql
SET session lock_wait_timeout = 3; -- 3秒拿不到 MDL 锁就直接报错退出，不堵塞后续流量
ALTER TABLE large_table ADD COLUMN new_col INT;

```


2. **使用在线变更工具（pt-osc / gh-ost）**
互联网大厂严禁对大表执行原生的 `ALTER TABLE`。必须使用 `gh-ost` 或 `pt-online-schema-change`。它们的原理是暗中建一张临时新表，异步同步数据，最后通过极其短暂的 `RENAME` 切换，将 MDL 锁的持有时间压缩到毫秒级，彻底解决阻塞问题。


## 当用户执行一条 UPDATE 时，底层到底加了什么锁？
当你在代码里执行一条普通的 UPDATE users SET name = 'X' WHERE id = 1; 时，MySQL 底层会同时叠加上述两层锁：

第一层防御（Server 层）：自动加一个 MDL 共享读锁（MDL_SHARED_WRITE）。

作用：告诉所有人，“我正在改这表里的数据，你们谁也别想动表结构（别来 ALTER/DROP）”。

第二层防御（Engine 层）：自动加一个 行级排他写锁（Record X Lock） 锁住 id=1 这一行。

作用：告诉其他人，“这行数据我正在改，别的连接别想碰这行”。