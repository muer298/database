-- ============================================================
-- 电影院票务预订管理系统 - 测试数据初始化脚本（对齐接口约定 v1.1）
-- 说明：字段名/状态/金额/主键类型均按复数表名 + 英文枚举；
--       顺序遵循外键依赖：users/movies/halls → seats/screenings
--       → orders → seat_occupancies → tickets。
--       INSERT IGNORE 支持重复执行，不覆盖历史数据。
-- ============================================================
USE cinema_ticket;

-- 演示哈希仅用于联调，不是真实凭据。
-- ---------- 1. users（10 条）----------
INSERT IGNORE INTO users
  (user_id, username, password_hash, real_name, phone, email, role, registered_at, account_status)
VALUES
  (1,'zhangsan',SHA2('demo-1',256),'张三','13800000001','zhangsan@email.com','CUSTOMER','2026-09-01 10:00:00','NORMAL'),
  (2,'lisi',    SHA2('demo-2',256),'李四','13800000002','lisi@email.com',   'CUSTOMER','2026-09-02 11:30:00','NORMAL'),
  (3,'wangwu',  SHA2('demo-3',256),'王五','13800000003','wangwu@email.com', 'CUSTOMER','2026-09-03 09:15:00','NORMAL'),
  (4,'zhaoliu', SHA2('demo-4',256),'赵六','13800000004','zhaoliu@email.com','CUSTOMER','2026-09-05 14:20:00','NORMAL'),
  (5,'sunqi',   SHA2('demo-5',256),'孙七','13800000005','sunqi@email.com',  'CUSTOMER','2026-09-08 16:45:00','NORMAL'),
  (6,'zhouba',  SHA2('demo-6',256),'周八','13800000006','zhouba@email.com', 'CUSTOMER','2026-09-10 08:30:00','NORMAL'),
  (7,'wujiu',   SHA2('demo-7',256),'吴九','13800000007','wujiu@email.com',  'CUSTOMER','2026-09-12 13:10:00','NORMAL'),
  (8,'zhengshi',SHA2('demo-8',256),'郑十','13800000008','zhengshi@email.com','CUSTOMER','2026-09-15 17:55:00','NORMAL'),
  (9,'chenyi',  SHA2('demo-9',256),'陈一','13800000009','chenyi@email.com', 'ADMIN',   '2026-09-18 10:40:00','NORMAL'),
  (10,'liuerm', SHA2('demo-10',256),'刘二','13800000010','liuerm@email.com','CUSTOMER','2026-09-20 15:25:00','FROZEN');

-- ---------- 2. movies（10 条；release_date 为 NOT NULL）----------
INSERT IGNORE INTO movies
  (movie_id, title, director, actors, genre, duration_minutes, release_date, base_price, synopsis, poster_url, showing_status)
VALUES
  (1,'星际穿越','克里斯托弗·诺兰','马修·麦康纳,安妮·海瑟薇','科幻',169,'2026-09-01',45.00,'探索宇宙与亲情','/poster/interstellar.jpg','SHOWING'),
  (2,'哪吒之魔童降世','饺子','吕艳婷,囧森瑟夫','动画',110,'2026-09-05',35.00,'逆天改命的少年','/poster/nezha.jpg','SHOWING'),
  (3,'肖申克的救赎','弗兰克·德拉邦特','蒂姆·罗宾斯,摩根·弗里曼','剧情',142,'2026-09-08',40.00,'希望与自由','/poster/shawshank.jpg','SHOWING'),
  (4,'千与千寻','宫崎骏','柊瑠美,入野自由','动画',125,'2026-09-10',38.00,'神秘世界的成长','/poster/spirited.jpg','SHOWING'),
  (5,'阿凡达','詹姆斯·卡梅隆','萨姆·沃辛顿,佐伊·索尔达娜','科幻',162,'2026-09-12',50.00,'潘多拉星球冒险','/poster/avatar.jpg','SHOWING'),
  (6,'盗梦空间','克里斯托弗·诺兰','莱昂纳多·迪卡普里奥,约瑟夫·高登-莱维特','科幻',148,'2026-09-15',45.00,'梦境层层嵌套','/poster/inception.jpg','SHOWING'),
  (7,'流浪地球','郭帆','吴京,刘慈欣','科幻',125,'2026-09-18',42.00,'带着地球去流浪','/poster/wandering.jpg','SHOWING'),
  (8,'疯狂动物城','拜伦·霍华德','金妮弗·古德温,杰森·贝特曼','动画',108,'2026-09-20',36.00,'梦想与勇气','/poster/zootopia.jpg','SHOWING'),
  (9,'教父','弗朗西斯·福特·科波拉','马龙·白兰度,阿尔·帕西诺','剧情',175,'2026-09-22',48.00,'家族与权力','/poster/godfather.jpg','SHOWING'),
  (10,'泰坦尼克号','詹姆斯·卡梅隆','莱昂纳多·迪卡普里奥,凯特·温斯莱特','爱情',194,'2026-09-25',46.00,'跨越阶级的爱情','/poster/titanic.jpg','OFFLINE');

