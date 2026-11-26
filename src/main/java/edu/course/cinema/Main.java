package edu.course.cinema;

import edu.course.cinema.dao.MovieDAO;
import edu.course.cinema.dao.ScreeningDAO;
import edu.course.cinema.dao.SeatDAO;
import edu.course.cinema.model.Movie;
import edu.course.cinema.model.MovieStatus;
import edu.course.cinema.model.Screening;
import edu.course.cinema.model.ScreeningStatus;
import edu.course.cinema.model.Seat;
import edu.course.cinema.service.ScreeningService;
import edu.course.cinema.util.DBUtil;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Scanner;

/** Week 2 command-line client for core movie, screening, and seat operations. */
public final class Main {
    private static final MovieDAO MOVIES = new MovieDAO();
    private static final ScreeningDAO SCREENINGS = new ScreeningDAO();
    private static final SeatDAO SEATS = new SeatDAO();
    private static final DateTimeFormatter DATE_TIME = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    private Main() { }

    public static void main(String[] args) {
        try (Scanner scanner = new Scanner(System.in)) {
            while (true) {
                printMenu();
                if (!scanner.hasNextLine()) return;
                try {
                    switch (scanner.nextLine().trim()) {
                        case "1" -> testConnection();
                        case "2" -> listMovies();
                        case "3" -> listScreenings(scanner);
                        case "4" -> listAvailableSeats(scanner);
                        case "5" -> addMovie(scanner);
                        case "6" -> addScreening(scanner);
                        case "0" -> { System.out.println("程序已退出。"); return; }
                        default -> System.out.println("无效选项，请重新输入。");
                    }
                } catch (SQLException error) {
                    System.out.printf("数据库操作失败：%s（SQLState=%s，错误码=%d）%n",
                            error.getMessage(), error.getSQLState(), error.getErrorCode());
                } catch (IllegalArgumentException error) {
                    System.out.println("输入无效：" + error.getMessage());
                }
            }
        }
    }

    private static void printMenu() {
        System.out.println("\n=== 电影院票务预订管理系统（第 2 周） ===");
        System.out.println("1. 测试 MySQL 数据库连接");
        System.out.println("2. 查看电影列表");
        System.out.println("3. 按电影和日期查询场次");
        System.out.println("4. 查询场次可售座位");
        System.out.println("5. 管理员新增电影");
        System.out.println("6. 管理员新增场次");
        System.out.println("0. 退出");
        System.out.print("请选择：");
    }

    private static void testConnection() throws SQLException {
        try (Connection connection = DBUtil.getConnection()) {
            if (!connection.isValid(3)) throw new SQLException("连接有效性检查未通过", "08006");
            DatabaseMetaData meta = connection.getMetaData();
            System.out.printf("数据库连接成功：%s %s，当前库：%s%n",
                    meta.getDatabaseProductName(), meta.getDatabaseProductVersion(), connection.getCatalog());
        }
    }

    private static void listMovies() throws SQLException {
        try (Connection connection = DBUtil.getConnection()) {
            List<Movie> movies = MOVIES.list(connection);
            if (movies.isEmpty()) {
                System.out.println("暂无电影。");
                return;
            }
            System.out.println("ID | 片名 | 类型 | 时长 | 上映日期 | 票价 | 状态");
            movies.forEach(movie -> System.out.printf("%d | %s | %s | %d分钟 | %s | %s | %s%n",
                    movie.id(), movie.title(), text(movie.genre()), movie.durationMinutes(),
                    movie.releaseDate(), movie.basePrice(), movie.showingStatus()));
        }
    }

    private static void listScreenings(Scanner scanner) throws SQLException {
        long movieId = readLong(scanner, "电影 ID：");
        LocalDate date = readDate(scanner, "日期（yyyy-MM-dd）：");
        try (Connection connection = DBUtil.getConnection()) {
            List<Screening> screenings = SCREENINGS.listByMovieAndDate(connection, movieId, date);
            if (screenings.isEmpty()) {
                System.out.println("该日期暂无场次。");
                return;
            }
            screenings.forEach(screening -> System.out.printf(
                    "场次%d | 影厅%d | %s - %s | %s元 | %s%n",
                    screening.id(), screening.hallId(), screening.startTime().format(DATE_TIME),
                    screening.endTime().format(DATE_TIME), screening.ticketPrice(), screening.status()));
        }
    }

