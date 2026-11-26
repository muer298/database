package edu.course.cinema.dao;

import edu.course.cinema.model.Movie;
import edu.course.cinema.model.MovieStatus;
import edu.course.cinema.model.AccountStatus;
import edu.course.cinema.model.Hall;
import edu.course.cinema.model.HallType;
import edu.course.cinema.model.Screening;
import edu.course.cinema.model.ScreeningStatus;
import edu.course.cinema.model.User;
import edu.course.cinema.model.UserRole;
import edu.course.cinema.service.ScreeningService;
import edu.course.cinema.util.DBUtil;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

class CoreDaoIntegrationTest {
    @BeforeAll
    static void requireExplicitTestDatabase() {
        assumeTrue("true".equalsIgnoreCase(System.getenv("CINEMA_RUN_DB_TESTS")),
                "设置 CINEMA_RUN_DB_TESTS=true 后才运行数据库集成测试");
    }

    @BeforeEach
    void removePreviousTestRows() throws Exception {
        String[] cleanupSql = {
                "DELETE FROM seat_occupancies WHERE screening_id IN "
                        + "(SELECT screening_id FROM screenings WHERE start_time='2099-02-01 07:00:00')",
                "DELETE FROM screenings WHERE start_time='2099-02-01 07:00:00'",
                "DELETE FROM movies WHERE title='DAO集成测试电影' AND release_date='2099-01-01'",
                "DELETE FROM users WHERE username='dao_test_user'",
                "DELETE FROM halls WHERE hall_name='DAO测试厅'"
        };
        try (Connection connection = DBUtil.getConnection()) {
            for (String sql : cleanupSql) {
                try (PreparedStatement statement = connection.prepareStatement(sql)) {
                    statement.executeUpdate();
                }
            }
        }
    }

    @Test
    void movieDaoCoversNormalEmptyAndUniqueConstraintPaths() throws Exception {
        MovieDAO dao = new MovieDAO();
        try (Connection connection = DBUtil.getConnection()) {
            assertEquals(10, dao.countMovies(connection));
            assertFalse(dao.findById(connection, 999_999).isPresent());

            Movie movie = new Movie(0, "DAO集成测试电影", "测试导演", null, "测试",
                    90, LocalDate.of(2099, 1, 1), new BigDecimal("19.90"),
                    null, null, MovieStatus.UPCOMING);
            long id = dao.create(connection, movie);
            assertEquals("DAO集成测试电影", dao.findById(connection, id).orElseThrow().title());
            assertThrows(SQLException.class, () -> dao.create(connection, movie));
        }
    }

    @Test
    void screeningAndSeatQueriesCoverConflictAndAvailability() throws Exception {
        ScreeningDAO screenings = new ScreeningDAO();
        SeatDAO seats = new SeatDAO();
        try (Connection connection = DBUtil.getConnection()) {
            assertTrue(screenings.hasTimeConflict(connection, 1,
                    LocalDateTime.of(2026, 11, 24, 11, 0),
                    LocalDateTime.of(2026, 11, 24, 13, 0), null));
            assertEquals(8, seats.listAvailableByScreening(connection, 3).size());
            assertTrue(screenings.listByMovieAndDate(connection, 1,
                    LocalDate.of(2026, 11, 24)).size() >= 1);
        }
    }

    @Test
    void userDaoCoversLookupInsertStatusAndUniqueConstraint() throws Exception {
        UserDAO dao = new UserDAO();
        try (Connection connection = DBUtil.getConnection()) {
            assertTrue(dao.findByUsername(connection, "zhangsan").isPresent());
            assertFalse(dao.findById(connection, 999_999).isPresent());
            User user = new User(0, "dao_test_user", "test-hash", "DAO测试用户",
                    null, null, UserRole.CUSTOMER, LocalDateTime.of(2099, 1, 1, 0, 0),
                    AccountStatus.NORMAL);
            long id = dao.insert(connection, user);
            assertTrue(dao.updateStatus(connection, id, AccountStatus.FROZEN));
            assertEquals(AccountStatus.FROZEN, dao.findById(connection, id).orElseThrow().accountStatus());
            assertThrows(SQLException.class, () -> dao.insert(connection, user));
        }
    }

    @Test
    void hallDaoCoversListCreateEmptyAndUniqueConstraint() throws Exception {
        HallDAO dao = new HallDAO();
        try (Connection connection = DBUtil.getConnection()) {
            assertEquals(10, dao.list(connection).size());
            assertFalse(dao.findById(connection, 999_999).isPresent());
            Hall hall = new Hall(0, "DAO测试厅", HallType.STANDARD, 2, 3);
            long id = dao.create(connection, hall);
            assertEquals("DAO测试厅", dao.findById(connection, id).orElseThrow().name());
            assertThrows(SQLException.class, () -> dao.create(connection, hall));
        }
    }

    @Test
    void schedulingInitializesSeatsAndRejectsForeignKeyFailure() throws Exception {
        Screening valid = new Screening(0, 1, 1,
                LocalDateTime.of(2099, 2, 1, 7, 0),
                LocalDateTime.of(2099, 2, 1, 9, 0),
                "ORIGINAL", "CHINESE", new BigDecimal("30.00"), ScreeningStatus.SELLING);
        long screeningId = new ScreeningService().schedule(valid);
        try (Connection connection = DBUtil.getConnection()) {
            assertEquals(10, new SeatDAO().listAvailableByScreening(connection, screeningId).size());
        }

        Screening invalid = new Screening(0, 999_999, 1,
                LocalDateTime.of(2099, 2, 1, 10, 0),
                LocalDateTime.of(2099, 2, 1, 12, 0),
                "ORIGINAL", "CHINESE", new BigDecimal("30.00"), ScreeningStatus.SELLING);
        assertThrows(SQLException.class, () -> new ScreeningService().schedule(invalid));
    }
}
