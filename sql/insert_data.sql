USE cinema_ticket;

-- 仅用于本地联调。密码字段是演示哈希，不是可用于生产环境的真实凭据。
INSERT IGNORE INTO users
  (username, password_hash, real_name, phone, email, role, account_status)
VALUES
  ('demo_customer', SHA2('demo-password', 256), '测试用户', '13800000001', 'customer@example.test', 'CUSTOMER', 'NORMAL'),
  ('demo_admin', SHA2('demo-admin-password', 256), '测试管理员', '13800000002', 'admin@example.test', 'ADMIN', 'NORMAL');

INSERT IGNORE INTO movies
  (title, director, actors, genre, duration_minutes, release_date, base_price, synopsis, showing_status)
VALUES
  ('示例电影', '示例导演', '演员甲, 演员乙', '剧情', 120, CURRENT_DATE, 45.00, '用于第一周数据库联调的示例电影。', 'SHOWING');

INSERT IGNORE INTO halls
  (hall_name, hall_type, row_count, column_count)
VALUES
  ('1号厅', 'STANDARD', 2, 3);

SET @sample_hall_id = (SELECT hall_id FROM halls WHERE hall_name = '1号厅' LIMIT 1);
SET @sample_movie_id = (
  SELECT movie_id FROM movies WHERE title = '示例电影' ORDER BY movie_id LIMIT 1
);

INSERT IGNORE INTO seats
  (hall_id, seat_row, seat_column, seat_type, use_status)
VALUES
  (@sample_hall_id, 1, 1, 'NORMAL', 'ENABLED'),
  (@sample_hall_id, 1, 2, 'NORMAL', 'ENABLED'),
  (@sample_hall_id, 1, 3, 'NORMAL', 'ENABLED'),
  (@sample_hall_id, 2, 1, 'VIP', 'ENABLED'),
  (@sample_hall_id, 2, 2, 'VIP', 'ENABLED'),
  (@sample_hall_id, 2, 3, 'VIP', 'ENABLED');

SET @sample_start_time = TIMESTAMP(DATE_ADD(CURRENT_DATE, INTERVAL 1 DAY), '19:00:00');
SET @sample_end_time = DATE_ADD(@sample_start_time, INTERVAL 2 HOUR);

INSERT INTO screenings
  (movie_id, hall_id, start_time, end_time, language_version, subtitle, ticket_price, screening_status)
SELECT
  @sample_movie_id, @sample_hall_id, @sample_start_time, @sample_end_time,
  'ORIGINAL', 'CHINESE', 45.00, 'SELLING'
WHERE NOT EXISTS (
  SELECT 1
  FROM screenings
  WHERE hall_id = @sample_hall_id AND start_time = @sample_start_time
);

SET @sample_screening_id = (
  SELECT screening_id
  FROM screenings
  WHERE hall_id = @sample_hall_id AND start_time = @sample_start_time
  LIMIT 1
);

INSERT IGNORE INTO seat_occupancies
  (screening_id, seat_id, occupancy_status)
SELECT
  @sample_screening_id, seat_id, 'AVAILABLE'
FROM seats
WHERE hall_id = @sample_hall_id AND use_status = 'ENABLED';

SELECT
  s.screening_id,
  m.title,
  h.hall_name,
  s.start_time,
  COUNT(so.seat_id) AS available_seats
FROM screenings s
JOIN movies m ON m.movie_id = s.movie_id
JOIN halls h ON h.hall_id = s.hall_id
LEFT JOIN seat_occupancies so
  ON so.screening_id = s.screening_id
 AND so.occupancy_status = 'AVAILABLE'
WHERE s.screening_id = @sample_screening_id
GROUP BY s.screening_id, m.title, h.hall_name, s.start_time;
