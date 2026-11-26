# DQL — 数据查询语言 / 高级分组特性

> **故事线与承上启下**：
> 上一节已经能按状态计算数量和金额。实际报表还会要求“每组包含哪些订单”以及“同一结果中附带总计”，这分别由 `GROUP_CONCAT` 和 `WITH ROLLUP` 解决。

## ⚡ 速查摘要

- `GROUP_CONCAT` 将组内多行值拼成字符串，支持 `DISTINCT`、内部 `ORDER BY` 和 `SEPARATOR`。
- `GROUP_CONCAT` 输出受 `group_concat_max_len` 限制，不能承载无限明细。
- `WITH ROLLUP` 按分组层级追加小计和总计行，汇总行的分组键通常为 `NULL`。
- 汇总行的 `NULL` 是结果标记，不一定代表源数据为空；可用 `GROUPING()` 精确识别。
- OLTP 接口不应实时生成超大报表；复杂汇总应限制范围或异步化。

---

## 🎯 学习目标与验收标准

**学习目标：**

- 掌握 `GROUP_CONCAT` 的去重、排序和分隔符。
- 理解 `group_concat_max_len` 截断边界。
- 掌握 `GROUP BY ... WITH ROLLUP` 的汇总层级。
- 能识别并标记 ROLLUP 产生的总计行。
- 能评估高级聚合在订单报表中的性能边界。

**验收标准：**

- [ ] 能按状态拼接稳定排序的订单号。
- [ ] 能在同一结果中返回各状态行和总计行。
- [ ] 能解释汇总行分组键为何为 `NULL`。
- [ ] 能独立完成 `exercises/03.04.10-advanced-grouping` 并通过测试。

---

## 📖 概念全景

### 1. GROUP_CONCAT：组内行转字符串

```sql
GROUP_CONCAT(
    [DISTINCT] expression
    ORDER BY expression
    SEPARATOR ','
)
```

它在每个分组内部执行：

```mermaid
flowchart LR
    A["同一状态的订单行"] --> B["提取 order_no"]
    B --> C["可选 DISTINCT"]
    C --> D["组内 ORDER BY"]
    D --> E["按 SEPARATOR 拼接"]
```

排序必须写在 `GROUP_CONCAT` 内部。查询末尾的 `ORDER BY` 只能排序结果行，不能保证拼接值的内部顺序。

```sql
GROUP_CONCAT(order_no ORDER BY order_no SEPARATOR ',')
```

### 2. 长度与类型边界

`GROUP_CONCAT` 结果受会话变量 `group_concat_max_len` 限制：

```sql
SHOW VARIABLES LIKE 'group_concat_max_len';
SET SESSION group_concat_max_len = 8192;
```

超过上限时结果会被截断并产生 warning。生产查询必须估算组内数量和字符串长度，不能把它当成无限数组聚合。接口需要结构化数组时，优先考虑 `JSON_ARRAYAGG`，但它同样存在内存和网络成本。

### 3. WITH ROLLUP：分层汇总

```sql
SELECT status, COUNT(*), SUM(total_amount)
FROM orders
GROUP BY status WITH ROLLUP;
```

普通分组返回每个状态一行；`WITH ROLLUP` 再追加一行总计。多列分组时，会沿分组键从右向左逐层产生小计：

```text
GROUP BY year, month WITH ROLLUP
→ 年月明细
→ 每年小计 month = NULL
→ 全部总计 year = NULL, month = NULL
```

### 4. 汇总 NULL 与真实 NULL

简单场景可写：

```sql
COALESCE(CAST(status AS CHAR), 'ALL') AS status_label
```

但如果源分组键本身允许 `NULL`，`COALESCE` 无法区分“真实 NULL 分组”和“ROLLUP 汇总行”。MySQL 8 可使用：

```sql
IF(GROUPING(status) = 1, 'ALL', COALESCE(status, 'UNKNOWN'))
```

`GROUPING(status) = 1` 表示该 NULL 由 ROLLUP 生成。

### 5. ROLLUP 与排序

ROLLUP 行由分组层级决定。不要依赖未声明的自然顺序构建 API 契约；如果需要复杂展示顺序，可将聚合结果包在派生表中再排序。注意 MySQL 对 `WITH ROLLUP` 与同层 `ORDER BY` 的组合有语法和语义限制。

### 6. 报表边界

`GROUP_CONCAT` 和 `ROLLUP` 都可能扩大单个查询的 CPU、内存和返回体积：

- 组内订单号过多会构造超长字符串。
- ROLLUP 增加汇总计算与结果行。
- 大范围订单扫描会占用 Buffer Pool 和临时空间。
- 在线接口同步生成多年报表会放大尾延迟。

建议限定时间范围、分组基数与最大返回长度。复杂报表使用异步任务、汇总表或 OLAP。

---

## 💻 SQL 语法

```sql
SELECT
    group_key,
    COUNT(*) AS row_count,
    GROUP_CONCAT(value ORDER BY value SEPARATOR ',') AS values_text,
    SUM(amount) AS total_amount
FROM table_name
GROUP BY group_key WITH ROLLUP;
```

---

## 🛒 订单系统实战

**业务场景：**

运营报表需要按订单状态展示订单号清单、订单数和总金额，并在末尾附加所有状态的总计。

```sql
SELECT
    COALESCE(CAST(status AS CHAR), 'ALL') AS status_label,
    COUNT(*) AS order_count,
    GROUP_CONCAT(order_no ORDER BY order_no SEPARATOR ',') AS order_nos,
    SUM(total_amount) AS total_amount
FROM orders
GROUP BY status WITH ROLLUP;
```

`CAST` 将 ENUM 分组键转为字符类型，使 `COALESCE` 的结果类型稳定；总计行显示为 `ALL`。

---

## ⚠️ 常见坑点

- 💣 **拼接结果顺序不稳定**：排序必须写在 `GROUP_CONCAT(... ORDER BY ...)` 内。
- 💣 **静默截断**：检查并合理设置 `group_concat_max_len`，不要无限提高。
- 💣 **把汇总 NULL 当源数据 NULL**：源列可空时使用 `GROUPING()`。
- 💣 **同步生成超大报表**：限定时间范围，必要时异步化。

---

## 🧠 主动回忆

1. 查询末尾 `ORDER BY` 为什么不能保证 `GROUP_CONCAT` 内部顺序？
2. `WITH ROLLUP` 的总计行为什么会出现 NULL 分组键？
3. 何时必须用 `GROUPING()`，不能只用 `COALESCE`？

## 🧭 进阶路线提示

| 后续章节 | 会继续解决什么问题 |
|---|---|
| 04.01 索引基础与查询计划 | 查看聚合是否产生临时表和排序。 |
| 04.04 高级查询表达 | 使用窗口函数计算小计、累计值和排名。 |

---

## ✅ 项目练习

去 `exercises/03.04.10-advanced-grouping`，生成带订单号清单和总计行的状态报表。

```bash
bash test.sh
```

---

## 🚀 延伸学习

- [选读] MySQL Reference Manual：GROUP_CONCAT、GROUP BY Modifiers、GROUPING。
