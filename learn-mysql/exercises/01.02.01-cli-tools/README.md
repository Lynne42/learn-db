# 练习 04: 编写自动化探针脚本

## 任务目标
检验你是否掌握了 `mysql` 命令行的非交互式执行 (`-e`) 技巧，以及结合 Docker 刺穿容器的能力。

## 题目说明
请打开本目录下的 `exercise.sh` 脚本文件。
你需要在这个 Bash 脚本中，写下一行长命令：

**需求要求**：
利用 `docker compose exec` 进入 `mysql-learn` 容器，并使用 `mysql` 命令行工具，以 `root` 用户身份（密码是 `root123`），采用**非交互式**参数，向数据库发送一行 SQL 查询语句：
`SELECT "Ready for duty" AS status;`

*(提示：这就像我们在课件中查版本号的那个实战例子一样)*

## 运行方式
编辑完 `exercise.sh` 并保存后，在聊天框向我发送：
```bash
/db.check
```
