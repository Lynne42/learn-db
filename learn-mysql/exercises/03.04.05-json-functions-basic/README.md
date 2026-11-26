# 练习：JSON 函数基础

## 业务背景

运营后台需要读取商品扩展属性：展示颜色、识别无线商品，并预览增加质保月数后的 JSON 文档。

## 任务要求

在 `exercise.sql` 中编写一条查询：

1. 从 `lesson_030405_products` 查询 `id`、`name`。
2. 使用 `->>` 提取 `$.color`，别名为 `color`。
3. 使用 `JSON_CONTAINS` 判断 `$.tags` 是否包含 JSON 字符串 `"wireless"`，别名为 `is_wireless`。
4. 使用 `JSON_SET` 把 `$.warranty_months` 设置为数字 `24`，再用 `JSON_EXTRACT + JSON_UNQUOTE` 从新文档中提取该值，别名为 `warranty_months`。
5. 使用 `ORDER BY id ASC` 保证结果稳定。

禁止直接写死预期结果；查询必须真实使用上述 JSON 操作。

## 如何验证

```bash
bash test.sh
```

通过后发送 `/db.check mysql 03.04.05`。
