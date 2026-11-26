package edu.course.cinema.dao;

import edu.course.cinema.model.AccountStatus;
import edu.course.cinema.model.User;
import edu.course.cinema.model.UserRole;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.Optional;

public class UserDAO {
    public Optional<User> findById(Connection connection, long id) throws SQLException {
        return findOne(connection, "SELECT * FROM users WHERE user_id = ?", id);
    }

    public Optional<User> findByUsername(Connection connection, String username) throws SQLException {
        return findOne(connection, "SELECT * FROM users WHERE username = ?", username);
    }

    private Optional<User> findOne(Connection connection, String sql, Object value) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setObject(1, value);
            try (ResultSet result = statement.executeQuery()) {
                return result.next() ? Optional.of(map(result)) : Optional.empty();
            }
        }
    }

    public long insert(Connection connection, User user) throws SQLException {
        String sql = """
                INSERT INTO users
                  (username,password_hash,real_name,phone,email,role,registered_at,account_status)
                VALUES (?,?,?,?,?,?,?,?)
                """;
        try (PreparedStatement statement = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setString(1, user.username());
            statement.setString(2, user.passwordHash());
            statement.setString(3, user.realName());
            statement.setString(4, user.phone());
            statement.setString(5, user.email());
            statement.setString(6, user.role().name());
            statement.setTimestamp(7, Timestamp.valueOf(user.registeredAt()));
            statement.setString(8, user.accountStatus().name());
            statement.executeUpdate();
            return generatedId(statement);
        }
    }

    public boolean updateStatus(Connection connection, long id, AccountStatus status) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(
                "UPDATE users SET account_status = ? WHERE user_id = ?")) {
            statement.setString(1, status.name());
            statement.setLong(2, id);
            return statement.executeUpdate() == 1;
        }
    }

    private User map(ResultSet result) throws SQLException {
        return new User(result.getLong("user_id"), result.getString("username"),
                result.getString("password_hash"), result.getString("real_name"),
                result.getString("phone"), result.getString("email"),
                UserRole.valueOf(result.getString("role")),
                result.getTimestamp("registered_at").toLocalDateTime(),
                AccountStatus.valueOf(result.getString("account_status")));
    }

    private long generatedId(PreparedStatement statement) throws SQLException {
        try (ResultSet keys = statement.getGeneratedKeys()) {
            if (keys.next()) return keys.getLong(1);
        }
        throw new SQLException("插入用户成功，但未返回主键");
    }
}