-- ---------- 3. halls（10 条；不存总座位数，由 seats 统计）----------
INSERT IGNORE INTO halls (hall_id, hall_name, hall_type, row_count, column_count) VALUES
  (1,'1号厅','STANDARD',8,10),
  (2,'2号厅','STANDARD',8,10),
  (3,'3号厅','IMAX',10,12),
  (4,'4号厅','VIP',5,8),
  (5,'5号厅','STANDARD',8,10),
  (6,'6号厅','STANDARD',8,10),
  (7,'7号厅','IMAX',10,12),
  (8,'8号厅','VIP',5,8),
  (9,'9号厅','STANDARD',8,10),
  (10,'10号厅','STANDARD',8,10);

-- ---------- 4. seats（每个影厅 10 条，共 100 条）----------
INSERT IGNORE INTO seats (seat_id, hall_id, seat_row, seat_column, seat_type, use_status) VALUES
  (1,1,1,1,'NORMAL','ENABLED'),(2,1,1,2,'NORMAL','ENABLED'),(3,1,1,3,'NORMAL','ENABLED'),(4,1,1,4,'NORMAL','ENABLED'),(5,1,1,5,'NORMAL','ENABLED'),
  (6,1,1,6,'NORMAL','ENABLED'),(7,1,1,7,'NORMAL','ENABLED'),(8,1,1,8,'NORMAL','ENABLED'),(9,1,2,1,'NORMAL','ENABLED'),(10,1,2,2,'NORMAL','ENABLED'),
  (11,2,1,1,'NORMAL','ENABLED'),(12,2,1,2,'NORMAL','ENABLED'),(13,2,1,3,'NORMAL','ENABLED'),(14,2,1,4,'NORMAL','ENABLED'),(15,2,1,5,'NORMAL','ENABLED'),
  (16,2,1,6,'NORMAL','ENABLED'),(17,2,1,7,'NORMAL','ENABLED'),(18,2,1,8,'NORMAL','ENABLED'),(19,2,2,1,'NORMAL','ENABLED'),(20,2,2,2,'NORMAL','ENABLED'),
  (21,3,1,1,'VIP','ENABLED'),(22,3,1,2,'VIP','ENABLED'),(23,3,1,3,'VIP','ENABLED'),(24,3,1,4,'VIP','ENABLED'),(25,3,1,5,'VIP','ENABLED'),
  (26,3,1,6,'VIP','ENABLED'),(27,3,1,7,'VIP','ENABLED'),(28,3,1,8,'VIP','ENABLED'),(29,3,2,1,'VIP','ENABLED'),(30,3,2,2,'VIP','ENABLED'),
  (31,4,1,1,'VIP','ENABLED'),(32,4,1,2,'VIP','ENABLED'),(33,4,1,3,'VIP','ENABLED'),(34,4,1,4,'VIP','ENABLED'),(35,4,1,5,'VIP','ENABLED'),
  (36,4,1,6,'VIP','ENABLED'),(37,4,1,7,'VIP','ENABLED'),(38,4,1,8,'VIP','ENABLED'),(39,4,2,1,'VIP','ENABLED'),(40,4,2,2,'VIP','ENABLED'),
  (41,5,1,1,'NORMAL','ENABLED'),(42,5,1,2,'NORMAL','ENABLED'),(43,5,1,3,'NORMAL','ENABLED'),(44,5,1,4,'NORMAL','ENABLED'),(45,5,1,5,'NORMAL','ENABLED'),
  (46,5,1,6,'NORMAL','ENABLED'),(47,5,1,7,'NORMAL','ENABLED'),(48,5,1,8,'NORMAL','ENABLED'),(49,5,2,1,'NORMAL','ENABLED'),(50,5,2,2,'NORMAL','ENABLED'),
  (51,6,1,1,'NORMAL','ENABLED'),(52,6,1,2,'NORMAL','ENABLED'),(53,6,1,3,'NORMAL','ENABLED'),(54,6,1,4,'NORMAL','ENABLED'),(55,6,1,5,'NORMAL','ENABLED'),
  (56,6,1,6,'NORMAL','ENABLED'),(57,6,1,7,'NORMAL','ENABLED'),(58,6,1,8,'NORMAL','ENABLED'),(59,6,2,1,'NORMAL','ENABLED'),(60,6,2,2,'NORMAL','ENABLED'),
  (61,7,1,1,'VIP','ENABLED'),(62,7,1,2,'VIP','ENABLED'),(63,7,1,3,'VIP','ENABLED'),(64,7,1,4,'VIP','ENABLED'),(65,7,1,5,'VIP','ENABLED'),
  (66,7,1,6,'VIP','ENABLED'),(67,7,1,7,'VIP','ENABLED'),(68,7,1,8,'VIP','ENABLED'),(69,7,2,1,'VIP','ENABLED'),(70,7,2,2,'VIP','ENABLED'),
  (71,8,1,1,'VIP','ENABLED'),(72,8,1,2,'VIP','ENABLED'),(73,8,1,3,'VIP','ENABLED'),(74,8,1,4,'VIP','ENABLED'),(75,8,1,5,'VIP','ENABLED'),
  (76,8,1,6,'VIP','ENABLED'),(77,8,1,7,'VIP','ENABLED'),(78,8,1,8,'VIP','ENABLED'),(79,8,2,1,'VIP','ENABLED'),(80,8,2,2,'VIP','ENABLED'),
  (81,9,1,1,'NORMAL','ENABLED'),(82,9,1,2,'NORMAL','ENABLED'),(83,9,1,3,'NORMAL','ENABLED'),(84,9,1,4,'NORMAL','ENABLED'),(85,9,1,5,'NORMAL','ENABLED'),
  (86,9,1,6,'NORMAL','ENABLED'),(87,9,1,7,'NORMAL','ENABLED'),(88,9,1,8,'NORMAL','ENABLED'),(89,9,2,1,'NORMAL','ENABLED'),(90,9,2,2,'NORMAL','ENABLED'),
  (91,10,1,1,'NORMAL','ENABLED'),(92,10,1,2,'NORMAL','ENABLED'),(93,10,1,3,'NORMAL','ENABLED'),(94,10,1,4,'NORMAL','ENABLED'),(95,10,1,5,'NORMAL','ENABLED'),
  (96,10,1,6,'NORMAL','ENABLED'),(97,10,1,7,'NORMAL','ENABLED'),(98,10,1,8,'NORMAL','ENABLED'),(99,10,2,1,'NORMAL','ENABLED'),(100,10,2,2,'NORMAL','ENABLED');

