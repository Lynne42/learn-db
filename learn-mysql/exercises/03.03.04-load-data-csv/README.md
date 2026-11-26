# 练习：LOAD DATA 与 CSV 导入

## 业务背景

系统需要大批量同步商户端导出的初始用户报表。为了保障数据导入性能，我们需要采用内建的 `LOAD DATA INFILE` 指令来进行极速加载。

当前，我们的 MySQL 容器已将安全目录限制在 `/var/lib/mysql-files/`。

## 任务要求

请在 `exercise.sql` 中编写 SQL 语句，完成以下任务：

1. 使用 `LOAD DATA INFILE` 将已经放置在安全目录下的数据文件 `/var/lib/mysql-files/seed_data.csv` 导入到用户表 `users` 中。
2. 数据格式设置：
   - 字段分隔符为逗号 `,`。
   - 数据**没有**使用双引号包裹，不需要写包裹符。
   - 换行符为 `\n`。
   - 数据文件第一行是表头 `username,email,password_hash,status`，导入时需要忽略该行。
3. 导入时必须显式指定列映射关系：映射到 `users` 表的 `(username, email, password_hash, status)` 列。

> 💡 **提示**：本练习执行时，`test.sh` 脚本在重置表结构后，会自动将本目录下的 `seed_data.csv` 通过 `docker cp` 复制到容器内的 `/var/lib/mysql-files/seed_data.csv`。你无需手动复制，直接在 `exercise.sql` 中编写 `LOAD DATA INFILE '/var/lib/mysql-files/seed_data.csv' ...` 即可。

## 如何验证

请在终端进入本目录，然后执行：
```bash
bash test.sh
```
如果输出 "✅ 测试通过！"，则说明你已成功完成。可以接着向 Agent 发送 `/db.check` 来登记进度。
