# A/B 数据库接口约定 v1.1

状态：在第 1 周综合版基础上升级。成员 A 负责业务规则与关系模式，成员 B 依据本约定实现 JDBC、DAO 和事务服务。后续如需修改字段，必须由 A、B 同时确认并更新版本号。

v1.1 变更（成员 A 提出，待 Pull Request 双方确认）：`movies.release_date` 由可空改为非空，使 `(title, release_date)` 组合唯一约束真正生效；对应 SQL 见 `sql/create_tables.sql`。

## 1. 统一设计结论

1. 系统采用 `users`、`movies`、`halls`、`seats`、`screenings`、`orders`、`tickets`、`seat_occupancies` 共 8 张表。
2. 普通用户与管理员统一保存在 `users`，由 `role` 区分 `CUSTOMER` 和 `ADMIN`。
3. 一个订单只能购买同一场次的一张或多张票。
4. `seat_occupancies` 为场次与座位的关联实体，联合主键为 `(screening_id, seat_id)`。
5. 创建场次时，为该影厅全部 `ENABLED` 座位生成 `AVAILABLE` 占用记录。
6. 订单、票和场次属于业务历史数据，外键采用 `RESTRICT`，不做级联物理删除。
7. 金额统一使用 `DECIMAL(10,2)`；业务时间统一使用 `DATETIME`，按数据库服务器所在的 `Asia/Shanghai` 本地时间保存。
8. 所有 SQL 使用参数化 `PreparedStatement`；DAO 不提交跨表事务，Service 负责事务边界。

## 2. 表与关键字段

| 表 | 主键 | 主要字段与约束 |
|---|---|---|
| `users` | `user_id` | `username` 唯一；`phone`、`email` 可空且分别唯一；`role`、`account_status` 有状态约束 |
| `movies` | `movie_id` | `(title, release_date)` 唯一且 `release_date` 非空；时长大于 0；基准票价不小于 0 |
| `halls` | `hall_id` | `hall_name` 唯一；保存排数与列数，总座位数由 `seats` 统计 |
| `seats` | `seat_id` | 外键 `hall_id`；`(hall_id, seat_row, seat_column)` 唯一 |
| `screenings` | `screening_id` | 外键 `movie_id`、`hall_id`；结束时间晚于开始时间；票价不小于 0 |
| `orders` | `order_id` | `order_number` 唯一；外键 `user_id`、`screening_id`；金额不小于 0 |
| `seat_occupancies` | `(screening_id, seat_id)` | 可关联当前 `order_id`；状态为 `AVAILABLE`、`LOCKED` 或 `SOLD` |
| `tickets` | `ticket_id` | `ticket_number` 唯一；同时关联订单和场次座位；保存排号、列号、成交价快照 |

完整字段、索引和外键以 `sql/create_tables.sql` 为准。

## 3. 状态定义与流转

### 3.1 用户

- `NORMAL`：允许登录、查询和购票。
- `FROZEN`：禁止新购票，保留历史订单。

### 3.2 电影

- `UPCOMING`：待上映。
- `SHOWING`：上映中。
- `OFFLINE`：已下映。

### 3.3 场次

- `SCHEDULED`：已排片，尚未开放售票。
- `SELLING`：允许购票。
- `ENDED`：已结束。
- `CANCELLED`：已取消，不允许购票。

### 3.4 订单

- `PENDING`：已创建，尚未完成模拟支付。
- `PAID`：已支付并出票。
- `CANCELLED`：未支付订单取消。
- `REFUNDED`：整单退票完成。

允许的主要流转为 `PENDING → PAID`、`PENDING → CANCELLED`、`PAID → REFUNDED`。

### 3.5 电影票

- `VALID`：有效、未使用。
- `USED`：已使用。
- `REFUNDED`：已退票。

### 3.6 场次座位

- `AVAILABLE`：可售，`order_id` 为空。
- `LOCKED`：购票事务或短时支付流程锁定，`order_id` 非空。
- `SOLD`：出票完成，`order_id` 非空。

允许的主要流转为 `AVAILABLE → LOCKED → SOLD`。事务失败或锁定超时执行 `LOCKED → AVAILABLE`；整单退票执行 `SOLD → AVAILABLE` 并清空当前 `order_id`。历史信息保留在订单和电影票中。

## 4. 核心业务规则

1. 只有 `NORMAL` 用户才能创建订单。
2. 只有状态为 `SELLING` 且开场时间晚于当前时间的场次允许购票。
3. 所选座位必须属于场次对应影厅，且物理状态为 `ENABLED`。
4. 锁座必须在事务内通过条件更新或 `SELECT ... FOR UPDATE` 实现；任何座位锁定失败时整单回滚。
5. 订单总金额等于该订单所有电影票成交价之和。
6. 目前只允许整单退票，且必须在开场前、订单为 `PAID`、所有票为 `VALID` 时执行。
7. 场次时间冲突由 `ScreeningDAO` 在新增或修改场次前检查：同一影厅内不得出现时间区间重叠。
8. 不物理删除已有订单、电影票或已产生业务数据的场次；使用状态字段保留历史。
9. 票房统计只统计 `PAID` 订单或 `VALID`、`USED` 电影票，不包含已退款记录。

## 5. Java 与数据库映射约定

| SQL 类型 | Java 建议类型 |
|---|---|
| `BIGINT UNSIGNED` | `long` / `Long` |
| `SMALLINT UNSIGNED` | `int` / `Integer` |
| `DECIMAL(10,2)` | `BigDecimal` |
| `DATE` | `LocalDate` |
| `DATETIME` | `LocalDateTime` |
| 状态 `VARCHAR` | Java `enum`，写库时使用枚举名称 |

数据库列采用 `snake_case`，Java 字段采用 `camelCase`。数据库生成的主键通过 `Statement.RETURN_GENERATED_KEYS` 读取。

## 6. B 层计划接口

| 类 | 第 2 至 3 周接口 |
|---|---|
| `UserDAO` | `findById`、`findByUsername`、`insert`、`updateStatus` |
| `MovieDAO` | `create`、`findById`、`list`、`update`、`updateStatus` |
| `HallDAO` | `create`、`findById`、`list` |
| `ScreeningDAO` | `create`、`findById`、`listByMovieAndDate`、`hasTimeConflict` |
| `SeatDAO` | `listByHall`、`listAvailableByScreening` |
| `OrderDAO` | `insert`、`findByUser`、`findDetails`、`updateStatus` |
| `TicketDAO` | `insertBatch`、`findByOrder`、`updateStatusByOrder` |
| `SeatOccupancyDAO` | `initializeForScreening`、`lockSeats`、`markSold`、`releaseByOrder` |
| `BookingService` | `book(userId, screeningId, seatIds)`，一个事务 |
| `RefundService` | `refund(orderId, userId)`，一个事务 |

## 7. 变更流程

如需修改表名、字段、状态或约束，提出者先说明业务原因和 Java 影响，再由 A、B 共同更新本文件及 SQL。B 不应只在 Java 中私自兼容未确认的数据库变更，A 也不应只修改 E-R 图而不更新 SQL 和接口约定。
