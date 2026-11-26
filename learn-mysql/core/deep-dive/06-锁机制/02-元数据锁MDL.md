# 06.02 元数据锁 MDL

> 状态：占位大纲，待系统学习。

## 学习目标

- 理解 DML 为什么会持有 Metadata Lock。
- 分析长事务阻塞 ALTER TABLE 的因果链。
- 学会用 `performance_schema` 或进程列表定位 MDL 等待。

## 后续展开

- MDL 的生命周期和释放条件。
- 线上 DDL 前的阻塞检查与超时策略。
