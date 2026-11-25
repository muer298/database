# SQL 目录

数据库契约版本为 **v1.1**（见 `docs/schema-contract.md`）。三份脚本用途如下：

- `create_tables.sql`：创建 `cinema_ticket` 数据库、8 张表、主键/外键/唯一/检查约束和索引。
- `insert_data.sql`：初始化测试数据，每张核心表不少于 10 条记录，并初始化场次座位占用。
- `query.sql`：第 2 周按课程要求编写的单表、连接、分组、嵌套和综合查询，共 8 条。

## 初始化

使用有建库权限的 MySQL 账号执行：

```bash
mysql -u root -p < sql/create_tables.sql
mysql -u root -p < sql/insert_data.sql
mysql -u root -p < sql/query.sql
```

也可以在 IntelliJ IDEA 的数据库控制台中按顺序执行三个文件。

## 脚本要点

- `create_tables.sql` 中 `movies.release_date` 为 `NOT NULL`，保证 `(title, release_date)` 组合唯一约束生效（v1.1 变更）。
- `insert_data.sql` 按外键依赖顺序插入：先基础表（用户、电影、影厅、座位），再场次、订单、座位占用，最后电影票；每张票都有对应的 `seat_occupancies` 记录，避免外键失败。
- `insert_data.sql` 可重复执行（`INSERT IGNORE`），不会破坏已有业务数据。
- `query.sql` 的 8 条查询覆盖：单表条件查询 2 条、多表连接查询 2 条、分组统计 1 条、嵌套查询 2 条、复杂业务查询 1 条。

## 注意事项

- 脚本不会删除已有表或历史数据。
- 表已存在但结构不同时，不要强行覆盖，应先由 A、B 确认迁移方案。
- 应用程序密码只能通过环境变量设置，不得写入 SQL、Java 源码或 Git 仓库。
- 执行截图保存在 `docs/` 下，作为第 2 周验收材料。
