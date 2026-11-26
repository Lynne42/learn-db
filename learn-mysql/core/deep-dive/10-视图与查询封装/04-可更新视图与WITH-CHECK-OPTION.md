# 10.04 可更新视图与 WITH CHECK OPTION

## 可更新视图

简单的单表视图可能允许执行 `INSERT`、`UPDATE` 或 `DELETE`：

```sql
CREATE VIEW v_active_products AS
SELECT id, name, price, status
FROM products
WHERE status = 1;

UPDATE v_active_products
SET price = 99.00
WHERE id = 10;
```

包含聚合、`GROUP BY`、`DISTINCT`、集合操作或部分复杂派生结构的视图通常不可更新。是否可更新应以当前 MySQL 版本规则和实际验证为准。

## 防止写出视图范围

没有检查约束时，通过视图更新记录可能使其不再满足视图条件。使用 `WITH CHECK OPTION` 可以拒绝这种写入：

```sql
CREATE VIEW v_active_products AS
SELECT id, name, price, status
FROM products
WHERE status = 1
WITH CASCADED CHECK OPTION;

UPDATE v_active_products
SET status = 0
WHERE id = 10;
-- 失败：更新后的记录不再满足 status = 1
```

- `LOCAL`：检查当前视图定义中的条件。
- `CASCADED`：同时检查当前视图及其依赖视图的条件。

## 工程边界

可更新不等于适合更新。核心写入链路优先直接操作明确的底层表，并由 Service 层表达业务约束。只有映射简单、权限目标明确、写入行为经过测试时，才考虑通过视图写入。
