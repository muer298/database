# SQL 目录

第 1 周综合版已冻结数据库接口，文件用途如下：

- `create_tables.sql`：创建 `cinema_ticket` 数据库、8 张表、索引和完整性约束。
- `insert_data.sql`：插入可重复执行的最小联调数据，并初始化场次座位。
- 后续 `query.sql`：第 2 周根据课程要求补充单表、连接、分组、嵌套和综合查询。

## 初始化

使用有建库权限的 MySQL 账号执行：

```bash
mysql -u root -p < sql/create_tables.sql
mysql -u root -p < sql/insert_data.sql
```

也可以在 IntelliJ IDEA 的数据库控制台中按顺序执行两个文件。

## 注意事项

- 脚本不会删除已有表或历史数据。
- 表已存在但结构不同的时候，不要强行覆盖，应先由 A、B 确认迁移方案。
- 应用程序密码只能通过环境变量设置，不得写入 SQL、Java 源码或 Git 仓库。