    private static void listAvailableSeats(Scanner scanner) throws SQLException {
        long screeningId = readLong(scanner, "场次 ID：");
        try (Connection connection = DBUtil.getConnection()) {
            List<Seat> seats = SEATS.listAvailableByScreening(connection, screeningId);
            if (seats.isEmpty()) {
                System.out.println("没有可售座位，或场次不存在/尚未初始化座位。");
                return;
            }
            System.out.printf("可售座位共 %d 个：%n", seats.size());
            seats.forEach(seat -> System.out.printf("座位%d（%d排%d列，%s）%n",
                    seat.id(), seat.row(), seat.column(), seat.type()));
        }
    }

    private static void addMovie(Scanner scanner) throws SQLException {
        System.out.print("片名：");
        String title = require(scanner.nextLine(), "片名");
        System.out.print("导演（可空）：");
        String director = blankToNull(scanner.nextLine());
        System.out.print("主演展示文本（可空）：");
        String actors = blankToNull(scanner.nextLine());
        System.out.print("类型（可空）：");
        String genre = blankToNull(scanner.nextLine());
        int duration = Math.toIntExact(readLong(scanner, "时长（分钟）："));
        LocalDate releaseDate = readDate(scanner, "上映日期（yyyy-MM-dd）：");
        BigDecimal price = readMoney(scanner, "参考票价：");
        System.out.print("简介（可空）：");
        String synopsis = blankToNull(scanner.nextLine());
        Movie movie = new Movie(0, title, director, actors, genre, duration, releaseDate,
                price, synopsis, null, MovieStatus.UPCOMING);
        try (Connection connection = DBUtil.getConnection()) {
            System.out.println("新增电影成功，ID=" + MOVIES.create(connection, movie));
        }
    }

    private static void addScreening(Scanner scanner) throws SQLException {
        long movieId = readLong(scanner, "电影 ID：");
        long hallId = readLong(scanner, "影厅 ID：");
        LocalDateTime start = readDateTime(scanner, "开始时间（yyyy-MM-dd HH:mm）：");
        LocalDateTime end = readDateTime(scanner, "结束时间（yyyy-MM-dd HH:mm）：");
        BigDecimal price = readMoney(scanner, "场次票价：");
        Screening screening = new Screening(0, movieId, hallId, start, end,
                "ORIGINAL", "CHINESE", price, ScreeningStatus.SELLING);
        long id = new ScreeningService().schedule(screening);
        System.out.println("新增场次并初始化座位成功，ID=" + id);
    }

    private static long readLong(Scanner scanner, String prompt) {
        System.out.print(prompt);
        try {
            long value = Long.parseLong(scanner.nextLine().trim());
            if (value <= 0) throw new NumberFormatException();
            return value;
        } catch (NumberFormatException error) {
            throw new IllegalArgumentException("请输入正整数");
        }
    }

    private static BigDecimal readMoney(Scanner scanner, String prompt) {
        System.out.print(prompt);
        try {
            BigDecimal value = new BigDecimal(scanner.nextLine().trim());
            if (value.signum() < 0) throw new NumberFormatException();
            return value;
        } catch (NumberFormatException error) {
            throw new IllegalArgumentException("请输入非负金额");
        }
    }

    private static LocalDate readDate(Scanner scanner, String prompt) {
        System.out.print(prompt);
        try {
            return LocalDate.parse(scanner.nextLine().trim());
        } catch (DateTimeParseException error) {
            throw new IllegalArgumentException("日期格式应为 yyyy-MM-dd");
        }
    }

    private static LocalDateTime readDateTime(Scanner scanner, String prompt) {
        System.out.print(prompt);
        try {
            return LocalDateTime.parse(scanner.nextLine().trim(), DATE_TIME);
        } catch (DateTimeParseException error) {
            throw new IllegalArgumentException("时间格式应为 yyyy-MM-dd HH:mm");
        }
    }

    private static String require(String value, String field) {
        if (value == null || value.isBlank()) throw new IllegalArgumentException(field + "不能为空");
        return value.trim();
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private static String text(String value) {
        return value == null ? "-" : value;
    }
}