-- ---------- 5. screenings（10 条）----------
INSERT IGNORE INTO screenings
  (screening_id, movie_id, hall_id, start_time, end_time, language_version, subtitle, ticket_price, screening_status)
VALUES
  (1,1,1,'2026-11-24 10:00:00','2026-11-24 12:50:00','ORIGINAL','CHINESE',45.00,'ENDED'),
  (2,2,2,'2026-11-24 13:00:00','2026-11-24 14:50:00','CHINESE','CHINESE',35.00,'ENDED'),
  (3,3,3,'2026-12-24 15:00:00','2026-12-24 17:22:00','ORIGINAL','CHINESE',50.00,'SELLING'),
  (4,4,4,'2026-12-24 18:00:00','2026-12-24 20:05:00','ORIGINAL','CHINESE',40.00,'SELLING'),
  (5,5,5,'2026-12-25 10:30:00','2026-12-25 13:12:00','ORIGINAL','CHINESE',50.00,'SELLING'),
  (6,6,6,'2026-12-25 14:00:00','2026-12-25 16:28:00','ORIGINAL','CHINESE',45.00,'SELLING'),
  (7,7,7,'2026-12-25 18:30:00','2026-12-25 20:35:00','CHINESE','CHINESE',48.00,'SELLING'),
  (8,8,8,'2026-12-26 09:30:00','2026-12-26 11:18:00','CHINESE','CHINESE',38.00,'SELLING'),
  (9,9,9,'2026-12-26 14:30:00','2026-12-26 17:25:00','ORIGINAL','CHINESE',48.00,'SELLING'),
  (10,1,10,'2026-12-26 19:00:00','2026-12-26 21:49:00','ORIGINAL','CHINESE',45.00,'SELLING');

-- ---------- 6. orders（10 条）----------
INSERT IGNORE INTO orders
  (order_id, order_number, user_id, screening_id, total_amount, ordered_at, paid_at, order_status)
