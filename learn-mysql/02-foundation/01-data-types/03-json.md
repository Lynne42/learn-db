# JSON 数据类型

> **故事线与承上启下**：
> 在传统的数据库设计中，我们强调结构化与强Schema约束（如数值、字符和时间类型）。然而，在真实的电商业务场景中，商品的规格属性（例如：手机的 RAM、存储、颜色；图书的作者、出版社、页数）是高度动态且稀疏的。如果为每个属性都设计单独的物理列，表结构将变得臃肿且难以维护；如果采用 EAV (Entity-Attribute-Value) 模式，又会导致极其复杂的 JOIN 查询和糟糕的性能。
> MySQL 5.7+ 引入、8.0+ 完善的原生 `JSON` 数据类型，为我们提供了一种兼顾关系型数据库 ACID 特性与 NoSQL 模式灵活性的半结构化数据存储方案。

## ⚡ 速查摘要

- **原生存储优势**：MySQL 的 `JSON` 类型并非简单的文本存储（不同于 `TEXT`），它在底层以优化的二进制格式（BSON 变体）存储，支持快速的键值定位，无需每次都解析整个 JSON 文本。
- **格式自动校验**：向 `JSON` 列插入数据时，MySQL 引擎会自动进行语法正确性校验，如果 JSON 格式非法，写入将直接报错。
- **精准提取操作符**：
  - `->`（即 `JSON_EXTRACT`）：提取指定路径的 JSON 元素，返回的值**保留双引号**（如 `"Apple"`）或 JSON 对象。
  - `->>`（即 `JSON_UNQUOTE(JSON_EXTRACT(...))`）：提取指定路径的 JSON 元素，并**去掉双引号**（如 `Apple`），直接返回纯文本。
- **局部修改函数**：使用 `JSON_SET()`、`JSON_INSERT()`、`JSON_REPLACE()`、`JSON_REMOVE()` 可以对 JSON 的特定节点进行局部增删改，避免了在应用层整存整取的开销。

---

## 🎯 学习目标与验收标准

**学习目标：**
- 深刻理解 `JSON` 数据类型与普通文本类型（`VARCHAR` / `TEXT`）的本质区别与性能差异。
- 熟练掌握 JSON 路径表达式（`$.path`）的编写规范。
- 熟练使用 `->` 和 `->>` 操作符以及核心 JSON 提取与修改函数。
- 掌握 JSON 在电商商品规格存储等经典场景中的架构选型依据。

**验收标准：**
- [ ] 能解释 `->` 与 `->>` 在提取字符串值时的本质差异。
- [ ] 能够写出往 `JSON` 列中局部追加或修改某个键值的 SQL 语句。
- [ ] 完成本小节的练习，成功用 DDL 声明包含 `JSON` 类型的商品规格表，并通过批改脚本。

---

## 📖 概念全景

### 1. 原生 JSON 与 TEXT 存 JSON 的本质对决

在原生 `JSON` 类型出现之前，开发人员常常用 `VARCHAR` 或 `TEXT` 来存储序列化后的 JSON 字符串。两者的区别在工程上是决定性的：

| 维度 | TEXT / VARCHAR 存储 JSON | 原生 JSON 类型 |
|:---|:---|:---|
| **合法性校验** | **无**。数据库无法阻止任意脏字符串写入，极易引发应用层解析崩溃。 | **有**。MySQL 会在物理写入前进行严格的 RFC 7159 规范校验，非法格式直接拒签。 |
| **查询性能** | **极慢**。必须读取整列到内存，在应用层反序列化；或使用全表扫描进行正则匹配。 | **极快**。底层以二进制格式存储。查询时仅根据键的偏移量进行部分解析，支持快速定位。 |
| **局部更新** | **全覆盖写入**。即使只修改一个属性，也需要将整个大文本读取、修改后重新覆盖写入。 | **支持局部更新**。MySQL 8.0+ 支持物理层面的 Partial Update，极大地降低了 I/O 损耗。 |
| **索引支持** | 无法对内部的 JSON 键直接建立索引。 | 支持通过**虚拟生成列 (Generated Column)** 提取指定键并建立物理索引（在工程进阶篇展开）。 |

---

### 2. 路径表达式 (Path Expression)

为了精确定位 JSON 数据内部的成员，MySQL 使用路径表达式：
- `$` 代表 JSON 文档的根节点。
- `.` 用于访问 JSON 对象的子健（例如：`$.brand`）。
- `[index]` 用于访问 JSON 数组的特定元素，索引从 0 开始（例如：`$.tags[0]`）。
- `*` 通配符用于匹配所有子节点。

