# 电影院票务预订管理系统第 1 周综合交付与验收记录

## 成员 A 已完成

- 需求范围、用户角色、核心流程和业务规则说明。
- 7 个基础实体与场次座位关联实体设计。
- E-R 图及实体属性说明。
- 修正并冻结 A/B 数据库接口约定 v1.0。
- `sql/create_tables.sql` 建表脚本和 `sql/insert_data.sql` 最小测试数据。
- 用户角色、订单、电影票、场次座位状态及流转规则定稿。

## 成员 B 已完成

- Maven 项目配置（Java 17 目标、MySQL Connector/J 8.4.0）。
- JDBC 连接工具 `DBUtil`，环境变量配置，不硬编码密码。
- `dao/`、`service/`、`Main` 分层和后续类占位。
- 命令行菜单：连接测试、无效输入处理、退出。
- 与成员 A 的数据库接口约定和后续 DAO 接口清单。
- README：MySQL 初始化、Mac/Windows 运行步骤、截图注意事项。

## 已执行的验证

- 本机 Java 17.0.20.1、Maven 3.9.16、MySQL 9.6.0 环境检查：通过。
- `mvn clean compile` 编译全部 9 个 Java 源文件：通过。
- IntelliJ IDEA 2026.3 导入 Maven 项目并执行项目构建：通过。
- 使用 `cinema_app@localhost` 连接 `cinema_ticket`：通过。
- 运行 `Main` 并输入 `1`：显示“数据库连接成功”、MySQL 9.6.0 和当前目录 `cinema_ticket`。
- 输入 `0`：正常退出。
- 连接成功截图：`docs/week1-db-connection-success.jpg`，不包含数据库密码。

## 第 1 周综合验收结论

- A 的需求与数据库设计、B 的 Java 项目骨架、Maven、JDBC 与 MySQL 实际连接已形成完整的第 1 周综合版本。
- 本机测试使用 MySQL 9.6.0；若课程提交环境强制要求 MySQL 8.x，第二周联调前需再做一次目标版本兼容性验证。
- 第 2 周可以按 `docs/schema-contract.md` v1.0 和 `sql/create_tables.sql` 开始 DAO 与查询功能开发。

## 本机配置说明

- 本地连接变量保存在根目录 `.env`，初始化 SQL 保存在 `.idea/init-local.sql`。
- 两个文件权限均为 `600`，且已被 `.gitignore` 排除，不得提交或对外发送。
- 本机运行命令：`source .env && mvn -q exec:java`。

## 下一阶段协作

- A 维护需求、E-R 图、业务状态与数据库约束，审核任何结构变更。
- B 维护 Java、JDBC、DAO 和 Service，实现并测试数据库操作。
- A 不需要逐行阅读 B 的全部 Java 代码，但必须审核 `schema-contract.md`、SQL 和涉及业务规则的接口变更。
- B 不需要等待 A 审核每个普通 Java 实现细节，但数据库字段、状态和业务规则变更必须双方确认。
