package edu.course.cinema.service;

import edu.course.cinema.dao.ScreeningDAO;
import edu.course.cinema.dao.SeatOccupancyDAO;
import edu.course.cinema.model.Screening;
import edu.course.cinema.util.DBUtil;

import java.sql.Connection;
import java.sql.SQLException;

/** Creates a screening and all AVAILABLE seat rows in one transaction. */
public class ScreeningService {
    private final ScreeningDAO screeningDAO = new ScreeningDAO();
    private final SeatOccupancyDAO occupancyDAO = new SeatOccupancyDAO();

    public long schedule(Screening screening) throws SQLException {
        if (!screening.endTime().isAfter(screening.startTime())) {
            throw new IllegalArgumentException("结束时间必须晚于开始时间");
        }
        try (Connection connection = DBUtil.getConnection()) {
            connection.setAutoCommit(false);
            try {
                if (screeningDAO.hasTimeConflict(connection, screening.hallId(),
                        screening.startTime(), screening.endTime(), null)) {
                    throw new SQLException("影厅在该时间段已有场次", "23000");
                }
                long id = screeningDAO.create(connection, screening);
                occupancyDAO.initializeForScreening(connection, id);
                connection.commit();
                return id;
            } catch (SQLException | RuntimeException error) {
                connection.rollback();
                throw error;
            } finally {
                connection.setAutoCommit(true);
            }
        }
    }
}
