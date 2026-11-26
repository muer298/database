package edu.course.cinema.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

public class SeatOccupancyDAO {
    public int initializeForScreening(Connection connection, long screeningId) throws SQLException {
        String sql = """
                INSERT INTO seat_occupancies (screening_id,seat_id,occupancy_status)
                SELECT sc.screening_id,s.seat_id,'AVAILABLE'
                FROM screenings sc JOIN seats s ON s.hall_id=sc.hall_id
                WHERE sc.screening_id=? AND s.use_status='ENABLED'
                """;
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, screeningId);
            return statement.executeUpdate();
        }
    }
}
