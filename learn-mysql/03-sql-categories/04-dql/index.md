# 模块 03.04: DQL — 数据查询语言

> **模块定位**：本模块聚合完整的基础查询能力，从单表过滤逐步进入函数、聚合、分页、多表连接和基础子查询，形成完整的 `SELECT` 心智模型。

## 🎯 知识边界与生态位

**本模块覆盖**：
- `SELECT` 字段投影与 `AS` 别名定义。
- `WHERE` 条件过滤（包括比较算子 `=`, `<>`, `<`, `>`, `BETWEEN AND`, `IN`）。
- 逻辑运算符 `AND`、`OR`、`NOT` 的组合逻辑与短路求值直觉。
- `LIKE` 模糊匹配、`REGEXP` 正则匹配基础。
- 深入底层探讨 SQL 的三值逻辑（`TRUE` / `FALSE` / `UNKNOWN`）以及由 `NULL` 引起的高危逻辑陷阱。
- 标量函数、控制流与 JSON 查询表达式。
- 聚合、分组、排序、分页和多表连接。
- 标量、列、行与表子查询基础。

**本模块不覆盖**：
- 相关子查询优化、CTE、集合操作和窗口函数（将在模块 04.04 展开）。
- 索引的物理结构与执行计划分析（将在模块 04.01 展开）。

## [DQL的核心原理](./core.md)

## 📚 本模块结构

| 小节 | 文件 | 状态 | 核心说明 |
|------|------|------|----------|
| 03.04.00. 基础查询与过滤 | [00-select-basics.md](./00-select-basics.md) | ✅已通关 | 掌握最基本的 `SELECT` 与 `WHERE` 条件，学会用逻辑运算符组合过滤条件。 |
| 03.04.01. 字符串匹配与空值 | [01-string-null.md](./01-string-null.md) | 📝已生成 | 学习 `LIKE`、`REGEXP` 正则匹配以及处理 MySQL 中的 `NULL` 值检索。 |
| 03.04.02. 谓词、三值逻辑与 NULL 陷阱 | [02-predicates-null.md](./02-predicates-null.md) | ✅已通关 | 深入理解三值逻辑，规避 `NOT IN` 子查询包含 `NULL` 等高危逻辑陷阱。 |
| 03.04.03. 标量函数 | [03-scalar-funcs.md](./03-scalar-funcs.md) | ✅已通关 | 字符串、数值和日期函数。 |
| 03.04.04. 控制流与转换 | [04-control-flow.md](./04-control-flow.md) | ✅已通关 | `CASE`、`IF`、`COALESCE` 与类型转换。 |
| 03.04.05. JSON 函数基础 | [05-json-functions-basic.md](./05-json-functions-basic.md) | 📝已生成 | JSON 提取、修改与包含判断。 |
| 03.04.06. 内连接 | [06-inner-join.md](./06-inner-join.md) | ✅已通关 | 笛卡尔积、`INNER JOIN` 与连接条件。 |
| 03.04.07. 外连接 | [07-outer-join.md](./07-outer-join.md) | ✅已通关 | `LEFT JOIN`、`RIGHT JOIN` 与 NULL 过滤。 |
| 03.04.08. 自连接与层级关系 | [08-self-join.md](./08-self-join.md) | ✅已通关 | 使用 Self Join 表达有限层级关系。 |
| 03.04.09. 聚合函数与分组 | [09-group-by.md](./09-group-by.md) | ✅已通关 | 聚合函数、`GROUP BY` 与 `HAVING`。 |
| 03.04.10. 高级分组特性 | [10-advanced-grouping.md](./10-advanced-grouping.md) | ✅已通关 | `GROUP_CONCAT` 与 `WITH ROLLUP`。 |
| 03.04.11. 排序、限制与分页 | [11-order-limit-pagination.md](./11-order-limit-pagination.md) | ✅已通关 | `ORDER BY`、`LIMIT/OFFSET` 与深度分页风险。 |
| 03.04.12. 基础子查询 | [12-basic-subqueries.md](./12-basic-subqueries.md) | ✅已通关 | 标量、列、行与表子查询。 |

## 🗺️ 完整知识地图 (Knowledge Map)

> 从架构师的视角，重新梳理本章知识点的因果关系。