假设有如下 JSON：
```json
{
  "brand": "Xiaomi",
  "config": {
    "ram": "12GB",
    "storage": "256GB"
  },
  "tags": ["旗舰", "性价比"]
}
```
- 提取品牌：`$.brand` => `"Xiaomi"`
- 提取 RAM：`$.config.ram` => `"12GB"`
- 提取第一个标签：`$.tags[0]` => `"旗舰"`

---

## 💻 SQL 语法

### 1. 建表与数据写入

```sql
CREATE TABLE temp_goods (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(100) NOT NULL,
    -- 声明 JSON 字段
    specs JSON NOT NULL
);

-- 写入数据，必须是合法的 JSON 字符串
INSERT INTO temp_goods (title, specs) VALUES 
('小米14', '{"brand": "Xiaomi", "ram": "12GB", "storage": "256GB", "tags": ["性价比", "徕卡"]}'),
('iPhone 15', '{"brand": "Apple", "ram": "8GB", "storage": "128GB", "tags": ["高端", "iOS"]}');
```

### 2. 数据查询与提取

#### 🔍 方法 A：使用 `JSON_EXTRACT` 与 `JSON_UNQUOTE`
```sql
-- 提取 brand（注意：结果带双引号）
SELECT JSON_EXTRACT(specs, '$.brand') AS brand FROM temp_goods; 
-- 输出: "Xiaomi"

-- 去除双引号
SELECT JSON_UNQUOTE(JSON_EXTRACT(specs, '$.brand')) AS brand FROM temp_goods;
-- 输出: Xiaomi
```

#### 🚀 方法 B：使用快捷操作符（推荐）
- **`->` (带有双引号)**
  ```sql
  SELECT title, specs->'$.brand' AS brand FROM temp_goods;
  -- 输出: "Xiaomi"
  ```
- **`->>` (去除双引号，等价于 unquote)**
  ```sql
  SELECT title, specs->>'$.brand' AS brand FROM temp_goods;
  -- 输出: Xiaomi
  ```

### 3. 数据更新

- **`JSON_SET(json_doc, path, val[, path, val]...)`**：
  插入或更新数据。如果路径存在，则替换；如果路径不存在，则新增。
  ```sql
  -- 将小米14的内存修改为 16GB，并新增 color 属性
  UPDATE temp_goods 
  SET specs = JSON_SET(specs, '$.ram', '16GB', '$.color', '黑色')
  WHERE title = '小米14';
  ```
- **`JSON_REPLACE(json_doc, path, val[, path, val]...)`**：
  仅替换已有的数据。如果路径不存在，则不作任何改变。
- **`JSON_REMOVE(json_doc, path[, path]...)`**：
  删除指定的键。
  ```sql
  -- 删除 tags 属性
  UPDATE temp_goods 
  SET specs = JSON_REMOVE(specs, '$.tags')
  WHERE title = 'iPhone 15';
  ```

---

## ⚡ 项目实战 —— 动态规格设计

在电商系统中，不同类目的商品（SPU）其规格（Specs）大相径庭。采用原生 `JSON` 能够让商品表保持极高的扩展性：

1. **核心字段结构化**：商品的 `id`、`title`、`price`、`stock` 等属于所有商品的公共属性，且经常用于范围查询、排序和更新，必须声明为独立的**物理列**。
2. **多变字段半结构化**：商品的 `specs`（如：手机的芯片型号、屏幕尺寸，服装的尺码、面料，书籍的装帧形式）设计为 **`JSON` 列**，允许随商品类目变化自由增减键，无需频繁进行 DDL 变更表结构。

---

## ⚠️ 常见坑点

### 1. JSON 字段无法直接声明非空表达式之外的硬编码默认值
在 MySQL 中，`JSON` 列**不能**被赋予一个像 `DEFAULT '{}'` 这样的普通字符串默认值。如果不需要强制输入，应默认允许为空（`NULL`），在应用层或写入时提供初始化对象。

### 2. 避免对 JSON 列进行频繁的全局聚合和排序
因为 JSON 数据是半结构化的，如果编写大量的 `GROUP BY specs->>'$.brand'` 或是 `ORDER BY specs->>'$.price'`，MySQL 引擎无法直接利用传统的 B-Tree 索引，会导致全表扫描并在内存中进行临时表排序（Filesort），在高并发下会瞬间耗尽 CPU。**对于高频作为过滤和排序条件的键，必须通过虚拟列并建立索引予以优化**。

---

## 📋 主动回忆

1. 如果执行 `SELECT specs->'$.tags[0]' FROM temp_goods`，拿到的结果是否带有引号？如何将其修改为不带引号的纯文本？
2. 往 `JSON` 列写入 `'{"name": "Apple",}'`（注意结尾的逗号）会发生什么？

---

## ✅ 项目练习

请进入 `exercises/02.01.03-json/` 目录，按照题目说明编写建表 SQL。

使用以下命令验证你的练习答案：
```bash
bash test.sh
```
