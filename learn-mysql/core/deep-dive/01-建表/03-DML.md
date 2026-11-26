<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [核心操作](#%E6%A0%B8%E5%BF%83%E6%93%8D%E4%BD%9C)
- [INSERT（插入数据）](#insert%E6%8F%92%E5%85%A5%E6%95%B0%E6%8D%AE)
  - [1. 基础插入（单行与批量插入）](#1-%E5%9F%BA%E7%A1%80%E6%8F%92%E5%85%A5%E5%8D%95%E8%A1%8C%E4%B8%8E%E6%89%B9%E9%87%8F%E6%8F%92%E5%85%A5)
  - [2. 表达式/查询插入（INSERT INTO ... SELECT）](#2-%E8%A1%A8%E8%BE%BE%E5%BC%8F%E6%9F%A5%E8%AF%A2%E6%8F%92%E5%85%A5insert-into--select)
  - [3. 存在即更新（INSERT ... ON DUPLICATE KEY UPDATE）](#3-%E5%AD%98%E5%9C%A8%E5%8D%B3%E6%9B%B4%E6%96%B0insert--on-duplicate-key-update)
- [UPDATE（更新数据）](#update%E6%9B%B4%E6%96%B0%E6%95%B0%E6%8D%AE)
  - [1. 单表条件更新](#1-%E5%8D%95%E8%A1%A8%E6%9D%A1%E4%BB%B6%E6%9B%B4%E6%96%B0)
  - [2. 多表关联更新（Multi-table Update）](#2-%E5%A4%9A%E8%A1%A8%E5%85%B3%E8%81%94%E6%9B%B4%E6%96%B0multi-table-update)
- [DELETE（删除数据）](#delete%E5%88%A0%E9%99%A4%E6%95%B0%E6%8D%AE)
  - [1. 单表条件删除](#1-%E5%8D%95%E8%A1%A8%E6%9D%A1%E4%BB%B6%E5%88%A0%E9%99%A4)
  - [2. 多表关联删除（Multi-table Delete）](#2-%E5%A4%9A%E8%A1%A8%E5%85%B3%E8%81%94%E5%88%A0%E9%99%A4multi-table-delete)
  - [3. 带排序与截取的删除（ORDER BY ... LIMIT）](#3-%E5%B8%A6%E6%8E%92%E5%BA%8F%E4%B8%8E%E6%88%AA%E5%8F%96%E7%9A%84%E5%88%A0%E9%99%A4order-by--limit)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

DML（Data Manipulation Language，数据操作语言） 是 SQL 中专门用来对数据库表中的数据记录进行增、删、改的指令集合。

DML 操作的是容器内部的具体数据。在 MySQL（InnoDB 存储引擎）中，DML 操作默认受事务（Transaction）管辖，会写入 Undo Log（用于回滚）和 Redo Log（用于持久化），支持撤销（ROLLBACK）与提交（COMMIT）。

DML 核心只有三大动作关键字：INSERT（插入）、UPDATE（更新）、DELETE（删除）。

# 核心操作
```
                          ┌── 1. 单行/多行批量插入 (INSERT INTO ... VALUES)
                          ├── 2. 查询插入 (INSERT INTO ... SELECT)
├── INSERT (插入) ──────── ┤
│                         └── 3. 存在即更新 (INSERT ... ON DUPLICATE KEY UPDATE)
│
├── UPDATE (更新) ─────────┬── 1. 单表条件更新 (UPDATE ... SET ... WHERE)
│                          └── 2. 多表关联更新 (UPDATE t1 JOIN t2 SET ...)
│
└── DELETE (删除) ─────────┬── 1. 单表条件删除 (DELETE FROM ... WHERE)
                           └── 2. 多表关联删除 (DELETE t1 FROM t1 JOIN t2 ...)
```

# INSERT（插入数据）
## 1. 基础插入（单行与批量插入）
```sql
-- 单行插入（指定字段）
INSERT INTO temp_products_preview (spu_no, price, product_type) 
VALUES ('SPU2026001', 99.00, 'PHYSICAL');

-- 批量插入（推荐！比单条循环插入性能快几十倍，大幅减少网络 RTT 和事务提交开销）
INSERT INTO temp_products_preview (spu_no, price, product_type) 
VALUES 
    ('SPU2026002', 199.00, 'PHYSICAL'),
    ('SPU2026003', 299.00, 'DIGITAL'),
    ('SPU2026004', 399.00, 'PHYSICAL');
```

## 2. 表达式/查询插入（INSERT INTO ... SELECT）
```sql
INSERT INTO products_archive (id, spu_no, price, created_at)
SELECT id, spu_no, price, created_at 
FROM temp_products_preview 
WHERE status = 'DELETED';
```

## 3. 存在即更新（INSERT ... ON DUPLICATE KEY UPDATE）
在插入数据时，如果触发了主键（PRIMARY KEY）或唯一索引（UNIQUE KEY）冲突，自动转换为 UPDATE 操作。在做数据同步、高并发计数器时极其常用。

```sql
INSERT INTO product_stats (spu_no, view_count, sales_count)
VALUES ('SPU2026001', 1, 1)
ON DUPLICATE KEY UPDATE 
    view_count = view_count + 1,            -- 冲突时：访问量 +1
    sales_count = sales_count + VALUES(sales_count);
```

# UPDATE（更新数据）
## 1. 单表条件更新
```SQL
UPDATE temp_products_preview 
SET price = 129.00, 
    status = 'ON_SALE',
    updated_at = NOW()
WHERE spu_no = 'SPU2026001' AND is_deleted = 0;
```

## 2. 多表关联更新（Multi-table Update）
当更新条件需要依赖另一张关联表的数据时，可以使用 JOIN 进行联合更新（避免写极慢的相关子查询）。
```sql
-- 例子：将“VIP商家”旗下所有商品的价格打 9 折
UPDATE temp_products_preview p
INNER JOIN merchants m ON p.merchant_id = m.id
SET p.price = p.price * 0.9
WHERE m.merchant_level = 'VIP';
```

# DELETE（删除数据）

```text
                            ┌── 1. 物理删除 (DELETE FROM ... WHERE)
                            ├── 2. 逻辑删除 (UPDATE ... SET is_deleted = 1)
┌── DML 显式操作 ──────────── ┼── 3. 分批删除 (DELETE, ORDER BY,  LIMIT)
│                           └── 4. 关联删除 (DELETE t1 FROM t1 JOIN t2 ...)
│
└── DDL 外键定义的物理级联触发 ──┬── CASCADE  (自动级联物理清理)
                               ├── SET NULL (解除关联，设为 NULL)
                               └── RESTRICT (严格拦截，拒绝删除父表)
```

## 1. 单表条件删除
```SQL
DELETE FROM temp_products_preview 
WHERE status = 'OFFLINE' AND updated_at < '2026-01-01 00:00:00';
```

## 2. 多表关联删除（Multi-table Delete）
根据多表联查的结果，精准删除某一张表（或两张表）中的对应记录。
```sql
-- 例子：删除所有“未激活用户”的“未支付订单”
DELETE o 
FROM orders o
INNER JOIN users u ON o.user_id = u.id
WHERE u.status = 'UNVERIFIED' AND o.pay_status = 'UNPAID';
```

## 3. 带排序与截取的删除（ORDER BY ... LIMIT）
在清理大表无用数据时，为了防止一次性锁定的数据量太大引发事故，通常加上 LIMIT 批量分段删除：
```sql
-- 每次只删除最老的前 1000 条废弃日志，循环执行
DELETE FROM sys_logs 
WHERE created_at < '2026-01-01' 
ORDER BY id ASC 
LIMIT 1000;
```

