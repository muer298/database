# 电影院票务预订管理系统

这是电影院票务预订管理系统课程项目的协作仓库。当前版本为**第 1 周综合交付版 v1.0**，已经把成员 A 的需求分析、E-R 设计和数据库关系模式，与成员 B 的 Java、Maven、JDBC 项目骨架整合到同一份可执行项目中。

当前已经完成数据库设计定稿、建表与测试数据脚本、Java 编译和 MySQL 实际连接验证。DAO 中除连接计数示例外仍以接口骨架为主，购票和退票事务尚未实现，不应把它们作为已完成功能展示。

## 成员分工

| 成员 | 主要职责 | 需要重点查看的目录 |
|---|---|---|
| A | 需求分析、E-R 图、关系模式、约束、业务规则与测试场景 | `docs/`、`sql/`、本 README |
| B | Java、JDBC、DAO、Service、事务、命令行入口与代码测试 | `src/`、`pom.xml`、`sql/`、本 README |

A 不需要逐行审查 B 的全部 Java 实现，但必须审核数据库字段、状态、业务规则和 SQL 结构变更。B 可以独立实现普通 DAO 代码，但不得私自改变双方已经确认的数据库契约。

## 仓库内容

```text
CinemaTicketSystem
├── README.md
├── pom.xml
├── docs
│   ├── schema-contract.md
│   ├── er-diagram-v1.png
│   ├── week1-handoff.md
│   ├── week1-db-connection-success.jpg
│   └── 电影院票务预订管理系统_第1周综合报告.docx
├── sql
│   ├── README.md
│   ├── create_tables.sql
│   └── insert_data.sql
├── src/main/java/edu/course/cinema
│   ├── Main.java
│   ├── util/DBUtil.java
│   ├── dao
│   └── service
└── tools
    └── build_week1_report.py
```

主要文件说明：

- `docs/schema-contract.md`：A 与 B 共同遵守的数据库接口约定 v1.0。
- `docs/er-diagram-v1.png`：修订后的 8 表 E-R 图。
- `docs/电影院票务预订管理系统_第1周综合报告.docx`：第一周完整报告和验收结论。
- `sql/create_tables.sql`：创建数据库、8 张表、索引、外键和检查约束。
- `sql/insert_data.sql`：可重复执行的最小联调数据。
- `src/main/java`：B 负责的 Java/JDBC 工程。
- `docs/week1-db-connection-success.jpg`：Java 连接 MySQL 成功的验收记录。

## 第 1 周完成情况

- [x] 明确普通用户和管理员的系统范围。
- [x] 完成 7 个基础实体和 `seat_occupancies` 关联实体设计。
- [x] 统一主键、外键、唯一约束、金额和时间类型。
- [x] 统一订单、电影票、场次和场次座位状态。
- [x] 完成 `create_tables.sql` 和 `insert_data.sql`。
- [x] 本机创建 8 张表并插入最小测试数据。
- [x] 完成 Java 17、Maven 和 Connector/J 项目骨架。
- [x] `mvn clean compile` 通过。
- [x] IntelliJ IDEA 项目构建通过。
- [x] Java 程序实际连接 MySQL 成功。

## 数据库设计摘要

系统包含以下 8 张表：

```text
users, movies, halls, seats,
screenings, orders, seat_occupancies, tickets
```

关键约定：

- 用户角色为 `CUSTOMER` 或 `ADMIN`。
- 一个订单只能购买同一场次的一张或多张票。
- `seat_occupancies` 使用 `(screening_id, seat_id)` 联合主键。
- 座位销售状态为 `AVAILABLE → LOCKED → SOLD`，退票恢复 `AVAILABLE`。
- 订单、电影票和已有业务数据的场次不进行级联物理删除。
- 金额统一使用 `DECIMAL(10,2)`，业务时间使用 `DATETIME`。

更完整的规则请阅读 `docs/schema-contract.md`，实际字段以 `sql/create_tables.sql` 为准。

## 开发环境

