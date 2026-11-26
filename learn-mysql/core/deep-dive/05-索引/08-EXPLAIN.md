# 是什么
EXPLAIN 是数据库提供的最核心的性能诊断工具（执行计划分析器）。

它的核心职能是：让数据库优化器（Optimizer）展示一条 SQL 语句在底层真实的物理执行路径（Execution Plan），而不真正运行这条 SQL（部分数据库/语法除外）。


1. 诊断索引命中：判断查询到底走的是全表扫描（ALL），还是高效的 B+ 树索引扫描（ref / range / eq_ref）。

2. 分析回表与覆盖索引：看查询是否触发了物理回表，还是直接通过覆盖索引（Using index）一步到位。

3. 识别联查算法与驱动表：在多表 JOIN 时，看清优化器选了哪张表作为驱动表（Outer Table），使用的是嵌套循环（Nested Loop）还是哈希连接（Hash Join）。
4. 定位低效临时表与排序：检查是否产生了极度消耗 CPU 和磁盘 I/O 的文件排序（Using filesort）或磁盘临时表（Using temporary）。

5. 评估扫描行数（Rows）：通过预估扫描的行数，精准判断哪一步产生了 O(N) 的暴涨。

# 分类
EXPLAIN 可以从 分析视角（输出格式）、执行动作（是否真正运行） 以及 关键输出指标（分析维度） 三个维度进行系统化分类：

```text
                               ┌── 1. 基础文本格式 (Traditional Text)
                               ├── 2. 树状图格式 (TREE - MySQL 8.0+)
                 ┌─ 输出格式 ── ┼── 3. JSON 格式 (JSON - 包含物理 Cost 成本计算)
                 │             └── 4. 图形化/可视格式 (Visual Explain)
                 │
                 │             ┌── 1. 预估执行计划 (Standard EXPLAIN - 仅模拟不真实运行)
【EXPLAIN 分类】  ┼─ 物理动作 ────┴── 2. 真实分析执行 (EXPLAIN ANALYZE - 真实运行并统计毫秒级耗时)
                 │
                 │             ┌── 1. 关联类型维度 (type: const, eq_ref, ref, range, ALL)
                 └─ 分析维度 ───┼   2. 键位匹配维度 (possible_keys, key, key_len)
                               └── 3. 额外特征维度 (Extra: Using index, Using filesort...)
                        
```

## 核心输出字段

1. 访问类型（type 列，性能从优到劣）
- system / const：常量级。主键或唯一索引的等值匹配，只读 1 行（最快）。
- eq_ref：多表联查时，驱动表通过主键/唯一索引匹配被驱动表，最多返回 1 行。
- ref：通过非唯一二级索引进行等值匹配（如 WHERE age = 20）。
- range：索引范围扫描（如 WHERE id > 10，BETWEEN，IN）。
- index：全索引扫描（把整个二级索引 B+ 树的叶子页全扫一遍，虽不用回表但依然是 O(N)）。
- ALL：全表扫描（最差）。直接去聚簇索引上从头扫到尾，必须优化！

2. 键位指标（key & key_len 列）
- possible_keys：优化器预测可能用到的候选索引。
- key：实际物理选用的索引。若为 NULL 说明没用索引。
- key_len：用到的索引字节长度。用于精确判断联合索引 (a, b, c) 中到底用到了前几个列。

3. 额外特征（Extra 列，关键物理标记）
- Using index：性能极佳！触发了覆盖索引，无需物理回表。
- Using index condition：触发了索引条件下推（ICP），在存储引擎层做过了过滤。
- Using where：数据到达 Server 层后，又进行了额外的过滤。
- Using filesort：危险信号！ 无法利用索引完成排序，被迫在内存或磁盘中进行了物理排序。
- Using temporary：高危信号！ 数据库创建了隐式临时表来处理分组或去重（如 GROUP BY 未命中索引），磁盘 I/O 剧增。

# 总结
EXPLAIN 是将高层 SQL 转化为底层的物理诊断全景图。

1. 查索引：看 type 否到达 range 以上，key 是否命中。
2. 看回表：看 Extra 是否有 Using index（覆盖索引）。
3. 排隐患：坚决消除 ALL（全表扫描）、Using filesort（文件排序）与 Using temporary（隐式临时表）。