# 练习：Schema V1 复盘

## 业务背景

订单系统准备进入工程优化阶段。需要从数据库实际元数据生成商品—订单交易子图的外键依赖清单，确认分类、商品、订单和明细之间的引用方向。

## 涉及的数据表

### `information_schema.KEY_COLUMN_USAGE`

| 字段 | 类型 | 可空 | Key / 约束 | 业务含义 |
|---|---|---|---|---|
| `TABLE_SCHEMA` | `VARCHAR(64)` | 否 | Metadata | 约束所属数据库 |
| `TABLE_NAME` | `VARCHAR(64)` | 否 | Metadata | 外键所在表 |
| `COLUMN_NAME` | `VARCHAR(64)` | 否 | Metadata | 外键列 |
| `REFERENCED_TABLE_NAME` | `VARCHAR(64)` | 是 | Metadata | 被引用表；非外键时为 `NULL` |
| `REFERENCED_COLUMN_NAME` | `VARCHAR(64)` | 是 | Metadata | 被引用列；非外键时为 `NULL` |

### 被审计的业务表

| 表 | 本题关注字段 | 关系角色 |
|---|---|---|
| `categories` | `parent_id` | 分类自引用 |
| `products` | `category_id` | 商品引用分类 |
| `orders` | `user_id` | 订单引用用户 |
| `order_items` | `order_id`、`product_id` | 明细引用订单和商品 |

**表关系：** 本题不预先给出完整清单；你需要从元数据中识别引用方向。`orders` 引用的父表不在交易子图筛选列表中，但该外键仍属于 `orders`，必须出现在结果中。

## 测试数据说明

本题不导入业务行数据。测试器会在隔离数据库中依次应用 `schema/v001` 至 `v007`，构造真实 Schema V1，再比对元数据查询结果。结果只取外键，不包含 Primary Key 或 Unique Key。

## 任务要求

在 `exercise.sql` 中查询 `information_schema.KEY_COLUMN_USAGE`：

1. 返回并使用小写别名：`table_name`、`column_name`、`referenced_table_name`、`referenced_column_name`。
2. 使用 `TABLE_SCHEMA = DATABASE()` 限定当前隔离数据库。
3. 只保留 `TABLE_NAME IN ('categories', 'products', 'orders', 'order_items')`。
4. 使用 `REFERENCED_TABLE_NAME IS NOT NULL` 排除非外键约束。
5. 按 `TABLE_NAME ASC, COLUMN_NAME ASC` 稳定排序。

不要硬编码结果行，不要查询 `mysql` 系统权限表。

## 如何验证

```bash
bash test.sh
```

如果输出“✅ 测试通过！”，发送 `/db.check mysql 03.07.00` 登记进度。

