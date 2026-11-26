# 练习：批处理 SQL 文件

## 业务背景

为了实现商品管理的微版本更新，我们需要在后台通过自动化脚本一键升级类目基础数据。
类目表 `categories` 的结构已经预置在 `test.sh` 初始化脚本中，定义如下：

```sql
CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL UNIQUE,
    parent_id INT DEFAULT 0
) ENGINE=InnoDB;
```

我们需要通过批处理机制向数据库灌入初始的三条主类目数据。

## 任务要求

请在 `exercise.sql` 中编写 SQL 语句，向商品类目表 `categories` 批量插入以下三条分类数据：
- 分类 1：`category_name` 为 `'Electronics'`
- 分类 2：`category_name` 为 `'Clothing'`
- 分类 3：`category_name` 为 `'Books'`

> 💡 **提示**：本节练习的验证脚本 `test.sh` 会通过外部终端重定向模式 (`mysql < exercise.sql`) 来执行你的 SQL 文件，并使用批处理静默选项 (`mysql -ss -N -e ...`) 来提取验证结果。你可以亲自在命令行执行，并查看批处理输出与交互式输出在表格边框和表头上的物理差异。

## 如何验证

请在终端进入本目录，然后执行：
```bash
bash test.sh
```
如果输出 "✅ 测试通过！"，则说明你已成功完成。可以接着向 Agent 发送 `/db.check` 来登记进度。
