# 成员 B 第二周交付说明

数据库基线：A/B 联合确认的 `schema-contract.md` v1.1。

## 已完成

- 建立 `User`、`Movie`、`Hall`、`Seat`、`Screening` Java 实体以及对应状态枚举。
- 实现 `UserDAO`、`MovieDAO`、`HallDAO`、`SeatDAO`、`ScreeningDAO`。
- 实现场次座位初始化 DAO；新增场次时在同一事务中完成时间冲突检查、场次插入和全部启用座位初始化。
- 实现电影列表、按电影和日期查询场次、查询场次可售座位。
- 命令行支持数据库连接测试、三项查询、管理员新增电影和管理员新增场次。
- JDBC 全部使用 `PreparedStatement` 和 try-with-resources；金额、日期、日期时间分别映射为 `BigDecimal`、`LocalDate`、`LocalDateTime`。

## 测试结果

在临时 MySQL 8.4 空库中依次执行 `create_tables.sql`、`insert_data.sql` 后运行集成测试：

- 5 项测试全部通过，0 failure、0 error。
- 覆盖正常查询、空结果、用户/电影/影厅唯一约束、场次外键失败、排片时间冲突、可售座位数量。
- 验证新增场次后会自动生成 10 条 `AVAILABLE` 场次座位记录。
- 命令行实测可列出电影、查询指定日期场次，并返回场次 3 的 8 个可售座位。

测试类：`src/test/java/edu/course/cinema/dao/CoreDaoIntegrationTest.java`。

## 尚未实现

- `OrderDAO`、`TicketDAO` 和完整 `SeatOccupancyDAO` 写操作。
- 购票、支付、并发锁座、锁超时释放与整单退票事务。
- 登录鉴权和根据用户角色隐藏管理员菜单。

以上内容属于后续周次；第二周不得把占位的购票、退票服务作为已完成功能展示。