- JDK 17 或 21，编译目标 Java 17
- Maven 3.9+
- MySQL 8.x，建议使用 MySQL 8.4 LTS
- MySQL Connector/J 8.4.0
- IntelliJ IDEA，可选

## 初始化数据库

使用有建库权限的 MySQL 账号执行：

```bash
mysql -u root -p < sql/create_tables.sql
mysql -u root -p < sql/insert_data.sql
```

也可以在 IntelliJ IDEA 数据库控制台中依次执行两个文件。

如果需要创建应用账号，可在 MySQL 管理员会话中执行：

```sql
CREATE USER IF NOT EXISTS 'cinema_app'@'localhost'
  IDENTIFIED BY '请替换成你自己的强密码';

GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, INDEX, REFERENCES
ON cinema_ticket.* TO 'cinema_app'@'localhost';
```

不要把真实密码写入 SQL、Java 或 Git 仓库。

## 运行项目

macOS 或 Linux：

```bash
export CINEMA_DB_URL='jdbc:mysql://localhost:3306/cinema_ticket?useUnicode=true&characterEncoding=utf8&connectionTimeZone=LOCAL'
export CINEMA_DB_USER='cinema_app'
export CINEMA_DB_PASSWORD='你的本机数据库密码'
mvn clean compile exec:java
```

Windows PowerShell：

```powershell
$env:CINEMA_DB_URL = 'jdbc:mysql://localhost:3306/cinema_ticket?useUnicode=true&characterEncoding=utf8&connectionTimeZone=LOCAL'
$env:CINEMA_DB_USER = 'cinema_app'
$env:CINEMA_DB_PASSWORD = '你的本机数据库密码'
mvn clean compile exec:java
```

运行后选择菜单 `1` 测试数据库连接。

## 第 2 周任务

### 成员 A

1. 在 MySQL 8.4 LTS 环境再次执行建表和测试数据脚本，记录兼容性结果。
2. 根据教师反馈维护 E-R 图、关系模式和 `schema-contract.md`；需要修改时升级版本号。
3. 补充第二周查询需求和预期结果，包括电影查询、场次查询、余座查询、用户订单查询和基础票房统计。
4. 准备正常数据、重复座位、冲突场次、非法状态和外键失败等测试场景。
5. 审核 B 提交的数据库字段映射和涉及业务规则的 Pull Request。

### 成员 B

1. 建立 `User`、`Movie`、`Hall`、`Seat`、`Screening` 等 Java 实体类和状态枚举。
2. 实现 `UserDAO`、`MovieDAO`、`HallDAO`、`SeatDAO` 和 `ScreeningDAO`。
3. 实现电影列表、按日期查询场次、查询场次详情和查询可售座位。
4. 所有 SQL 使用 `PreparedStatement`，金额使用 `BigDecimal`，日期时间使用 `LocalDate` 或 `LocalDateTime`。
5. 为 DAO 增加正常路径、空结果、唯一约束和外键异常测试。
6. 扩展命令行菜单，使管理员可以维护电影和场次，普通用户可以查询电影、场次和可售座位。
7. 开始设计 `BookingService` 的事务与并发锁座方案，但完整购票和退票事务放到后续计划实现。

### 第二周共同验收标准

- MySQL 8.4 LTS 建表和测试数据执行通过。
- Java 实体字段与 `schema-contract.md` 完全一致。
- 至少完成用户、电影、影厅、座位和场次的核心 DAO。
- 电影、场次和可售座位查询可以从命令行实际运行。
- 不出现字符串拼接 SQL、硬编码密码或未关闭 JDBC 资源。
- 数据库结构如有变更，A 与 B 已共同更新 SQL、契约和 README。

## Git 协作建议

- `main` 保存可以编译、可以运行的稳定版本。
- A 和 B 分别在功能分支工作，例如 `a/schema-v1.1`、`b/movie-dao`。
- 涉及表结构、状态或业务规则的修改必须通过 Pull Request 让双方确认。
- 普通 Java 重构可由 B 主责，但合并前必须通过编译和测试。
- 不提交 `.env`、数据库密码、`.idea/`、`target/`、`*.iml` 或个人配置。
