# 练习：字符集与排序规则

## 业务背景

随着电商系统的全球化扩展，我们的订单评价系统需要支持多国语言以及用户丰富的表情符号（Emoji）。此外，商品 SKU 编码在后台是严格区分大小写的，比如 SKU 编码 `sku_itemA` 和 `sku_itema` 代表两款完全不同的单品，录入时不能因为唯一索引冲突而被阻止。

为了支持上述业务需求，我们需要创建一张临时国际化评论表 `temp_international_reviews`，并对其各个列的字符集和排序规则进行精确配置。

## 任务要求

请在 `exercise.sql` 中编写 SQL 语句，创建表 `temp_international_reviews`，具体要求如下：

1. 表名为 `temp_international_reviews`。
2. 表默认字符集设为 `utf8mb4`，默认排序规则为 `utf8mb4_unicode_ci`。
3. 字段设计：
   - `review_id`：整型（`INT`），主键且自增（`AUTO_INCREMENT`）。
   - `order_no`：变长字符串 `VARCHAR(50)`，必填（`NOT NULL`）。该字段继承表的默认字符集。
   - `user_id`：大整型（`BIGINT`），必填（`NOT NULL`）。
   - `sku_code`：变长字符串 `VARCHAR(50)`，必填（`NOT NULL`）。**核心要求**：必须支持大小写敏感（例如，使用 `utf8mb4_bin` 排序规则），防止大小写不同的 SKU 冲突。
   - `review_text`：大文本（`TEXT`），必填（`NOT NULL`）。**核心要求**：必须支持表情符号，并且使用 `utf8mb4_unicode_ci` 排序规则。
4. 在建表语句之后不需要编写其他多余 SQL，确保脚本仅包含建表逻辑。

## 如何验证

请在终端进入本目录，然后执行：
```bash
bash test.sh
```
如果输出 "✅ 测试通过！"，则说明你已掌握本节内容。可以接着向 Agent 发送 `/db.check` 来登记进度。
