package edu.course.cinema.dao;

import edu.course.cinema.model.Seat;
import edu.course.cinema.model.SeatStatus;
import edu.course.cinema.model.SeatType;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class SeatDAO {
    public List<Seat> listByHall(Connection connection, long hallId) throws SQLException {
        return list(connection, "SELECT s.* FROM seats s WHERE s.hall_id=? ORDER BY s.seat_row,s.seat_column", hallId);
    }

    public List<Seat> listAvailableByScreening(Connection connection, long screeningId) throws SQLException {
        String sql = """
                SELECT s.* FROM seat_occupancies so
                JOIN seats s ON s.seat_id=so.seat_id
                WHERE so.screening_id=? AND so.occupancy_status='AVAILABLE' AND s.use_status='ENABLED'
                ORDER BY s.seat_row,s.seat_column
                """;
        return list(connection, sql, screeningId);
    }

    private List<Seat> list(Connection connection, String sql, long id) throws SQLException {
        List<Seat> seats = new ArrayList<>();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, id);
            try (ResultSet result = statement.executeQuery()) {
                while (result.next()) seats.add(map(result));
            }
        }
        return seats;
    }

    private Seat map(ResultSet result) throws SQLException {
        return new Seat(result.getLong("seat_id"), result.getLong("hall_id"),
                result.getInt("seat_row"), result.getInt("seat_column"),
                SeatType.valueOf(result.getString("seat_type")),
                SeatStatus.valueOf(result.getString("use_status")));
    }
}
