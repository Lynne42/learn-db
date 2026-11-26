# 03.02.05. 多对多关系与关联表设计

> **故事线与承上启下**：
> 在前两节中，我们攻克了主键、唯一键保障实体唯一性，并通过外键连接了用户表（`users`）与个人资料表（`temp_user_profiles`）之间 1:1 的归属关系。但在实际业务中，我们很快会面临多对多（`M:N`）的复杂关联。比如：一个用户可以拥有“系统管理员”和“财务专员”等多个角色，同时“系统管理员”这一角色下也会包含很多个具体的用户。关系型数据库无法直接在两张表之间拉起多对多指针，本节我们将探讨如何利用“关联表（Junction Table）”进行维度拆解。

## ⚡ 速查摘要

- **多对多降维**：通过引入关联表，将一个多对多（`M:N`）关系拆解为两个一对多（`1:N`）关系。
- **关联表主键设计**：优先使用两个外键的组合作为**联合主键（Composite Primary Key）**。
- **右前缀索引必要性**：联合主键 `(A, B)` 会自动为 A 建立左前缀索引。如果业务需要通过 B 关联查询 A，必须**为 B 列单独建立一个二级索引**。

---

## 🎯 学习目标与验收标准

**学习目标：**
- 掌握多对多（`M:N`）实体关系的识别与多对多降维原理。
- 理解关联表（Junction Table）的表结构骨架与字段设计。
- 掌握联合主键（Composite Primary Key）的逻辑与在 InnoDB 底层的存储优势。
- 理解联合索引的左前缀原则（Leftmost Prefix Rule）对关联表二级索引建立的决定性影响。

**验收标准：**
- [ ] 能在不引入无意义自增 id 的情况下，正确使用联合主键定义多对多关联表。
- [ ] 能解释为什么在主键设为 `(user_id, role_id)` 的情况下，必须为 `role_id` 单独加建二级索引。
- [ ] 在项目练习中创建出 `user_roles` 关联表，并通过本地校验脚本验证。

---

## 📖 概念全景

### 1. 为什么关系型数据库不能“直接”多对多？

关系型数据库的基本物理逻辑是“行与列”。在一行数据里，一个字段只能存放一个标量值。
假设要让用户关联多个角色，如果直接在 `users` 表里加一个 `role_ids` 字段并用逗号分隔（如 `1,2,3`），这虽然看起来简单，但直接破坏了**数据库第一范式（1NF）的原子性要求**。这样会导致我们根本无法对外键做物理约束、无法针对角色进行索引提速，更无法进行多表 JOIN 关联查询。

因此，解决多对多关系的唯一标准工程方案，是引入第三张表——**关联表（连接表 / 中介表 / Junction Table）**。

```mermaid
flowchart LR
    Users["用户表 users<br/>(id, username)"] -->|1| user_roles["关联表 user_roles<br/>(user_id, role_id)"]
    Roles["角色表 roles<br/>(id, role_name)"] -->|1| user_roles
    user_roles -->|N| Users
    user_roles -->|N| Roles
```

通过引入 `user_roles` 表，原本错综复杂的 `users <==> roles` 多对多关系，成功被降维成了：
- `users` (1) <=====> (N) `user_roles`
- `roles` (1) <=====> (N) `user_roles`
两个平易近人的一对多关系。

### 2. 联合主键 (Composite Primary Key)

对于关联表 `user_roles`，它的唯一性由 `user_id` 和 `role_id` 两个字段共同决定。一个用户关联某个角色的记录，在库里应该是有且仅有一条的。

因此，最优雅、最高效的设计是**直接将这两个字段声明为联合主键**：
`PRIMARY KEY (user_id, role_id)`。

> 💡 **架构师视角**：
> 关联表**不需要**自增的 `id` 列。
> 1. 省空间：自增 id 纯属冗余，去掉它可以节省物理主键和二级索引的存储开销。
> 2. 防重写：联合主键在物理上就锁死了 `(1, 2)` 这对关联，避免了因为程序 bug 导致同一个用户重复被授权同一个角色的垃圾数据产生。

### 3. 左前缀与二级索引补强

当我们创建了联合主键 `PRIMARY KEY (user_id, role_id)` 时，MySQL 实际上会自动为我们建立一个联合索引 `(user_id, role_id)`。
根据索引的**左前缀匹配原则**：
- 如果查询条件是 `WHERE user_id = ?`，可以完美走索引检索。
- 如果查询条件是 `WHERE role_id = ?`（比如：想要查出所有“系统管理员”的用户），由于 `role_id` 在索引字段的右侧，MySQL **完全无法走该索引**，只能退化为全表扫描。

为了解决这个问题，我们必须在关联表上为右侧的 `role_id` 列**手动加建一个二级索引**（`KEY idx_user_roles_role_id (role_id)`），确保“用户查角色”和“角色查用户”两个方向的关联查询都是极速的。

---

## 💻 SQL 语法

### 创建包含联合主键、物理外键及右侧索引的关联表

```sql
CREATE TABLE IF NOT EXISTS user_roles (
    user_id INT NOT NULL,
    role_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- 1. 定义联合主键
    PRIMARY KEY (user_id, role_id),
    
    -- 2. 定义双物理外键关联，并指定级联删除
    CONSTRAINT fk_user_roles_user 
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_roles_role 
      FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
      
    -- 3. 为右侧列创建二级索引，防止“反向关联”时索引失效
    KEY idx_user_roles_role_id (role_id)
) ENGINE=InnoDB;
```

---

## 🛒 订单系统实战

