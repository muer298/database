package edu.course.cinema.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/** Centralizes JDBC connection configuration. Credentials are never hardcoded. */
public final class DBUtil {
    private DBUtil() { }

    public static Connection getConnection() throws SQLException {
        String url = env("CINEMA_DB_URL", "jdbc:mysql://localhost:3306/cinema_ticket?useUnicode=true&characterEncoding=utf8&connectionTimeZone=LOCAL");
        String user = env("CINEMA_DB_USER", "cinema_app");
        String password = System.getenv("CINEMA_DB_PASSWORD");
        if (password == null) {
            throw new SQLException("未设置 CINEMA_DB_PASSWORD 环境变量，请先按 README 配置数据库账号。", "08001");
        }
        return DriverManager.getConnection(url, user, password);
    }

    private static String env(String key, String defaultValue) {
        String value = System.getenv(key);
        return value == null || value.isBlank() ? defaultValue : value;
    }
}