| 核心知识点 | 本质/语法 | 架构师视角 (Why & When) | 学习位置 |
|------------|-----------|-------------------------|----------|
| **字段投影 (Projection)** | `SELECT col1, col2` | 限制返回的数据宽度，降低网络 I/O。杜绝 `SELECT *` 避免未来表结构变更引入的不确定性。 | 03.04.00 |
| **AS 别名 (Alias)** | `col AS alias_name` | 对外部应用程序和聚合层隐藏数据库物理字段命名，提升面向消费端契约的灵活性。 | 03.04.00 |
| **WHERE 逻辑组合** | `WHERE cond1 AND cond2` | 学会依据过滤效果将强过滤条件前置，利用数据库执行引擎的“短路直觉”提升效率。 | 03.04.00 |
| **模糊匹配与索引限制** | `LIKE 'abc%'` | 前缀模糊匹配可以利用 B+树索引，而后置模糊匹配（`%abc`）会导致全表扫描。 | 03.04.01 |
| **三值逻辑 (3VL)** | `TRUE / FALSE / UNKNOWN` | SQL 中任何与 `NULL` 的比较都会返回 `UNKNOWN`。在逻辑判定中必须注意它对布尔上下文的污染。 | 03.04.02 |
| **NOT IN 陷阱** | `NOT IN (..., NULL)` | 当集合中包含 `NULL` 时，`NOT IN` 判定永远返回 `UNKNOWN`，进而导致整条 SQL 无法返回任何数据。 | 03.04.02 |
| **标量函数** | `CONCAT` / `ROUND` / `DATE_FORMAT` | 对每行独立加工展示和计算字段；过滤索引列时应避免用函数包裹列。 | 03.04.03 |
| **控制流与转换** | `CASE` / `COALESCE` / `CAST` | 明确表达状态映射、空值回退和类型边界，避免隐式转换污染结果。 | 03.04.04 |
| **JSON 查询表达式** | `->>` / `JSON_CONTAINS` / `JSON_SET` | 在保留扩展属性灵活性的同时，明确路径、返回类型和索引边界。 | 03.04.05 |
| **内连接** | `INNER JOIN ... ON` | 通过关系键组合规范化数据，并警惕基数放大与笛卡尔积。 | 03.04.06 |
| **外连接** | `LEFT JOIN ... ON` | 保留缺失关系，明确 NULL 扩展行以及 `ON`/`WHERE` 的语义边界。 | 03.04.07 |
| **自连接** | 同表多别名 Join | 用角色别名表达父子关系，明确固定层级与 Recursive CTE 的能力边界。 | 03.04.08 |
| **聚合与分组** | `COUNT/SUM/AVG/MIN/MAX` | 明确结果粒度、NULL 语义、`WHERE/HAVING` 边界和大表聚合成本。 | 03.04.09 |
| **高级分组** | `GROUP_CONCAT` / `WITH ROLLUP` | 在单次查询中生成组内清单与汇总行，同时控制长度、排序和报表边界。 | 03.04.10 |
| **排序与分页** | `ORDER BY` / `LIMIT` / `OFFSET` | 以唯一 Tie-breaker 建立稳定顺序，控制返回规模，并识别深度分页扫描成本。 | 03.04.11 |
| **基础子查询** | 标量 / 列 / 行 / 表子查询 | 按结果形状选择比较语义，组合两阶段查询，并识别基数、NULL 与相关执行成本。 | 03.04.12 |

## ⚡ 速查与避坑指南 (Cheat Sheet)

> 快速查阅本章最常用的命令、最佳实践或最容易踩坑的设定。

| 场景/操作 | 最佳实践 / 核心命令 | ⚠️ 常见避坑提示 |
|-----------|--------------------|----------------|
| **安全过滤空值** | `WHERE email IS NULL` | 绝不能写成 `WHERE email = NULL`，这会永远返回空集。 |
| **值区间匹配** | `WHERE id BETWEEN 10 AND 50` | 记住 `BETWEEN AND` 是闭区间（包含边界值本身）。 |
| **多值集合过滤** | `WHERE status IN (1, 2, 3)` | 尽量保持集合元素数量在合理区间（如百级以内），避免过长的 `IN` 列表撑爆解析树。 |
| **否定多值过滤** | `WHERE status NOT IN (1, 2)` | 必须保证列表里的每个元素都不为 `NULL`，若有 `NULL` 推荐使用 `NOT EXISTS` 或 `LEFT JOIN` 代替。 |
