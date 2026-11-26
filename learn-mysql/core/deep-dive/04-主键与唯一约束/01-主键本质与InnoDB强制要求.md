<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [主键本质与 InnoDB 强制要求](#%E4%B8%BB%E9%94%AE%E6%9C%AC%E8%B4%A8%E4%B8%8E-innodb-%E5%BC%BA%E5%88%B6%E8%A6%81%E6%B1%82)
  - [主键的定义](#%E4%B8%BB%E9%94%AE%E7%9A%84%E5%AE%9A%E4%B9%89)
  - [1. 任何表都需要主键](#1-%E4%BB%BB%E4%BD%95%E8%A1%A8%E9%83%BD%E9%9C%80%E8%A6%81%E4%B8%BB%E9%94%AE)
  - [2. 不指定主键时 InnoDB 的 DB_ROW_ID 替代策略](#2-%E4%B8%8D%E6%8C%87%E5%AE%9A%E4%B8%BB%E9%94%AE%E6%97%B6-innodb-%E7%9A%84-db_row_id-%E6%9B%BF%E4%BB%A3%E7%AD%96%E7%95%A5)
  - [3. 没有主键导致 `dict_sys->mutex` 全局锁竞争](#3-%E6%B2%A1%E6%9C%89%E4%B8%BB%E9%94%AE%E5%AF%BC%E8%87%B4-dict_sys-mutex-%E5%85%A8%E5%B1%80%E9%94%81%E7%AB%9E%E4%BA%89)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# 主键本质与 InnoDB 强制要求

## 主键的定义

**主键**是每一行数据的**唯一标识符**。
- **唯一性**：表中任意两行的主键值绝不相同。
- **不可空**：主键绝对不能是空值（NULL）。
- **不可变性**：一旦分配，通常不应再修改。

*(底层提示：在 InnoDB 引擎中，主键不仅仅是标识，整张表的数据在磁盘上就是**按照主键顺序物理排列**的。这被称为"聚簇索引"。)*

## 1. 任何表都需要主键

在 MySQL 最常用的 InnoDB 存储引擎中，数据并不是随便扔在硬盘上的，而是强制和主键绑定在一起，形成一棵 B+ 树（这叫聚簇索引）。 如果你建表时不给它定主键：

- InnoDB 就会去表里找有没有 UNIQUE 且 NOT NULL 的列来顶替。

- 如果连这个也没有，InnoDB 会在底层偷偷为你生成一个不可见的、6 字节长的隐藏列（Row ID）来做主键。这不仅会带来额外的性能损耗，而且在高并发插入时极易产生全局锁冲突。

结论：与其让底层悄悄搞小动作，不如我们把主动权握在手里，必须显式声明主键。

## 2. 不指定主键时 InnoDB 的 DB_ROW_ID 替代策略

当一张表没有显式主键、也没有任何 UNIQUE NOT NULL 列时，InnoDB 会启用内部的 `DB_ROW_ID` 机制：

1. **隐藏列**：InnoDB 自动为每行添加一个 6 字节的 `DB_ROW_ID` 隐藏列作为聚簇索引的 Key。
2. **全局计数器**：这个 Row ID 并非每张表独立计数，而是来自 InnoDB 全局的 `dict_sys->row_id` 计数器。所有没有主键的表共享同一个自增源。
3. **不可见**：你在 `SELECT *` 中看不到它，也无法在 SQL 中引用它。这意味着你**彻底丧失了对数据唯一标识的控制权**。
4. **上限风险**：`DB_ROW_ID` 是 6 字节无符号整数，上限为 2^48（约 281 万亿行）。虽然极端场景下才会触及，但由于全局共享，多张无主键表并发插入会加速消耗。

## 3. 没有主键导致 `dict_sys->mutex` 全局锁竞争

这是最致命的性能问题：

- InnoDB 分配 `DB_ROW_ID` 时，需要对全局数据字典互斥锁 `dict_sys->mutex` 加锁。
- 这把锁**不是表级别的，而是整个 InnoDB 实例级别的**。
- 在高并发 INSERT 场景下，所有没有主键的表都在争抢同一把锁来递增 Row ID，形成严重的串行化瓶颈。

**吞吐量断崖现象**：当多个线程同时向无主键表执行 INSERT 时，TPS（Transactions Per Second）会随并发数增加而急剧下降，而非线性增长。这是因为线程在 `dict_sys->mutex` 上排队等待，CPU 空转在锁竞争而非实际写入上。

> **铁律**：任何表都必须显式声明主键，绝不依赖 InnoDB 的隐式 `DB_ROW_ID`。
