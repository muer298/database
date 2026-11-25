-- ============================================================
-- 电影院票务预订管理系统 - 查询脚本（对齐接口约定 v1.1）
-- 分类：单表条件2 + 多表关联2 + 分组统计1 + 嵌套2 + 复杂业务1 = 8 条
-- 说明：表名复数 snake_case，状态英文枚举，金额 DECIMAL(10,2)。
-- ============================================================
USE cinema_ticket;

-- ---------- 【单表条件查询 1】WHERE + ORDER BY ----------
-- 查询上映中的电影，按上映日期降序显示
SELECT movie_id, title, genre, duration_minutes, base_price, release_date
FROM movies
WHERE showing_status = 'SHOWING'
ORDER BY release_date DESC;

-- ---------- 【单表条件查询 2】WHERE 多条件 ----------
-- 查询 2026-12-24 放映且票价不超过 50 元的场次
SELECT screening_id, movie_id, hall_id, start_time, end_time, ticket_price
FROM screenings
WHERE start_time >= '2026-12-24 00:00:00'
  AND start_time <  '2026-12-25 00:00:00'
  AND ticket_price <= 50.00
ORDER BY start_time;

-- ---------- 【多表关联查询 1】INNER JOIN ----------
-- 查询订单明细：订单编号、用户名、影片名、场次时间、票号、座位快照、票价
SELECT o.order_number, u.real_name, m.title, sc.start_time,
       t.ticket_number, t.row_number_snapshot, t.column_number_snapshot, t.ticket_price
FROM orders o
JOIN users u          ON o.user_id = u.user_id
JOIN screenings sc    ON o.screening_id = sc.screening_id
JOIN movies m         ON sc.movie_id = m.movie_id
JOIN tickets t        ON t.order_id = o.order_id
ORDER BY o.order_number;

-- ---------- 【多表关联查询 2】LEFT JOIN ----------
-- 查询所有场次及其售票数量（含未售出场次，售票数显示 0）
SELECT sc.screening_id, m.title, h.hall_name, sc.start_time,
       COUNT(t.ticket_id) AS sold_count
FROM screenings sc
JOIN movies m     ON sc.movie_id = m.movie_id
JOIN halls h      ON sc.hall_id = h.hall_id
LEFT JOIN tickets t ON t.screening_id = sc.screening_id AND t.ticket_status = 'VALID'
GROUP BY sc.screening_id, m.title, h.hall_name, sc.start_time
ORDER BY sold_count DESC;

-- ---------- 【分组统计查询】GROUP BY + HAVING ----------
-- 统计每部影片的票房收入与售票数，只显示票房不低于 80 元的影片
SELECT m.title,
       COUNT(t.ticket_id) AS tickets_sold,
       SUM(t.ticket_price) AS box_office
FROM tickets t
JOIN screenings sc ON t.screening_id = sc.screening_id
JOIN movies m      ON sc.movie_id = m.movie_id
WHERE t.ticket_status = 'VALID'
GROUP BY m.movie_id, m.title
HAVING SUM(t.ticket_price) >= 80.00
ORDER BY box_office DESC;

-- ---------- 【嵌套查询 1】IN 子查询 ----------
-- 查询购买过「星际穿越」的用户
SELECT DISTINCT u.user_id, u.real_name, u.phone
FROM users u
WHERE u.user_id IN (
    SELECT o.user_id
    FROM orders o
    JOIN screenings sc ON o.screening_id = sc.screening_id
    WHERE sc.movie_id = (SELECT movie_id FROM movies WHERE title = '星际穿越')
)
ORDER BY u.user_id;

-- ---------- 【嵌套查询 2】EXISTS 子查询 ----------
-- 查询存在有效电影票的已支付订单
SELECT o.order_number, o.total_amount, o.ordered_at
FROM orders o
WHERE o.order_status = 'PAID'
  AND EXISTS (
    SELECT 1 FROM tickets t
    WHERE t.order_id = o.order_id AND t.ticket_status = 'VALID'
)
ORDER BY o.ordered_at DESC;

-- ---------- 【复杂业务查询】多表连接 + 聚合 + 上座率 ----------
-- 查询每个场次的上座率（SOLD 座位数 / 影厅实际座位数）
-- 影厅总座位数不存字段，改用 seats 实际记录数统计（对齐 v1.0 约定）
SELECT sc.screening_id,
       m.title,
       h.hall_name,
       COUNT(DISTINCT s.seat_id) AS hall_seats,
       SUM(CASE WHEN so.occupancy_status = 'SOLD' THEN 1 ELSE 0 END) AS sold_seats,
       ROUND(100.0 * SUM(CASE WHEN so.occupancy_status = 'SOLD' THEN 1 ELSE 0 END)
             / NULLIF(COUNT(DISTINCT s.seat_id), 0), 2) AS occupancy_rate
FROM screenings sc
JOIN movies m  ON sc.movie_id = m.movie_id
JOIN halls h   ON sc.hall_id = h.hall_id
JOIN seats s   ON s.hall_id = h.hall_id
LEFT JOIN seat_occupancies so
       ON so.screening_id = sc.screening_id AND so.seat_id = s.seat_id
GROUP BY sc.screening_id, m.title, h.hall_name
ORDER BY occupancy_rate DESC;

-- ============================================================
-- 查询脚本结束（共 8 条）
-- ============================================================
