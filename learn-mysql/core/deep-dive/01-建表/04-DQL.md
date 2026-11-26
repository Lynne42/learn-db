<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [一、 DQL 完整语法骨架与物理执行顺序](#%E4%B8%80-dql-%E5%AE%8C%E6%95%B4%E8%AF%AD%E6%B3%95%E9%AA%A8%E6%9E%B6%E4%B8%8E%E7%89%A9%E7%90%86%E6%89%A7%E8%A1%8C%E9%A1%BA%E5%BA%8F)
- [二、 DQL 操作全景分类](#%E4%BA%8C-dql-%E6%93%8D%E4%BD%9C%E5%85%A8%E6%99%AF%E5%88%86%E7%B1%BB)
- [三、 7 大核心操作详细拆解](#%E4%B8%89-7-%E5%A4%A7%E6%A0%B8%E5%BF%83%E6%93%8D%E4%BD%9C%E8%AF%A6%E7%BB%86%E6%8B%86%E8%A7%A3)
  - [1. 基础条件查询（单表过滤）](#1-%E5%9F%BA%E7%A1%80%E6%9D%A1%E4%BB%B6%E6%9F%A5%E8%AF%A2%E5%8D%95%E8%A1%A8%E8%BF%87%E6%BB%A4)
  - [2. 聚合与分组查询（数据统计）](#2-%E8%81%9A%E5%90%88%E4%B8%8E%E5%88%86%E7%BB%84%E6%9F%A5%E8%AF%A2%E6%95%B0%E6%8D%AE%E7%BB%9F%E8%AE%A1)
  - [3. 多表联查（JOIN 拼表）](#3-%E5%A4%9A%E8%A1%A8%E8%81%94%E6%9F%A5join-%E6%8B%BC%E8%A1%A8)
  - [4. 子查询（嵌套查询）](#4-%E5%AD%90%E6%9F%A5%E8%AF%A2%E5%B5%8C%E5%A5%97%E6%9F%A5%E8%AF%A2)
  - [5. 窗口函数查询（MySQL 8.0+ 杀手锏）](#5-%E7%AA%97%E5%8F%A3%E5%87%BD%E6%95%B0%E6%9F%A5%E8%AF%A2mysql-80-%E6%9D%80%E6%89%8B%E9%94%8F)
  - [6. 集合操作（Set Operations）](#6-%E9%9B%86%E5%90%88%E6%93%8D%E4%BD%9Cset-operations)
  - [7. 排序与分页（结果集裁切）](#7-%E6%8E%92%E5%BA%8F%E4%B8%8E%E5%88%86%E9%A1%B5%E7%BB%93%E6%9E%9C%E9%9B%86%E8%A3%81%E5%88%87)
  - [四、 顶尖开发者的 DQL 避坑军规](#%E5%9B%9B-%E9%A1%B6%E5%B0%96%E5%BC%80%E5%8F%91%E8%80%85%E7%9A%84-dql-%E9%81%BF%E5%9D%91%E5%86%9B%E8%A7%84)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

**DQL（Data Query Language，数据查询语言）** 是 SQL 中最庞大、使用频率最高的部分，其核心职能是：**从数据库中检索数据，且绝对不修改原始数据**。

无论查询多么复杂，所有的 DQL 操作都是围绕其 **7 大核心子句** 的组合展开的。

---

# 一、 DQL 完整语法骨架与物理执行顺序

理解 DQL 的底层，首要前提是区分 **“书写顺序”** 与 **“物理执行顺序”**：

```text
【你书写的语法顺序】                       【数据库物理执行顺序】

1. SELECT [DISTINCT] 字段/表达式           1. FROM         (确定数据源/加载表)
2. FROM 驱动表                             2. ON / JOIN    (多表匹配，构建临时拼表结果)
3. [JOIN 关联表 ON 关联条件]               3. WHERE        (对原始单行数据进行过滤)
4. [WHERE 单行筛选条件]                    4. GROUP BY     (对过滤后的数据进行分组)
5. [GROUP BY 分组字段]                     5. HAVING       (对分组汇总后的聚合结果再次过滤)
6. [HAVING 分组后筛选条件]                 6. SELECT       (提取指定列、计算表达式/窗口函数)
7. [ORDER BY 排序字段 ASC|DESC]            7. DISTINCT     (去重)
8. [LIMIT 偏移量, 条数]                    8. ORDER BY     (对最终结果集进行物理排序)
                                           9. LIMIT        (截取指定条数流式返回)

```

---

# 二、 DQL 操作全景分类

按照业务复杂度和检索目的，DQL 可以划分为以下 **7 大核心操作类型**：

```text
                               ┌── 1. 基础条件查询 (WHERE 过滤、逻辑/模糊匹配)
                               ├── 2. 聚合与分组查询 (GROUP BY, HAVING, ROLLUP)
                               ├── 3. 多表联查 (JOIN: INNER, LEFT, RIGHT, SELF, CROSS)
【DQL 7 大核心查询操作分类】 ───   ├── 4. 子查询 (标量/列/行/表子查询、EXISTS/IN)
                               ├── 5. 窗口函数查询 (Over 组内排名、累计计算)
                               ├── 6. 集合操作 (UNION / UNION ALL 并集)
                               └── 7. 排序与分页 (ORDER BY, LIMIT, Keyset 游标)

```

---

# 三、 7 大核心操作详细拆解

## 1. 基础条件查询（单表过滤）

作用于 `WHERE` 阶段，对原始行进行逐行校验。

* **比较与范围**：`=`, `!=` (`<>`), `>`, `<`, `>=`, `<=`, `BETWEEN ... AND ...`, `IN (...)`
* **空值判断**：`IS NULL`, `IS NOT NULL`
* **逻辑组合**：`AND`, `OR`, `NOT`
* **模糊与正则**：`LIKE '前缀%'`（走索引）, `LIKE '%包含%'`（全表扫描）, `REGEXP`（正则匹配）
* **表达式与函数处理**：`IFNULL()`, `NULLIF()`, `CASE WHEN ... THEN ... ELSE END`, `CAST() / CONVERT()`

---

## 2. 聚合与分组查询（数据统计）

作用于 `GROUP BY` 与 `HAVING` 阶段，将多行数据“多进一出”压缩汇总。

* **基础聚合函数**：`COUNT()`, `SUM()`, `AVG()`, `MAX()`, `MIN()`
* **文本拼接聚合**：`GROUP_CONCAT()`（将分组内的多行文本拼为一个字符串）
* **分组过滤**：`HAVING`（只能作用于分组汇总后的结果，可以使用聚合函数）
* **高级层级汇总**：`WITH ROLLUP`（自动生成部门小计、全公司总计等多层级折叠行）

---

## 3. 多表联查（JOIN 拼表）

将分布在不同规范化表中的数据，通过关联条件“动态缝合”成一张大宽表。

* **内连接（`INNER JOIN`）**：取两表匹配的**交集**。
* **左外连接（`LEFT JOIN`）**：**保留左表全量**，右表匹配不上补 `NULL`（工业级最常用）。
* **右外连接（`RIGHT JOIN`）**：保留右表全量（通常改写为 `LEFT JOIN`）。
* **自连接（`Self JOIN`）**：自己跟自己拼表，用于处理菜单树、上下级架构等树形结构。
* **交叉连接（`CROSS JOIN`）**：无条件拼表，产生**笛卡尔积**。
* **全外连接（`FULL JOIN`）**：取两表并集（MySQL 中通过 `LEFT JOIN ... UNION ... RIGHT JOIN` 实现）。

---

## 4. 子查询（嵌套查询）

把一个 `SELECT` 的结果作为另一个 SQL 的输入来源。

* **按结果形状分类**：
* **标量子查询**（1 行 1 列）：配合 `=`, `>`, `<` 等比较符。
* **列子查询**（N 行 1 列）：配合 `IN`, `NOT IN`, `ANY`, `ALL` 等。
* **行子查询**（1 行 N 列）：配合多元组比较 `(a, b) = (SELECT x, y)`。
* **表/派生表子查询**（N 行 M 列）：放在 `FROM` 后面，**必须强行加别名**。


* **按依赖关系分类（性能分水岭）**：
* **独立子查询**：内层先算一次，外层复用（高效）。
* **相关子查询**（如 `EXISTS`）：外层查一行，内层跑一次（循环 $O(N \times M)$，易引发慢查询）。



---

## 5. 窗口函数查询（MySQL 8.0+ 杀手锏）

在不改变原始行数（不折叠数据）的前提下，实现组内排名、滑动累加等计算。

* **语法**：`函数() OVER (PARTITION BY 分组字段 ORDER BY 排序字段)`
* **排名函数**：
* `ROW_NUMBER()`：连续唯一排名（1, 2, 3, 4）
* `RANK()`：跳跃排名（1, 2, 2, 4）
* `DENSE_RANK()`：连续并行排名（1, 2, 2, 3）


* **偏移函数**：`LAG()`（往前看第 N 行）, `LEAD()`（往后看第 N 行）
* **聚合窗口**：`SUM(amount) OVER (PARTITION BY user_id ORDER BY created_at)`（实现账户累计余额动态计算）

---

## 6. 集合操作（Set Operations）

将多个结构相同的 `SELECT` 语句的结果集横向拼接在一起。

* **`UNION ALL`**：直接拼在一起，**不去重、不排序**（物理性能极高，优先推荐）。
* **`UNION`**：拼接后进行**物理去重并排序**（涉及内存哈希与 CPU 开销）。

---

## 7. 排序与分页（结果集裁切）

作用于 DQL 的最末尾环节，处理前端展示格式。

* **排序（`ORDER BY`）**：`ASC`（升序，默认）, `DESC`（降序）。支持多字段阶梯排序、表达式排序及拼音转换排序 `ORDER BY CONVERT(name USING gbk)`。
* **传统偏移分页（`LIMIT offset, size`）**：简单直观，但在深分页场景（如 `LIMIT 1000000, 20`）下会引发全表/全索引扫描，性能彻底崩溃。
* **高性能键集分页（`Keyset Pagination`）**：通过记录上一页最后一行的唯一键（`WHERE id > last_id LIMIT 20`），借助 B+ 树实现 $O(1)$ 恒定极速 Seek 定位。

---

## 四、 顶尖开发者的 DQL 避坑军规

1. **拒绝 `SELECT ***`：防止破坏覆盖索引（Covering Index）引发二次回表，增加非必要网络与磁盘 I/O。
2. **避免“伪 LEFT JOIN”**：不要写 `LEFT JOIN` 然后在 `WHERE` 里加上被驱动表的非空过滤，这在逻辑上自相矛盾，应直接显式写 `INNER JOIN`。
3. **谨防 `NOT IN` 中的 `NULL` 毒药**：若子查询结果包含 `NULL`，`NOT IN` 将永远返回 0 行，必须改用 `NOT EXISTS` 或过滤 `IS NOT NULL`。
4. **大深度分页用 Keyset 或延迟关联**：解决深度翻页问题，拒绝高位 `OFFSET`。