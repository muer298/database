package edu.course.cinema.dao;

import edu.course.cinema.model.Screening;
import edu.course.cinema.model.ScreeningStatus;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

public class ScreeningDAO {
    public long create(Connection connection, Screening screening) throws SQLException {
        String sql = """
                INSERT INTO screenings
                  (movie_id,hall_id,start_time,end_time,language_version,subtitle,ticket_price,screening_status)
                VALUES (?,?,?,?,?,?,?,?)
                """;
        try (PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setLong(1, screening.movieId());
            statement.setLong(2, screening.hallId());
            statement.setTimestamp(3, Timestamp.valueOf(screening.startTime()));
            statement.setTimestamp(4, Timestamp.valueOf(screening.endTime()));
            statement.setString(5, screening.languageVersion());
            statement.setString(6, screening.subtitle());
            statement.setBigDecimal(7, screening.ticketPrice());
            statement.setString(8, screening.status().name());
            statement.executeUpdate();
            try (ResultSet keys = statement.getGeneratedKeys()) {
                if (keys.next()) return keys.getLong(1);
            }
        }
        throw new SQLException("插入场次成功，但未返回主键");
    }

    public Optional<Screening> findById(Connection connection, long id) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT * FROM screenings WHERE screening_id=?")) {
            statement.setLong(1, id);
            try (ResultSet result = statement.executeQuery()) {
                return result.next() ? Optional.of(map(result)) : Optional.empty();
            }
        }
    }

    public List<Screening> listByMovieAndDate(Connection connection, long movieId, LocalDate date)
            throws SQLException {
        String sql = """
                SELECT * FROM screenings
                WHERE movie_id=? AND start_time>=? AND start_time<?
                ORDER BY start_time
                """;
        List<Screening> screenings = new ArrayList<>();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, movieId);
            statement.setTimestamp(2, Timestamp.valueOf(date.atStartOfDay()));
            statement.setTimestamp(3, Timestamp.valueOf(date.plusDays(1).atStartOfDay()));
            try (ResultSet result = statement.executeQuery()) {
                while (result.next()) screenings.add(map(result));
            }
        }
        return screenings;
    }

    public boolean hasTimeConflict(Connection connection, long hallId, LocalDateTime start,
                                   LocalDateTime end, Long excludedScreeningId) throws SQLException {
        String sql = """
                SELECT EXISTS(
                  SELECT 1 FROM screenings
                  WHERE hall_id=? AND screening_status<>'CANCELLED'
                    AND start_time<? AND end_time>?
                    AND (? IS NULL OR screening_id<>?)
                )
                """;
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, hallId);
            statement.setTimestamp(2, Timestamp.valueOf(end));
            statement.setTimestamp(3, Timestamp.valueOf(start));
            if (excludedScreeningId == null) {
                statement.setNull(4, Types.BIGINT);
                statement.setNull(5, Types.BIGINT);
            } else {
                statement.setLong(4, excludedScreeningId);
                statement.setLong(5, excludedScreeningId);
            }
            try (ResultSet result = statement.executeQuery()) {
                result.next();
                return result.getBoolean(1);
            }
        }
    }

    private Screening map(ResultSet result) throws SQLException {
        return new Screening(result.getLong("screening_id"), result.getLong("movie_id"),
                result.getLong("hall_id"), result.getTimestamp("start_time").toLocalDateTime(),
                result.getTimestamp("end_time").toLocalDateTime(), result.getString("language_version"),
                result.getString("subtitle"), result.getBigDecimal("ticket_price"),
                ScreeningStatus.valueOf(result.getString("screening_status")));
    }
}
