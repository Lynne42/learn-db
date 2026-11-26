# 练习：字符串类型选型实战

## 业务背景

我们的「电商订单管理系统」需要开发一个面向商品后台渲染的辅助系统。为此我们需要创建一张名为 `temp_products_preview` 的商品预览快照表，用以暂存商品的预览标题、定长编码、图文描述及商品大类属性。

## 任务要求

请在 `exercise.sql` 中编写一条 `CREATE TABLE` 语句，创建 `temp_products_preview` 表，其字段定义必须严格符合以下设计契约：

| 字段名 | 类型与属性 | 空值限制 | 默认值 | 说明 |
|:---|:---|:---|:---|:---|
| **id** | `INT UNSIGNED` | `NOT NULL` | - | 自增主键 (`AUTO_INCREMENT PRIMARY KEY`) |
| **spu_no** | `CHAR(12)` | `NOT NULL` | - | 固定 12 位的商品 SPU 编码 |
| **preview_title** | `VARCHAR(150)` | `NOT NULL` | - | 动态变长的商品预览标题，上限 150 字符 |
| **detail_desc** | `TEXT` | `YES` (即允许为空) | `NULL` | 允许发生行溢出的长图文详情描述 |
| **product_type** | `ENUM('PHYSICAL', 'DIGITAL', 'VIRTUAL')` | `NOT NULL` | `'PHYSICAL'` | 商品类型，限定这三种值之一 |

## 如何验证

请在终端进入本目录，然后执行：
```bash
bash test.sh
```

如果输出 "✅ 测试通过！"，说明建表契约完全吻合，接着可以向 Agent 发送 `/db.check` 登记进度。
