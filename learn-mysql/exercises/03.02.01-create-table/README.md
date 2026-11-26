# 练习：创建表与基础约束

## 业务背景

我们要为我们的电商订单管理系统落地最核心的用户表 `users`。在本小节中，我们只需要建立最基础的物理结构并加上非空与默认值约束即可。暂时不需要在此处加入唯一性索引（UNIQUE），后续的课程（模块 03.02）将专门演进唯一性约束。

## 任务要求

请在 `exercise.sql` 中编写一条 `CREATE TABLE` 语句，创建 `users` 表，具体字段与属性要求如下：

1. 表名为 `users`。
2. 表的存储引擎指定为 `InnoDB`。
3. 表默认字符集设为 `utf8mb4`，排序规则设为 `utf8mb4_unicode_ci`。
4. 字段设计：
   - `id`：整型（`INT`），主键且自增。
   - `username`：变长字符串 `VARCHAR(50)`，必填（`NOT NULL`）。
   - `email`：变长字符串 `VARCHAR(100)`，必填（`NOT NULL`）。
   - `password_hash`：变长字符串 `VARCHAR(255)`，必填（`NOT NULL`）。
   - `status`：微整型（`TINYINT`），必填（`NOT NULL`），默认值为 `1`。

## 如何验证

请在终端进入本目录，然后执行：
```bash
bash test.sh
```
如果输出 "✅ 测试通过！"，则说明你已掌握本节内容。可以接着向 Agent 发送 `/db.check` 来登记进度。
