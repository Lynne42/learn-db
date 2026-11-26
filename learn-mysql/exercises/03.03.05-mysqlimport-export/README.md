# 练习：mysqlimport 与基础导出

## 业务背景

由于审计部门需要对系统内的正常用户进行定期合规审计，我们需要在后台安全目录下生成一份正常用户的明细报表。

## 任务要求

请在 `exercise.sql` 中编写 SQL 语句，完成以下任务：

1. 使用 `SELECT ... INTO OUTFILE` 将正常激活的用户数据（即 `status = 1` 的记录）导出到服务器的安全目录 `/var/lib/mysql-files/active_users.csv` 中。
2. 导出字段：`username` 和 `email`。
3. 导出要求：
   - 字段之间使用逗号 `,` 分隔。
   - 换行符使用 `\n`。
   - **必须**按照 `username` 升序排序 (`ORDER BY username ASC`) 进行导出，以确保输出文件顺序固定。

> 💡 **提示**：为防止多次测试时因文件已存在报错，`test.sh` 脚本在每次运行前，会自动在操作系统中执行文件清理操作 (`rm -f /var/lib/mysql-files/active_users.csv`)。你只需专心写好导出 SQL 即可。

## 如何验证

请在终端进入本目录，然后执行：
```bash
bash test.sh
```
如果输出 "✅ 测试通过！"，则说明你已成功完成。可以接着向 Agent 发送 `/db.check` 来登记进度。
