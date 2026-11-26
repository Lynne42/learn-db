# 03.03.04. LOAD DATA 与 CSV 导入

> **故事线与承上启下**：
> 在上节课中，我们掌握了如何批量执行 SQL 脚本文件。然而，在日常开发和系统集成中，我们要面对的往往不是预先写好 SQL 的文件，而是其他业务系统（如 ERP、财务系统或商户后台）导出的纯文本数据报表（如 CSV 格式的商品列表、订单流水）。如果把这些动辄几十万行的文本数据在应用层解析、拼接并循环调用 `INSERT` 写入，不仅代码繁琐，还会对 CPU 和网络造成严重压迫。本节我们将学习 MySQL 内建的超高速数据加载指令：`LOAD DATA`，并掌握如何应对路径安全变量 `secure_file_priv` 的物理阻防。

## ⚡ 速查摘要

- **基础语法**：
  ```sql
  LOAD DATA INFILE '数据文件路径.csv'
  INTO TABLE 表名
  FIELDS TERMINATED BY ',' -- 字段分隔符，CSV通常为逗号
  ENCLOSED BY '"'          -- 包裹符，用于包含有空格或逗号的字符串
  LINES TERMINATED BY '\n' -- 换行符
  IGNORE 1 LINES           -- 忽略第一行的 CSV 表头
  (字段1, 字段2, 字段3);     -- 对应映射的表字段列表
  ```
- **安全路径限制**：当系统变量 `secure_file_priv` 开启时，`LOAD DATA INFILE` 只能导入存放在该指定安全目录下的文件，否则会抛出权限拒绝报错。
- **网络导入**：若文件在客户端本地，可使用 `LOAD DATA LOCAL INFILE ...`，由客户端将文件内容以数据流形式通过连接管道上传至服务器并载入。

---

## 🎯 学习目标与验收标准

**学习目标：**
- 掌握 `LOAD DATA` 的核心参数设置（分隔符、包裹符、换行符及表头忽略）。
- 理解 `secure_file_priv` 系统变量的设置边界及对服务器文件安全的防护机理。
- 掌握如何安全处理由于换行符在 Windows (`\r\n`) 与 Linux (`\n`) 环境下差异导致的“最后一列乱码与溢出”隐蔽 Bug。

**验收标准：**
- [ ] 能解释为什么 `LOAD DATA` 旁路加载性能远优于普通的批量 `INSERT`。
- [ ] 能排除因 `secure_file_priv` 限制导致的 `1290 (HY000)` 错误。
- [ ] 能够成功完成练习：将种子用户 CSV 文本文件高速加载进 `users` 表并通过测试脚本。

---

## 📖 概念全景

### 1. LOAD DATA 极速写入的底层原理

在 MySQL 中，`LOAD DATA` 的写入速度通常是批量 `INSERT` 的 **10 倍以上**，更是逐行单事务 `INSERT` 的 **百倍以上**。

```mermaid
flowchart TD
    subgraph InsertPath ["普通 INSERT 写入路径"]
        InsertSql["INSERT SQL 语句"] --> SQLParser["1. 解析器 (语法分析)"]
        SQLParser --> Optimizer["2. 优化器 (生成执行计划)"]
        Optimizer --> ExecuteEngine["3. 执行引擎 (逐行写入)"]
        ExecuteEngine --> LogEngine["4. 日志引擎 (逐行写 Undo/Redo)"]
        LogEngine --> IndexRebuild["5. 逐行更新 B+ 树索引"]
    end

    subgraph LoadDataPath ["LOAD DATA 高速旁路"]
        TextFile["纯文本文件 (CSV)"] --> FastReader["1. 高速文本流式读取器"]
        FastReader --> BufferPack["2. 内存块序列化反序列化"]
        BufferPack --> PageWrite["3. 旁路直接填充 InnoDB 数据页"]
        PageWrite --> LogOnce["4. 批量提交写入 Redo Log"]
        PageWrite --> IndexBulk["5. 批量构建索引分支"]
    end
    
    style InsertPath fill:#fff2cc,stroke:#d6b656,stroke-width:1px
    style LoadDataPath fill:#d5e8d4,stroke:#82b366,stroke-width:1px
```

