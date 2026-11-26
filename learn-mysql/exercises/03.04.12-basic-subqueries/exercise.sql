-- TODO: 使用标量子查询和列子查询，找出存在高于平均金额订单的用户。
-- 必须使用 IN、AVG(total_amount) 和 ORDER BY id ASC。

SELECT id, username
FROM users AS u
WHERE u.id in (
    SELECT o.user_id
    FROM orders AS o
    WHERE o.total_amount > (
        SELECT AVG(total_amount)
        FROM orders
    )
)
ORDER BY id ASC