**业务场景：**
我们要为我们的电商系统架设多对多权限桥梁。
在此之前，我们已经生成了 [v001](file:///Users/realai/Documents/github-per/learn-db/learn-mysql/schema/v001-create-users.sql)、[v002](file:///Users/realai/Documents/github-per/learn-db/learn-mysql/schema/v002-alter-users.sql)、[v003](file:///Users/realai/Documents/github-per/learn-db/learn-mysql/schema/v003-users-unique.sql) 和 [v004](file:///Users/realai/Documents/github-per/learn-db/learn-mysql/schema/v004-create-roles.sql) 的库表结构（包含 `users` 用户表和 `roles` 角色表）。
现在，我们创建多对多关联表 `user_roles` 将二者打通。

---

## ⚠️ 常见坑点

- 💣 **坑点 1：联合索引失效导致的反向查询慢 SQL**
  - **现象**：系统运行一段时间后，当管理员想拉出“普通会员”角色的所有用户列表时，系统接口响应极慢，数据库 CPU 占用率升高。
  - **对策**：排查发现，建表时只设了 `PRIMARY KEY (user_id, role_id)`，没有为 `role_id` 创建单独的二级索引。导致通过 `role_id` 过滤或 JOIN 关联时，MySQL 只能对关联表做全表扫描。
- 💣 **坑点 2：外键级联选项遗漏**
  - **现象**：删除了一个违规用户，但是发现 `user_roles` 关联表里的脏关联记录仍然残留，后续如果复用相同用户 id 时发生越权或关联混乱。
  - **对策**：关联表的外键必须显式指定 `ON DELETE CASCADE`，使父记录销毁时，中间表自动清理关联关系。

---

## 🧠 主动回忆

请在不看上文的情况下，尝试回答以下问题：

1. 多对多关系如果不使用关联表，而是直接在字段里存逗号分隔的字符串（如 `ids = '1,2,3'`），在工程上会带来哪些严重问题？
2. 为什么在建有联合主键 `(user_id, role_id)` 的关联表上，我们依然要为 `role_id` 单独建一个二级索引？
3. 关联表为什么不需要单独设计一个自增的 `id` 字段做主键？

## 🧭 进阶路线提示

> 本主题后续还会在以下章节继续展开：

| 后续章节 | 会继续解决什么问题 |
|---|---|
| 03.04 多表查询 | 正式学习如何使用 `INNER JOIN` 将 `users`、`user_roles`、`roles` 三张表串联起来，查询某个用户拥有的所有角色名。 |
| 04.02 索引工程化与优化器 | 深入拆解联合索引（Composite Index）的物理排版，探讨最左前缀匹配规则在各种复杂 WHERE 条件下的执行计划表现。 |

---

# 扩展和延伸

## 联合主键检索

### 1. 底层物理结构：联合主键是如何排列的？
假设我们有一张学生课程表，建立了联合主键：PRIMARY KEY (class_id, student_id)。
```sql
CREATE TABLE student_courses (
    class_id INT NOT NULL,
    student_id INT NOT NULL,
    score INT NOT NULL,
    PRIMARY KEY (class_id, student_id)
) ENGINE=InnoDB;
```

在 InnoDB 的聚簇索引 B+Tree 中，数据行的物理物理排列顺序是：先按 class_id 绝对有序排列；当 class_id 相同时，再按 student_id 有序排列。

在磁盘上的物理页里，数据的逻辑顺序长这样：
```sql
(class_id=1, student_id=10) -> score=90
(class_id=1, student_id=20) -> score=85
(class_id=2, student_id=05) -> score=95  -- 新班级，student_id 重新从小到大排
(class_id=2, student_id=15) -> score=88
```

关键点：单独看 student_id 这一列（10, 20, 05, 15），在全局物理层面上是完全乱序的。

### 2. 检索（SELECT）时的三种物理命运
基于上述的物理排列，当你执行不同的 SELECT 语句时，数据库底层的检索速度会发生天壤之别：

1. 场景 A：降维打击（精确匹配/最左匹配）—— 走索引（Index Seek）
```sql
SELECT * FROM student_courses WHERE class_id = 2 AND student_id = 15;
-- 或者只查前缀
SELECT * FROM student_courses WHERE class_id = 2;
```

底层操作：执行器拿到 class_id = 2，因为 B+Tree 根节点是按 class_id 排好序的，指针可以在 $\log(N)$ 时间内瞬间定位到班级 2 的起始位置。如果还带了 student_id，就在班级 2 的内部继续二分查找。

耗时：0 毫秒级。

2. 场景 B：全面崩塌（绕过前缀）—— 全表扫描（Table Scan）

```sql
SELECT * FROM student_courses WHERE student_id = 15;
```

- 底层操作
你绕过了 class_id 直接查 student_id。因为在整棵 B+Tree 的全局视角看，student_id 是乱序的。B+Tree 的二分查找直接失效。

- 无奈的选择
InnoDB 别无选择，只能启动全表扫描（Full Table Scan），把磁盘上的所有数据页从头到尾挨个读一遍，人肉筛选出 student_id = 15 的行。

- 架构风险
如果表里有几千万条记录，这个查询会直接引发剧烈的磁盘 IO，把数据库卡死。

3. 场景 C：混合双打（范围查询）—— 索引部分失效
```sql
SELECT * FROM student_courses WHERE class_id > 1 AND student_id = 15;
```

- 底层操作：
class_id > 1 是一个范围。执行器定位到 class_id = 2 的起点，往后的数据都满足条件。但在 class_id 变成范围之后，其后面的 student_id 检索就无法再走 B+Tree 的精确定位了，只能在符合 class_id > 1 的所有数据里进行逐行扫描过滤（Index Condition Pushdown）。