它之所以快，是因为跳过了以下物理开销：
1. **跳过编译开销**：无需对每行语句进行 SQL 语法解析、词法分析和优化器计划评估。
2. **极大的缓存页连续性**：流式读取器能直接将文本段连续写入 InnoDB 数据缓冲池（Buffer Pool）的新页，大幅减少页面随机分裂。
3. **批量写入开销极低**：它是一个整体大事务，只在全部载入后统一触发一次日志提交。

### 2. secure_file_priv 物理限制

为了防止恶意攻击者通过 SQL 注入调用恶意指令读取系统敏感文件（例如通过 SQL 执行命令去读系统的 `/etc/passwd` 并写入其他表），MySQL 引入了 `secure_file_priv` 只读系统参数。

我们可以通过查询来获知其设定：
```sql
SHOW VARIABLES LIKE 'secure_file_priv';
```

- **情况 A (返回值为具体的物理目录路径，如 `/var/lib/mysql-files/`)**：
  你所使用的 `LOAD DATA INFILE` 中的文件，**必须**事先物理移动到该目录下。否则会抛出报错：
  `ERROR 1290 (HY000): The MySQL server is running with the --secure-file-priv option so it cannot execute this statement`
- **情况 B (返回值为 NULL)**：
  MySQL 被设定为**禁止所有导入导出**，无法运行此命令。
- **情况 C (返回值为空字符串 `""`)**：
  没有路径限制，允许在任何地方读取。但这在生产环境是非常危险的。

---

## 💻 SQL 语法

```sql
LOAD DATA
    [LOW_PRIORITY | CONCURRENT] [LOCAL]
    INFILE 'file_name'
    INTO TABLE tbl_name
    [CHARACTER SET charset_name]
    [{FIELDS | COLUMNS}
        [TERMINATED BY 'string']
        [[OPTIONALLY] ENCLOSED BY 'char']
        [ESCAPED BY 'char']
    ]
    [LINES
        [STARTING BY 'string']
        [TERMINATED BY 'string']
    ]
    [IGNORE number {LINES | ROWS}]
    [(col_name_or_user_var, ...)]
    [SET col_name = expr, ...];
```

### 关键子句与换行符防坑

- **`ENCLOSED BY '"'`**：用来匹配被双引号包裹的字段。例如 CSV 中一行数据是 `1,"Alice, Jr.",99.00`。如果不设包裹符，第二个字段由于含有逗号，会被错误拆分成两列；设定包裹符后，MySQL 会忽略被包裹值内部的逗号。
- **`LINES TERMINATED BY '\n'` (重点避坑)**：
  - 如果文件是从 Windows 系统编辑导出的，其换行符为 `\r\n` (CRLF)。
  - 如果你的 SQL 写成了 `TERMINATED BY '\n'`，MySQL 在读取时只会去掉 `\n`，而把回车符 `\r` (即 ASCII `\r`) 强行当作数据的一部分保留在最后一列中！
  - **严重后果**：在查询时，你会发现 `WHERE email = 'dev@order.com'` 查不出结果，但 `WHERE email LIKE 'dev@order.com%'` 却能查出。因为库里存储的实际值是 `'dev@order.com\r'`！
  - **避坑对策**：如果数据来自 Windows，必须显式写为：`LINES TERMINATED BY '\r\n'`。

---

## 🛒 订单系统实战

**业务场景：**
运维部门导出了一个包含 1000 个批量注册用户的 CSV 文件 `seed_users.csv`，需要将其高速灌入我们的 `users` 表。为了合规和安全，MySQL 数据库配置了 `secure_file_priv` 为容器内的 `/var/lib/mysql-files/`。

**实战 SQL：**

*首先，在宿主机上把数据文件复制到容器的安全目录下：*
```bash
docker cp seed_users.csv mysql-learn:/var/lib/mysql-files/seed_users.csv
```

