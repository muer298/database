package edu.course.cinema;

import edu.course.cinema.util.DBUtil;
import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.SQLException;
import java.util.Scanner;

/** Week 1 startup and connection verification menu. */
public final class Main {
    private Main() { }

    public static void main(String[] args) {
        try (Scanner scanner = new Scanner(System.in)) {
            while (true) {
                System.out.println("\n=== 电影院票务预订管理系统（第 1 周骨架） ===");
                System.out.println("1. 测试 MySQL 数据库连接");
                System.out.println("0. 退出");
                System.out.print("请选择：");
                if (!scanner.hasNextLine()) return;
                String choice = scanner.nextLine().trim();
                switch (choice) {
                    case "1" -> testConnection();
                    case "0" -> { System.out.println("程序已退出。"); return; }
                    default -> System.out.println("无效选项，请输入 1 或 0。");
                }
            }
        }
    }

    private static void testConnection() {
        try (Connection connection = DBUtil.getConnection()) {
            if (!connection.isValid(3)) {
                System.out.println("连接已建立，但有效性检查未通过。");
                return;
            }
            DatabaseMetaData meta = connection.getMetaData();
            System.out.println("数据库连接成功！");
            System.out.println("数据库：" + meta.getDatabaseProductName() + " " + meta.getDatabaseProductVersion());
            System.out.println("当前目录：" + connection.getCatalog());
        } catch (SQLException error) {
            System.out.println("数据库连接失败：" + error.getMessage());
            System.out.println("SQLState=" + error.getSQLState() + "，错误码=" + error.getErrorCode());
        }
    }
}
