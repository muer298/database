package edu.course.cinema.dao;

import edu.course.cinema.model.Hall;
import edu.course.cinema.model.HallType;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

public class HallDAO {
    public long create(Connection connection, Hall hall) throws SQLException {
        String sql = "INSERT INTO halls (hall_name,hall_type,row_count,column_count) VALUES (?,?,?,?)";
        try (PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setString(1, hall.name());
            statement.setString(2, hall.type().name());
            statement.setInt(3, hall.rowCount());
            statement.setInt(4, hall.columnCount());
            statement.executeUpdate();
            try (ResultSet keys = statement.getGeneratedKeys()) {
                if (keys.next()) return keys.getLong(1);
            }
        }
        throw new SQLException("插入影厅成功，但未返回主键");
    }

    public Optional<Hall> findById(Connection connection, long id) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement("SELECT * FROM halls WHERE hall_id=?")) {
            statement.setLong(1, id);
            try (ResultSet result = statement.executeQuery()) {
                return result.next() ? Optional.of(map(result)) : Optional.empty();
            }
        }
    }

    public List<Hall> list(Connection connection) throws SQLException {
        List<Hall> halls = new ArrayList<>();
        try (PreparedStatement statement = connection.prepareStatement("SELECT * FROM halls ORDER BY hall_id");
             ResultSet result = statement.executeQuery()) {
            while (result.next()) halls.add(map(result));
        }
        return halls;
    }

    private Hall map(ResultSet result) throws SQLException {
        return new Hall(result.getLong("hall_id"), result.getString("hall_name"),
                HallType.valueOf(result.getString("hall_type")), result.getInt("row_count"),
                result.getInt("column_count"));
    }
}