*然后，连接数据库执行数据高速载入：*
```sql
LOAD DATA INFILE '/var/lib/mysql-files/seed_users.csv'
INTO TABLE users
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES -- 过滤掉 CSV 的表头 (username,email,password_hash,status)
(username, email, password_hash, status);
```

---

## ⚠️ 常见坑点

- 💣 **坑点 1：本地文件使用 LOCAL 时未开启服务器配置**
  * **现象**：在客户端运行 `LOAD DATA LOCAL INFILE ...` 时报错：
    `ERROR 2068 (HY000): LOAD DATA LOCAL INFILE file request rejected due to restrictions on access.`
  * **原因**：出于客户端文件上传的安全性，MySQL 默认在服务器端和客户端同时禁用了 `local_infile` 配置。
  * **对策**：
    1. 服务器端开启变量：`SET GLOBAL local_infile = 1;`。
    2. 客户端连接时，命令行加上 `--local-infile=1` 参数（例如 `mysql --local-infile=1 -u root ...`）。

- 💣 **坑点 2：忽略列映射顺序导致数据错配错乱**
  * **现象**：CSV 中列顺序是 `(email, username)`，但直接运行 `LOAD DATA` 时未在末尾指定映射字段列表。
  * **原因**：如果没有在 SQL 语句末尾显式写上映射的列名列表，MySQL 会粗暴地按照表定义的物理列顺序从左到右依次对应，这极易导致列值错位（如将 email 写入了 username 字段）。
  * **对策**：始终在 SQL 末尾加上字段对应列表，即：`(username, email, password_hash, status)`。

---

## 🧠 主动回忆

请在不看上文的情况下，尝试回答以下问题：

1. 如果你正在连接一个位于远程云端的 MySQL 数据库，并且要将你电脑本地桌面上的一份 CSV 导入。你是否可以使用普通的 `LOAD DATA INFILE 'C:/Desktop/data.csv' ...` 进行导入？为什么？该怎么处理？
   - *答案：不行。普通的 `LOAD DATA INFILE` 会让 MySQL 服务端在它自己的本地磁盘文件系统中去寻找 `C:/Desktop/data.csv`，云端服务器是无法读取你个人电脑的磁盘的。应当改用 `LOAD DATA LOCAL INFILE ...`，并开启客户端及服务器的 `local_infile` 参数，这会让客户端把本地文件解析并封装为数据包通过网络发送给服务端执行。*
2. 为什么 `secure_file_priv` 被设定为 `NULL` 时不能使用 `LOAD DATA INFILE`？它限制的是服务器上的文件还是客户端上的文件？
   - *答案：当该参数为 `NULL` 时，MySQL 物理禁用了所有的服务端导入导出文件流。它限制的是 MySQL 服务端进程在服务器系统文件中的读取和写入。若使用 `LOAD DATA LOCAL INFILE` 导入客户端文件，通常不受此系统变量的影响，因为它是客户端主动发送流，而非服务端发起的文件系统读取。*

---

## 🧭 进阶路线提示

| 后续章节 | 会继续解决什么问题 |
|---|---|
| [05.03 用户权限与安全] | 探讨在安全审计中，如何严格收回普通用户的 `FILE` 权限，以防止利用 `LOAD DATA` 进行敏感文件越权读取。 |

---

## ✅ 项目练习

去 `exercises/03.03.04-load-data-csv` 目录下，完成你的第一个 CSV 高速载入实操任务！

**任务描述：**
1. 练习目录下预置了一个种子用户文本文件 `seed_data.csv`。为了兼容 Docker 容器内的路径访问安全，`test.sh` 脚本在运行前会自动将该文件复制到容器的唯一安全路径 `/var/lib/mysql-files/seed_data.csv` 下。
2. 请在 `exercise.sql` 中编写 `LOAD DATA INFILE` 语句，将 `/var/lib/mysql-files/seed_data.csv` 中的数据导入到 `users` 表中。
3. 表头第一行需要忽略，各个列映射顺序请参看 `seed_data.csv` 里的表头列名。数据文本格式使用逗号隔开，无双引号包裹。

**运行验证：**
在终端进入该练习目录，执行自动化测试脚本：
```bash
bash test.sh
```