VALUES
  (1,'OD202611240001',1,1,90.00,'2026-11-23 10:05:00','2026-11-23 10:06:00','PAID'),
  (2,'OD202611240002',2,2,70.00,'2026-11-23 11:10:00','2026-11-23 11:11:00','PAID'),
  (3,'OD202612240003',3,3,100.00,'2026-12-23 12:20:00','2026-12-23 12:21:00','PAID'),
  (4,'OD202611240004',4,1,45.00,'2026-11-23 13:30:00','2026-11-23 13:31:00','PAID'),
  (5,'OD202612250005',5,5,50.00,'2026-12-24 14:40:00','2026-12-24 14:41:00','PAID'),
  (6,'OD202612250006',6,6,90.00,'2026-12-24 15:50:00','2026-12-24 15:51:00','PAID'),
  (7,'OD202612250007',7,7,48.00,'2026-12-24 16:15:00','2026-12-24 16:16:00','PAID'),
  (8,'OD202612260008',8,8,38.00,'2026-12-25 17:25:00','2026-12-25 17:26:00','PAID'),
  (9,'OD202612260009',9,9,96.00,'2026-12-25 18:35:00','2026-12-25 18:36:00','PAID'),
  (10,'OD202612260010',10,10,45.00,'2026-12-25 19:45:00',NULL,'REFUNDED');

-- ---------- 7. seat_occupancies（18 条：14 张票对应的 SOLD + 4 条 AVAILABLE）----------
-- 重要：tickets 通过 (screening_id, seat_id) 复合外键引用本表，必须先插本表。
--       AVAILABLE 时 order_id 必须为 NULL（ck_occupancies_owner）。
INSERT IGNORE INTO seat_occupancies
  (screening_id, seat_id, order_id, occupancy_status, locked_at, lock_expires_at)
VALUES
  (1,1,1,'SOLD','2026-11-23 10:05:00',NULL),
  (1,2,1,'SOLD','2026-11-23 10:05:00',NULL),
  (1,3,4,'SOLD','2026-11-23 13:30:00',NULL),
  (2,11,2,'SOLD','2026-11-23 11:10:00',NULL),
  (2,12,2,'SOLD','2026-11-23 11:10:00',NULL),
  (3,21,3,'SOLD','2026-12-23 12:20:00',NULL),
  (3,22,3,'SOLD','2026-12-23 12:20:00',NULL),
  (5,41,5,'SOLD','2026-12-24 14:40:00',NULL),
  (6,51,6,'SOLD','2026-12-24 15:50:00',NULL),
  (6,52,6,'SOLD','2026-12-24 15:50:00',NULL),
  (7,61,7,'SOLD','2026-12-24 16:15:00',NULL),
  (8,71,8,'SOLD','2026-12-25 17:25:00',NULL),
  (9,81,9,'SOLD','2026-12-25 18:35:00',NULL),
  (9,82,9,'SOLD','2026-12-25 18:35:00',NULL),
  (10,91,NULL,'AVAILABLE',NULL,NULL),
  (10,92,NULL,'AVAILABLE',NULL,NULL),
  (3,23,NULL,'AVAILABLE',NULL,NULL),
  (3,24,NULL,'AVAILABLE',NULL,NULL);

-- ---------- 8. tickets（14 条；screening+seat 组合已在占用表存在）----------
INSERT IGNORE INTO tickets
  (ticket_id, ticket_number, order_id, screening_id, seat_id, row_number_snapshot, column_number_snapshot, ticket_price, ticket_status, issued_at)
VALUES
  (1,'TK001',1,1,1,1,1,45.00,'VALID','2026-11-23 10:06:00'),
  (2,'TK002',1,1,2,1,2,45.00,'VALID','2026-11-23 10:06:00'),
  (3,'TK003',2,2,11,1,1,35.00,'VALID','2026-11-23 11:11:00'),
  (4,'TK004',2,2,12,1,2,35.00,'VALID','2026-11-23 11:11:00'),
  (5,'TK005',3,3,21,1,1,50.00,'VALID','2026-12-23 12:21:00'),
  (6,'TK006',3,3,22,1,2,50.00,'VALID','2026-12-23 12:21:00'),
  (7,'TK007',4,1,3,1,3,45.00,'VALID','2026-11-23 13:31:00'),
  (8,'TK008',5,5,41,1,1,50.00,'VALID','2026-12-24 14:41:00'),
  (9,'TK009',6,6,51,1,1,45.00,'VALID','2026-12-24 15:51:00'),
  (10,'TK010',6,6,52,1,2,45.00,'VALID','2026-12-24 15:51:00'),
  (11,'TK011',7,7,61,1,1,48.00,'VALID','2026-12-24 16:16:00'),
  (12,'TK012',8,8,71,1,1,38.00,'VALID','2026-12-25 17:26:00'),
  (13,'TK013',9,9,81,1,1,48.00,'VALID','2026-12-25 18:36:00'),
  (14,'TK014',9,9,82,1,2,48.00,'VALID','2026-12-25 18:36:00');

-- ============================================================
-- 测试数据初始化完成
-- ============================================================
