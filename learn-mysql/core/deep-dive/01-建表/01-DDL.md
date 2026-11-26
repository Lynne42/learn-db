<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [常见操作](#%E5%B8%B8%E8%A7%81%E6%93%8D%E4%BD%9C)
- [库操作](#%E5%BA%93%E6%93%8D%E4%BD%9C)
- [表操作](#%E8%A1%A8%E6%93%8D%E4%BD%9C)
  - [创建表](#%E5%88%9B%E5%BB%BA%E8%A1%A8)
    - [方式1：全新创建表](#%E6%96%B9%E5%BC%8F1%E5%85%A8%E6%96%B0%E5%88%9B%E5%BB%BA%E8%A1%A8)
    - [方式2： 根据已有的表创建](#%E6%96%B9%E5%BC%8F2-%E6%A0%B9%E6%8D%AE%E5%B7%B2%E6%9C%89%E7%9A%84%E8%A1%A8%E5%88%9B%E5%BB%BA)
- [修改表](#%E4%BF%AE%E6%94%B9%E8%A1%A8)
- [删除与清空表（DROP vs TRUNCATE）](#%E5%88%A0%E9%99%A4%E4%B8%8E%E6%B8%85%E7%A9%BA%E8%A1%A8drop-vs-truncate)
- [索引（Index）](#%E7%B4%A2%E5%BC%95index)
- [视图、触发器与存储过程](#%E8%A7%86%E5%9B%BE%E8%A7%A6%E5%8F%91%E5%99%A8%E4%B8%8E%E5%AD%98%E5%82%A8%E8%BF%87%E7%A8%8B)
  - [视图](#%E8%A7%86%E5%9B%BE)
  - [触发器（Trigger）& 存储过程/函数（Procedure/Function）](#%E8%A7%A6%E5%8F%91%E5%99%A8trigger-%E5%AD%98%E5%82%A8%E8%BF%87%E7%A8%8B%E5%87%BD%E6%95%B0procedurefunction)
- [指南](#%E6%8C%87%E5%8D%97)
  - [DROP vs TRUNCATE vs DELETE 区别](#drop-vs-truncate-vs-delete-%E5%8C%BA%E5%88%AB)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# 常见操作
关键字 | 动作语义 | 物理影响 | 
-- | -- | -- |
CREATE | 创建对象 | 在磁盘生成新的元数据及物理存储文件 | 
ALTER | 修改对象结构 | 变更元数据，严重时会引发底层 B+ 树数据页重构（锁表/DDL重建） | 
DROP | 销毁对象 | 直接删除元数据及磁盘数据文件，不可撤销/不可回滚 | 
TRUNCATE | 清空表数据 | 物理清空表空间并重置自增主键（比 DELETE 快百倍，但不可回滚） | 

# 库操作
```sql
-- 1. 创建数据库（建议无条件带上 utf8mb4 字符集）
CREATE DATABASE IF NOT EXISTS my_project_db 
DEFAULT CHARACTER SET utf8mb4 
DEFAULT COLLATE utf8mb4_0900_ai_ci;

-- 2. 修改数据库字符集/排序规则
ALTER DATABASE my_project_db CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- 3. 删除数据库（高危！连同目录下所有表物理文件一并删除）
DROP DATABASE IF EXISTS my_project_db;
```

# 表操作

- **创建数据库**：`CREATE DATABASE IF NOT EXISTS <库名> CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;`
- **修改字符编码**：`ALTER DATABASE <库名> CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;`
- **销毁数据库**：`DROP DATABASE IF EXISTS <库名>;`


## 创建表
### 方式1：全新创建表
```sql
-- 创建表并指定基础约束的标准语法
CREATE TABLE IF NOT EXISTS 表名 (
    列名 数据类型 [列约束] COMMENT ['字段描述'],
    ...
    [表约束]
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='表描述';
```
- **核心约束**：
  - `PRIMARY KEY`：主键，唯一标识一行，不允许为 NULL。
  - `NOT NULL`：必填，防止产生空值（NULL）引发的逻辑漏洞。
  - `DEFAULT`：默认值，当插入数据未指定该列时自动填入的值。
  - ENGINE：指定使用的数据库引擎
  - CHARSET： 设置默认使用的字符集

```sql
CREATE TABLE IF NOT EXISTS temp_products_preview (
    id BIGINT UNSIGNED AUTO_INCREMENT COMMENT '主键ID',
    spu_no VARCHAR(32) NOT NULL COMMENT '商品SPU编码',
    price DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT '价格',
    specs JSON DEFAULT NULL COMMENT '规格扩展属性',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_spu_no (spu_no),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='商品预览表';
```

### 方式2： 根据已有的表创建
```sql
-- 通过其他表查询数据作为新的表
CREATE TABLE users_copy 
AS
SELECT id, username
FROM users;
```
根据users表， 使用字段 id, username 创建一个新的表 叫做users_copy，这种创建方式，会通过SELECT查询出来的所有数据一起放到新的表中，也就是说  users_copy 拥有数据


```sql
-- 通过其他表查找字段， 通过WHERE过滤数据，由于 WHERE 1 > 2 永远不为TRUE， 素以这种写法最终创建的只有表结构，不包含表数据
CREATE TABLE users_copy 
AS
SELECT id, username
FROM users
WHERE 1 > 2;
```

# 修改表
- **增加列**：`ALTER TABLE <表名> ADD COLUMN <列名> <类型> [约束];`
- **修改列属性**：`ALTER TABLE <表名> MODIFY COLUMN <列名> <新类型> [新约束];`
- **删除列**：`ALTER TABLE <表名> DROP COLUMN <列名>;`
- **重命名列**：`ALTER TABLE <表名> CHANGE COLUMN <旧名> <新名> <类型> [约束];`
- **重命名表**：`RENAME TABLE <旧表名> TO <新表名>;`
- **虚拟生成列**：`ALTER TABLE <表名> ADD COLUMN <列名> <类型> GENERATED ALWAYS AS (表达式) VIRTUAL;`

```sql
-- 【字段操作】
-- A. 追加新字段
ALTER TABLE temp_products_preview ADD COLUMN status TINYINT NOT NULL DEFAULT 1 COMMENT '状态' AFTER price;
  -- AFTER 表示追加到哪个字段的后面，默认不写AFTER的话，是追加到表的末尾

-- B. 修改字段定义（修改类型、长度、约束等）
ALTER TABLE temp_products_preview MODIFY COLUMN spu_no VARCHAR(64) NOT NULL COMMENT '扩展为64位';

-- C. 重命名并修改字段（Change 可以同时修改字段名和类型）
ALTER TABLE temp_products_preview CHANGE COLUMN price product_price DECIMAL(12,2) NOT NULL;

-- D. 删除字段
ALTER TABLE temp_products_preview DROP COLUMN specs;


-- 【索引操作】
-- E. 添加普通索引 / 唯一索引 / 主键
ALTER TABLE temp_products_preview ADD INDEX idx_status (status);
ALTER TABLE temp_products_preview ADD UNIQUE KEY uk_spu (spu_no);

-- F. 删除索引 / 主键
ALTER TABLE temp_products_preview DROP INDEX idx_status;
ALTER TABLE temp_products_preview DROP PRIMARY KEY;


-- 【表属性修改】
-- G. 修改表名
ALTER TABLE temp_products_preview RENAME TO products;
-- 或直接：
RENAME TABLE temp_products_preview TO products;
```

# 删除与清空表（DROP vs TRUNCATE）
```sql
-- 清空表数据（物理重建表空间，重置 AUTO_INCREMENT，不走事务日志，极快）
TRUNCATE TABLE temp_products_preview;

-- 销毁整张表（表结构与数据一并从磁盘抹去）
DROP TABLE IF EXISTS temp_products_preview;
```


# 索引（Index）
```sql
-- 1. 创建索引（普通索引 / 联合索引 / 唯一索引）
CREATE INDEX idx_merchant_status ON products (merchant_id, status);
CREATE UNIQUE INDEX uk_order_no ON orders (order_no);

-- 2. 删除索引
DROP INDEX idx_merchant_status ON products;
```

# 视图、触发器与存储过程

## 视图
```sql
-- 创建 / 覆盖视图
CREATE OR REPLACE VIEW v_active_products AS
SELECT id, spu_no, price FROM products WHERE status = 1;

-- 删除视图
DROP VIEW IF EXISTS v_active_products;
```

## 触发器（Trigger）& 存储过程/函数（Procedure/Function）
```sql
-- 创建与删除触发器
CREATE TRIGGER trg_before_insert_orders ... ;
DROP TRIGGER IF EXISTS trg_before_insert_orders;

-- 创建与删除存储过程
CREATE PROCEDURE proc_monthly_settlement() BEGIN ... END;
DROP PROCEDURE IF EXISTS proc_monthly_settlement;
```

# 指南
## DROP vs TRUNCATE vs DELETE 区别
操作 | 语言类型 | 执行逻辑 | 能否回滚 | 自增主键 | 性能 | 
--  |  --  | -- | -- | -- | -- | 
DELETE FROM t | DML | 逐行删除数据，向 Redo/Undo 日志写入大量记录 | 能（处于事务中时） | 不重置 | 极慢（大表易打爆日志） | 
TRUNCATE t | DDL | 物理直接销毁并重新创建一个全新的空表文件（Segment） | 不能 | 重置为 1 | 极快（毫秒级） | 
DROP TABLE t | DDL | 从元数据中注销，并直接将表文件从磁盘删除 | 不能 | 直接销毁 | 极快 | 