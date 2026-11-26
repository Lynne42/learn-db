# 练习：JSON 数据类型应用实战

## 业务背景

在我们的「电商订单管理系统」中，为了支持不同类目商品动态且稀疏的规格属性（例如：手机的内存与存储容量；服装的尺码与面料），我们需要创建一张名为 `temp_product_specs` 的商品规格临时表，利用原生 JSON 类型来实现高扩展性的半结构化数据存储。

## 任务要求

请在 `exercise.sql` 中编写一条 `CREATE TABLE` 语句，创建 `temp_product_specs` 表，其字段定义必须严格符合以下设计契约：

| 字段名 | 类型与属性 | 空值限制 | 默认值 | 说明 |
|:---|:---|:---|:---|:---|
| **id** | `BIGINT UNSIGNED` | `NOT NULL` | - | 自增主键 (`AUTO_INCREMENT PRIMARY KEY`) |
| **product_name** | `VARCHAR(100)` | `NOT NULL` | - | 商品名称，最大长度 100 字符 |
| **specs** | `JSON` | `NOT NULL` | - | 原生 JSON 类型，用于存放核心规格参数（不允许为空） |
| **ext_attrs** | `JSON` | `YES` (允许为空) | `NULL` | 原生 JSON 类型，用于存放扩展定制参数（允许为空） |

## 如何验证

请在终端进入本目录，然后执行：
```bash
bash test.sh
```

如果输出 "✅ 测试通过！"，说明建表契约完全吻合，接着可以向 Agent 发送 `/db.check` 登记进度。
